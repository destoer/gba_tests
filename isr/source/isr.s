.global main
.arm
.text

    // checks the timing of isrs
    // and that the return address is set properly

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
    mov r8, #0x02000000
    add r8, #0x400

    // notify of an intr trigger
    mov r1, #1
    str r1, [r8]

    // store the time for it to fire
    str r3, [r8, #4]

    mov r7, lr

    // store the lr pushed to return to the mode intr was called from
    // the bios after calling our handler wille execute this instr 
    // with a stack writeback
    ldmfd  r13, {r0-r3,r12,r14}

    str lr, [r8, #8]

    mov lr, r7
    bx lr
isr_end:

isr_size = isr_end - isr




intr_test_arm:
    push {r0-r7,lr}

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
    


    // force an intr
    // make sure your pipeline is full if you emulate it
    // or youll get some nice behavior
fire_intr_arm:
    strh r3, [r2]

    // save cpsr
    mrs r7, cpsr

    // nop sled here in case the return addr is off
    nop
    nop
    nop
    nop
    nop
    nop

    ldr r1, [r4]
    cmp r1, #1
    beq intr_fired_arm

    ldr r0, =no_intr_string
    bl write

    b infin
    
intr_fired_arm:
    // print the results


    ldr r0, =intr_fired_string
    bl write

    ldr r0, =timer_string
    bl write

    ldr r0, [r4,#4]
    bl print_hex


    ldr r0, =lr_string
    bl write

    // calc the lr relative to the intr
    ldr r0, [r4, #8]
    ldr r1, =#fire_intr_arm
    sub r0, r1

    bl print_hex

    ldr r0, =cpsr_string
    bl write
    mov r0, r7
    bl print_hex

    pop {r0-r7,lr}
    bx lr

    
.thumb
intr_test_thumb:
    ldr r1, =#0x04000202

    // wait for a vblank intr
    // we will use this to force an intr later
    mov r2, #1
vblank_wait_thumb:
    ldrh r3, [r1]
    and r3, r2
    cmp r3, #1
    bne vblank_wait_thumb





    // setup timer 0 to count the intr time
    // setup the timers
    ldr r0, =#0x04000100
    mov r1, #0
    strh r1, [r0]
    strh r1, [r0,#2]
    mov r1, #0x80
    strh r1, [r0,#2]   


    // preload some vars for reading out results
    ldr r4, =#0x02000400

    // set ie mask to allow all
    ldr r2, =#0x04000200
    ldr r3, =#0xffffffff
    


    // force an intr
    // make sure your pipeline is full if you emulate it
    // or youll get some nice behavior
fire_intr_thumb:
    strh r3, [r2]

    // nop sled here in case the return addr is off
    nop
    nop
    nop
    nop
    nop
    nop

    ldr r1, [r4]
    cmp r1, #1
    beq intr_fired_thumb

thumb_infin:
    b thumb_infin

intr_fired_thumb:
    ldr r2, [r4, #8]
    ldr r3, =#fire_intr_thumb
    sub r2,r3






    ldr r0, =return_thumb
    bx r0



.arm
    
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

    bl intr_test_arm

    // set ie mask to disallow all
    ldr r2, =#0x04000200
    mov r3, #0
    
    strh r3, [r2]
    
    
    ldr r0, =intr_test_thumb
    add r0, #1
    bx r0
    
return_thumb:
    
    ldr r0, =lr_string
    bl write

    // calc the lr relative to the intr
    mov r0, r2

    bl print_hex    
    
    
    
    // ok now we are going to test swi return addresses
    ldr r0, =swi_string
    bl write
    mov r12, #0
    swi #0x80000
    
    // ok lets jam 5 incs to get a rough indicator of where this should return
    add r12, #1
    add r12, #1
    add r12, #1
    add r12, #1
    add r12, #1
    
    
    sub r0, r12, #4
    lsl r0, #2
    bl print_hex
    
    
    
    
    
infin:
    b infin

.data


no_intr_string:
    .asciz "no interrupt"

intr_fired_string:
    .asciz "interrupt fired\n"

cpsr_string:
    .asciz "\ncspr: "

timer_string:
    .asciz "timer: "

lr_string:
    .asciz "\nlr: "
    
swi_string:
    .asciz "\nswi: \n"
