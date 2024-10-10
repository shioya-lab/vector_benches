#ifdef USE_RISCV_VECTOR

	.globl	spmv_vector
	.type	spmv_vector, @function
	// void spmv_vector(
	// a0 : int r,
	// a1 : const double* val,
	// a2 : const uint64_t* idx,
	// a3 : const double* x,
	// a4 : const uint64_t* ptr, double* y)

    #define    VREG_VEC_B   v24
    #define    VREG_VEC_A   v8
    #define    VREG_VEC_C   v16
    #define    LMUL         m1
spmv_vector:
	ble	    a0,zero,.L26
	slli	a0,a0,3
	add	    t6,a4,a0
.whole_loop:
	vsetvli	t5,zero,e64,LMUL,ta,mu
	ld	    a0,0(a4)
	ld	    a6,8(a4)
	vmv.v.i	VREG_VEC_C,0
	slli	t1,a0,3
	subw	a6,a6,a0
	add	t3,a2,t1
	add	t1,a1,t1
	ble	a6,zero,.final_reduc
.calc_loop:
	vsetvli	    a0,a6,e64,LMUL,ta,mu
	slli	    t4,a0,3
	subw	    a6,a6,a0
	vle64.v	    VREG_VEC_B,(t3)
	vle64.v	    VREG_VEC_A,(t1)
	vsll.vi	    VREG_VEC_B,VREG_VEC_B,3
	add	        t3,t3,t4
	vluxei64.v	VREG_VEC_B,(a3),VREG_VEC_B
	add	        t1,t1,t4
	vfmacc.vv	VREG_VEC_C,VREG_VEC_B,VREG_VEC_A
    bgt	        a6,zero,.calc_loop
.final_reduc:
	vsetvli	zero,t5,e64,m1,ta,mu
	vmv.v.i	VREG_VEC_B,0
	vsetvli	a0,zero,e64,LMUL,tu,mu
	addi	a4,a4,8
	vfredusum.vs	VREG_VEC_C,VREG_VEC_C,VREG_VEC_B
	vsetivli	zero,0,e64,m1,ta,mu
	vfmv.f.s	fa5,VREG_VEC_C
	fsd	fa5,0(a5)
	addi	a5,a5,8
	bne	t6,a4,.whole_loop
.L26:
	ret


#endif  // USE_RISCV_VECTOR
