

TimeSlideBegin		=	20*50	temps de départ
TimeSlideContinue		=	20*50	d'une page à l'autre

TimeAttBas		=	50
TimeAttHaut		=	2*50
TimeRalent		=	1	Ralentissement en VBLs

CreditsAppearTime		=	50
CreditsFadeTime		=	25

ImDebSlide		=	4
ImFinSlide		=	5
ImBonus			=	5

BonusHeight		=	377

	***********************
	*** Affichage SLIDE ***
	***********************
SLIDE1	Move.l	#40*(BonusHeight-256),YActBonus	Pour le scrolling de l'écran bonus
	Move.l	#40,SensActBonus	sens (en octets)
	Clr.l	WaitBonus

	*** FADING de l'écran actuel
	Move.l	#PalSrc,A0	Palette
	Move.l	#128,D0		
	Move.l	MenuACol,D1	Couleur 0 du dégradé (36)
	Bsr	PalClr	A0/D0/D1	
	*** Fading
	Move.l	#MenuACol,A0
	Move.l	#PalSrc,A1
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#128,D0		
	Move.l	#MenuAFadeTime,D1	
	Move.w	#-1,FadeBtw_BreakEnable
	Bsr	FadeBetween_Run
	Tst.w	FadeBtw_Finished
	Beq	Break
	Move.l	#PalSrc,A0
	Move.l	#128,D0
	Jsr	MakePaletteNew
SLIDE2
	* Chargement image *
	Move.l	SlidePicAct,D0
	Bsr	ChargePic		Retour: Pic_Ptr,PicLen
	***
	Move.l	SlidePicAct,D0
	Lea	PaletteDef,A3
	Move.l	(A3,D0.w*4),PalPtr

	Lea	PicturesDef,A3
	Mulu.w	#Pic_SIZEOF,D0
	Adda.w	D0,A3
	Move.l	Pic_Ptr(A3),PicPtr
	***
	Tst.l	PicPtr
	Beq	ERROR2
	Tst.l	PalPtr
	Beq	ERROR2
	* Dégradés *
	Move.l	SlidePicAct,D0
	*Cmp.l	#ImBonus,D0
	*Bne.s	.Nop2
	Clr.l	YActBonus	
.Nop2
	Cmp.l	#6,D0
	Bge.s	.NoDegr

	Move.w	#32,D0		Couleur départ
	Move.w	#63,D1		Couleur fin
	Move.w	DegradeMenuA,D2	Dégradé
	Move.l	PalPtr,A0
	Bsr	MakeDegrad
	Move.l	PalPtr,A3
	Move.l	36*4(A3),(A3)
.NoDegr



	Movea.l	A3,A0		Pour displaypic2
	Move.l	#128,D0		

	Move.l	PicPtr,A3
	Moveq	#7,D1		<- En dur: Nb plans image source!
	Move.l	#(320/8)*256,D3	Taille plan en chip
	Movea.l	Planar,A2		Chip

	Move.l	SlidePicAct,D2
	Cmp.w	#ImBonus,D2
	Bne.s	.Normal	
	Move.l	#BonusHeight*40,D2		320*356 => 40*356 = 14240
	Bra.s	.Tout
.Normal	Move.l	#SizePlan,D2	Taille plan source
.Tout	Move.l	D2,SizePlanAct

	* DEBUG: Mais attention! il ne faut pas de double buffer!
	* car taille en CHIP trop petite pour 2*BONUS !
	Move.l	D2,D3		Taille plan en chip 

	Bsr	DisplayPic2	Display	A0/D0 A3/D1/D2/D3

	Movea.l	Planar,A2
	****
	Move.l	SlidePicAct,D0	4:Credits   5:Bonus	   6:Test
	Cmp.w	#ImBonus,D0
	Bne	.NoDe
	Adda.l	YActBonus,A2
.NoDe
	****

	Bsr	DisplayPic2Go	GO!

	Move.l	#PalSrc,A0	Fading affichage
	Move.l	PalPtr,A1
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#128,D0
	Move.l	#CreditsAppearTime,D1		
	Move.w	#-1,FadeBtw_BreakEnable
	Bsr	FadeBetween_Run
	Tst.w	FadeBtw_Finished
	Beq	Break
	Move.l	PalPtr,A0
	Move.l	#128,D0
	Jsr	MakePaletteNew
	Clr.l	AutoCounter
	Move.w	#-1,SlideBreak	Tout différent timing = Break !


.NoFire2	***********
	Move.l	ClavierPtr,A0
	Tst.b	HotKey_MenuSlideShow(A0)	Slide continue
	Bne.s	.ContS
	Move.l	AutoCounter,D3
	Cmp.l	#TimeSlideContinue,D3
	Blt.s	.NoEnd
.ContS	Clr.l	AutoCounter
	Clr.w	SlideBreak
	Bra	.Fire
.NoEnd	***********	
	VblWait	#30		Synchro pour MAJ copperliste
	Bsr	TestInputs	On attend le FIRE
	
	Move.l	SlidePicAct,D0	4:Credits   5:Bonus	6:Test
	Cmp.w	#ImBonus,D0
	Bne	.Wait		

	
	***** Mode scrolling vertical (pour l'écran des bonus)	
	*
	*
	Move.l	D4,-(A7)		Mise à jour copperlist
	Move.l	CopPlanAdr,A0
	Movea.l	Planar,A2
	Adda.l	YActBonus,A2
	CopPlan	A2,SizePlanAct,#7		Adr,Siz,Nb
	Move.l	(A7)+,D4

	Move.l	WaitBonus,D0
	Beq.s	.NoW
	Subq.l	#1,D0
	Move.l	D0,WaitBonus
	Bge.s	.Wait
.NoW
	Move.l	#40*(BonusHeight-256),D1
	Move.l	YActBonus,D0	Scrolling
	Add.l	SensActBonus,D0
	Move.l	#TimeRalent,WaitBonus	Ralentissement
	Tst.l	D0
	Bge.s	.Ok2		*
	*Move.l	#TimeRalent,WaitBonus	Ralentissement
	Tst.l	SensActBonus
	Bgt.s	.NoChg1
	Move.l	#TimeAttHaut,WaitBonus	Attente de fin de course	
	Move.l	#40,SensActBonus
.NoChg1	Clr.l	D0
.Ok2	Cmp.l	D1,D0
	Blt.s	.Ok1		*
	*Move.l	#TimeRalent,WaitBonus	Ralentissement
	Tst.l	SensActBonus
	Blt.s	.NoChg2
	Move.l	#TimeAttBas,WaitBonus	Attente de fin de course
	Move.l	#-40,SensActBonus
.NoChg2	Move.l	D1,D0
.Ok1	Move.l	D0,YActBonus
	*
	*
	***** Fin de la partie réservée au scrolling vertical

.Wait
	Movea.l	ClavierPtr,A0
	Tst.b	HotKey_MenuQuit(A0)
	Bne.s	.Fire

	Tst.w	D4
	Beq	.NoFire2
.Fire	******

	Move.l	PalPtr,A0		Fading au noir
	Lea	PalWork,A1
	Move.l	#128,D0		Nombre de longs mots
	Bsr	CopZone
	
Refade
	Move.l	#PalSrc,A0	Palette
	Move.l	#128,D0		
	Move.l	PalPtr,A1
	Move.l	(A1),D1
	Bsr	PalClr	A0/D0/D1	

	Move.l	#PalWork,A0	Source (soit image soit palette act)
	Move.l	#PalSrc,A1	But
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#128,D0
	Move.l	#CreditsFadeTime,D1		
	Clr.w	FadeBtw_BreakEnable
	Bsr	FadeBetween_Run
	Move.l	#PalSrc,A0
	Move.l	#128,D0
	Jsr	MakePaletteNew
Error2	Move.l	SlidePicAct,D0
	*Bsr	FreePic

	*** Restauration copperliste si jamais mode scrolling
	* Modif: 02/06/2000	
	Move.l	SlidePicAct,D0	4:Credits   5:Bonus	6:Test
	Cmp.w	#ImBonus,D0
	Bne.s	.FinRCop	
	Clr.l	YActBonus		Prochain scrolling commence à 0
	Move.l	CopPlanAdr,A0
	Movea.l	Planar,A2
	Move.l	#SizePlan,SizePlanAct
	CopPlan	A2,SizePlanAct,#7		Adr,Siz,Nb
.FinRCop 	* Fin modif


	*** Next image
	Move.l	SlidePicAct,D0	4:Credits   5:Bonus
	Addq.w	#1,D0
	Cmp.w	#ImFinSlide,D0
	Ble.s	.OkP
	Move.l	#ImDebSlide,SlidePicAct
	Bra.s	.NoBoucl
.OkP	Move.l	D0,SlidePicAct	Inversion écran
	* Bouclage ?
	Tst.w	SlideBreak
	Beq	SLIDE2
.NoBoucl

	Move.l	#PalSrc,A0
	Move.l	#128,D0
	Jsr	MakePaletteNew

	RTS

Break	Move.l	#256,D0		Copie palette act
	Move.l	#PalAct,A0
	Move.l	#PalWork,A1
	Bsr	ConvPal		$R,$G,$B -> $RGB
	Move.w	#-1,SlideBreak
	Bra	ReFade
	
	
	
