	.file	"vulnShellCode.c"
	.text
	.section .rdata,"dr"
	.align 8
.LC0:
	.ascii "Ingrese un string, y este ser\303\241 impreso de vuelta:\0"
	.text
	.globl	vuln
	.def	vuln;	.scl	2;	.type	32;	.endef
	.seh_proc	vuln
vuln:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$64, %rsp
	.seh_stackalloc	64
	.seh_endprologue
	leaq	.LC0(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	-32(%rbp), %rax
	movq	%rax, %rcx
	call	gets
	leaq	-32(%rbp), %rax
	movq	%rax, %rcx
	call	puts
	movl	$1, %ecx
	movq	__imp___acrt_iob_func(%rip), %rax
	call	*%rax
	movq	%rax, %rcx
	call	fflush
	nop
	addq	$64, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.globl	main
	.def	main;	.scl	2;	.type	32;	.endef
	.seh_proc	main
main:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movl	%ecx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	call	__main
	call	vuln
	movl	$0, %eax
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.def	__main;	.scl	2;	.type	32;	.endef
	.ident	"GCC: (Rev5, Built by MSYS2 project) 16.1.0"
	.def	puts;	.scl	2;	.type	32;	.endef
	.def	gets;	.scl	2;	.type	32;	.endef
	.def	fflush;	.scl	2;	.type	32;	.endef
