# Variables
# =========

NAME = rust_c_js

# Default to debug mode
ifneq ($(BUILD),release)
	BUILD = debug
	CFLAGS = "-g"
else
	CARGO_FLAGS = "--release"
endif

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
RUST_SRC = rust/src/lib.rs

# Rust build artifacts
RUST_TARGET_DIR = rust/target

# Rust C build artifacts
RUST_C_LIB_DIR = $(RUST_TARGET_DIR)/$(BUILD)
RUST_C_LIB = $(RUST_C_LIB_DIR)/lib$(NAME).dylib
RUST_C_HEADER = c/src/rust.h

# Rust WebAssembly build artifacts
RUST_WASM_LIB_DIR = $(RUST_TARGET_DIR)/wasm32-unknown-unknown/$(BUILD)
RUST_WASM_LIB = $(RUST_WASM_LIB_DIR)/$(NAME).wasm

UGLIFYJS = ./node_modules/.bin/uglifyjs

# Build Rules
# ===========

.DEFAULT_GOAL = help

.PHONY: all clean debug help release test test-c test-js

all: test ## Build and test everything (defaults to debug mode)

clean: ## Clean everything (both release and debug artifacts)
	rm -rf build $(RUST_C_HEADER) rust/target

debug: ## Build and test everything (debug mode)
	$(MAKE) BUILD=$@ all

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

release: ## Build and test everything (release mode)
	$(MAKE) BUILD=$@ all

test: test-c test-js ## Run both the C and JavaScript test applications (defaults to debug mode)

test-c: $(C_OUT_MAIN) ## Run the C test application (defaults to debug mode)
	LD_LIBRARY_PATH=$(RUST_C_LIB_DIR) $<

test-js: $(JS_OUT_MAIN) ## Run the JavaScript test application (defaults to debug mode)
	node $<

# C Test Application
# ------------------

$(C_OUT_MAIN): c/src/main.c $(RUST_C_LIB) $(RUST_C_HEADER) rust/cbindgen.toml
	mkdir -p $(C_OUT_DIR)
	$(CC) $(CFLAGS) $< -I c -L $(RUST_C_LIB_DIR) -l$(NAME) -o $@

# JavaScript Test Application
# ---------------------------

$(JS_OUT_MAIN): js/index.js $(JS_OUT_LIB_JS) $(JS_OUT_LIB_JS_BG) $(JS_OUT_LIB_WASM_BG)
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

$(RUST_C_LIB): rust/Cargo.toml $(RUST_SRC)
	cd rust && cargo build $(CARGO_FLAGS)

$(RUST_C_HEADER): rust/Cargo.toml $(RUST_SRC) rust/cbindgen.toml
	cbindgen rust -o $@

# Rust WebAssembly Library
# ------------------------

$(RUST_WASM_LIB): rust/Cargo.toml $(RUST_SRC)
	cd rust && cargo build --target wasm32-unknown-unknown $(CARGO_FLAGS)

# Optimized Rust WebAssembly Library
# ----------------------------------

$(WASM_OUT_LIB): $(RUST_WASM_LIB)
	mkdir -p $(WASM_OUT_DIR)
	cp $< $@

$(WASM_OPT_OUT_LIB_GC): $(WASM_OUT_LIB)
	mkdir -p $(WASM_OPT_OUT_DIR)
	wasm-gc $< $@

$(WASM_OPT_OUT_LIB): $(WASM_OPT_OUT_LIB_GC)
	wasm-opt $< -Os -o $@

# wasm-bindgen Library
# --------------------

ifeq ($(BUILD),debug)
$(WASM_BINDGEN_OUT_JS): $(WASM_OUT_LIB)
else
$(WASM_BINDGEN_OUT_JS): $(WASM_OPT_OUT_LIB)
endif
	mkdir -p $(WASM_BINDGEN_OUT_DIR)
	wasm-bindgen $< --nodejs --out-dir $(WASM_BINDGEN_OUT_DIR)
	cd $(WASM_BINDGEN_OUT_DIR) && patch -p0 <../../../js/$(NAME)_bg.js.patch

# Optimized wasm-bindgen Library
# ------------------------------

$(WASM_BINDGEN_OPT_OUT_JS): $(WASM_BINDGEN_OUT_JS) $(UGLIFYJS)
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
	npm install
	touch $(UGLIFYJS)
