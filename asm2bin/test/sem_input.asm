/*
  This is the input for the semantic check,
  it checks the most important instructions regarding semantic check
*/

padding: 1
value: 5
file_data: "file://asm2bin/test/data.txt"
regular_string: "string"
symbol_but_actually_string: 'symbol'
string_with_interpolation: "str\x00\ning"

label:
mov currentDmaId, file_data
mov copyDataDmaDest, value
mov copyDataSize, file_data
mov copyDataSrcAddr, file_data
mov copyDataDestAddr, value
mov r0, file_data
poll file_data
sync file_data
lock file_data
unlock file_data
dmaCopy
jmp label
