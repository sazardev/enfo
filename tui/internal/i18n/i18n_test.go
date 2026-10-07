package i18n

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

// Every key must exist in every language, with the same printf verbs.
func TestLanguagesAreComplete(t *testing.T) {
	verbs := regexp.MustCompile(`%[-+# 0-9.]*[a-zA-Z%]`)
	for _, l := range Languages {
		if l.Code == "en" {
			continue
		}
		tab := Table(l.Code)
		for k, v := range en {
			tv, ok := tab[k]
			if !ok {
				t.Errorf("%s: missing key %q", l.Code, k)
				continue
			}
			if strings.TrimSpace(tv) == "" && strings.TrimSpace(v) != "" {
				t.Errorf("%s: empty translation for %q", l.Code, k)
			}
			a, b := verbs.FindAllString(v, -1), verbs.FindAllString(tv, -1)
			if len(a) != len(b) {
				t.Errorf("%s: %q has %d format verbs, English has %d", l.Code, k, len(b), len(a))
			}
		}
		for k := range tab {
			if _, ok := en[k]; !ok {
				t.Errorf("%s: key %q does not exist in English", l.Code, k)
			}
		}
	}
}

// Every i18n.T("literal") in the source must be a defined key. Dynamic keys
// (built with +) are checked by their literal prefix.
func TestUsedKeysExist(t *testing.T) {
	call := regexp.MustCompile(`i18n\.T\(\s*"([^"]+)"`)
	root := filepath.Join("..", "..")
	var files []string
	_ = filepath.WalkDir(root, func(p string, d os.DirEntry, err error) error {
		if err == nil && !d.IsDir() && strings.HasSuffix(p, ".go") && !strings.HasSuffix(p, "_test.go") {
			files = append(files, p)
		}
		return nil
	})
	for _, f := range files {
		b, err := os.ReadFile(f)
		if err != nil {
			continue
		}
		for _, m := range call.FindAllStringSubmatch(string(b), -1) {
			key := m[1]
			if _, ok := en[key]; ok {
				continue
			}
			// dynamic: "phase." + x  -> some key must start with the prefix
			found := false
			for k := range en {
				if strings.HasPrefix(k, key) {
					found = true
					break
				}
			}
			if !found {
				t.Errorf("%s: i18n key %q is not defined", f, key)
			}
		}
	}
}

func TestFallbackToKey(t *testing.T) {
	Set("es")
	defer Set("en")
	if got := T("definitely.not.a.key"); got != "definitely.not.a.key" {
		t.Fatalf("got %q", got)
	}
}
