*
*
* Sons utilisés: 8,17,18: on peut virer les autres.
*
* WinGuy: le N° du joueur qui a gagné (0-5)
* Si mode équipes: tester le Bit #0 du joueur !
*	
PodiumAppearTime	=	100
PodiumFadingTime	=	20

AFF_PODIUM
	Clr.l	BarreDecounter	Pour retour plus facile...
	Jsr	Set3

	****** On vire tous les sons inutiles ! on garde 8,17,18
	*Move.l	#SamplesPodium,SamplesToKeep
	*Bsr	FreeSamples


	****** Podium!	Si on n'a pas eu assez de mémoire pour
	Moveq	#3,D0	le charger avant...
	Bsr	ChargePic


	* WINNERSPH : RequestForNewLevel

	Move.w	#64,SoundVol	Valeurs temporaires au maxi
	Move.w	#64,P61_Master

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
	*Lea	PODIUM,A3
	Moveq	#7,D1
	Move.l	#(320/8)*256,D2
	* Chip *
	Movea.l	Planar,A2
	Move.l	#SizePlan,D3
	* DISPLAY *
	Bsr	DisplayPic2
	************************

	***********************	STOP MUSIC
	Moveq	#0,D0	Arrêt de la musique: toutes voies libres
	Jsr	LaunchZik	
	***********************

	***********************	BRUIT win 1: Foule
	Movem.l	A0-A1/D1/D3-D5,-(A7)
	Moveq	#17,D3
	Moveq	#PriSonWinT1,D1
	Move.w	#2,SampleLoops	3 fois le sample ! ;-)
	Bsr	PlaySon
	Movem.l	(A7)+,A0-A1/D1/D3-D5
	***********************	BRUIT win 2: Photo
	Movem.l	A0-A1/D1/D3-D5,-(A7)
	Moveq	#18,D3
	Moveq	#PriSonWinT2,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,A0-A1/D1/D3-D5
	***********************	BRUIT win normal: applause
	Movem.l	A0-A1/D1/D3-D5,-(A7)
	Moveq	#8,D3
	Moveq	#PriSonWin,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,A0-A1/D1/D3-D5
	*************************
	Movem.l	D0-D7/A0-A6,-(A7)
	*- Fading affichage
	Move.l	#PalSrc,A0
	Move.l	#PodiumCol,A1
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#128,D0	
	Move.l	#PodiumAppearTime,D1		temps Apparition		
	Bsr	FadeBetween_Run
	Move.l	#PodiumCol,A0
	Move.l	#128,D0
	Jsr	MakePaletteNew
	Movem.l	(A7)+,D0-D7/A0-A6


	Bsr	Statistiques

	Bsr	InitAnimPodium
	
	WaitHard	#25
.AttLa	***
	Bsr	AnimPodium
	***
	Move.l	ClavierPtr,A0
	Tst.b	69(A0)
	Bne	.Qui	
	Bsr	TestInputs
	Tst.w	D4
	Bne.s	.AttLa		Feu(x) enclenché(s)


.Nop	***
	Bsr	AnimPodium
	***
	Move.l	ClavierPtr,A0
	Tst.b	69(A0)
	Bne	.Qui	
	Bsr	TestInputs
	Tst.w	D4
	Beq.s	.Nop		Aucun feu enclenché

	*Bra.s	.ErrQui

.Qui	*- Préparation palette cible
	Move.l	#PalSrc,A0	Palette
	Move.l	#128,D0		
	Move.l	#0,D1	
	Bsr	PalClr	A0/D0/D1	
	*- Fading affichage
	Move.l	#PodiumCol,A0
	Move.l	#PalSrc,A1
	Move.l	#PalVec,A2
	Move.l	#PalAct,A4
	Move.l	#128,D0	
	Move.l	#PodiumFadingTime,D1		
	Bsr	FadeBetween_Run

	* Nouveau Level
	Bsr	ClsALL
	*** Palette
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
	*Move.w	#1,LevelInfoState	Pour pas restaurer plan 7
	RTS

.ErrQui
	Move.l	MessageWaitPtr,A0
	Move.l	#Phrase_ErrMem,(A0)+
	Clr.l	(A0)	<- si liste de messages... mais bon,
	*		il manque les zones pour stocker...
	Bra	.Qui

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
* Inconvénient:
* - Perte mémoire
*
* Pour la mémoire, au lieu de réserver:
* - en cours de route et s'attendre à une erreur de mémoire
* - au début du jeu et bouffer 25 Ko juste pour le podium
* Je peux utiliser la mémoire de la barre des joueurs, qui fait:
* 80*6*18=8640 ... hum! manque un peu...
*
* Utilisation de DIM4 pour travail: 4*4*64*32 = 32768
*
*
InitAnimPodium
	Movea.l	Dim4,A0		65536 ou au pire 32768 octets




	RTS

	****

AnimPodium
	Movea.l	Dim4,A0

	RTS




*PodiumCoul_Vert	=	1	Vert
*PodiumCoul_VertF	=	1	Vert
*PodiumCoul_Jaune	=	1	Jaune
*PodiumCoul_Rouge	=	1	Rouge
*PodiumCoul_RougeF	=	1	Rouge
*PodiumCoul_GrisF	=	1	Gris (ombre)
*PodiumCoul_Blanc	=	1	Blanc (texte)


