    .text
    .global     main_load
# void main_load(int loop, int *base);
# a0=loop
#
main_load:
    vsetivli x0, 31, e64, m1
.loop:
    vle64.v v0, (a1)
    vadd.vv v1, v0, v0
    vadd.vv v2, v1, v1
    vadd.vv v3, v2, v2
    vadd.vv v4, v3, v3
    vadd.vv v5, v4, v4
    vadd.vv v6, v5, v5
    vadd.vv v7, v6, v6
    vadd.vv v8, v7, v7
    vadd.vv v9, v8, v8
    vadd.vv v10, v9, v9
    vadd.vv v11, v10, v10
    vadd.vv v12, v11, v11
    vadd.vv v13, v12, v12
    vadd.vv v14, v13, v13
    vadd.vv v15, v14, v14
    vadd.vv v16, v15, v15
    vadd.vv v18, v16, v16
    vadd.vv v19, v18, v18
    vadd.vv v20, v19, v19
    vadd.vv v21, v20, v20
    vadd.vv v22, v21, v21
    vadd.vv v23, v22, v22
    vadd.vv v24, v23, v23
    vadd.vv v25, v24, v24
    vadd.vv v26, v25, v25
    vadd.vv v28, v26, v26
    vadd.vv v29, v28, v28
    vadd.vv v30, v29, v29
    vadd.vv v31, v30, v30
    addi    a0, a0, -1
    addi    a1, a1, 0x100
    bnez    a0, .loop    	# Any more?
    ret                 	# Return
