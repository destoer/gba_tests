.global main
.arm
.text


// init wave ram to a value and look for that nibble somewhere in the io range
// to see if there is an eqiv of pcmxx for the gba that LIJI found on the gb

// TODO:
// check if there is an eqiv for the dma sound 
// if there is a pcmxx in gba moade i cant find it

// thanks
// https://github.com/LIJI32/
//
//  <^)
//  (__)>

init_wave_ram:
	push {r0-r3}
    // memset wave ram to 0xaa
    ldr r0, =#0x04000090
    ldr r1, =#0x040000A0
    ldr r2, =#0xaa
	//mov r2, #0x0
memset_wave_ram:
    strb r2, [r0]
	//add r2, #0x15
    add r0, #1
    cmp r0, r1
    bne memset_wave_ram
	pop {r0-r3}
	bx lr
	
main:
	// turn off interrupts
	ldr r1, =#0x04000208
	str r1, [r1]


	bl init_text

    ldr r0, =setup
    bl write


    // enable nr52 master
    ldr r0, =#0x04000084
    mov r1, #0xffffffff
    str r1, [r0]

    // psg max all others off
    ldr r0, =#0x04000082
    mov r1, #0x2
    strh r1, [r0]

	// turn off dac & fill both banks
	mov r1, #0x20
    ldr r0, =#0x04000070
    strh r1, [r0]

	bl init_wave_ram

	mov r1, #0x60
    ldr r0, =#0x04000070
    strh r1, [r0]

	bl init_wave_ram

    // enable everything in nr50 & 51
    ldr r0, =#0x04000080
    mov r1, #0xffffffff
    strh r1, [r0]
	
	// turn on dac
	mov r1, #0xff
    ldr r0, =#0x04000070
    strh r1, [r0]

	// max sample
	mov r1, #0xffffffff
    ldr r0, =#0x04000088
    strh r1, [r0]


    // max vol + len 
    ldr r1, =#0x2000
    ldr r0, =#0x04000072
    strh r1, [r0]

    // now just start the wave chan
	ldr r1, =#0x8000
    ldr r0, =#0x04000074
    strh r1, [r0]
	

    ldr r0, =tone
    bl write


scan_loop:
    ldr r4, =#0x04000000
    ldr r1, =#0x04000800

    ldr r5, =#0x04000090
    ldr r6, =#0x040000A0

# scan for pcmxx
scan_pcm:

	# ignore wave ram it will ofc course have our sample!
	cmp r4, r5
	bge wave_ram_range_2nd
	b scan_main
	
	
wave_ram_range_2nd:
	cmp r4, r6
	ble scan_pcm_end

scan_main:
    ldrb r2, [r4]
    nop
    and r3,r2, #0xf
    cmp r3, #0xa

    bne scan_pcm_high
    mov r0, r4
    bl print_hex
    ldr r0, =newline
    bl write
    b scan_pcm_end

scan_pcm_high:
    and r3,r2, #0xf0
    cmp r3, #0xaa
    bne scan_pcm_end

    mov r0, r4
    bl print_hex
    ldr r0, =newline
    bl write
    b scan_pcm_end

scan_pcm_end:
    add r4, #1
    cmp r4, r1
    bne scan_pcm


	b scan_loop

    ldr r0, =end
    bl write

infin:
    b infin

setup:
.asciz "setting up wave chan\n"

tone:
.asciz "playing tone\n"

end:
.asciz "scan end\n"

newline:
.asciz "\n"