# Variables
# =========

NAME = oxidation_tweek

# Default to debug mode
ifneq ($(BUILD),release)
	BUILD = debug
	CFLAGS = -g
else
	CARGO_FLAGS = --release
endif

ifneq ($(TARGET),)
	CARGO_TARGET = --target $(TARGET)
endif

define echo
	@tput setaf 6
	@echo $1
	@tput sgr0
endef

# Build artifacts
OUT_DIR = build/$(BUILD)

# C build artifacts
C_OUT_DIR = $(OUT_DIR)/c
C_OUT_MAIN = $(C_OUT_DIR)/main

# JavaScript and WebAssembly build artifacts
JS_OUT_DIR = $(OUT_DIR)/js
JS_OUT_MAIN = $(JS_OUT_DIR)/main
JS_OUT_LIB_DIR = $(JS_OUT_DIR)/lib
JS_OUT_LIB_JS = $(JS_OUT_LIB_DIR)/$(NAME).js
JS_OUT_LIB_JS_BG = $(JS_OUT_LIB_DIR)/$(NAME)_bg.js
JS_OUT_LIB_WASM_BG = $(JS_OUT_LIB_DIR)/$(NAME)_bg.wasm

# WebAssembly build artifacts
WASM_OUT_DIR = $(OUT_DIR)/wasm
WASM_OUT_LIB = $(WASM_OUT_DIR)/$(NAME).wasm

# Optimized WebAssembly build artifacts
WASM_OPT_OUT_DIR = $(OUT_DIR)/wasm-opt
WASM_OPT_OUT_LIB = $(WASM_OPT_OUT_DIR)/$(NAME).wasm
WASM_OPT_OUT_LIB_GC = $(WASM_OPT_OUT_DIR)/$(NAME)_gc.wasm

# wasm-bindgen build artifacts
WASM_BINDGEN_OUT_DIR = $(OUT_DIR)/wasm-bindgen
WASM_BINDGEN_OUT_JS = $(WASM_BINDGEN_OUT_DIR)/$(NAME).js
WASM_BINDGEN_OUT_JS_BG = $(WASM_BINDGEN_OUT_DIR)/$(NAME)_bg.js
WASM_BINDGEN_OUT_WASM_BG = $(WASM_BINDGEN_OUT_DIR)/$(NAME)_bg.wasm

# Optimized wasm-bindgen build artifacts
WASM_BINDGEN_OPT_OUT_DIR = $(OUT_DIR)/wasm-bindgen-opt
WASM_BINDGEN_OPT_OUT_JS = $(WASM_BINDGEN_OPT_OUT_DIR)/$(NAME).js
WASM_BINDGEN_OPT_OUT_JS_BG = $(WASM_BINDGEN_OPT_OUT_DIR)/$(NAME)_bg.js
WASM_BINDGEN_OPT_OUT_WASM_BG = $(WASM_BINDGEN_OPT_OUT_DIR)/$(NAME)_bg.wasm

# Rust sources
RUST_SRC = rust/src/lib.rs rust/src/util.rs

RUST_LINTED = .rust-linted
RUST_TESTED = .rust-tested

# Rust build artifacts
RUST_TARGET_DIR = rust/target

# Rust C build artifacts
ifeq ($(TARGET),)
RUST_C_LIB_DIR = $(RUST_TARGET_DIR)/$(BUILD)
else
RUST_C_LIB_DIR = $(RUST_TARGET_DIR)/$(TARGET)/$(BUILD)
endif
RUST_C_LIB = $(RUST_C_LIB_DIR)/lib$(NAME).a
RUST_C_HEADER = c/src/$(NAME).h

# Rust WebAssembly build artifacts
RUST_WASM_LIB_DIR = $(RUST_TARGET_DIR)/wasm32-unknown-unknown/$(BUILD)
RUST_WASM_LIB = $(RUST_WASM_LIB_DIR)/$(NAME).wasm

UGLIFYJS = ./node_modules/.bin/uglifyjs

# Build Rules
# ===========

.DEFAULT_GOAL = help

.PHONY: all clean debug help lint-rust release test test-c test-js test-rust

all: test ## Build and test everything (defaults to debug mode)

clean: ## Clean everything (both release and debug artifacts)
	rm -rf build $(RUST_C_HEADER) $(RUST_LINTED) $(RUST_TESTED) $(RUST_TARGET_DIR)

debug: ## Build and test everything (debug mode)
	$(MAKE) BUILD=$@ all

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

lint-rust:  ## Lint the Rust source (runs Clippy)
	$(call echo, "Linting Rust source")
	cd rust && cargo +nightly clippy $(CARGO_TARGET) $(CARGO_FLAGS)

release: ## Build and test everything (release mode)
	$(MAKE) BUILD=$@ all

test: test-c test-js ## Run both the C and JavaScript test applications (defaults to debug mode)

test-c: $(C_OUT_MAIN) ## Run the C test application (defaults to debug mode)
	$(call echo, "Running C test application")
	$<

test-js: $(JS_OUT_MAIN) ## Run the JavaScript test application (defaults to debug mode)
	$(call echo, "Running JavaScript test application")
	node $<

test-rust: ## Run the Rust unit tests
	$(call echo, "Running Rust unit tests")
	cd rust && cargo test $(CARGO_TARGET) $(CARGO_FLAGS)

# C Test Application
# ------------------

$(C_OUT_MAIN): c/src/main.c $(RUST_C_LIB) $(RUST_C_HEADER) rust/cbindgen.toml
	$(call echo, "Building C test application")
	mkdir -p $(C_OUT_DIR)
	$(CC) $(CFLAGS) $< -I c -l$(RUST_C_LIB) -o $@

# JavaScript Test Application
# ---------------------------

$(JS_OUT_MAIN): js/index.js $(JS_OUT_LIB_JS) $(JS_OUT_LIB_JS_BG) $(JS_OUT_LIB_WASM_BG)
	$(call echo, "Building JavaScript test application")
	mkdir -p $(JS_OUT_DIR)
	cp $< $@

ifeq ($(BUILD),debug)
$(JS_OUT_LIB_JS): $(WASM_BINDGEN_OUT_JS)
else
$(JS_OUT_LIB_JS): $(WASM_BINDGEN_OPT_OUT_JS)
endif
	mkdir -p $(JS_OUT_LIB_DIR)
	cp $< $@

ifeq ($(BUILD),debug)
$(JS_OUT_LIB_JS_BG): $(WASM_BINDGEN_OUT_JS_BG)
else
$(JS_OUT_LIB_JS_BG): $(WASM_BINDGEN_OPT_OUT_JS_BG)
endif
	mkdir -p $(JS_OUT_LIB_DIR)
	cp $< $@

ifeq ($(BUILD),debug)
$(JS_OUT_LIB_WASM_BG): $(WASM_BINDGEN_OUT_WASM_BG)
else
$(JS_OUT_LIB_WASM_BG): $(WASM_BINDGEN_OPT_OUT_WASM_BG)
endif
	mkdir -p $(JS_OUT_LIB_DIR)
	cp $< $@

# Rust C Library
# --------------

$(RUST_C_LIB): rust/Cargo.toml $(RUST_SRC) $(RUST_LINTED) $(RUST_TESTED)
	$(call echo, "Building Rust C library")
	cd rust && cargo build $(CARGO_TARGET) $(CARGO_FLAGS)

$(RUST_C_HEADER): rust/Cargo.toml $(RUST_SRC) rust/cbindgen.toml
	$(call echo, "Generating Rust C library headers")
	cbindgen rust -o $@

$(RUST_LINTED): rust/Cargo.toml $(RUST_SRC)
	make lint-rust
	touch $(RUST_LINTED)

$(RUST_TESTED): rust/Cargo.toml $(RUST_SRC)
	make test-rust
	touch $(RUST_TESTED)

# Rust WebAssembly Library
# ------------------------

$(RUST_WASM_LIB): rust/Cargo.toml $(RUST_SRC)
	$(call echo, "Building Rust WebAssembly library")
	cd rust && cargo build --target wasm32-unknown-unknown $(CARGO_FLAGS)

# Optimized Rust WebAssembly Library
# ----------------------------------

$(WASM_OUT_LIB): $(RUST_WASM_LIB)
	mkdir -p $(WASM_OUT_DIR)
	cp $< $@

$(WASM_OPT_OUT_LIB_GC): $(WASM_OUT_LIB)
	$(call echo, "Running wasm-gc over Rust WebAssembly library")
	mkdir -p $(WASM_OPT_OUT_DIR)
	wasm-gc $< $@

$(WASM_OPT_OUT_LIB): $(WASM_OPT_OUT_LIB_GC)
	$(call echo, "Running wasm-opt over Rust WebAssembly library")
	wasm-opt $< -Os -o $@

# wasm-bindgen Library
# --------------------

ifeq ($(BUILD),debug)
$(WASM_BINDGEN_OUT_JS): $(WASM_OUT_LIB)
else
$(WASM_BINDGEN_OUT_JS): $(WASM_OPT_OUT_LIB)
endif
	$(call echo, "Running wasm-bindgen over Rust WebAssembly library")
	mkdir -p $(WASM_BINDGEN_OUT_DIR)
	wasm-bindgen $< --nodejs --out-dir $(WASM_BINDGEN_OUT_DIR) --typescript
	cd $(WASM_BINDGEN_OUT_DIR) && patch -p0 <../../../js/$(NAME)_bg.js.patch

# Optimized wasm-bindgen Library
# ------------------------------

$(WASM_BINDGEN_OPT_OUT_JS): $(WASM_BINDGEN_OUT_JS) $(UGLIFYJS)
	$(call echo, "Minifying wasm-bindgen JavaScript library")
	mkdir -p $(WASM_BINDGEN_OPT_OUT_DIR)
	$(UGLIFYJS) $< --compress -o $@

$(WASM_BINDGEN_OPT_OUT_JS_BG): $(WASM_BINDGEN_OUT_JS_BG) $(UGLIFYJS)
	mkdir -p $(WASM_BINDGEN_OPT_OUT_DIR)
	$(UGLIFYJS) $< --compress -o $@

$(WASM_BINDGEN_OPT_OUT_WASM_BG): $(WASM_BINDGEN_OUT_WASM_BG)
	mkdir -p $(WASM_BINDGEN_OPT_OUT_DIR)
	cp $< $@

# uglifyjs
# --------

$(UGLIFYJS): package.json
	$(call echo, "Installing uglify-js")
	npm install
	touch $(UGLIFYJS)
