all: test

clean:
	rm -rf main rust_c_js.js rust_c_js_bg.js rust_c_js_bg.wasm target

main: src/main.c target/debug/librust_c_js.dylib
	gcc src/main.c -L target/debug -lrust_c_js -o main

rust_c_js.js: target/wasm32-unknown-unknown/debug/rust_c_js.wasm
	wasm-bindgen target/wasm32-unknown-unknown/debug/rust_c_js.wasm --nodejs --out-dir .

target/debug/librust_c_js.dylib: Cargo.toml src/lib.rs
	cargo build

target/wasm32-unknown-unknown/debug/rust_c_js.wasm: Cargo.toml src/lib.rs
	cargo build --target wasm32-unknown-unknown

test: test-c test-js

test-c: main
	LD_LIBRARY_PATH=target/debug ./main

test-js: rust_c_js.js
	node src/main.js

.PHONY: all clean test test-c test-js
