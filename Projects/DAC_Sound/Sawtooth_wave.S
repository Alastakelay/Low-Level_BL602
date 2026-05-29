.section .text
.globl _start
.globl main
_start:
main:
//global vars and mmio pointers
	li gp, 0x40000000                       //GLB pointer
    li s1, 0x40001000                       //RF pointer
    li s0, 0x40002000                       //ANALOG pointer
//le debugging ____________________________________________________________________________________________________________________________
    #li t0, 0xB000000 #blue led config setting
    #sw t0, 0x114(gp) #cfg blue led
    #li s11, 1<<11 #blue output mask
    #sw s11, 0x190(gp) #turn blue led on
//le debugging ____________________________________________________________________________________________________________________________
//configure GPIO14 as DAC channel b
    //reg: GPIO_CFGCTL7
    lw t0, 0x11C(gp)
    srli t0, t0, 16
    slli t0, t0, 16
    li t1, 0x0A00                           //reg_gpio_14_func_sel=GPIP_CH2(0xA)
    or t0, t0, t1
    sw t0, 0x11C(gp)
//set up dac_clk (apparently this doesn't do anything)
    //reg: adda1
    #lw t0, 0x08C(s1)
    #andi t0, t0, ~0x300
    #ori t0, t0, 0x000           #dac_clk_sel=0
    #sw t0, 0x08C(s1)
    //reg: DIG32K_WAKEUP_CTRL
    lw t0, 0x0A8(gp)
    li t1, 0xEC80FFFF
    and t0, t0, t1
    li t1, 0x103E0000           #dig_512k_div = 32MHz/512KHz, dig_clk_src_sel=1
    or t0, t0, t1
    sw t0, 0x0A8(gp)
    li t1, 0x01000000           //dig_512k_en=1, dig_512k_comp=0
    or t0, t0, t1
    sw t0, 0x0A8(gp)
//pull up dac (this probably has no effect)
    //reg: pucr1
    #lw t0, 0x030(s1)
    #li t1, 1<<19
    #or t0, t0, t1
    #sw t0, 0x030(s1)
//reset dac channel b
    //reg: gpdac_ctrl
    lw t0, 0x308(gp)
    andi t0, t0, ~0b10
    sw t0, 0x308(gp)
    jal noop
    ori t0, t0, 0b10
    sw t0, 0x308(gp)
    jal noop
//initialise dac channel b
    //reg: gpdac_bctrl
    lw t0, 0x310(gp)
    ori t0, t0, 0b11
    sw t0, 0x310(gp)
//configure dac
    //reg: gpdac_config
    li t0, 0b10
    sw t0, 0x040(s0)
//alternate highest and lowest analog value on channel b
    //reg: gpdac_data
    li t0, 0
    loop:
    addi t0, t0, 1
    andi t0, t0, 0x3FF
    sw t0, 0x314(gp)
    li a0, 0xF
    jal delay
    j loop
cease: .word 0x30500073
noop:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
ret

delay:
    addi a0, a0, -1
    blt zero, a0, delay
ret
/*register behavior:
    pucr1 & pucr1_hw:
        I can set bits in pucr1, but they aren't mirrored to pucr1_hw regardless of how long I wait. trsw_en is set by default in pucr1, and only pu_sfreg_hw is set in pucr1_hw
    adda1:
        dac_clk_sel can be set to 0b00, 0b01, 0b10 & 0b11, suggesting that is selects between 4 source clocks
    GPIO_CFGCTL7:
        reg_gpio_14_smt=1 (not sure if this is right, but the drivers have it that way), reg_gpio_14_drv needs to be set to either 1 or two
*/
