.macro write addr, val
    li t0, \val
    li t1, \addr
    sw t0, (t1)
.endm

.macro writer addr, reg
    li t0, \addr
    sw \reg, (t0)
.endm

.macro read addr, reg
    li t0, \addr
    lw \reg, (t0)
.endm

.macro set mask, reg
    li t0, \mask
    or \reg, \reg, t0 
.endm

.macro clear mask, reg
    li t0, ~(\mask)
    and \reg, \reg, t0 
.endm

.macro led
    //turn on the blue led on the pinecone
    write 0x40000114, 0xB000000
    write 0x40000190, 1<<11
.endm

.macro cease
    //halt the cpu
    .word 0x30500073
.endm

//constants
.equ gpio_10_11_configuration, 0x08060B00
.equ pwm_config, 1 | 1 << 2                     #select bclk as source, invert output (because blue led on pinecone evb is active low)
.equ pwm_clock_divider, 1 - 1
.equ period, 256
.equ threshold1, 0
.equ threshold2, 256

//registers
.equ GPIO_CFGCTL5, 0x40000114
.equ pwm_base_addr, 0x4000A400
.equ pwm1_clkdiv, pwm_base_addr + 0x40
.equ pwm1_thre1, pwm_base_addr + 0x44
.equ pwm1_thre2, pwm_base_addr + 0x48
.equ pwm1_period, pwm_base_addr + 0x4C
.equ pwm1_config, pwm_base_addr + 0x50
.equ pwm1_interrupt, pwm_base_addr + 0x54

//code
.section .text
.globl _start
.globl main
_start:
main:
//gpio setup
    //set pin 11 to pwm channel1
    write GPIO_CFGCTL5, gpio_10_11_configuration
//clock setup
    //set channel 1 source to bclk
    write pwm1_config, pwm_config
    //set channel 1 clock divider
    write pwm1_clkdiv, pwm_clock_divider
//timing setup
    //set channel 1 period
    write pwm1_period, period
    //set channel 1 period
    write pwm1_thre1, threshold1
    //set channel 1 period
    write pwm1_thre2, threshold2

//fade led in and out by incrementing/decrementing threshold1 in a loop changing the duty cycle
    li t1, 0
    li s0, 1
    negate_increment:
        neg s0, s0          
    loop:
        add t1, t1, s0
        andi t1, t1, 0xFF
        writer pwm1_thre1, t1
        jal delay
        beqz t1, negate_increment
        j loop
//function for waiting
    delay:
            lui t0, 0x20
        spin:
            addi t0, t0, -1
            blt zero, t0, spin
        ret

/*notes:
    the clock block diagram in the bl602 reference manual depicts inaccurate information about the PWM clock:
        1. Each of the 5 PWM channels have their own independent clock source selection (reg_clk_sel field in pwm*_config registers)
        2. Each of the 5 PWM channels have their own independent clock divider (pwm*_clkdiv registers)
        3. There don't to be enable bits for the 5 PWM channels' clocks
*/