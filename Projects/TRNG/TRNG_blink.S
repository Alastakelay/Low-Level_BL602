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

//IO registers
.equ GPIO_CFGCTL5, 0x40000114
.equ pwm_base_addr, 0x4000A400
.equ pwm1_clkdiv, pwm_base_addr + 0x40
.equ pwm1_thre1, pwm_base_addr + 0x44
.equ pwm1_thre2, pwm_base_addr + 0x48
.equ pwm1_period, pwm_base_addr + 0x4C
.equ pwm1_config, pwm_base_addr + 0x50
.equ pwm1_interrupt, pwm_base_addr + 0x54
//TRNG registers
.equ SEC_ENG_base_address, 0x40004000
.equ se_trng_0_ctrl_0, SEC_ENG_base_address + 0x200
.equ se_trng_0_status, SEC_ENG_base_address + 0x204
.equ se_trng_0_dout_0, SEC_ENG_base_address + 0x208
.equ se_trng_0_dout_1, SEC_ENG_base_address + 0x20C
.equ se_trng_0_dout_2, SEC_ENG_base_address + 0x210
.equ se_trng_0_dout_3, SEC_ENG_base_address + 0x214
.equ se_trng_0_dout_4, SEC_ENG_base_address + 0x218
.equ se_trng_0_dout_5, SEC_ENG_base_address + 0x21C
.equ se_trng_0_dout_6, SEC_ENG_base_address + 0x220
.equ se_trng_0_dout_7, SEC_ENG_base_address + 0x224
.equ se_trng_0_ctrl_3, SEC_ENG_base_address + 0x234

//code
.section .text
.globl _start
.globl main
_start:
main:
//set up LEDs
        li s0, 0x40000000 #gbl register base addr
        li t0, 0xB000000 #blue led config setting
        sw t0, 0x114(s0) #cfg blue led
        sw t0, 0x120(s0) #cfg red led
        srli t0, t0, 16 #green led config setting
        sw t0, 0x11c(s0) #cfg green led
        li s1, 1<<11 #blue output mask
        li s2, 1<<14 #green output mask
        li s3, 1<<17 #red output mask
//trng
    //enable ring oscillator                #already on
        #read se_trng_0_ctrl_3, t1
        #set 1 << 31, t1
        #writer se_trng_0_ctrl_3, t1
    //enable trng
        read se_trng_0_ctrl_0, t1
        set 1 << 2, t1
        writer se_trng_0_ctrl_0, t1
    //clear interrupt
        #read se_trng_0_ctrl_0, t1
        #set 1 << 9, t1
        #writer se_trng_0_ctrl_0, t1
    //wait until not busy
        jal wait_until_trng_not_busy
    //clear interrupt again
        #read se_trng_0_ctrl_0, t1
        #set 1 << 9, t1
        #writer se_trng_0_ctrl_0, t1
    //trigger trng generation
        read se_trng_0_ctrl_0, t1
        set 1 << 1, t1
        writer se_trng_0_ctrl_0, t1
    //wait until not busy
        jal wait_until_trng_not_busy
    //output all the random bytes
        read se_trng_0_dout_0, a0
        jal blink_digits
        read se_trng_0_dout_1, a0
        jal blink_digits
        read se_trng_0_dout_2, a0
        jal blink_digits
        read se_trng_0_dout_3, a0
        jal blink_digits
        read se_trng_0_dout_4, a0
        jal blink_digits
        read se_trng_0_dout_5, a0
        jal blink_digits
        read se_trng_0_dout_6, a0
        jal blink_digits
        read se_trng_0_dout_7, a0
        jal blink_digits
        cease
//function to wait intil the TRNG busy flag is cleared
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

//function to blink through the digits of a0
    blink_digits:
        andi t0, a0, 1
        bne zero, t0, blink1
        sw s3, 0x190(s0)
        j delay
        blink1:
            sw s2, 0x190(s0)
        delay:
            lui t0, 0x2000
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

/*notes:
    I was told you don't need to aquire access to trng by writing se_trng_0_ctrl_prot to use the trng (it's optional)
    It's stupid that the busy flag isn't set right away after writing to se_trng_0_ctrl_0
    Also a little confusing that you are required to [enable TRNG -> wait until not busy -> trigger TRNG -> wait again] to get your random numbers
    Overall not the worst bl602 internal I had to deal with
    Also big thanks to the maintainers of zephyr's entropy_bflb_sec_eng.c, whose code I, more, or less, copied. =)
*/
