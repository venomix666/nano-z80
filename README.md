# nano-z80
Z80 based SoC for the [Tang Nano 20k FPGA Board](https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/nano-20k.html) which is designed to run CP/M. It reuses many IP-blocks from my [nano6502](https://github.com/venomix666/nano6502/) project which is very similar but is built around a 6502-core instead of a Z80.

Current features:
* 8192 k RAM, banked in four 16k banks
* 8k ROM which can be switched out (also block RAM)
* SD card storage
* UART (on the built in USB-C connector)
* 80-column text mode HDMI video output, 640x480 60 Hz (80x30 characters)  
* USB keyboard support (with [nanoComp](https://github.com/venomix666/nanoComp/) carrier board)  
* Bidirectional GPIO on the header on the nanoComp carrier board
* Control of the LEDs on the Tang Nano 20k board
* Additional UART on carrier board UART header

Everything is clocked of the pixel clock, so the Z80-core is running at 25.175 MHz.

A port of David Given's [CP/Mish](https://github.com/davidgiven/cpmish) gives a very nice CP/M 2.2 environment for this computer. See the [cpmish page](https://github.com/davidgiven/cpmish/blob/master/arch/nano-z80/README.md) for more details. Here are some screenshots:

<img src="https://github.com/user-attachments/assets/8a74a47b-7cd5-410c-bc62-b158b1f7f0e4" width=320>
<img src="https://github.com/user-attachments/assets/3edb0d60-d8a0-4273-ac66-0d46e5ade73b" width=320>
<img src="https://github.com/user-attachments/assets/b4cd34e4-e134-46d5-9724-2d2eaca2829b" width=320>
<img src="https://github.com/user-attachments/assets/0e108a81-7ccb-4e55-ad49-cf99b76fd4ff" width=320>


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
openFPGAloader -b tangnano20k -f ./nano-z80.fs
```
### Prepare the SD card
Write the [nano-z80.img](https://github.com/venomix666/nano-z80/releases/latest/download/nano-z80.img) file into the SD-card using `dd` or your preferred SD-card image writer. 

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
0x60: MMU bank 0 LSB (8 bits) (0x0000-0x3FFF)  
0x61: MMU bank 0 MSB (1 bits) (0x0000-0x3FFF)  
0x62: MMU bank 1 LSB (8 bits) (0x4000-0x7FFF)  
0x63: MMU bank 1 MSB (1 bits) (0x4000-0x7FFF)  
0x64: MMU bank 2 LSB (8 bits) (0x8000-0xBFFF)  
0x65: MMU bank 2 MSB (1 bits) (0x8000-0xBFFF)  
0x66: MMU bank 3 LSB (8 bits) (0xC000-0xFFFF)  
0x67: MMU bank 3 MSB (1 bits) (0xC000-0xFFFF)  
0x70: UART A TX data  
0x71: UART A TX ready  
0x72: UART A RX data  
0x73: UART A RX available  
0x74: Keyboard data available   
0x75: Keyboard data  
0x76: Video TTY data write  
0x77: Video TTY busy
0x7e: ROM disable

### LED ports (0x7f == 0x00)
0x00:  LEDs - byte 0-6 connected to the on board LEDs  
0x01:  WS2812 Red - On board RGB led is automatically updated on write  
0x02:  WS2812 Green - On board RGB led is automatically updated on write  
0x03:  WS2812 Blue - On board RGB led is automatically updated on write  


### GPIO ports  (0x7f == 0x01)
0x00: Data register 1 (GPIO 0-7)  
0x01: Data register 2 (GPIO 8-12)  
0x02: Direction register 1 (GPIO 0-8), 0=Input, 1=Output  
0x03: Direction register 2 (GPIO 8-12), 0=Input, 1=Output  

### USB host registers (0x7f == 0x02)
0x00: New key available - clears on read  
0x01: Keypress ASCII data  
0x02: Key modifier  
0x03: Mouse button  
0x04: Mouse dX  
0x05: Mouse dY  
0x06: Gamepad direction {4'b0000, game_d, game_u, game_r, game_l}  
0x07: Gamepad buttons {2'b00, game_sta, game_sel, game_y, game_x, game_b, game_a}  
0x08: New USB report available - clears on read  
0x09: Device type - 0: no device, 1: keyboard, 2: mouse, 3: gamepad  
0x0a: USB error code  

### SD-card ports (0x7f == 0x03)
0x00:  SD card sector address (LSB)  
0x01:  SD card sector address  
0x02:  SD card sector address  
0x03:  SD card sector address (MSB)  
0x04:  SD card busy  
0x05:  SD card read strobe (write any value to initiate a sector read)  
0x06:  SD card write strobe (write any value to initiate a sector write)  
0x07:  Sector data page register (0-3), selects which 128 bytes of the sector are availabe on 0xfe80-0xfeff  
0x08:  SD card status (debug only)  
0x09:  SD card type (debug only)  
0x80 - 0xff: 128 byte data page, paged by the page register so that all 512 bytes can be accessed 

### Video/TTY ports (0x7f == 0x04)
0x00:  Active line - selects which line in memory that is available at 0xfe80  
0x01:  Cursor X position  
0x02:  Cursor Y position  
0x03:  Cursor visible  
0x04:  Scroll up strobe  
0x05:  Scroll down strobe  
0x06:  TTY write character  
0x07:  Busy flag - no registers can be changed when this is high  
0x08:  Clear to end-of-line strobe  
0x09:  Clear screen strobe
0x0a:  Clear to end-of-screen strobe  
0x0b:  Delete line strobe  
0x0c:  Insert line stribe  
0x0d:  TTY enabled  
0x0e:  Scrolling enabled  
0x10:  Foreground Red  
0x11:  Foreground Green  
0x12:  Foreground Blue  
0x13:  Background Red  
0x14:  Background Green  
0x15:  Background Blue  
0x80 - 0xff: Active line data, for direct access  

### UART ports (0x7f == 0x05)
0x00:  TX data UART A - write to initiate transmission  
0x01:  TX ready UART A - UART is ready to accept a new TX byte  
0x02:  RX data UART A   
0x03:  RX data available UART A - high if a new byte is available in RX data  
0x04:  TX data UART B - write to initiate transmission  
0x05:  TX ready UART B - UART is ready to accept a new TX byte  
0x06:  RX data UART B  
0x07:  RX data available UART B - high if a new byte is available in RX data  
0x08:  Baudrate UART B - 0: 4800, 1: 9600, 2: 19200, 3: 38400, 4: 57600, 5: 115200  

### Known bugs
* Direct writing / reading to the video memory is glitchy due to some timing issue in the FPGA.

### Credits
Some parts in this project are reused from other projects:  
The Z80 Core used is [TV80](https://github.com/hutch31/tv80)  
The low-level SD-card state-machine is reused from [MiSTeryNano](https://github.com/harbaum/MiSTeryNano/)  
The USB HID host core was made by [nand2mario](https://github.com/nand2mario/usb_hid_host/)  
The font used is from this [romfont](https://github.com/spacerace/romfont) repository  




The monitor in ROM is based on the [bsx](https://github.com/breakintoprogram/bsx) monitor.

 
  

