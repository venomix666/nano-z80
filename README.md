# nano-z80
Z80 based SoC for the [Tang Nano 20k FPGA Board](https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/nano-20k.html) which is designed to run CP/M. It reuses many IP-blocks from my [nano6502](https://github.com/venomix666/nano6502/) project which is very similar but is built around a 6502-core instead of a Z80.

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

A port of David Given's [CP/Mish](https://github.com/venomix666/cpmish/tree/nanoZ80) gives a very nice CP/M 2.2 environment for this computer.

## Gettings started

### Set up PLL
In order to set up the external PLL on the Tang Nano 20K for generation of the 25.175 MHz video clock and the 12 MHz USB clock, do the following:
* Open a serial terminal connection to the board
* Press Ctrl+x, Ctrl+c, enter
* Enter the command: `pll_clk O0=25175K -s`
* Enter the command: `pll_clk O1=12M -s`
* Enter the command: `reboot`

### Program the FPGA
If you don't want to synthesize the project yourself, you can download the [bitstream file](https://github.com/venomix666/nano-z80/releases/latest/download/nano-z80.fs) and program it to the FPGA configuration flash memory using [openFPGAloader](https://github.com/trabucayre/openFPGALoader):  
```console
openFPGAloader -b tangnano20k -f ./nano6502.fs
```
### Prepare the SD card
Write the [nano6502.img](https://github.com/venomix666/nano-z80/releases/latest/download/nano-z80.img) file into the SD-card using `dd` or your preferred SD-card image writer. 

## Peripherals and IO model
In order to maximize the amount of available IO ports, a simple banked IO model is used.   
The IO select register (port 0x7f) performs banking of the IO ports and can be set to the following values:  
0x00: LED control selected  
0x01: GPIO selected
0x02: USB selected  
0x03: SD card control selected.  
0x04: Video control selected.  
0x05: UART selected.  

In addition to the banked port, the following ports are always available:  
0x70: UART A TX data  
0x71: UART A TX ready  
0x72: UART A RX data  
0x73: UART A RX available  
0x74: Keyboard data available   
0x75: Keyboard data  
0x76: Video TTY data write  
0x77: Video TTY busy  

### Known bugs
* Direct writing / reading to the video memory is glitchy due to some timing issue in the FPGA.

### Credits
Some parts in this project are reused from other projects:  
The 6502 Core used is [Arlet's 6502 core](https://github.com/Arlet/verilog-6502) with [65C02 instruction extension](https://github.com/hoglet67/verilog-6502)   
The low-level SD-card state-machine is reused from [MiSTeryNano](https://github.com/harbaum/MiSTeryNano/)  
The USB HID host core was made by [nand2mario](https://github.com/nand2mario/usb_hid_host/)  
The font used is from this [romfont](https://github.com/spacerace/romfont) repository  




The monitor in ROM is based on the [bsx](https://github.com/breakintoprogram/bsx) monitor.

 
  

