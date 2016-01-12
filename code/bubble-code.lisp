(! bubble-code
'(bubble_a
	(pushl		%ebp)
	(rrmovl		%esp 		%ebp)	;setup for procedure
	(pushl		%ebx)
	(pushl		%esi)
	(pushl		%edi)				;save the callee-save registers
	(mrmovl		12(%ebp) 	%edx)	;get count
	(irmovl		1 			%ebx)
	(subl		%ebx		%edx)	;compute count-1
	(addl		%edx 		%edx)	;compute (count-1) * 2
	(addl		%edx 		%edx)	;compute (count-1) * 4
	(mrmovl		8(%ebp) 	%ebx)	;put data in %ebx
	(addl		%edx 		%ebx)	;data + ((count-1) * 4) = Bptr (to last element)

loop1
	(mrmovl		8(%ebp) 	%ecx)	;get data again because Y86 is dumb and can't do 
									;arithmetic with immediates for some reason
	(rrmovl		%ebx		%eax)	;copy Bptr for comparison
	(subl		%ecx		%eax)	;Bptr compare w/ data
	(jle 		end)				;if Bptr <= data, jump to end

	(rrmovl		%ecx 		%edx)	;Crush %edx with data because we don't need that anymore. 
									;This will be Fptr, and will be reset every loop1.
									
	(irmovl		4			%ecx)	;Put 4 into %ecx for arithmetic later

loop2
	(rrmovl		%edx		%eax)	;copy Fptr for comparison
	(subl		%ebx		%eax)	;Fptr compare w/ Bptr
	(jge 		next_loop1)			;if Fptr >= Bptr, jump to next_loop1 to prep

	(mrmovl		4(%edx) 	%esi)	;get *(Fptr + 1)
	(mrmovl		0(%edx) 	%edi)	;get *Fptr
	(rrmovl		%esi		%eax)	;copy *(Fptr + 1) for the test
	(subl		%edi 		%eax)	;compare *(Fptr + 1) and *Fptr
	(jge		next_loop2)				;dont do the following if *(Fptr + 1) >= *Fptr
	
	(rmmovl		%esi	0(%edx))	
	(rmmovl		%edi	4(%edx))	;put into memory

	(jmp 		next_loop2)

end
	(popl		%edi)
	(popl		%esi)
	(popl		%ebx)
	(popl		%ebp)				;restore callee save registers
	(ret)

next_loop1
	(addl		%ecx 		%edx)	;incremement Fptr by 4
	(subl		%ecx		%ebx)	;decrement Bptr by 4
	(jmp 		loop1)

next_loop2
	(addl		%ecx 		%edx)	;incremement Fptr by 4
	(jmp 		loop2)

main
	(irmovl 	stack_top %esp)
	(rrmovl 	%esp	%ebp)		;set up
	(irmovl		5		%ecx)
	(irmovl		ele1	%edx)
	(pushl		%ecx)
	(pushl		%edx)				;pass arguments to stack
	(call 		bubble_a)
	(popl		%edx)
	(popl		%ecx)
	(halt)

	; Array input in memory
	(align 4)
	ele1
	(dword 5)
	ele2
	(dword 1)
	ele3
	(dword 8)
	ele4
	(dword 4)
	ele5
	(dword 3)

    (pos 4096)
     stack_top
     ))

; Program OK?

(y86-prog (@ bubble-code))

(! location 0)

(! symbol-table
   (hons-shrink-alist
    (y86-symbol-table (@ bubble-code) (@ location) 'symbol-table)
    'shrunk-symbol-table))

(! init-mem
    (hons-shrink-alist
     (y86-asm (@ bubble-code) (@ location) (@ symbol-table) 'bubble-code)
     'shrunk-bubble-code))

(m86-clear-regs x86-32)       ; Clear registers
(m86-clear-mem  x86-32 8192)  ; Clear memory location 0 to 8192

(! init-pc (cdr (hons-get 'main (@ symbol-table))))
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

; Step ISA 10,000,000 (about 20 minutes) steps or to HALT.
(time$ (y86 x86-32 10000000000))
(m32-get-regs-and-flags x86-32)