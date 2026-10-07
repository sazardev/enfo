# Enfo TUI — build helpers.   make help
BIN      ?= enfo
PREFIX   ?= /usr/local
VERSION  ?= 0.1.0
COMMIT   ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo none)
LDFLAGS  := -s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT)

.PHONY: help build run test vet install uninstall demo clean dist

help: ## list targets
	@grep -E '^[a-z-]+:.*##' Makefile | sed 's/:.*##/\t/'

build: ## build ./enfo
	go build -trimpath -ldflags '$(LDFLAGS)' -o $(BIN) ./cmd/enfo

run: build ## build and run
	./$(BIN)

test: ## run all tests
	go test ./...

vet: ## go vet + gofmt check
	go vet ./...
	@test -z "$$(gofmt -l .)" || (gofmt -l . && exit 1)

install: build ## install to $(PREFIX)/bin with completions and man page
	install -Dm755 $(BIN) $(DESTDIR)$(PREFIX)/bin/$(BIN)
	./$(BIN) completion bash | install -Dm644 /dev/stdin $(DESTDIR)$(PREFIX)/share/bash-completion/completions/$(BIN)
	./$(BIN) completion zsh  | install -Dm644 /dev/stdin $(DESTDIR)$(PREFIX)/share/zsh/site-functions/_$(BIN)
	./$(BIN) completion fish | install -Dm644 /dev/stdin $(DESTDIR)$(PREFIX)/share/fish/vendor_completions.d/$(BIN).fish
	./$(BIN) man | install -Dm644 /dev/stdin $(DESTDIR)$(PREFIX)/share/man/man1/$(BIN).1

uninstall: ## remove what install put in $(PREFIX)
	rm -f $(DESTDIR)$(PREFIX)/bin/$(BIN) \
	  $(DESTDIR)$(PREFIX)/share/bash-completion/completions/$(BIN) \
	  $(DESTDIR)$(PREFIX)/share/zsh/site-functions/_$(BIN) \
	  $(DESTDIR)$(PREFIX)/share/fish/vendor_completions.d/$(BIN).fish \
	  $(DESTDIR)$(PREFIX)/share/man/man1/$(BIN).1

demo: build ## render demo/enfo.gif with VHS (needs vhs, ttyd, ffmpeg)
	PATH="$(CURDIR):$$PATH" vhs demo/demo.tape

dist: ## cross-compile release binaries into dist/
	@mkdir -p dist
	@for t in linux/amd64 linux/arm64 darwin/arm64 darwin/amd64 freebsd/amd64; do \
	  os=$${t%/*}; arch=$${t#*/}; \
	  GOOS=$$os GOARCH=$$arch CGO_ENABLED=0 go build -trimpath -ldflags '$(LDFLAGS)' -o dist/$(BIN)-$$os-$$arch ./cmd/enfo && echo built $$os/$$arch; \
	done

clean: ## remove build output
	rm -rf $(BIN) dist
