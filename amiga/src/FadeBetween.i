

*
* Pour le fading multitaches, utiliser FadeBtw_Activate qui se met à 0
* dès que le fading est fini.
*

****************
*
*
*  A0: Palette Source
*  A1: Palette cible
*  A2: Adresse de travail (4*3*Nb couleur) pour les vecteurs
*  D0: Nombre de couleurs
*  D1: Nombre d'étapes .W
*  A4: Couleurs actuelles (Travail)  (3*4*Nb couleurs)
*	
FadeBetween
	VblWait	#25
	Bsr	FadeBtw_Init
.Run	ltest
	beq.s	.bug
	VblWait	#10
	Bsr	FadeBtw_Run
	*Tst.w	FadeBtw_State
	Tst.w	FadeBtw_Activate
.bug	Bgt.s	.Run
	RTS

	******************

**************************

FadeBetween_Run	* D1: Temps de fading
	Tst.w	D1
	Ble	.Err
	Movem.l	D0-D7/A0-A6,-(A7)
	Clr.w	FadeBtw_Finished
	Clr.w	FadeBtw_Activate
	Bsr	FadeBtw_Init	
	Move.w	#-1,FadeBtw_Activate
.Loop1	Tst.w	FadeBtw_BreakEnable
	Beq.s	.NoBreak
	Bsr	TestInputs
	Tst.w	D4
	Bne	.EndLoop2		Aucun feu enclenché
	***
	Movea.l	ClavierPtr,A0
	Tst.b	69(A0)
	Bne.s	.NoChg1
	Clr.w	KeyStateESC	
	Bra.s	.Chg1
.NoChg1	Tst.w	KeyStateESC
	Bne.s	.Chg1
	Move.w	#1,KeyStateESC
	Bra	.EndLoop2
.Chg1	***
	LTest			<---- ???
	Beq	.EndLoop2	
.NoBreak	Tst.w	FadeBtw_Activate
	Bne.s	.Loop1
.EndLoop1	Move.w	#-1,FadeBtw_Finished
.EndLoop2	Clr.w	FadeBtw_Activate
	Movem.l	(A7)+,D0-D7/A0-A6
.Err	RTS




	
FadeBetweenMusic_Run	* D1: Temps de fading
	Ext.l	D1
	Tst.w	D1
	Ble	.Err	
	Movem.l	D0-D7/A0-A6,-(A7)

	IFNE	Music_Activation	
	Move.l	D0,-(A7)
	Move.w	P61_Master,D0	
	Swap	D0
	Clr.w	D0
	Move.l	D0,MusicFadeVol
	Divu.l	D1,D0		Vecteur = Volume/Time
	Move.l	D0,MusicFadeVec
	Move.l	(A7)+,D0
	ENDC

	*Move.l	MusicFadeVol,Temp1
	*Move.l	MusicFadeVec,Temp2
	*Bsr	DEBUG
	*lwaitp	
	
	Clr.w	FadeBtw_Finished
	Clr.w	FadeBtw_Activate
	Bsr	FadeBtw_Init	
	Move.w	#-1,FadeBtw_Activate
.Loop1	Tst.w	VblPassed
	Beq.s	.TstE
	Clr.w	VblPassed
	Move.l	MusicFadeVol,D0
	Sub.l	MusicFadeVec,D0
	Bge.s	.OkV
	Clr.l	D0
.OkV	Move.l	D0,MusicFadeVol
	Swap	D0

	IFNE	Music_Activation
	Move.w	D0,P61_Master
	ENDC
.TstE	Tst.w	FadeBtw_Activate
	Bne.s	.Loop1	
.EndLoop1	Move.w	#-1,FadeBtw_Finished
.EndLoop2	Clr.w	FadeBtw_Activate
	Movem.l	(A7)+,D0-D7/A0-A6
.Err	RTS
	*ENDC


**************************


FadeBtw_Init
	Ext.l	D1
	Tst.w	D1
	Bgt.s	.Ok
	Clr.w	FadeBtw_State
	RTS	
.Ok	Move.l	A2,FadeBtw_MemVec	Sauve adresse vecteurs
	Move.l	A4,FadeBtw_MemAct	Sauve adresse couleurs
	Move.w	D1,FadeBtw_State
	Subq.w	#1,D0
	Move.w	D0,FadeBtw_NbCouls
.Precalc	Move.l	(A0)+,D5		Lecture source
	Move.l	(A1)+,D6		Lecture cible
	Moveq	#2,D7
.Couls	Clr.l	D3
	Move.b	D6,D3		Lecture Blue,Green,Red
	Clr.l	D4
	Move.b	D5,D4		Source
	Swap	D4
	Move.l	D4,(A4)+	<-- Couleur actuelle
	Swap	D3
	Sub.l	D4,D3
	Divs.l	D1,D3	<---- Div par nombre d'étapes
	Move.l	D3,(A2)+	<- On sauve les vecteurs Blue,Green,Red
	Lsr.l	#8,D5
	Lsr.l	#8,D6
	Dbf	D7,.Couls
	Dbf	D0,.Precalc			
	RTS

FadeBtw_Run
	Movea.l	FadeBtw_MemVec,A3	Sauve adresse vecteurs
	Movea.l	FadeBtw_MemAct,A5	Sauve adresse couleurs
	Clr.w	Number		routine couleur
	Move.w	FadeBtw_NbCouls,D2
.Fade
	Move.l	(A5),D3	Couleur actuelle	BLUE
	Move.l	D3,D4
	Add.l	(A3)+,D3	+ Vecteur
	Move.l	D3,(A5)+
	Swap	D4
	Move.b	D4,Blue
	Move.l	(A5),D3	Couleur actuelle	GREEN
	Move.l	D3,D4
	Add.l	(A3)+,D3	+ Vecteur
	Move.l	D3,(A5)+
	Swap	D4
	Move.b	D4,Green
	Move.l	(A5),D3	Couleur actuelle	RED
	Move.l	D3,D4
	Add.l	(A3)+,D3	+ Vecteur
	Move.l	D3,(A5)+
	Swap	D4
	Move.b	D4,Red		
	Movem.l	D0-D7/A0-A6,-(A7)
	Bsr	Colour
	Movem.l	(A7)+,D0-D7/A0-A6
	Add.w	#1,Number
	Dbf	D2,.Fade
	Move.w	FadeBtw_State,D1
	Dbf	D1,.Vbl
	Clr.w	FadeBtw_Activate		
.Vbl	Move.w	D1,FadeBtw_State
	RTS

	

****************************

********* Conversion palette $B.L,$G.L,$R.L -> $RGB.L
*
* A0: Source
* A1: Cible
* D0: Nb couleurs
*
CONVPAL	Movem.l	D0/D2-D3/A0-A1,-(A7)
	Subq.w	#1,D0
.CopPal1	Clr.l	D3
	Move.l	(A0)+,D2	Blue
	Swap	D2
	Or.b	D2,D3
	Move.l	(A0)+,D2	Green
	Lsr.l	#8,D2
	Clr.b	D2
	Or.w	D2,D3
	Move.l	(A0)+,D2	Red
	Clr.w	D2
	Or.l	D2,D3
	Move.l	D3,(A1)+	Cible
	Dbf	D0,.CopPal1
	Movem.l	(A7)+,D0/D2-D3/A0-A1
	RTS
	


FadeBtw_NbCouls	Ds.w	1
FadeBtw_State	Ds.w	1
FadeBtw_Activate	Ds.w	1
FadeBtw_MemVec	Ds.l	1
FadeBtw_MemAct	Ds.l	1
FadeBtw_BreakEnable	Ds.w	1
FadeBtw_Finished	Ds.w	1

