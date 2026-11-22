*********************************

IntRoutine1 *** VBL

	Movem.l	D0/D1,-(A7)

*	Jsr	VBLDEBUG_START

	Move.l	CHEAT_ENABLED,D0	-1:Ok 0:Rien 1:Effacer 3:Afficher
	Tst.l	D0
	Ble.s	.CMFin		<=0 pas de couleur
	Cmp.l	#3,D0
	Bne.s	.CMRestor

	*Move.w	#%0000000100000000,BplCon2	Lecture palette
	Move.w	#%0000001100111111,BplCon2	Lecture palette (+ Kill EHB+ Priorités Sprites)
	Move.w	#$0010,BplCon3	Palette 0 bits forts
	Move.w	$DFF180,CHEAT_COLOUR

	Moveq	#1,D0		Programmation effacement next VBL
	Move.l	#$FFF,D1		Couleur temporaire
	Bra.s	.CMAff	
.CMRestor	Move.w	CHEAT_COLOUR,D1
	Subq.l	#2,D0
.CMAff	Move.w	#%0000001000111111,BplCon2	Ecriture palette (+ Kill EHB+ Priorités Sprites)
	Move.w	#$0010,BplCon3		Border blank
	Move.w	D1,$dff180
	Move.l	D0,CHEAT_ENABLED	
.CMFin	Movem.l	(A7)+,D0/D1


	****************************** DEBUT NORMAL
	Addq.l	#1,AutoCounter	Début level + slide menus
	Tst.w	ExeGENERALVbl
	Bne.s	.OkGene
	RTS
.OkGene	Move.w	#-1,VblPassed
	Move.l	BarreDecounter,D0
	Beq.s	.OkBD
	Subq.l	#1,D0
	Move.l	D0,BarreDecounter
	Bgt.s	.OkBD
	Bsr	Set3
.OkBD	Subq.l	#1,AutoDecounter
	Bge.s	.OkAD
	Clr.l	AutoDecounter
.OkAD	

	**********************

	Movem.l	D0-D7/A0-A6,-(A7)
	********************************	Musique P6
	IFNE	Music_Activation

	 Tst.w	ExeZik
	 Beq.s	.NoZik
	 Movem.l	Sauve,D0-D7/A0-A6
	 Lea	$DFF000,A6
	 Jsr	P61_Music
	 Movem.l	D0-D7/A0-A6,Sauve
.NoZik
	ENDC

	********************************	EFFETS DE PALETTE
	Tst.l	PALETTE_IN_PROGRESS
	Bne	.NotOkP
	********* FADING
	Tst.w	FadeBtw_Activate
	Beq.s	.NoFade
	Jsr	FadeBtw_Run
	Bra.s	.NoCycle		Pas de cycle si fading !
.NoFade	********* CYCLE
	Tst.w	Cycle_Activate
	Beq.s	.NoCycle
	*** Attente ou execution ?
	Move.w	Cycle_Wait,D0
	Subq.w	#1,D0
	Bge.s	.OkCyc
	Move.w	Cycle_Speed,D0
.OkCyc	Move.w	D0,Cycle_Wait
	Bgt.s	.NoCycle
	Move.l	Cycle_PalAdr,A0
	Move.w	Cycle_FirstCoul,D0
	Move.w	Cycle_LastCoul,D1
	Tst.w	Cycle_Activate
	Blt.s	.Inv
	Jsr	CyclePalette
	Bra.s	.NoCycle
.Inv	Jsr	CyclePaletteINVERSE
.NoCycle	********* FLASH
	Tst.w	ExeFlash
	Beq.s	.NoFlash
	Move.w	LevelInfoState,D0
	Blt.s	.NoFlash
	Cmp.w	#1,D0
	Bgt.s	.NoFlash	
	Move.w	Flash_Cpt,D0
	Dbf	D0,.NoEnd
	Move.w	#Flash_Time,Flash_Cpt
	Move.l	Flash_Coul1,D0
	Move.l	Flash_Coul2,Flash_Coul1
	Move.l	D0,Flash_Coul2
	Move.l	D0,RGB
	Move.w	Flash_CoulNumber,Number
	Bsr	Colour
	Bra.s	.NoFlash
.NoEnd	Move.w	D0,Flash_Cpt
.NoFlash
.NotOkP	****

	********************************	Timing level	

	*************
	*Moveq	#1,D1
	*Move.w	ExeLevel,Temp1
	*Move.w	LvlEndFill,Temp1+2
	*Move.l	TimeLvl2,Temp2	
	*Bsr	DEBUG
	*************

	Tst.w	ExeLevel
	Beq	.NoLevel		$c34f

	Tst.w	WinnersPhase
	Bne	.NoLevel

	******* Afficher le TIMER *************

	Subq.l	#1,TimeLvl2
	Move.l	TimeLvl2,D0
	Ble	.GAME_OVER
	Divu.l	#50,D0		Nombre de secondes
	* On a les 50èmes de seconde en Rab dans la partie haute
	* on ne les affiche pas, donc on s'en fout...
	
	* On a D0 secondes
	Divu.w	#60,D0		Nombre de minutes	
	Clr.l	D2
	Move.w	D0,D2		D2: Minutes
	Divu.w	#10,D2		Pour récupérer le chiffre de droite
	Swap	D2
	Clr.w	D0		Pour le Divu.w (32/16=16:16)
	Swap	D0		D0: Secondes restantes (0-59)
	Divu.w	#10,D0
	Move.w	D0,D1		D1: Nombre de dizaines de secondes
	Swap	D0		D0: Nombre d'unités de secondes

	* D2: Minutes
	* D1: Secondes (Dizaines)
	* D0: Secondes (Unités)

	Move.w	#(2*SizeLine*4+PosDigit/8+5)*8,D4	Secondes unités
	Addq.w	#1,D0
	Tst.w	RequestAffAllDigit
	Bne.s	.AffAl12
	Cmp.w	MemTime1,D0
	Beq.s	.Nop12
.AffAl12	Move.w	D0,MemTime1
	Bsr	DigitCopy8
.Nop12
	Move.w	#(2*SizeLine*4+PosDigit/8+3)*8,D4	Secondes dizaines
	Move.w	D1,D0
	Addq.w	#1,D0
	Tst.w	RequestAffAllDigit
	Bne.s	.AffAl22
	Cmp.w	MemTime2,D0
	Beq.s	.Nop22
.AffAl22	Move.w	D0,MemTime2
	Bsr	DigitCopy8
.Nop22
	Move.w	#(2*SizeLine*4+PosDigit/8)*8,D4	Minutes
	Move.w	D2,D0
	Addq.w	#1,D0
	Tst.w	RequestAffAllDigit
	Bne.s	.AffAl32
	Cmp.w	MemTime3,D0
	Beq.s	.Nop32
.AffAl32	Move.w	D0,MemTime3
	Bsr	DigitCopy8	
.Nop32
	Clr.w	RequestAffAllDigit
	************************************
.GAME_OVER
	Tst.l	TimeLvl2
	Bgt.s	.NoGameO

	*Bra	.NoLevel

	Clr.w	ExeLevelRalent
	Move.w	#-1,GameOver
	Clr.w	ExeLevel
	Move.w	#-1,LvlEndFill

	******* NIVEAU TERMINE : On fait TOUT PETER les bombes
	Movea.l	BombPtr,A1
	Move.w	LastNBomb,D5
	Subq.w	#1,D5
	Blt	.NoB1
.Loop12	Clr.w	Bomb_Time(A1)
	Adda.w	#Bomb_SizeOf,A1
	Dbf	D5,.Loop12

	*** FIN LEVEL: Les joueurs absents sont considérés comme morts
	* (Cela a pu ne pas être executé si on n'a pas d'ALERT TIME)
	Bsr	non_app_mort

	Bra	.NoLevel

.NoGameO	Move.l	TimeLvl1,D0
	Beq.s	.RunL
	Subq.l	#1,D0
	Move.l	D0,TimeLvl1
	Bgt	.NoLEnd		
.RunL	Tst.w	LvlEndFill	Fini ?
	Bne	.NoLevel
	* T=0 : On pose les murs
	
	Tst.w	LvlFillRemain	
	Bgt.s	.OkFRM
	Bra	.Error
.OkFRM		

	Move.w	LvlFillXMin,D0
	Subq.w	#1,D0
	Cmp.w	LvlFillXMax,D0
	Bgt.s	.ErrB
	Move.w	LvlFillYMin,D0
	Subq.w	#1,D0
	Cmp.w	LvlFillYMax,D0
	Bgt.s	.ErrB

	Move.w	LvlFillX,D0
	Move.w	D0,LvlFillXOld
	Move.w	LvlFillY,D1
	Move.w	D1,LvlFillYOld

	Bra.s	.OkSC6
.ErrB	Move.w	#-1,LvlEndFill	Seulement remplissage terminé
	Bra	.NoLevel
.OkSC6
	Move.w	LvlFillX,D0
	Move.w	LvlFillY,D1
	Move.w	LvlFillAnim,D4	N° du bloc <>0: Animation
	Bne	.AnimL

	Tst.w	ExeLevel
	Ble.s	.NopSpe		ExeLevel>0: En attente de 0
	Clr.w	ExeLevel		Donc level TERMINE
	Move.w	#-1,LvlEndFill	Fini...
	Bra	.NoLevel
.NopSpe
	Move.w	LvlFillSensX,D2
	Move.w	LvlFillSensY,D3
	Movea.l	LevelAct,A6
	Move.w	Level_Bloc+2*(_DECAL-1)(A6),D4	2*14	
	Move.w	D4,LvlFillAnim

	* On gère les mouvements en spirale carrée...
	
	Cmp.w	LvlFillXMin,D0
	Bne.s	.PasGauch
	Blt.s	.Error
	Tst.w	D2
	Bge.s	.PasGauch
	* On se dirigeait vers la gauche: changement	
	Clr.w	D2
	Moveq	#-1,D3
	Addq.w	#1,LvlFillXMin
.PasGauch	Cmp.w	LvlFillYMin,D1
	Bne.s	.PasHaut
	Blt.s	.Error
	Tst.w	D3
	Bge.s	.PasHaut
	* On se dirigeait vers le haut: changement	
	Moveq	#1,D2
	Clr.w	D3
	Addq.w	#1,LvlFillYMin
	Subq.w	#1,LvlFillRemain
	Bgt.s	.NoEnd2
.Error	Move.w	#-1,LvlEndFill	On a terminé le remplissage!
	Bra	.NoLevel	
.NoEnd2	
.PasHaut	Cmp.w	LvlFillXMax,D0
	Bne.s	.PasDr
	Bgt.s	.Error
	Tst.w	D2
	Ble.s	.PasDr
	* On allait à droite: changement	
	Clr.w	D2
	Moveq	#1,D3
	Subq.w	#1,LvlFillXMax
.PasDr	Cmp.w	LvlFillYMax,D1
	Bne.s	.PasBa
	Bgt.s	.Error
	Tst.w	D3
	Ble.s	.PasBa
	* On allait vers le bas: changement	
	Moveq	#-1,D2
	Clr.w	D3
	Subq.w	#1,LvlFillYMax
.PasBa	
	Move.w	LvlFillXMin,D6	Vérification pas de croisement
	Subq.w	#1,D6		????
	Cmp.w	LvlFillXMax,D6	de valeurs G-D et H-B
	Bgt	.Error
	Move.w	LvlFillYMin,D6
	Subq.w	#1,D6		????
	Cmp.w	LvlFillYMax,D6
	Bgt	.Error

	Add.w	D2,D0	X=X+Mvt X
	Add.w	D3,D1	Y=Y+Mvt Y

	Move.w	D0,LvlFillX
	Move.w	D1,LvlFillY
	
	Move.w	D2,LvlFillSensX
	Move.w	D3,LvlFillSensY

	Tst.w	LvlEndFill
	Bne	.NoLevel

	Add.w	D0,D0	Position *2 !	
	Add.w	D1,D1

	* On vérifie les 4 cases sous le bloc

	Move.w	D1,D6
	Lsl.w	#6,D6
	Add.w	D0,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Movea.l	Dim2,A2	Visible
	Lea	(A2,D6.l),A2
	**********************
.Test1	Move.w	(A2),D2		(X,Y)
	Cmp.w	#Type_Bombe,D2
	Bne.s	.NoB1
	Movea.l	Dim1,A1	Bombes
	Move.w	(A1,D6.l),D2
	Mulu.w	#Bomb_SizeOf,D2
	Movea.l	BombPtr,A1
	Clr.w	Bomb_Time(A1,D2.l)
	Bra.s	.NoB11
.NoB1	
	Cmp.w	#Type_Bumper,D2
	Bne.s	.NoB11
	Movea.l	Dim6,A1	Bumpers
	Move.w	(A1,D6.l),D2
	Mulu.w	#Bumper_SizeOf,D2
	Movea.l	BumperPtr,A1
	Clr.w	Bumper_Activate(A1,D2.l)

.NoB11	Move.w	#Type_Bloc_NoDestr,(A2)	1 ou 2, on réaffiche pas de toutes façons !

.Test2	Move.w	SizeStructure(A2),D2	(X+1,Y)
	Cmp.w	#Type_Bombe,D2
	Bne.s	.NoB2
	Movea.l	Dim1,A1	Bombes
	Move.w	SizeStructure(A1,D6.l),D2
	Mulu.w	#Bomb_SizeOf,D2
	Movea.l	BombPtr,A1
	Clr.w	Bomb_Time(A1,D2.l)
	Bra.s	.NoB21
.NoB2	
	Cmp.w	#Type_Bumper,D2
	Bne.s	.NoB21
	Movea.l	Dim6,A1	Bumpers
	Move.w	(A1,D6.l),D2
	Mulu.w	#Bumper_SizeOf,D2
	Movea.l	BumperPtr,A1
	Clr.w	Bumper_Activate(A1,D2.l)

.NoB21	Move.w	#Type_Bloc_NoDestr,SizeStructure(A2)
	
.Test3	Move.w	SizeStructure*64(A2),D2	(X,Y+1)
	Cmp.w	#Type_Bombe,D2
	Bne.s	.NoB3
	Movea.l	Dim1,A1	Bombes
	Lea	(A1,D6.l),A1
	Move.w	SizeStructure*64(A1),D2
	Mulu.w	#Bomb_SizeOf,D2
	Movea.l	BombPtr,A1
	Clr.w	Bomb_Time(A1,D2.l)
	Bra.s	.NoB31
.NoB3
	Cmp.w	#Type_Bumper,D2
	Bne.s	.NoB31
	Movea.l	Dim6,A1	Bumpers
	Move.w	(A1,D6.l),D2
	Mulu.w	#Bumper_SizeOf,D2
	Movea.l	BumperPtr,A1
	Clr.w	Bumper_Activate(A1,D2.l)

.NoB31	Move.w	#Type_Bloc_NoDestr,SizeStructure*64(A2)

.Test4	Move.w	SizeStructure*65(A2),D2	(X+1,Y+1)
	Cmp.w	#Type_Bombe,D2
	Bne.s	.NoB4
	Movea.l	Dim1,A1		Bombes
	Lea	(A1,D6.l),A1
	Move.w	SizeStructure*65(A1),D2
	Mulu.w	#Bomb_SizeOf,D2
	Movea.l	BombPtr,A1
	Clr.w	Bomb_Time(A1,D2.l)
	Bra.s	.NoB41

.NoB4	Cmp.w	#Type_Bumper,D2
	Bne.s	.NoB41
	Movea.l	Dim6,A1	Bumpers
	Move.w	(A1,D6.l),D2
	Mulu.w	#Bumper_SizeOf,D2
	Movea.l	BumperPtr,A1
	Clr.w	Bumper_Activate(A1,D2.l)

.NoB41	Move.w	#Type_Bloc_NoDestr,SizeStructure*65(A2)


 	*** On pose un nouveau bloc de fin de niveau: son
	Move.l	D1,-(A7)
	Moveq	#7,D3
	Moveq	#PriSonPoseFin,D1	Priorité
	Clr.w	SampleLoops
	Bsr	PlaySon
	Clr.w	ExeLevelRalent
	Move.l	(A7)+,D1
	***************
	Bra.s	.NopFF	* On affiche le bloc (D0,D1)=D4


.AnimL	Subq.w	#1,ExeLevelRalent	Multiplication du temps par 2...
	Bgt	.NoLEnd
	Move.w	#LevelRalentTime,ExeLevelRalent
	*
	Addq.w	#1,D4
	Move.w	D4,LvlFillAnim
	Add.w	D0,D0
	Add.w	D1,D1
	Move.w	D4,D2
	Movea.l	LevelAct,A6
	Sub.w	Level_Bloc+2*(_DECAL-1)(A6),D2	2*14
	Sub.w	#NbImFill-1,D2
	Blt.s	.NopFF		* NbImFill
	Clr.w	LvlFillAnim	
.NopFF
	* Il faut afficher le bloc a la position (D0,D1)
	* Et modifier le Dim visible, et gèrer les bombes: Déclenchement

	Movea.l	Planar,A1
	Movea.l	FontPtr,A2	<-- Sert a rien
	Move.w	D4,D5

	******
	*Cmp.w	#20,D5
	*Bgt.s	.Ok12
	*Move.l	D1,-(A7)
	*Move.w	D0,Temp1
	*Move.w	D1,Temp1+2
	*Move.w	D5,Temp2
	*Moveq	#5,D1
	*Bsr	DEBUG
	*
	*Move.w	LvlEndFill,Temp1
	*Move.w	ExeLevel,Temp1+2
	*Move.w	LvlFillAnim,Temp2
	*Move.w	ExeLevelRalent,Temp2+2
	*Moveq	#6,D1
	*Bsr	DEBUG
	*Move.l	(A7)+,D1
	*****************
	
	*Bra.s	.NoLEnd	
.Ok12
	****
	Move.w	D0,D3
	Bge.s	.OkMX
	Clr.w	D3
.OkMX	Cmp.w	#17*2+1,D3
	Ble.s	.OkAX
	Move.w	#17*2+1,D3
.OkAX
	Move.w	D1,D4	
	Bge.s	.OkMY
	Clr.w	D4	
.OkMY	Cmp.w	#14*2+1,D4
	Ble.s	.OkAY
	Move.w	#14*2+1,D4
.OkAY
	
	Bsr	TraceBlocWithMask		(X=D3,Y=D4,B=D5)
	Bra.s	.NoLevel
	
.NoLEnd	Move.l	TimeLvl1,D0
	Cmp.w	#SECONDE*10,D0	Reste quelques secondes...
	Bne.s	.NopTM10

	*** ALARME: On déclenche la sirène
	Moveq	#6,D3
	Moveq	#PriSonSirene,D1	Priorité
	Move.w	#2,SampleLoops	3 fois la sirène
	Bsr	PlaySon


	*** ALARME: Les joueurs absents sont considérés comme morts
	Bsr	non_app_mort
.NopTM10
.NoLevel

********************************	SPRITES
*
*
* je les mets EN DERNIER parce qu'il faut attendre la ligne
* #25 de toutes façons, alors autant éxécuter tout le reste
* pour perdre un peu moins de temps pour rien.
*
	IFNE	VblSprites_Activation
	 Tst.w	ExeSprite
	 Beq.s	.NoSpr
 	 VblWait	#25		Pour les Sprites (25, OBLIGE<=30)
	 Add.l	#1,TotalPlayingTime		temps de JEU !
	 Jsr	GestionSprites
.NoSpr
	ENDC


	********************************
*	Move.w	#0,BplCon3
*	Move.w	#$0,$dff180


*	Jsr	VBLDEBUG_START
*
*
*	*** MICRO		toutes les Vbl
*	Movea.l	MicroPtr,A0	pour l'instant un seul micro
*	Tst.l	A0
*	Beq.s	.NoMicro
*	Jsr	Micro_Routage
*.NoMicro
*
*
*	Jsr	VBLDEBUG_END

	
	Movem.l	(A7)+,D0-D7/A0-A6
	Lea	$dff000,a0
	Tst.b	#1	Z=0
	RTS


	******************************	FIN VBL
