.data
    test_1: .word 0xFFFF
    test_2: .word 0x0710
    test_3: .word 0x80F3        
    str1:     .string "\nresult1 is  " 
    str2:     .string "\nresult2 is  " 
    str3:     .string "\nresult3 is  "  
.text
main:
        la a0, str1                # print "result1 is  " 
        li a7, 4
        ecall
        lw  a0, test_1           
        jal ra, fp16_to_fp32       # result1 = fp16_to_fp32(0x0710)      
        li a7, 1                   # print result1
        ecall
    
        la a0, str2                # print "result2 is  " 
        li a7, 4
        ecall
        lw  a0, test_2           
        jal ra, fp16_to_fp32       # result2 = fp16_to_fp32(0x0710)      
        li a7, 1                   # print result2
        ecall
        
        la a0, str3                # print "result3 is  " 
        li a7, 4
        ecall
        lw  a0, test_3           
        jal ra, fp16_to_fp32       # result3 = fp16_to_fp32(0x80F3)      
        li a7, 1                   # print result3
        ecall
        
        # Exit the program
        li a7, 10                  # System call code for exiting the program
        ecall                      # Make the exit system call
        
fp16_to_fp32:
        # a0 is h
        # t0 is w
        # t1 is sign
        # t2 is nonsign
        # t3 is renorm_shift 
        # t4 is inf_nan_mask 
        # t5 is zero_mask 
        slli t0, a0, 16            # w = (uint32_t) h << 16;
        li t2, 0x80000000
        and t1, t0, t2             # sign = w & UINT32_C(0x80000000);
        li t2, 0x7FFFFFFF
        and t2, t0, t2             # nonsign = w & UINT32_C(0x7FFFFFFF);
        mv t3, t2                  # renorm_shift = nonsign
                                   # renorm_shift = my_clz(nonsign) after my_clz labels
my_clz:
        # t3 is the input parameter x
        # t4 is r
        # t5 is c
        # t6 is tmp
        li t4, 0                    # r = 0
        li t6, 0x00010000           # tmp = 0x00010000
        sltu t5, t3, t6             # c = (x < 0x00010000)
        slli t5, t5, 4              # c = (x < 0x00010000) << 4;
        add t4, t4, t5              # r += c
        sll t3, t3, t5              # x <<= c
        
        slli t6, t6, 8             
        sltu t5, t3, t6             # c = (x < 0x01000000)
        slli t5, t5, 3              # c = (x < 0x01000000) << 3;
        add t4, t4, t5              # r += c
        sll t3, t3, t5              # x <<= c
        slli t6, t6, 4              
        sltu t5, t3, t6             # c = (x < 0x10000000)
        slli t5, t5, 2              # c = (x < 0x10000000) << 2;
        add t4, t4, t5              # r += c
        sll t3, t3, t5              # x <<= c
        srli t5, t3, 27             
        andi t5, t5, 0x1e           # c = (x >> (32 - 4 - 1))  & 0x1e
        li t3, 0x55af               
        srl t3, t3, t5              
        andi t3, t3, 3              
        add t3, t4, t3              # renorm_shift = r + (0x55af >> c) & 3
my_clz_end:                         # renorm_shift = my_clz(nonsign)
        li t4, 5
        bleu t3, t4, renorm_shift_zero # if renorm_shift <= 5, then renorm_shift = 0
renorm_shift_substract5:  
        addi t3, t3, -5             # else renorm_shift = renorm_shift - 5
        j renorm_shift_end
renorm_shift_zero:
        li t3, 0                    # renorm_shift = 0
renorm_shift_end:
        li t5, 0x04000000
        add t4, t2, t5              # inf_nan_mask = nonsign + 0x04000000
        srai t4, t4, 8              # inf_nan_mask = ((int32_t)(nonsign + 0x04000000) >> 8)
        li t5, 0x7F800000
        and t4, t4, t5              # inf_nan_mask = ((int32_t)(nonsign + 0x04000000) >> 8) & INT32_C(0x7F800000);
        addi t5, t2, -1             # zero_mask = (int32_t)(nonsign - 1)
        srai t5, t5, 31             # zero_mask = (int32_t)(nonsign - 1) >> 31;

        sll t2, t2, t3              
        srli t2, t2, 3              # tmp1 = nonsign << renorm_shift >> 3
        li t6, 0x70
        sub t3, t6, t3              # tmp2 = 0x70 - renorm_shift
        slli t3, t3, 23             # tmp2 = (0x70 - renorm_shift) << 23
        add t2, t2, t3              # tmp2 = (nonsign << renorm_shift >> 3) + ((0x70 - renorm_shift) << 23)
        
        or t2, t2, t4               # tmp2 = ((nonsign << renorm_shift >> 3) + ((0x70 - renorm_shift) << 23) | inf_nan_mask)
        not t5, t5                  # zero_mask = ~zero_mask
        and t2, t2, t5              # tmp2 = ((((nonsign << renorm_shift >> 3) + ((0x70 - renorm_shift) << 23)) | inf_nan_mask) & ~zero_mask)
        
        ori a0, t1, 0               # result = sign
        or a0, a0, t2               # result = sign | ((((nonsign << renorm_shift >> 3) + ((0x70 - renorm_shift) << 23)) | inf_nan_mask) & ~zero_mask)
        ret                         # return result