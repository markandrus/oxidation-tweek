all: test

clean:
	rm -rf target main

main: src/main.c target/debug
	gcc src/main.c -L target/debug -lrust_c_js -o main

target/debug: Cargo.toml src/lib.rs
	cargo build

test: main
	LD_LIBRARY_PATH=target/debug ./main

.PHONY: all clean test
