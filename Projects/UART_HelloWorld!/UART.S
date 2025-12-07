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

//set UART clock source
#    li t4, 0xAA0A0020                       //hbn_uart_clk_sel=0
#    sw t4, 0x30(s2)                         //HBN_GLB

//enable uart clk and set clock divider
#    li t3, 0xFF8F2B10                       //UARTEN=1, UARTDIV=0
#    sw t3, 0x8(s1)                          //clk_cfg2

//set baud 115200 through bit period
    li t2, magic_number                     //TBITPRD=magic number (see end of file)
    sw t2, 0x8(s0)                          //uart_bit_prd

//disable all UART interrupts
#    sw zero, 0x24(s0)                       //uart_int_mask=0

//load UART start/stop constants
    li x4, 0x00002714                       //start constant
    ori x3, x4, 1                           //stop constant

//load the character constants into registers
    li s1, 'H'                              //load char 'H'
    li s2, 'e'                              //load char 'e'
    li s3, 'l'                              //load char 'l'
    li s4, 'o'                              //load char 'o'
    li s5, ' '                              //load char ' '
    li s6, 'W'                              //load char 'W'
    li s7, 'r'                              //load char 'r'
    li s8, 'd'                              //load char 'd'
    li s9, '!'                              //load char '!'
    li s10, '\r'                            //load char '\r'
    li s11, '\n'                            //load char '\n'

//push string "Hello World!\r\n" byte by byte into uart tx FIFO
print:
    sw x3, 0(s0)                            //start transmission
//transmit these bytes
    sb s1, 0x88(s0)                         
    sb s2, 0x88(s0)
    sb s3, 0x88(s0)
    sb s3, 0x88(s0)
    sb s4, 0x88(s0)
    sb s5, 0x88(s0)
    sb s6, 0x88(s0)
    sb s4, 0x88(s0)
    sb s7, 0x88(s0)
    sb s3, 0x88(s0)
    sb s8, 0x88(s0)
    sb s9, 0x88(s0)
    sb s10, 0x88(s0)
    sb s11, 0x88(s0)

//wait a bit for transmission to finish
    li a6, 0x4000                           //wait so the tx fifo doesn't overflow
    loop0:
        addi a6, a6, -1
        blt zero, a6, loop0

//stop transmission
    sw x4, 0(s0)

//wait a bit before starting next transmission
    li a6, 0xA00000
    loop1:
        addi a6, a6, -1
        blt zero, a6, loop1
j print                                     //restart transmission



//things I commented out are configured how we want them by default or have no impact on whether it works or not

/*magic number: 
    -found by trial and error 
    -strangely indicates that UART source clock=~34.2Mhz:
        -roughly 2000000Hz off from the closest clock source mentioned in the reference manual 
    -please enlighten me
*/
