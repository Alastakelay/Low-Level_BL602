# Interrupt driven Blinky
> The purpose of this code is to teach people how to configure interrupts on the bl602  
> (The same priciples may or may not apply also for the bl604 and other single-core RISC-V Bouffalo Lab chips)  

## Timer Interrupts:
The most efficient way for software on a microcontrolle to make an led blink is *usually* a timer **interrupt**-driven toggling.  
That means we tell the chip to set a **timer** for 1 second after which we toggle the state of the led.  
The timer gets reset, and counts to 1 second again.  
The result is that the led switches from on to off and vice versa every second resulting in a steady blinking.

Now the advantage of using a timer to generate a periodic alarm is that the hart,  
or core, is free to do other computations while the timer is counting up to the desired value.  

In contrast to what we call "busy waiting" interrupt driven waiting doesn't waste millions of clock cycles to do the job of the timer peripheral. It is thus advantageous to be used in performance critical applications.
>Generating the same waveform required to make an led blink could also be realized by the PWM peripheral, at least theoretically, but I haven't tested it out yet, so idk  

Interrups are asynchronous external events which, when enabled, can make a trap occur/**interrupt** the core in its current execution and make it execute some other code.

## Implementation in the BL602:
In our beloved BL602 interrupts are managed and routed through the CLIC (**C**ore **L**ocal **I**ntererupt **C**ontroller) to the hart
> The BL602 is based on a lot of SiFive's IP (**I**ntellectual **P**roperty)  

> There's also the CLINT (**C**ore **L**ocal **INT**ereruptor) but we don't really need to use it here, and I don't know how to  

## Memory mapping of the peripherals:
Peripherals like Timer0, CLIC, and GPIO can be controlled, configured, and read by the cpu through MMIO  
> "That's all embedded programming is,
>  it's programming where, magic address, when you write to it, has a side effect" ~[Low Level](https://www.youtube.com/@LowLevelTV)

For some MMIO registers only fullword loads and stores (lw/sw) seem to be legal (Idk if they trigger exceptions)
Atomic operations (part of the "A" extension) may also not be valid for those registers

### Base addresses:
**CLIC**:  `0x02800000`  
**Timer**: `0x4000A500`  
**GLB**:`0x40000000`  

## Documentation of the peripherals:
The timers are documented ok in the RM, but description of the GPIO isn't very detailed and CLIC is omitted entirely by the OEM in any of their docs.  
I provided links to reliable sources in the [main readme file](https://github.com/Alastakelay/Low-Level_BL602/blob/main/README.md)

## Notes about [Blinky_with_CLIC.S](https://github.com/Alastakelay/Low-Level_BL602/blob/main/Projects/Interrupt_driven_blinky/Blinky_with_CLIC.S)
> I wrote this code on my own with the occasional help of an LLM
> (which didn't write any parts of the aforementioned program, but rather helped me understand)
### **Warning**:
>It is possible that the way this code drives ***may reduce lifespan***, since it is active low and this code doen't configure a pullup resistor  
>and switches it on simply by enabling its respective output instead of changing the output value (I'm **not** an electrical engineer, so idk)

I tried my best to keep the code as readable as I could, but still **prioritized performance**.
If you have any good suggestions for improving the code or this accompanying readme, please open up an issue
