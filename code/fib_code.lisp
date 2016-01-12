;; Answer to the question: ``What is the
;; largest input for which this routine produces the correct answer (when
;; running on our Y86 simulated computer)?''
;; 
;; 47

(! fib-code
   '(fib_setup
    (irmovl  	stack_top 	%esp)
    (irmovl  	stack_top 	%ebp)
    (irmovl  	31   		%edx)    	; %edx <- 31   -- This is < x >.
    (pushl   	%edx)
    (call    	fib2)
    (popl		%edx)
    (halt)

    fib_rec
    (pushl		%ebp)
	(rrmovl		%esp 		%ebp)
	(mrmovl		8(%ebp) 	%eax)		;get fx
	(mrmovl		12(%ebp) 	%ecx)		;get fx_1
	(mrmovl		16(%ebp) 	%edx)		;get remaining

	(andl		%edx 		%edx)		;test remaining
	(je 		return)					;if remaining == 0, return fx

	(pushl		%ebx)					;callee-save register
	(irmovl		1 			%ebx)		;set %ebx to 1... Y86 is pretty annoying
	(subl 		%ebx		%edx)		;remaining--
	(addl		%eax		%ecx)		;comp fx_1 + fx
	(pushl		%edx)
	(pushl		%eax)
	(pushl		%ecx)
	(call 		fib_rec)
	(popl		%ecx)
	(popl		%edx)					;dont pop back to %eax... I wanna keep that :/
	(popl		%edx)
	(popl		%ebx)
	(jmp 		return)

    fib2
    (pushl		%ebp)
	(rrmovl		%esp 		%ebp)
	(xorl		%eax		%eax)		;put 0 into return value
	(mrmovl		8(%ebp) 	%edx)		;get x
	(andl		%edx 		%edx)		;test x
	(jl 		return)					;if x is < 0, return 0

	(rrmovl		%edx		%eax)		;set return value as x
	(irmovl		1 			%ecx)		;put 1 in a register, because Y86 sucks
	(subl		%ecx 		%edx)		;x-1
	(jle		return)					;if less than or equal to 1, return x

	(xorl		%eax		%eax)		;put 0 into return value
	(pushl		%edx)					;put x - 1 in "remaining" space
	(pushl		%eax)					;put 0 in "fx_1" space
	(pushl		%ecx)					;put 1 in "fx" space
	(call 		fib_rec)				;call fib_rec with the above arguments
	(popl		%ecx)
	(popl		%edx)					;dont pop back to %eax... I wanna keep that :/
	(popl		%edx)

	return
    (popl		%ebp)
	(ret)

     end-of-code

(pos 4096)
     stack_top
     ))

; Program OK?

(y86-prog (@ fib-code))

(! location 0)
(! symbol-table
   (hons-shrink-alist
    (y86-symbol-table (@ fib-code) (@ location) 'symbol-table)
    'shrunk-symbol-table))

; The function Y86-ASM assembles a program into a memory image.

(!! init-mem
    (hons-shrink-alist
     (y86-asm (@ fib-code) (@ location) (@ symbol-table) 'fib-iterative)
     'shrunk-fib-iterative))

; Initialize the Y86 state, note we need initial values for various
; registers.  Here, we clear the registers (not really necessary) and
; the memory

(m86-clear-regs x86-32)       ; Clear registers
(m86-clear-mem  x86-32 8192)  ; Clear memory location 0 to 8192

;; You may set init-pc to whatever you want, as long as your code runs properly.
(! init-pc (cdr (hons-get 'fib_setup (@ symbol-table))))
(! y86-status nil)   ; Initial value for the Y86 status register

(init-y86-state
 (@ y86-status)  ; Y86 status
 (@ init-pc)     ; Initial program counter
 nil             ; Initial registers, if NIL, then all zeros
 nil             ; Initial flags, if NIL, then all zeros
 (@ init-mem)    ; Initial memory
 x86-32
 )

; Lines that can be typed that just shows the Y86 machine status and
; some of the memory after single stepping.
; (y86-step x86-32) (m32-get-regs-and-flags x86-32)
; (rmb 4 (rgfi *mr-esp* x86-32) x86-32)

; Step ISA 10,000 steps or to HALT.
(time$ (y86 x86-32 10000)) (m32-get-regs-and-flags x86-32)