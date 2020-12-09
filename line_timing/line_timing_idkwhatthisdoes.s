

.global main
.arm
.text

    // prints timings on hardware that i dont understand
    // this test is buggy...

isr:
    
    //pull timer
    mov r1, #0x04000000
    add r1, #0x100

    ldrh r3, [r1]

    // ackknowledge intr 
    add r1, #0x100
    add r1, #2

    // pull it first
    ldrh r2, [r1]

    mov r0, #0xffffffff
    strh r0, [r1]

    // dump some vars
    mov r8, #0x02000000
    add r8, #0x400



    // check what intr we got
   
    // got a hblank intr
    and r1, r2, #2
    cmp r1, #2
    beq hblank

    // got a vcount intr
    and r1, r2, #4
    cmp r1, #4
    beq vcount 

    // dont know rofl
    b other

hblank:
    mov r1, #1
    b source_done

vcount:
    mov r1, #2
    b source_done

other:
    mov r1, #3

source_done:
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


// wait for vcount to sync line then wait for hblank
wait_intr:
    push {r0-r3,lr}


    // store vcount-1 into vcount compare
    ldr r0, =#04000005
    ldrb r1, [r0,#1]
    sub r1, #1
    strb r1, [r0]


/* 
    // store 40 into vcount
    ldr r0, =#04000005
    mov r1, #40
    strb r1, [r0]
*/
    mov r2, #0x02000000
    add r2, #0x400

    // reset our intr source
    mov r0, #0
    str r0, [r2]


    // set ie mask to allow vcount
    ldr r0, =#0x04000200
    mov r1, #4
    strh r1, [r0]

    // halt
    swi #0x020000


    // setup timer 0 to count the intr time
    ldr r0, =#0x04000100
    mov r1, #0
    strh r1, [r0]
    strh r1, [r0,#2]
    mov r1, #0x80
    strh r1, [r0,#2]   


    // set ie mask to allow hblank
    ldr r0, =#0x04000200
    mov r1, #2
    strh r1, [r0]

    // halt
    swi #0x020000

    pop {r0-r3,lr}
    bx lr 


main:
	// turn off interrupts
	ldr r1, =#0x04000208
	str r1, [r1]

    // turn off prefetch buffer
    // and max sram wait state
    ldr r1, =#0x04000204
    mov r0, #3
    str r0, [r1]

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

   	// enable interrupt servicing
	ldr r1, =#0x04000208
    mov r0, #1
	str r0, [r1]

    // enable the hblank intr and vcount intr
    ldr r1, =#0x04000004
    mov r0, #48
    strh r0, [r1]



	// dispcnt enable all bg text mode 0
	mov r0, #0x04000000
	mov r1, #0xF00
	strh r1, [r0]

    ldr r1, =#0x04000010
    //ldr r1, =#0x04000014
    ldr r3, =#0x02000400
    ldr r5, =#0x02000600
/* 
    bl wait_intr
    bl wait_intr 
    bl wait_intr
    bl wait_intr
    bl wait_intr
    bl wait_intr
*/

intr_loop:
    strh r2, [r1]
    strh r2, [r1,#4]
    strh r2, [r1,#8]
    strh r2, [r1,#12]
    bl wait_intr


    // print scx
    ldr r0, =newline_string
    bl write
    mov r0, r2
    bl print_hex

    // print timer
    ldr r0, =seperator_string
    bl write

    ldr r0, [r3,#4]
    bl print_hex  


    str r0, [r5]
    add r5, #4

    add r2, #1
    cmp r2, #512
    bne intr_loop



    mov r2, #0
    ldr r5, =#0x02000600
sram_dump:

    // ok now lets try write the result to sram
    ldr r1, =0x0e000000
    add r1, r2, lsl #2

    // write a byte
    ldr r0, [r5]
    and r4, r0, #0xff 
    lsr r0, #8
    strb r4, [r1,#0]

    // write a byte
    and r4, r0, #0xff 
    lsr r0, #8
    strb r4, [r1,#1]

    // write a byte
    and r4, r0, #0xff 
    lsr r0, #8
    strb r4, [r1,#2]

    // write a byte
    and r4, r0, #0xff 
    lsr r0, #8
    strb r4, [r1,#3]

    add r5, #4 
    add r2, #1
    cmp r2, #512
    bne sram_dump

    ldr r0, =sram_write
    bl write
infin:
    b infin




.data




newline_string:
    .asciz "\n "
seperator_string:
    .asciz " : "

sram_write:
    .asciz "\nsram write done"

// trick cart detection into using sram
sram_string:
.asciz "SRAM_"
