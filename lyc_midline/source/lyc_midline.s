.global main
.arm
.text

// register defines
.equ IME, 0x04000208
.equ IF, 0x04000202
.equ DISP_STAT, 0x04000004
.equ LYC, 0x04000005
.equ VCOUNT, 0x04000006
.equ TM0CNT_L, 0x04000100

// sync to visible on line 0x10
line_sync:
    push {r0-r2}
    ldr r1, =DISP_STAT 
    ldr r0, =VCOUNT
wait:
    ldrh r2, [r1]
    ands r2, #3
    bne wait
    ldrb r2, [r0]
    cmp r2, r2
    bne wait

    pop {r0-r2}
    bx lr


/*
    tests what happens during midline lyc writes

*/


main:

	// turn off interrupts
	ldr r1, =IME
	str r0, [r0]

    // acklowedge all interrupts
    mov r0, #0xffffffff
    ldr r1, =IF
    strh r0, [r1]

    // set lyc to something too high
    // so it wont trigger
    ldr r4, =LYC
    strb r0, [r4]



    // enable vcount interrupt
    ldr r0, =DISP_STAT
    ldrb r1, [r0]
    orr r1, #0x20
    strb r1, [r0]

    bl line_sync

    // setup the timers
    ldr r0, =TM0CNT_L
    mov r1, #0
    strh r1, [r0]
    strh r1, [r0,#2]
    mov r1, #0x80
    strh r1, [r0,#2]

    // pull start
    ldrh r3, [r0]

    ldr r1, =DISP_STAT

    // set vcount to lyc
    ldrb r2, [r1,#2]
    strb r2, [r1,#1]

    // get result
    ldrb r2, [r1]

    // get end
    ldrh r5, [r0]


    bl init_text

    // print our first load of writes

    ldr r0, =start_string
    bl write
    mov r0, r3
    bl print_hex

    ldr r0, =end_string
    bl write
    mov r0, r5
    bl print_hex

    ldr r0, =vcount_string
    bl write
    mov r0, r2
    bl print_hex

    ldr r0, =rapid_string
    bl write




    ldr r0, =DISP_STAT
    
    mov r3, #0xffffffff

    // if lyc == vcount set it to something nonsense
    strb r3, [r0,#1]

    ldr r7, =IF
    // acknowledge the intr
    strh r3, [r7]

    bl line_sync

    // cache ly
    ldrb r1, [r0,#2]
    mov r4, #0

    ldr r2, =TM0CNT_L
    // get start
    ldrh r5, [r2]



    // while our initial ly is the current line
    // keep writing matching and non matching lyc values
    // and see how many times the intr fires
rapid_loop:
    

    ldrb r2, [r7]
    and r2, #4
    cmp r2, #4
    beq set_lyc_invalid


    // set lyc = ly
    // and trigger an interrupt req
    strb r1, [r0,#1]

    b rapid_check

set_lyc_invalid:
    // if lyc == vcount set it to something nonsense
    strb r3, [r0,#1]

    // acknowledge the intr
    strh r3, [r7]

    add r4, #1



rapid_check:
    ldrb r2, [r0,#2]
    cmp r1, r2
    beq rapid_loop


    // get end
    ldr r2, =TM0CNT_L
    ldrh r6, [r2]



    // print our results

    ldr r0, =start_string
    bl write
    mov r0, r5
    bl print_hex

    ldr r0, =end_string
    bl write
    mov r0, r6
    bl print_hex

    ldr r0, =count_string
    bl write
    mov r0, r4
    bl print_hex


infin: 
    b infin

.data

vcount_string:
    .asciz "\nvcount: "

start_string:
    .asciz "\nstart: "

end_string:
    .asciz "\nend: "

rapid_string:
    .asciz "\n\nrapid toggle\n\n"

count_string:
    .asciz "\nlyc count: "