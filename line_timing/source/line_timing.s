

.global main
.arm
.text


/*
    tests basic line timings

 */


// wait for vcount to sync line then wait for hblank
wait_intr:
    push {r0-r3,lr}
    mov r3, r2

    // store 40 into vcount compare
    //ldr r0, =#0x04000005
    //ldrb r1, [r0,#1]
    mov r1, #40
    strb r1, [r0]

    mov r2, #0x02000000
    add r2, #0x400

    // reset our intr source
    mov r0, #0
    str r0, [r2]


    // set ie mask to allow vcount
    ldr r0, =#0x04000202
    mov r1, #0xffffffff
    strh r1, [r0]
    ldr r0, =#0x04000200
    mov r1, #4
    strh r1, [r0]


    // setup timer 0 to count the intr time
    ldr r0, =#0x04000100
    mov r1, #0
    strh r1, [r0]
    strh r1, [r0,#2]
    mov r1, #0x80

    // halt
    swi #0x020000


    // enable the timer
    strh r1, [r0,#2]   

    // set ie mask to allow hblank
    ldr r0, =#0x04000202
    mov r1, #0xffffffff
    strh r1, [r0]
    ldr r0, =#0x04000200
    mov r1, #2
    strh r1, [r0]


    //pull timer
    ldr r1, =#0x04000100

    // halt
    swi #0x020000


    ldrh r3, [r1]

    // dump some vars
    ldr r1, =#0x02000400
    str r3, [r1]


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

    // enable the hblank intr and vcount intr
    ldr r1, =#0x04000004
    mov r0, #48
    strh r0, [r1]


/* 
	// dispcnt enable all bg text mode 0
	mov r0, #0x04000000
	mov r1, #0xF00
	strh r1, [r0]
*/
    ldr r1, =#0x04000010
    ldr r3, =#0x02000400
    ldr r5, =#0x02000600
    mov r2, #0

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

    ldr r0, [r3]
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
