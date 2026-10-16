; Multiply 6 x 7 using repeated addition (the CPU has no multiply instruction!)
;   r0 = 6 (the number to add), r1 = 7 (how many times left), r2 = running total

        LDI 6
        ST r0
        LDI 7
        ST r1
        LDI 0
        ST r2
loop:   LD r2
        ADD r0          ; total = total + 6
        ST r2
        LD r1
        SUBI 1          ; times left - 1
        ST r1
        JNZ loop        ; keep going until it hits 0
        LD r2
        OUT             ; show 42
        HALT
