.global main
.arm
.text

/* 
    tests that instructions are not executed for the invalid arm condition code
*/



main:
	// turn off interrupts
	ldr r1, =#0x04000208
	str r1, [r1]


	bl init_text
	
	// iter through every value of the flags
	// and see what effect the invalid cond field has
	mov r1, #0

cpsr_loop:
    mrs r2, cpsr
    and r2, #0x0fffffff
    mov r3, r1
    lsl r3, #28
    orr r3, r2
    msr cpsr, r3

    mov r2, #0
    .word 0xf3a02001 // movnv r2, #1
    ldr r0, =r2_string
    bl write
    mov r0, r2
    bl print_hex
    
    add r1, #1
    cmp r1, #16
    bne cpsr_loop
    
infin:
    b infin
    

    
r2_string:
    .asciz "\nr2 = "
