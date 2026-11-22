
CaptureEcran
	Tst.w	ExeSauveScreen
	Beq	.NoSav
	Tst.l	SauvePtr
	Beq	.NoSav
	Movem.l	D0/A0-A1,-(A7)
	Move.l	SauvePtr,A0
	Move.l	Planar,A1
	Move.l	#(SizePlan*7)/4-1,D0
.Loop	Move.l	(A1)+,(A0)+
	Dbf	D0,.Loop
	Movem.l	(A7)+,D0/A0-A1
	*********	
	Movem.l	A0-A1/D1/D3-D5,-(A7)
	Moveq	#19,D3
	Moveq	#PriSonDontMove,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,A0-A1/D1/D3-D5
	*********
	Clr.w	ExeSprite		Plus de sprites
	*Move.w	ExeLevel,TempExe	Plus de temps de level
	*Clr.w	ExeLevel
	Move.w	#-1,ExeSprite
	*Move.w	TempExe,ExeLevel
.NoSav	RTS

	
	
	
	
	***************************** D1: Y
DEBUG	Movem.l	D0-D7/A0-A6,-(A7)
	Movea.l	Planar,A0
	Adda.l	#2*SizePlan,A0
	Movea.l	A0,A1
	Moveq	#2,D0
	And.l	#$FFFF,D1
	Cmp.l	#20,D1
	Ble.s	.Ok
	Clr.l	D1
.Ok	*Moveq	#0,D1
	Move.l	Temp1,D2
	Moveq	#'0',D3
	Jsr	QPrintH
	Addq.w	#2,D0
	*Addq.w	#1,D1
	Move.l	Temp2,D2
	Jsr	QPrintH	
	Movem.l	(A7)+,D0-D7/A0-A6		

	Movem.l	D0-D7/A0-A6,-(A7)
	Movea.l	Planar,A0
	*Adda.l	#2*SizePlan,A0
	Movea.l	A0,A1
	Moveq	#2,D0
	And.l	#$FFFF,D1
	Cmp.l	#20,D1
	Ble.s	.Ok2
	Clr.l	D1
.Ok2	*Moveq	#0,D1
	Move.l	Temp1,D2
	Moveq	#'0',D3
	Bsr	QPrintH
	Addq.w	#2,D0
	*Addq.w	#1,D1
	Move.l	Temp2,D2
	Bsr	QPrintH	
	Movem.l	(A7)+,D0-D7/A0-A6		

	Movem.l	D0-D7/A0-A6,-(A7)
	Movea.l	Planar,A0
	Adda.l	#3*SizePlan,A0
	Movea.l	A0,A1
	Moveq	#2,D0
	And.l	#$FFFF,D1
	Cmp.l	#20,D1
	Ble.s	.Ok4
	Clr.l	D1
.Ok4	*Moveq	#0,D1
	Move.l	Temp1,D2
	Moveq	#'0',D3
	Bsr	QPrintH
	Addq.w	#2,D0
	*Addq.w	#1,D1
	Move.l	Temp2,D2
	Bsr	QPrintH	
	Movem.l	(A7)+,D0-D7/A0-A6		

	Movem.l	D0-D7/A0-A6,-(A7)
	Movea.l	Planar,A0
	Adda.l	#4*SizePlan,A0
	Movea.l	A0,A1
	Moveq	#2,D0
	And.l	#$FFFF,D1
	Cmp.l	#20,D1
	Ble.s	.Ok5
	Clr.l	D1
.Ok5	*Moveq	#0,D1
	Move.l	Temp1,D2
	Moveq	#'0',D3
	Bsr	QPrintH
	Addq.w	#2,D0
	*Addq.w	#1,D1
	Move.l	Temp2,D2
	Bsr	QPrintH	
	Movem.l	(A7)+,D0-D7/A0-A6		

	Movem.l	D0-D7/A0-A6,-(A7)
	Movea.l	Planar,A0
	Adda.l	#1*SizePlan,A0
	Movea.l	A0,A1
	Moveq	#2,D0
	And.l	#$FFFF,D1
	Cmp.l	#20,D1
	Ble.s	.Ok6
	Clr.l	D1
.Ok6	*Moveq	#0,D1
	Move.l	Temp1,D2
	Moveq	#'0',D3
	Bsr	QPrintH
	Addq.w	#2,D0
	*Addq.w	#1,D1
	Move.l	Temp2,D2
	Bsr	QPrintH	
	Movem.l	(A7)+,D0-D7/A0-A6		

	Movem.l	D0-D7/A0-A6,-(A7)
	Movea.l	Planar,A0
	Adda.l	#5*SizePlan,A0
	Movea.l	A0,A1
	Moveq	#2,D0
	And.l	#$FFFF,D1
	Cmp.l	#20,D1
	Ble.s	.Ok7
	Clr.l	D1
.Ok7	*Moveq	#0,D1
	Move.l	Temp1,D2
	Moveq	#'0',D3
	Bsr	QPrintH
	Addq.w	#2,D0
	*Addq.w	#1,D1
	Move.l	Temp2,D2
	Bsr	QPrintH	
	Movem.l	(A7)+,D0-D7/A0-A6		


	RTS
	*****************************

VBLDEBUG_START	* Gris
	Tst.w	CHEAT_ENABLED
	Beq.s	.NoCheat
	Move.w	#%0000001000111111,BplCon2	Ecriture palette (+ Kill EHB+ Priorités Sprites)
	Move.w	#$0010,BplCon3		Border blank
	Move.w	#$555,$dff180
.NoCheat	RTS

VBLDEBUG_START2	* Rouge
	Tst.w	CHEAT_ENABLED
	Beq.s	.NoCheat
	Move.w	#%0000001000111111,BplCon2	Ecriture palette (+ Kill EHB+ Priorités Sprites)
	Move.w	#$0010,BplCon3		Border blank
	Move.w	#$500,$dff180
.NoCheat	RTS

VBLDEBUG_START3	* Jaune
	Tst.w	CHEAT_ENABLED
	Beq.s	.NoCheat
	Move.w	#%0000001000111111,BplCon2	Ecriture palette (+ Kill EHB+ Priorités Sprites)
	Move.w	#$0010,BplCon3		Border blank
	Move.w	#$FF0,$dff180
.NoCheat	RTS
	
VBLDEBUG_END
	Tst.w	CHEAT_ENABLED
	Beq.s	.NoCheat
	Move.w	#%0000001000111111,BplCon2	Ecriture palette (+ Kill EHB+ Priorités Sprites)
	Move.w	#$0010,BplCon3		Border blank
	*Move.w	#$000,$dff180
	Move.w	CHEAT_COLOUR,$dff180
.NoCheat	RTS
