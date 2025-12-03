.set delay, 0xAE0000		#~(fclk=~34.214400Mhz)/3cycles per loop
.section .text
.globl _start
.globl main

_start:
main:
	li t0, 0x40000100           #GPIO_CFGCTL0
	li t1, 0x0B000000			#pin 11 config setting
	sw t1, 0x14(t0)		        #configure pin 11 as output (blue led pin)(GPIO_CFGCTL5)
	li t2, 1<<11                #pin 11 output mask (0x800)
	li t3, delay

	blink_loop:
		sw t2, 0x90(t0)       	#turn led on
	
		addi t4, t3, -2			#wait some cycles
		wait_while_on:
			addi t4, t4, -1
			blt zero, t4, wait_while_on
	
		sw zero, 0x90(t0)       #turn led off
	
		addi t4, t3, -2			#wait some cycles
		wait_while_off:
			addi t4, t4, -1
			blt zero, t4, wait_while_off
	
		j blink_loop            #repeat
	
