.section .text
.globl _start
.globl main
.globl interrupt_service_routine
_start:
main:
	initialize_global_variables:
		li s0, 1										//easily accessible 1								//pin 11 output mask (0x800)
		li s1, 0x40000000								//Globl
		li s2, 0x02800800								//CLIC_HART0_ADDR +0x800 (points to the middle, to enable stores in 1 instruction (immediate field limitation))
        li s6, 0x42030000
	setup_led:
		li t0, 0xB000000 #blue led config setting
        sw t0, 0x114(s1) #cfg blue led
        sw t0, 0x120(s1) #cfg red led
        srli t0, t0, 16 #green led config setting
        sw t0, 0x11c(s1) #cfg green led
        li s3, 1<<11 #blue output mask
        li s4, 1<<14 #green output mask
        li s5, 1<<17 #red output mask
	setup_clic:
		sb s0, -0x3CC(s2)								//enable interrupt 36 (0x10(base) + 0x24(interrupt number)) (CLIC_INTIE[36])
		lla t4, (interrupt_service_routine + 0b10)		//load address of interrupt_service_routine ([1:0] select CLIC/CLINT & vectored/direct modes)
		csrrw zero, mtvec, t4							//write trap handler address & trap mode to mtvec
    test:
    //your code here to test whether something causes an exception

	waiting:
    //no exception ocurred --> white light
		or s3, s3, s4
        or s3, s3, s5
        sw s3, 0x190(s1)
        //powerdown cpu
        cease: .word 0x30500073

.balign 64
//displays the number of the caused interrupt
interrupt_service_routine:
	csrr a0, mcause
    bl_dig:
        andi t0, a0, 1
        bne zero, t0, blink1
        sw s5, 0x190(s1)
        j delay
        blink1:
            sw s4, 0x190(s1)
        delay:
            lui t0, 0xA00
        loop:
            addi t0, t0, -1
            blt zero, t0, loop
        sw x0, 0x190(s1)
        lui t0, 0x800
        loop1:
            addi t0, t0, -1
            blt zero, t0, loop1
        srli a0, a0, 1
        beq zero, a0, end
        j bl_dig
        end:
        sw s3, 0x190(s1)
        lui t0, 0x4000
        loop2:
            addi t0, t0, -1
            blt zero, t0, loop2
        sw x0, 0x190(s1)
	mret												//return to other code