all: test

clean:
	rm -rf target main

main: src/main.c target/debug
	gcc src/main.c -L target/debug -lrust_c_js -o main

rust_c_js_bg.wasm: target/wasm32-unknown-unknown
	wasm-bindgen target/wasm32-unknown-unknown/debug/rust_c_js.wasm --nodejs --out-dir .

target/debug: Cargo.toml src/lib.rs
	cargo build

target/wasm32-unknown-unknown: Cargo.toml src/lib.rs
	cargo build --target wasm32-unknown-unknown

test: main rust_c_js_bg.wasm
	LD_LIBRARY_PATH=target/debug ./main
	node src/main

.PHONY: all clean test
