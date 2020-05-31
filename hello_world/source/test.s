.global main
.arm
.text

main:
	// turn off interrupts
	ldr r1, =#0x04000208
	strb r0, [r0]


	bl init_text


	ldr r0, =hello_world
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	bl write
	ldr r0, =it_works
	bl write
	bl write
	mov r0, #'b'
	bl putchar
	ldr r0, =it_works
	bl write
	bl write

	mov r0, sp
	bl print_hex
	
infin:	
	b infin


.data
hello_world:
	.asciz "hello world!\n"

it_works:
	.asciz "it works\n"