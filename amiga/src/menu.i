
*************** MENU DE LEGOBLAST 
*
* Touches F1-F4: Activation/Désactivation des channels
*
*

KeySpeed	=	20
KeyRepeat	=	2

	rsreset
Pic_Ptr	Rs.l	1
Pic_Len	Rs.l	1
Pic_Name	Rs.l	1
Pic_SIZEOF Rs.w	0

**** Réglages pour les Menus

MenuAAppearTime	=	15
MenuAFadeTime	=	20
MenuAFadeTimeQUIT	=	100	200
MenuBAppearTime	=	15
MenuBFadeTime	=	5
FadeColourA	=	$000000
FadeColourB	=	$000000


MENU	********************************

	Move.l	#SizePlanMenu,VarSizePlan
	Move.l	#SizeLine,VarSizeLine
	Move.w	MusicVol,MusicVolBack

	Clr.w	FadeBtw_BreakEnable

	**** Ferme podium si existant
	Moveq	#3,D0
	Bsr	FreePic
	**** Coupe la musique
	IFNE 	Music_Activation
	 Moveq	#0,D0	N° de la musique dans la liste (0=No Zik)
	 Bsr	LaunchZik
	ENDC

	********* CHARGEMENTS de la musique et des images pour les menus

	Move.l	#-1,DO_NOT_RETAKE_SYSTEM	*** NE RIEN RECOUPER

	**** Vérifier que les images sont chargées
	Moveq	#1,D0
	Bsr	ChargePic
	Moveq	#2,D0
	Bsr	ChargePic

	**** Charger les images du slide...

	Move.w	#ImDebSlide,D0
.ChargL	Bsr	ChargePic
	Addq.w	#1,D0
	Cmp.w	#ImFinSlide,D0
	Ble.s	.ChargL

*	Moveq	#2,D0
*	Bsr	ChargePic
*	Moveq	#2,D0
*	Bsr	ChargePic	
*	Moveq	#2,D0
*	Bsr	ChargePic
	
	Clr.l	DO_NOT_RETAKE_SYSTEM
	Bsr	TEMP_TAKE_SYSTEM

	IFNE 	Music_Activation
	 Move.w	#64,MusicVol
	 Moveq	#9,D0	N° de la musique dans la liste (0=No Zik)
	 Bsr	LaunchZik
	 Move.l	#4,P61_Channels
	ENDC	

	Move.l	#ImDebSlide,SlidePicAct	4:Credits   5:Bonus

	Bsr	MAIN_MENU

	Bsr	FreeMenuData
		
	RTS


	********************* Virer toutes les images de la mémoire
	*
FreeAllPics
	Moveq	#9,D0
.Free	Bsr	FreePic
	Dbf	D0,.Free
	RTS
	

	********************* Virer l'image de la mémoire si elle existe
	* D0: N° de l'image
FreePic
	Movem.l	D0-D7/A0-A6,-(A7)
	Lea	PicturesDef,A0
	Mulu.w	#Pic_SIZEOF,D0
	Lea	(A0,D0.w),A0
	Move.l	Pic_Ptr(A0),A1
	Tst.l	A1
	Beq.s	.NotInMem
	Clr.l	Pic_Ptr(A0)
	Move.l	Pic_Len(A0),D0
	Move.l	$4.w,A6
	Jsr	_LVOFreeMem(A6)	A1/D0
.NotInMem	Movem.l	(A7)+,D0-D7/A0-A6
	RTS
	
	
	********************* charger l'image en mémoire
	* D0: N° de l'image
ChargePic		
	Movem.l	D0-D7/A0-A6,-(A7)
	Lea	PicturesDef,A1
	Mulu.w	#Pic_SIZEOF,D0
	Lea	(A1,D0.w),A1
	Tst.l	Pic_Ptr(A1)
	Bne.s	.Error
	Move.l	Pic_Name(A1),A0
	Move.l	#Public,D1	Chip
	Move.l	A1,-(A7)
	Bsr	TEMP_RESTORE_SYSTEM
	Jsr	ChargeFichier	A0/D1 -> A1/D0
	Bsr	TEMP_TAKE_SYSTEM
	Move.l	(A7)+,A2
	Move.l	D0,Pic_Len(A2)
	Beq.s	.Error
	Move.l	A1,Pic_Ptr(A2)
	*
.Error	Movem.l	(A7)+,D0-D7/A0-A6
	RTS


	********************* charger l'image en mémoire ET DECOMPRESSION
	* D0: N° de l'image
ChargeCRP		* Charge crunched pic
	Movem.l	D0-D7/A0-A6,-(A7)
	Lea	PicturesDef,A1
	Mulu.w	#Pic_SIZEOF,D0
	Lea	(A1,D0.w),A1
	Tst.l	Pic_Ptr(A1)
	Bne.s	.Error
	Move.l	Pic_Name(A1),A0
	Move.l	#Public,D1
	Move.l	A1,-(A7)
	Bsr	TEMP_RESTORE_SYSTEM
	Jsr	ChargeFichier	A0/D1 -> A1/D0
	Bsr	TEMP_TAKE_SYSTEM
	Move.l	(A7)+,A2
	Move.l	D0,Pic_Len(A2)
	Beq.s	.Error
	Move.l	A1,Pic_Ptr(A2)	A1 normalement

*	Move.l	A1,A0		DECOMPACTER LE FICHIER IMAGE
*	Move.l	Planar,A1
*	Move.l	ORIGINAL_SIZE,D6	
*	Jsr	DECRUNCH

.Error	Movem.l	(A7)+,D0-D7/A0-A6
	RTS



******** Constantes de l'écran des options

DecX	=	0
DecY	=	-1

Larg1	=	83	Case normale
Haut1	=	14
Larg2	=	19	petite case
Haut2	=	10

CaseA1X	=	109-1	85	
CaseA1Y	=	129	132
CaseA1L	=	Larg2+3
CaseA1H	=	Haut2

CaseA2X	=	57	
CaseA2Y	=	113+DecY
CaseA2L	=	Larg1
CaseA2H	=	Haut1

CaseA3X	=	57
CaseA3Y	=	143+DecY
CaseA3L	=	Larg1
CaseA3H	=	Haut1

CaseA4X	=	57
CaseA4Y	=	173+DecY
CaseA4L	=	Larg1
CaseA4H	=	Haut1

CaseP1X	=	217	
CaseP1Y	=	113+DecY
CaseP1L	=	Larg1
CaseP1H	=	Haut1

CaseP2X	=	217	
CaseP2Y	=	143+DecY
CaseP2L	=	Larg1
CaseP2H	=	Haut1

CaseP3X	=	217	
CaseP3Y	=	173+DecY
CaseP3L	=	Larg1
CaseP3H	=	Haut1


*****************************************************
*** 	  	MENU PRINCIPAL		***
*****************************************************


MAIN_MENU
	Clr.w	Cycle_Activate
	*************************
	***     Inits jeu     ***
	*************************
		
	Lea	PlayersSet,A1
	Clr.l	(A1)+
	Clr.l	(A1)
	Clr.w	NbJoueursAct
	Lea	JoyList,A1
.ClearJL	Tst.l	(A1)+
	Beq.s	.NopMJL
	Clr.w	(A1)+
	Bra.s	.ClearJL
.NopMJL	
	*************************
	*** Affichage MENU(A) ***
	*************************
	* Dégradés *
	Move.w	#32,D0	Couleur départ
	Move.w	#63,D1	Couleur fin
	Move.w	DegradeMenuA,D2	Dégradé
	Lea	MenuAcol,A0
	Bsr	MakeDegrad
	Move.l	MenuAcol+36*4,MenuACol
	* Palette *
	Lea	MenuAcol,A0
	Move.l	#128,D0
	* Image *
	Lea	PicturesDef+1*Pic_SIZEOF,A3
	Move.l	Pic_Ptr(A3),A3
	Move.l	A3,PicPtr
	Tst.l	A3
	Beq	QUITMenu
	Moveq	#7,D1
	Move.l	#(320/8)*256,D2
	* Chip *
	Movea.l	Planar,A2
	Move.l	#SizePlan,D3
	* DISPLAY *
	Bsr	DisplayPic2
	*************************
	
	Moveq	#0,D2			INITS BOB
	Move.w	D2,D3
	Mulu.w	#18*SizeLine,D3
	Add.l	#15+SizeLine*87,D3		Offset
	Bsr	BobONMain			Y actuel=0 (Esp.Y=18)

	Move.w	#0,Bpl1Mod
	Move.w	#0,Bpl2Mod
	Movea.l	Planar,A2
	Bsr	DisplayPic2Go	GO!
	
	Movem.l	D0-D7/A0-A6,-(A7)
	****** Apparition *
	*- Préparation palette source
	*Move.l	#PalSrc,A0	Palette
	*Move.l	#128,D0		
	*Move.l	#0,D1	
	*Bsr	PalClr	A0/D0/D1	
	*- Fading affichage
	Move.l	#PalSrc,A0
	Move.l	#MenuAcol,A1
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#128,D0	
	Move.l	#MenuAAppearTime,D1		
	Bsr	FadeBetween_Run

	Move.l	#MenuAcol,A0
	Move.l	#128,D0
	Jsr	MakePaletteNew
	Movem.l	(A7)+,D0-D7/A0-A6

	*Tst.l	MemBIGerror
	*Bne	QUITMenu

	************* CYCLE Couleurs pour box de sélection
	Clr.w	Cycle_Wait
	Move.w	#5,Cycle_Speed
	Move.w	#96,Cycle_FirstCoul
	Move.w	#96+15,Cycle_LastCoul
	Move.l	#MenuACol,Cycle_PalAdr
	Move.w	#1,Cycle_Activate	
	*************

	Clr.l	AutoCounter

	Move.l	D2,-(A7)
NoFire1	*WaitHard	#1		Attente du relâchement du feu
	VblWait	#45
	VblWait	#40
	Bsr	TestInputs
	Tst.w	D4
	Bne.s	NoFire1
	Move.l	(A7)+,D2
	
	***************
Main_Loop	VblWait	#45

	IFNE	Music_Activation	
	Move.l	A0,-(A7)
	Move.l	ClavierPtr,A0
	Tst.b	80(A0)	F1
	Beq.s	.NoF1
	*BChg	#0,P61_Channels
	Move.l	#1,P61_Channels
.NoF1
	Tst.b	81(A0)	F2
	Beq.s	.NoF2
	*BChg	#1,P61_Channels
	Move.l	#2,P61_Channels
.NoF2
	Tst.b	82(A0)	F3
	Beq.s	.NoF3
	*BChg	#2,P61_Channels
	Move.l	#3,P61_Channels
.NoF3
	Tst.b	83(A0)	F4
	Beq.s	.NoF4
	*BChg	#0,P61_Channels
	Move.l	#4,P61_Channels
.NoF4	Move.l	(A7)+,A0
	ENDC

	Move.w	#-1,Cycle_Activate	

	************************	Temps d'inactivité: SLIDESHOW !!!
	Move.l	ClavierPtr,A0
	Tst.b	HotKey_MenuQuit(A0)		
	Beq.s	.NoQuit
	Moveq	#2,D2	Simulation choix menu EXIT
	Bra	MenuChoose		
.NoQuit	Tst.b	HotKey_MenuSlideShow(A0)	Espace en principe
	Bne.s	.StartS
	Move.l	AutoCounter,D3
	Cmp.l	#TimeSlideBegin,D3
	Blt.s	.NoSlide
.StartS	Clr.l	AutoCounter
	Clr.w	Cycle_Activate
	Jsr	SLIDE1
	Bra	MAIN_MENU
.NoSlide	************************

	Bsr	TestInputs

	Tst.w	D4
	Bne	MenuChoose
	Tst.w	D1	
	Beq	.NoMvt		Rien
	Add.w	D2,D1
	Blt	.NoMvt
	Cmp.w	#2,D1
	Bgt	.NoMvt
	Clr.l	AutoCounter	Mouvement: Slide repoussé
	Bsr	BobOffMain
	Move.w	D1,D2
	Move.w	D2,D3
	Mulu.w	#18*SizeLine,D3
	Add.l	#15+SizeLine*87,D3		Offset
	Bsr	BobONMain			
	WaitHard	#4

.WaitR	Bsr	TestInputs
	Tst.w	D4
	Bne.s	MenuChoose
	Tst.w	D1
	Bne.s	.WaitR	
.NoMvt
	Bra	Main_Loop
MenuChoose
	***************
	Move.l	D2,-(A7)		D2: N° de la ligne du menu choisie

	* Avant de commencer les opérations pour le MenuB,
	* on fait un rapide fading du MenuA

	*** Préparation palette cible
	Move.l	#PalSrc,A0	Palette
	Move.l	#128,D0		
	Clr.l	D1		"START"
	Cmp.w	#1,D2		Ecran noir pour START et QUIT
	Bne.s	.No		Couleur pour OPTIONS
	Move.l	MenuACol,D1
.No
	Bsr	PalClr	A0/D0/D1	

	*** Fading
	Move.l	#MenuAcol,A0
	Move.l	#PalSrc,A1
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#128,D0
			
	Move.l	(A7)+,D2

	***************

	Cmp.w	#2,D2		"EXIT"
	Beq	QUITMenu

	Move.l	D2,-(A7)
	Move.l	#MenuAFadeTime,D1
	Cmp.w	#0,D2
	Beq.s	.WithMus
	Bsr	FadeBetween_Run
	Bra.s	.All
.WithMus	Bsr	FadeBetweenMusic_Run	avec FADING MUSIQUE !!!
	
.All	Move.l	#PalSrc,A0
	Move.l	#128,D0
	Jsr	MakePaletteNew
	Move.l	(A7)+,D2

	Cmp.w	#1,D2		"OPTIONS"
	Beq	OPTIONS_MENU


	Bsr	BobOffMain
	Jsr	ClsAll
	************
	
	******************************
	Move.l	#-1,PALETTE_IN_PROGRESS
	Movea.l	ColPalJauge,A0
	Move.l	#128,D0
	Clr.l	D7
	Jsr	MakePaletteNew
	Clr.l	PALETTE_IN_PROGRESS
	******************************

	*Movea.l	FTinyTxt8,A0
	*Movea.l	FAachen13,A0
	Movea.l	FMob8,A0
	Lea	Opt_Loading,A1
	Movea.l	Planar,A2
	Move.w	#XTextSamples,D0
	Move.w	#YTextSamples,D1
	Moveq	#%11111,D2	31 : Blanc
	Moveq	#7,D7		5 plans
	Move.l	#SizePlan,VarSizePlan
	Move.l	#SizeLine,VarSizeLine
	Bsr	GPrint	
	RTS
	

**************   QUITTER LE JEU
*
* WARNING!!! Comme le MENU a été appelé avec un BSR, on ne peut pas
* simplement faire un branchement au label QUIT !
* De plus, MAIN_MENU a été appelé avec un BSR depuis MENU.
*	
QUITMenu
	Move.l	D2,-(A7)
	Move.l	#MenuAFadeTimeQUIT,D1
	***
	Bsr	FadeBetweenMusic_Run	avec FADING MUSIQUE !!!
	***
	Move.l	#PalSrc,A0
	Move.l	#128,D0
	Jsr	MakePaletteNew
	Move.l	(A7)+,D2
	
	Bsr	FreeMenuData

	Adda.w	#8,A7	"Pop"	
*	Move.w	#-1,WANT_TO_QUIT
	Jmp	QUIT

		
	
*****************************************************
*** 	  	MENU - OPTIONS		***
*****************************************************

OPTIONS_MENU
	Clr.w	Cycle_Activate
	*************************
	*** Affichage MENU(B) ***
	*************************
	* Dégradés *
	Move.w	#32,D0	Couleur départ
	Move.w	#63,D1	Couleur fin
	Move.w	DegradeMenuB,D2	Dégradé
	Lea	MenuBcol,A0
	Bsr	MakeDegrad
	Move.l	MenuBcol+36*4,MenuBCol
	* Palette *
	Lea	MenuBcol,A0
	Move.l	#128,D0
	* Image *
	*Lea	MenuB,A3
	Lea	PicturesDef+2*Pic_SIZEOF,A3
	Move.l	Pic_Ptr(A3),A3
	Move.l	A3,PicPtr
	Tst.l	A3
	Beq	MAIN_MENU
	Moveq	#7,D1
	Move.l	#(320/8)*256,D2
	* Chip *
	Movea.l	Planar,A2
	Move.l	#SizePlan,D3
	* DISPLAY *
	Bsr	DisplayPic2
	*************************

	Bsr	CLS1	On efface toutes les Zones de travail
	Bsr	CLS2
	Bsr	CLS3
	Bsr	CLS4
	Bsr	CLS5
	Bsr	CLS6
	Bsr	CLS7

	* Mettre les bonnes valeurs dans les différentes cases

	Bsr	AffArenaZone
	Bsr	AffArenaMode
	Bsr	AffModeJeu

	Bsr	AffModePlayer
	Bsr	AffControl
	Bsr	AffDefinition

	Moveq	#1,D2	Position X	INITS BOB
	Moveq	#1,D3	Position Y
	Bsr	BobOnOpt	Transformer (X,Y) en X',Y',N°BOB !!! :-(

	Movea.l	Planar,A2
	Bsr	DisplayPic2Go	GO!

	Movem.l	D0-D7/A0-A6,-(A7)

	****** Apparition *
	*- Préparation palette source
	*Move.l	#PalSrc,A0	Palette
	*Move.l	#128,D0		
	*Move.l	#0,D1	
	*Bsr	PalClr	A0/D0/D1	
	*- Fading affichage
	Move.l	#PalSrc,A0
	Move.l	#MenuBcol,A1
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#128,D0
	Move.l	#MenuBAppearTime,D1		
	*Bsr	FadeBetween
	Bsr	FadeBetween_Run

	Move.l	#MenuBcol,A0
	Move.l	#128,D0
	Jsr	MakePaletteNew
	Movem.l	(A7)+,D0-D7/A0-A6

	************* CYCLE Couleurs
	Clr.w	Cycle_Wait
	Move.w	#5,Cycle_Speed
	Move.w	#96,Cycle_FirstCoul
	Move.w	#96+15,Cycle_LastCoul
	Move.l	#MenuBCol,Cycle_PalAdr
	Move.w	#1,Cycle_Activate	
	*************


	*************************
NoFire2	WaitHard	#1	On attend le fire
	Bsr	TestInputs
	Tst.w	D4
	Bne.s	NoFire2


	***************	GESTION DE SURFACE DU MENU
Main_Loop2
	*Rtest
	*Bne.s	.no
	*Move.w	#$ff0,$dff180	
.no
	VblWait	#45

	Move.w	#-1,Cycle_Activate	

	Bsr	TestInputs
	Tst.w	D4	Priorité 1 : Fire=Choix effectué
	Bne	.Choose
	Clr.l	D7
.TestMvY	Tst.w	D1	
	Beq	.TestMvX		Rien
	Add.w	D3,D1		Position X(D3) + DX
	Blt	.TestMvX
	
	Cmp.w	#1,D1
	Bgt	.TestMvX

	* Quand on va en bas...
	Tst.w	D1
	Beq.s	.NoPbl1
	Moveq	#1,D2	Si Y=1, alors X=1
	Clr.w	D0
.NoPbl1	*
	Move.w	D1,D3
	Moveq	#-1,D7

.TestMvX	Tst.w	D0
	Beq	.WaitR
	Add.w	D2,D0
	Blt	.WaitR
	Cmp.w	#1,D0
	Bgt	.WaitR


	* Quand on va à gauche...
	Tst.w	D0
	Bgt.s	.NoPbl2
	Tst.w	D3
	Bgt.s	.WaitR
.NoPbl2	*
	Move.w	D0,D2
	Moveq	#-1,D7
	
.WaitR	Tst.w	D7
	Beq	.NoMvt
	Bsr	BobOffOpt
	Bsr	BobONOpt
	WaitHard	#1
.NoMvt	Bra	Main_Loop2
.Choose	* D2: X (0,1)
	* D3: Y (0,1)
	Movem.w	D2-D3,SauveOptMain	On sauve la position actuelle
	*Bsr	BobOffOpt		On efface le bob
	Add.w	D3,D3
	Add.w	D2,D3	0=(0,0) 1=(1,0) 2=(0,1) 3=(1,1)	
	
	Cmp.w	#3,D3		GO!
	Beq	MAIN_MENU_RETURN
	
	Bsr	BobOffOpt
	
	Cmp.w	#0,D3		ARENA
	Beq	ARENA_MENU
	
	Cmp.w	#1,D3		PLAYERS
	Beq	PLAYERS_MENU

	
ContinueMainOpt	
	Movem.w	SauveOptMain,D2-D3	
	Bsr	BobOnOpt
	Bra	NoFire2

MAIN_MENU_RETURN
	**** Avant de rejoindre le menu principal, on fait
	* disparaître le MenuB en fondu.
	*- Préparation palette cible
	Move.l	#PalSrc,A0	Palette
	Move.l	#128,D0		
	Move.l	MenuBCol,D1
	*Move.l	#FadeColourB,D1	pour couleur fixe $RRGGBB
	Bsr	PalClr	A0/D0/D1	
	*- Fading effacement
	Move.l	#MenuBcol,A0
	Move.l	#PalSrc,A1
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#128,D0
	Move.l	#MenuBFadeTime,D1		
	*Bsr	FadeBetween
	Bsr	FadeBetween_Run

	Move.l	#PalSrc,A0
	Move.l	#128,D0
	Jsr	MakePaletteNew

	Bra	MAIN_MENU
	
	************************	ARENA (Du menu OPTIONS)
	*
	*
ARENA_MENU
	Moveq	#0,D3		Position Y (0-2)
	Bsr	BobOnOptInA
NoFire3	WaitHard	#1	On attend le fire
	Bsr	TestInputs
	Tst.w	D4
	Bne.s	NoFire3
	Clr.w	OldDirX
Main_Loop3
	VblWait	#45

	Move.w	#1,Cycle_Activate	

	Bsr	TestInputs
	Cmp.w	OldDirX,D0
	Beq.s	.Equal
	Move.w	D0,OldDirX
	Bsr	InitKeyS
.Equal	Tst.w	D1
	Beq.s	.NoMvt
	Add.w	D3,D1	Mouvement Y
	Blt.s	.ChooseBack
	Cmp.w	#2,D1
	Bgt.s	.ChooseBack	NoMvt	
	Move.w	D1,D3
	Bsr	BobOffOpt
	Bsr	BobOnOptInA
	WaitHard	#4
.WaitR	Bsr	TestInputs
	Tst.w	D1
	Bne.s	.WaitR
	Bra	Main_Loop3
.NoMvt	* Pas de mouvement en Y: on s'occupe des choix en X et du feu
	Tst.w	D4	Priorité 1 : Fire=Choix effectué
	Bne	.ChooseFire
	Tst.w	D0
	Bne	.Choose		Gauche<->Droite

	Bra	Main_Loop3

.ChooseBack * On est allé en haut ou en bas et on est donc sorti de l'Arena

	Tst.w	D3
	Ble.s	.NoBas
	* Pour que le pointeur de retour soit sur le "GO"
	Lea	SauveOptMain,A0
	Move.w	#1,(A0)	X
	Move.w	#1,2(A0)	Y 
.NoBas	Bsr	BobOffOpt		On efface le bob
	Bra	ContinueMainOpt	Revenir dans le main menu options


.ChooseFire * On a clické sur une des 3 cases
	Cmp.w	#1,D3		C'est pas la case 1
	Bne	NoFire3
.Nop0	* Si on est ici, c'est qu'on veut activer/désactiver un level
	Move.l	MenuPtrOptA1,A0	ZONE
	Not.l	4(A0)
	Bsr	AffArenaZone
	Bra	NoFire3

.Choose	* On a bougé le joy à gauche<>droite

	* D3: Y (0,1)	
	*
	* Pour les 2 cases il faut faire défiler avec Gauche<->Droite,
	* et pour la 2ème case on peut appuyer sur feu pour 
	* activer/désactiver un level
	*
	Bsr	KeyHandle
	Bne	Main_Loop3
	
	Tst.w	D3
	Beq	.Case0			*** Case choix mode levels

	Cmp.w	#2,D3
	Beq	.Case2			*** Case mode de jeu

.Case1	************* 			*** Case choix du level
	*
	* Défilement des levels (avec les flèches gauche-droite)
	* 

	Move.l	MenuPtrOptA1,A0	ZONE
	Tst.l	A0
	Beq	Main_Loop3	
	Movea.l	A0,A2	
	Moveq	#100,D7		Nombre d'essais (minimum=1!)
.NewTry
*	Dbf	D7,.NewTryOk
*	Bra	Main_Loop3	Plus d'essais dispo!
*.NewTryOK
	Tst.w	D0
	Beq.s	.All
	Bgt.s	.Next

.Prev	**** Level précédent
	Suba.w	#8,A2
	Cmpa.l	#Levels,A2
	Bge.s	.OkPrev1
	Move.l	#Levels,A2	Erreur : pas de précedent	
	Bra	Main_Loop3
.OkPrev1	Tst.l	(A2)		Test level vide
	Bne.s	.Okay	Prev2
	Subq.w	#1,D7
	Bgt.s	.NewTry
	Bra	Main_Loop3	Pas le choix.. on arrête les essais

.Next	*** Prochain Level
	Adda.w	#8,A2
	Cmpa.l	#LevelsEnd,A2
	Blt.s	.OkNext1
	Move.l	#LevelsEnd-8,A2	Erreur: pas de suivant
	Bra	Main_Loop3
.OkNext1	Tst.l	(A2)		Test level vide
	Bne.s	.Okay	Next2
	Subq.w	#1,D7
	Bgt.s	.NewTry
	Bra	Main_Loop3
*.OkNext2	*Bra.s	.Okay
	* All
.Okay	Movea.l	A2,A0
.All	Move.l	A0,MenuPtrOptA1	ZONE
.AllFin	Bsr	AffArenaZone
	Bra	Main_Loop3


.Case2	***************	Case choix mode de jeu (tournoi/libre)
	*
	* D0: Direction en X (-1,1)
	* (D3=Y (0-2))
	*

	Move.l	MenuPtrOptA2,A0
	Tst.l	A0
	Beq	Main_Loop3
	Movea.l	A0,A2	
	Tst.w	D0
	Beq.s	.M2All
	Bgt.s	.M2Next
.M2Prev	* Choix précédent
	Suba.w	#4,A2
	Cmpa.l	#Opt_ModeJ1,A2
	Bge.s	.M2Okay
	* Erreur : pas de précedent	
	Bra	Main_Loop3
.M2Next	* Prochain choix
	Adda.w	#4,A2
	Tst.l	(A2)
	Bne.s	.M2Okay
	Bra	Main_Loop3
	* All
.M2Okay	Movea.l	A2,A0
.M2All	Move.l	A0,MenuPtrOptA2	MODE
	Bsr	AffModeJeu
	Bra	Main_Loop3



.Case0	************ Case choix du mode

	Move.l	MenuPtrOptA0,A0	MODE
	Tst.l	A0
	Beq	Main_Loop3
	Movea.l	A0,A2	
	Tst.w	D0
	Beq.s	.MAll
	Bgt.s	.MNext
.MPrev	* Choix précédent
	Suba.w	#4,A2
	Cmpa.l	#Opt_Arena1,A2
	Bge.s	.MOkay
	* Erreur : pas de précedent	
	Bra	Main_Loop3
.MNext	* Prochain choix
	Adda.w	#4,A2
	Tst.l	(A2)
	Bne.s	.MOkay
	Bra	Main_Loop3
	* All
.MOkay	Movea.l	A2,A0
.MAll	Move.l	A0,MenuPtrOptA0	MODE
	Bsr	AffArenaMode
	Bra	Main_Loop3







	************************	PLAYERS (Du menu OPTIONS)
	*
	*
PLAYERS_MENU
	Moveq	#0,D3		Position Y (0-2)
	Bsr	BobOnOptInP
NoFire4	WaitHard	#1	On attend le fire
	Bsr	TestInputs
	Tst.w	D4
	Bne.s	NoFire4
	Clr.w	OldDirX
Main_Loop4
	VblWait	#45

	Move.w	#1,Cycle_Activate	

	Bsr	TestInputs
	Cmp.w	OldDirX,D0
	Beq.s	.Equal
	Move.w	D0,OldDirX
	Bsr	InitKeyS
.Equal	Tst.w	D1
	Beq.s	.NoMvt
	Add.w	D3,D1	Mouvement Y
	Blt.s	.ChooseBack
	Cmp.w	#2,D1
	Bgt.s	.ChooseBack	NoMvt	
	Move.w	D1,D3
	Bsr	BobOffOpt
	Bsr	BobOnOptInP
	WaitHard	#4
.WaitR	Bsr	TestInputs
	Tst.w	D1
	Bne.s	.WaitR
	Bra	Main_Loop4
.NoMvt	* Pas de mouvement en Y: on s'occupe des choix en X et du feu
	Tst.w	D4	Priorité 1 : Fire=Choix effectué
	Bne	.ChooseFire
	Tst.w	D0
	Bne	.Choose		Gauche<->Droite

	Bra	Main_Loop4

.ChooseBack * On est allé en haut et on est donc sorti de l'Arena

	Tst.w	D3
	Ble.s	.NoBas2
	* Pour que le pointeur de retour soit sur le "GO"
	Lea	SauveOptMain,A0
	Move.w	#1,(A0)	X
	Move.w	#1,2(A0)	Y 
.NoBas2
	Bsr	BobOffOpt		On efface le bob
	Bra	ContinueMainOpt	Revenir dans le main menu options

	* D3:Y (0-2)

.ChooseFire

	Bra	Main_Loop4


.Choose
	Bsr	KeyHandle
	Bne	Main_Loop4

	Tst.w	D3
	Beq.s	.Case0
	Cmp.w	#1,D3
	Beq	.Case1
	Cmp.w	#2,D3
	Beq	.Case2
	Bra	Main_Loop4



.Case0	***************	Case choix mode de players (individual...)
	*
	* D0: Direction en X (-1,0,1)
	*
	Move.l	MenuPtrOptP0,A0
	Tst.l	A0
	Beq	Main_Loop4
	Movea.l	A0,A2	
	Tst.w	D0
	Beq.s	.M2All	Choix: -1=Avant 0=Affiche 1=Après
	Bgt.s	.M2Next
.M2Prev	* Choix précédent
	Suba.w	#4,A2
	Cmpa.l	#Opt_ModeP1,A2
	Bge.s	.M2Okay
	* Erreur : pas de précedent	
	Bra	Main_Loop4
.M2Next	* Prochain choix
	Adda.w	#4,A2
	Tst.l	(A2)
	Bne.s	.M2Okay
	Bra	Main_Loop4
	* All
.M2Okay	Movea.l	A2,A0
.M2All	Move.l	A0,MenuPtrOptP0	MODE
	Bsr	AffModePlayer
	Bra	Main_Loop4


.Case1	***************	Case choix controls
	*
	* D0: Direction en X (-1,0,1)
	*
	Move.l	MenuPtrOptP1,A0
	Tst.l	A0
	Beq	Main_Loop4
	Movea.l	A0,A2	
	Tst.w	D0
	Beq.s	.MAll
	Bgt.s	.MNext
.MPrev	* Choix précédent
	Suba.w	#4,A2
	Cmpa.l	#Opt_ModeC1,A2
	Bge.s	.MOkay
	* Erreur : pas de précedent	
	Bra	Main_Loop4
.MNext	* Prochain choix
	Adda.w	#4,A2
	Tst.l	(A2)
	Bne.s	.MOkay
	Bra	Main_Loop4
	* All
.MOkay	Movea.l	A2,A0
.MAll	Move.l	A0,MenuPtrOptP1	MODE
	Bsr	AffControl
	Bra	Main_Loop4

.Case2	***************	Case définition des contrôles 
	*
	* D0: Direction en X (-1,0,1)
	*
	Move.l	MenuPtrOptP2,A0
	Tst.l	A0
	Beq	Main_Loop4
	Movea.l	A0,A2	
	Tst.w	D0
	Beq.s	.All
	Bgt.s	.Next
.Prev	* Choix précédent
	Suba.w	#4,A2
	Cmpa.l	#Opt_ModeD1,A2
	Bge.s	.Okay
	* Erreur : pas de précedent	
	Bra	Main_Loop4
.Next	* Prochain choix
	Adda.w	#4,A2
	Tst.l	(A2)
	Bne.s	.Okay
	Bra	Main_Loop4
	* All
.Okay	Movea.l	A2,A0
.All	Move.l	A0,MenuPtrOptP2	MODE
	Bsr	AffDefinition
	Bra	Main_Loop4






	***********		PrintNb(D3:Nombre)
	* Ne modifie pas : D0-D2/A0-A1/A3-A7
	* D3: Nombre
	* D6: Nombre de chiffres en sortie
	* D7: Remplissage (0:OFF)
STR	Lea	TravNb+12,A2
	Move.l	D3,D5
	Bge.s	.Pos1
	Neg.l	D3
.Pos1	Clr.b	-(A2)
.Convert	divsl.l	#10,D4:D3		* Début
	Add.w	#48,D4
	Move.b	D4,-(A2)				
	Subq.w	#1,D6
	Tst.l	D3
	Bne.s	.Convert		* Fin
	Tst.b	D7
	Beq.s	.EndF		
.Fill	Subq.w	#1,D6
	Blt.s	.EndF
	Move.b	D7,-(A2)		
	Bra.s	.Fill	
.EndF	Move.l	D5,D3	Pour le signe
	Bge.s	.Pos
	Move.b	#"-",-(A2)
.Pos	* A2: Adresse à afficher
	RTS
	***********







	*********************
	*** Affichage BOB ***
	*********************
BobONMain	
	Movem.l	D0-D3/D7,-(A7)
	Mulu.w	#SizeLine*(104-86),D2
	Add.w	#86*SizeLine+15,D2
	Move.w	D2,D3
	Moveq	#0,D4		N° Bob
	Movea.l	MainBox,A1
	Movea.l	Planar,A2
	Bsr	DisplayBob8
	Movem.l	(A7)+,D0-D3/D7
	RTS

	****  On a D2=Mvt X et D3=Mvt Y et on doit transformer ça 
	* en une position X, une position Y et un N° de BOB
BobONOpt
	*RTS
	Movem.l	D0-D4/D5/D7,-(A7)
	* D2=0,1
	* D3=0,1
	Move.w	D3,D5	Y*2
	Add.w	D5,D5
	Add.w	D2,D5	+X : Pour des datas
	Lsl.w	#3,D5	*8, on va pas lésiner pour 8 octets... ;-)
	Lea	(MenuOptDatOld,D5.w),A1
	*
	Movem.l	(A1)+,D3-D4	Offset,N°Bob	
	* D3: Offset sur l'écran
	* D4: N° Bob
	Movea.l	MainBox,A1
	Movea.l	Planar,A2
	Bsr	DisplayBob8
	Movem.l	(A7)+,D0-D4/D5/D7
	RTS

BobONOptInA
	Movem.l	D0-D4/D5/D7,-(A7)
	Mulu.w	#30,D3
	Add.w	#CaseA2Y,D3
	Mulu.w	#SizeLine,D3
	Add.w	#CaseA2X/8,D3	
	Moveq	#4,D4
	Movea.l	MainBox,A1
	Movea.l	Planar,A2
	Bsr	DisplayBob8
	Movem.l	(A7)+,D0-D4/D5/D7
	RTS

BobONOptInP
	Movem.l	D0-D4/D5/D7,-(A7)
	Mulu.w	#30,D3
	Add.w	#CaseP1Y,D3
	Mulu.w	#SizeLine,D3
	Add.w	#CaseP1X/8,D3	
	Moveq	#4,D4
	Movea.l	MainBox,A1
	Movea.l	Planar,A2
	Bsr	DisplayBob8
	Movem.l	(A7)+,D0-D4/D5/D7
	RTS

	***************
	*** Del BOB ***
	***************
BobOffMain
	Bsr	DelBob8
	RTS	

BobOffOpt
	Bsr	DelBob8
	RTS	


***************** Pour les menus : Tester tous les joysticks, etc...
*		(sauf la souris) et le feu.
*
*
TestInputs
	Clr.w	TotFeu	Feu=0: On appuye pas
	Clr.w	TotMvX
	Clr.w	TotMvY
	Movem.l	A0-A2/D2-D3,-(A7)

	Lea	JoyList2,A0
.Loop	Move.l	(A0)+,A2
	Tst.l	A2
	Beq.s	.FinLoop
	Moveq	#1,D4
	Jsr	(A2)	 D0: Mvt X    D1: Mvt Y    D4: Fire ($FF=Feu  $00=Rien)
	Add.w	D0,TotMvX
	Add.w	D1,TotMvY
	Or.w	D4,TotFeu
	Bra.s	.Loop
.FinLoop
	Movem.l	(A7)+,A0-A2/D2-D3
	Movem.w	TotMvX,D0-D1/D4	X,Y,Feu

	* Pour avoir -1,0,1 au max pour chaque direction

	Tst.w	D0	
	Beq	.NoMvX		Rien
	Bgt.s	.PlusX
	Moveq	#-1,D0		Haut
	Bra.s	.PlMoX
.PlusX	Moveq	#1,D0		Bas
.PlMoX
.NoMvX
	Tst.w	D1	
	Beq	.NoMvY		Rien
	Bgt.s	.PlusY
	Moveq	#-1,D1		Haut
	Bra.s	.PlMoY
.PlusY	Moveq	#1,D1		Bas
.PlMoY
.NoMvY
	RTS

**********************************




Cls1	Move.w	#CaseA1X,D0		ARENA-N° ZONE
	Move.w	#CaseA1Y,D1
	Move.w	#CaseA1X+CaseA1L-1,D2
	Move.w	#CaseA1Y+CaseA1H-1,D3
	Move.w	#17,D6	Noir=17
	Moveq	#7,D7
	Movea.l	Planar,A2
	Bsr	BAR
	RTS

Cls2	Move.w	#CaseA2X+1+1,D0		ARENA-CASE N°1  MODE
	Move.w	#CaseA2Y+1+1,D1
	Move.w	#CaseA2X+CaseA2L-2-1,D2
	Move.w	#CaseA2Y+CaseA2H-2-1,D3
	Move.w	#23,D6	Bleu case=12
	Moveq	#7,D7
	Movea.l	Planar,A2
	Bsr	BAR
	RTS

Cls3	Move.w	#CaseA3X+1+1,D0		ARENA-CASE N°2  ZONE
	Move.w	#CaseA3Y+1+1,D1
	Move.w	#CaseA3X+CaseA3L-2-1,D2
	Move.w	#CaseA3Y+CaseA3H-2-1,D3
	Move.w	#23,D6
	Moveq	#7,D7
	Movea.l	Planar,A2
	Bsr	BAR
	RTS

Cls4	Move.w	#CaseA4X+1+1,D0		ARENA-CASE N°3  MODE'
	Move.w	#CaseA4Y+1+1,D1
	Move.w	#CaseA4X+CaseA4L-2-1,D2
	Move.w	#CaseA4Y+CaseA4H-2-1,D3
	Move.w	#23,D6
	Moveq	#7,D7
	Movea.l	Planar,A2
	Bsr	BAR
	RTS


Cls5	Move.w	#CaseP1X+1+1,D0		PLAYERS-CASE N°1
	Move.w	#CaseP1Y+1+1,D1
	Move.w	#CaseP1X+CaseP1L-2-1,D2
	Move.w	#CaseP1Y+CaseP1H-2-1,D3
	Move.w	#23,D6
	Moveq	#7,D7
	Movea.l	Planar,A2
	Bsr	BAR
	RTS

Cls6	Move.w	#CaseP2X+1+1,D0		PLAYERS-CASE N°2
	Move.w	#CaseP2Y+1+1,D1
	Move.w	#CaseP2X+CaseP2L-2-1,D2
	Move.w	#CaseP2Y+CaseP2H-2-1,D3	
	Move.w	#23,D6
	Moveq	#7,D7
	Movea.l	Planar,A2
	Bsr	BAR
	RTS

Cls7	Move.w	#CaseP3X+1+1,D0		PLAYERS-CASE N°3
	Move.w	#CaseP3Y+1+1,D1
	Move.w	#CaseP3X+CaseP3L-2-1,D2
	Move.w	#CaseP3Y+CaseP3H-2-1,D3	
	Move.w	#23,D6
	Moveq	#7,D7
	Movea.l	Planar,A2
	Bsr	BAR
	RTS


InitKeyS
	Move.w	#KeySpeed,VarKeySpeed
	Move.w	#0,VarKeyRepeat
	RTS


********************************* AFFICHAGES ************************

	******
AffDefinition
	Move.l	MenuPtrOptP2,A0
	Move.l	(A0),A1
	Tst.l	A1
	Beq	.Fin
	Movem.l	D0-D3/A0-A1,-(A7)
	Move.l	A1,-(A7)
	VblWait	#35
	BSR	CLS7
	Move.l	(A7)+,A1
	*** PRINT du mode de jeu	
	Movea.l	FTinyTxt8,A0
	Movea.l	Planar,A2
	Move.w	#CaseP3X+3,D0
	Move.w	#CaseP3Y+3,D1
	Moveq	#%11111,D2	31 : Blanc
	Moveq	#7,D7		5 plans
	Move.l	#SizePlanMenu,VarSizePlan
	Move.l	#SizeLine,VarSizeLine
	Bsr	GPrint	
	*
	Movem.l	(A7)+,D0-D3/A0-A1
.Fin	RTS


	******
AffControl
	Move.l	MenuPtrOptP1,A0
	Move.l	(A0),A1
	Tst.l	A1
	Beq	.Fin
	Movem.l	D0-D3/A0-A1,-(A7)
	Move.l	A1,-(A7)
	VblWait	#35
	BSR	CLS6
	Move.l	(A7)+,A1
	*** PRINT du mode de jeu	
	Movea.l	FTinyTxt8,A0
	Movea.l	Planar,A2
	Move.w	#CaseP2X+3,D0
	Move.w	#CaseP2Y+3,D1
	Moveq	#%11111,D2	31 : Blanc
	Moveq	#7,D7		5 plans
	Move.l	#SizePlanMenu,VarSizePlan
	Move.l	#SizeLine,VarSizeLine
	Bsr	GPrint	
	*
	Movem.l	(A7)+,D0-D3/A0-A1
.Fin	RTS


	******
AffModePlayer
	Move.l	MenuPtrOptP0,A0
	Move.l	(A0),A1
	Tst.l	A1
	Beq	.Fin
	Movem.l	D0-D3/A0-A1,-(A7)
	Move.l	A1,-(A7)
	VblWait	#35
	BSR	CLS5
	Move.l	(A7)+,A1
	*** PRINT du mode de jeu	
	Movea.l	FTinyTxt8,A0
	Movea.l	Planar,A2
	Move.w	#CaseP1X+3,D0
	Move.w	#CaseP1Y+3,D1
	Moveq	#%11111,D2	31 : Blanc
	Moveq	#7,D7		5 plans
	Move.l	#SizePlanMenu,VarSizePlan
	Move.l	#SizeLine,VarSizeLine
	Bsr	GPrint	
	*
	Movem.l	(A7)+,D0-D3/A0-A1
.Fin	RTS


	******
AffModeJeu
	Move.l	MenuPtrOptA2,A0
	Move.l	(A0),A1
	Tst.l	A1
	Beq	.Fin
	Movem.l	D0-D3/A0-A1,-(A7)
	Move.l	A1,-(A7)
	VblWait	#35
	BSR	CLS4
	Move.l	(A7)+,A1
	*** PRINT du mode de jeu	
	Movea.l	FTinyTxt8,A0
	Movea.l	Planar,A2
	Move.w	#CaseA4X+3,D0
	Move.w	#CaseA4Y+3,D1
	Moveq	#%11111,D2	31 : Blanc
	Moveq	#7,D7		5 plans
	Move.l	#SizePlanMenu,VarSizePlan
	Move.l	#SizeLine,VarSizeLine
	Bsr	GPrint	
	*
	Movem.l	(A7)+,D0-D3/A0-A1
.Fin	RTS


	******
AffArenaMode
	Move.l	MenuPtrOptA0,A0
	Move.l	(A0),A1		Adresse level
	Tst.l	A1	Au casou... Préfére assurer !...
	Beq	.Fin
	Movem.l	D0-D3/A0-A1,-(A7)
	Move.l	A1,-(A7)
	VblWait	#35
	BSR	CLS2
	Move.l	(A7)+,A1
	*** PRINT du mode de jeu	
	Movea.l	FTinyTxt8,A0
	Movea.l	Planar,A2
	Move.w	#CaseA2X+3,D0
	Move.w	#CaseA2Y+3,D1
	Moveq	#%11111,D2	31 : Blanc
	Moveq	#7,D7		5 plans
	Move.l	#SizePlanMenu,VarSizePlan
	Move.l	#SizeLine,VarSizeLine
	Bsr	GPrint	
	*
	Movem.l	(A7)+,D0-D3/A0-A1
.Fin	RTS


	************

AffArenaZone
	Move.l	MenuPtrOptA1,A0
	Move.l	(A0),A0		Adresse level
	Cmpa.l	#0,A0
	Bne.s	.Ok
	Movea.l	#Level_Empty,A1	
	Bra.s	.OkF	
.Ok	Move.l	(A0),A1		Offset nom du level
	Tst.l	A1	Au casou... Préfére assurer !...
	Beq	.Fin
	Adda.l	A0,A1
.OkF	Tst.l	A1	Au casou... Préfére assurer !...
	Beq	.Fin
	Movem.l	D0-D3/A0-A1,-(A7)
	Move.l	A1,-(A7)
	VblWait	#35
	BSR	CLS1
	BSR	CLS3
	Move.l	(A7)+,A1

	*** PRINT du nom de la zone	
	
	* La couleur du print dépend de l'état du Level !
	Move.l	MenuPtrOptA1,A0
	Tst.w	4(A0)	
	Beq.s	.Blanc
	Moveq	#26,D2		17 : Noir
	Bra.s	.Couls	
.Blanc	Moveq	#%11111,D2	31 : Blanc
.Couls	Movea.l	FTinyTxt8,A0
	Movea.l	Planar,A2
	Move.w	#CaseA3X+3,D0
	Move.w	#CaseA3Y+3,D1
	Moveq	#7,D7		5 plans
	Move.l	#SizePlanMenu,VarSizePlan
	Move.l	#SizeLine,VarSizeLine
	Bsr	GPrint		A1: Phrase
	*** PRINT du N° Du Level   Normalement de "1-01" à "5-20"	
	Move.l	MenuPtrOptA1,A0
	Suba.l	#Levels,A0
	Move.l	A0,D0
	Lsr.w	#3,D0
	*Addq.w	#1,D0	D0: N° Level
	* On découpe le N° en World+Level
	Ext.l	D0
	Divs.w	#NbLevelsParWorld,D0	
	Lea	StrWork,A3
	*****
	Clr.l	D3
	Move.w	D0,D3	
	Addq.w	#1,D3
	Moveq	#1,D6	1 chiffre
	Move.b	#'0',D7
	Bsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
.Cop1	Move.b	(A2)+,D2
	Beq.s	.EndC1
	Move.b	D2,(A3)+
	Bra.s	.Cop1
.EndC1	Move.b	#'-',(A3)+
	*****
	Swap	D0
	Addq.w	#1,D0
	Clr.l	D3
	Move.w	D0,D3	
	Moveq	#2,D6	2 chiffres
	Move.b	#'0',D7
	Bsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
.Cop2	Move.b	(A2)+,D2
	Beq.s	.EndC2
	Move.b	D2,(A3)+
	Bra.s	.Cop2
.EndC2	Clr.b	(A3)+
	*****
	Lea	StrWork,A1	Adresse string
	Movea.l	FTinyTxt8,A0
	Movea.l	Planar,A2
	Move.w	#CaseA1X+2,D0
	Move.w	#CaseA1Y+1,D1
	Moveq	#%11111,D2	31 : Blanc
	Moveq	#7,D7		5 plans
	Move.l	#SizePlanMenu,VarSizePlan
	Move.l	#SizeLine,VarSizeLine
	Bsr	GPrint	
	*
	Movem.l	(A7)+,D0-D3/A0-A1
	*
.Fin	RTS



	******************	GESTION DU KEY SPEED
KeyHandle	Move.w	VarKeySpeed,D5
	Blt.s	.Repeat
	Subq.w	#1,VarKeySpeed
	Cmp.w	#KeySpeed,D5
	Beq.s	.Autorisation
	Bra.s	.NoAutorisation
.Repeat	Move.w	VarKeyRepeat,D5
	Dbf	D5,.Ouait		
	Move.w	#KeyRepeat,VarKeyRepeat
	Bra.s	.Autorisation	
.Ouait	Move.w	D5,VarKeyRepeat
.NoAutorisation
	Tst.b	#1
	RTS
.Autorisation	
	Tst.b	#0
	RTS
	******************


FreeMenuData
	Clr.w	Cycle_Activate
	IFNE 	Music_Activation
	 Moveq	#0,D0	N° de la musique dans la liste (0=No Zik)
	 Bsr	LaunchZik
	ENDC	

	Bsr	FreeAllPics

	Move.w	MusicVolBack,MusicVol

	RTS

***********************	Vérifier la cohérence des pointeurs menu
*
*
*
Verif_Pointeurs_Menu
	**** Vérif pointeur level actuel
	Move.l	MenuPtrOptA1,A2	Level Actuel
	Cmpa.l	#Levels,A2
	Bge.s	.OkMi
	Move.l	#Levels,A2
	Bra.s	.OkMa
.OkMi	Cmpa.l	#LevelsEnd-8,A2
	Ble.s	.OkMa
	Move.l	#LevelsEnd-8,A2
.OkMa	Move.l	A2,D1
	Sub.l	#Levels,D1	Adresse relative divisible par 8
	And.b	#%11111000,D1	<- BUG avant: Obligeait des adresses Alignées sur 4 octets !!! :-) DSS OBLIGATOIREMENT SUR EVEN !
	Add.l	#Levels,D1	Adresse absolue
	Move.l	D1,A2
	Move.l	A2,MenuPtrOptA1
	RTS









**********************************	Phrases des MENUS

*	Section 	MenuDat,data

	even
Opt_Arena1 *	MODE
	Dc.l	Opt_A0
	Dc.l	Opt_A1
	Dc.l	Opt_A2
	Dc.l	Opt_A3
	Dc.l	0
Opt_A0	Dc.b	'Random',0
Opt_A1	Dc.b	'Sequential',0
Opt_A2	Dc.b	'One level',0
Opt_A3	Dc.b	'Dynablaster',0

	even
Opt_ModeJ1 *	MODE DE JEU
	Dc.l	Opt_J0
	Dc.l	Opt_J1
	Dc.l	0	
Opt_J0	Dc.b	'Free play',0
Opt_J1	Dc.b	'5 Win Match',0
Opt_J2	Dc.b	'',0

	even
Opt_ModeP1 * 	MODE DE PLAYER : TEAMS/INDIVIDUAL
	Dc.l	Opt_P0
	Dc.l	Opt_P1
	Dc.l	Opt_P2
	Dc.l	0	
Opt_P0	Dc.b	'Individual',0
Opt_P1	Dc.b	'Two Teams',0
Opt_P2	Dc.b	'Survivor',0

	even
Opt_ModeC1 * 	CONTROLS
	Dc.l	Opt_C0
	Dc.l	Opt_C1
	Dc.l	Opt_C2
	Dc.l	Opt_C3
	Dc.l	Opt_C4
	Dc.l	Opt_C5
	Dc.l	Opt_C6
	Dc.l	0
Opt_C0	Dc.b	'Joystick 0',0	
Opt_C1	Dc.b	'Joystick 1',0	
Opt_C2	Dc.b	'Joy Doubler 3',0	
Opt_C3	Dc.b	'Joy Doubler 4',0	
Opt_C4	Dc.b	'Keyboard A-1/1',0	
Opt_C5	Dc.b	'Keyboard B-1/2',0	
Opt_C6	Dc.b	'Keyboard B-2/2',0	
Opt_C7	Dc.b	'Keyboard C-1/3',0	
Opt_C8	Dc.b	'Keyboard C-2/3',0	
Opt_C9	Dc.b	'Keyboard C-3/3',0	

	even
Opt_ModeD1 *	DEFINITION DES CONTROLES
	Dc.l	Opt_D1
	Dc.l	Opt_D2
	Dc.l	Opt_D3
	Dc.l	0
Opt_D1	Dc.b	'Flèches RAlt',0
Opt_D2	Dc.b	']879 Flèche droite',0
Opt_D3	Dc.b	'"EZR Espace',0

	even
*Opt_Music1 * 	MODE
*	Dc.l	Opt_Mo0
*	Dc.l	Opt_Mo1
*	Dc.l	Opt_Mo2
*	Dc.l	0
*Opt_Mo0	Dc.b	'Random',0
*Opt_Mo1	Dc.b	'Sequential',0
*Opt_Mo2	Dc.b	'No Music',0

	even
*Opt_Music2 * 	SWAP
*	Dc.l	Opt_S0
*	Dc.l	Opt_S1
*	Dc.l	Opt_S2
*	Dc.l	0
*Opt_S0	Dc.b	'Every 10 mn',0
*Opt_S1	Dc.b	'Every Level',0
*Opt_S2	Dc.b	'Never',0

	even

MenuMainDat
	Dc.w	120,86,202,100
	Dc.w	120,104,202,118
	Dc.w	120,122,202,136

MenuOptDatOld	* Pour la version avec les BOBS
	Dc.l	3001,1	0,0 Pour un (X,Y), j'ai un (Offset,N°Bob)	
	Dc.l	3021,1	1,0
	Dc.l	6641,1	0,1	<--- à virer
	Dc.l	8708,3	1,1

*MenuOptDat	* Pour la version avec les BOX
*	Dc.w	15,76,45,106	0,0
*	Dc.w	175,76,205,106	1,0
*	Dc.w	0,0,5,5		0,1
*	Dc.w	232,218,282,243	1,1

		
*Opt_Game	Dc.l	Opt_G0
*	Dc.l	Opt_G1
*	Dc.l	Opt_G2
*	Dc.l	0
*Opt_G0	Dc.b	'Individual',0
*Opt_G1	Dc.b	'Teams',0

SauveOptMain Ds.w	2

MENUSPTR
MenuPtrOptA0 Dc.l	0,Opt_Arena1	Mode
MenuPtrOptA1 Dc.l	0,Levels		Zone	
MenuPtrOptA2 Dc.l	0,Opt_ModeJ1	Mode de jeu
MenuPtrOptP0 Dc.l	0,Opt_ModeP1	Mode players
MenuPtrOptP1 Dc.l	0,Opt_ModeC1	Controls
MenuPtrOptP2 Dc.l	0,Opt_ModeD1	Definition
	Dc.l	0,0

VarKeySpeed	Dc.w	0
VarKeyRepeat	Dc.w	0
OldDirY		Dc.w	0
OldDirX		Dc.w	0
TravNb		Ds.b	20

*PicturePtr Ds.l	MaxPictures

PicturesDef
	Dc.l	0,0,Pic0N
	Dc.l	0,0,Pic1N
	Dc.l	0,0,Pic2N
	Dc.l	0,0,Pic3N
	Dc.l	0,0,Pic4N
	Dc.l	0,0,Pic5N
	Dc.l	0,0,Pic6N
	Dc.l	0,0,Pic7N
	Dc.l	0,0,Pic8N
	Dc.l	0,0,Pic9N


	*Dc.l	0,0,Pic0N,PalProxi
	*Dc.l	0,0,Pic1N,MenuACol
	*Dc.l	0,0,Pic2N,MenuBCol
	*Dc.l	0,0,Pic3N,PodiumCol
	*Dc.l	0,0,Pic4N,MenuCreditsCol
	*Dc.l	0,0,Pic5N,MenuBonusCol
	*Dc.l	0,0,Pic6N,0
	*Dc.l	0,0,Pic7N,0
	*Dc.l	0,0,Pic8N,0
	*Dc.l	0,0,Pic9N,0

PaletteDef
	Dc.l	PalProxi
	Dc.l	MenuACol
	Dc.l	MenuBCol
	Dc.l	PodiumCol
	Dc.l	MenuCreditsCol
	Dc.l	MenuBonusCol
	Dc.l	TestCol
	Dc.l	0
	Dc.l	0
	Dc.l	TestCol	

Level_Empty Dc.b	'<Free>',0

Pic0N	Dc.b	'binary/Proxima.crp',0	#0 CRunched Picture
Pic1N	Dc.b	'binary/MenuA.raw',0	image #1	
Pic2N	Dc.b	'binary/MenuB.raw',0	
Pic3N	Dc.b	'binary/Podium.raw',0
Pic4N	Dc.b	'binary/Menu_Credits.raw',0
Pic5N	Dc.b	'binary/Menu_Bonus2.raw',0	Scrolling
Pic6N	Dc.b	'binary/Test.raw',0	
Pic7N	Dc.b	'',0	
Pic8N	Dc.b	'',0	
Pic9N	Dc.b	'binary/Test.raw',0	

Opt_Loading Dc.b	'Loading datas...',0

	even
*
* Picture  0: Proxima
* Picture  1: MenuA
* Picture  2: MenuB
* Picture  3: Podium
* Picture  4: Credits 
* Picture  5: Bonus
* Picture  6: 
* Picture  7: 
* Picture  8: 
* Picture  9: 
*
*
*
*	*** UN PRINT !!! ********	
*	Movea.l	FTinyTxt8,A0
*	Lea	Opt_Ph1,A1
*	Movea.l	Planar,A2
*	Move.w	#50,D0
*	Move.w	#50,D1
*	Moveq	#%11111,D2	31 : Blanc
*	Moveq	#5,D7		5 plans
*	Move.l	#SizePlanMenu,VarSizePlan
*	Move.l	#SizeLine,VarSizeLine
*	Bsr	GPrint	
*	*************************
*
*

