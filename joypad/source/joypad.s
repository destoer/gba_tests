.global main
.arm
.text

    // checks the joypad and joypad control regs
    // requires interrupts

// wait until the joypad reg gives the button state we expect
// args r0: expected button state
button_wait:
    push {r0-r5}
    // only interested in the button bits
    ldr r2, =#0x3ff 
    and r0, r2
    ldr r1, =#0x04000130
    ldr r3, =#0x04000202
wait:
    // acknowledge our intrs
    // this is in case users push the wrong button while waiting
    mov r5, #0xffffffff
    strh r5, [r3]

    ldrh r2, [r1]
    cmp r0, r2
    bne wait

    pop {r0-r5}
    bx lr

main:
	// turn off interrupts
	ldr r1, =#0x04000208
	strb r1, [r1]

    // acknowledge our intrs
    ldr r3, =#0x04000202
    mov r5, #0xffffffff
    strh r5, [r3]

	bl init_text


    ldr r0, =unpressed_high_string
    bl write

    // check that the joypad register has bits '1'
    // for unpressed buttons
    // this will provide inaccurate results if users
    // hold buttons while the test boots 
    // but theres not much to be done about this
    ldr r1, =#0x04000130
    ldrh r0, [r1]

    ldr r2, =#0x3ff
    cmp r0, r2
    bne fail_keyinput

    ldr r0, =ok_string

    b print_keyinput

fail_keyinput:
    ldr r0, =fail_string

print_keyinput:
    bl write


    ldr r0, =and_string
    bl write

    ldr r3, =#0x04000202
    ldr r4, =#0x04000132

    // check keycnt and mode intr fires with no buttons pressed

    ldr r0, =and_no_select
    bl write

    mvn r0, #0
    bl button_wait

    mov r5, #0
    strh r5, [r4]

    mvn r0, #0
    bl button_wait

    // set to and mode and enable intr
    mov r5, #192
    strb r5, [r4,#1]


    // check intr fired
    ldrh r5, [r3]
    and r5, #4096
    cmp r5, #4096

    ldr r0, =ok_string

    bne and_fail

    b print_and_no_select
and_fail:

    ldr r0, =fail_string

print_and_no_select:
    bl write


    ldr r0, =press_a_and_b
    bl write

    ldr r0, =and_select
    bl write

    // check keycnt and mode intr fires with both buttons pressed

    // wait for no input
    mvn r0, #0
    bl button_wait

    // filter by 'A' and 'B'
    mov r5, #3
    strb r5, [r4]

    mvn r0, #0
    bl button_wait

    // a and b down
    mvn r0, #3
    bl button_wait

    // check intr fired
    ldrh r5, [r3]
    and r5, #4096
    cmp r5, #4096

    bne fail_and_select

    ldr r0, =ok_string

    b and_select_print

fail_and_select:
    ldr r0, =fail_string

and_select_print:
    bl write


    ldr r0, =press_a
    bl write

    // check no intr fires when the selected and buttons aernt pressed
    // hardware wants 'a' and 'b' for one to fire still
    ldr r0, =and_no_intr
    bl write

    mvn r0, #0
    bl button_wait

    // wait for a press
    mvn r0, #1
    bl button_wait


    // check no intr fired
    ldrh r5, [r3]
    and r5, #4096
    cmp r5, #4096    

    beq and_no_intr_fail

    ldr r0, =ok_string

    b and_no_intr_print

and_no_intr_fail:
    ldr r0, =fail_string

and_no_intr_print:
    bl write


    ldr r0, =press_a_and_b
    bl write

    ldr r0, =and_no_irq
    bl write


    mvn r0, #0
    bl button_wait

    // test that an intr does not fire when the irq is off

    // set to and mode no enable intr
    mov r5, #128
    strb r5, [r4,#1]  

    mvn r0, #0
    bl button_wait

    mvn r0, #3
    bl button_wait

    // check no intr fired
    ldrh r5, [r3]
    and r5, #4096
    cmp r5, #4096    
    beq and_no_irq_fail

    ldr r0, =ok_string

    b and_no_irq_print

and_no_irq_fail:
    ldr r0, =fail_string

and_no_irq_print:
    bl write


    ldr r0, =or_string
    bl write


    ldr r0, =press_a
    bl write


    ldr r0, =or_select
    bl write

    // check or mode fires when the specified button is pressed
    // (a in this case)

    // change to or mode fire irq
    mov r5, #0x40
    strb r5, [r4,#1]

    // filter by 'A'
    mov r5, #1
    strb r5, [r4]

    // wait for no input
    mvn r0, #0
    bl button_wait

    // wait for a
    mvn r0, #1
    bl button_wait

    // check intr fired
    ldrh r5, [r3]
    and r5, #4096
    cmp r5, #4096

    bne or_select_fail

    ldr r0, =ok_string

    b or_select_print

or_select_fail:
    ldr r0, =fail_string

or_select_print:
    bl write


    // check or mode does not fire when the selected button is not pressed
    
    ldr r0, =press_b
    bl write

    ldr r0, =or_no_select
    bl write

    // wait for no input
    mvn r0, #0
    bl button_wait    

    // wait for b
    mvn r0, #2
    bl button_wait

    // check no intr fired
    ldrh r5, [r3]
    and r5, #4096
    cmp r5, #4096    

    beq or_no_select_fail

    ldr r0, =ok_string

    b or_no_select_print

or_no_select_fail:
    ldr r0, =fail_string

or_no_select_print:
    bl write


    ldr r0, =done
    bl write


infin:
    b infin


unpressed_high_string:
    .asciz "unpressed high: "

and_no_select:
    .asciz "\nand_no_select: "

and_select:
    .asciz "\nand_select: "

and_no_intr:
    .asciz "\nand_no_intr: "

and_no_irq:
    .asciz "\nand_no_irq: "

or_select:
    .asciz "\nor_select: "

or_no_select:
    .asciz "\nor_no_select: "


press_a_and_b:
    .asciz "\npress a and b"

press_a:
    .asciz "\npress a"

press_b:
    .asciz "\npress b"

ok_string:
    .asciz "ok"

fail_string:
    .asciz "fail"


and_string:
    .asciz "\n****and_tests****"

or_string:
    .asciz "\n****or_tests****"


done:
    .asciz "\nyour emulator sucks?\n"