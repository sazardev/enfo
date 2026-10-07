// Package i18n holds the interface strings. Spanish and English ship; adding a
// language is one more map in its own file plus a line in Languages.
package i18n

import (
	"fmt"
	"os"
	"strings"
)

// Language is a selectable UI language.
type Language struct{ Code, Name string }

var Languages = []Language{{"en", "English"}, {"es", "Español"}}

var (
	current = "en"
	tables  = map[string]map[string]string{"en": en, "es": es}
)

// Detect picks a language from the environment (LC_ALL, LC_MESSAGES, LANG).
func Detect() string {
	for _, k := range []string{"LC_ALL", "LC_MESSAGES", "LANG", "LANGUAGE"} {
		v := strings.ToLower(os.Getenv(k))
		if v == "" || v == "c" || v == "posix" || strings.HasPrefix(v, "c.") {
			continue
		}
		for _, l := range Languages {
			if strings.HasPrefix(v, l.Code) {
				return l.Code
			}
		}
		return "en"
	}
	return "en"
}

// Set chooses the language; "auto" (or empty) follows the environment.
func Set(code string) string {
	if code == "" || code == "auto" {
		code = Detect()
	}
	if _, ok := tables[code]; !ok {
		code = "en"
	}
	current = code
	return code
}

// Lang is the active language code.
func Lang() string { return current }

// T returns the string for key, formatted with args. Unknown keys come back as
// the key itself so a gap is visible instead of blank.
func T(key string, args ...any) string {
	s, ok := tables[current][key]
	if !ok {
		if s, ok = en[key]; !ok {
			return key
		}
	}
	if len(args) > 0 {
		return fmt.Sprintf(s, args...)
	}
	return s
}

// Has reports whether a key exists (used by tests).
func Has(lang, key string) bool { _, ok := tables[lang][key]; return ok }

// Keys lists the English keys (the source of truth).
func Keys() []string {
	out := make([]string, 0, len(en))
	for k := range en {
		out = append(out, k)
	}
	return out
}

// Table returns a language's map (tests).
func Table(lang string) map[string]string { return tables[lang] }
