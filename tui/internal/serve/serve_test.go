package serve

import (
	"crypto/ed25519"
	"crypto/rand"
	"os"
	"strings"
	"testing"

	gossh "golang.org/x/crypto/ssh"
)

func TestUserKeyIsFilesystemSafe(t *testing.T) {
	pub, _, _ := ed25519.GenerateKey(rand.Reader)
	k, err := gossh.NewPublicKey(pub)
	if err != nil {
		t.Fatal(err)
	}
	u := UserKey(k)
	if !strings.HasPrefix(u, "SHA256-") || strings.ContainsAny(u, "/+= :") {
		t.Fatalf("unsafe key dir: %q", u)
	}
	if UserKey(k) != u {
		t.Fatal("key dir must be stable")
	}
	if UserKey(nil) != "guest" {
		t.Fatal("nil key")
	}
}

func TestSessionStoreIsolatedAndQuiet(t *testing.T) {
	base := t.TempDir()
	a, err := SessionStore(base, "alice")
	if err != nil {
		t.Fatal(err)
	}
	b, _ := SessionStore(base, "bob")
	if a.StateDir == b.StateDir || a.ConfigDir == b.ConfigDir {
		t.Fatal("sessions must not share directories")
	}
	cfg, found := a.LoadConfig()
	if !found || cfg.Notify || cfg.Sound || !cfg.Bell {
		t.Fatalf("ssh sessions must not notify or play sounds on the server: %+v", cfg)
	}
	// an existing config is left alone
	cfg.Work = 50
	_ = a.SaveConfig(cfg)
	a2, _ := SessionStore(base, "alice")
	if c, _ := a2.LoadConfig(); c.Work != 50 {
		t.Fatal("existing config was overwritten")
	}
	if _, err := os.Stat(a.StateDir); err != nil {
		t.Fatal(err)
	}
}
