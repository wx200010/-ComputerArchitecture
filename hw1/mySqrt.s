.data
    datas: .word 0, 1, 2, 4, 8, 2147483647
    ans: .word 0, 1, 1, 2, 2, 46340
    str1:     .string "\nmySqrt(0) is : " 
    str2:     .string "\nmySqrt(1) is : " 
    str3:     .string "\nmySqrt(2) is : " 
    str4:     .string "\nmySqrt(4) is : " 
    str5:     .string "\nmySqrt(8) is : " 
    str6:     .string "\nmySqrt(2147483647) is : " 
    strError: .string "\nthe answer is wrong!!!"
    strs:     .word str1, str2, str3, str4, str5, str6
.text

main:
        la s6, ans                 # Load ans reference
        la s7, datas               # Load datas reference
        la s8, strs                # Load strs references
        li s9, 6                   # Load the loop count
print_numbers:
        lw a0, 0(s8)               # Load string reference
        li a7, 4                   # print string
        ecall
        lw a0, 0(s7)               # Load data
        jal ra, mySqrt       # calculate fp16_to_fp32(data)   
        li, a7, 36                  # print the result in unsigned format
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
mySqrt:
        # a0 is x
        # t0 is temp
        # t1 is L
        # t2 is R
        # t3 is M
        bnez a0, conditionSkip     # if(x==0) then return x
        ret
conditionSkip:
        mv t3, a0                  # set t3 = x to calc my_clz(x)
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
        add t0, t4, t3              # temp = r + (0x55af >> c) & 3
my_clz_end:                         # temp = my_clz(x)
        li t4, 31                   
        sub t0, t4, t0              # temp = 31 - my_clz(x)
        srli t0, t0, 1              # tmp = temp >> 1
        li t1, 1                    # L = 1
        sll t1, t1, t0              # L = 1 << (temp >> 1)
        slli t2, t1, 1              # R = L << 1
binary_search_loop:
        add t3, t1, t2              # M = L + R
        srli t3, t3, 1              # M = (L + R) >> 1
        mv t4, t3                   # copy M to t4
        mv t5, t3                   # copy M to t5
        li s0, 0                    # set result = 0
    multiple_loop:                      # calculate result = M * M
            andi t6, t4, 1              # check LSB of t4
            beqz t6, skip_add           # if LSB of t4 == 0 then skip
            add s0, s0, t5              # result = result + t5
    skip_add:
            srli t4, t4, 1              # t4 = t4 >> 1
            slli t5, t5, 1              # t5 = t5 << 1
            bnez t4, multiple_loop
multiple_end:
        bgtu s0, a0, squareM_is_bigger  # if(M * M > x) then jump
        add s0, s0, t3                  # result =  M*M + M
        add s0, s0, t3                  # result =  M*M + 2*M
        addi s0, s0, 1                  # result = (M+1)*(M+1)
        bleu s0, a0, squareM1_is_smaller # if((M+1)*(M+1) <= x) then jump
breakLoop:                              # else return M
        mv a0, t3
        ret                             # return M
squareM_is_bigger:                  
        mv t2, t3                       # R = M
        j binary_search_loop            # continue
squareM1_is_smaller:
        mv t1, t3                       # L = M
        j binary_search_loop            # continue