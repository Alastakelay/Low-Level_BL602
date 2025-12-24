.section .text
.globl _start
.globl main
.globl blink_digits
_start:
main:
    setup_leds:
        li s0, 0x40000000 #gbl register base addr
        li t0, 0xB000000 #blue led config setting
        sw t0, 0x114(s0) #cfg blue led
        sw t0, 0x120(s0) #cfg red led
        srli t0, t0, 16 #green led config setting
        sw t0, 0x11c(s0) #cfg green led
        li s1, 1<<11 #blue output mask
        li s2, 1<<14 #green output mask
        li s3, 1<<17 #red output mask

    test:
    //put value to be displayed in a0
        //your code here
        jal blink_digits
    //powerdown cpu
        cease: .word 0x30500073
// blinks through the digits from msb to highest set 1 bit. gree=1, red=0 & blue=end of number
blink_digits:
    andi t0, a0, 1
    bne zero, t0, blink1
    sw s3, 0x190(s0)
    j delay
    blink1:
        sw s2, 0x190(s0)
    delay:
        lui t0, 0xA00
    loop:
        addi t0, t0, -1
        blt zero, t0, loop
    sw x0, 0x190(s0)
    lui t0, 0x800
    loop1:
        addi t0, t0, -1
        blt zero, t0, loop1
    srli a0, a0, 1
    beq zero, a0, end
    j blink_digits
    end:
    sw s1, 0x190(s0)
    lui t0, 0x4000
    loop2:
        addi t0, t0, -1
        blt zero, t0, loop2
    sw x0, 0x190(s0)
    ret

/*test results
fclk=~34214400???
mvendorid=0x489 (SiFive’s JEDEC number)
marchid=0x80000002 (E2/S2-Series Processor)
mimpid=0x20190919 (used generator: 19.08p0p0 / 19.08.00)
mheartid=0x00000000 (hart0)
misa=0b40801125 (RV32IMAFCX)
RX=GPIO7
TX=GPIO16
sp=0x42043F70 (WRAM_base_addr + 0x13F70)
gp=0x42044400
tp=0x5DACCADC
fp=0x40000000 (GLB registers)
ra=0x2100F0B4 (Inside ROM)
*/