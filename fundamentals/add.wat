(module
    (func $add (param $lhs i32) (param $rhs i32) (result i32)
        (i32.add
            (local.get $lhs)
            (local.get $rhs)
        )
    )
    (func $add5plus9 (result i32)
        (call $add (i32.const 5) (i32.const 9))
    )
    (export "add5plus9" (func $add5plus9))
)
