.global main
.arm
.text

    // checks the intr are acknowledged by writing a '1' bit to it

main:
	// turn off interrupts
	ldr r1, =#0x04000208
	strb r0, [r0]

	bl init_text

    ldr r2, =#0x04000004
    ldr r1, =#0x04000202
    
    // enable vblank intr
    ldrh r3, [r2]
    orr r3, #8
    strh r3, [r2]

    // wait for a vblank intr
vblank_wait:
    ldrh r3, [r1]
    and r3, #1
    cmp r3, #1
    bne vblank_wait

    // acknowlege it by writing '1' to the if reg
    mov r4, #0xffffffff
    strh r4, [r1]

    ldrh r4, [r1]

    ldr r0, =string
    bl write

    mov r0, r3
    bl print_hex

    mov r0, #0xa
    bl putchar

    mov r0, r4
    bl print_hex


infin:
    b infin

.data

string:
.asciz "if vblank acknowledge\n"