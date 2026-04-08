/*
    Description:
        This is a small code example for manually driving SSD1306/SSD1315 display modules using the I²C peripheral of the BL602 (no DMA involved)
        You're supposed to see a moving pattern on the screen.
        If you don't, try using 0x3D instead of 0x3C as I²C slave address, and verify that your SCL is connected to gpio0 and SDA to gpio1
        Feel free to tinker with it, I went through a lot of trial and error to get this to work
*/

//Register usage:
    //gp  = GPIO base (0x40000000)
    //s0  = peripheral base (0x4000A000)
    //s1  = i2c_int_sts enable/mask/clear mask (preserved across ISR)

.equ GPIOConfigurationMask, 0x06010601    //pin function=I2C, Input=enabled
.equ I2CConfigCode8B, 0x00073C09   //transfer byte length=8, slave addr=0x3C, direction=write, enable=1
.equ I2CConfigCode6B, 0x00053C09   //transfer byte length=6, slave addr=0x3C, direction=write, enable=1
.section .text
.globl _start
.globl main
_start:
main:
//GPIO0(SCL) + GPIO1(SDA)
    lui gp, 0x40000     //load global base address
    lui s0, 0x4000A     //load base address of peripherals
    li t0, GPIOConfigurationMask
    sw t0, 0x100(gp)    //GPIO_CFGCTL0
//I²C clock setup
    lw t0, 0xC(gp)
    andi t0, t0, 0b111111111
    lui t1, 0x01070     //I²C clock divider=7 --> i2c_clk = 32MHz/8 = 4MHz
    or t0, t0, t1
    sw t0, 0xC(gp)      //clk_cfg3
//enable I²C interrupts, unmask transfer end interrupt, and clear interrupts
    li s1, 0x3F193E00   //0x3F=enable mask, 0x19=clear mask, 0x3E=masking mask
    sw s1, 0x304(s0)    //i2c_int_sts
//configure I²C interrupts
    lui t1, 0x2800
    li t0, 1
    sb t0, 0x430(t1)								//clicIntIE_48      (enable interrupt 32 in CLIC)
	lla t0, (interrupt_service_routine + 0b10)		//load address of interrupt_service_routine ([1:0] select CLIC/CLINT & vectored/direct modes)
	csrrw zero, mtvec, t0							//write trap handler address & trap mode to mtvec
//set up periods    (periods and I²C peripheral source clock are set for 100KHz I²C transmission)
    li t0, 0x09090909
    sw t0, 0x310(s0)    //i2c_prd_start
    sw t0, 0x314(s0)    //i2c_prd_stop
    sw t0, 0x318(s0)    //i2c_prd_data
//clear FIFOs
    li t0, 0b1100
    sw t0, 0x380(s0)    //i2c_fifo_config_0
//populate fifo
    li t0, 0xAF148D00
    sw t0, 0x388(s0)    //i2c_fifo_wdata
    li t0, 0x0020
    sw t0, 0x388(s0)    //i2c_fifo_wdata
//configure and start transmission
    li t0, I2CConfigCode6B
    sw t0, 0x300(s0)    //i2c_config
//wait for transmission finish successfully
    wfi
draw:
//populate fifo
    li t0, 0x55555540   //feed continuous display data
    sw t0, 0x388(s0)    //i2c_fifo_wdata
    li t0, 0x33333333
    sw t0, 0x388(s0)    //i2c_fifo_wdata
//configure and start transmission
    li t0, I2CConfigCode8B
    sw t0, 0x300(s0)    //i2c_config
    wfi
    j draw
    
//CLIC vectored mode requires handler to be aligned to 64 bytes
.balign 64
//clear interrupt, blink, clear configuration, and continue if NACK is absent
interrupt_service_routine:
    lw t0, 0x304(s0)
    sw s1, 0x304(s0)    //i2c_int_sts
    andi t0, t0, 0b1000
    bnez t0, cease
    sw zero, 0x300(s0)  //i2c_config
    mret
//BL602/SiFive-specific: encodes "cease" (core halt), no mnemonic available in standard RV32I assembler
cease: .word 0x30500073

/* considerations:
    required:
        set input_enable bits for the I²C pins  #I don't understand why it's necessary to set the input enable bit for the I²C pin functions, but not the output enable bit. I thought that was just for software inputs
    optional:
        set output_enable bits for the I²C pins
        set pullup bits for the I²C pins
*/
