
TEMP_RESTORE_SYSTEM
	Tst.l	SYSTEM_RESIDENT
	Bne	.MultiOk
	Move.w	#0,ExeGENERALVbl
	Movem.l	D0-D7/A0-A6,-(A7)
*	Moveq	#8,D0		*
*	Bsr	PaletteBackup	*
	Jsr	RestoreSystem2	Sans le View() !
	Jsr	SetSimple		*
	VblWait	#250
	VblWait	#30
	Move.l	#-1,SYSTEM_RESIDENT
	Movem.l	(A7)+,D0-D7/A0-A6
.MultiOk	RTS

TEMP_TAKE_SYSTEM
	Tst.l	DO_NOT_RETAKE_SYSTEM
	Bne	.LegoOk
	Tst.l	SYSTEM_RESIDENT	On ne restaure que si sys coupé
	Beq.s	.LegoOk
	Movem.l	D0-D7/A0-A6,-(A7)
	WaitHard	#10
	Clr.l	SYSTEM_RESIDENT
	Bsr	BIGTAKESYSTEM
*	Moveq	#8,D0		*
*	Bsr	PaletteRestore	*
	Move.w	#-1,ExeGENERALVbl
	Movem.l	(A7)+,D0-D7/A0-A6
.LegoOk	RTS

************* Pour prendre TOUT le système
*
* Cette routine n'est utilisée qu'ici, on peut donc la modifier 
* sans problème !
*
BIGTAKESYSTEM
	Jsr	TakeSystem2		COUPE TOUT !
	Jsr	Set1
	Move.l	CopList1,Cop1Lch
	VblWait	#10
	Clr.w	CopJmp1
	Move.w	#$8180,DMACon
	Jsr	SetScreenRegisters
	RTS

*************  Afficher un requester GURU, pour une erreur.
*
* A0: Adresse string
*
*
BIG_ERROR
	Move.l	MemBIGerror,A0
	Tst.l	A0
	Beq	.ErrInt
	
	Move.l	$4.w,A6
	Lea	IntName,A1
	Clr.l	D0
	Jsr	_LVOOpenLibrary(A6)
	Move.l	D0,IntBase
	Beq	.ErrInt	
	
	Move.l	IntBase,A6
	Clr.l	D0
	Move.l	MemBIGerror,A0
	Move.l	#30,D1
	Jsr	_LVODisplayAlert(A6)
	
.Clos	Move.l	$4.w,A6
	Move.l	IntBase,A1
	Jsr	_LVOCloseLibrary(A6)

.ErrInt	RTS
	
	
MsgErrSprite
	Dc.w	13
	Dc.b	17
	Dc.b	'!!!ERROR!!! The Sprite files could not be loaded. Check files and memory. !!!',0
	Dc.b	0

MsgErrMem	Dc.w	17
	Dc.b	13
	Dc.b	'!!!ERROR!!! As you can imagine, there''s a lack of memory !!!',0
	Dc.b	0

	
IntName	Dc.b	'intuition.library',0		
IntBase	Dc.l	0	
	

