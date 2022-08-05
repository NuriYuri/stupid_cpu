/*
  This is the input for the ast,
  it checks if all instructions can be built with all their operand kind
*/
value: 0
ptr: 0

// nop
nop

// dmaCopy
dmaCopy ; doing this in such state might just break the program

// mov a, b
mov r0, value
mov r1, r2
mov [r3], r4
mov r5, [r6]
mov [ptr], value
mov [ptr], r7
mov pc, [ptr]

// or a, b
or r0, value
or r1, r2
or [r3], r4
or r5, [r6]
or [ptr], value
or [ptr], r7
or pc, [ptr]

// and a, b
and r0, value
and r1, r2
and [r3], r4
and r5, [r6]
and [ptr], value
and [ptr], r7
and pc, [ptr]

// xor a, b
xor r0, value
xor r1, r2
xor [r3], r4
xor r5, [r6]
xor [ptr], value
xor [ptr], r7
xor pc, [ptr]

// add a, b
add r0, value
add r1, r2
add [r3], r4
add r5, [r6]
add [ptr], value
add [ptr], r7
add pc, [ptr]

// sub a, b
sub r0, value
sub r1, r2
sub [r3], r4
sub r5, [r6]
sub [ptr], value
sub [ptr], r7
sub pc, [ptr]

// mul a, b
mul r0, value
mul r1, r2
mul [r3], r4
mul r5, [r6]
mul [ptr], value
mul [ptr], r7
mul pc, [ptr]

// shr a, b
shr r0, value
shr r1, r2
shr [r3], r4
shr r5, [r6]
shr [ptr], value
shr [ptr], r7
shr pc, [ptr]

// shl a, b
shl r0, value
shl r1, r2
shl [r3], r4
shl r5, [r6]
shl [ptr], value
shl [ptr], r7
shl pc, [ptr]

// ror a, b
ror r0, value
ror r1, r2
ror [r3], r4
ror r5, [r6]
ror [ptr], value
ror [ptr], r7
ror pc, [ptr]

// rol a, b
rol r0, value
rol r1, r2
rol [r3], r4
rol r5, [r6]
rol [ptr], value
rol [ptr], r7
rol pc, [ptr]

// test a, b
test r0, value
test r1, r2
test [r3], r4
test r5, [r6]
test [ptr], value
test [ptr], r7
test pc, [ptr]

// cmp a, b
cmp r0, value
cmp r1, r2
cmp [r3], r4
cmp r5, [r6]
cmp [ptr], value
cmp [ptr], r7
cmp pc, [ptr]

// jc a
jc st
jc value
jc [ptr]
jc [hp]

// jnc a
jnc st
jnc value
jnc [ptr]
jnc [hp]

// jha
jh st
jh value
jh [ptr]
jh [hp]

// jnh a
jnh st
jnh value
jnh [ptr]
jnh [hp]

// jl a
jl st
jl value
jl [ptr]
jl [hp]

// jnl a
jnl st
jnl value
jnl [ptr]
jnl [hp]

// jz a
jz st
jz value
jz [ptr]
jz [hp]

// jnz a
jnz st
jnz value
jnz [ptr]
jnz [hp]

// inv a
inv st
inv value
inv [ptr]
inv [hp]

// inc a
inc st
inc value
inc [ptr]
inc [hp]

// dec a
dec st
dec value
dec [ptr]
dec [hp]

// poll a
poll st
poll value
poll [ptr]
poll [hp]

// sync a
sync st
sync value
sync [ptr]
sync [hp]

// lock a
lock st
lock value
lock [ptr]
lock [hp]

// unlock a
unlock st
unlock value
unlock [ptr]
unlock [hp]

// jmp a
jmp st
jmp value
jmp [ptr]
jmp [hp]
