(module
;; -- Imports
(import "events" "piececrowned"
    (func $notify_piececrowned (param $pieceX i32) (param $pieceY i32))
)

;; -- Allocate memory
(memory $mem 1)

;; -- Globals
;; piece state
(global $BLACK i32 (i32.const 1))
(global $WHITE i32 (i32.const 2))
(global $CROWN i32 (i32.const 4))

;; turn state
(global $currentTurn (mut i32) (i32.const 0))

;; -- Board control

;; position = y * 8 + x
(func $indexForPosition (param $x i32) (param $y i32) (result i32)
    (i32.add
        (i32.mul
            (i32.const 8)
            (local.get $y)
        )
        (local.get $x)
    )
)

;; offset = (y * 8 + x) * 4(bytes)
(func $offsetForPosition (param $x i32) (param $y i32) (result i32)
    (i32.mul
        (call $indexForPosition (local.get $x) (local.get $y))
        (i32.const 4)
    )
)

;; -- Piece control

;; Determine if a piece has been crowned
(func $isCrowned (param $piece i32) (result i32)
    (i32.eq
        (i32.and (local.get $piece) (global.get $CROWN))
        (global.get $CROWN)
    )
)

;; Determine if a piece is white
(func $isWhite (param $piece i32) (result i32)
    (i32.eq
        (i32.and (local.get $piece) (global.get $WHITE))
        (global.get $WHITE)
    )
)

;; Determine if a piece is black
(func $isBlack (param $piece i32) (result i32)
    (i32.eq
        (i32.and (local.get $piece) (global.get $BLACK))
        (global.get $BLACK)
    )
)

;; Adds a crown to a fiven piece (no mutation)
(func $withCrown (param $piece i32) (result i32)
    (i32.or (local.get $piece) (global.get $CROWN))
)

;; Removes a crown from a given piece (no mutation)
(func $withoutCrown (param $piece i32) (result i32)
    (i32.and (local.get $piece) (i32.const 3))
)

;; Sets a piece on the board.
(func $setPiece (param $x i32) (param $y i32) (param $piece i32)
    (i32.store
        (call $offsetForPosition
            (local.get $x)
            (local.get $y)
        )
        (local.get $piece)
    )
)

;; Gets a piece from the board.
;; Out of range causes a trap.
(func $getPiece (param $x i32) (param $y i32) (result i32)
    (if (result i32)
        (i32.and
            (call $inRange
                (i32.const 0)
                (i32.const 7)
                (local.get $x)
            )
            (call $inRange
                (i32.const 0)
                (i32.const 7)
                (local.get $y)
            )
        )
        (then
            (i32.load
                (call $offsetForPosition
                    (local.get $x)
                    (local.get $y)
                )
            )
        )
        (else
            (unreachable)
        )
    )
)

;; Detect if values are within range (inclusive high and low).
(func $inRange (param $low i32) (param $high i32) (param $value i32) (result i32)
    (i32.and
        (i32.ge_s (local.get $value) (local.get $low))
        (i32.le_s (local.get $value) (local.get $high))
    )
)

;; -- Turn controll

;; Gets the current turn owner (white or black)
(func $getTurnOwner (result i32)
    (global.get $currentTurn)
)

;; Sets the turn owner.
(func $setTurnOwner (param $piece i32)
    (global.set $currentTurn (local.get $piece))
)

;; At the end of turn, switch turn owner to the other player.
(func $toggleTurnOwner
    (if
        (i32.eq (call $getTurnOwner) (global.get $BLACK))
        (then (call $setTurnOwner (global.get $WHITE)))
        (else (call $setTurnOwner (global.get $BLACK)))
    )
)

;; Determine if it's a player's turn.
(func $isPlayersTurn (param $player i32) (result i32)
    (i32.gt_s
        (i32.and (local.get $player) (call $getTurnOwner))
        (i32.const 0)
    )
)

;; -- Rule control

;; Should this piece get crowned?
;; We crown black pieces in row 0, white pieces in row 7.
(func $shouldCrown (param $pieceY i32) (param $piece i32) (result i32)
    (i32.or
        (i32.and
            (i32.eq
                (local.get $pieceY)
                (i32.const 0)
            )
            (call $isBlack (local.get $piece))
        )
        (i32.and
            (i32.eq
                (local.get $pieceY)
                (i32.const 7)
            )
            (call $isWhite (local.get $piece))
        )
    )
)

;; Converts a piece into a crowned piece and invokes a host notifier.
(func $crownPiece (param $x i32) (param $y i32)
    (local $piece i32)
    (local.set $piece (call $getPiece (local.get $x) (local.get $y)))
    (call $setPiece (local.get $x) (local.get $y)
        (call $withCrown (local.get $piece))
    )
    (call $notify_piececrowned (local.get $x) (local.get $y))
)

(func $distance (param $x i32) (param $y i32) (result i32)
    (i32.sub (local.get $x) (local.get $y))
)

;; -- Moving

;; Determine if the move is valid.
(func $isValidMove (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
    (local $player i32)
    (local $target i32)

    (local.set $player (call $getPiece (local.get $fromX) (local.get $fromY)))
    (local.set $target (call $getPiece (local.get $toX) (local.get $toY)))

    (if (result i32)
        (block (result i32)
            (i32.and
                (call $validJumpDistance (local.get $fromY) (local.get $toY))
                (i32.and
                    (call $isPlayersTurn (local.get $player))
                    ;; target must be unoccupied.
                    (i32.eq (local.get $target) (i32.const 0))
                )
            )
        )
        (then
            (i32.const 1)
        )
        (else
            (i32.const 0)
        )
    )
)

;; Ensures travel is 1 or 2 squares.
(func $validJumpDistance (param $from i32) (param $to i32) (result i32)
    (local $d i32)
    (local.set $d
        (if (result i32)
            (i32.gt_s (local.get $to (local.get $from)))
            (then
                (call $distance (local.get $to) (local.get $from))
            )
            (else
                (call $distance (local.get $from) (local.get $to))
            )
        )
    )
    (i32.le_u
        (local.get $d)
        (i32.const 2)
    )
)

) ;; end of module
