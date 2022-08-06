/*
  This program is a basic hello world program in stupid cpu assembly!
*/
string_to_display: "Hello World!\n"

main:
  mov currentDmaId, string_to_display
  mov copyDataSize, string_to_display
  mov copyDataSrcAddr, string_to_display
  mov copyDataDestAddr, 0x0000 ; First address in VRAM 1 contains text to output to a 80x20 terminal (for now)
  mov copyDataDmaDest, 0x0010 ; VRAM 1
  sync copyDataDmaDest
  dmaCopy ; Actually copies the data to the VRAM 
  lock currentDmaId
  sync currentDmaId ; Stops the program since the dma is locked by CPU and will never be released
