.set delay, 0x20A1200

.section .text
.globl _start
.globl main
.globl interrupt_service_routine
_start:
main:
	initialize_global_variables:
		li s0, 1				#easily accessible 1
		slli s1, s0, 11			#pin 11 output mask (0x800)
		li s2, 0x40000190		#output enable register ptr (GPIO_CFGCTL36???)
		li s3, 0x4000a500		#timer register base ptr (TIMER_CH0, aka Timer2)
		li s4, 0x02800800		#CLIC_HART0_ADDR +0x800 (points to the middle, to enable stores in 1 instruction (immediate field limitation))
	setup_led:
		lui t0, 0xB000			#pin 11 config setting
		sw t0, -0x7C(s2)		#configure pin 11 as output (blue led pin)(GPIO_CFGCTL5)
	setup_clic:
		sb s0, -0x3CC(s4)		#enable interrupt 36 (0x10(base) + 0x24(interrupt number)) (CLIC_INTIE[36])
		la t4, (interrupt_service_routine + 2)		#load address of interrupt_service_routine ([1:0] select CLIC/CLINT & vectored/direct modes)
		csrrw zero, mtvec, t4	#write trap handler address & trap mode to mtvec
	setup_timer_interrupt:
		li t5, delay
		sw t5, 0x10(s3)			#(TMR2_0)alarm value <-- 0x9896800 (160.000.000 cycles =~ 1 sec)(assumes 160Mhz)
		sw s0, 0x5c(s3)			#(TPLCR2) reload control <-- 1 (reload upon comparison match)
		sw s0, 0x44(s3)			#(TIER2) interrupt enable <-- 1 (enable interrupt generation)
		sw s0, 0x90(s3)			#(TILR2) interrupt mode <-- 1 (pulse interrupt)
		li t6, 2
		sw t6, 0x84(s3)			#(TCER) count enable <-- 2
		sw s1, 0(s2)			//turn led on
		waiting:
			wfi					#wait until timer interrupt occurs, the wait again
		j waiting

.balign 64
interrupt_service_routine:
	lw t0, 0(s2)
	xor t0, t0, s1
	sw t0, 0(s2)				#toggle led
	mret						#return to other code

/* HONORABLE MENTIONS:
0x02000000 #CLINT address

li t1, 0b********
sb t1, 0x400(s4) 			#configure global interrupt settings (CLIC_CFG) (configuring levels/priorities isn't needed here)
li t2, 0b********
sb t2, 0x34(s4) 			#configure interrupt signal source (CLIC_INTCFG) (configuring per interrupt level/priority isn't needed here)

sw zero, 0(s3)    			#timer clk source <-- 0 (master clock) (is default value)
sw zero, 0x88(s3)			#timer run mode <-- 0 (enable reload) (is default value)
sw zero, 0x50(s3) 			#reload value <-- 0 (is default value)
sw zero, 0xbc(s3) 			#clk prescaler <-- 0 (is default value)

sw s0, 0x78(s3)				#clear timer interrupt (not needed for edge triggered timer interrupt)
amoxor.w zero, s1, (s2)		#toggle led (amo not supported for this part of mmio as far as I can tell)

csrrsi zero, 0x300, 0b1000 	#set mstatus.mie (set by default)
csrrw zero, 0x304, s1 		#set mie.meie (inactive in CLIC mode)
*/

