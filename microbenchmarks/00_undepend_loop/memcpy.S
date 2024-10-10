    .text
    .global     main_load
# void main_load(int loop);
# a0=loop
#
main_load:
    vsetivli x0, 31, e64, m1
.loop:
    vadd.vv v1, v0, v0
    vadd.vv v2, v0, v0
    vadd.vv v3, v0, v0
    vadd.vv v4, v0, v0
    vadd.vv v5, v0, v0
    vadd.vv v6, v0, v0
    vadd.vv v8, v0, v0
    vadd.vv v9, v0, v0
    vadd.vv v10, v0, v0
    vadd.vv v11, v0, v0
    vadd.vv v12, v0, v0
    vadd.vv v13, v0, v0
    vadd.vv v14, v0, v0
    vadd.vv v15, v0, v0
    vadd.vv v16, v0, v0
    vadd.vv v18, v0, v0
    vadd.vv v19, v0, v0
    vadd.vv v20, v0, v0
    vadd.vv v21, v0, v0
    vadd.vv v22, v0, v0
    vadd.vv v23, v0, v0
    vadd.vv v24, v0, v0
    vadd.vv v25, v0, v0
    vadd.vv v26, v0, v0
    vadd.vv v28, v0, v0
    vadd.vv v29, v0, v0
    vadd.vv v30, v0, v0
    vadd.vv v31, v0, v0
    vadd.vv v1,  v0, v0
    addi    a0, a0, -1
    bnez    a0, .loop    	# Any more?
    ret                 	# Return
