.global main
.arm
.text


/*
    tests priority of dma's
    by dmaing to the control regs with another dma
 */



//r0 dest 
//r1 source
//r2 dma reg
//r3 control
//r4 size (in bytes)
test_dma:
    push {r0-r6,lr}

    // where we test dmas too
    ldr r6, =#0x03000000

    // reset the value each time
    mov r5, #0
    str r5, [r6]

    // mov dest to r5 so its easier
    mov r5, r0

    // convert to word ammount 
    // (ideally we shouldunt assume that our control is of this type if we were to reusue this)
    lsr r4, #2

    ldr r0, =before_string
    bl write

    ldr r0, [r6]

    bl print_hex

    
    str r1, [r2] // write source
    str r5, [r2,#4] // write dest
    strh r4, [r2,#8] // write word count
    strh r3, [r2,#0xa] // write control


    // write out result
    ldr r0, =after_string
    bl write
    ldr r0, [r6]
    bl print_hex


    pop {r0-r6,lr}
    bx lr




// hack of above fucntion
// to flash screen red
// incase of hardware lockups

.text
//r0 dest 
//r1 source
//r2 dma reg
//r3 control
//r4 size (in bytes)
test_dma_hack:
    push {r0-r6,lr}

    // where we test dmas too
    ldr r6, =#0x03000000

    // reset the value each time
    mov r5, #0
    str r5, [r6]

    // mov dest to r5 so its easier
    mov r5, r0

    // convert to word ammount 
    // (ideally we shouldunt assume that our control is of this type if we were to reusue this)
    lsr r4, #2

    ldr r0, =before_string
    bl write

    ldr r0, [r6]

    bl print_hex

    
    str r1, [r2] // write source
    str r5, [r2,#4] // write dest
    strh r4, [r2,#8] // write word count
    strh r3, [r2,#0xa] // write control

    // ok the dma might have completly
    // screwed the entire of memory
    // lets try smash a red screen
    // if we dont get it that means the hardware
    // has complelty locked up...

    mov r0, #0x04000000 // dispcnt
    ldr r1, =#0x403
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

infin_2:
    b infin_2
/* 
    // write out result
    ldr r0, =after_string
    bl write
    ldr r0, [r6]
    bl print_hex





    pop {r0-r6,lr}
    bx lr
*/


main:
	// turn off interrupts
	ldr r1, =#0x04000208
	str r1, [r1]


    // write waitstates to max so we dont get any bugs
    ldr r1, =#0x04000204
    ldr r2, =#0xfffffff
    str r2, [r1]

	bl init_text    



    // test 1
    // ok lets just test doing a straight up dma to 0x03000000
    // to check the value is overwritten
    ldr r0, =test1_string
    bl write


    ldr r0, =#0x03000000 // dest
    ldr r1, =test1_data // source
    ldr r2, =#0x040000b0 //dma0
    ldr r3, =#0b1000010000000000 // enable word size
    mov r4, #4
    bl test_dma




    // test2 
    // test two dma regs in order 

    ldr r0, =test2_string
    bl write

    //(need to write some garbage before to avoid lockups on hardware)
    // dma0 start - 24
    // wil write to dma0 then dma 1
    ldr r0, =#0x040000b0-24// dest 

    ldr r1, =dma_info // source
    ldr r2, =#0x040000d4 //dma3
    ldr r3, =#0b1000010000000000 // enable word size
    ldr r4, =dma_info_size-24
    bl test_dma    



    // test3
    // test two dma regs in reverse order
    //  3 then 2
    // (does not work)
    ldr r0, =test3_string
    bl write

    //(need to write some garbage before to avoid lockups on hardware)
    // dma3 end + 24
    ldr r0, =#0x040000de + 24// dest 

    ldr r1, =dma_info_end // source
    ldr r2, =#0x040000b0 //dma0
    ldr r3, =#0b1000010010100000 // enable word size (minus dst, minus src)
    ldr r4, =dma_info_size-24
    bl test_dma    



    // test4 dma to self enable during xfer
    // should not execute dma

    ldr r0, =test4_string
    bl write

    ldr r0, =#0x040000d4
    ldr r1, =dma_info+24
    mov r2, r0
    ldr r3, =#0b1000010000000000 // enable word size
    mov r4, #12
    bl test_dma
/* 
    //inc version (locks up on hardware appears to trash ram without a dma end)
    // TODO find out why

    // tes5 4 dma to self disable during xfer
    // if it disables the next dma reg wont get written
    // and tehre wont be a dump
    // 0 then 1


    ldr r0, =test5_string
    bl write

    ldr r0, =#0x040000b0-24
    ldr r1, =dma_cancel
    ldr r2, =#0x040000b0 // dma 0
    ldr r3, =#0b1000010000000000 // enable word size
    ldr r4, =dma_cancel_size-36
    //bl test_dma_hack
    bl test_dma
*/


    // dec version

    // test 5 4 dma to self disable during xfer
    // if it disables the next dma reg wont get written
    // and tehre wont be a dump
    // 3 then 2
    // appears to disable on hardware

    ldr r0, =test5_string
    bl write

    ldr r0, =#0x040000d4+24
    ldr r1, =dma_cancel_end
    ldr r2, =#0x040000d4 // dma 0
    ldr r3, =#0b1000010010100000 
    ldr r4, =dma_cancel_size-36
    bl test_dma


infin:
    b infin



.data

// reserve first part for ourself :P
.word 0x0

test1_data:
.word 0xdeadbeef


dma2_data:
.word 0x2
dma1_data:
.word 0x1


dma_info:


// dummy data either side
// so we can delay starting dmas
.word 0x0
.word 0x0
.word 0x0

.word 0x0
.word 0x0
.word 0x0


// dma 1
.word dma1_data 
.word 0x03000000
.word 0x85400001

// (fixed) xfer one word
// 1000010101000000  = 0x8540

// dma 2
.word dma2_data 
.word 0x03000000
.word 0x85400001

// dummy data either side

.word 0x0
.word 0x0
.word 0x0

.word 0x0
.word 0x0
.word 0x0


dma_info_end:

dma_info_size = dma_info_end - dma_info



dma_cancel:
.word 0x0
.word 0x0
.word 0x0

.word 0x0
.word 0x0
.word 0x0

// dma 0
.word 0x0
.word 0x0
.word 0x0

// dma 1 / 2
.word dma1_data 
.word 0x03000000
.word 0x85400001

// dummy data either side

// dma3
.word 0x0
.word 0x0
.word 0x0

.word 0x0
.word 0x0
.word 0x0

.word 0x0
.word 0x0
.word 0x0


dma_cancel_end:

dma_cancel_size = dma_cancel_end - dma_cancel


before_string:
.asciz "before: "

after_string:
.asciz "\nafter: "


test1_string:
.asciz "test 1 basic dma\n"

test2_string:
.asciz "\ntest 2 forward priority\n"

test3_string:
.asciz "\ntest 3 reverse priority\n"

test4_string:
.asciz "\ntest 4 dma to self enable\n"

test5_string:
.asciz "\ntest 5 dma to self disable\n"