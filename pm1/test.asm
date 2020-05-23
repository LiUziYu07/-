; ==========================================
; pmtest1.asm
; 编译方法：nasm pmtest1.asm -o pmtest1.bin
; ==========================================
 
DA_32		EQU	4000h	; 32 位段
DA_C		EQU	98h	; 存在的只执行代码段属性值
DA_DRW		EQU	92h	; 存在的可读写数据段属性值
ATCE32		EQU	4098h   ;存在的只执行32代码段属性值
 
;下面是存储段描述符的宏定义
; 有三个参数：段界限,段基址,段属性其中宏定义中的%1代表参数1，%2代表参数2，%3代表参数3
%macro Descriptor 3  
 
	dw	%2 & 0FFFFh				; 段界限1（参数2的低16位）
	dw	%1 & 0FFFFh				; 段基址1（参数1的低16位）
	db	(%1 >> 16) & 0FFh			; 段基址2（参数1的16-23位）
	dw	((%2 >> 8) & 0F00h) | (%3 & 0F0FFh)	; 属性1（高4位） + 段界限2（高4位） + 属性2（低8位）
	db	(%1 >> 24) & 0FFh			; 段基址3（参数1的24-31位）
%endmacro ; 共 8 字节
;段界限共20位，段基地址30位，段属性共16位（含段界限高4位）
 
org	07c00h
	jmp	LABEL_BEGIN
 
[SECTION .gdt]  ;section是告诉编译器划分出一个叫gdt的段
; GDT
;                              段基址,       段界限     ,    属性
LABEL_GDT:	   Descriptor       0,                0, 0           ; 空描述符
LABEL_DESC_CODE32: Descriptor       0, SegCode32Len - 1, DA_C + DA_32; 非一致代码段（DA_C + DA_32=ATCE32）
LABEL_DESC_VIDEO:  Descriptor 0B8000h,           0ffffh, DA_DRW	     ; 显存首地址
; GDT 结束
 
GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1	; GDT界限
		dd	0		; GDT基地址
 
; GDT 选择子
SelectorCode32		equ	LABEL_DESC_CODE32	- LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT
; END of [SECTION .gdt]
 
[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax    ;设置数据段
	mov	es, ax    
	mov	ss, ax    ;设置堆栈段
	mov	sp, 0100h ;设置栈底指针
 
	; 初始化 32 位代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4    ;eax*16==段值*16(实模式下不用手工计算，但是这里需要自己计算)
	add	eax, LABEL_SEG_CODE32;加上LABEL_SEG_CODE32偏移,这样eax->LABEL_SEG_CODE32基地址
	mov	word [LABEL_DESC_CODE32 + 2], ax    ;设置基地址1（0-15位）
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al    ;设置基地址2（16-23位）
	mov	byte [LABEL_DESC_CODE32 + 7], ah    ;设置基地址3（24-31位）
 
	; 为加载 GDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4   ;eax*16==段值*16
	add	eax, LABEL_GDT		; eax <- gdt 基地址
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt 基地址
 
	; 加载 GDTR
	lgdt	[GdtPtr]   ;将GdtPtr所指的内容送到GDT寄存器
 
	; 关中断
	cli
 
	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al
 
	; 准备切换到保护模式
	mov	eax, cr0
	or	eax, 1   ;设置cr0的0位（PE位，PE=1准备进入保护模式）
	mov	cr0, eax ;更新cr0
 
	; 真正进入保护模式
	jmp	dword SelectorCode32:0	; 执行这一句会把 SelectorCode32 装入 cs,
					; 并跳转到 Code32Selector:0  处
; END of [SECTION .s16]
 
[SECTION .s32]; 32 位代码段. 由实模式跳入.
[BITS	32]
 
LABEL_SEG_CODE32:
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子(目的)
 
	mov	edi, (80 * 11 + 79) * 2	; 屏幕第 11 行, 第 79 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'P'
	mov	[gs:edi], ax
 
	; 到此停止
	jmp	$
 
SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]