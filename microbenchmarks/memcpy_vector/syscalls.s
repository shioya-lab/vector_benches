	.file	"syscalls.c"
	.option nopic
	.attribute arch, "rv64i2p0_m2p0_a2p0_f2p0_d2p0_c2p0_v1p0_zve32f1p0_zve32x1p0_zve64d1p0_zve64f1p0_zve64x1p0_zvl128b1p0_zvl32b1p0_zvl64b1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	1
	.type	sprintf_putch.0, @function
sprintf_putch.0:
	ld	a5,0(a1)
	sb	a0,0(a5)
	ld	a5,0(a1)
	addi	a5,a5,1
	sd	a5,0(a1)
	ret
	.size	sprintf_putch.0, .-sprintf_putch.0
	.align	1
	.globl	putchar
	.type	putchar, @function
putchar:
	lui	a1,%tprel_hi(buflen.1)
	add	a4,a1,tp,%tprel_add(buflen.1)
	lw	a6,%tprel_lo(buflen.1)(a4)
	lui	a2,%tprel_hi(.LANCHOR0)
	add	a5,a2,tp,%tprel_add(.LANCHOR0)
	addi	a5,a5,%tprel_lo(.LANCHOR0)
	add	a5,a5,a6
	addi	sp,sp,-112
	addiw	a3,a6,1
	sw	a3,%tprel_lo(buflen.1)(a4)
	sb	a0,0(a5)
	addi	a4,sp,63
	li	a5,10
	andi	a4,a4,-64
	beq	a0,a5,.L4
	li	a5,64
	beq	a3,a5,.L4
	li	a0,0
	addi	sp,sp,112
	jr	ra
.L4:
	li	a5,64
	sd	a5,0(a4)
	add	a2,a2,tp,%tprel_add(.LANCHOR0)
	li	a5,1
	sd	a5,8(a4)
	addi	a2,a2,%tprel_lo(.LANCHOR0)
	sd	a2,16(a4)
	sd	a3,24(a4)
	fence	iorw,iorw
	lla	a3,fromhost
	sd	a4,tohost,a5
.L6:
	ld	a5,0(a3)
	beq	a5,zero,.L6
	sd	zero,fromhost,a5
	fence	iorw,iorw
	add	a1,a1,tp,%tprel_add(buflen.1)
	sw	zero,%tprel_lo(buflen.1)(a1)
	ld	a5,0(a4)
	li	a0,0
	addi	sp,sp,112
	jr	ra
	.size	putchar, .-putchar
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align	3
.LC0:
	.string	"(null)"
	.text
	.align	1
	.type	vprintfmt.constprop.1, @function
vprintfmt.constprop.1:
	addi	sp,sp,-272
	sd	s0,264(sp)
	li	t1,37
	li	t5,85
	lla	t4,.L18
	j	.L102
.L14:
	beq	a4,zero,.L94
	ld	a4,0(a0)
	addi	a1,a1,1
	sb	a5,0(a4)
	ld	a5,0(a0)
	addi	a5,a5,1
	sd	a5,0(a0)
.L102:
	lbu	a5,0(a1)
	sext.w	a4,a5
	bne	a5,t1,.L14
	lbu	a3,1(a1)
	addi	a7,a1,1
	mv	a4,a7
	li	t0,32
	li	a6,-1
	li	t6,-1
	li	t3,0
.L15:
	addiw	a5,a3,-35
	andi	a5,a5,0xff
	addi	a1,a4,1
	bgtu	a5,t5,.L16
.L106:
	slli	a5,a5,2
	add	a5,a5,t4
	lw	a5,0(a5)
	add	a5,a5,t4
	jr	a5
	.section	.rodata
	.align	2
	.align	2
.L18:
	.word	.L32-.L18
	.word	.L16-.L18
	.word	.L31-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L30-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L27-.L18
	.word	.L28-.L18
	.word	.L16-.L18
	.word	.L27-.L18
	.word	.L26-.L18
	.word	.L26-.L18
	.word	.L26-.L18
	.word	.L26-.L18
	.word	.L26-.L18
	.word	.L26-.L18
	.word	.L26-.L18
	.word	.L26-.L18
	.word	.L26-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L25-.L18
	.word	.L24-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L23-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L22-.L18
	.word	.L21-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L20-.L18
	.word	.L16-.L18
	.word	.L77-.L18
	.word	.L16-.L18
	.word	.L16-.L18
	.word	.L17-.L18
	.text
.L94:
	ld	s0,264(sp)
	addi	sp,sp,272
	jr	ra
.L27:
	mv	t0,a3
	lbu	a3,1(a4)
	mv	a4,a1
	addi	a1,a4,1
	addiw	a5,a3,-35
	andi	a5,a5,0xff
	bleu	a5,t5,.L106
.L16:
	ld	a5,0(a0)
	mv	a1,a7
.L97:
	li	a4,37
	sb	a4,0(a5)
	ld	a5,0(a0)
	addi	a5,a5,1
	sd	a5,0(a0)
	j	.L102
.L26:
	addiw	a6,a3,-48
	lbu	a3,1(a4)
	li	a5,9
	addiw	a4,a3,-48
	sext.w	t2,a3
	bgtu	a4,a5,.L78
	mv	a4,a1
	li	s0,9
.L35:
	lbu	a3,1(a4)
	slliw	a5,a6,2
	addw	a5,a5,a6
	slliw	a5,a5,1
	addw	a5,a5,t2
	addiw	a1,a3,-48
	addi	a4,a4,1
	addiw	a6,a5,-48
	sext.w	t2,a3
	bleu	a1,s0,.L35
.L34:
	bge	t6,zero,.L15
	mv	t6,a6
	li	a6,-1
	j	.L15
.L32:
	lbu	a3,1(a4)
	mv	a4,a1
	j	.L15
.L31:
	ld	a5,0(a0)
	j	.L97
.L30:
	lw	a6,0(a2)
	lbu	a3,1(a4)
	addi	a2,a2,8
	mv	a4,a1
	j	.L34
.L21:
	ld	a5,0(a0)
	li	a4,48
	li	a6,16
	sb	a4,0(a5)
	ld	a5,0(a0)
	addi	a3,a2,8
	addi	a4,a5,1
	sd	a4,0(a0)
	li	a4,120
	sb	a4,1(a5)
	ld	a5,0(a0)
	addi	a5,a5,1
	sd	a5,0(a0)
.L62:
	ld	a4,0(a2)
	mv	a2,a3
.L61:
	remu	t3,a4,a6
	addi	a7,sp,4
	li	a3,1
	sw	t3,0(sp)
	bltu	a4,a6,.L107
.L69:
	divu	a4,a4,a6
	addi	a7,a7,4
	mv	t2,a3
	addiw	a3,a3,1
	remu	t3,a4,a6
	sw	t3,-4(a7)
	bgeu	a4,a6,.L69
.L68:
	addiw	a4,t6,-1
	addiw	a6,a3,-1
	ble	t6,a3,.L67
.L70:
	sb	t0,0(a5)
	ld	a5,0(a0)
	addiw	a4,a4,-1
	addi	a5,a5,1
	sd	a5,0(a0)
	bne	a6,a4,.L70
.L67:
	slli	t2,t2,2
	add	a3,sp,t2
	addi	a7,sp,-4
	li	a6,9
	j	.L74
.L108:
	addiw	a4,a4,48
.L99:
	sb	a4,0(a5)
	ld	a5,0(a0)
	addi	a3,a3,-4
	addi	a5,a5,1
	sd	a5,0(a0)
	beq	a7,a3,.L102
.L74:
	lw	a4,0(a3)
	bleu	a4,a6,.L108
	addiw	a4,a4,87
	j	.L99
.L24:
	li	a5,1
	addi	a3,a2,8
	bgt	t3,a5,.L105
	beq	t3,zero,.L59
.L105:
	ld	a4,0(a2)
.L58:
	ld	a5,0(a0)
	blt	a4,zero,.L60
	mv	a2,a3
	li	a6,10
	j	.L61
.L23:
	lbu	a3,1(a4)
	addiw	t3,t3,1
	mv	a4,a1
	j	.L15
.L17:
	li	a6,16
.L19:
	li	a4,1
	ld	a5,0(a0)
	addi	a3,a2,8
	bgt	t3,a4,.L62
	bne	t3,zero,.L62
	lwu	a4,0(a2)
	mv	a2,a3
	j	.L61
.L20:
	ld	a4,0(a2)
	addi	a2,a2,8
	beq	a4,zero,.L38
	ble	t6,zero,.L95
	li	a5,45
	bne	t0,a5,.L40
	lbu	a5,0(a4)
	beq	a5,zero,.L42
.L41:
	bge	a6,zero,.L109
	ld	a3,0(a0)
	addiw	t6,t6,-1
	mv	a7,t6
	sb	a5,0(a3)
	ld	a5,0(a0)
	addi	a6,a4,1
	addi	a5,a5,1
	sd	a5,0(a0)
	lbu	a3,1(a4)
	beq	a3,zero,.L55
	mv	a4,a6
.L52:
	sb	a3,0(a5)
	ld	a5,0(a0)
	addi	a4,a4,1
	addi	a5,a5,1
	sd	a5,0(a0)
	lbu	a3,0(a4)
	bne	a3,zero,.L52
	subw	a5,a6,a4
	addw	t6,a5,a7
.L55:
	ble	t6,zero,.L102
.L42:
	ld	a5,0(a0)
	li	a4,32
.L56:
	sb	a4,0(a5)
	ld	a5,0(a0)
	addiw	t6,t6,-1
	addi	a5,a5,1
	sd	a5,0(a0)
	bne	t6,zero,.L56
	j	.L102
.L80:
	lla	a4,.LC0
.L40:
	mv	a5,a4
	add	a7,a4,a6
	bne	a6,zero,.L43
	j	.L44
.L46:
	addi	a5,a5,1
	beq	a5,a7,.L103
.L43:
	lbu	a3,0(a5)
	bne	a3,zero,.L46
.L103:
	subw	a5,a5,a4
	subw	t6,t6,a5
	ble	t6,zero,.L95
.L44:
	ld	a5,0(a0)
.L48:
	sb	t0,0(a5)
	ld	a5,0(a0)
	addiw	t6,t6,-1
	addi	a5,a5,1
	sd	a5,0(a0)
	bne	t6,zero,.L48
.L95:
	lbu	a5,0(a4)
	bne	a5,zero,.L41
	j	.L102
.L28:
	not	a5,t6
	srai	a5,a5,63
	and	a5,t6,a5
	lbu	a3,1(a4)
	sext.w	t6,a5
	mv	a4,a1
	j	.L15
.L25:
	lw	a4,0(a2)
	ld	a5,0(a0)
	addi	a2,a2,8
	sb	a4,0(a5)
	ld	a5,0(a0)
	addi	a5,a5,1
	sd	a5,0(a0)
	j	.L102
.L107:
	li	t2,0
	j	.L68
.L59:
	lw	a4,0(a2)
	j	.L58
.L77:
	li	a6,10
	j	.L19
.L22:
	li	a6,8
	j	.L19
.L60:
	li	a2,45
	sb	a2,0(a5)
	ld	a5,0(a0)
	neg	a4,a4
	mv	a2,a3
	addi	a5,a5,1
	sd	a5,0(a0)
	li	a6,10
	j	.L61
.L38:
	ble	t6,zero,.L104
	li	a5,45
	bne	t0,a5,.L80
.L104:
	lla	a4,.LC0
	li	a5,40
	j	.L41
.L109:
	li	a7,-1
.L76:
	addiw	a6,a6,-1
	beq	a6,a7,.L55
	ld	a3,0(a0)
	addi	a4,a4,1
	addiw	t6,t6,-1
	sb	a5,0(a3)
	ld	a5,0(a0)
	addi	a5,a5,1
	sd	a5,0(a0)
	lbu	a5,0(a4)
	bne	a5,zero,.L76
	j	.L55
.L78:
	mv	a4,a1
	j	.L34
	.size	vprintfmt.constprop.1, .-vprintfmt.constprop.1
	.align	1
	.type	vprintfmt.constprop.0, @function
vprintfmt.constprop.0:
	addi	sp,sp,-1184
	addi	a4,sp,335
	lui	a2,%tprel_hi(.LANCHOR0)
	andi	a4,a4,-64
	add	a2,a2,tp,%tprel_add(.LANCHOR0)
	lui	a3,%tprel_hi(buflen.1)
	sd	s9,1104(sp)
	sd	s10,1096(sp)
	sd	s11,1088(sp)
	sd	s0,1176(sp)
	sd	s1,1168(sp)
	sd	s2,1160(sp)
	sd	s3,1152(sp)
	sd	s4,1144(sp)
	sd	s5,1136(sp)
	sd	s6,1128(sp)
	sd	s7,1120(sp)
	sd	s8,1112(sp)
	li	a7,37
	add	a3,a3,tp,%tprel_add(buflen.1)
	addi	a2,a2,%tprel_lo(.LANCHOR0)
	li	s9,10
	li	a6,64
	li	s11,1
	addi	t2,a4,704
	lla	s10,tohost
	lla	a5,fromhost
.L111:
	lbu	t4,0(a0)
	sext.w	t5,t4
	beq	t4,a7,.L112
.L264:
	beq	t5,zero,.L255
	lw	t3,%tprel_lo(buflen.1)(a3)
	addi	a0,a0,1
	addiw	t1,t3,1
	add	t3,a2,t3
	sw	t1,%tprel_lo(buflen.1)(a3)
	sb	t4,0(t3)
	beq	t5,s9,.L114
	bne	t1,a6,.L111
.L114:
	sd	a6,704(a4)
	sd	s11,712(a4)
	sd	a2,720(a4)
	sd	t1,728(a4)
	fence	iorw,iorw
	sd	t2,0(s10)
.L116:
	ld	t1,0(a5)
	beq	t1,zero,.L116
	sd	zero,fromhost,t1
	fence	iorw,iorw
	sw	zero,%tprel_lo(buflen.1)(a3)
	lbu	t4,0(a0)
	ld	t1,704(a4)
	sext.w	t5,t4
	bne	t4,a7,.L264
.L112:
	lbu	t6,1(a0)
	addi	s3,a0,1
	mv	t5,s3
	li	s2,32
	li	t1,-1
	li	t3,-1
	li	t0,0
	li	s0,85
.L118:
	addiw	t4,t6,-35
	andi	t4,t4,0xff
	addi	a0,t5,1
	bgtu	t4,s0,.L119
.L265:
	lla	s1,.L121
	slli	t4,t4,2
	add	t4,t4,s1
	lw	t4,0(t4)
	add	t4,t4,s1
	jr	t4
	.section	.rodata
	.align	2
	.align	2
.L121:
	.word	.L135-.L121
	.word	.L119-.L121
	.word	.L134-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L133-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L130-.L121
	.word	.L131-.L121
	.word	.L119-.L121
	.word	.L130-.L121
	.word	.L129-.L121
	.word	.L129-.L121
	.word	.L129-.L121
	.word	.L129-.L121
	.word	.L129-.L121
	.word	.L129-.L121
	.word	.L129-.L121
	.word	.L129-.L121
	.word	.L129-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L128-.L121
	.word	.L127-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L126-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L125-.L121
	.word	.L124-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L123-.L121
	.word	.L119-.L121
	.word	.L204-.L121
	.word	.L119-.L121
	.word	.L119-.L121
	.word	.L120-.L121
	.text
.L255:
	ld	s0,1176(sp)
	ld	s1,1168(sp)
	ld	s2,1160(sp)
	ld	s3,1152(sp)
	ld	s4,1144(sp)
	ld	s5,1136(sp)
	ld	s6,1128(sp)
	ld	s7,1120(sp)
	ld	s8,1112(sp)
	ld	s9,1104(sp)
	ld	s10,1096(sp)
	ld	s11,1088(sp)
	addi	sp,sp,1184
	jr	ra
.L130:
	mv	s2,t6
	lbu	t6,1(t5)
	mv	t5,a0
	addi	a0,t5,1
	addiw	t4,t6,-35
	andi	t4,t4,0xff
	bleu	t4,s0,.L265
.L119:
	lui	t6,%tprel_hi(buflen.1)
	add	t4,t6,tp,%tprel_add(buflen.1)
	lw	t1,%tprel_lo(buflen.1)(t4)
	lui	s1,%tprel_hi(.LANCHOR0)
	add	a0,s1,tp,%tprel_add(.LANCHOR0)
	addiw	t3,t1,1
	addi	a0,a0,%tprel_lo(.LANCHOR0)
	add	t1,a0,t1
	sw	t3,%tprel_lo(buflen.1)(t4)
	li	t4,37
	sb	t4,0(t1)
	li	t1,64
	beq	t3,t1,.L266
	mv	a0,s3
	j	.L111
.L129:
	addiw	t1,t6,-48
	lbu	t6,1(t5)
	li	t5,9
	addiw	s1,t6,-48
	sext.w	t4,t6
	bgtu	s1,t5,.L205
	mv	t5,a0
	li	s4,9
.L138:
	lbu	t6,1(t5)
	slliw	a0,t1,2
	addw	a0,a0,t1
	slliw	a0,a0,1
	addw	a0,a0,t4
	addiw	s1,t6,-48
	addi	t5,t5,1
	addiw	t1,a0,-48
	sext.w	t4,t6
	bleu	s1,s4,.L138
.L137:
	bge	t3,zero,.L118
	mv	t3,t1
	li	t1,-1
	j	.L118
.L135:
	lbu	t6,1(t5)
	mv	t5,a0
	j	.L118
.L134:
	lui	t6,%tprel_hi(buflen.1)
	add	t5,t6,tp,%tprel_add(buflen.1)
	lw	t3,%tprel_lo(buflen.1)(t5)
	lui	s1,%tprel_hi(.LANCHOR0)
	add	t1,s1,tp,%tprel_add(.LANCHOR0)
	addiw	t4,t3,1
	addi	t1,t1,%tprel_lo(.LANCHOR0)
	add	t3,t1,t3
	sw	t4,%tprel_lo(buflen.1)(t5)
	li	t5,37
	sb	t5,0(t3)
	li	t3,64
	bne	t4,t3,.L111
	sd	t4,64(a4)
	li	t3,1
	sd	t3,72(a4)
	sd	t1,80(a4)
	sd	t4,88(a4)
	fence	iorw,iorw
	addi	t1,a4,64
	sd	t1,tohost,t3
	lla	t1,fromhost
.L201:
	ld	t3,0(t1)
	beq	t3,zero,.L201
	sd	zero,fromhost,t1
	fence	iorw,iorw
	add	t6,t6,tp,%tprel_add(buflen.1)
	ld	t1,64(a4)
	sw	zero,%tprel_lo(buflen.1)(t6)
	j	.L111
.L133:
	lw	t1,0(a1)
	lbu	t6,1(t5)
	addi	a1,a1,8
	mv	t5,a0
	j	.L137
.L124:
	lui	t6,%tprel_hi(buflen.1)
	add	s0,t6,tp,%tprel_add(buflen.1)
	lw	t5,%tprel_lo(buflen.1)(s0)
	lui	s1,%tprel_hi(.LANCHOR0)
	add	t4,s1,tp,%tprel_add(.LANCHOR0)
	addi	t4,t4,%tprel_lo(.LANCHOR0)
	add	s3,t4,t5
	addiw	t1,t5,1
	li	t0,48
	sb	t0,0(s3)
	sw	t1,%tprel_lo(buflen.1)(s0)
	li	s3,64
	beq	t1,s3,.L267
	addiw	t0,t5,2
	sw	t0,%tprel_lo(buflen.1)(s0)
	add	t5,t4,t1
	sext.w	t1,t0
	li	t0,120
	sb	t0,0(t5)
	bne	t1,s3,.L211
	sd	t1,256(a4)
	li	t5,1
	sd	t5,264(a4)
	sd	t4,272(a4)
	sd	t1,280(a4)
	fence	iorw,iorw
	addi	t1,a4,256
	sd	t1,tohost,t4
	lla	t1,fromhost
.L183:
	ld	t4,0(t1)
	beq	t4,zero,.L183
	sd	zero,fromhost,t1
	fence	iorw,iorw
	ld	t4,256(a4)
	add	t1,t6,tp,%tprel_add(buflen.1)
	sw	zero,%tprel_lo(buflen.1)(t1)
	li	t5,16
	li	t1,0
	addi	s0,a1,8
.L182:
	ld	t4,0(a1)
	mv	a1,s0
	j	.L177
.L127:
	li	t1,1
	addi	t5,a1,8
	bgt	t0,t1,.L263
	beq	t0,zero,.L175
.L263:
	ld	t4,0(a1)
.L174:
	lui	t6,%tprel_hi(buflen.1)
	add	t0,t6,tp,%tprel_add(buflen.1)
	lw	t1,%tprel_lo(buflen.1)(t0)
	blt	t4,zero,.L176
	mv	a1,t5
	lui	s1,%tprel_hi(.LANCHOR0)
	li	t5,10
.L177:
	remu	s3,t4,t5
	addi	s0,sp,20
	li	t0,1
	sw	s3,16(sp)
	bltu	t4,t5,.L268
.L190:
	divu	t4,t4,t5
	addi	s0,s0,4
	mv	s3,t0
	addiw	t0,t0,1
	remu	s4,t4,t5
	sw	s4,-4(s0)
	bgeu	t4,t5,.L190
.L189:
	addiw	t4,t3,-1
	addiw	s4,t0,-1
	ble	t3,t0,.L188
	add	t0,s1,tp,%tprel_add(.LANCHOR0)
	add	s0,t6,tp,%tprel_add(buflen.1)
	addi	t0,t0,%tprel_lo(.LANCHOR0)
	li	t5,64
	li	s7,1
	addi	s6,a4,192
	lla	s5,tohost
	lla	t3,fromhost
	j	.L193
.L191:
	addiw	t4,t4,-1
	beq	s4,t4,.L188
.L193:
	addiw	s8,t1,1
	add	t1,t0,t1
	sb	s2,0(t1)
	sw	s8,%tprel_lo(buflen.1)(s0)
	sext.w	t1,s8
	bne	t1,t5,.L191
	sd	t5,192(a4)
	sd	s7,200(a4)
	sd	t0,208(a4)
	sd	t5,216(a4)
	fence	iorw,iorw
	sd	s6,0(s5)
.L192:
	ld	t1,0(t3)
	beq	t1,zero,.L192
	sd	zero,fromhost,t1
	fence	iorw,iorw
	ld	t1,192(a4)
	sw	zero,%tprel_lo(buflen.1)(s0)
	addiw	t4,t4,-1
	li	t1,0
	bne	s4,t4,.L193
.L188:
	slli	s3,s3,2
	addi	s0,s3,16
	add	t0,s1,tp,%tprel_add(.LANCHOR0)
	add	t5,s0,sp
	addi	s3,sp,12
	li	s2,9
	addi	t0,t0,%tprel_lo(.LANCHOR0)
	li	s1,64
	li	s6,1
	addi	s5,a4,128
	lla	s4,tohost
	lla	t4,fromhost
	add	s0,t6,tp,%tprel_add(buflen.1)
	li	s7,10
	j	.L199
.L270:
	add	t1,t0,t1
	addiw	t3,t3,48
	sw	t6,%tprel_lo(buflen.1)(s0)
	sb	t3,0(t1)
.L195:
	mv	t1,t6
	beq	t6,s1,.L269
.L197:
	addi	t5,t5,-4
	beq	s3,t5,.L111
.L199:
	lw	t3,0(t5)
	addiw	t6,t1,1
	bleu	t3,s2,.L270
	addiw	t3,t3,87
	add	t1,t0,t1
	sw	t6,%tprel_lo(buflen.1)(s0)
	sb	t3,0(t1)
	bne	t3,s7,.L195
.L196:
	sd	s1,128(a4)
	sd	s6,136(a4)
	sd	t0,144(a4)
	sd	t6,152(a4)
	fence	iorw,iorw
	sd	s5,0(s4)
.L198:
	ld	t1,0(t4)
	beq	t1,zero,.L198
	sd	zero,fromhost,t1
	fence	iorw,iorw
	ld	t1,128(a4)
	sw	zero,%tprel_lo(buflen.1)(s0)
	li	t1,0
	j	.L197
.L126:
	lbu	t6,1(t5)
	addiw	t0,t0,1
	mv	t5,a0
	j	.L118
.L120:
	li	t5,16
.L122:
	lui	t6,%tprel_hi(buflen.1)
	add	t1,t6,tp,%tprel_add(buflen.1)
	li	t4,1
	lw	t1,%tprel_lo(buflen.1)(t1)
	addi	s0,a1,8
	bgt	t0,t4,.L271
	lui	s1,%tprel_hi(.LANCHOR0)
	bne	t0,zero,.L182
	lwu	t4,0(a1)
	lui	s1,%tprel_hi(.LANCHOR0)
	mv	a1,s0
	j	.L177
.L123:
	ld	s0,0(a1)
	addi	t0,a1,8
	beq	s0,zero,.L143
	ble	t3,zero,.L256
	li	a1,45
	bne	s2,a1,.L145
	lbu	a1,0(s0)
	sext.w	t4,a1
	bne	a1,zero,.L146
	j	.L147
.L256:
	lbu	a1,0(s0)
	sext.w	t4,a1
	beq	a1,zero,.L261
.L146:
	addi	s1,a4,512
	lui	s2,%tprel_hi(.LANCHOR0)
	lui	t6,%tprel_hi(buflen.1)
	add	s5,s2,tp,%tprel_add(.LANCHOR0)
	sd	s1,8(sp)
	sd	t0,0(sp)
	li	s8,-1
	add	s4,t6,tp,%tprel_add(buflen.1)
	addi	s5,s5,%tprel_lo(.LANCHOR0)
	li	s7,10
	li	s6,64
	lla	s1,fromhost
	blt	t1,zero,.L209
.L273:
	addiw	s3,t1,-1
	beq	s3,s8,.L258
.L168:
	lw	t0,%tprel_lo(buflen.1)(s4)
	addiw	t5,t0,1
	add	t0,s5,t0
	sw	t5,%tprel_lo(buflen.1)(s4)
	sb	a1,0(t0)
	beq	t4,s7,.L158
	beq	t5,s6,.L158
.L159:
	lbu	a1,1(s0)
	addiw	t3,t3,-1
	mv	t5,t3
	addi	s0,s0,1
	sext.w	t4,a1
	beq	a1,zero,.L258
	blt	t1,zero,.L272
	mv	t1,s3
	bge	t1,zero,.L273
.L209:
	mv	s3,t1
	j	.L168
.L131:
	not	t4,t3
	srai	t4,t4,63
	and	t3,t3,t4
	lbu	t6,1(t5)
	sext.w	t3,t3
	mv	t5,a0
	j	.L118
.L128:
	lui	t6,%tprel_hi(buflen.1)
	add	t5,t6,tp,%tprel_add(buflen.1)
	lw	t0,%tprel_lo(buflen.1)(t5)
	lui	s1,%tprel_hi(.LANCHOR0)
	lw	t4,0(a1)
	add	t3,s1,tp,%tprel_add(.LANCHOR0)
	addi	t3,t3,%tprel_lo(.LANCHOR0)
	add	t3,t3,t0
	addiw	t1,t0,1
	sb	t4,0(t3)
	sw	t1,%tprel_lo(buflen.1)(t5)
	li	t3,10
	beq	t4,t3,.L140
	li	t3,64
	beq	t1,t3,.L140
	addi	a1,a1,8
	j	.L111
.L140:
	li	t3,64
	sd	t3,640(a4)
	li	t4,1
	add	t3,s1,tp,%tprel_add(.LANCHOR0)
	sd	t4,648(a4)
	addi	t3,t3,%tprel_lo(.LANCHOR0)
	sd	t3,656(a4)
	sd	t1,664(a4)
	fence	iorw,iorw
	addi	t1,a4,640
	sd	t1,tohost,t3
	lla	t1,fromhost
.L142:
	ld	t3,0(t1)
	beq	t3,zero,.L142
	sd	zero,fromhost,t1
	fence	iorw,iorw
	add	t6,t6,tp,%tprel_add(buflen.1)
	ld	t1,640(a4)
	sw	zero,%tprel_lo(buflen.1)(t6)
	addi	a1,a1,8
	j	.L111
.L269:
	li	t6,64
	j	.L196
.L158:
	sd	s6,512(a4)
	li	a1,1
	sd	a1,520(a4)
	sd	s5,528(a4)
	sd	t5,536(a4)
	fence	iorw,iorw
	ld	t4,8(sp)
	lla	a1,tohost
	sd	t4,0(a1)
.L160:
	ld	a1,0(s1)
	beq	a1,zero,.L160
	sd	zero,fromhost,a1
	fence	iorw,iorw
	ld	a1,512(a4)
	sw	zero,%tprel_lo(buflen.1)(s4)
	j	.L159
.L272:
	add	s2,s2,tp,%tprel_add(.LANCHOR0)
	ld	t0,0(sp)
	mv	s1,s0
	add	t6,t6,tp,%tprel_add(buflen.1)
	addi	s2,s2,%tprel_lo(.LANCHOR0)
	li	s4,10
	li	s3,64
	li	s7,1
	addi	s6,a4,512
	lla	s5,tohost
	lla	t3,fromhost
	j	.L166
.L164:
	lbu	a1,1(s1)
	addi	s1,s1,1
	sext.w	t4,a1
	beq	a1,zero,.L274
.L166:
	lw	s8,%tprel_lo(buflen.1)(t6)
	addiw	t1,s8,1
	add	s8,s2,s8
	sw	t1,%tprel_lo(buflen.1)(t6)
	sb	a1,0(s8)
	beq	t4,s4,.L163
	bne	t1,s3,.L164
.L163:
	sd	s3,512(a4)
	sd	s7,520(a4)
	sd	s2,528(a4)
	sd	t1,536(a4)
	fence	iorw,iorw
	sd	s6,0(s5)
.L165:
	ld	a1,0(t3)
	beq	a1,zero,.L165
	sd	zero,fromhost,a1
	fence	iorw,iorw
	ld	a1,512(a4)
	sw	zero,%tprel_lo(buflen.1)(t6)
	j	.L164
.L271:
	ld	t4,0(a1)
	lui	s1,%tprel_hi(.LANCHOR0)
	mv	a1,s0
	j	.L177
.L261:
	mv	a1,t0
	j	.L111
.L258:
	ld	t0,0(sp)
.L169:
	ble	t3,zero,.L261
.L147:
	lui	t6,%tprel_hi(buflen.1)
	lui	s1,%tprel_hi(.LANCHOR0)
	add	t6,t6,tp,%tprel_add(buflen.1)
	add	s1,s1,tp,%tprel_add(.LANCHOR0)
	lw	a1,%tprel_lo(buflen.1)(t6)
	addi	s1,s1,%tprel_lo(.LANCHOR0)
	li	s2,32
	li	t5,64
	li	s4,1
	addi	s3,a4,448
	lla	s0,tohost
	lla	t1,fromhost
	j	.L172
.L170:
	addiw	t3,t3,-1
	beq	t3,zero,.L261
.L172:
	addiw	t4,a1,1
	add	a1,s1,a1
	sb	s2,0(a1)
	sw	t4,%tprel_lo(buflen.1)(t6)
	sext.w	a1,t4
	bne	a1,t5,.L170
	sd	t5,448(a4)
	sd	s4,456(a4)
	sd	s1,464(a4)
	sd	t5,472(a4)
	fence	iorw,iorw
	sd	s3,0(s0)
.L171:
	ld	a1,0(t1)
	beq	a1,zero,.L171
	sd	zero,fromhost,a1
	fence	iorw,iorw
	ld	a1,448(a4)
	sw	zero,%tprel_lo(buflen.1)(t6)
	li	a1,0
	j	.L170
.L268:
	li	s3,0
	j	.L189
.L274:
	addw	t3,t5,s0
	subw	t3,t3,s1
	j	.L169
.L175:
	lw	t4,0(a1)
	j	.L174
.L266:
	sd	t3,0(a4)
	li	t1,1
	sd	t1,8(a4)
	sd	a0,16(a4)
	sd	t3,24(a4)
	fence	iorw,iorw
	lla	t1,fromhost
	sd	a4,tohost,a0
.L203:
	ld	a0,0(t1)
	beq	a0,zero,.L203
	sd	zero,fromhost,a0
	fence	iorw,iorw
	ld	a0,0(a4)
	add	t6,t6,tp,%tprel_add(buflen.1)
	sw	zero,%tprel_lo(buflen.1)(t6)
	mv	a0,s3
	j	.L111
.L211:
	li	t5,16
	addi	s0,a1,8
	j	.L182
.L204:
	li	t5,10
	j	.L122
.L125:
	li	t5,8
	j	.L122
.L176:
	lui	s1,%tprel_hi(.LANCHOR0)
	add	a1,s1,tp,%tprel_add(.LANCHOR0)
	addiw	s0,t1,1
	addi	a1,a1,%tprel_lo(.LANCHOR0)
	add	s3,a1,t1
	sw	s0,%tprel_lo(buflen.1)(t0)
	li	t0,45
	sb	t0,0(s3)
	sext.w	t1,s0
	li	t0,64
	beq	t1,t0,.L275
.L178:
	mv	a1,t5
	neg	t4,t4
	li	t5,10
	j	.L177
.L267:
	sd	t1,320(a4)
	li	t5,1
	sd	t5,328(a4)
	sd	t4,336(a4)
	sd	t1,344(a4)
	fence	iorw,iorw
	addi	t1,a4,320
	sd	t1,tohost,t4
	lla	t1,fromhost
.L181:
	ld	t4,0(t1)
	beq	t4,zero,.L181
	sd	zero,fromhost,t1
	fence	iorw,iorw
	ld	t5,320(a4)
	add	t4,t6,tp,%tprel_add(buflen.1)
	li	t5,1
	add	t1,s1,tp,%tprel_add(.LANCHOR0)
	sw	t5,%tprel_lo(buflen.1)(t4)
	li	t4,120
	sb	t4,%tprel_lo(.LANCHOR0)(t1)
	li	t5,16
	li	t1,1
	addi	s0,a1,8
	j	.L182
.L143:
	ble	t3,zero,.L214
	li	a1,45
	bne	s2,a1,.L215
.L214:
	lla	s0,.LC0
	li	a1,40
	li	t4,40
	j	.L146
.L215:
	lla	s0,.LC0
.L145:
	mv	a1,s0
	add	t5,s0,t1
	bne	t1,zero,.L148
	j	.L149
.L151:
	addi	a1,a1,1
	beq	a1,t5,.L262
.L148:
	lbu	t4,0(a1)
	bne	t4,zero,.L151
.L262:
	subw	a1,a1,s0
	subw	t3,t3,a1
	ble	t3,zero,.L256
.L149:
	lui	t6,%tprel_hi(buflen.1)
	lui	s1,%tprel_hi(.LANCHOR0)
	add	t6,t6,tp,%tprel_add(buflen.1)
	add	s1,s1,tp,%tprel_add(.LANCHOR0)
	lw	a1,%tprel_lo(buflen.1)(t6)
	addi	s1,s1,%tprel_lo(.LANCHOR0)
	li	s3,64
	li	s6,1
	addi	s5,a4,576
	lla	s4,tohost
	lla	t4,fromhost
	j	.L155
.L153:
	addiw	t3,t3,-1
	beq	t3,zero,.L256
.L155:
	addiw	t5,a1,1
	add	a1,s1,a1
	sb	s2,0(a1)
	sw	t5,%tprel_lo(buflen.1)(t6)
	sext.w	a1,t5
	bne	a1,s3,.L153
	sd	s3,576(a4)
	sd	s6,584(a4)
	sd	s1,592(a4)
	sd	s3,600(a4)
	fence	iorw,iorw
	sd	s5,0(s4)
.L154:
	ld	a1,0(t4)
	beq	a1,zero,.L154
	sd	zero,fromhost,a1
	fence	iorw,iorw
	ld	a1,576(a4)
	sw	zero,%tprel_lo(buflen.1)(t6)
	li	a1,0
	j	.L153
.L275:
	sd	t1,384(a4)
	li	t0,1
	sd	t0,392(a4)
	sd	a1,400(a4)
	sd	t1,408(a4)
	fence	iorw,iorw
	addi	a1,a4,384
	sd	a1,tohost,t1
	lla	t1,fromhost
.L179:
	ld	a1,0(t1)
	beq	a1,zero,.L179
	sd	zero,fromhost,a1
	fence	iorw,iorw
	ld	a1,384(a4)
	li	t1,0
	add	a1,t6,tp,%tprel_add(buflen.1)
	sw	zero,%tprel_lo(buflen.1)(a1)
	j	.L178
.L205:
	mv	t5,a0
	j	.L137
	.size	vprintfmt.constprop.0, .-vprintfmt.constprop.0
	.section	.rodata.str1.8
	.align	3
.LC1:
	.string	"mcycle"
	.align	3
.LC2:
	.string	"minstret"
	.text
	.align	1
	.globl	setStats
	.type	setStats, @function
setStats:
 #APP
# 50 "syscalls.c" 1
	csrr a4, mcycle
# 0 "" 2
 #NO_APP
	lla	a5,.LANCHOR1
	beq	a0,zero,.L277
	sd	a4,0(a5)
 #APP
# 51 "syscalls.c" 1
	csrr a4, minstret
# 0 "" 2
 #NO_APP
	sd	a4,8(a5)
	ret
.L277:
	ld	a3,0(a5)
	lla	a2,.LC1
	sd	a2,16(a5)
	sub	a4,a4,a3
	sd	a4,0(a5)
 #APP
# 51 "syscalls.c" 1
	csrr a4, minstret
# 0 "" 2
 #NO_APP
	ld	a3,8(a5)
	lla	a2,.LC2
	sd	a2,24(a5)
	sub	a4,a4,a3
	sd	a4,8(a5)
	ret
	.size	setStats, .-setStats
	.align	1
	.globl	tohost_exit
	.type	tohost_exit, @function
tohost_exit:
	slli	a5,a0,1
	ori	a5,a5,1
	sd	a5,tohost,a4
.L280:
	j	.L280
	.size	tohost_exit, .-tohost_exit
	.align	1
	.weak	handle_trap
	.type	handle_trap, @function
handle_trap:
	li	a5,4096
	addi	a5,a5,-1421
	sd	a5,tohost,a4
.L282:
	j	.L282
	.size	handle_trap, .-handle_trap
	.align	1
	.globl	exit
	.type	exit, @function
exit:
	addi	sp,sp,-16
	sd	ra,8(sp)
	call	tohost_exit
	.size	exit, .-exit
	.align	1
	.globl	abort
	.type	abort, @function
abort:
	li	a5,269
	sd	a5,tohost,a4
.L286:
	j	.L286
	.size	abort, .-abort
	.align	1
	.globl	printstr
	.type	printstr, @function
printstr:
	lbu	a5,0(a0)
	addi	sp,sp,-112
	addi	a3,sp,63
	andi	a3,a3,-64
	beq	a5,zero,.L291
	mv	a5,a0
.L289:
	lbu	a4,1(a5)
	addi	a5,a5,1
	bne	a4,zero,.L289
	sub	a5,a5,a0
.L288:
	li	a4,64
	sd	a4,0(a3)
	li	a4,1
	sd	a4,8(a3)
	sd	a0,16(a3)
	sd	a5,24(a3)
	fence	iorw,iorw
	lla	a4,fromhost
	sd	a3,tohost,a5
.L290:
	ld	a5,0(a4)
	beq	a5,zero,.L290
	sd	zero,fromhost,a5
	fence	iorw,iorw
	ld	a5,0(a3)
	addi	sp,sp,112
	jr	ra
.L291:
	li	a5,0
	j	.L288
	.size	printstr, .-printstr
	.align	1
	.weak	thread_entry
	.type	thread_entry, @function
thread_entry:
	beq	a0,zero,.L296
.L298:
	j	.L298
.L296:
	ret
	.size	thread_entry, .-thread_entry
	.section	.rodata.str1.8
	.align	3
.LC3:
	.string	"Implement main(), foo!\n"
	.section	.text.startup,"ax",@progbits
	.align	1
	.weak	main
	.type	main, @function
main:
	addi	sp,sp,-16
	lla	a0,.LC3
	sd	ra,8(sp)
	call	printstr
	ld	ra,8(sp)
	li	a0,-1
	addi	sp,sp,16
	jr	ra
	.size	main, .-main
	.text
	.align	1
	.globl	printhex
	.type	printhex, @function
printhex:
	addi	sp,sp,-192
	andi	a4,a0,15
	addi	a3,sp,95
	sd	s0,184(sp)
	sd	s1,176(sp)
	sd	s2,168(sp)
	sd	s3,160(sp)
	sd	s4,152(sp)
	li	a5,9
	andi	a3,a3,-64
	mv	a1,a4
	li	t2,48
	bleu	a4,a5,.L302
	li	t2,87
.L302:
	srli	a5,a0,4
	andi	a2,a5,15
	li	a4,9
	add	t2,t2,a1
	mv	a5,a2
	li	t0,87
	bgtu	a2,a4,.L303
	li	t0,48
.L303:
	srli	t6,a0,8
	andi	a2,t6,15
	li	a4,9
	add	t0,t0,a5
	mv	t6,a2
	li	a5,87
	bgtu	a2,a4,.L304
	li	a5,48
.L304:
	srli	t5,a0,12
	andi	a2,t5,15
	li	a4,9
	add	t6,t6,a5
	mv	t5,a2
	li	a5,87
	bgtu	a2,a4,.L305
	li	a5,48
.L305:
	srli	t4,a0,16
	andi	a2,t4,15
	li	a4,9
	add	t5,t5,a5
	mv	t4,a2
	li	a5,87
	bgtu	a2,a4,.L306
	li	a5,48
.L306:
	srli	t3,a0,20
	andi	a2,t3,15
	li	a4,9
	add	t4,t4,a5
	mv	t3,a2
	li	a5,87
	bgtu	a2,a4,.L307
	li	a5,48
.L307:
	srli	t1,a0,24
	andi	a1,t1,15
	li	a2,9
	add	t3,t3,a5
	mv	t1,a1
	li	a4,87
	bgtu	a1,a2,.L308
	li	a4,48
.L308:
	srliw	a5,a0,28
	li	a2,9
	add	t1,t1,a4
	mv	s0,a5
	li	a4,87
	bgtu	a5,a2,.L309
	li	a4,48
.L309:
	srli	a7,a0,32
	andi	a1,a7,15
	li	a2,9
	add	s0,s0,a4
	mv	a7,a1
	li	a5,87
	bgtu	a1,a2,.L310
	li	a5,48
.L310:
	srli	a6,a0,36
	andi	a1,a6,15
	li	a2,9
	add	a7,a7,a5
	mv	a6,a1
	li	a4,87
	bgtu	a1,a2,.L311
	li	a4,48
.L311:
	srli	a5,a0,40
	andi	s1,a5,15
	li	a1,9
	add	a6,a6,a4
	li	a2,87
	mv	a4,s1
	bgtu	s1,a1,.L312
	li	a2,48
.L312:
	srli	a5,a0,44
	andi	s2,a5,15
	li	a1,9
	add	s1,a4,a2
	mv	a4,s2
	li	a2,87
	bgtu	s2,a1,.L313
	li	a2,48
.L313:
	srli	a5,a0,48
	andi	s3,a5,15
	li	s2,9
	add	a1,a4,a2
	mv	a4,s3
	li	a2,87
	bgtu	s3,s2,.L314
	li	a2,48
.L314:
	srli	a5,a0,52
	andi	s4,a5,15
	li	s3,9
	add	a2,a4,a2
	li	s2,87
	mv	a4,s4
	bgtu	s4,s3,.L315
	li	s2,48
.L315:
	srli	a5,a0,56
	andi	s4,a5,15
	li	s3,9
	add	a4,a4,s2
	mv	a5,s4
	li	s2,87
	bgtu	s4,s3,.L316
	li	s2,48
.L316:
	srli	s4,a0,60
	li	s3,9
	add	a5,a5,s2
	bleu	s4,s3,.L317
	addi	a0,s4,87
	addi	s2,sp,8
.L318:
	sb	a5,9(sp)
	sb	t2,23(sp)
	sb	t0,22(sp)
	sb	t6,21(sp)
	sb	t5,20(sp)
	sb	t4,19(sp)
	sb	t3,18(sp)
	sb	t1,17(sp)
	sb	s0,16(sp)
	sb	a7,15(sp)
	sb	a6,14(sp)
	sb	s1,13(sp)
	sb	a1,12(sp)
	sb	a2,11(sp)
	sb	a4,10(sp)
	sb	a0,8(sp)
	sb	zero,24(sp)
	mv	a5,s2
.L319:
	lbu	a4,1(a5)
	addi	a5,a5,1
	bne	a4,zero,.L319
	li	a4,64
	sd	a4,0(a3)
	li	a4,1
	sd	a4,8(a3)
	sd	s2,16(a3)
	sub	a5,a5,s2
	sd	a5,24(a3)
	fence	iorw,iorw
	lla	a4,fromhost
	sd	a3,tohost,a5
.L320:
	ld	a5,0(a4)
	beq	a5,zero,.L320
	sd	zero,fromhost,a5
	fence	iorw,iorw
	ld	s0,184(sp)
	ld	s1,176(sp)
	ld	s2,168(sp)
	ld	s3,160(sp)
	ld	s4,152(sp)
	ld	a5,0(a3)
	addi	sp,sp,192
	jr	ra
.L317:
	addi	a0,s4,48
	addi	s2,sp,8
	j	.L318
	.size	printhex, .-printhex
	.align	1
	.globl	printf
	.type	printf, @function
printf:
	addi	sp,sp,-96
	addi	t1,sp,40
	sd	a1,40(sp)
	mv	a1,t1
	sd	ra,24(sp)
	sd	a2,48(sp)
	sd	a3,56(sp)
	sd	a4,64(sp)
	sd	a5,72(sp)
	sd	a6,80(sp)
	sd	a7,88(sp)
	sd	t1,8(sp)
	call	vprintfmt.constprop.0
	ld	ra,24(sp)
	li	a0,0
	addi	sp,sp,96
	jr	ra
	.size	printf, .-printf
	.align	1
	.globl	sprintf
	.type	sprintf, @function
sprintf:
	addi	sp,sp,-96
	addi	t1,sp,48
	sd	s0,32(sp)
	sd	a0,8(sp)
	sd	a2,48(sp)
	mv	s0,a0
	mv	a2,t1
	addi	a0,sp,8
	sd	ra,40(sp)
	sd	a3,56(sp)
	sd	a4,64(sp)
	sd	a5,72(sp)
	sd	a6,80(sp)
	sd	a7,88(sp)
	sd	t1,24(sp)
	call	vprintfmt.constprop.1
	ld	a0,8(sp)
	sb	zero,0(a0)
	ld	ra,40(sp)
	subw	a0,a0,s0
	ld	s0,32(sp)
	addi	sp,sp,96
	jr	ra
	.size	sprintf, .-sprintf
	.align	1
	.globl	memcpy
	.type	memcpy, @function
memcpy:
	or	a5,a0,a1
	or	a5,a5,a2
	andi	a5,a5,7
	add	a6,a0,a2
	beq	a5,zero,.L346
	bleu	a6,a0,.L365
	addi	a5,a1,1
	csrr	a4,vlenb
	sub	a6,a0,a5
	addi	a3,a4,-2
	bleu	a6,a3,.L353
	mv	a5,a0
.L354:
	vsetvli	a3,a2,e8,m1,ta,mu
	vle8.v	v24,(a1)
	sub	a2,a2,a3
	vse8.v	v24,(a5)
	add	a1,a1,a4
	add	a5,a5,a4
	bne	a2,zero,.L354
	ret
.L346:
	bleu	a6,a0,.L359
	addi	a2,a2,-1
	li	a5,7
	bleu	a2,a5,.L357
	addi	a4,a1,8
	csrr	a3,vlenb
	sub	t1,a0,a4
	addi	a7,a3,-16
	mv	a5,a0
	bgtu	t1,a7,.L366
.L351:
	ld	a3,-8(a4)
	addi	a5,a5,8
	addi	a4,a4,8
	sd	a3,-8(a5)
	bltu	a5,a6,.L351
.L359:
	ret
.L365:
	ret
.L366:
	srli	a2,a2,3
	mv	a4,a0
	addi	a5,a2,1
.L350:
	vsetvli	a2,a5,e64,m1,ta,mu
	vle64.v	v24,(a1)
	sub	a5,a5,a2
	vse64.v	v24,(a4)
	add	a1,a1,a3
	add	a4,a4,a3
	bne	a5,zero,.L350
	ret
.L357:
	mv	a5,a0
	addi	a4,a1,8
	j	.L351
.L353:
	add	a1,a1,a2
	mv	a4,a0
	j	.L355
.L367:
	addi	a5,a5,1
.L355:
	lbu	a3,-1(a5)
	addi	a4,a4,1
	sb	a3,-1(a4)
	bne	a1,a5,.L367
	ret
	.size	memcpy, .-memcpy
	.align	1
	.globl	memset
	.type	memset, @function
memset:
	or	a5,a0,a2
	andi	a4,a5,7
	add	a6,a0,a2
	mv	a5,a0
	beq	a4,zero,.L369
	vsetvli	a4,zero,e8,m1,ta,mu
	csrr	a3,vlenb
	vmv.v.x	v24,a1
	bleu	a6,a0,.L378
.L373:
	vsetvli	a4,a2,e8,m1,ta,mu
	vse8.v	v24,(a5)
	sub	a2,a2,a4
	add	a5,a5,a3
	bne	a2,zero,.L373
.L374:
	ret
.L369:
	andi	a1,a1,0xff
	ld	a4,.LC4
	mul	a1,a1,a4
	bleu	a6,a0,.L374
	addi	a2,a2,-1
	srli	a2,a2,3
	addi	a2,a2,1
	csrr	a3,vlenb
	vsetvli	a4,zero,e64,m1,ta,mu
	vmv.v.x	v24,a1
.L372:
	vsetvli	a4,a2,e64,m1,ta,mu
	vse64.v	v24,(a5)
	sub	a2,a2,a4
	add	a5,a5,a3
	bne	a2,zero,.L372
	ret
.L378:
	ret
	.size	memset, .-memset
	.section	.rodata.str1.8
	.align	3
.LC5:
	.string	"%s = %d\n"
	.text
	.align	1
	.globl	_init
	.type	_init, @function
_init:
	addi	sp,sp,-176
	lla	a5,_tdata_begin
	sd	s4,128(sp)
	lla	s4,_tdata_end
	sd	s3,136(sp)
	sub	s3,s4,a5
	sd	s1,152(sp)
	sd	s2,144(sp)
	mv	s1,a0
	mv	s2,a1
	mv	a0,tp
	mv	a1,a5
	mv	a2,s3
	sd	ra,168(sp)
	sd	s0,160(sp)
	sd	s5,120(sp)
	mv	s5,tp
	call	memcpy
	lla	a2,_tbss_end
	sub	a2,a2,s4
	li	a1,0
	add	a0,s5,s3
	call	memset
	mv	a1,s2
	mv	a0,s1
	call	thread_entry
	li	a1,0
	li	a0,0
	call	main
	lla	s2,.LANCHOR1
	ld	a3,0(s2)
	addi	s0,sp,63
	andi	s0,s0,-64
	mv	s1,a0
	bne	a3,zero,.L391
	ld	a3,8(s2)
	bne	a3,zero,.L392
.L383:
	mv	a0,s1
	call	tohost_exit
.L392:
	mv	s3,s0
.L384:
	ld	a2,24(s2)
	mv	a0,s3
	lla	a1,.LC5
	call	sprintf
	add	s3,s3,a0
.L381:
	beq	s0,s3,.L383
	mv	a0,s0
	call	printstr
	j	.L383
.L391:
	ld	a2,16(s2)
	lla	a1,.LC5
	mv	a0,s0
	call	sprintf
	ld	a3,8(s2)
	add	s3,s0,a0
	beq	a3,zero,.L381
	j	.L384
	.size	_init, .-_init
	.align	1
	.globl	strlen
	.type	strlen, @function
strlen:
	lbu	a5,0(a0)
	beq	a5,zero,.L396
	mv	a5,a0
.L395:
	lbu	a4,1(a5)
	addi	a5,a5,1
	bne	a4,zero,.L395
	sub	a0,a5,a0
	ret
.L396:
	li	a0,0
	ret
	.size	strlen, .-strlen
	.align	1
	.globl	strnlen
	.type	strnlen, @function
strnlen:
	add	a3,a0,a1
	mv	a5,a0
	bne	a1,zero,.L401
	j	.L405
.L402:
	addi	a5,a5,1
	beq	a3,a5,.L406
.L401:
	lbu	a4,0(a5)
	bne	a4,zero,.L402
	sub	a0,a5,a0
	ret
.L406:
	sub	a0,a3,a0
	ret
.L405:
	li	a0,0
	ret
	.size	strnlen, .-strnlen
	.align	1
	.globl	strcmp
	.type	strcmp, @function
strcmp:
.L409:
	lbu	a5,0(a0)
	addi	a1,a1,1
	addi	a0,a0,1
	lbu	a4,-1(a1)
	beq	a5,zero,.L410
	beq	a5,a4,.L409
	sext.w	a0,a5
.L408:
	subw	a0,a0,a4
	ret
.L410:
	li	a0,0
	j	.L408
	.size	strcmp, .-strcmp
	.align	1
	.globl	strcpy
	.type	strcpy, @function
strcpy:
	mv	a5,a0
.L413:
	lbu	a4,0(a1)
	addi	a5,a5,1
	addi	a1,a1,1
	sb	a4,-1(a5)
	bne	a4,zero,.L413
	ret
	.size	strcpy, .-strcpy
	.align	1
	.globl	atol
	.type	atol, @function
atol:
	lbu	a3,0(a0)
	li	a4,32
	mv	a5,a0
	bne	a3,a4,.L416
.L417:
	lbu	a3,1(a5)
	addi	a5,a5,1
	beq	a3,a4,.L417
.L416:
	li	a4,45
	beq	a3,a4,.L418
	li	a4,43
	beq	a3,a4,.L437
	li	a1,0
	beq	a3,zero,.L436
.L423:
	li	a0,0
.L421:
	addi	a5,a5,1
	slli	a4,a0,2
	addiw	a2,a3,-48
	lbu	a3,0(a5)
	add	a4,a4,a0
	slli	a4,a4,1
	add	a0,a2,a4
	bne	a3,zero,.L421
	beq	a1,zero,.L415
	neg	a0,a0
	ret
.L437:
	lbu	a3,1(a5)
	li	a1,0
	addi	a5,a5,1
	bne	a3,zero,.L423
.L436:
	li	a0,0
.L415:
	ret
.L418:
	lbu	a3,1(a5)
	li	a1,1
	addi	a5,a5,1
	bne	a3,zero,.L423
	li	a0,0
	j	.L415
	.size	atol, .-atol
	.section	.srodata.cst8,"aM",@progbits,8
	.align	3
.LC4:
	.dword	72340172838076673
	.bss
	.align	3
	.set	.LANCHOR1,. + 0
	.type	counters, @object
	.size	counters, 16
counters:
	.zero	16
	.type	counter_names, @object
	.size	counter_names, 16
counter_names:
	.zero	16
	.section	.tbss,"awT",@nobits
	.align	6
	.set	.LANCHOR0,. + 0
	.type	buf.2, @object
	.size	buf.2, 64
buf.2:
	.zero	64
	.type	buflen.1, @object
	.size	buflen.1, 4
buflen.1:
	.zero	4
	.ident	"GCC: () 12.0.1 20220505 (prerelease)"
