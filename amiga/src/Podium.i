*
*
* Sons utilisés: 8,17,18: on peut virer les autres.
*
* WinGuy: le N° du joueur qui a gagné (0-5)
* Si mode équipes: tester le Bit #0 du joueur !
*	
PodiumAppearTime	=	100
PodiumFadingTime	=	20
PodiumToGREYTime	=	100

AFF_PODIUM
	Clr.w	GamesSincePodium
	Bsr	END_GAME_INITS	Pour barres joueurs et bois etc...

	Move.w	#-1,KeyStateESC	Esc appuyé

	*Clr.w	ExeSprite
	*Clr.l	BarreDecounter	Pour retour plus facile...
	*Jsr	Set3
	
	****** On vire tous les sons inutiles ! on garde 8,17,18
	*Move.l	#SamplesPodium,SamplesToKeep
	*Bsr	FreeSamples

	****** Podium!	Si on n'a pas eu assez de mémoire pour
	Moveq	#3,D0	le charger avant...
	Bsr	ChargePic

	* WINNERSPH : RequestForNewLevel

	Move.w	#64,SoundVol	Valeurs temporaires au maxi
	IFNE	Music_Activation
	Move.w	#64,P61_Master
	ENDC

	* On a terminé : Fading au noir
	Clr.w	ExeSprite
	Clr.w	ExeFlash
	Move.w	#-1,GameOver

	Jsr	MakeMenuCopList

	Movem.l	D0-D7/A0-A6,-(A7)
	*- Préparation palette source
	Move.l	#PalSrc,A0	Palette
	Move.l	#128,D0		
	Move.l	#0,D1	
	Bsr	PalClr	A0/D0/D1	
	Move.l	#PalSrc,A0
	Move.l	#128,D0
	Jsr	MakePaletteNew
	Movem.l	(A7)+,D0-D7/A0-A6

	************************
	*** Affichage PODIUM ***
	************************
	* Palette *
	Lea	PODIUMcol,A0
	Move.w	#128,D0
	* Image *
	Lea	PicturesDef+3*Pic_SIZEOF,A3
	Move.l	Pic_Ptr(A3),A3
	Tst.l	A3
	Beq	.ErrQui
	Moveq	#7,D1
	Move.l	#(320/8)*256,D2
	* Chip *
	Movea.l	Planar,A2
	Move.l	#SizePlan,D3
	* DISPLAY *
	Bsr	DisplayPic2
	Movea.l	Planar,A2
	Bsr	DisplayPic2Go
	************************

	***********************	STOP MUSIC
	Moveq	#0,D0	Arrêt de la musique: toutes voies libres
	IFNE	Music_Activation
	Jsr	LaunchZik	
	ENDC
	***********************

	***********************	BRUIT win 1: Foule
	Movem.l	A0-A1/D1/D3-D5,-(A7)
	Moveq	#17,D3
	Moveq	#PriSonWinT1,D1
	Move.w	#2,SampleLoops	3 fois le sample ! ;-)
	Bsr	PlaySon
	Movem.l	(A7)+,A0-A1/D1/D3-D5
	***********************	BRUIT win normal: applause
	Movem.l	A0-A1/D1/D3-D5,-(A7)
	Moveq	#8,D3
	Moveq	#PriSonWin,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,A0-A1/D1/D3-D5


	***********************	CREATION ANIMATIONS
	Bsr	InitAnimPodium

	*************************
	Movem.l	D0-D7/A0-A6,-(A7)
	*- Fading affichage
	Move.l	#PalSrc,A0
	Move.l	#PodiumCol,A1
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#128,D0	
	Move.l	#PodiumAppearTime,D1		temps Apparition		
	Move.w	#0,FadeBtw_BreakEnable
	Bsr	FadeBtw_Init
	Move.w	#-1,FadeBtw_Activate

	Movem.l	(A7)+,D0-D7/A0-A6
	
	Tst.w	KeyStateESC	-1:Appuyé  0:Relâché  1:Break
	Bgt	.Qui

	Clr.w	Ask_To_Stop
	
.AttLa	***
	VblWait	#250
	Bsr	AnimPodium
	***
	Move.l	ClavierPtr,A0
	Tst.b	69(A0)
	Bne	.Qui	
	Bsr	TestInputs
	Tst.w	D4
	Bne.s	.AttLa		Feu(x) enclenché(s)

.NOP	***
	VblWait	#250
	Bsr	AnimPodium
	***
	Moveq	#3-1,D7
.WAITSVB	Move.l	ClavierPtr,A0
	Tst.b	69(A0)
	Bne	.Qui	
	WaitHard	#1
	Tst.w	Ask_To_Stop
	Bgt	.OKSUITE
	Blt.s	.DbL
	Bsr	TestInputs	Retours: D0-D1/D4
	Tst.w	D4
	Bne.s	.ATS		Aucun feu enclenché
.DbL	Dbf	D7,.WAITSVB
	Bra	.NOP
	***
.ATS	Tst.w	Ask_To_Stop
	Bne.s	.WAITSVB
	Move.l	D7,-(A7)
	Move.w	#-1,Ask_To_Stop
	********* Faire le cadre blanc style photographie
	Move.l	#SizePlan,VarSizePlan
	Move.l	#SizeLine,VarSizeLine
	Moveq	#0,D0
	Moveq	#0,D1
	Move.w	#319,D2
	Move.w	#255,D3
	Moveq	#6,D4	Pixels de tour
	Move.w	#103,D6	Couleur 
	Move.w	#7,D7	Nb de plans
	Movea.l	Planar,A2
	Jsr	BAR_OUTLINE	(D0,D1)-(D2,D3),D6
	*********	
	Bsr	LaunchGRIS
	Move.l	(A7)+,D7
	Bra	.DbL

.QUI	Tst.w	Ask_To_Stop
	Bne.s	.NoWH
	Bsr	LaunchGRIS
	Bra.s	.NoWH
.OKSUITE	***********************       TEMPORISATION
	WaitHard	#PodiumToGREYTime/2

.NoWH	***********************	AFFICHAGE DES STATISTIQUES
	Bsr	Statistiques
	
	***********************	ATTENTE UTILISATEUR
.AttLa2	Move.l	ClavierPtr,A0
	Tst.b	69(A0)
	Bne	.Qui2	
	Bsr	TestInputs
	Tst.w	D4
	Bne.s	.AttLa2		Feu(x) enclenché(s)
.Nop2	Move.l	ClavierPtr,A0
	Tst.b	69(A0)
	Bne	.Qui2	
	Bsr	TestInputs
	Tst.w	D4
	Beq.s	.Nop2		Aucun feu enclenché
.Qui2

	*********************** SORTIE DU PODIUM
	
	Tst.w	FadeBtw_Activate
	Beq.s	.OkPalG
	Clr.w	FadeBtw_Activate	Le le fading n'était pas terminé
	Movea.l	#PalAct,A0	Source
	Movea.l	#PalWork,A1	Cible
	Move.l	#128,D0
	Bsr	ConvPal
	
.OkpalG	*- Préparation palette cible
	Move.l	#PalSrc,A0	Palette
	Move.l	#128,D0		
	Move.l	#0,D1	
	Bsr	PalClr	A0/D0/D1	
	*- Fading affichage
	Move.l	#PalWork,A0	Palette grise
	Move.l	#PalSrc,A1
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#128,D0	
	Move.l	#PodiumFadingTime,D1		
	Move.w	#0,FadeBtw_BreakEnable
	Bsr	FadeBetween_Run

	Tst.w	KeyStateESC	-1:Appuyé  0:Relâché  1:Break
	Bgt	.Qui

	* Nouveau Level
	Bsr	ClsALL
	*** Palette SPRITES
	*Movea.l	ColPalette,A0
	Lea	Palette,A0
	Move.l	#64+32,D0
	Clr.l	D7
	Jsr	MakePaletteNew
	***
	Clr.w	ExeSprite
	Bsr	ClearSprites
	Move.w	#-1,RequestForNewLevel	Pas besoin ? sisi ...;-/
	Move.w	#-1,RequestBeginLevel
	Move.w	#-1,ExeFlash	Bizarre pas dans InitLevel..mais bon
	Jsr	RestoreCopList
	DMASet	Sprite
	Move.w	#1,LevelInfoState	pour pas restauration inits	
	RTS

.ErrQui
	Move.l	MessageWaitPtr,A0
	Move.l	#Phrase_ErrMem,(A0)+
	Clr.l	(A0)	<- si liste de messages... mais bon,
	*		il manque les zones pour stocker...
	Bra	.Qui


********* Lancer les traitements à faire entre le podium et les stats
*
*
*	
LaunchGRIS
	Clr.w	FadeBtw_Activate	Au cas où il n'ait pas fini
	Move.l	#PodiumCol,A0
	Move.l	#128,D0
	Jsr	MakePaletteNew	BOURRIN, mais bon!


	***********************	BRUIT win 2: Photo
	Movem.l	A0-A1/D1/D3-D5,-(A7)
	Moveq	#18,D3
	Moveq	#PriSonWinT2,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,A0-A1/D1/D3-D5


	***********************	GENERATION PALETTE MONOCHROME
	Move.l	#PodiumCol,A0	Palette
	Move.l	#PalWork,A1	Cible
	Move.l	#128,D0		Couleurs totales
	Move.l	#128-32,D1	Couleurs à modifier
	Bsr	ComputePALGRIS
	
	***********************	FADING ECRAN -> GRIS
	Move.l	#PodiumCol,A0
	Move.l	#PalWork,A1
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#128,D0		Contenant les couleurs sprites	
	Move.l	#PodiumToGREYTime,D1		temps Apparition		
	Move.w	#0,FadeBtw_BreakEnable
	Bsr	FadeBtw_Init
	Move.w	#-1,FadeBtw_Activate
	RTS


******************** Changer la palette en gris
*
* A0: Palette source (non modifiée)
* A1: Palette cible
* D0: Nombre de couleurs de la palette source
* D1: Nombre de couleurs à modifier
*
ComputePALGRIS
	Move.l	A1,A2
	Bsr	CopZone		A0/A1/D0
	Move.l	A2,A0
	Move.l	D1,D0
	Subq.w	#1,D0
.Loop	Clr.l	D2	Blue
	Clr.l	D3	Green
	Clr.l	D4	Red
	Move.l	(A0),D1
	Move.b	D1,D2	
	Lsr.l	#8,D1
	Move.b	D1,D3	
	Lsr.l	#8,D1
	Move.b	D1,D4	
	Move.l	D2,D5
	Add.l	D3,D5
	Add.l	D4,D5	Somme
	Divu.l	#3,D5	Moyenne

	Move.l	D5,D4
	Bra.s	.NewRGB

	* Pour faire les carrés des écarts à la moyenne (compliqué et 
	* pas top car couleurs claires->foncées et inversement !)
	Move.l	D5,D7	
	Sub.l	D2,D7	C1=(Moy-Blue)^2 		
	*Muls.l	D7,D7
	Bgt.s	.NZ1
	Beq.s	.Z1
	Neg.l	D7
	Bra.s	.NZ1
.Z1	Moveq	#1,D7
.NZ1	Move.l	D5,D6
	Sub.l	D3,D6	C2=(Moy-Green)^2	
	*Muls.l	D6,D6
	Bgt.s	.NZ2
	Beq.s	.Z2
	Neg.l	D6
	Bra.s	.NZ2
.Z2	Moveq	#1,D6
.NZ2	Sub.l	D4,D5	C3=(Moy-Red)^2
	*Muls.l	D5,D5	
	Bgt.s	.NZ3
	Beq.s	.Z3
	Neg.l	D5
	Bra.s	.NZ3
.Z3	Moveq	#1,D5
.NZ3	Move.l	D7,D1	Somme des coefficients
	Add.l	D6,D1
	Add.l	D5,D1	Cof=C1+C2+C3
	Mulu.l	D7,D2	Blue*C1
	Mulu.l	D6,D3	Green*C2
	Mulu.l	D5,D4	Red*C3
	Add.l	D2,D4	
	Add.l	D3,D4	Blue*C1+Green*C2+Red*C3
	Divu.l	D1,D4	(Blue*C1+Green*C2+Red*C3)/(C1+C2+C3)	

.NewRGB
	Clr.l	D3	On met le résultat pour R,G,B
	Move.b	D4,D3	RED
	Lsl.l	#8,D3
	Move.b	D4,D3	GREEN
	Lsl.l	#8,D3
	Move.b	D4,D3	BLUE
	Move.l	D3,(A0)+
	Dbf	D0,.Loop
	RTS


*************************** PARTIE DU CHERCHEUR *******************
*						      *
* DEFENSE DE PENETRER ICI SOUS PEINE DE POURSUITE JUSQU'A LA MORT *
* 						      *
*******************************************************************
*
* Bon, alors comment que je vais faire pour animer les petits
* bonhommes sur le podium ? 
* 1/ C'est en boucle
* 2/ C'est plus de 1 vbl
* 3/ Il faudrait que ca ait un air de fête (confettis)
* 
* Solution 1: 4*6*18*6*8 = 20736
* - Capture fond
* - Affichage sprite
* - Restauration fond
*
* Solution 2: 
* - Copie fond bobs écran caché *8 en hauteur
* - Copie anims bobs sur les fonds cachés
* - Copie en boucle des anims cachées sur l'écran visible.
*
* Avec une alternative pour chaque cas: utilisation du screen 2 pour
* faire un double buffer. 
*
* Problèmes:
* Solution 1: Utilisation obligée double buffer, très chiant à gérer
* Solution 2: Impossible de mettre des confettis après...
*
* Bon, je prends la solution 2, on verra les problèmes en cours de route.
* Je la prends avec le double buffer pour éviter les problèmes de flashs
* et autoriser les confettis.
*
* Solution 3: 10*6*18*3*8 = 25920 octets
* - Copie du sol des 3 marches sur l'écran caché en 8 exemplaires (larg=80)
* - Calcul de la place par mec. DX=80/Nb -> Pos=DX*(0.5+NumJ)
* - Copie des mecs sur le podium correspondant à leur résultat
* - Animation par copie des 3 marches.
*
* Avantage de la solution 3 sur la solution 2:
* - Mecs superposables
* - Backup des marches facile
* - Même vitesse qu'il y ait 1 mec ou 1000 sur les marches
* Inconvénient:
* - Perte mémoire
*
* Pour la mémoire, au lieu de réserver:
* - en cours de route et s'attendre à une erreur de mémoire
* - au début du jeu et bouffer 25 Ko juste pour le podium
* Je peux utiliser la mémoire de la barre des joueurs, qui fait:
* 80*6*18=8640 ... hum! manque un peu...
*
* Utilisation de DIM4 pour travail: 4*4*64*64 = 64 Ko
*
* 
******
Zone1_X		=	144/8	PREMIERE MARCHE (Vainqueurs)
Zone1_Y		=	131
Zone1_L		=	64/8	=8 octets
Zone1_H		=	25
Zone1_SIZE	=	Zone1_L*Zone1_H	$C8=200 octets/plan
*
Zone2_X		=	24/8	DEUXIEME MARCHE (Moyens)
Zone2_Y		=	146
Zone2_L		=	96/8	=12 octets
Zone2_H		=	25
Zone2_SIZE	=	Zone2_L*Zone2_H	$12C=300 octets/plan
*
Zone3_X		=	208/8
Zone3_Y		=	161
Zone3_L		=	96/8	=12 octets
Zone3_H		=	25
Zone3_SIZE	=	Zone3_L*Zone3_H	$12C=300 octets/plan
*
Zone_TOTAL	=	(Zone1_SIZE+Zone2_SIZE+Zone3_SIZE)*7
*
******
* 
* Taille demandée au total pour: 
* - les trois zones: 5600 octets
* - les trois zones * les 7 vues = 39200 octets
*
* Z1,Z2,Z3   N° 1
* Z1,Z2,Z3   N° 2
* Z1,Z2,Z3   .
* Z1,Z2,Z3   N° 4
* Z1,Z2,Z3   .
* Z1,Z2,Z3   .
* Z1,Z2,Z3   N° 7
*
* et pour chaque Z, j'ai pl0,pl1,pl2,pl3,pl4,pl5,pl6
*
*
********************************************************************
*                PREPARER L'ANIMATION DU PODIUM                    *
********************************************************************
InitAnimPodium
	Move.l	#$00000001,Tri	ANTIBUG au cas où il n'y ait aucun
	Move.l	#$00020003,Tri+4	joueur, pour les Statistiques
	Move.l	#$00040005,Tri+8	qui sont toujours affichées
	*
	Movea.l	Dim4,A0		Valeurs d'origine à laquelle
	Move.l	A0,AdrZone1	il faudra ajouter 
	Adda.w	#Zone1_SIZE*7,A0	N*Zone_TOTAL
	Move.l	A0,AdrZone2
	Adda.w	#Zone2_SIZE*7,A0
	Move.l	A0,AdrZone3

	** On a déterminé les adresses des zones, on copie maintenant
	* les zones de l'écran source en 7 exemplaires dans ces zones.

	********************  COPIES DE LA ZONE 1
	Move.l	Planar,A0	
	Adda.l	#Zone1_Y*SizeLine+Zone1_X,A0		Source podium
	Movea.l	AdrZone1,A1			Cible zone
	Move.w	#Zone1_H,D0
	Move.w	#Zone1_L,D2
	Move.w	#Zone1_SIZE,D6
	Bsr	Copy7

	********************  COPIES DE LA ZONE 2
	Move.l	Planar,A0	
	Adda.l	#Zone2_Y*SizeLine+Zone2_X,A0		Source podium
	Movea.l	AdrZone2,A1			Cible zone
	Move.w	#Zone2_H,D0
	Move.w	#Zone2_L,D2
	Move.w	#Zone2_SIZE,D6
	Bsr	Copy7

	********************  COPIES DE LA ZONE 3
	Move.l	Planar,A0	
	Adda.l	#Zone3_Y*SizeLine+Zone3_X,A0		Source podium
	Movea.l	AdrZone3,A1			Cible zone
	Move.w	#Zone3_H,D0
	Move.w	#Zone3_L,D2
	Move.w	#Zone3_SIZE,D6
	Bsr	Copy7

**********************************
*
* Il ne faut pas oublier que si l'on est ici, c'est que quelqu'un à
* gagné, il faut donc gérer ça !
*
*
*
********
	Lea	FeelWork,A1
	Clr.w	NbPlayersFeel
	Clr.l	PasMarche1
	Clr.l	PasMarche2
	Clr.l	PasMarche3
	*
	Cmp.w	#1,PlayerMode
	Bne	.INDIV
*************************************************************
*		     TEAMS			*
*************************************************************
.TEAMS
	Move.l	#$00000002,Tri	Ordre d'apparition stats
	Move.l	#$00040001,Tri+4
	Move.l	#$00030005,Tri+8

	* Il faut d'abord compter le nombre de mecs par marche
	* avant de les assigner....

	Clr.l	D3	Equipe 0
	Clr.l	D4	Equipe 1
	Movea.l	LegoPtr,A0
	Clr.l	D2	
.LoopJMA	Tst.l	Leg_GamesPlayed(A0)
	Beq.s	.Nex
	Btst	#0,D2
	Bne.s	.Eq1
	Addq.w	#1,D3
	Bra.s	.Nex		
.Eq1	Addq.w	#1,D4
.Nex	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D2
	Cmp.w	#NbJoueurs,D2
	Blt.s	.LoopJMA
	*
	Tst.w	D3	
	Beq	.QUITA	Personne dans l'équipe 0: on vire
	Tst.w	D4	
	Beq	.QUITA	Personne dans l'équipe 1: on vire
	*
	Ext.l	D3
	Ext.l	D4
	Lea	VictoiresEq,A0	.W Eq0,.W Eq1
	Move.w	(A0),D7
	Sub.w	2(A0),D7		0:Egalité  >0:Equipe 0 gagne 
	Beq	.EqNoWin
	Blt.s	.Eq1Win

	********** ON CALCULE LE PAS SUR CHAQUE MARCHE
.Eq0Win	
	Move.l	#Zone1_L*8,D5	Centrage sur une marche: DX=(Larg-Nb*LS)/(Nb+1)
	Move.l	D3,D6		Nombre de bonhommes
	Mulu.w	#VueLarg,D6
	Sub.l	D6,D5
	Addq.l	#1,D3
	Divs.l	D3,D5	
	Move.l	D5,PasMarche1	VAINQUEURS


	Move.l	#Zone3_L*8,D5
	Move.l	D4,D6
	Mulu.w	#VueLarg,D6
	Sub.l	D6,D5
	Addq.l	#1,D4
	Divs.l	D4,D5	
	Move.l	D5,PasMarche3	LOOSERS

	Bra.s	.EqWS
.Eq1Win

	Move.l	#Zone1_L*8,D5	Centrage sur une marche: DX=(Larg-Nb*LS)/(Nb+1)
	Move.l	D4,D6
	Mulu.w	#VueLarg,D6
	Sub.l	D6,D5
	Addq.l	#1,D4
	Divs.l	D4,D5	
	Move.l	D5,PasMarche1	VAINQUEURS


	Move.l	#Zone3_L*8,D5
	Move.l	D3,D6
	Mulu.w	#VueLarg,D6
	Sub.l	D6,D5
	Addq.l	#1,D3
	Divs.l	D3,D5	
	Move.l	D5,PasMarche3	LOOSERS

	Bra.s	.EqWS
	
.EqNoWin
	*Move.l	D3,D6	Centrage sur une marche: DX=(Larg-Nb*LS)/(Nb+1)
	*Add.l	D4,D6
	*Move.l	D6,D4
	*Mulu.w	#VueLarg,D6	Nb*LSpr
	*Move.l	#Zone1_L*8,D5
	*Sub.l	D6,D5		Larg-Nb*LSpr	
	*Addq.l	#1,D4
	*Divs.l	D4,D5	
	*Move.l	D5,PasMarche1	

	Move.l	#Zone2_L*8,D5	Centrage sur une marche: DX=(Larg-Nb*LS)/(Nb+1)
	Move.l	D3,D6		Nombre de bonhommes
	Mulu.w	#VueLarg,D6
	Sub.l	D6,D5
	Addq.l	#1,D3
	Divs.l	D3,D5	
	Move.l	D5,PasMarche2	EGAL 1


	Move.l	#Zone3_L*8,D5
	Move.l	D4,D6
	Mulu.w	#VueLarg,D6
	Sub.l	D6,D5
	Addq.l	#1,D4
	Divs.l	D4,D5	
	Move.l	D5,PasMarche3	EGAL 2


.EqWS	**** On refait le traitement précédent mais en affectant les
	* joueurs sur les marches.
	
	Movea.l	LegoPtr,A0
	Clr.l	D2	
	Move.l	PasMarche1,D3	Pour la marche 1
	Move.l	PasMarche2,D5	Pour la marche 2
	Move.l	PasMarche3,D4	Pour la marche 3
	Add.l	#VueLarg,PasMarche1
	Add.l	#VueLarg,PasMarche2
	Add.l	#VueLarg,PasMarche3	
.LoopJ2	Tst.l	Leg_GamesPlayed(A0)
	Beq.s	.Nex2
	***** Ca ne rigole plus, on a trouvé un mec... ;-)
	Tst.w	D7		0:Egalité  >0:Equipe 0 gagne 	
	Beq	.EGALTEAM
	Bgt.s	.E0Win
.E1Win	* Equipe 1 qui gagne	
	Btst	#0,D2
	Bne	.WINNERSTEAM	
	Bra	.LOOSERSTEAM
.E0Win	* Equipe 0 qui gagne
	Btst	#0,D2
	Beq	.WINNERSTEAM
	Bra	.LOOSERSTEAM		
	*****
.Nex2	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D2
	Cmp.w	#NbJoueurs,D2
	Blt.s	.LoopJ2
	
	Bra	.QUITA

**************** On est ici pour ajouter un joueur de l'équipe gagnante
*
*
.WINNERSTEAM
*** Pas touche à:   D2,D3,D4/A0/A1
	Move.w	D3,Feel_X(A1)
	Move.w	#2,Feel_Y(A1)	0-3
	Move.w	#2,Feel_Anim(A1)
	Clr.w	Feel_Vue(A1)
	Move.w	#Zone1_SIZE,Feel_SSizePlan(A1)
	Move.w	#Zone1_L,Feel_SSizeLine(A1)
	Move.l	AdrZone1,Feel_AdrPlan(A1)
	Move.w	D2,Feel_NumPl(A1)
	Adda.w	#Feel_SizeOf,A1
	Add.w	#1,NbPlayersFeel
	Add.l	PasMarche1,D3	Pour la marche 1
	Bra.s	.Nex2

**************** On est ici pour ajouter un joueur de l'équipe perdante.
*
*
.LOOSERSTEAM
	*** Pas touche à:   D2,D3,D4/A0/A1
	Move.w	D4,Feel_X(A1)
	Move.w	#2,Feel_Y(A1)	0-3
	Move.w	#1,Feel_Anim(A1)
	Clr.w	Feel_Vue(A1)
	Move.w	#Zone3_SIZE,Feel_SSizePlan(A1)
	Move.w	#Zone3_L,Feel_SSizeLine(A1)
	Move.l	AdrZone3,Feel_AdrPlan(A1)
	Move.w	D2,Feel_NumPl(A1)
	Adda.w	#Feel_SizeOf,A1
	Add.w	#1,NbPlayersFeel
	Add.l	PasMarche3,D4	Pour la marche 3
	Bra	.Nex2

**************** On est ici pour ajouter un joueur de l'équipe égal
*
*
*** Pas touche à:   D2,D3,D4/A0/A1
*
.EGALTEAM	
	Btst	#0,D2
	Bne.s	.EgalT1
.EgalT0	Move.w	D5,Feel_X(A1)
	Move.w	#2,Feel_Y(A1)	0-3
	Move.w	#1,Feel_Anim(A1)
	Clr.w	Feel_Vue(A1)
	Move.w	#Zone2_SIZE,Feel_SSizePlan(A1)
	Move.w	#Zone2_L,Feel_SSizeLine(A1)
	Move.l	AdrZone2,Feel_AdrPlan(A1)
	Move.w	D2,Feel_NumPl(A1)
	Adda.w	#Feel_SizeOf,A1
	Add.w	#1,NbPlayersFeel
	Add.l	PasMarche2,D5	Pour la marche 2
	Bra	.Nex2
.EgalT1	Move.w	D4,Feel_X(A1)
	Move.w	#2,Feel_Y(A1)	0-3
	Move.w	#1,Feel_Anim(A1)
	Clr.w	Feel_Vue(A1)
	Move.w	#Zone3_SIZE,Feel_SSizePlan(A1)
	Move.w	#Zone3_L,Feel_SSizeLine(A1)
	Move.l	AdrZone3,Feel_AdrPlan(A1)
	Move.w	D2,Feel_NumPl(A1)
	Adda.w	#Feel_SizeOf,A1
	Add.w	#1,NbPlayersFeel
	Add.l	PasMarche3,D4	Pour la marche 3
	Bra	.Nex2



*************************************************************
*		     INDIVIDUAL			*
*************************************************************
.INDIV
*
* D7 libre (utilisé seulement en mode TEAMS!)
* A1: VITAL ! pointeur actuel de la liste de joueurs animés


***********************	ON COMMENCE PAR TRIER LES JOUEURS (Indexé)
	
	Lea	Tri,A2		40 octets
	Clr.l	D1		Nombre de mecs déjà mis dans le tri
	Clr.l	D3		Nombre de joueurs sur le podium
	Movea.l	LegoPtr,A0
	Clr.l	D2	
.LoopJT	Tst.l	Leg_GamesPlayed(A0)
	Beq.s	.NexI
	Tst.w	D1	AJOUT DANS LE TRI si joueur a joué >=1 partie
	Ble	.AddFin
	********************	
	Lea	Tri,A3
	Move.w	D1,D4		On lit les anciens joueurs
	Subq.w	#1,D4	>=0	dans l'ordre MEILLEUR->A CHIER
.LoopQQ	Move.w	(A3)+,D5		N° du joueur déjà écrit (<D2)
	Mulu.w	#Leg_SizeOf,D5
	Movea.l	LegoPtr,A4
	Lea	(A4,D5.w),A4	Adresse joueur ancien
	** pour s'insérer, on DOIT être MEILLEUR que lui
	Move.l	Leg_GamesWon(A4),D5
	Sub.l	Leg_GamesWon(A0),D5	<0:Nous meilleur =0:Egalite
	Bgt	.PlusMauv		>0: Lui meilleur
	Blt	.INSERE
	* Egalite dans les victoires...
	Move.l	Leg_GamesPlayed(A4),D5
	Sub.l	Leg_GamesPlayed(A0),D5	<0:Nous meilleur =0:Egalite
	Bgt	.PlusMauv		>0: Lui meilleur
	Blt	.INSERE
	* Egalite dans les parties jouées
	Move.l	Leg_BombesPosees(A4),D5
	Sub.l	Leg_BombesPosees(A0),D5	<0:Nous meilleur =0:Egalite
	Bgt	.PlusMauv		>0: Lui meilleur
	Blt	.INSERE
	* Egalite dans les bombes posées
	Move.l	Leg_BonusTaken(A4),D5
	Sub.l	Leg_BonusTaken(A0),D5	<0:Nous meilleur =0:Egalite
	Bgt	.PlusMauv		>0: Lui meilleur
	Blt	.INSERE
	* EGALITE PARFAITE: il faut bien en mettre un devant l'autre...	
.PlusMauv	Dbf	D4,.LoopQQ
.AddFin	Addq.w	#1,D1	Ecriture Premier joueur ou joueur plus mauvais
	Move.w	D2,(A2)+	que tous ceux déjà écrits.
	********************
.NexI2	Addq.w	#1,D3
.NexI	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D2
	Cmp.w	#NbJoueurs,D2
	Blt.s	.LoopJT

	**** On rajoute les joueurs qui n'ont pas joué à la fin
	* pour conserver une bonne cohérence pour les statistiques
	*
	Movea.l	LegoPtr,A0
	Clr.l	D2
.LoopFil	Tst.l	Leg_GamesPlayed(A0)
	Bgt.s	.Deja
	Move.w	D2,(A2)+
.Deja	Addq.w	#1,D2
	Cmp.w	#NbJoueurs,D2
	Blt.s	.LoopFil

	*******

	Tst.w	D3
	Beq	.QUITA		Aucun joueur: on JARTE !


	***************	C'EST LE TRI QUI DECONNE
	*Move.l	Tri,Temp1
	*Move.l	Tri+4,Temp2
	*Bsr	DEBUG
	***************



	******* On détermine les points de rupture et le nombre de joueurs
	*       par marche

	Movea.l	LegoPtr,A0
	Lea	JParMarche,A4
	Clr.l	(A4)	0 joueurs pour l'instant par marche
	Clr.w	4(A4)
	Lea	Tri,A3	D1:Nombre de joueurs dans le tri
	Move.w	D1,D4
	Subq.w	#1,D4
	Blt	.QUITA	Erreur
	Moveq	#-1,D5	C'est le premier joueur
	Clr.l	D0	N° de la marche 0-2
.Compte	Move.w	(A3)+,D2
	Tst.w	D5		Premier joueur ???
	Bne.s	.OkMarch	
	Cmp.w	#2,D0		Si dernière marche: pas le choix!
	Bge.s	.OkMarch		

	Mulu.w	#Leg_SizeOf,D2
	Lea	(A0,D2.w),A2	Joueur actuel

	* On est au moins au deuxième joueur et pas encore à la dernière 
	Move.w	-4(A3),D2		marche. On cherche une rupture.
	Mulu.w	#Leg_SizeOf,D2
	Lea	(A0,D2.w),A5	Joueur précédent
	
	Move.l	Leg_GamesWon(A5),D5
	Sub.l	Leg_GamesWon(A2),D5		=0: Egalite...
	Bne.s	.Rupture

	* Si il n'y a pas de rupture naturelle, on vérifie si
	* la marche est saturée (Max N bonhommes par marche)
	Cmp.w	#3,(A4)
	Ble.s	.OkMarch		<=3 joueurs ? pas de problème
	
.Rupture	Adda.w	#2,A4		On passe à la marche suivante
	Addq.w	#1,D0
.OkMarch	Add.w	#1,(A4)		Un de plus sur la marche
	Clr.l	D5		Ce n'est plus le premier joueur
	Dbf	D4,.Compte

	******* On compte combien on a de joueurs par marche
	*	et on les affecte à l'écran

	Lea	JParMarche,A4
	**
	Move.w	(A4),D4		Nb joueurs PREMIERE marche
	Ext.l	D4
	Move.l	#Zone1_L*8,D5	Centrage sur une marche: DX=(Larg-Nb*LS)/(Nb+1)
	Move.l	D4,D6
	Mulu.w	#VueLarg,D6
	Sub.l	D6,D5
	Addq.l	#1,D4
	Divs.l	D4,D5	
	Move.l	D5,PasMarche1	VAINQUEURS
	**
	Move.w	2(A4),D4		Nb joueurs DEUXIEME marche
	Ext.l	D4
	Move.l	#Zone2_L*8,D5	Centrage sur une marche: DX=(Larg-Nb*LS)/(Nb+1)
	Move.l	D4,D6
	Mulu.w	#VueLarg,D6
	Sub.l	D6,D5
	Addq.l	#1,D4
	Divs.l	D4,D5	
	Move.l	D5,PasMarche2	MOYENS
	**
	Move.w	4(A4),D4		Nb joueurs TROISIEME marche
	Ext.l	D4
	Move.l	#Zone3_L*8,D5	Centrage sur une marche: DX=(Larg-Nb*LS)/(Nb+1)
	Move.l	D4,D6
	Mulu.w	#VueLarg,D6
	Sub.l	D6,D5
	Addq.l	#1,D4
	Divs.l	D4,D5	
	Move.l	D5,PasMarche3	GROSSES MERDES VISQUEUSES
	**
	****** On a a nos pas de centrage sur les marches...
	*	On COPIE nos joueurs sur les Marches... hum! dur!
	Lea	Tri,A3
	**
	Move.w	(A4)+,D0	Joueurs sur cette marche 1

	Subq.w	#1,D0
	Blt	.NoMarch1
	Move.l	PasMarche1,D4
	Add.l	#VueLarg,PasMarche1
.March1L	Move.w	D4,Feel_X(A1)
	Move.w	#2,Feel_Y(A1)	0-3
	Move.w	#2,Feel_Anim(A1)
	Clr.w	Feel_Vue(A1)
	Move.w	#Zone1_SIZE,Feel_SSizePlan(A1)
	Move.w	#Zone1_L,Feel_SSizeLine(A1)
	Move.l	AdrZone1,Feel_AdrPlan(A1)
	Move.w	(A3)+,Feel_NumPl(A1)
	Adda.w	#Feel_SizeOf,A1
	Add.w	#1,NbPlayersFeel	
	Add.l	PasMarche1,D4	Pour la marche 1
	Dbf	D0,.March1L
.NoMarch1
	**
	Move.w	(A4)+,D0	Joueurs sur cette marche 2
	Subq.w	#1,D0
	Blt	.NoMarch2
	Move.l	PasMarche2,D4
	Add.l	#VueLarg,PasMarche2
.March2L	Move.w	D4,Feel_X(A1)
	Move.w	#2,Feel_Y(A1)	0-3
	Move.w	#1,Feel_Anim(A1)
	Clr.w	Feel_Vue(A1)
	Move.w	#Zone2_SIZE,Feel_SSizePlan(A1)
	Move.w	#Zone2_L,Feel_SSizeLine(A1)
	Move.l	AdrZone2,Feel_AdrPlan(A1)
	Move.w	(A3)+,Feel_NumPl(A1)
	Adda.w	#Feel_SizeOf,A1
	Add.w	#1,NbPlayersFeel	
	Add.l	PasMarche2,D4	Pour la marche 2
	Dbf	D0,.March2L
.NoMarch2
	**
	Move.w	(A4),D0	Joueurs sur cette marche 3
	Subq.w	#1,D0
	Blt	.NoMarch3
	Move.l	PasMarche3,D4
	Add.l	#VueLarg,PasMarche3
.March3L	Move.w	D4,Feel_X(A1)
	Move.w	#2,Feel_Y(A1)	0-3
	Move.w	#3,Feel_Anim(A1)
	Clr.w	Feel_Vue(A1)
	Move.w	#Zone3_SIZE,Feel_SSizePlan(A1)
	Move.w	#Zone3_L,Feel_SSizeLine(A1)
	Move.l	AdrZone3,Feel_AdrPlan(A1)
	Move.w	(A3)+,Feel_NumPl(A1)
	Adda.w	#Feel_SizeOf,A1
	Add.w	#1,NbPlayersFeel	
	Add.l	PasMarche3,D4	Pour la marche 3
	Dbf	D0,.March3L
.NoMarch3
.QUITA
*************************************************************
*       COPIER LES VUES DANS LES CADRES D'ANIMATION         *
*************************************************************
	
	************  COPIER LES JOUEURS EN ZONES
	Tst.w	NbPlayersFeel
	Beq	.EndCop
	Movea.l	LegoPtr,A1
	Moveq	#7-1,D6		Boucle pour les ZONES
.Loop7	Lea	FeelWork,A0
	Move.w	NbPlayersFeel,D7
	Subq.w	#1,D7
.LoopJ	Move.w	Feel_NumPl(A0),D2
	Mulu.w	#Leg_SizeOf,D2
	Lea	(A1,D2.w),A2		Adresse structure joueur
	Move.w	Leg_FeelCol(A2),FeelCol	Couleur voulue
	Move.w	Feel_X(A0),D0
	Move.w	Feel_Y(A0),D1
	Move.w	Feel_Anim(A0),D2
	Move.w	Feel_Vue(A0),D3
	Move.w	Feel_SSizePlan(A0),Source_SizePlan
	Move.w	Feel_SSizeLine(A0),Source_SizeLine
	Move.l	Feel_AdrPlan(A0),Source_AdrPlan
	*
**** Ici on doit lire la couleur du joueur et lancer le "COLORIAGE" ****

	Bsr	COLORIAGE		(D2:Animation)

*************
	Move.w	D6,D5
	Mulu.w	#Zone_TOTAL,D5
	Add.l	D5,Source_AdrPlan
	Bsr	CopVue
	Add.w	#1,D3	Prochaine vue de l'anim
	Cmp.w	#6,D3
	Ble.s	.OkV
	Clr.w	D3
.OkV	Move.w	D3,Feel_Vue(A0)
	Adda.w	#Feel_SizeOf,A0
	Dbf	D7,.LoopJ
	Dbf	D6,.Loop7

.EndCop	Move.w	#0,ImageAct1	0-6
	Move.w	#1,ImageSens1
	Move.w	#5,ImageAct2
	Move.w	#1,ImageSens2
	Move.w	#2,ImageAct3
	Move.w	#-1,ImageSens3

	RTS

*******	On INSERE un numéro de joueur dans le tableau de tri
*
* On est meilleur que le joueur précédemment trouvé, on se met à sa place
*
* D4: Nombre de boucles restantes dans le tri... (>0 : reste D4 joueurs)
* A3: Pointeur actuel sur le tri +1
* D2: N° du joueur en cours de traitement, celui que l'on veut placer
* A3: Prochain joueur à lire (Joueur lu+2)
* 
.INSERE
	Tst.w	D4
	Beq.s	.Dernier
	
	* Le joueurs à remplacer était en début ou milieu de liste
	Lea	(Tri,D1.w*2),A4	Dernier+1
.Decal	Move.w	-(A4),2(A4)
	Cmpa.l	A3,A4		
	Bge.s	.Decal
	Move.w	D2,(A4)
	Addq.w	#1,D1
	Bra	.NexI2

.Dernier	* Le joueur à remplacer était le dernier
	Move.w	-2(A3),(A3)
	Move.w	D2,-2(A3)
	Addq.w	#1,D1
	Bra	.NexI2
*******


************	Copier la zone en 7 exemplaires
* A0: Source (plan)
* A1: Cible (zones)
* D0: H
* D2: L
* D6: Taille plan zone
*
Copy7
	Move.w	#SizeLine,D3	-4 pour le (A0)+,...
	Sub.w	D2,D3	D3=MODULO
	Lsr.w	#2,D2	D2=Largeur
	Subq.w	#1,D2
	Move.w	D0,D4	D4=Hauteur
	Subq.w	#1,D4
	Moveq	#7-1,D1
.Loop7	Movem.l	A0-A1,-(A7)
	Moveq	#7-1,D5
.LoopPl	Movem.l	D4/A0-A1,-(A7)
.LoopY	Move.w	D2,-(A7)
.Line	Move.l	(A0)+,(A1)+
	Dbf	D2,.Line
	Move.w	(A7)+,D2		
	Adda.w	D3,A0		Prochaine ligne
	Dbf	D4,.loopY
	Movem.l	(A7)+,D4/A0-A1
	Adda.w	#SizePlan,A0	Prochain plan
	Adda.w	D6,A1
	Dbf	D5,.LoopPl
	Movem.l	(A7)+,A0-A1	
	Adda.w	#Zone_TOTAL,A1	Prochaine zone cible
	Dbf	D1,.Loop7
	RTS

	****
	
****************  Ordre de défilement des images
*
*
AnimNext	
	Tst.w	Ask_To_Stop
	Beq.s	.Normal		Arrêt anim dernière vue
	Cmp.w	#0,D0
	Beq.s	.OkP	On ne touche plus à rien		
.Normal	Add.w	D1,D0
	Bge.s	.OkN
	Clr.w	D0
	Move.w	#1,D1
.OkN	Cmp.w	#6,D0
	Ble.s	.OkP
	Move.w	#6,D0
	Move.w	#-1,D1	
.OkP	RTS



********************************************************************
*                EXECUTER L'ANIMATION DU PODIUM                    *
********************************************************************
AnimPodium

	**************************** COPIER LA ZONE EN VISIBLE

	**** FAIRE ANIMER LES ZONES

Zone1	Move.w	ImageAct1,D0
	Move.w	ImageSens1,D1
	Bsr	AnimNext
	Move.w	D0,ImageAct1
	Move.w	D1,ImageSens1
	**
	Move.l	AdrZone1,A0
	Mulu.w	#Zone_TOTAL,D0
	Adda.l	D0,A0
	Move.l	Planar,A1
	Adda.w	#Zone1_Y*SizeLine+Zone1_X,A1
	Move.w	#SizeLine-Zone1_L,D3	
	Moveq	#7-1,D2	
.LoopPl	Movem.l	A0-A1,-(A7)
	Move.w	#Zone1_H-1,D1
.LoopY	Moveq	#Zone1_L/4-1,D0
.Line	Move.l	(A0)+,(A1)+
	Dbf	D0,.Line
	Adda.w	D3,A1
	Dbf	D1,.LoopY	
	Movem.l	(A7)+,A0-A1
	Adda.w	#Zone1_SIZE,A0
	Adda.w	#SizePlan,A1
	Dbf	D2,.LoopPl

Zone2	Move.w	ImageAct2,D0
	Move.w	ImageSens2,D1
	Bsr	AnimNext
	Move.w	D0,ImageAct2
	Move.w	D1,ImageSens2
	**
	Move.l	AdrZone2,A0
	Mulu.w	#Zone_TOTAL,D0
	Adda.l	D0,A0
	Move.l	Planar,A1
	Adda.w	#Zone2_Y*SizeLine+Zone2_X,A1
	Move.w	#SizeLine-Zone2_L,D3	
	Moveq	#7-1,D2	
.LoopPl	Movem.l	A0-A1,-(A7)
	Move.w	#Zone2_H-1,D1
.LoopY	Moveq	#Zone2_L/4-1,D0
.Line	Move.l	(A0)+,(A1)+
	Dbf	D0,.Line
	Adda.w	D3,A1
	Dbf	D1,.LoopY	
	Movem.l	(A7)+,A0-A1
	Adda.w	#Zone2_SIZE,A0
	Adda.w	#SizePlan,A1
	Dbf	D2,.LoopPl

Zone3	Move.w	ImageAct3,D0
	Move.w	ImageSens3,D1
	Bsr	AnimNext
	Move.w	D0,ImageAct3
	Move.w	D1,ImageSens3
	**
	Move.l	AdrZone3,A0
	Mulu.w	#Zone_TOTAL,D0
	Adda.l	D0,A0
	Move.l	Planar,A1
	Adda.w	#Zone3_Y*SizeLine+Zone3_X,A1
	Move.w	#SizeLine-Zone3_L,D3	
	Moveq	#7-1,D2	
.LoopPl	Movem.l	A0-A1,-(A7)
	Move.w	#Zone3_H-1,D1
.LoopY	Moveq	#Zone3_L/4-1,D0
.Line	Move.l	(A0)+,(A1)+
	Dbf	D0,.Line
	Adda.w	D3,A1
	Dbf	D1,.LoopY	
	Movem.l	(A7)+,A0-A1
	Adda.w	#Zone3_SIZE,A0
	Adda.w	#SizePlan,A1
	Dbf	D2,.LoopPl
		
	Tst.w	Ask_To_Stop
	Beq.s	.NoAsk
	Cmp.w	#0,ImageAct1
	Bne.s	.NoAsk
	Cmp.w	#0,ImageAct2
	Bne.s	.NoAsk
	Cmp.w	#0,ImageAct3
	Bne.s	.NoAsk
	Move.w	#1,Ask_To_Stop	
.NoAsk		
	RTS



*
* Pour définir la position des joueurs sur le podium:
*
* On sépare le cas équipe/pas équipe.
*
* Si équipe: 3 sur la première marche, 3 sur la DERNIERE (no second prize!)
*		SI EGALITE ENTRE EQUIPES ?????? ON LES SERRE ????
*
* Si indiv.: >=1 sur la première marche, >=1 sur la deuxième
*                   SI EGALITE ENTRE 6 MECS ???? 
*
*
* BUT1: On classe les joueurs par:
* NOMBRE DE VICTOIRES,Nombre de parties (ancienneté),Nombre de bombes posées,
* Bonus pris
*
* Puis on parcourt le tableau et on fait de ruptures là où il y en a de
* naturelles, ou si il y a trop de monde sur un podium. à la moindre 
* différence de nb de bombes, on change de marche.
*
***************
* Animations FEELINGS:
* 	 0: Bisou
* 	 1: Poing, colère
*	 2: Bras levés
*	 3: Mouchoir
*	 4: Ok pouce
*	 5: Pas Ok Pouce
*	 6: Mains poches ok
*	 7: Mains hanches pas content
*
*
* Individual codé en UNE fois !!! :
* 192 lignes non stop!: Et ça a marché du premier coup!
*
* DEBUG: 
* - A3 utilisé 2 fois en Individual
*



