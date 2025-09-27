# nano-z80
Z80 based SoC for the [Tang Nano 20k FPGA Board](https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/nano-20k.html) which is currently a work in progress. It reuses many IP-blocks from my [nano6502](https://github.com/venomix666/nano6502/) project which is very similar but is built around a 6502-core instead of a Z80.

Current features:
* 64 k RAM (currently implemented with block RAM)
* 8k ROM which can be switched out (also block RAM)
* SD card storage
* UART (on the built in USB-C connector)
* 80-column text mode HDMI video output, 640x480 60 Hz (current 80x30, will probably be changed to 80x24 for compatibility)
* USB keyboard support (with [nanoComp](https://github.com/venomix666/nanoComp/) carrier board)  
* Bidirectional GPIO on the header on the nanoComp carrier board
* Control of the LEDs on the Tang Nano 20k board
* Additional UART on carrier board UART header

Everything is clocked of the pixel clock, so the Z80-core is running at 25.175 MHz.

A port of David Given's [CP/Mish](https://github.com/venomix666/cpmish/tree/nanoZ80) is underway. It boots, but is still lacking some features and needs cleaning up.

The monitor in ROM is based on the [bsx](https://github.com/breakintoprogram/bsx) monitor.

 
  

