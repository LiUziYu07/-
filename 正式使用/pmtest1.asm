; ======================
; pmtest1.asm
; ======================
#include "pm.inc" ;其中问一些常量、宏和一些说明

org		07c00h
		jmp 	LABEL_BEGIN

[SECTION .gdt]
;GDT
;									段基址				段界限	属性
LABEL_GDT:			Descriptor			0,					0 ,	0			;	空描述符
LABEL_DESC_CODE32:	Descriptor			0,	 SegCode32Len - 1 , DA_C + DA_32; 非一致代码段
LABEL_DESC_VIDEO:	Descriptor	  0B8000h,			   0ffffh , DA_DRW		; 显存的首地址
