//pipe the raw serial stream into a .bin file to dump the ROM
.equ magic_number, 0x128
.section .text
.globl _start
.globl main

_start:
main:
//global vars and mmio pointers
    li s0, 0x4000A000                       //UART0 pointer
    li s1, 0x40000000                       //GLB pointer
    li s2, 0x4000F000                       //HBN pointer

//tie gpio16 to UART SIG0
    li t6, 0x0E030710                       //gpio_func_sel=7
    sw t6, 0x120(s1)                        //GPIO_CFGCTL8

//map SIG0 (GPIO16) to UART0_TXD function
    li t5, 0x76543212                       //uart_sig_0_sel=2
    sw t5, 0xC0(s1)                         //UART_SIG_SEL_0

//set baud 115200 through bit period
    li t2, magic_number                     //TBITPRD=magic number (see end of file)
    sw t2, 0x8(s0)                          //uart_bit_prd

//load UART start constant
    li x3, 0x00002715
//start transmission
    sw x3, 0(s0)
//base address
    li s3, 0x21000000
//last address
    li s5, 0x2101FFFF
//transmits the ROM in raw over UART (should take < 10min)
transmit:
    lb s6, 0(s3)
    sb s6, 0x88(s0)
    bge s3, s5, cease
    addi s3, s3, 1

//wait a bit for transmission to finish
    li a6, 0x4000                           //wait so the tx fifo doesn't overflow (reduce delay at your own RISC)
    delay:
        addi a6, a6, -1
        blt zero, a6, delay
j transmit                                  //restart transmission
//powerdown cpu
cease: .word 0x30500073