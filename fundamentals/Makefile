.PHONY: all
all: add.wasm add_sexpr.wasm

add.wasm: add1.wat
	wat2wasm add1.wat -o add.wasm

add_sexpr.wasm: add2.wat
	wat2wasm add2.wat -o add_sexpr.wasm

.PHONY: objdump
objdump: add.wasm add_sexpr.wasm
	wasm-objdump add.wasm -x
	wasm-objdump add_sexpr.wasm -x

.PHONY: roundtrip
roundtrip: add.wasm add_sexpr.wasm
	wasm2wat add.wasm
	wasm2wat add_sexpr.wasm
