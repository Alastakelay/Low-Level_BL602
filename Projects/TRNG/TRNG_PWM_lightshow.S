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
//halt the cpu (custom hcf (halt and catch fire) instruction from sifive)
    .word 0x30500073
.endm

//constants
.equ gpio_10_11_configuration, 0x08060B00
.equ gpio_14_15_configuration, 0x0B030806
.equ gpio_16_17_configuration, 0x08060B03
.equ pwm_config, 1 | 1 << 2                     #select bclk as source, invert output (because blue led on pinecone evb is active low)
.equ pwm_clock_divider, 1 - 1
.equ period, 256
.equ threshold1, 0
.equ threshold2, 256

//GPIO registers
.equ GPIO_CFGCTL5, 0x40000114
.equ GPIO_CFGCTL7, 0x4000011C
.equ GPIO_CFGCTL8, 0x40000120

//pwm registers
.equ pwm_base_addr, 0x4000A400
.equ pwm1_clkdiv, pwm_base_addr + 0x40
.equ pwm1_thre1, pwm_base_addr + 0x44
.equ pwm1_thre2, pwm_base_addr + 0x48
.equ pwm1_period, pwm_base_addr + 0x4C
.equ pwm1_config, pwm_base_addr + 0x50
.equ pwm1_interrupt, pwm_base_addr + 0x54
.equ pwm2_clkdiv, pwm_base_addr + 0x60
.equ pwm2_thre1, pwm_base_addr + 0x64
.equ pwm2_thre2, pwm_base_addr + 0x68
.equ pwm2_period, pwm_base_addr + 0x6C
.equ pwm2_config, pwm_base_addr + 0x70
.equ pwm2_interrupt, pwm_base_addr + 0xB4
.equ pwm4_clkdiv, pwm_base_addr + 0xA0
.equ pwm4_thre1, pwm_base_addr + 0xA4
.equ pwm4_thre2, pwm_base_addr + 0xA8
.equ pwm4_period, pwm_base_addr + 0xAC
.equ pwm4_config, pwm_base_addr + 0xB0
.equ pwm4_interrupt, pwm_base_addr + 0xB4

//TRNG registers
.equ SEC_ENG_base_address, 0x40004000
.equ se_trng_0_ctrl_0, SEC_ENG_base_address + 0x200
.equ se_trng_0_status, SEC_ENG_base_address + 0x204
.equ se_trng_0_dout_0, SEC_ENG_base_address + 0x208

//code
.section .text
.globl _start
.globl main
_start:
main:
//GPIO setup
    //set pin 11 to pwm channel 1
    write GPIO_CFGCTL5, gpio_10_11_configuration
    //set pin 14 to pwm channel 4
    write GPIO_CFGCTL7, gpio_14_15_configuration
    //set pin 17 to pwm channel 2
    write GPIO_CFGCTL8, gpio_16_17_configuration
//PWM setup
    //clock setup
        //set channel sources to bclk
        write pwm1_config, pwm_config
        write pwm2_config, pwm_config
        write pwm4_config, pwm_config
        //set channel clock dividers
        write pwm1_clkdiv, pwm_clock_divider
        write pwm2_clkdiv, pwm_clock_divider
        write pwm4_clkdiv, pwm_clock_divider
    //set periods
    write pwm1_period, period
    write pwm2_period, period
    write pwm4_period, period
    //set threshold1s
    write pwm1_thre1, threshold1
    write pwm2_thre1, threshold1
    write pwm4_thre1, threshold1
//initialize trng
    jal trng_init
//set random color on the rgb led of the pinecone using PWM
    lightshow:
        jal get_rand_int
        andi t1, a0, 0xFF
        writer pwm1_thre2, t1
        srli a0, a0, 8
        andi t1, a0, 0xFF
        writer pwm2_thre2, t1
        srli a0, a0, 8
        andi t1, a0, 0xFF
        writer pwm4_thre2, t1
        delay:
            lui t0, 0xA00
        loop:
            addi t0, t0, -1
            blt zero, t0, loop
    j lightshow

//wait intil the TRNG busy flag is cleared
    wait_until_trng_not_busy:
    //wait the busy flag is latched (it's not latched right away, so if you read se_trng_0_ctrl_0 right away after enabling or triggering trng it will appear not busy)
        nop
        nop
        nop
        nop
    //wait until busy flag is cleared
        busycheck:
            read se_trng_0_ctrl_0, t0
            andi t0, t0, 1
            bnez t0, busycheck
    ret

//initialize trng
    trng_init:
        mv s6, ra
        //enable trng
        read se_trng_0_ctrl_0, t1
        set 1 << 2, t1
        writer se_trng_0_ctrl_0, t1
        //wait until not busy
        jal wait_until_trng_not_busy
        mv ra, s6
    ret

//get random dataword
    get_rand_int:
        mv s6, ra
        jal trigger_trng
        jal wait_until_trng_not_busy
        read se_trng_0_dout_0, a0
        mv ra, s6
    ret

//trigger trng generation
    trigger_trng:
        read se_trng_0_ctrl_0, t1
        set 1 << 1, t1
        writer se_trng_0_ctrl_0, t1
    ret

/*notes:
    I was told you don't need to aquire access to trng by writing se_trng_0_ctrl_prot to use the trng (it's optional)
    It's stupid that the busy flag isn't set right away after writing to se_trng_0_ctrl_0
    Also a little confusing that you are required to [enable TRNG -> wait until not busy -> trigger TRNG -> wait again] to get your random numbers
    Overall not the worst bl602 internal I had to deal with
    Also big thanks to the maintainers of zephyr's entropy_bflb_sec_eng.c, whose code I, more, or less, copied. =)
*/
