.data
    datas: .word 0x0710, 0x311F, 0x000F, 0x0000, 0x8000, 0x7C00, 0xFC00, 0x7CFF
    ans: .word 0x38e20000, 0x3e23e000, 0x35700000, 0x0, 0x80000000, 0x7f800000, 0xff800000, 0x7f9fe000
    str1:     .string "\nfp16_to_fp32(0x0710) is : " 
    str2:     .string "\nfp16_to_fp32(0x311F) is : " 
    str3:     .string "\nfp16_to_fp32(0x000F) is : " 
    str4:     .string "\nfp16_to_fp32(0x0000) is : " 
    str5:     .string "\nfp16_to_fp32(0x8000) is : " 
    str6:     .string "\nfp16_to_fp32(0x7C00) is : " 
    str7:     .string "\nfp16_to_fp32(0xFC00) is : " 
    str8:     .string "\nfp16_to_fp32(0x7CFF) is : " 
    strError: .string "\nthe answer is wrong!!!"
    strs:     .word str1, str2, str3, str4, str5, str6, str7, str8
.text
main:
        la s6, ans                 # Load ans reference
        la s7, datas               # Load datas reference
        la s8, strs                # Load strs references
        li s9, 8                   # Load the loop count
print_numbers:
        lw a0, 0(s8)               # Load string reference
        li a7, 4                   # print string
        ecall
        lw a0, 0(s7)               # Load data
        jal ra, fp16_to_fp32       # calculate fp16_to_fp32(data)   
        li, a7, 34                  # print the result in hex format
        ecall
validation:
        lw t0, 0(s6)               # Load ans
        sub t0, t0, a0             # calculate ans - result for validation
        beqz t0, check_loop        # if (ans - result) == 0 then skip
        la a0, strError
        li a7, 4                   # print error message!!!
        ecall
check_loop:
        addi s6, s6, 4             # shift ans index
        addi s7, s7, 4             # shift datas index
        addi s8, s8, 4             # shift strs index
        addi s9, s9, -1            # loop count - 1
        bnez s9, print_numbers
        
exit:
        # Exit the program
        li a7, 10                  # System call code for exiting the program
        ecall                      # Make the exit system call
        ret
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