	.build_version macos, 26, 0	sdk_version 26, 5
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_vuln                           ; -- Begin function vuln
	.p2align	2
_vuln:                                  ; @vuln
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #64
	stp	x29, x30, [sp, #48]             ; 16-byte Folded Spill
	add	x29, sp, #48
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
Lloh0:
	adrp	x8, ___stack_chk_guard@GOTPAGE
Lloh1:
	ldr	x8, [x8, ___stack_chk_guard@GOTPAGEOFF]
Lloh2:
	ldr	x8, [x8]
	stur	x8, [x29, #-8]
Lloh3:
	adrp	x0, l_.str@PAGE
Lloh4:
	add	x0, x0, l_.str@PAGEOFF
	bl	_puts
	add	x0, sp, #8
	bl	_gets
	add	x0, sp, #8
	bl	_puts
Lloh5:
	adrp	x8, ___stdoutp@GOTPAGE
Lloh6:
	ldr	x8, [x8, ___stdoutp@GOTPAGEOFF]
Lloh7:
	ldr	x0, [x8]
	bl	_fflush
	ldur	x8, [x29, #-8]
Lloh8:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh9:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh10:
	ldr	x9, [x9]
	cmp	x9, x8
	b.ne	LBB0_2
; %bb.1:
	ldp	x29, x30, [sp, #48]             ; 16-byte Folded Reload
	add	sp, sp, #64
	ret
LBB0_2:
	bl	___stack_chk_fail
	.loh AdrpLdrGotLdr	Lloh8, Lloh9, Lloh10
	.loh AdrpLdrGotLdr	Lloh5, Lloh6, Lloh7
	.loh AdrpAdd	Lloh3, Lloh4
	.loh AdrpLdrGotLdr	Lloh0, Lloh1, Lloh2
	.cfi_endproc
                                        ; -- End function
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #64
	stp	x29, x30, [sp, #48]             ; 16-byte Folded Spill
	add	x29, sp, #48
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
Lloh11:
	adrp	x8, ___stack_chk_guard@GOTPAGE
Lloh12:
	ldr	x8, [x8, ___stack_chk_guard@GOTPAGEOFF]
Lloh13:
	ldr	x8, [x8]
	stur	x8, [x29, #-8]
Lloh14:
	adrp	x0, l_.str@PAGE
Lloh15:
	add	x0, x0, l_.str@PAGEOFF
	bl	_puts
	add	x0, sp, #8
	bl	_gets
	add	x0, sp, #8
	bl	_puts
Lloh16:
	adrp	x8, ___stdoutp@GOTPAGE
Lloh17:
	ldr	x8, [x8, ___stdoutp@GOTPAGEOFF]
Lloh18:
	ldr	x0, [x8]
	bl	_fflush
	ldur	x8, [x29, #-8]
Lloh19:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh20:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh21:
	ldr	x9, [x9]
	cmp	x9, x8
	b.ne	LBB1_2
; %bb.1:
	mov	w0, #0                          ; =0x0
	ldp	x29, x30, [sp, #48]             ; 16-byte Folded Reload
	add	sp, sp, #64
	ret
LBB1_2:
	bl	___stack_chk_fail
	.loh AdrpLdrGotLdr	Lloh19, Lloh20, Lloh21
	.loh AdrpLdrGotLdr	Lloh16, Lloh17, Lloh18
	.loh AdrpAdd	Lloh14, Lloh15
	.loh AdrpLdrGotLdr	Lloh11, Lloh12, Lloh13
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"Ingrese un string, y este ser\303\241 impreso de vuelta:"

.subsections_via_symbols
