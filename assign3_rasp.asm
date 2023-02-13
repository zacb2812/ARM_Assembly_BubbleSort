.text
.global _start

_timer$:
	wait$:
		sub r3,#1
		cmp r3,#0
		bne wait$
	bx lr

_flash$:
	cmp r11, #0 /*compare current value to 0*/
	sub r11, #1 /*subtract 1 from current value to keep track of how many times to flash*/
	mov r1,#1
	lsl r1,#18
	str r1,[r0,#28]  /*turn LED on*/
	mov r3,#0xF000000 /*initialise r3 with value for busy timer to use*/
	wait2$:
		sub r3,#1
		cmp r3,#0
		bne wait2$
	str r1,[r0,#40]   /*turn LED off*/
	mov r3,#0xF000000 /*initialise r3 with value for busy timer to use*/
	wait3$:
		sub r3,#1
		cmp r3,#0
		bne wait3$
	cmp r11, #0 /*compare current value to 0*/
	addeq r10, #4 /*increment index if current value is 0 so the next value can be loaded*/
	subeq r8, #1 /*decrement flash counter*/
	beq loop$ /*call loop if moving to next value*/
	b _flash$ /*call flash again if still flashing current value*/
		
_swap$:
	str r6, [r10, #4]
	str r7, [r10]
	bx lr

_sort$:
	ldr r6, [r10] /*get first value*/
	ldr r7, [r10, #4] /*get second value*/
	cmp r7, r6 /*compare first and second values*/
	movlt lr, pc /*stores next instruction in link register if values will be swapped*/
	blt _swap$ /*compare and swap if needed*/
	add r10, #4 /*increment index*/
	sub r5, #1 /*decrement inner counter*/
	cmp r5, #0 /*check if ended*/
	bne _sort$ /*if inner counter not 0 call sort again*/
	sub r4, #1 /*decrement outer counter*/
	cmp r4, #0 /*check if ended*/
	bne _init_sort$

_init_sort$:
	cmp r12, #0 /*compare sort counter to 0*/
	subne r12, #1 /*subtract 1 from sort counter if not 0*/
	movne r4, #4 /*array length-1 = outer counter*/
	movne r5, r4 /*inner counter*/
	movne r10, r9 /*index*/
	bne _sort$
	pop {lr}
	bx lr
	
loop$:
	mov r3,#0x1E000000
	wait4$:
		sub r3,#1
		cmp r3,#0
		bne wait4$
	cmp r8, #0
	ldrne r11, [r10] /*load value in array*/
	bne _flash$
	bx lr
	
_init$:
	ldr r9, =arr
	mov r8, #5  /*arr length*/
	mov r10, r9 /*arr index*/
	mov r12, r8 /*sort counter*/
	bx lr

_start:
    ldr	r0, =gpiomem
	ldr	r1, =0x101002	/* O_RDWR | O_SYNC */
	mov	r7, #5		/* open */
	svc	#0
	mov	r4, r0		/* file descriptor */
	mov	r0, #0		/* kernel chooses address */
	mov	r1, #4096	/* map size */
	mov	r2, #3		/* PROT_READ | PROT_WRITE */
	mov	r3, #1		/* MAP_SHARED */
	mov	r5, #0		/* offset */
	mov	r7, #192	/* mmap2 */
	svc	#0

    mov r1,#1
    lsl r1,#24
    str r1,[r0,#4] /*Set GPIO 18 for output*/

	bl _init$
	bl loop$ /*call loop first time*/
	mov r10, r9 /*re-initialise arr index*/
	push {pc}
	bl _init_sort$
	str r1,[r0,#28]  /*turn LED on*/
	mov r3,#0x2D00000
	bl _timer$
	str r1,[r0,#40]  /*turn LED off*/
	mov r3,#0x2D00000
	bl _timer$
	str r1,[r0,#28]  /*turn LED on*/
	mov r3,#0x2D00000
	bl _timer$
	str r1,[r0,#40]  /*turn LED off*/
	mov r3,#0x2D00000
	bl _timer$
	str r1,[r0,#28]  /*turn LED on*/
	mov r3,#0x2D00000
	bl _timer$
	str r1,[r0,#40]  /*turn LED off*/
	bl _init$
	bl loop$
	end_loop$:
	b end_loop$
	
.data

arr: .word 3,1,2,1,4
gpiomem: .asciz	"/dev/gpiomem"