*************************************************
*	MACRO Pour Devpac 3		        *
*************************************************
Pos1	=4
Pos2	=17
Pos3	=30
Pos4	=44
Pos5	=57
Pos6	=70
_Custom		EQU $DFF000


*******MACRO COPPER*******
*	include	Progs:assembleur/include3/Hardware/custom.i
*	include	exec/Memory.i
*	include	exec/exec_lib.i

CopperLPlan	Macro	Numero
	Move.l	D0,D1
 	Move.w	#\1*4+$0DE,(A0)+
	Move.w	D1,(A0)+
	Swap	D1
	Move.w	#\1*4+$0DC,(A0)+
	Move.w	D1,(A0)+
		Endm
CopperLActiveBitplan	Macro	N°bitplan
	Move.w	#$100,(A0)+		BplCon0
	Move.w	#%0000001000000000+\1*4096,(A0)+
	Endm
CopperLActiveBitplanHires Macro
	Move.w	#$100,(A0)+
	Move.w	#%1000001000000000+\1*4096,(A0)+		
	Endm


CopperLActiveBitplan8	Macro	N°bitplan
	Move.w	#$100,(A0)+
	Move.w	#%0000001000010000,(A0)+
			Endm
CopperLDeactiveBitplan	Macro	Ligne
	Move.l	#$000ffffe+\1*16777216,(A0)+
	Move.w	#$100,(A0)+
	Move.w	#%1000001000000000,(A0)+
			EndM
CopperLFin		Macro
	Move.l	#$FFFFFFFE,(A0)
			Endm
CopperScreen	Macro	Largeur
	Move.l	#$DFF000,A5
	Move.w	#$3060,DiwSTRT 
	Move.w	#$00E1,DiwSTOP 
	Move.w	#$32,DDFstrt 
	Move.w	#$32+(\1/2-8),DDFstop 
	CLR.w	BPLCON1 
	CLR.w	BPLCON2 
	CLR.w	BPL1MOD 
	CLR.w	BPL2MOD 
	Move.w	#%00,Fmode 
	endm
CopperScreenC	Macro	Largeur
	Move.l	#$DFF000,A5
	Move.w	#$3060,DiwSTRT 
	Move.w	#$00E1,DiwSTOP 
	Move.w	#$42,DDFstrt 
	Move.w	#$42+(\1/2-8),DDFstop 
	CLR.w	BPLCON1 
	CLR.w	BPLCON2 
	CLR.w	BPL1MOD 
	CLR.w	BPL2MOD 
	Move.w	#%00,Fmode 

		EndM
CopperScreenHIRES	Macro	Largeur
	Move.l	#$DFF000,A5
	Move.w	#$3081,DiwSTRT 
	Move.w	#$30C1,DiwSTOP 
	Move.w	#$3C,DDFstrt 
	Move.w	#$3C+(\1/4-8),DDFstop 
	CLR.w	BPLCON1 
	CLR.w	BPLCON2 
	CLR.w	BPL1MOD 
	CLR.w	BPL2MOD 
	CLR.w	Fmode 
		EndM

Color256		Macro 	;Avec D0=Color :D1=R ;D2=V ;D3=B
		;Préparation couleur rouge
		Rol.l	#8,D1
		Rol.l	#4,D1
		Ror.w	#4,D1
		swap	D1
		Rol.w	#8,D1
		;Préparation Couleur Vert
		Rol.l	#8,D2
		Rol.l	#4,D2
		Ror.w	#8,D2
		swap	D2
		Rol.w	#4,D2
		;Préparation Couleur bleu
		Ror.l	#4,D3
		Swap	D3
		Rol.w	#4,D3
		Swap	D3
		;Préparation Msb
		Add.w	D1,D3
		Add.w	D2,D3
		;Préparation N°Tableau
		*Rsr.w	#6,D0
		Divu.w	#32,D0
		Rol.w	#8,D0
		Rol.w	#5,D0	
		Move.w	D0,BPLCon3
		Swap 	D0
		Rol.w	D0
		Sub.l	A5,A5
		Move.w	D0,A5
		Add.l	#$DFF180,A5
		Move.w	D3,(A5)
		Swap	D2
		swap	D1
		Swap	D3
		Add.w	D1,D3
		Add.w	D2,D3
		Swap	D0
		Ori.w	#%1000000000,D0
		Move.w	D0,BPLCOn3
		Swap 	D0
		Move.w	D3,(A5)
		endm
InitColor256	Macro Ncouleur Rouge Vert Bleu
		Move.l	#\1,D0
		Move.l	#\2,D1
		Move.l	#\3,D2
		Move.l	#\4,D3
		Color256
		Endm
Color256T		Macro	Ncouleur,MSB,LSB
		DivU.w	#32,D0
		Rol.w	#8,D0
		Rol.w	#5,D0	
		Move.w	D0,BPLCon3
		Swap 	D0
		Rol.w	D0
		Sub.l	A5,A5
		Move.w	D0,A5
		swap	D1
		Add.l	#$DFF180,A5
		Move.w	D1,(A5)
		Swap	D0
		Ori.w	#%1000000000,D0
		Move.w	D0,BPLCOn3
		Swap 	D1
		Move.w	D1,(A5)
		Endm

*CopWait	MACRO       Y (peut-être un registre)
*	Move.b	\1,(A0)+
*	Move.b	#%00000001,(A0)+ 
*	Move.w	#%1111111111111110,(A0)+  
*	ENDM

*CopWaitXY	MACRO       X,Y
*	Move.b	\2,(A0)+
*	Move.w	\1,D2
*	lsr.l	#1,D2
*	bset	#0,D2
*	Move.b	D2,(A0)+
*	Move.w	#$FFFE,(A0)+
*	ENDM
BLWait	Macro
WAIT\@	Btst	#6,$BFE001
	BNE	Wait\@
	EndM
FadeIn	MACRO	N°VBL,Tableau de couleur,N°couleur
	Move.w	#0,FADE\@
Couleurs\@
	Move.b	$BFE801,D4
	Cmp.B	WaitV\@,D4
	BEQ	couleurs\@
	Move.b	D4,WaitV\@
	Move.l	\2,A0
	Move.l	#0,D4
	Move.l	#0,D0
	
couleurT\@
	CLR.l	D1
	CLR.l	D2
	CLR.l	D3
	Move.B	(A0)+,D3
	Move.B	(A0)+,D2
	Move.B	(A0)+,D1
	Mulu.w	FADE\@,D1
	MULu.w	FADE\@,D2
	Mulu.w	FADE\@,D3
	DIVU.w	#\1,D1
	Divu.w	#\1,D2
	DivU.w	#\1,D3
	AndI.l	#$0000FFFF,D1
	AndI.l	#$0000FFFF,D2
	AndI.l	#$0000FFFF,D3
	color256
	add.l	#1,D4
	Move.l	D4,D0
	Cmp.l	#\3,D4
	BNE	couleurT\@
	AddI.w	#1,FADE\@
	CMP.w	#\1,FADE\@
	BNE	Couleurs\@
	JMP	Suite\@
FADE\@	DC.w	0
WaitV\@	DC.b	0 
	Even
Suite\@
	Endm
Fadeout	MACRO	N°VBL,Tableau de couleur,N°couleur
	Move.w	#\1,FADE\@
Couleurs\@
	Move.b	$BFE801,D4
	Cmp.B	WaitV\@,D4
	BEQ	couleurs\@
	Move.b	D4,WaitV\@
	Move.l	\2,A0
	Move.l	#0,D4
	Move.l	#0,D0
	
couleurT\@
	CLR.l	D1
	CLR.l	D2
	CLR.l	D3
	Move.B	(A0)+,D3
	Move.B	(A0)+,D2
	Move.B	(A0)+,D1
	Mulu.w	FADE\@,D1
	MULu.w	FADE\@,D2
	Mulu.w	FADE\@,D3
	DIVU.w	#\1,D1
	Divu.w	#\1,D2
	DivU.w	#\1,D3
	AndI.l	#$0000FFFF,D1
	AndI.l	#$0000FFFF,D2
	AndI.l	#$0000FFFF,D3
	color256
	add.l	#1,D4
	Move.l	D4,D0
	Cmp.l	#\3,D4
	BNE	couleurT\@
	subI.w	#1,Fade\@
	CMP.w	#0,FADE\@
	BNE	Couleurs\@
	JMP	Suite\@
	JMP	Suite\@
FADE\@	DC.w	0
WaitV\@	DC.b	0 
	Even
Suite\@

	Endm
ChargeCouleur	Macro	Couleur.col,Tableau des couleurs,N°
	Move.l	\1,A0
	Move.l	#0,D2
	Move.l	\2,A1
Lcouleur\@	Move.L	(A0)+,D1
	Move.b	D1,D0
	AndI.B	#%00001111,D0	*Selection de $0000000F
	Move.b	D0,(A1)		*Premier bordel
	lsr.l	#4,D1
	Move.b	D1,D0
	AndI.B	#$0F,D0		*Selection de $000000F0
	Move.b	D0,1(A1)		*Second
	Lsr.l	#4,D1
	Move.b	D1,D0
	AndI.b	#$0f,D0		*selection de $00000F00
	Move.b	D0,2(A1)
	Lsr.l	#4,D1
	Move.b	D1,D0
	AndI.B	#$F0,D0		*Selection de $000F0000
	Add.B	D0,(A1)
	Lsr.l	#4,D1
	Move.b	D1,D0
	AndI.B	#$F0,D0		*Selection de $00f00000
	Add.B	D0,1(A1)
	Lsr.l	#4,D1
	Move.b	D1,D0
	AndI.B	#$F0,D0		*Selection de $0F000000
	Add.B	D0,2(A1)
	*********Finit Conversion*************
	Adda.l	#3,A1	
	add.l	#1,D2
	Cmp.l	#\3,D2
	BNE	lcouleur\@
	endM
AllocMem	MAcro	Nom mémoire , Taille , Type
	Move.l	$4,A6
	Move.l	#\2,D0
	Move.l	#\3,D1
	JSR	-198(A6)
	BEQ	FinMem
	Move.l	D0,\1
	Jmp	Suite\@
\1	DC.l	0
Suite\@
	Move.l	\1,-(A7)
	Move.l	#\2,-(A7)
	add.l	#1,MEM
	Endm
FreeMem	Macro	Restitu toute la mémoire allocé pa AlLocMem
FinMem	TST.l	MEM
	BEQ	Suite\@
Loop\@	
	Move.l	$4,A6
	Move.l	(A7)+,D0	
	Move.l	(A7)+,A1
	jsr	_LVOFreeMem(A6)
	sub.l	#1,MEM
	CMP.l	#0,MEM
	BNE	Loop\@	
	JMP	Suite\@
MEM	DC.l	0
Suite\@
	Endm
CopperAfficheligne	Macro
	Move.b	D4,(A0)+
	Add.l	#1,D4
	Move.b	#%00000001+160,(A0)+ 
	Move.w	#%1111111111111110,(A0)+  
	Move.l	Planar,D0
	Move.l	D2,D3
	MULU.l	#40,D3
	Add.l	D3,D0
	copperLPlan	1
	Add.l	#40*100,D0
	CopperLPlan	2
	Add.l	#40*100,D0
	CopperLPlan	3
	Add.l	#40*100,D0
	CopperLPlan	4
	Add.l	#40*100,D0
	CopperLPlan	5
	Add.l	#40*100,D0
	CopperLPlan	6
	Add.l	#40*100,D0
	CopperLPlan	7
	Add.l	#40*100,D0
	CopperLPlan	8

*	Move.w	#BPL1MOD,(A0)+
*	CLR.w	(A0)+
*	Move.w	#BPL2MOD,(A0)+
*	Clr.w	(A0)+
	EndM
VblWait	MACRO		Ligne à attendre: Y
	Move.l	Donne,D4
Loop1\@	Move.B	D4,D0
	Move.b	$BFE801,D4
	Cmp.B	D4,D0
	BEQ	loop1\@	
suite\@	Move.l	D4,donne

	ENDM
Wait28k	MACRO		Ligne à attendre: Y
Loop2\@	Move.B	D4,D0
	Move.b	$BFD800,D4
	Cmp.B	D4,D0
	BEQ	loop2\@	

	ENDM


InitAfficheur	Macro
	Move.b	#$FF,$bfe301
	Move.b	#%110,$bfD200
	Move.b	#$0,$Bfd000
	rept	3
	VBLwait	
	Move.b	#%111000,$BFE101
	endr
	VBLwait	
	Move.b	#%1101,$BFE101
	VBLwait	
	Move.b	#%1,$bfe101
	vblwait	
	Move.b	#%11100,$bfe101
	vblwait
	Move.b	#%1101,$BFE101
	vblwait	
	Move.b	#%110,$BFE101
	vblwait	
	Move.b	#%100,$BfD000
	vblwait	
	vblwait
	VBlwait
	vblwait
	vblwait
	wait28K
	Wait28K
	wait28K
	endm
Type	Macro	Pointeur Text
	Movem.l	D0-D4,-(A7)
	Move.l	\1,A0
LoopT\@
	Move.b	(A0)+,D1
	Tst.b	D1
	BEQ	FIN\@
	Move.b	D1,$BFE101
	wait28k
	JMp	Loopt\@
Fin\@
	Movem.l	(A7)+,D0-D4
	endm
Hex2text	Macro	Donné,Pointeur
	Movem.l	D0-D4/A0,-(A7)
	Move.l	\1,D0
	Move.w	#7,D1
	Move.l	\2,A0
	Rol.l	#4,D0
Conv\@
	Move.b	D0,D2
	And.b	#$0f,D2
	Add.b	#%110000,D2
	CMp.b	#%111001,D2
	BLe	Suite\@
	Add.b	#7,D2
suite\@	Move.b	D2,(A0)+
	ROl.l	#4,D0
	dbf	D1,Conv\@
	Movem.l	(A7)+,D0-D4/A0
	endm
Locate	Macro	X,Y
	Move.b	#0,$bfd000
	Wait28k
	Move.b	#%10000000+\2*%1000000+\1,$bfe101
	wait28k
	Move.b	#%100,$bfd000
	endm
		

TakeSystem	MACRO
*	CALLEXEC Forbid			; stop multitasking

	lea	_Custom,a5
	move.w	dmaconr,OLD_dmaconr ; save DMA control (blitter status)
	move.w	adkconr,OLD_adkconr	; save Audio, disk control register read
	move.w	intenar,OLD_intenar ; save Interrupt enable bits read
	move.w	intreqr,OLD_intreqr ; save Interrupt request bits read

	move.w	#$8000,d0
	or.w	d0,OLD_dmaconr 		; set control bit to 1
	or.w	d0,OLD_adkconr
	or.w	d0,OLD_intenar
	or.w	d0,OLD_intreqr

	moveq	#$00,d0
	lea	Graphicname,a1
	CALLEXEC OpenLibrary		; a6 = execbase
	move.l	d0,_GfxBase
*	beq.w	CannotOpenGfxLibrary


	movea.l	_GfxBase,a6
	move.l	gb_ActiView(a6),OLD_View

	suba.l	a1,a1		; open a NULL View
	CALL	LoadView	; resets display on any amiga
	move.w	#$7fff,adkcon	; disable all adkcon bits
	move.w	#$7fff,intena	; disable all interrupts
	move.w	#$7fff,intreq	; disable all interrupts
;*	move.w	#$7fff,dmacon	; disable all dma
	endm
	
RestoreSystem MAcro
	movea.l	_GfxBase,a6
	move.l	gb_copinit(a6),cop1lch	;restore system copper list

	movea.l	OLD_View,a1		; ptr on OLD_View struct
	CALL	LoadView		; Restore the OLD_View
	move.w	#$7fff,dmacon	; disable all dma
	move.w	#$7fff,adkcon	; disable all adkcon bits
	move.w	#$7fff,intena	; disable all interrupts
	move.w	#$7fff,intreq	; disable all interrupts

	move.w	OLD_dmaconr,dmacon	; restore old dma bits
	move.w	OLD_adkconr,adkcon	; restore old adkcon status
	move.w	OLD_intenar,intena	; restore old intena status
	move.w	OLD_intreqr,intreq	; restore old intreq status

*	CALLJEXEC Permit		; enable multitask
	endm
CALL		macro
		jsr	_LVO\1(a6)
		endm
CALLJ		macro
		jsr	_LVO\1(a6)
		endm
CALLJEXEC	macro
		move.l	4.w,a6
		jsr	_LVO\1(a6)
		endm
CALLJDOS	macro
		move.l	_DOSBase,a6
		jsr	_LVO\1(a6)
		endm
CALLJINT	macro
		move.l	_IntuitionBase,a6
		jsr	_LVO\1(a6)
		endm
CALLJGRAF	macro
		move.l	_GfxBase,a6
		jsr	_LVO\1(a6)
		endm
CALLREQ		macro
		move.l	_ReqToolBase,a6
		jsr	_LVO\1(a6)
		endm
CALLJREQ	macro
		move.l	_ReqToolBase,a6
		jsr	_LVO\1(a6)
		endm
	
	