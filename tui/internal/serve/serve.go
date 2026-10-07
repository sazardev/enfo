// Package serve runs Enfo over SSH (Charm's Wish): every connection gets its
// own Enfo with its own settings and history, keyed by the user's public key.
package serve

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"regexp"
	"time"

	tea "charm.land/bubbletea/v2"
	"charm.land/log/v2"
	"charm.land/ssh"
	"charm.land/wish/v2"
	"charm.land/wish/v2/activeterm"
	wbt "charm.land/wish/v2/bubbletea"
	"charm.land/wish/v2/logging"
	gossh "golang.org/x/crypto/ssh"

	"github.com/sazardev/enfo/tui/internal/store"
	"github.com/sazardev/enfo/tui/internal/ui"
)

// Options configure the SSH server.
type Options struct {
	Addr     string // host:port, default ":2222"
	HostKey  string // path of the host key (created if missing); default <state>/ssh/host_ed25519
	StateDir string // base state directory (for per-user data); default from the store
}

var unsafe = regexp.MustCompile(`[^A-Za-z0-9]+`)

// UserKey names a session's data directory from its public key; sessions
// without a key all share "guest".
func UserKey(pk ssh.PublicKey) string {
	if pk == nil {
		return "guest"
	}
	return unsafe.ReplaceAllString(gossh.FingerprintSHA256(pk), "-")
}

// SessionStore opens (creating it) the private store of one user under base.
// Desktop notifications and sounds are switched off in it: they would ring on
// the server, not on the user's machine (the terminal bell still works).
func SessionStore(base, user string) (*store.Store, error) {
	dir := filepath.Join(base, "ssh", user)
	st := &store.Store{ConfigDir: filepath.Join(dir, "config"), StateDir: filepath.Join(dir, "state")}
	for _, d := range []string{st.ConfigDir, st.StateDir} {
		if err := os.MkdirAll(d, 0o755); err != nil {
			return nil, err
		}
	}
	if _, err := os.Stat(st.ConfigPath()); errors.Is(err, os.ErrNotExist) {
		c := store.DefaultConfig()
		c.Notify, c.Sound = false, false
		if b, err := json.MarshalIndent(c, "", "  "); err == nil {
			_ = os.WriteFile(st.ConfigPath(), append(b, '\n'), 0o644)
		}
	}
	return st, nil
}

// Handler builds the Bubble Tea handler for a session.
func Handler(base string) wbt.Handler {
	return func(sess ssh.Session) (tea.Model, []tea.ProgramOption) {
		pty, _, ok := sess.Pty()
		if !ok {
			wish.Fatalln(sess, "Enfo needs a terminal: ssh -t")
			return nil, nil
		}
		user := UserKey(sess.PublicKey())
		st, err := SessionStore(base, user)
		if err != nil {
			wish.Fatalln(sess, "can't open your data:", err)
			return nil, nil
		}
		log.Info("session", "user", sess.User(), "key", user, "term", pty.Term, "size", fmt.Sprintf("%dx%d", pty.Window.Width, pty.Window.Height))
		return ui.New(st, ui.Options{}), nil
	}
}

// Run serves until ctx is cancelled, then shuts down gracefully.
func Run(ctx context.Context, o Options) error {
	if o.Addr == "" {
		o.Addr = ":2222"
	}
	if o.StateDir == "" {
		st, err := store.Open()
		if err != nil {
			return err
		}
		o.StateDir = st.StateDir
	}
	if o.HostKey == "" {
		o.HostKey = filepath.Join(o.StateDir, "ssh", "host_ed25519")
	}
	if err := os.MkdirAll(filepath.Dir(o.HostKey), 0o700); err != nil {
		return err
	}
	srv, err := wish.NewServer(
		wish.WithAddress(o.Addr),
		wish.WithHostKeyPath(o.HostKey),
		wish.WithPublicKeyAuth(func(ssh.Context, ssh.PublicKey) bool { return true }),
		wish.WithMiddleware(
			wbt.Middleware(Handler(o.StateDir)),
			activeterm.Middleware(),
			logging.Middleware(),
		),
	)
	if err != nil {
		return fmt.Errorf("can't create the SSH server: %w", err)
	}
	ln, err := net.Listen("tcp", o.Addr)
	if err != nil {
		return fmt.Errorf("can't listen on %s: %w", o.Addr, err)
	}
	log.Info("Enfo over SSH", "addr", ln.Addr().String(), "hostkey", o.HostKey)
	errc := make(chan error, 1)
	go func() { errc <- srv.Serve(ln) }()
	select {
	case err := <-errc:
		if err != nil && !errors.Is(err, ssh.ErrServerClosed) {
			return err
		}
		return nil
	case <-ctx.Done():
	}
	log.Info("shutting down")
	sctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(sctx); err != nil && !errors.Is(err, ssh.ErrServerClosed) {
		return err
	}
	return nil
}
