.global main
.arm


/* 
    tests window behavior in the middle of a frame,
    how i supsect the hardware works is that win1 & win0 have an internal flag
    that enables the window

    when it hits y1 it is enabled
    when it hits y2 it is disabled
    this is reaserted on every line even vblank

    this explains why setting wy lower than the current line but not directly hitting it
    will cause the window to not draw

    it also explains this line in gbatek
    https://problemkaputt.de/gbatek.htm
    "Y1>Y2 are interpreted as Y2=160"

    because the disable is hit first it will not get turned off again until it wraps back around and hits it
    gbatek also seems wrong slightly wrong in this regard and said checks are still asserted in vblank
    likely this is when the ly changes but im not sure

    as can be seen in tonc win_demo
    https://www.coranac.com/tonc/text/gfx.htm#sec-win
    
    moving window off the top and bottom of the screen
    the y2=160 would make you think the flag is reset at vblank but it does not appear to be the case

    thanks fleroviux for testing this in nba =)
    https://github.com/fleroviux/NanoboyAdvance/
*/







// param r1 line
// waits for specified line by waiting for line start
// and then for hblank
// with swi halt
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


// param r1 wy min
// sets wy0 y1 to param
set_wy0_min:
    push {r0-r1}

    // ok now set wy0 min to 70
    ldr r0, =#0x04000044
    strb r1, [r0,#1] 

    pop {r0-r1}
    bx lr

// param r1 wy max
// sets wy0 y2 to param
set_wy0_max:
    push {r0-r1}

    ldr r0, =#0x4000044
    strb r1, [r0]

    pop {r0-r1}
    bx lr

main:
	// turn off interrupts
    mov r0, #0
	ldr r1, =#0x04000208
	str r0, [r1]



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
    mov r1, #0
    ldr r2, =#0x06012c00

vram_loop:
    strh r1, [r0]
    add r1, #10
    add r0, #2
    cmp r2, r0
    bne vram_loop



    // winout enable everything
    ldr r1, =#0x0400004a
    mov r2, #0xffffffff
    strh r2, [r1]

    // win zero setup
    # max wx conver entire scren
    ldr r1, =#0x4000040
    mov r2, #0
    strb r2, [r1,#1]
    mov r2, #241
    strb r2, [r1]

    # end of screen cover
    ldr r1, =#0x04000044
    mov r2, #141
    strb r2, [r1]



    // win 1 setup
    # max wx conver entire scren
    ldr r1, =#0x4000042
    mov r2, #0
    strb r2, [r1,#1]
    mov r2, #241
    strb r2, [r1]

    // we aernt going to change this i just want something to make sure the windows
    // are otherwhise behaving fine
    // so put something at the top of the screen out of the way of where we are testing
    // 10 - 40
    ldr r1, =#0x04000046
    mov r2, #10
    strb r2, [r1,#1]
    mov r2, #41
    strb r2, [r1]


    // set ie mask to allow vcount
    ldr r0, =#0x04000202
    mov r1, #0xffffffff
    strh r1, [r0]
    ldr r0, =#0x04000200
    mov r1, #2
    strh r1, [r0]

    mov r0, #0x04000000 // dispcnt
    ldr r1, =#0x6403 // window 0 & 1 on
    strh r1, [r0]


// todo how does the object window work?

window_loop:

    // now we have a red screen setup the window to turn off the bg
    // when we do the all important wy write

    // todo fiddle the window turn off

    // wait 160
    mov r1, #160
    bl wait_line

    // test that it reasserts the check in vblank
    mov r1, #161
    bl set_wy0_min

    mov r1, #5
    bl set_wy0_max
    bl wait_line

    

    mov r1, #141
    bl set_wy0_max    


    // no window max = min
    // wy0 = 140
    mov r1, #140
    bl set_wy0_min


    // in theory it is asserted on line start and a internal flag set
    // so if we dont this it not going to be active
    // i.e its not doing >=
    // wait 80
    mov r1, #80
    bl wait_line

    // wy0 = 70
    mov r1, #70
    bl set_wy0_min


    // from here is new

    // test draw 80-100
    // wait 100
    mov r1, #100
    bl wait_line

    // test if triggering it all gives free reign for rest of screen time
    mov r1, #101
    bl set_wy0_min
    bl wait_line

    // test 101-110
    mov r1, #110
    bl set_wy0_min
    bl wait_line

    // no window max = min
    mov r1, #140
    bl set_wy0_min

    b window_loop


infin:
    b infin