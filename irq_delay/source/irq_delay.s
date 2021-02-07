.global main
.arm
.text

    // irq delay test!
    // 1 2 IRQ!
    // points so far
    // cpsr enable is checked as the service is done
    // IE & IF is cached for the delay until service
    // ie resetting them or IME after the trigger has allready happened
    // wont do anything.
    // the intr will still fire if the cpsr bit is enabled
    
    // if cpsr is not ready at this point it is lost
isr:

    // ackknowledge intr and pull timer
    mov r1, #0x04000000
    add r1, #0x100

    ldrh r3, [r1]

    add r1, #0x100
    add r1, #2

    mov r0, #0xffffffff
    strh r0, [r1]

    // dump some vars
    mov r6, #0x02000000
    add r6, #0x400

    // notify of an intr trigger
    mov r1, #1
    str r1, [r6]

    // store the time for it to fire
    str r3, [r6, #4]

    mov r7, lr

    // store the lr pushed to return to the mode intr was called from
    // the bios after calling our handler wille execute this instr 
    // with a stack writeback
    ldmfd  r13, {r0-r3,r12,r14}

    str lr, [r6, #8]

    mov lr, r7
    bx lr
isr_end:

isr_size = isr_end - isr


// basic interrupt force (do we implement irq delay at all? )
test_one:
    // force an intr
    strh r3, [r2]
	
    // nop sled here in case the return addr is off
    nop
    nop
    nop
    nop
    nop
    nop
	nop

	bx lr

test_one_end:

test_one_size = test_one_end - test_one

// test two (disable IE after forcing an intr)
// should still fire
test_two:
    // force an intr
    strh r3, [r2]
    
    // disable ie
    strh r5, [r2]
	
    // nop sled here in case the return addr is off
    nop
    nop
    nop
    nop
    nop
    nop
	nop

	bx lr

test_two_end:

test_two_size = test_two_end - test_two


// test three (disabe intr fire under cpsr)
// will off hold the fire
test_three:
    // force an intr
    strh r3, [r2]
    msr cpsr, r8
    
    // disable ie
    strh r5, [r2]
	
	// renable the interrupts
	msr cpsr, r10
	
    // nop sled here in case the return addr is off
    nop
    nop
    nop
    nop
    nop
    nop
	nop

	bx lr

test_three_end:

test_three_size = test_three_end - test_three



// test four
// when does the intr check expire?
test_four:
    // force an intr
    strh r3, [r2]
    
    // disable intr service
    msr cpsr, r8
    
    // disable ie
    strh r5, [r2]
	
	nop
	nop
	
	// renable the interrupts
	msr cpsr, r10
	
    // nop sled here in case the return addr is off
    nop
    nop
    nop
    nop
    nop
    nop
	nop

	bx lr

test_four_end:

test_four_size = test_four_end - test_four




// test five
// what actually advances the state of the syncronizer
test_five:
    // force an intr
    strh r3, [r2]
    
    // force alot of memory accesses
	stm r7, {r0-r15}
	
    // nop sled here in case the return addr is off
    nop
    nop
    nop
    nop
    nop
    nop
	nop

	bx lr

test_five_end:

test_five_size = test_five_end - test_five

// test six
// rapid toggle of irq bit
test_six:
    // force an intr
    strh r3, [r2]
    
    msr cpsr,r8
    msr cpsr,r10

	
    // nop sled here in case the return addr is off
    nop
    nop
    nop
    nop
    nop
    nop
	nop

	bx lr

test_six_end:

test_six_size = test_six_end - test_six

// test seven
// cpsr off before force
test_seven:
    // force an intr
    strh r3, [r2]
    
    msr cpsr,r10

	
    // nop sled here in case the return addr is off
    nop
    nop
    nop
    nop
    nop
    nop
	nop

	bx lr

test_seven_end:

test_seven_size = test_seven_end - test_seven



// test eight
// instr with large number of internal cycles
test_eight:
    // force an intr
    strh r3, [r2]
    
    mul r2, r5
    mul r2, r5
    mul r2, r5
    mul r2, r5

	
    // nop sled here in case the return addr is off
    nop
    nop
    nop
    nop
    nop
    nop
	nop

	bx lr

test_eight_end:

test_eight_size = test_eight_end - test_eight


// test nine
// instr with a mix or internal and memory cycles
test_nine:
    // force an intr
    strh r3, [r2]
    
    swp r0, r1, [r2]
   
	
    // nop sled here in case the return addr is off
    nop
    nop
    nop
    nop
    nop
    nop
	nop

	bx lr

test_nine_end:

test_nine_size = test_nine_end - test_nine





// test ten
// branch after force
test_ten:
    // force an intr
    strh r3, [r2]
    
    b heh
   
	
    // nop sled here in case the return addr is off
    nop
    nop
heh:
    nop
    nop
    nop
    nop
	nop

	bx lr

test_ten_end:

test_ten_size = test_ten_end - test_ten



// test eleven
// force with swp
test_eleven:
    // force an intr
    // swp
    swp r0, r9, [r2]
    mul r2, r5
    mul r2, r5
   
	
    // nop sled here in case the return addr is off
    nop
    nop
    nop
    nop
    nop
    nop
	nop

	bx lr

test_eleven_end:

test_eleven_size = test_eleven_end - test_eleven


// r1 address of test routine
// r2 routine size

intr_test_arm:
    push {r0-r11,lr}

    // copy routine into wram
	ldr r0, =#0x03000400 + isr_size
	bl memcpy    
    
    
    ldr r1, =#0x04000202

    // wait for a vblank intr
    // we will use this to force an intr later
vblank_wait_arm:
    ldrh r3, [r1]
    and r3, #1
    cmp r3, #1
    bne vblank_wait_arm





    // setup timer 0 to count the intr time
    // setup the timers
    ldr r0, =#0x04000100
    mov r1, #0
    strh r1, [r0]
    strh r1, [r0,#2]
    mov r1, #0x80
    strh r1, [r0,#2]   


    // preload some vars for reading out results
    mov r4, #0x02000000
    add r4, #0x400


    // set ie mask to allow all
    ldr r2, =#0x04000200
    mov r3, #0xffffffff
    

	// call the test!
	ldr lr, =fire_intr_arm_return
	ldr r0, =#0x03000400 + isr_size 
	bx r0
	

	// returns to this label!
fire_intr_arm_return:

    // reset cpsr after any potential shenanigans
	msr cpsr,r10

    ldr r1, [r4]
    
    // reset interrupt trigger
    mov r0, #0
    strh r0, [r4]
    
    cmp r1, #1
    beq intr_fired_arm

    // no interrupt fired
    // just return out
    ldr r0, =no_intr_string
    bl write

    b return_fired
    
intr_fired_arm:
    // print the results

    // calc the lr relative to the intr
    ldr r0, [r4, #8]
    ldr r1, =#0x03000400 + isr_size
    sub r0, r1

    bl print_hex

    ldr r0, =split_string
    bl write

    // load timer
    ldr r0, [r4,#4]
    bl print_hex

    ldr r0, =newline_string
    bl write


return_fired:

    // set ie mask to disallow all
    ldr r2, =#0x04000200
    mov r3, #0
    strh r3, [r2]
    
    pop {r0-r11,lr}
    bx lr

main:
	// turn off interrupts
	ldr r1, =#0x04000208
	str r1, [r1]

	bl init_text

    // copy our isr to wram
    ldr r0, =#0x03000400
    ldr r1, =isr
    ldr r2, =isr_size

    bl memcpy



    // setup our isr pointer
    ldr r0, =#0x03007FFC
    ldr r1, =#0x03000400
    str r1,[r0]

   // ldr r0

   	// enable interrupt servicing
	ldr r1, =#0x04000208
    mov r0, #1
	str r0, [r1]

    // enable the vblank intr
    ldr r1, =#0x04000004
    mov r0, #8
    strh r0, [r1]

    
    // setup registers for screwing with cpsr
    // and the interrupt regs
	mov r5, #0
	mov r9, #0xffffffff
	
	// via cpsr
	mrs r8, cpsr
	mov r10, r8
	orr r8, #128
    
    

    
    
    // test cases
    
	ldr r1, =test_one
	ldr r2, =test_one_size
    bl intr_test_arm

	ldr r1, =test_two
	ldr r2, =test_two_size
    bl intr_test_arm
    
	ldr r1, =test_three
	ldr r2, =test_three_size
    bl intr_test_arm
    
    ldr r1, =test_four
    ldr r2, =test_four_size
    bl intr_test_arm
    
    ldr r7, =#0x07000000
    ldr r1, =test_five
    ldr r2, =test_five_size
    bl intr_test_arm
    
    
    ldr r1, =test_six
    ldr r2, =test_six_size
    bl intr_test_arm    
    
    msr cpsr,r8
    ldr r1, =test_seven
    ldr r2, =test_seven_size
    bl intr_test_arm

    ldr r1, =test_eight
    ldr r2, =test_eight_size
    bl intr_test_arm

    ldr r1, =test_nine
    ldr r2, =test_nine_size
    bl intr_test_arm    

    ldr r1, =test_ten
    ldr r2, =test_ten_size
    bl intr_test_arm  
    
    ldr r9, =#0xffff
    ldr r1, =test_eleven
    ldr r2, =test_eleven_size
    bl intr_test_arm  
    
infin:
    b infin



.data


no_intr_string:
    .asciz "no interrupt\n"


split_string:
    .asciz " : "

newline_string:
    .asciz "\n"



