.global main
.arm
.text


// init wave ram to a value and look for that nibble somewhere in the io range
// to see if there is an eqiv of pcmxx for the gba that LIJI found on the gb

// TODO:
// does not play a tone out of chan3 on some emulators why? (works on mgba)
// change the master psg vol set

// thanks
// https://github.com/LIJI32/
//
//  <^)
//  (__)>

main:
	// turn off interrupts
	ldr r1, =#0x04000208
	str r1, [r1]


	bl init_text

    ldr r0, =setup
    bl write


    // memset wave ram to 0xaa
    ldr r0, =#0x04000090
    ldr r1, =#0x040000A0
    ldr r2, =#0xaa
memset_wave_ram:
    strb r2, [r0]
    add r0, #1
    cmp r0, r1
    bne memset_wave_ram


    // enable nr52 master
    ldr r0, =#0x04000084
    mov r1, #0x80
    strb r1, [r0]


    // enable everything in nr50 & 51
    ldr r0, =#0x04000080
    mov r1, #0xffffffff
    strh r1, [r0]

    // max vol (need to set a different value here!)
    ldr r1, =#32
    ldr r0, =#0x04000073
    strb r1, [r0]

    # set len to something too
    ldr r0, =#0x04000072
    strb r1, [r0]

    # setup some freq
    ldr r0, =#0x04000074
    mov r1, #1024
    strb r1, [r0]

    # now just start the wave chan
    ldr r0, =#0x04000070
    mov r1, #0x80
    strb r1, [r0]
    ldr r0, =#0x04000075
    strb r1, [r0]

    ldr r0, =tone
    bl write



    ldr r4, =#0x04000000
    ldr r1, =#0x04000800

# scan for pcmxx
scan_pcm:
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
    cmp r3, #0xa0
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