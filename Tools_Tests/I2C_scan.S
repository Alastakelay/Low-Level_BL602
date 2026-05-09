/*
    Description:
        This scans for I²C peripherals connected to GPIO0(scl) & GPIO1(sda) at 100KHz and echos hits over GPIO16(uart tx) at baud 115200
*/

//Register usage:
    //gp  = GPIO base (0x40000000)
    //s0  = peripheral base (0x4000A000)
    //s1  = i2c_int_sts enable/mask/clear mask (preserved across ISR)
    //s2  = i2c_config code 

.equ UARTMagicNumber, 0x128
.equ GPIOConfigurationMaskI2C, 0x06110611    //pin function=I2C, Input=enabled
.equ GPIOConfigurationMaskUART, 0x0E030710    //pin function=UART, Pullup=enabled
.equ I2CConfigCode1B, 0x00000009   //transfer byte length=8, slave addr=0x00, direction=write, enable=1
.equ UARTConfigCode, 0x00001715   //stop bit length=1 bit, character bit count=8, parity=even, freerun mode=1, enable=1
.section .text
.globl _start
.globl main
_start:
main:
//GPIO0(SCL) + GPIO1(SDA)
    li gp, 0x40000000                       //load global base address
    li s0, 0x4000A000                       //load base address of peripherals
    li t0, GPIOConfigurationMaskI2C
    sw t0, 0x100(gp)                        //GPIO_CFGCTL0
//GPIO16(UART_SIG0)
    li t0, GPIOConfigurationMaskUART        //gpio_func_sel=7
    sw t0, 0x120(gp)                        //GPIO_CFGCTL8
//map UART_SIG0 (GPIO16) to UART0_TXD function
    li t0, 0x76543212                       //uart_sig_0_sel=2
    sw t0, 0x0C0(gp)                        //UART_SIG_SEL_0
//set UART baud 115200 through bit period
    li t0, UARTMagicNumber                  //TBITPRD=magic number
    sw t0, 0x008(s0)                        //uart_bit_prd
//configure and start UART transmission
    li t0, UARTConfigCode
    sw t0, 0x000(s0)                        //utx_config
//I²C clock setup
    lw t0, 0x00C(gp)
    andi t0, t0, 0b111111111
    lui t1, 0x01070                         //I²C clock divider=7 --> i2c_clk = 32MHz/8 = 4MHz
    or t0, t0, t1
    sw t0, 0x00C(gp)                        //clk_cfg3
//load I²C interrupt mask & clear interrupts
    li s1, 0x3F193E00                       //0x3F=enable mask, 0x19=clear mask, 0x3E=masking mask
    sw s1, 0x304(s0)                        //i2c_int_sts
//configure I²C interrupts
    li t1, 0x02800000                       //Hart 0 CLIC Base
    li t0, 1
    sb t0, 0x430(t1)								//clicIntIE_48      (enable external interrupt 32 (I2C Interrupt) in CLIC)
	lla t0, (interrupt_service_routine + 0b10)		//load address of interrupt_service_routine ([1:0] select CLIC/CLINT & vectored/direct modes)
	csrw mtvec, t0							//write trap handler address & trap mode to mtvec
//set up periods    (periods and I²C peripheral source clock are set for 100KHz I²C transmission)
    li t0, 0x09090909
    sw t0, 0x310(s0)    //i2c_prd_start
    sw t0, 0x314(s0)    //i2c_prd_stop
    sw t0, 0x318(s0)    //i2c_prd_data
//clear FIFOs
    li t0, 0b1100
    sw t0, 0x380(s0)    //i2c_fifo_config_0
//load transmission configuration code
    li s2, I2CConfigCode1B
retransmit:
//populate fifo
    sw zero, 0x388(s0)    //i2c_fifo_wdata
//configure and start I²C transmission
    sw s2, 0x300(s0)    //i2c_config
//wait for transmission finish successfully
    wfi
    j retransmit
//BL602/SiFive-specific: encodes "cease" (core halt), no mnemonic available in standard RV32I assembler
cease: .word 0x30500073


//CLIC vectored mode requires handler to be aligned to 64 bytes
.balign 64
//clear interrupt, blink, clear configuration, and continue if NACK is absent
interrupt_service_routine:
    sw zero, 0x300(s0)  //wipe i2c_config
    lw t0, 0x304(s0)    //get interrupts
    sw s1, 0x304(s0)    //clear interrupts
    andi t0, t0, 0b1000 //check for nACK interrupt
    beqz t0, address_found
    addi s2, s2, 0x100  //increment I²C address
    li t0, 0x7FFF       //
    and s2, s2, t0      //
    mret
    address_found:
//print message
    lla t1, message
    puts_loop:
        lbu t0, 0x000(t1)
        beqz t0, print_bin_to_hex
        sb t0, 0x088(s0)
        addi t1, t1, 1
        j puts_loop
    print_bin_to_hex:
//print higher 3 address bits in hex
    srli t0, s2, 12     //get bits[14:12]
    addi t0, t0, 0x30   //adjust to ascii number
    sb t0, 0x088(s0)    //put char
//print lower 4 address bits in hex
    srli t0, s2, 8      //get bits[11:8]
    andi t0, t0, 0xF
    addi t0, t0, 0x30
    sltiu t1, t0, 0x3A  //is not A-F
    bnez t1, noadd
    addi t0, t0, 7      //':' -> 'A', ';' -> 'B', '<' -> 'C', '=' -> 'D', '>' -> 'E', '?' -> 'F', 
    noadd:
    sb t0, 0x088(s0)    //put char
//wait
    delay:
        lui t0, 0xA00
    loop:
        addi t0, t0, -1
        blt zero, t0, loop
    mret

message: .asciz "\n\rAddress found: 0x"