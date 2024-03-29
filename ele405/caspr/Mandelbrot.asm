.arch rhody_fp			;use rhody_fp.cfg
.outfmt hex			;output format is hex
.memsize 2048			;specify 2K words
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Program variables in System Data memory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Define part to be included in user's program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.define tx	0x0900	;text video X (0 - 99)
.define ty	0x0901	;text video Y (0 - 59)
.define taddr	0x0902	;text video address
.define tascii	0x0903	;text video ASCII code
.define cursor	0x0904	;ASCII for text cursor
.define prompt	0x0905	;prompt length for BS left limit
.define tnum	0x0906	;text video number to be printed
.define format	0x0907	;number output format
.define gx	0x0908	;graphic video X (0 - 639)
.define gy	0x0909	;graphic video Y (0 - 479)
.define gaddr	0x090A	;graphic video address
.define color	0x090B	;color for graphic
.define x1	0x090C	;x1 for line/circle
.define y1	0x090D	;y1
.define x2	0x090E	;x2 for line
.define y2	0x090F	;y2
.define rad	0x0910	;radius for circle
.define string	0x0911	;pointer to string
;Program variables;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.define lpx	0x0801	;loop X (0 to 639) -3200 before use
.define lpy	0x0802	;loop Y (0 to 479) -240 before use
.define cx	0x0803	;center point X
.define cy	0x0804	;center point Y
.define mx	0x0805	;scaled current x + CX
.define my	0x0806	;scaled current y + CY
.define scale	0x0807	;scale
.define real	0x0808
.define imag	0x0809
.define tmpx	0x080A	;save TX
.define tmpy	0x080B	;save TY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Initialize the system
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init:	sys	clear		;clear text video
	sys	clearg		;clear graphic video
	ldi	r0, 7
	stm	vcntrl, r0	;Video=Text xor Graphic
	ldi	r0, 0	
	stm	cx, r0		;CX=0
	stm	cy, r0		;CY=0
	stm	format, r0	;print numbers in decimal
	stm	time0, r0
	ldm	r0, init_scale	;initial scale=0.006
	stm	scale, r0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Mandelbrot with floating-point arithmetic
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Mand:	ldi	r0, 0
	stm	lpx, r0		;lpx starts at 0 (or -320)
	stm	lpy, r0		;lpy starts at 0 (or -240)
Man0:	ldm	r0, lpx		;r0=lpx
	ldi	r1, 320
	sub	r0, r1		;r0=lpx-320
	conv	r1, r0		;r1=lpx-320 in FP
	ldm	r2, lpy		;r2=lpy
	ldi	r0, 240
	sub	r0, r2		;r0=240-lpy
	conv	r2, r0		;r2=240-lpy in FP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;All arithmetic are floating point after this point
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldm	r3, scale
	fmul	r3, r1		;r3=(lpx-320)*scale
	ldm	r0, cx
	fadd	r3, r0		;r3=mx=cx+(lpx-320)*scale
	stm	real, r3	;save to REAL
	stm	mx, r3		;save to MX
	ldm	r4, scale
	fmul	r4, r2		;r4=(240-lpy)*scale
	ldm	r0, cy
	fadd	r4, r0		;r4=my=cy+(240-lpy)*scale
	stm	imag, r4	;save to IMAG
	stm	my, r4		;save to MY
	ldi	r7, 0		;r7=count=0 loop count
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Mandelbrot inner loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Man1:	ldm	r1, real	;r1=real
	ldm	r2, imag	;r2=imag
	mov	r3, r1		;r3=real
	fmul	r3, r3		;r3=real*real
	mov	r4, r2		;r4=imag
	fmul	r4, r4		;r4=imag*imag
	mov	r5, r3		;r5=real*real
	fsub	r5, r4		;r5=real*real - imag*imag
	ldm	r0, mx
	fadd	r5, r0		;r5=real*real - imag*imag + mx
	stm	real, r5	;update REAL
	ldm	r5, two		;r5=2 (in FP) 
	fmul	r5, r1		;r5=2*real
	fmul	r5, r2		;r5=2*real*imag
	ldm	r0, my
	fadd	r5, r0		;r5=2*real*imag+my
	stm	imag, r5	;update imag
	adi	r7, 1
	cmpi	r7, 256		;exceed loop count (convergence)
	jz	Man2
	fadd	r3, r4		;r3=real*real+imag*imag
	ldm	r6, limit
	fcmp	r3, r6	
	js	Man1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Mandelbrot draw pixel
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Man2:	ldm	r1, lpx
	stm	gx, r1		;GX=LPX
	ldm	r2, lpy
	stm	gy, r2		;GY=LPY
	stm	color, r7	;color=loop count
	sys	pixel		;draw one pixel
;
Man4:	ldm	r0, time0
	stm	tnum, r0
	ldi	r0, 0
	stm	tx, r0
	stm	ty, r0
	sys	printn
	ldi	r0, 0x0B	;'mu'
	stm	tascii, r0
	sys	putchar
	ldi	r0, S		;'S'
	stm	tascii, r0
	sys	putchar
;
	adi	r1, 1
	stm	lpx, r1
	cmpi	r1, 640		;exceed X limit?
	jnz	Man0
	ldi	r1, 0
	stm	lpx, r1		;reset lpy=0
	adi	r2, 1
	stm	lpy, r2
	cmpi	r2, 480		;exceed Y limit?
	jnz	Man0
halt:	jmp	halt
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Pre-stored constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
limit:
	word	0x41000000	;limit=8 in single precision FP
init_scale:
	word	0x3BC49BA6	;initial scale=0.006 in FP
two:	word	0x40000000	;2 in FP
half:	word	0x3F000000	;0.5in FP

