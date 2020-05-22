




DA_32		EQU	4000h 		;
DA_C		EQU	98h			;
DA_DRW 		EQU 92h			;
ATCE32		EQU	4098h
; 描述符
; usage: Descriptor Base, Limit, Attr
;		 Base:	dd
;		 Limit: dd (low 20 bits available)
;		 Attr:  dw (lower 4 bits of higher byte are always 0)
%macro Descriptor 3
			dw 		%2 & 0FFFFh								; 段界限
			dw 		%1 & 0FFFFh								;
			db		(%1 >> 16) & 0FFh						;
			dw 		((%2 >> 8) & 0F00h) | (%3 & 0F0FFh)		;
			db 		(%1 >> 24) & 0FFh 						;
%endmacro	; 共8字节