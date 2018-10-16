.arch rhody		;use rhody.cfg
.outfmt hex		;output format is hex
.memsize 2048		;specify 2K words
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Memory addresses for Rhody System I/O devices
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.define kcntrl	0xf0000	;keyboard control register
.define kascii	0xf0001	;keyboard ASCII code
.define vcntrl	0xf0002	;video control register
.define time0	0xf0003	;Timer 0
.define time1	0xf0004	;Timer 1
.define inport 	0xf0005	;GPIO read address
.define outport	0xf0005	;GPIO write address
.define rand	0xf0006	;random number
.define msx	0xf0007	;mouse X
.define msy	0xf0008	;mouse Y
.define msrb	0xf0009	;mouse right button
.define mslb	0xf000A	;mouse left button
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Library function constants for Rhody System Video
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.define ttop 	0x02000		;text video address
.define gtop 	0x100000	;graphic video address	
.define	gwidth	800		;graphic screen width
.define gheight	480		;graphic screen height
.define ginc	224		;graphic scren increment: 1024-800
.define gshift	22		;graphic address shift: 32-10
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Define part to be included in user's program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.define tx	0x0900	;text video X (0 - 79)
.define ty	0x0901	;text video Y (0 - 59)
.define taddr	0x0902	;text video address
.define tascii	0x0903	;text video ASCII code
.define cursor	0x0904	;ASCII for text cursor
.define prompt	0x0905	;prompt length for BS left limit
.define tnum	0x0906	;text video number to be printed
.define format	0x0907	;number output format
.define gx	0x0908	;graphic video X (0 - 799)
.define gy	0x0909	;graphic video Y (0 - 479)
.define gaddr	0x090A	;graphic video address
.define color	0x090B	;color for graphic
.define x1	0x090C	;x1 for line/circle
.define y1	0x090D	;y1
.define x2	0x090E	;x2 for line
.define y2	0x090F	;y2
.define rad	0x0910	;radius for circle
.define string	0x0911	;pointer to string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Define part not to be included in user's program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.define deltax	0x0812	;parameters for line
.define deltay	0x0813
.define error	0x0814
.define ystep	0x0815
.define steep	0x0816
.define cf	0x0817	;parameters for circle
.define ddfx	0x0818
.define ddfy	0x0819
.define tmp0	0x081A	;temp holders for reg0-2
.define tmp1	0x081B
.define tmp2	0x081C
.define tmpx	0x081D	;temp holder for TX
.define tmpy	0x081E	;temp holder for TY
.define tmpa	0x081F	;temp holder for TASCII
.define tmpn	0x0820	;temp holder for TNUM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;			
.define matrix_C 0x0800	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ACC:	sys	clear		;clear text video
	sys	clearg
	ldi	r0, 0
	ldi	r1, 200		;r1 = x1
	ldi	r2, 200		;r2 = y1
	ldi	r4, 100		;r4 = rad
	ldi	r6, 0xD0
	stm	color, r6
	stm	format, r0	;force decimal output
	stm	tx, r0		;force (TX, TY) to (0, 0)
	stm	ty, r0
	stm	time0, r0	;start timer0
	
	call	solidc

	ldm	r0, time0
	ldi	r3, 0x0D	;ASCII CR
	stm	tascii, r3
	sys	putchar
	stm	tnum, r0
	sys	printn
	ldi	r0, 0x0B	;'mu'
	stm	tascii, r0
	sys	putchar
	ldi	r0, S		;'S'
	stm	tascii, r0
	sys	putchar
stop:	jmp	stop



solidc:	stm	tmpx, r1	
	stm	tmpy, r2
	add	r2, r4		;r2=y1+radius
	
	;stm	GX, r1
	;stm	GY, r2
	;sys	pixel		;draw at (x1, y1+rad)	
	
	push	r6
	push	r7
	mov	r6, r1
	mov	r7, r2
	call	pxl		;draw at (x1, y1+rad)
	pop	r7
	pop	r6	

	ldm	r2, tmpy
	sub	r2, r4		;r2=y1-radius
	
	;stm	GY, r2
	;sys	pixel		;draw at (x1, y1-rad)
	
	push	r7
	mov	r7, r2
	call	pxl		;draw at (x1, y1-rad)
	pop	r7
	
	ldm	r1, tmpx
	add	r1, r4
	mov	r3, r1		;x2=x1+radius	
	ldm	r1, tmpx
	sub	r1, r4
	ldm	r2, tmpy
	call	hlin		;hline (x1-rad, y1) to (x1+rad, y1)
	;
	ldi	r5, 0x0000	;r5=x=0
	mov	r6, r4		;r6=y=radius
	ldi	r0, 0x0001
	sub	r0, r6		;cf=1-radius
	stm	cf, r0
	ldi	r0, 0x0001	;ddfx=1
	stm	ddfx, r0
	ldi	r0, 0xfffe
	mul	r0, r6
	stm	ddfy, r0	;ddfy= -2 * radius
	;
scr1:	
	mov	r0, r5
	sub	r0, r6		;r0=x-y
	jns	scd		;done if x-y>=0
	ldm	r4, cf
	adi	r4, 0x0000
	jns	syi		;if cf >= 0
	;
	adi	r5, 0x0001	;x++
	ldm	r0, ddfx
	adi	r0, 0x0002	;ddf_x += 2
	stm	ddfx, r0
	ldm	r4, cf
	add	r4, r0		;cf += ddf_x
	stm	cf, r4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sdrw:	
	ldm	r1, tmpx	;r1=x1
	ldm	r2, tmpy	;r2=y1
	add	r1, r5		;X=x1+x
	add	r2, r6		;Y=y1+y
	mov	r3, r1
	ldm	r1, tmpx
	sub	r1, r5		;X=x1-x
	call	hlin		;hline (x1-x, y1+y) to (x1+x, y1+y)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldm	r2, tmpy
	sub	r2, r6		;Y=y1-y
	call	hlin		;hline (x1-x, y1-y) to (x1+x, y1-y)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldm	r1, tmpx	;r1=x1
	ldm	r2, tmpy	;r2=y1
	add	r1, r6		;X=x1+y
	add	r2, r5		;Y=y1+x
	mov	r3, r1
	ldm	r1, tmpx
	sub	r1, r6		;X=x1-y
	
	call	hlin		;hline (x1-y, y1+x) to (x1+y, y1+x)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldm	r2, tmpy
	sub	r2, r5		;Y=y1-x
	call	hlin		;hline (x1-y, y1-x) to (x1+y, y1-x)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	jmp	scr1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
syi:	
	adi	r6, 0xffff	;y--
	ldm	r0, ddfy
	adi	r0, 0x0002	;ddf_y += 2
	stm	ddfy, r0
	ldm	r4, cf
	add	r4, r0		;f += dff_y
	stm	cf, r4
	jmp	sdrw
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
scd:	
	ldm	r1, tmpx
	stm	x1, r1		;restore x1
	ldm	r2, tmpy
	stm	y1, r2		;restore y1
	ret			;solid circle complete

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;draws a horizontal line between (x1,y1) and (x2,y1)
;line color in "color"
;GIVEN:
;r1 = x1
;r2 = y1
;r3 = x2

;OP REGS:
;r5 = x1
;r6 = y1
;r7 = x2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
hlin:	
	push	r5
	push	r6
	push	r7

	mov	r5, r1
	mov	r6, r2
	mov	r7, r3

	;stm	GY, r6		;GY=y1=y2
	cmp 	r7, r5		;test x2-x1
	jns	hlp0	
	push	r5		;swap(x1, x2)
	mov	r5, r7		;if x2 < x1
	pop	r7
hlp0:	
	;stm	GX, r5		;update GX	
	;sys	pixel
	
	push	r6
	mov	r6, r5		;update GX
	call	pxl		;draw one pixel
	pop	r6	
	adi	r5, 0x0001	;x=x+1
	cmp 	r7, r5
	jns	hlp0		;if End point > X
	pop	r7
	pop	r6
	pop	r5	
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;sys4: calculates the memory address of graphic video
;base address: 0x00100000
;inputs: GX, GY
;return: GADDR=meory address
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
gp:	push	r1
	push	r2
	mov	r1, r6
	mov	r2, r7
	;ldm	r1, GX		;r1=GX
	;ldm	r2, GY		;r2=GY
	ror	r2, gshift	;rotate GY left by 10
	add	r2, r1		;r2=2**10*GY+GX
	ldi	r1, 0x0010	
	ror	r1, 16		;r3=00100000
	add	r2, r1		;add base address
	stm	gaddr, r2	;save to GADDR
	pop	r2
	pop	r1
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;sys6: draw one pixel on graphic video screen
;base address: 00100000
;inputs: GX, GY, COLOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pxl:	push	r0
	push	r1
	call	gp		;get address in gaddr
	ldm	r0, color	;get COLOR
	ldm	r1, gaddr	;get GADDR		
	str	r1, r0
	pop	r1
	pop	r0
	ret


