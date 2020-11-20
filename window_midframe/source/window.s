.global main
.arm

// param r1 line
wait_line:
    push {r0-r1}

    // store vcount compare with r1
    ldr r0, =#0x04000005
    strb r1, [r0]    

    // enable vcount
    ldr r0, =#0x04000200
    mov r1, #4
    strh r1, [r0]

    // halt
    swi #0x020000
    ldr r0, =#0x04000202
    mov r1, #0xffffffff
    strh r1, [r0]


    // ok now we wait for hblank
    ldr r0, =#0x04000200
    mov r1, #2
    strh r1, [r0]

    // halt
    swi #0x020000
    ldr r0, =#0x04000202
    mov r1, #0xffffffff
    strh r1, [r0]

    pop {r0-r1}
    bx lr

main:
	// turn off interrupts
	ldr r1, =#0x04000208
	str r1, [r1]



    // enable the hblank intr and vcount intr
    ldr r1, =#0x04000004
    mov r0, #48
    strh r0, [r1]    






    
    // ok red screen gang time

    mov r0, #0x04000000 // dispcnt
    ldr r1, =#0x2403 // window 0 on
    strh r1, [r0]


    //memcpy red into vram :P
    mov r0, #0x06000000
    mov r1, #31
    ldr r2, =#0x06012c00

vram_loop:
    strh r1, [r0]
    add r0, #2
    cmp r2, r0
    bne vram_loop



    // winout enable everything
    ldr r1, =#0x0400004a
    mov r2, #0xffffffff
    strh r2, [r1]

    # max wx conver entire scren
    ldr r1, =#0x4000040
    mov r2, #0
    strb r2, [r1,#1]
    mov r2, #241
    strb r2, [r1]


    ldr r1, =#0x04000044
    mov r2, #161
    strb r2, [r1]


    // set ie mask to allow vcount
    ldr r0, =#0x04000202
    mov r1, #0xffffffff
    strh r1, [r0]
    ldr r0, =#0x04000200
    mov r1, #2
    strh r1, [r0]

    mov r0, #0x04000000 // dispcnt
    ldr r1, =#0x2403 // window 0 on
    strh r1, [r0]

window_loop:

    // now we have a red screen setup the window to turn off the bg
    // when we do the all important wy write

    // dont even wanna know what this is doing
/* 
    // first wait for line one
    ldr r0, =#04000005
    mov r1, #0
    strb r1, [r0]    

    // halt
    swi #0x020000

    // first wait for line zero
    ldr r0, =#04000005
    mov r1, #0
    strb r1, [r0]    

    // halt
    swi #0x020000

    // now wait for line 40
    ldr r0, =#04000005
    mov r1, #40
    strb r1, [r0]   


    // halt
    swi #0x020000

    // ok now set wy min to 0
    ldr r1, =#0x04000044
    mov r2, #0
    strb r2, [r1,#1]


    // now wait for line 100
    ldr r0, =#04000005
    mov r1, #100
    strb r1, [r0]   

    // halt
    swi #0x020000

    // ok now set wy min to 90
    ldr r1, =#0x04000044
    mov r2, #90
    strb r2, [r1,#1]

    b window_loop
*/

    // todo fiddle the window turn off

    // wait 160
    mov r1, #160
    bl wait_line

    // ok now set wy min to 160
    ldr r1, =#0x04000044
    mov r2, #160
    strb r2, [r1,#1] 

    
    mov r1, #80
    bl wait_line

    // ok now set wy min to 70
    ldr r1, =#0x04000044
    mov r2, #70
    strb r2, [r1,#1] 

    b window_loop


infin:
    b infin