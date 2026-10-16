; Fibonacci: outputs 1 1 2 3 5 8 13 21 34 55 89 144 233, then stops
; when the next number won't fit in 8 bits.
;   r0 = previous number, r1 = current number, r2 = next number

        LDI 0
        ST r0           ; prev = 0
        LDI 1
        ST r1           ; cur = 1
loop:   LD r1
        OUT             ; show cur
        ADD r0          ; A = cur + prev
        JC done         ; overflowed past 255? stop
        ST r2           ; next = A
        LD r1
        ST r0           ; prev = cur
        LD r2
        ST r1           ; cur = next
        JMP loop
done:   HALT
