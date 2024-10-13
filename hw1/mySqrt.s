.data
    test_1: .word 4
    test_2: .word 8
    test_3: .word 0x7FFFFFFF   
    str1:     .string "\nmySqrt(4) is " 
    str2:     .string "\nmySqrt(8) is " 
    str3:     .string "\nmySqrt(0x7FFFFFFF) is "  
.text
main:
        la a0, str1              # print "result1 is  " 
        li a7, 4
        ecall
        lw  a0, test_1           
        jal ra, mySqrt           # result1 = mySqrt(0x4)      
        li a7, 1                 # print result1
        ecall
        
        la a0, str2              # print "result2 is  " 
        li a7, 4
        ecall
        lw  a0, test_2           
        jal ra, mySqrt           # result2 = mySqrt(0x8)      
        li a7, 1                 # print result2
        ecall

        la a0, str3              # print "result3 is  " 
        li a7, 4
        ecall
        lw  a0, test_3           
        jal ra, mySqrt           # result3 = mySqrt(0x7FFFFFFF)      
        li a7, 1                 # print result3
        ecall
    
        # Exit the program
        li a7, 10                  # System call code for exiting the program
        ecall                      # Make the exit system call
        
mySqrt:
        # a0 is x
        # t0 is temp
        # t1 is L
        # t2 is R
        # t3 is M
                                   
        li t0, 0xFFFFFFFE          # check if(x==0 || x==1) then return
        and t0, a0, t0             # temp = x & 0xFFFFFFFE
        bnez t0, conditionSkip     # if temp == 0 then return x
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