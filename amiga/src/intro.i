INTRO	********************************

	Movea.l	Planar,A0		On efface l'écran
	Move.l	#SizePlan*2,D0
	Moveq	#8,D1
	Bsr	CLS

	******* Créer la copperlist pour 640*256*8
	
	Move.l	CopList2,A0
	CopMove	#%0000000000100000,#$96	Sprites OFF
	CopMove	#%01,#$1FC		FMode %10 ou %01 pour Hires
	CopMove	#%1000001000010000,#$100	BplCon0: 8 plans hires
	CopPlan	Planar,#80*256,#8
	CopMove	#$2081-$60,#$8E		Diw VH  $3081-$60
	CopMove	#$20c1,#$90			$30C1
	CopMove	#$30c1,#$92
	CopMove	#$3c-$8,#$92			DDf
	CopMove	#$3c+(640/4-8)-$8,#$94
	CopEnd	
	VblWait	#30
	Move.l	CopList2,Cop1Lch
	Clr.w	CopJmp1
	
.ShortCut
	*************************
	*** Affichage PROXIMA ***
	*************************
	Bsr	ClearSprites

	Lea	PalSrc,A0		Palette
	Move.l	#256,D0		32 pour l'ancien
	Move.l	#0,D1	
	Bsr	PalClr	A0/D0/D1

	Lea	PicturesDef,A3
	Move.l	Pic_Ptr(A3),A3
	Tst.l	A3
	Beq	.YACommeUneErreur

	****************
	Moveq	#8,D1		5 pour l'ancien
	Move.l	#80*256,D2	Taille plan source 40*340 pour l'ancien
	Movea.l	Planar,A2		Cible
	Move.l	#80*256,D3	sizeplan pour l'ancien
	Bsr	DisplayPic
	
	*** Fading affichage

	Move.l	#PalSrc,A0
	Move.l	#PalProxi,A1
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#256,D0		32 pour l'ancien
	Move.l	#250,D1		
	Move.w	#-1,FadeBtw_BreakEnable
	Bsr	FadeBetween_Run
	Tst.w	FadeBtw_Finished
	Beq	.Break

	* Conversion palette actuelle -> source

	Movea.l	#PalAct,A0	Source
	Movea.l	#PalSrc,A1	Cible
	Move.l	#256,D0		32 pour l'ancien
	Bsr	ConvPal

	* Palette réelle pour effacer les erreurs
	Movea.l	#PalProxi,A0
	Move.w	#256,D0
	Jsr	MakePaletteNew	

	* Palette blanche

	Move.l	#PalSrc,A0	PalSrc obligatoire pour Menu !
	Move.l	#256,D0		32 pour l'ancien
	Move.l	#$ffffff,D1
	Bsr	PalClr

	*** Inits nouveau fading (BLANC)
	
	Move.l	#PalProxi,A0	Source
	Move.l	#PalSrc,A1	Cible
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#256,D0		32 pour l'ancien
	Move.l	#40,D1		
	Move.w	#-1,FadeBtw_BreakEnable
	Bsr	FadeBetween_Run
	Tst.w	FadeBtw_Finished
	Bne	.NoBreak

.Break	*** On a interrompu le fading... grave ! on corrige

	Move.l	#PalSrc,A0	PalSrc obligatoire pour Menu !
	Move.l	#256,D0	
	Move.l	#$ffffff,D1
	Bsr	PalClr

	Move.l	#256,D0		Copie palette act
	Move.l	#PalAct,A0
	Move.l	#PalWork,A1
	Bsr	ConvPal		$R,$G,$B -> $RGB

	Move.l	#PalWork,A0	Source
	Move.l	#PalSrc,A1	Cible
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#256,D0		32 pour l'ancien
	Move.l	#10,D1
	Move.w	#0,FadeBtw_BreakEnable	ininterruptible
	Bsr	FadeBetween_Run
	
.NoBreak	Bsr	RemovePic
	***
	Moveq	#0,D0
	Bsr	FreePic
	***
.YACommeUneErreur

	******* Recréer la copperlist
	VblWait	#30
	Move.l	CopList1,Cop1Lch
	Clr.w	CopJmp1
	
	RTS

************ Initialiser une palette
*
* A0: Palette
* D0: Nb couls
* D1: Valeur d'initialisation
*
PalClr	Movem.l	D0/A0,-(A7)
	Subq.w	#1,D0
.Loop	Move.l	D1,(A0)+
	Dbf	D0,.Loop
	Movem.l	(A7)+,D0/A0
	RTS


************ Affichage d'une image
*
* A0: Palette
* D0: Nombre de couleurs
*
* A3: Image source
* D1: Nombre de plans de l'image source
* D2: Taille d'un plan source
*
* A2: Adresse cible en chip
* D3: Taille d'un plan en Chip
*
DISPLAYPIC
	VblWait	#25
	DMAClr	BitPlan|Copper|Sprite
	Movem.l	D1-D3/A2-A3,-(A7)
	Jsr	MakePaletteNew	
	Movem.l	(A7)+,D1-D3/A2-A3

*	Movem.l	D0-D2/A2,-(A7)
*	Move.l	CopList1,A0
*	CopPlan	Planar,D3,D1
*	Movem.l	(A7)+,D0-D2/A2

	********************* DECOMPACTER LE FICHIER IMAGE	
	Move.l	A3,A0		Source
	Move.l	A2,A1		Cible	
	Move.l	#163840,D6	ANTIBUG du decruncher
	Jsr	DECRUNCH


	Bra.s	.PasCopie
	Subq.w	#1,D1
.CopiePl	Movea.l	A2,A1	
	Movea.l	A3,A0
	Move.l	D2,D0
	Lsr.l	#2,D0
	Subq.w	#1,D0
.Copie	Move.l	(A0)+,(A1)+
	Dbf	D0,.Copie	
	Adda.l	D3,A2
	Adda.l	D2,A3
	Dbf	D1,.CopiePl
*	VblWait	#25
	
.PasCopie	
	DMASet	BitPlan|Copper
	RTS

************* Enlever une image proprement
*
*
*
*
RemovePic	
	VblWait	#25
	DMAClr	BitPlan
	Move.l	Planar,A0
	Move.l	#(SizePlan*(NbPlans))/4-1,D0
.Clr	Clr.l	(A0)+
	Dbf	D0,.Clr	
	VblWait	#25
	DMASet	BitPlan
	RTS


************ Affichage d'une image >>> Avec DOUBLE BUFFER <<<
*
* A0: Palette
* D0: Nombre de couleurs
*
* A3: Image source
* D1: Nombre de plans de l'image source
* D2: Taille d'un plan source
*
* (A2: Adresse cible en chip)
* D3: Taille d'un plan en Chip
*
* L'image source que je veux afficher est sûrement en FAST, donc 
* il faut la copier dans le buffer screen en CHIP pour pouvoir l'afficher.
*
* Fonction:
* - Copie de l'écran visible dans le deuxième écran
* - Affichage du deuxième écran
* - Copie de l'image dans le premier écran, partie visible
*
* Problème de cette fonction: si l'image à copier est plus grande que
* le screen, alors le backup est écrasé, ce qui occasionne un flash sur
* la partie visible pendant la copie.
*
*
DISPLAYPIC2
	VblWait	#35
	DMAClr	Sprite
	Move.l	A0,TempPal
	Move.l	D0,TempCoul

	Bra	.Pkoi


	**** ETAPE 1 : On copie l'écran actuel en écran de backup
	
	Movea.l	Planar,A4			A4: Ecran actuel
	Movea.l	A4,A5
	
toto	Set	SizePlan*(NbPlans+1)

	Add.l	#Toto,A5			A5: Ecran 2
	Move.l	#Toto/16-1,D0
.Loop1	Movem.l	(A4)+,D4-D7	Copie de A4 à A5
	Move.l	D4,(A5)+
	Move.l	D5,(A5)+
	Move.l	D6,(A5)+
	Move.l	D7,(A5)+
	Dbf	D0,.Loop1	
	
	**** ETAPE 2 : On affiche l'écran de backup pour ne pas avoir de saut

	VblWait	#230
	Movem.l	D0-D2/A2,-(A7)
	Move.l	CopList1,A0
	Movea.l	Planar,A4	
	Add.l	#toto,A4			Ecran "2"
	CopPlan	A4,D3,D1
	Movem.l	(A7)+,D0-D2/A2

	**** ETAPE 3 : Copie dans l'écran principal (pas affiché actuellement)
.PKoi
	Move.l	D1,-(A7)		à garder pour le CopPlan (ETAPE 4)
	Movea.l	Planar,A2		Cible en CHIP
	Subq.w	#1,D1
.CopiePl	Movea.l	A2,A1	Screen en CHIP	
	Movea.l	A3,A0	Image source (Même en FAST)
	Move.l	D2,D0	Taille plan source
	Lsr.l	#2,D0
	Subq.w	#1,D0
.Copie	Move.l	(A0)+,(A1)+
	Dbf	D0,.Copie	
	Adda.l	D3,A2	Chip
	Adda.l	D2,A3	Source
	Dbf	D1,.CopiePl
	Move.l	(A7)+,D1

	*** Palette
	*
	* On n'a plus besoin de créer la palette ici depuis que
	* j'utilise des fadings dans les menus pour l'affichage et
	* la disparition des écrans.
	*
	*Move.l	TempPal,A0
	*Move.l	TempCoul,D0
	*Movem.l	D1-D3/A2-A3,-(A7)
	*Jsr	MakePaletteNew	
	*Movem.l	(A7)+,D1-D3/A2-A3
	***

	Movem.l	D1/D3,MemDisplay
	RTS
	
* Recupération automatique de:
* 			D1: Nb de plans de l'image
*			D3: Taille d'un plan en chip
DISPLAYPIC2GO
	Movem.l	D0-D7/A0-A6,-(A7)

	**** ETAPE 4 : On affiche l'écran actuel
	Movem.l	MemDisplay,D1/D3
	VblWait	#230
	*Move.l	CopList1,A0	DEBUG 03/06/2000
	Move.l	CopPlanAdr,A0
	CopPlan	Planar,D3,D1
	DMASet	BitPlan|Copper
	Movem.l	(A7)+,D0-D7/A0-A6
	RTS


*	VblWait	#230
*	Movem.l	D0-D2/A2,-(A7)
*	Move.l	CopList1,A0
*	CopPlan	Planar,D3,D1
*	Movem.l	(A7)+,D0-D2/A2
*
*	DMASet	BitPlan|Copper
*	Movem.l	(A7)+,D0-D7/A0-A6
*

	include	FadeBetween.i
	
		



