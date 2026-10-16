; Count down from 10 to 0, outputting each number. Tests SUBI and JNZ/JZ.
        LDI 10
loop:   OUT
        JZ done
        SUBI 1
        JMP loop
done:   HALT
