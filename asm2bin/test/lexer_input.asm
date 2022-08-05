/*
  This is the input for the lexer,
  it checks that all tokens are generated properly
*/

// First we start with all instructions
mov a, b
or a, b
and a, b
xor a, b
add a, b
sub a, b
mul a, b
shr a, b
shl a, b
ror a, b
rol a, b
test a, b
cmp a, b
jc a
jnc a
jh a
jnh a
jl a
jnl a
jz a
jnz a
inv a
inc a
dec a
poll dmaID
sync dmaID
lock dmaID
unlock dmaID
jmp a
nop
dmaCopy

// Then we check instruction variations
mov r0, 0         ; reg, val
mov r1, r2        ; reg, reg
mov [r3], r4      ; [reg], reg
mov r5, [r6]      ; reg, [reg]
mov [0xFFFF], -59 ; [val], val
mov [0xABC0], r7  ; [val], reg
mov st, [0x12A0]  ; reg, [val]

jmp pc      ; reg
jmp 0x0120  ; val
jmp [0x33AB]; [val]
jmp [hp]    ; [reg]

// Finally we test labels
label:
