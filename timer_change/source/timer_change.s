.global main
.arm
.text


reset_timer:
    push {r0,r1}
    
    ldr r0, =#0x04000100
    mov r1, #0
    strh r1, [r0]
    strh r1, [r0,#2]
    mov r1, #0x83	
    // enable the timer
    strh r1, [r0,#2]
    
    pop {r0,r1}
    bx lr

main:
	// turn off interrupts
	ldr r1, =#0x04000208
	str r1, [r1]


	bl init_text
	
    bl reset_timer
	
	
    // okay now we delay a bunch
    // get a good number of cycles
    // then we simply switch the tick mode and read out the timer

    mov r0, #100
    
wait_loop:
    subs r0, #1
    bne wait_loop
    
    //pull timer
    ldr r1, =#0x04000100
    ldrh r2, [r1]
    
    bl reset_timer
    
    
    // okay now mess with the prescaler
    mov r0, #0x80	
    strh r0, [r1,#2] 
    
    ldrh r3, [r1]
    
    // print results
    mov r0, r2
    bl print_hex
    ldr r0, =new_line
    bl write
    mov r0, r3
    bl print_hex
    
    
    bl reset_timer
    
    // now for jokes lets flash the timer on and off
    // okay now mess with the prescaler
    mov r0, #0x80	
    mov r2, #0
    mov r3, #10
rapid_loop:
    strh r0, [r1,#2]
    strh r2, [r1,#2]
    subs r3, #1
    bne rapid_loop
	
	ldr r0, =new_line
	bl write
	ldrh r0, [r1]
	bl print_hex
	
infin:
    b infin

new_line:
    .asciz "\n"
