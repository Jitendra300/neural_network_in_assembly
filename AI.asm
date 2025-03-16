section .bss
	random_buffer resd 1

section .text
	global _start

_start:
	;; Calling getrandom function through SyScall to get random values for our weight parameter
	mov rax, 318
	lea rdi, [random_buffer]
	mov rsi, 4
	xor rdx, rdx
	syscall

	mov eax, [random_buffer]

	;; Change type from int to float
	cvtsi2ss xmm0, eax

	;; Get the random number into range of [0,1] by dividing from (2^31 - 1)
	mov eax, 0x7FFFFFFF
	cvtsi2ss xmm1, eax
	divss xmm0, xmm1	; In xmm0 we are storing out weight parameter!

	;; Setting Training Size
	mov eax, 3
	cvtsi2ss xmm7, eax
	
	;; Setting Training Iteration
	mov r8, 256		; I believe this much iteration is already an overkill...

	;; Setting Training Inputs [1,2,3]
	mov eax, 1
	cvtsi2ss xmm8, eax
	mov eax, 2
	cvtsi2ss xmm9, eax
	mov eax, 3
	cvtsi2ss xmm10, eax

	;; Setting Training Outputs [2,4,6]
	mov eax, 2
	cvtsi2ss xmm11, eax
	mov eax, 4
	cvtsi2ss xmm12, eax
	mov eax, 6
	cvtsi2ss xmm13, eax

	;; Setting Learning Rate
	mov eax, 1 		; Load 1 into eax
	cvtsi2ss xmm14, eax
	mov eax, 10 		; Load 10 into eax
	cvtsi2ss xmm1, eax
	divss xmm14, xmm1 	; Now this is equaivalent to 0.1 cause 1/10 == 0.1; also 0.1 is kinda good rate

	;; Let's start the Training Process
	call training_process

training_process:
	mov rbx, 0
	cmp rbx, r8
	jg exit_program 	; Gonna exit the program when rbx > r8
	
	mov eax, 0
	cvtsi2ss xmm1, eax 	; Gonna keep correction value in xmm1 register

	;; Z = W*X[0]
	movss xmm2, xmm0 	; Keep weight value loaded into xmm2 register which will be the modelPrediction
	mulss xmm2, xmm8 	; Multiplying X[0] to weight i.e. here we have Z = W*X[0]
	movss xmm3, xmm2	; Keeping subtracted values here... i.e. modelprediction - Y[0] or error in simple words
	subss xmm3, xmm11
	movss xmm4, xmm3
	mulss xmm4, xmm8
	mov eax, 2
	cvtsi2ss xmm5, eax
	mulss xmm4, xmm5
	addss xmm1, xmm4 	; We did like correction += 2*X[0]*error
	;; In simple words the above block of code did is:
	;; Take modelprediction = weight*X[0]
	;; Then we took correction for our weight : correction = 2*X[0]*(modelprediction - Y[0])

	;; Below the same concept is applied more two times for X[1] and X[2].
	;; Note here X is trainingInput and Y is trainingOutput; in our example trainingInput = {1,2,3} and trainingOutput = {2,4,6}

	;; Z = W*X[1]
	movss xmm2, xmm0 	; Keep weight value loaded into xmm2 register which will be the modelPrediction
	mulss xmm2, xmm9 	; Multiplying trainingInput[1] to weight i.e. Z = W*X[1] here!
	movss xmm3, xmm2		; Keeping subtracted values here... i.e. modelprediction - trainingoutput[1] or error
	subss xmm3, xmm12
	movss xmm4, xmm3
	mulss xmm4, xmm9
	mov eax, 2
	cvtsi2ss xmm5, eax
	mulss xmm4, xmm5
	addss xmm1, xmm4 	; We did like correction += 2*X[0]*error

	;; Z = W*X[1]
	movss xmm2, xmm0 	; Keep weight value loaded into xmm2 register which will be the modelPrediction
	mulss xmm2, xmm10 	; Multiplying trainingInput[1] to weight i.e. Z = W*X[1] here!
	movss xmm3, xmm2		; Keeping subtracted values here... i.e. modelprediction - trainingoutput[1] or error
	subss xmm3, xmm13
	movss xmm4, xmm3
	mulss xmm4, xmm10
	mov eax, 2
	cvtsi2ss xmm5, eax
	mulss xmm4, xmm5
	addss xmm1, xmm4 	; We did like correction += 2*X[0]*error

	;; Now we the total correction by no of samples which is 3 in our case
	divss xmm1, xmm7 	; This well is the correction or dw for our weight parameter

	movss xmm6, xmm1
	mulss xmm6, xmm14
	subss xmm0, xmm6 	; Updated the weight here.... by this formula: W -= learningRate*dw where dw is the change to be made!

	add rbx, 1
	call training_process

exit_program:
	;; Exiting using SyScall
	mov rax, 60
	xor rdi, rdi
	syscall
