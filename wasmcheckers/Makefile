.PHONY: all clean
all: checkers.wasm
clean:
	rm -f *.wasm

%.wasm: %.wat
	wat2wasm $< -o $@

.PHONY: run
run: checkers.wasm
	wasm-interp checkers.wasm
