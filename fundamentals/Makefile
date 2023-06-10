.PHONY: all clean
all: add1.wasm add2.wasm add.wasm
clean:
	rm -f *.wasm

%.wasm: %.wat
	wat2wasm $< -o $@

.PHONY: objdump
objdump: all
	wasm-objdump add1.wasm -x
	wasm-objdump add2.wasm -x
	wasm-objdump add.wasm -x

.PHONY: roundtrip
roundtrip: all
	wasm2wat add1.wasm
	wasm2wat add2.wasm
	wasm2wat add.wasm

.PHONY: run run1 run2
run: add.wasm
	wasm-interp add.wasm -r add5plus9
run1: add1.wasm
	wasm-interp add1.wasm -r add -a i32:5 -a i32:9
run2: add2.wasm
	wasm-interp add2.wasm -r add -a i32:5 -a i32:9
