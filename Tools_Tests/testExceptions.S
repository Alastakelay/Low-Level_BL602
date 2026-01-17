.section .text
.globl _start
.globl main
.globl interrupt_service_routine
_start:
main:
	initialize_global_variables:
		li gp, 0x40000000								//Global pointer
        li s6, 0x42030000								//writable address in ram
	setup_led:
		li t0, 0xB000000 #blue_led_config_setting
        sw t0, 0x114(gp) #cfg_blue_led
        sw t0, 0x120(gp) #cfg red_led
        srli t0, t0, 16 #green_led config setting
        sw t0, 0x11c(gp) #cfg_green_led
        li s0, 1<<11 #blue_output_mask
        li s1, 1<<14 #green_output_mask
        li s2, 1<<17 #red_output_mask
	setup_clic:
		lla t4, (interrupt_service_routine + 0b10)		//load address of interrupt_service_routine ([1:0] select CLIC/CLINT & vectored/direct modes)
		csrrw zero, mtvec, t4							//write trap handler address & trap mode to mtvec
    test:
    //your code here to test whether something causes an exception

	waiting:
    //no exception ocurred --> white light
		or s0, s0, s1
        or s0, s0, s2
        sw s0, 0x190(gp)
        //powerdown_cpu
        cease: .word 0x30500073

.balign 64
//displays the number of the caused interrupt
interrupt_service_routine:
	csrr a0, mcause
    blink_digits:
        andi t0, a0, 1
        bne zero, t0, blink1
        sw s2, 0x190(gp)
        j delay
        blink1:
            sw s1, 0x190(gp)
        delay:
            lui t0, 0xA00
        loop:
            addi t0, t0, -1
            blt zero, t0, loop
        sw x0, 0x190(gp)
        lui t0, 0x800
        loop1:
            addi t0, t0, -1
            blt zero, t0, loop1
        srli a0, a0, 1
        beq zero, a0, end
        j blink_digits
        end:
        sw s0, 0x190(gp)
        lui t0, 0x4000
        loop2:
            addi t0, t0, -1
            blt zero, t0, loop2
        sw x0, 0x190(gp)
	mret												//return to other code
