	*	CalcMot
	*	TriJou
	*	makesprpal
	

	*********	Gérer les joueurs et modifier la copper liste
	*
	*
GestionSprites
	Bsr	TriJou8Pal	Palette pour 8 sprites-retard 1 vbl
	*Bsr	SprCol		Collisions - Maladies par Sprite <=4
	Bsr	ColJoue		Collisions - Maladies par Position
	Bsr	Joueurs		Joueurs
	Bsr	Trier		Trier 
	Bsr	TriJou		Mettre a jour
	RTS


*********************************

************* Préparer les joueurs pour un niveau
*
* A6: Adresse structure level
*
PrepPos	Move.w	#-1,RequestBeginLevel
	Clr.w	NbJActMax
	Clr.w	JActivated	Aucun joueur activé (On/Off)
	Move.w	#2,NbJoueursEnVie	>1
	*Clr.w	NbJoueursEnVie
	Move.w	#1,NbJEVEq1
	Move.w	#1,NbJEVEq2
	Move.w	#0,NbJAct
	Move.w	#0,NbJAct2
	Move.l	XAff,D0		Positions en pixels
	Move.l	YAff,D1
	Add.l	#136-16,D0
	Add.l	#42-16,D1
	Move.l	D0,SprBaseX
	Move.l	D1,SprBaseY
	Move.l	LegoPtr,A0	Joueur 1
	Lea	Level_PosDep(A6),A5
	Bsr	DefWhichBar

	Clr.w	LegAutoFire
	Move.w	NLevel,D3
	Cmp.w	#-1,D3
	Beq.s	.NoAutoF
	Move.w	#-1,LegAutoFire
.NoAutoF	Move.w	Level_AutoFire(A6),D3
	Ext.l	D3
	And.w	D3,LegAutoFire

	Clr.l	D7
	Clr.l	D2
	Moveq	#NbJoueurs-1,D3
.LoopPl	**************************
	Move.w	D2,Leg_ImBase(A0)
	Move.w	#ImFinTele,D0	
	Move.w	D0,Leg_Im(A0)		Images
	Move.w	D7,Leg_Ralent(A0)
	Move.w	D7,Leg_MDY(A0)		

	Move.l	D4,-(A7)
	Tst.w	Leg_Mort(A0)
	Beq.s	.NotNewL
	Move.w	#-1,Leg_Mort(A0)
	Move.w	Leg_DontMove(A0),D4
	Cmp.w	#1,D4	1 fois=Autorisé
	Bgt.s	.NotNewL
	Move.w	D7,Leg_Mort(A0)
.NotNewL	Move.l	(A7)+,D4
	Tst.w	NewLevel
	Beq.s	.NoNL
	Move.w	D7,Leg_FireRequest(A0)
	Bra.s	.ANL
.NoNL	Move.w	#TimeRestartDontMove,Leg_FireRequest(A0)	Don't move: on appuie
.ANL
	Move.w	D7,Leg_MDX(A0)		
	Move.w	D7,Leg_ImBl(A0)
	Move.w	D7,Leg_Malad(A0)
	Move.w	D7,Leg_BumpX(A0)
	Move.w	D7,Leg_BumpY(A0)
	Move.w	D7,Leg_Offset(A0)
 	Move.w	D7,Leg_OkBump(A0)
	Move.w	D7,Leg_Fire(A0)
	Move.w	D7,Leg_FireAct(A0)
	Move.w	D7,Leg_FireAnc(A0)
	Move.w	LegAutoFire,Leg_AutoFire(A0)
	Move.l	D4,-(A7)
	Move.w	Level_TimeB(A6),D4
	Move.w	D4,Leg_NbBoucles(A0)
	Mulu.w	#(BombImT-BombImL+1),D4
	Add.w	#BombImFin-BombImT,D4
	Move.w	D4,Leg_BTime(A0)		#BTime_Normal

*	Move.w	#BombNbBoucles,Leg_NbBoucles(A0)

	Move.l	(A7)+,D4
	Move.w	D7,Leg_LastCount(A0)
	Move.l	D7,Leg_HMem(A0)
	Move.w	D7,Leg_Activated(A0)
	Move.w	D7,Leg_Horloge(A0)
	Move.w	Level_SpeedJ(A6),Leg_VitJou(A0)
	Move.w	Level_NbB(A6),Leg_MaBomb(A0)
	Move.w	Level_LongF(A6),Leg_Flamme(A0)	
	Move.w	Level_PousseB(A6),Leg_PousseBombe(A0)
	Move.w	#1,Leg_ForceCentre(A0)
	Move.w	Leg_Im(A0),Leg_Tele(A0)	Image téléportation
	Move.w	D7,Leg_TelOk(A0)
	Move.w	#-1,Leg_TelePhase(A0)
	Move.l	D7,Leg_LastPos(A0)
	Move.l	D7,Leg_LastPos2(A0)
	Move.w	D7,Leg_LastBomb(A0)
	**
	Move.w	OffPosBarre(A4),Leg_BarreX8(A0)	Coordonnées dans la barre
	Move.w	(A4)+,Leg_BarreX4(A0)	Coordonnées dans la barre
	Move.w	OffPosBarre(A4),Leg_BarreY8(A0)
	Move.w	(A4)+,Leg_BarreY4(A0)
	Move.w	OffPosBarre(A4),Leg_BarreBase8(A0)
	Move.w	(A4)+,Leg_BarreBase4(A0)
	Move.w	OffPosBarre(A4),Leg_BarreBlocX8(A0)
	Move.w	(A4)+,Leg_BarreBlocX4(A0)
	*Move.w	OffPosBarre(A4),Leg_FeelCol(A0)
	Move.w	(A4)+,Leg_FeelCol(A0)
	*
	**				Position départ du joueur
	Move.w	(A5)+,D0
	Lsl.w	#4,D0
	Add.l	SprBaseX,D0
	Move.w	D0,Leg_X(A0)
	Move.w	(A5)+,D1
	Lsl.w	#4,D1
	Add.l	SprBaseY,D1
	Move.w	D1,Leg_Y(A0)
	**
	Lea	Leg_M1(A0),A1		Effacement maladies
	Moveq	#10-1,D1
.EffMalad	Clr.l	(A1)+	malad + mem	
	Dbf	D1,.EffMalad
	Clr.l	(A1)+	(Leg_M2Mem2,LegM4Mem2)
	**
	Move.w	Leg_BTime(A0),Leg_M3Mem2(A0)		ANTIBUG de 
	Move.w	Leg_NbBoucles(A0),Leg_M3Mem3(A0)	l'ambulance
	**
	Move.w	Leg_ImBase(A0),D2
	Add.w	#NbImsParSprite,D2	pour le début de la boucle
	Adda.w	#Leg_SIZEOF,A0
	**************************
	Dbf	D3,.LoopPl

	Tst.w	ModeAct
	Bne.s	.J8
	Bsr	PosTo4
	Bra.s	.JA
.J8	Bsr	PosTo8
.JA	Clr.w	BombDGel

	Bsr	PrepStatsT
	RTS

DefWhichBar
	Movem.l	D0-D1,-(A7)
	Cmp.w	#1,PlayerMode
	Bne.s	.PlIndiv
	Lea	PosBarreTeams,A4	*** TEAMS
	Tst.w	ModeAct
	Beq.s	.4pl1

	Moveq	#3,D0		barre teams 6 joueurs
	Move.w	#292,PosDigitJ
	Bra.s	.PlIA3

.4pl1	Moveq	#2,D0		barre teams 4 joueurs
	Move.w	#368,PosDigitJ

.PlIA3	Bsr	SetOneBarreJ
	Move.w	#210-1,PosLevelJ	Seulement pour 4 joueurs
	Move.w	#152,LargLevelJ
	Bra.s	.PlIA
	
.PlIndiv	Lea	PosBarre,A4	*** INDIVIDUAL
	Tst.w	ModeAct
	Beq.s	.4pl2
	*
	Moveq	#1,D0		barre indiv 6 joueurs
	Move.w	#4,PosDigitJ
	Bra.s	.PlIA2
	*
.4pl2	Moveq	#0,D0		barre indiv 4 joueurs
	Move.w	#24*8,PosDigitJ
	*
.PlIA2	Bsr	SetOneBarreJ
	Move.w	#2-1,PosLevelJ	Seulement pour 4 joueurs
	Move.w	#186,LargLevelJ
.PlIA	Movem.l	(A7)+,D0-D1
	RTS


*********************************************
*
* Initialisation des statistiques:
* à faire une fois par JEU et non par LEVEL.
*
*
PrepStats
	Movea.l	LegoPtr,A0
	Clr.l	D7
	Clr.l	D2	
.LoopJMA	***
	Move.l	D7,Leg_GamesPlayed(A0)
	Move.l	D7,Leg_GamesLoose(A0)
	Move.l	D7,Leg_GamesWon(A0)
	Move.l	D7,Leg_BombesPosees(A0)
	Move.l	D7,Leg_BonusTaken(A0)
	Move.l	D7,Leg_GamesPlayedT(A0)
	Move.l	D7,Leg_GamesLooseT(A0)
	Move.l	D7,Leg_GamesWonT(A0)
	***
	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D2
	Cmp.w	#NbJoueurs,D2
	Blt.s	.LoopJMA
	RTS

PrepStatsT
	Movem.l	D2/D7/A0,-(A7)
	Movea.l	LegoPtr,A0
	Clr.l	D7
	Clr.l	D2	
.LoopJMA	Move.l	D7,Leg_GamesPlayedT(A0)
	Move.l	D7,Leg_GamesLooseT(A0)
	Move.l	D7,Leg_GamesWonT(A0)
	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D2
	Cmp.w	#NbJoueurs,D2
	Blt.s	.LoopJMA
	Movem.l	(A7)+,D2/D7/A0
	RTS

CopStatsT * Ajouter les statistiques temporaires aux stats normales
	Movem.l	D2-D3/A0,-(A7)
	Movea.l	LegoPtr,A0
	Clr.l	D2	
.LoopJMA	Move.l	Leg_GamesPlayedT(A0),D3
	Add.l	D3,Leg_GamesPlayed(A0)
	Move.l	Leg_GamesLooseT(A0),D3
	Add.l	D3,Leg_GamesLoose(A0)
	Move.l	Leg_GamesWonT(A0),D3
	Add.l	D3,Leg_GamesWon(A0)
	Clr.l	Leg_GamesPlayedT(A0)
	Clr.l	Leg_GamesLooseT(A0)
	Clr.l	Leg_GamesWonT(A0)
	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D2
	Cmp.w	#NbJoueurs,D2
	Blt.s	.LoopJMA
	Movem.l	(A7)+,D2-D3/A0
	RTS

*********************************************************
****************     Routines joueurs     ***************
*********************************************************
*
* NE PAS TOUCHER A >>> D0-D3/A0 <<<
*
Joueurs	

******** Gestion de TOUS les types de feu
*
* Première boucle pour affecter un joueur à un nouveau type de feu 
* détecté.
*
*
	Lea	JoyList,A1
.chch	Move.l	(A1)+,A2
	Tst.l	A2
	Beq	.EndChch		Plus de contrôles à tester
	Tst.w	(A1)+
	Blt	.Deja		<0: Joy déjà utilisé
	Cmp.w	#NbJoueurs,NbJoueursAct
	Bge	.Deja		Tous les joueurs utilisés

	* Le Joy a sa chance. On le teste
	Clr.l	D0
	Clr.l	D1
	Move.w	#1,D4
	Move.l	A1,-(A7)
	Jsr	(A2)		D4:Step -> D4:Fire	
	Move.l	(A7)+,A1
	Tst.w	D4		D4=-1: Feu enclenché
	Beq	.Deja	
	
	Add.w	#1,NbCreated
	
	* On cherche un joueur libre
	Moveq	#NbJoueurs-1,D3
	Lea	PlayersSet,A0
.ChFrPlay	Tst.b	(A0)+
	Beq.s	.OkFPlay
	Dbf	D3,.ChFrPlay	
	Bra.s	.Deja		Raison inexplicable: on trouve pas...

.OkFPlay	* On a trouvé le joystick et le joueur
	* Inits
	Move.b	#-1,-1(A0)	PlayersSet ON
	Move.w	#-1,-2(A1)	JoyStick=-1 (Utilisation lockée)
.MicroJ	Neg.w	D3
	Add.w	#NbJoueurs-1,D3
	Mulu.w	#Leg_SizeOf,D3
	Movea.l	LegoPtr,A0
	Lea	(A0,D3.w),A0	Pointeur nouveau joueur
	Move.l	A2,Leg_Joy(A0)		JoyStick
	Move.w	#1,Leg_FireRequest(A0)
	Add.w	#1,NbJoueursAct
	* Si le contrôle est un clavier, il faut désactiver d'autres
	* claviers: ceux qui seraient en interférence avec celui-ci.
	Cmpa.l	#Clavier1,A2
	Bne.s	.NoClav1
	Move.w	#-1,Cl2Lock
	Move.w	#-1,Cl3Lock
.NoClav1
	Cmpa.l	#Clavier2,A2
	Bne.s	.NoClav2
	Move.w	#-1,Cl1Lock
.NoClav2
	Cmpa.l	#Clavier3,A2
	Bne.s	.NoClav3
	Move.w	#-1,Cl1Lock
.NoClav3
	*Cmpa.l	#MicroDeclenchement,A2
	*Bne.s	.NoMic
	*Move.w	#1,ClMLock	Pour autoriser multi-micro!
.NoMic
.Deja	
	Bra	.Chch
.EndChch

*
*
*
******** Début de la gestion normale des joueurs
*
*
*
	Move.l	LegoPtr,A0	D0:X,D1:Y,D3:J,A0:JAct
	Clr.l	D3
	Clr.w	NbJoueursEnVie
	Clr.w	NbJEVEq1
	Clr.w	NbJEVEq2

	Move.w	NbJAct,NbJAct2
	Clr.w	NbJAct
.LoopJ	Clr.w	Leg_OkBump(A0)
	Tst.w	Leg_Mort(A0)	Mec Mort
	*Bgt	.AnimMort
	Blt	.Mort

	Move.w	WinnersPhase,D0
	Beq.s	.NoWin
	Cmp.w	#2,D0		Phase=2: Anim, Sinon rien
	Beq	.AnimEnd
	Bra	.Mort		Comme mort, on bouge plus
.NoWin
	Add.w	#1,NbJoueursEnVie	Pas mort=En vie ;-)
	Btst	#0,D3
	Bne.s	.JEq2
	Add.w	#1,NbJEVEq1
	Bra.s	.JEqA
.JEq2	Add.w	#1,NbJEVEq2
.JEqA
	Tst.w	Leg_Mort(A0)	Mec Mort
	Bgt	.AnimMort		Animation mort en cours...


	Tst.w	GameMode		Pas le droit d'apparaître
	Beq.s	.OkActi		1=5 Win match
	Tst.w	LevelInfoState
	Beq	.Mort		avant transparent en 5 win match!

	Move.l	AutoCounter,D0	Temps mini d'attente début level mode 5 win match
	Sub.l	#LevelBeginMinWait5,D0
	Blt	.Mort
	Bra.s	.OkActi2		<- Si MinWait5 < MinWaitF !

.OkActi
	Move.l	AutoCounter,D0	Temps mini d'attente début level en mode free play
	Sub.l	#LevelBeginMinWaitF,D0
	Blt	.Mort
.OkActi2

	Tst.w	Leg_Activated(A0)
	Beq	.NotActive	Mec pas encore sur le jeu	

	Move.w	LevelInfoState,D0	0:Attente -1:Affiché 1:Déjà effacé
	Tst.w	D0
	Bgt.s	.DejaMec		>0: Affichage déjà annulé ou effacé
	Blt.s	.ResWS		<0: lancer ordre d'effacement
	* On annule l'affichage QUE si on est PAS en mode 5 win match !
*	Tst.w	GameMode
*	Bne.s	.DejaMec
	Move.w	#1,LevelInfoState	=0: Annulation affichage
	Bra.s	.DejaMec
.ResWS	* On ne donne l'ordre de restaurer que si on est pas en mode
	* 5 win match avant les 3 secondes
	Move.w	#3,LevelInfoState		-1: Restauration à FAIRE !	
.DejaMec
	Add.w	#1,NbJAct		Mecs sur l'écran

	Tst.w	Leg_TelePhase(A0)	Mec téléportation
	Bne	.AnimTele

	Move.w	#-1,Leg_OkBump(A0)	Autorisation de se faire "bumper"


	Clr.l	D0
	Clr.l	D1
	Move.w	Leg_VitJou(A0),D4
	Move.l	Leg_Joy(A0),A1	JoyStock
	Jsr	(A1)		D4:0 No Fire

	* Autofire désactivé ?	
	Tst.w	Leg_AutoFire(A0)
	Bne.s	.OnSenTap		AutoFire ON: on quitte cette partie		

	* Si on a la maladie de l'inversion, l'autofire est
	* réactivé pour ne pas créer de situations débiles.
	Tst.w	Leg_M1(A0)
	Bne.s	.OnSenTap

	* Si en mode autofire Off, mise en autofire On pour 
	* l'horloge.
	Tst.w	Leg_Horloge(A0)
	Bne.s	.OnSenTap
	
	* AutoFire OFF
	Move.b	Leg_FireAct(A0),D2		-> Ancien
	Move.b	D2,Leg_FireAnc(A0)
	Move.b	D4,Leg_FireAct(A0)		-> Actuel	
	Beq.s	.OnSenTap
	Eor.b	D2,D4
	Bra.s	.OnSen2
.OnSenTap	Clr.b	Leg_FireAct(A0)	<- Transitions AutoFire ON<->OFF
.OnSen2	Move.b	D4,Leg_Fire(A0)

	************ 
	* On ajoute la vitesse des tapis roulants à la vitesse actuelle
	* 
	*
*	Movem.l	D4/A1,-(A7)
*
*	Movea.l	Dim7,A1		Dalles
*	Move.w	(A1,D5.l),D4
*	Cmp.w	#Type_AntiMec,D4
**	Beq	.NoB
*	Cmp.w	#Type_AntiFeuMec,D4
*	Beq	.NoB*
*
*	Movem.l	(A7)+,D4/A1

	************

	* Si le joueur est éjecté par un bumper, on écrase les valeurs
	* recueillies (Mais on a besoin du fire ainsi que de la valeur
	* du joy pour ralentir la course)
	*

*	Tst.w	Leg_OkBump(A0)
*	Bne.s	.OkBJ
*	Clr.w	Leg_BumpX(A0)
*	Clr.w	Leg_BumpY(A0)
*	Bra.s	.NopBY1	

.OkBJ	Move.w	Leg_Ralent(A0),D2
	Dbf	D2,.NopR
	Move.w	#3,D2
.NopR	Move.w	D2,Leg_Ralent(A0)

	Move.w	Leg_BumpX(A0),D2
	Beq.s	.NopBX1

	Tst.w	D0
	Beq.s	.NoRal1
	Eor.w	D2,D0
	Bge.s	.NoRal1
	Tst.w	Leg_Ralent(A0)
	Bne.s	.NoRal1
	* Signe inverse joy <-> vitesse
	Tst.w	D2
	Bgt.s	.PlG
	Addq.w	#1,D2		
	Bra.s	.NoRal1
.PlG	Subq.w	#1,D2		
	* On ajoute BumpX a D0 si le signe est différent	
.NoRal1	Move.w	D2,D0
	Move.w	D0,Leg_BumpX(A0)
	Clr.w	D1
	Clr.w	Leg_BumpY(A0)
	Bra.s	.NopBY1

.NopBX1	Move.w	Leg_BumpY(A0),D2
	Beq.s	.NopBY1
	Tst.w	D1
	Beq.s	.NoRal2
	Eor.w	D2,D1
	Bge.s	.NoRal2
	Tst.w	Leg_Ralent(A0)
	Bne.s	.NoRal2
	* Signe inverse joy <-> vitesse
	Tst.w	D2
	Bgt.s	.PlG2
	Addq.w	#1,D2		
	Bra.s	.NoRal2
.PlG2	Subq.w	#1,D2		
	* On ajoute BumpY a D1 si le signe est différent	
.NoRal2	Move.w	D2,D1
	Move.w	D1,Leg_BumpY(A0)
	Clr.w	D0
	Clr.w	Leg_BumpX(A0)			
.NopBY1


	Tst.w	Leg_Activated(A0)	+1:écran  -1: activé
	Blt.s	.RienAct		<0: Déjà activé
	Tst.w	Leg_Fire(A0)	Attend relachement feu:pour pas poser de bombes par erreur en arrivant
	Beq	.NoLaF		On passe au joueur suivant...Mort
	Clr.w	Leg_Fire(A0)
	Bra.s	.NoMalInv
.NoLaF	Move.w	#-1,Leg_Activated(A0)	On a relaché: On a le droit de poser des bombes

.RienAct	Tst.w	Leg_M5(A0)	Maladie pose plus de bombes
	Beq.s	.NoMalPlB
	Clr.w	Leg_Fire(A0)	
.NoMalPlB	Tst.w	Leg_M9(A0)	Maladie collique: pose toutes bb
	Beq.s	.NoMalCol
	Move.b	#-1,Leg_Fire(A0)
.NoMalCol	Tst.w	Leg_M1(A0)	Maladie inversion
	Beq.s	.NoMalInv
	Not.b	Leg_Fire(A0)
	Tst.w	Leg_BumpX(A0)
	Bne.s	.NoMalInv
	Tst.w	Leg_BumpY(A0)
	Bne.s	.NoMalInv
	Neg.w	D0
	Neg.w	D1
.NoMalInv	Bsr	TestDir
	Bsr	ScreenPos
*	Bsr	TestFleche

	Tst.w	Leg_Fire(A0)
	Beq	.NoFire
	Move.w	Leg_NbF(A0),D4
	Addq.w	#1,D4	
	And.w	#$0003,D4	
	Move.w	D4,Leg_NbF(A0)
	Bne.s	.NoPos
	Tst.w	Leg_MaBomb(A0)
	Ble.s	.NoPos
	Tst.w	GameOver		Plus le droit de poser de bombes
	Bne.s	.NoPos		Si Game Over
	Bsr	PoseBombe
	Tst.l	D7		Bombe posée ?
	Beq.s	.NoPos
	Add.l	#1,Leg_BombesPosees(A0)
	Subq.w	#1,Leg_MaBomb(A0)
.NoPos	*Bsr	TestFleche
	Bsr	CentreJ
	Movem.w	D0/D1,DirJoue
	Bsr	TestFleche
	Bsr	TestMur		COLLISIONS
	Bsr	TestMalad		MALADIES
	Bsr	TestMort		MORT
	Tst.w	Leg_Mort(A0)
	Bgt	.AnimMort
	Blt	.Mort
	Tst.w	Leg_TelePhase(A0)
	Bne	.AnimTele
	Add.w	D0,Leg_X(A0)
	Add.w	D1,Leg_Y(A0)
	Movem.w	DirJoue,D0/D1	Récupération: on vire tapis roulant
	Bsr	CalcVue
	Move.w	D0,Leg_MDX(A0)
	Move.w	D1,Leg_MDY(A0)
.AnimCont	Move.w	Leg_X(A0),D0
	Move.w	Leg_Y(A0),D1
	Add.l	XAff,D0
	Add.l	YAff,D1
	Bsr	CalcMot
.Mort	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D3
	Cmp.w	#NbJoueurs,D3
	Blt	.LoopJ
	*************************	Vérif fin level
*	Movea.l	LegoPtr,A0
*	Clr.l	D3
*	Clr.w	D4
*	Clr.w	D5	
*	Moveq	#-1,D6
*.LoopJLA3	Move.w	D0,Leg_Im(A0)
*	Tst.w	Leg_Mort(A0)		Mecs vivants même équipe ?
*	Bne.s	.Mort2
*	Tst.w	Leg_Activated(A0)
*	Beq.s	.Mort2
*	Btst	#0,D3
*	Bne.s	.Eq1
*	Addq.w	#1,D4
*	Bra.s	.Mort2
*.Eq1	Addq.w	#1,D5
*.Mort2	Adda.w	#Leg_SizeOf,A0
*	Addq.w	#1,D3
*	Cmp.w	#NbJoueurs,D3
*	Blt.s	.LoopJLA3
	*********************

	*** nombre joueurs en vie <=1 OU joueurs vivants même équipe 
	Cmp.w	#1,PlayerMode	0:Individual
	Bne.s	.Indiv	
 	Tst.w	NbJEVEq2
	Beq.s	.GamOv
 	Tst.w	NbJEVEq1
	Bne.s	.Indiv
.GamOv	Move.w	#1,BombDGel	Dégeler les bombes
	Move.w	#-1,GameOver	
.Indiv	Clr.l	D0
	Move.w	NbJoueursEnVie,D0
	Cmp.w	#1,D0
	Bgt	.NoFinG
	Move.w	#1,BombDGel	Dégeler les bombes
	Move.w	#-1,GameOver	Plus qu'un joueur: plus le droit de poser des bombes
.NoFinG	*************************	Vérif changement 4<->8 joueurs


	Tst.w	RequestBeginLevel
	Beq.s	.NoBL
	Clr.w	RequestBeginLevel
	Tst.w	ModeAct
	Bgt.s	.f4to8
	Bra.s	.f8to4

.NoBL	Move.w	NbCreated,D0	J'utilise ModeAct...
	Cmp.w	#4,D0
	Bgt.s	.8j
	Tst.w	ModeAct
	Beq.s	.NoChang
	Move.w	#0,ModeAct	Mode 4 joueurs (ModeAct=0) 
	Bra.s	.Change

.8j	Tst.w	ModeAct
	Bne.s	.NoChang	
	Move.w	#8,ModeAct	Mode 8 joueurs (ModeAct>0) 
	
.Change	Move.l	A4,-(A7)
	Bsr	DefWhichBar
	Move.l	(A7)+,A4
	Move.w	#1,RequestForNewBar
*	Cmp.w	#4,NbJAct
	Cmp.w	#4,NbCreated
	Bgt.s	.f4to8
	Bra.s	.NoChang	ON NE PEUT PAS FAIRE 8->4
.f8to4	******* En effet, il faudrait COMPACTER les joueurs !!!!!
	* ou au moins intervertir TOUTES LES STRUCTURES !!!!!!
	* en Realtime je suppute un travail un peu chiant.
	Bsr	PosTo4
	Clr.w	ModeAct		Mode 4 joueurs
	Move.w	#%0000000001010101,BplCon4	Palette sprites 15-31 de la banque 5 de 16 couleurs
	Jsr	MAgiXPalette
	Bra.s	.NoChang	
	***
	
.f4to8	Bsr	PosTo8
	Move.w	#8,ModeAct	Mode 8 joueurs (ModeAct>0) 
	Move.w	#%0000000011101111,BplCon4	xxxx(pair)-xxxx(impair)
	Jsr	MAgiXPalette
.NoChang	*************************
	*Move.w	#%0000000001110110,BplCon3	Palette sprites

	***** Compter le nombre de joueurs en VIE !!!
	Clr.w	NbJoueursEnVie
	Clr.w	NbJAct
	Move.l	LegoPtr,A0
	Clr.l	D2		
.LoopJMA2	Tst.w	Leg_Mort(A0)
	Bne.s	.DjM2	
	Add.w	#1,NbJoueursEnVie
	Tst.w	Leg_Activated(A0)
	Beq.s	.DjM2
	Add.w	#1,NbJAct
.DjM2	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D2
	Cmp.w	#NbJoueurs,D2
	Blt.s	.LoopJMA2
	Move.w	NBJAct,D2
	Move.w	D2,NbJAct2
	Cmp.w	NBJActMax,D2
	Blt.s	.OkMJA
	Move.w	D2,NbJActMax
.OkMJA	RTS

.NoFire	Move.w	#-1,Leg_NbF(A0)

	Tst.w	Leg_Horloge(A0)
	Beq.s	.NoH3
	Move.l	Leg_HMem(A0),A1
	Tst.l	A1
	Beq.s	.NoH3
	* On a lâché le bouton, et on a l'horloge, et une bombe
	* était bloquée à cause de ça, donc on la libère
	Clr.w	Bomb_Horloge(A1)
	Clr.l	Bomb_JMem(A1)
	Move.w	#BombImL,Bomb_Im(A1)
	Clr.l	Leg_HMem(A0)
.NoH3	Bra	.NoPos

	****** Le lego est en train de mourrir: nouvelle image
	*
	*
.AnimMort	Move.w	Leg_Mort(A0),D4
	Addq.w	#1,D4
	Move.w	D4,Leg_Mort(A0)
	Move.w	D4,Leg_Im(A0)
	Cmp.w	#ImFinMortFl,D4
	Beq.s	.NewMort
	Cmp.w	#ImFinMortEcr,D4
	Bne	.NoNewMor
.NewMort	Move.w	#-1,Leg_Mort(A0)	Il a finit de mourrir

	Movem.l	D0-D3/A0,-(A7)
	Move.w	Leg_BarreX(A0),D3		On trace le mec mort
	Move.w	Leg_BarreY(A0),D4
	Move.w	Leg_BarreBase(A0),D5	Content, dort, >triste<
	Addq.w	#2,D5
	Bsr	Bloc32x16cop
	Move.w	Leg_BarreBlocX(A0),D3
	Move.w	Leg_BarreY(A0),D4
	Moveq	#15,D5		Croix : Mec mort....
	Bsr	Bloc32x16cop	
	Movem.l	(A7)+,D0-D3/A0

************ 
* On teste le temps depuis le début du level: Si il est trop court,
* on recommence le level (Max 1 fois, quel que soit le joueur).
* Le mieux serait max 1 fois par joueur, mais bon.... faut finir le jeu
* un jour ou l'autre. C'EST FAIT !!! MAX UNE FOIS PAR JOUEUR !!!! :-)
*	
	********************	Message écran bois
	Movem.l	D0-D3/A0,-(A7)
	*Tst.w	GameOver	
	*Bne	.NoNoMove		Seulement si pas dernier joueur

	Move.w	NbJAct2,D0
	Cmp.w	#1,D0
	Blt	.NoNoMove

	***** SURVIVOR MODE
	Tst.w	SurvivorMode
	Beq.s	.NoSurviv

	Move.w	NbJAct2,D0
	Cmp.w	#1,D0
	Ble	.NoNoMove

	Bsr	BClearBois
	Move.w	#0,D0		X de début centrage
	Move.w	#5,D1
	Movea.l	FTinyTxt8,A0
	Lea	Phrase_Survivor,A1
	Move.w	#320,D3		Largeur écran
	Bsr	CenterX
	Jsr	AffichePhraseBarre2	(D0-D1/A0-A1) "DONT'T MOVE"
	Jsr	Set4
	Move.l	#TimeBarreDONTMOVE,BarreDecounter
	Bra.s	.SurvCont
	*****
.NoSurviv	Move.w	Leg_DontMove(A0),D0
	Cmp.w	#1,D0
	Bgt	.NoNoMove		Déjà mort une fois !!!
	****
	Move.l	LevelAct,A6
	Move.l	Level_Time1(A6),D1	Vérifier alert time existe	
	Move.l	Level_Time2(A6),D0	   Temps total du level
	Cmp.l	D1,D0
	Ble.s	.NoAlert
	Tst.l	TimeLvl1		Alerte possible: eu lieu ?
	Ble	.NoNoMove		Oui:on n'autorise pas de recommencer
.NoAlert	Sub.l	TimeLvl2,D0	Temps restant
	* Temps total-Temps restant = Temps utilisé
	Divs.l	#Seconde,D0	Nombre de secondes écoulées
	Cmp.l	#TimeDontMoveMax,D0
	Bgt.s	.NoNoMove
	Bsr	BClearBois
	Move.w	#0,D0		X de début centrage
	Move.w	#5,D1
	Movea.l	FTinyTxt8,A0
	Lea	Phrase_DontMove,A1
	Move.w	#320,D3		Largeur écran
	Bsr	CenterX
	Jsr	AffichePhraseBarre2	(D0-D1/A0-A1) "DONT'T MOVE"
	Jsr	Set4
	Move.l	#TimeBarreDONTMOVE,BarreDecounter
.SurvCont	*********	BRUIT Don't Move
	Movem.l	A0-A1/D1/D3-D5,-(A7)
	Moveq	#19,D3
	Moveq	#PriSonDontMove,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,A0-A1/D1/D3-D5
	*********
	Move.w	#3,WinnersPhase	
	Clr.w	ExeSprite
	Clr.w	NewLevel		Pas de nouveau level
	Clr.w	TypTouche		=0: Pas de regénération pour random
	Move.w	#-1,RequestForNewLevel
.NoNoMove	Movem.l	(A7)+,D0-D3/A0
	********************


.NoNewMor	Bra	.AnimCont


	******** Le Lego est en cours d'animation de "Winning"
	*
	*
.AnimEnd	Bsr	OuaitLent
	Tst.w	Leg_Time(A0)
	Bne	.AnimCont
	Move.w	Leg_Im(A0),D4
	Cmp.w	#ImFinFin1,D4
	Beq.s	.StopAn1
	Cmp.w	#ImFinFin2,D4
	Beq.s	.StopAn2
	Cmp.w	#ImFinFin3,D4
	Beq.s	.StopAn3
	Cmp.w	#ImFinFin4,D4
	Beq.s	.StopAn4
	Cmp.w	#ImFinFin5,D4
	Beq.s	.StopAn5
	Cmp.w	#ImFinFin6,D4
	Beq.s	.StopAn6
	Addq.w	#1,D4
.LoopAn	Move.w	D4,Leg_Im(A0)
	Bra	.AnimCont

	* Dorénavant les animations sont bouclées !!!
.StopAn1	Move.w	#ImDebFin1+3,D4	ImDebFin
	Bra.s	.LoopAn
.StopAn2	Move.w	#ImFinFin2-2,D4
	Bra.s	.LoopAn
.StopAn3	Move.w	#ImFinFin3-3,D4
	Bra.s	.LoopAn
.StopAn4	Move.w	#ImFinFin4-3,D4
	Bra.s	.LoopAn
.StopAn5	Move.w	#ImFinFin5,D4
	Bra.s	.LoopAn
.StopAn6	Move.w	#ImFinFin6,D4
	Bra.s	.LoopAn
	
	******** Le Lego est en train de se téléporter
	*
	*
.AnimTele
	Move.w	Leg_Tele(A0),D4		Image actuelle
	Add.w	Leg_TelePhase(A0),D4	Sens (Départ=1/Arrivée=-1)
	Move.w	D4,Leg_Im(A0)
	Move.w	D4,Leg_Tele(A0)
	Cmp.w	#ImDebTele,D4
	Bne.s	.NoIDeb
	* On a fini la téléportation entière
	Move.w	#33,Leg_Im(A0)
	Clr.w	Leg_MDX(A0)
	Clr.w	Leg_MDY(A0)
	Clr.w	Leg_TelePhase(A0)	
	Bra	.AnimCont
.NoIDeb
	Cmp.w	#ImFinTele,D4
	Bne.s	.NoIFin	
	* On a fini la disparition
	Clr.w	Leg_ImBl(A0)
	Move.w	#-1,Leg_TelePhase(A0)
	Move.w	Leg_TeleX(A0),Leg_X(A0)
	Move.w	Leg_TeleY(A0),Leg_Y(A0)
	Move.w	#1,Leg_ForceCentre(A0)		
	Movem.l	D1/D3,-(A7)	Bruit téléportation
	Moveq	#3,D3
	Moveq	#PriSonTele,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3
.NoIFin	Bra	.AnimCont


	******** Le Mec n'est pas encore activé. On attend le fire
	*
	*
.NotActive
	* D3: N° Du joueur  
	Lea	PlayersSet,A1
	Tst.b	(A1,D3.w)
	Beq	.NoNewsA

	* Joueur déjà défini ("SET ON")
	* Cela sert par exemple au 2ème round, quand on ne réassigne
	* pas les joueurs mais que l'on attend quand même qu'ils 
	* appuyent sur "feu"

	Move.w	Leg_VitJou(A0),D4
	Move.l	Leg_Joy(A0),A1	On teste le feu
	Jsr	(A1)		Retour D4:Feu
	Move.w	Leg_FireRequest(A0),D5
	Ble.s	.NoFRq	
	Subq.w	#1,D5
	Move.w	D5,Leg_FireRequest(A0)	
	Bgt.s	.NoFRq
	Clr.w	Leg_FireRequest(A0)	
	Move.w	#1,D4
.NoFRq	Move.b	D4,Leg_Fire(A0)
	Tst.w	Leg_Fire(A0)
	Beq	.NoNewsA

	*** Le mec vient d'appuyer sur FEU
	
	Add.l	#1,Leg_GamesPlayedT(A0)	Nombre de parties jouées	

	* On affiche le nombre de victoires du mec	
	Bsr	AfficheVictoires

	* On affiche la gueule du mec dans la barre.... Mec content
	Movem.l	D3-D5,-(A7)
	Move.w	Leg_BarreX(A0),D3
	Move.w	Leg_BarreY(A0),D4
	Move.w	Leg_BarreBase(A0),D5	>Content<, dort, triste
	Bsr	Bloc32x16cop	

	Move.w	Leg_BarreBlocX(A0),D3
	Move.w	Leg_BarreY(A0),D4
	Moveq	#16,D5		Vide: mec vivant
	Bsr	Bloc32x16cop

	Movem.l	(A7)+,D3-D5	

	Bset	#0,JActivated	Premier joueur à apparaître ???	
	Bne.s	.NopZAv
	Tst.w	ExeLevel		Oui:
	Bne.s	.NopZAv
	Move.w	#-1,RequestForClearBois
	Move.w	#-1,ExeLevel	Première apparition: Level timer ON
	Move.l	#1,BarreDecounter
	
	
.NopZAv	Move.w	#1,Leg_Activated(A0)	Lego activé en attente
	Clr.w	Leg_ImBl(A0)		relâchement feu
	Movem.l	D1/D3,-(A7)	Bruit téléportation
	Moveq	#3,D3
	Moveq	#PriSonTeleDeb,D1	Priorité son
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3
.NoNewsA	Bra	.Mort

******** Trier les joueurs
*
* Ce tri marche suivant la technique du remplissage des valeurs max :
* on cherche le max, et on met en pos N, puis le max en N-1 etc...
* Comme ca on fait un swap pour positionner correctement un nombre
*
*
Trier	Movea.l	LegoPtr,A1
	Lea	Tri,A2		Tri par bulle indexé

	************************
	Clr.l	D0
	Movea.l	A2,A4
	Lea	PlayersSet,A3
.Boucle0	Move.w	D0,D1		Joueur mort ?
	Mulu.w	#Leg_SIZEOF,D1
	Move.l	LegoPtr,A5
	Lea	(A5,D1.w),A5
	Tst.w	Leg_Mort(A5)
	Blt.s	.noa
	Tst.b	(A3,D0.w)		Joueur activé ?
	Beq.s	.Noa	
	Move.w	D0,(A4)+		On ajoute le joueur...
	Bra.s	.s2
.noa	Move.w	#-1,(A4)+		Joueur non activé ou mort
.s2	Addq.w	#1,D0
	Cmp.w	#NbJoueurs,D0
	Blt.s	.Boucle0

	************************	DEBUT DU TRI
	Moveq	#NbJoueurs-1,D4
.boucle2	Move.w	D4,D0
	Move.w	#-1,D3
	Move.w	#0,D1	-50
	
	***********	BOUCLE POUR CHERCHER LE Y MAX
.boucle1	Move.w	(A2,D0.w*2),D2	prendre le N° de D2 dans le tri
	Bge.s	.Oks
	Move.w	D0,D3	
	Bra.s	.OkSwap
.Oks	Mulu.w	#Leg_SizeOf,D2
	Move.w	Leg_Y(A1,D2.w),D7	On cherche chaque Y pour le comparer au MAX
	Cmp.w	D7,D1		prendre le Y du N°
	Bgt.s	.no
	Move.w	D7,D1		D1=MAX(Y)
	Move.w	D0,D3		N° en mémoire du plus grand Y
.no	Dbf	D0,.boucle1	******* BOUCLE 1
	***
	Cmp.w	#-1,D3		Pas de swap si MAX=Dernière pos
	Beq.s	.noswap		ou si pas de max trouvé
.OkSwap	Move.w	D4,D5
	Add.w	D5,D5
	Add.w	D3,D3
	Move.w	(A2,D3.w),D6	Swap A2(D3,D5)
	Move.w	(A2,D5.w),(A2,D3.w)
	Move.w	D6,(A2,D5.w)
.noswap	Subq.l	#1,D4		Remplissage de la fin au début
	Bgt.s	.boucle2
	Rts

*********	Parcourir le tableau trié et assigner les sprites
*	POUR 4 SPRITES
*
*
* Les derniers sprites sont les plus bas en Y
* Les plus bas sont de priorité supérieure.
* 
*
TriJou	
	****
	Move.l	CopAdrSprite0,A0
	CopInitSprites
	****

	Tst.w	ModeAct
	Bgt.s	TriJou8
	***
	Moveq.l	#NbJoueurs-1,D5
	Lea	Tri,A0			Trier les joueurs
	Movea.l	LegoPtr,A1
	Moveq	#6,D3	N°Sprite
.New	Move.w	(A0)+,D4			!!! (A0)+ OU -(A0) !!!
	Blt.s	.Mort3		Mettre à 0 les mauvais sprites
	Mulu.w	#Leg_SizeOf,D4
	Lea	(A1,D4.w),A2	Pointeur structure Lego
	Move.w	Leg_Im(A2),D2
	*********
	Cmp.w	#NbImsParSprite,D2		Tests bords (antibug)
	Ble.s	.Ok1
	Move.w	#NbImsParSprite,D2
	Bra.s	.Ok2
.Ok1	Tst.w	D2
	Bge.s	.Ok2
	Clr.w	D2
.Ok2	******
	Add.w	Leg_ImBase(A2),D2
	Add.w	Leg_ImBl(A2),D2	
.Mort	Bsr	Jour
.Mort2	Subq.w	#2,D3
	Blt.s	.Err
.Mort3	Dbf	D5,.New

.Loop	Tst.w	D3	* pour les sprites inutilisés
	Blt.s	.Err		
	Bsr	JourInit
	Subq.w	#2,D3
	Bra.s	.Loop

.Err	RTS



*********	Parcourir le tableau trié et assigner les sprites
*	POUR 8 SPRITES
*
*
*
*
TriJou8	Moveq	#NbJoueurs-1,D5
	Lea	Tri,A0			Trier les joueurs
	Movea.l	LegoPtr,A1
	Moveq	#7,D3	N°Sprite
.New	Move.w	(A0)+,D4
	Blt.s	.Mort	Pour mettre à 0 les autres sprites: Mort3
	Mulu.w	#Leg_SizeOf,D4
	Lea	(A1,D4.w),A2	Pointeur structure Lego
	Move.w	Leg_Im(A2),D2
	Add.w	Leg_ImBase(A2),D2
	Add.w	Leg_ImBl(A2),D2	
.Mort3	Bsr	Jour8		SPRITE
.Mort2	Subq.w	#1,D3
	Blt.s	.Err
.Mort	Dbf	D5,.New

.Loop	Tst.w	D3	* pour les sprites inutilisés
	Blt.s	.Err		
	Bsr	JourInit8
	Subq.w	#1,D3
	Bra.s	.Loop

.Err	RTS


	************* Juste mettre à jour la palette des 8 sprites 
	*	Routine séparée pour pouvoir faire cela avec une
	*	VBL de temporisation.
	*
TriJou8PAL
	*Cmp.w	#4,NbJAct
	Tst.w	ModeAct
	Bgt.s	.Ok
	RTS
.Ok	Moveq	#NbJoueurs-1,D5
	Lea	Tri,A0			Trier les joueurs
	Moveq	#7,D3	N°Sprite
.New	Move.w	(A0)+,D1
	Blt.s	.Mort		Mort3
	Movem.l	D3/D5/A0,-(A7)	PALETTE
	Move.w	D3,D0
	Jsr	MakeSprPal	(D0=Sprite,D1=Joueur)	
	Movem.l	(A7)+,D3/D5/A0
.Mort3	Subq.w	#1,D3
	Blt.s	.Err
.Mort	Dbf	D5,.New
.Err	RTS




*******************************   Routines de mise à jour des sprites
*			    DANS LA COPPER LIST EN COURS DE ROUTE !!!
*			POUR 4 SPRITES
* => D2: N° de l'image
*    D3: N° du sprite de base (0,2,4,6)
*
* travail: A0-A4,D1,D2,D3,D4
* 
*
*
Jour	Movem.l	A0-A4/D1-D4,-(A7)

	Lsl.w	#2,D3
	Lea	CopAdrSprite0,A3	
	Lea	Rien,A1
	Clr.l	Rien
	Move.l	A1,D1
	
	Tst.w	Leg_Mort(A2)	
	Blt.s	.Mort
	Tst.w	Leg_Activated(A2)
	Beq.s	.Mort
	***	
	Move.l	AdrIndex,A2
	Ext.l	D2
	Lsl.l	#3,D2		
	Move.l	AdrSprites,A1
	Adda.l	(A2,D2.l),A1	
	Move.l	A1,D1

	Move.l	AdrSprites,A1
	Adda.l	4(A2,D2.l),A1
	***
.Mort
	*
	Move.l	(A3,D3.w),A0	
	Move.w	D3,D4		Modifier la copperlist
	Add.w	#$122,D4
	CopMove	D1,D4	Valeur,adresse
	Swap	D1
	Subq.w	#2,D4
	CopMove	D1,D4
	*
	*
	Move.l	A1,D1
	Addq.w	#4,D3	On ajoute 4 pour passer au sprite suivant (1-3-5-7)
	Move.l	(A3,D3.w),A0	On récupére l'adresse dans la copperlist
	Move.w	D3,D4		
	Add.w	#$122,D4
	CopMove	D1,D4
	Swap	D1
	Subq.w	#2,D4
	CopMove	D1,D4
	*
	Movem.l	(A7)+,A0-A4/D1-D4
	Rts




*******************************   Routines de mise à jour des sprites
*			    DANS LA COPPER LIST EN COURS DE ROUTE !!!
*			POUR 8 SPRITES
* => D2: N° de l'image
*    D3: N° du sprite (0,1,2,3,4,5,6,7)
*
* travail: A0-A4,D1,D2,D3,D4
* 
*
*
Jour8	Movem.l	A0-A4/D1-D4,-(A7)

	Lsl.w	#2,D3
	Lea	CopAdrSprite0,A3	
	Lea	Rien,A1
	Clr.l	Rien
	Move.l	A1,D1
	
	Tst.w	Leg_Mort(A2)	
	Blt.s	.Mort
	Tst.w	Leg_Activated(A2)
	Beq.s	.Mort
	***	
	Move.l	AdrIndex8,A2
	Ext.l	D2
	Lsl.l	#2,D2		*4 pour 1 image/sprite	
	Move.l	AdrSprites8,A1
	Adda.l	(A2,D2.l),A1	
	Move.l	A1,D1		D1: Adresse du sprite en chip
.Mort
	*
	Move.l	(A3,D3.w),A0	Adresse dans la copperliste
	Move.w	D3,D4		Modifier la copperlist
	Add.w	#$122,D4
	CopMove	D1,D4	Valeur,adresse
	Swap	D1
	Subq.w	#2,D4
	CopMove	D1,D4
	*
	Movem.l	(A7)+,A0-A4/D1-D4
	Rts



JourInit8	Movem.l	D1/D3/A0-A1/A3,-(A7)
	Lsl.w	#2,D3
	Lea	CopAdrSprite0,A3	
	Lea	Rien,A1
	Clr.l	Rien
	Move.l	A1,D1
	Move.l	(A3,D3.w),A0	
	Add.w	#$122,D3
	CopMove	D1,D3	Valeur,adresse
	Swap	D1
	Subq.w	#2,D3
	CopMove	D1,D3
	Movem.l	(A7)+,D1/D3/A0-A1/A3
	Rts

JourInit	Movem.l	D1/D3-D4/A0-A1/A3,-(A7)
	Lsl.w	#2,D3
	Lea	CopAdrSprite0,A3	
	Lea	Rien,A1
	Clr.l	Rien
	Move.l	A1,D1
	Move.l	(A3,D3.w),A0	
	Add.w	#$122,D3
	Move.w	D3,D4
	Addq.w	#4,D4
	CopMove	D1,D3	Valeur,adresse
	CopMove	D1,D4
	Swap	D1
	Subq.w	#2,D3
	Subq.w	#2,D4
	CopMove	D1,D3
	CopMove	D1,D4
	Movem.l	(A7)+,D1/D3-D4/A0-A1/A3
	Rts




*****	Calcul des mots de contrôle des sprites
*	pour 4 sprites de 16 couleurs !!!
*
*	A0: Structure joueur
*	   D0: X
*	   D1: Y
*
CalcMot	*Cmp.w	#4,NbJAct2	NbJAct2	>4 joueurs: 8 sprites non attachés
	Tst.w	ModeAct
	Bgt.s	CalcMot8
	***
	Move.l	d3,-(A7)
	Move.w	d0,d3 
	And.w	#1,d3  
	Lsr.w	#1,D0
	Move.w	d0,d4 
	And.w	#$FF,d4
	Move.w	d1,d0
	Add.w	#27-5+2,d0 	Ajouter la hauteur
	Asl.w	#8,d1
	Bcc	.noE8
	Bset	#2,d3   
.noE8	Or.w	d1,d4            
	Asl.w	#8,d0
	Bcc	.noL8               
	Bset	#1,d3
.noL8	Or.w	d0,d3   
	Bset	#7,D3		Sprites liés : 16 couleurs
	Move.l	AdrIndex,A1
	Clr.l	D1
	Move.w	Leg_Im(A0),D1
	Add.w	Leg_ImBase(A0),D1
	Add.w	Leg_ImBl(A0),D1	
	Lsl.l	#3,D1			
	Move.l	AdrSprites,A2	Mêmes mots de contrôle
	Adda.l	(A1,D1.l),A2	pour les 2 sprites en mode
	Move.w	D4,(A2)+		attaché
	Move.w	D3,(A2)
	Move.l	AdrSprites,A2
	Adda.l	4(A1,D1.l),A2
	Move.w	D4,(A2)+
	Move.w	D3,(A2)
	Move.l	(A7)+,d3
	RTS

*****	Calcul des mots de contrôle des sprites
*	pour 8 sprites de 3 couleurs !!!
*
*	A0: Structure joueur
*	   D0: X
*	   D1: Y
*
CalcMot8	Move.l	D3,-(A7)
	Move.w	d0,d3 
	And.w	#1,d3  
	Lsr.w	#1,D0
	Move.w	d0,d4 
	And.w	#$FF,d4
	Move.w	d1,d0
	Add.w	#27-5+2,d0 	Ajouter la hauteur
	Asl.w	#8,d1
	Bcc	.noE8
	Bset	#2,d3   
.noE8	Or.w	d1,d4            
	Asl.w	#8,d0
	Bcc	.noL8               
	Bset	#1,d3
.noL8	Or.w	d0,d3   
	Move.l	AdrIndex8,A1
	Clr.l	D1
	Move.w	Leg_Im(A0),D1
	Add.w	Leg_ImBase(A0),D1
	Add.w	Leg_ImBl(A0),D1	
	Lsl.l	#2,D1		*4 seulement pour 1 image/sprite			
	Move.l	AdrSprites8,A2	8 sprites...
	Adda.l	(A1,D1.l),A2	ECRITURE DES MOTS DE CONTROLE
	Move.w	D4,(A2)+		Dans les sprites même
	Move.w	D3,(A2)
	Move.l	(A7)+,D3
	RTS


*************************	ROUTINES COMMUNES A TOUS LES JOUEURS

Ouait	*Move.l	D2,-(A7)
	Move.w	Leg_Time(A0),D2
	Addq.w	#1,D2
	Cmp.w	#TimeAnim,D2
	Bne.s	.Ok	
	Move.w	#0,Leg_Time(A0)
	Bra.s	.End
.Ok	Move.w	D2,Leg_Time(A0)
.End	*Move.l	(A7)+,D2
	Rts

OuaitLent	Move.l	D2,-(A7)
	Move.w	Leg_Time(A0),D2
	Addq.w	#1,D2
	Cmp.w	#TimeAnimLent,D2
	Bne.s	.Ok	
	Move.w	#0,Leg_Time(A0)
	Bra.s	.End
.Ok	Move.w	D2,Leg_Time(A0)
.End	Move.l	(A7)+,D2
	Rts

	
***************		Interdiction de diagonale
*			avec priorité de direction=Direction(T-1)
TestDir	Tst.w	D0
	Beq.s	.FinX	
	Tst.w	Leg_MDX(A0)
	Bne.s	.MvX
	Tst.w	D1
	Bne.s	.FinX		 MX= (my+MX2).MX
.MvX	Clr.l	D1
.FinX	Tst.w	D1	
	Beq.s	.FinY
.MvY	Clr.l	D0
.FinY	RTS	

***************		Calcul de la vue du sprite
CalcVue
	Move.w	Leg_VitJou(A0),D4
	Move.w	Leg_BumpX(A0),D6		Si bump, vitesse <>
	Beq.s	.NoSp1
	Bgt.s	.OkSgn1	
	Neg.w	D6
.OkSgn1	Move.w	D6,D4		
.NoSp1	Move.w	Leg_BumpY(A0),D6
	Beq.s	.NoSp2
	Bgt.s	.OkSgn2	
	Neg.w	D6
.OkSgn2	Move.w	D6,D4			
.NoSp2
	Tst.w	D0
	Beq	.pash
	Tst.w	D0
	Bgt.s	.Droite
*	Cmp.w	D4,D0		Test même direction		
*	Beq.s	.droite		
*	Cmp.w	Leg_MDX(A0),D0		GAUCHE
*	Bne.s	.newdirg
	Tst.w	Leg_MDX(A0)
	Bge.s	.newdirg
	Bsr	ouait
	Bne	.fvue
	Addq.w	#1,Leg_Im(A0)
	Cmp.w	#24,Leg_Im(A0)
	Bne	.fvue
	Move.w	#16,Leg_Im(A0)
	Bra	.fvue
.newdirg	Move.w	#16,Leg_Im(A0)
	Move.w	#TimeAnim-1,Leg_Time(A0)
	Bra	.fvue
.droite	*Cmp.w	Leg_MDX(A0),D0		DROITE
	*Bne.s	.newdird
	Tst.w	Leg_MDX(A0)
	Ble.s	.newdird
	Bsr	ouait
	Bne	.fvue
	Addq.w	#1,Leg_Im(A0)
	Cmp.w	#8,Leg_Im(A0)
	Bne	.fvue
	Move.w	#0,Leg_Im(A0)
	Bra	.fvue
.newdird	Move.w	#0,Leg_Im(A0)
	Move.w	#TimeAnim-1,Leg_Time(A0)
	Bra	.fvue
.pash	Tst.w	D1
	Beq	.pasv
	*Tst.w	D1
	*Bgt.s	.bas
	Cmp.w	D4,D1
	Beq.s	.bas
	Cmp.w	Leg_MDY(A0),D1		HAUT
	Bne.s	.newdirh
	*Tst.w	Leg_MDY(A0)
	*Bge.s	.newdirh
	Bsr	ouait
	Bne	.fvue
	Addq.w	#1,Leg_Im(A0)
	Cmp.w	#32,Leg_Im(A0)
	Bne	.fvue
	Move.w	#24,Leg_Im(A0)
	Bra	.fvue
.newdirh	Move.w	#24,Leg_Im(A0)
	Move.w	#TimeAnim-1,Leg_Time(A0)
	Bra	.fvue
.bas	Cmp.w	Leg_MDY(A0),D1		BAS
	Bne.s	.newdirb
	*Tst.w	Leg_MDY(A0)
	*Ble.s	.newdirb
	Bsr	ouait
	Bne	.fvue
	Addq.w	#1,Leg_Im(A0)
	Cmp.w	#16,Leg_Im(A0)
	Bne.s	.fvue
	Move.w	#8,Leg_Im(A0)
	Bra.s	.fvue
.newdirb	Move.w	#8,Leg_Im(A0)
	Move.w	#TimeAnim-1,Leg_Time(A0)
	Bra.s	.fvue
.pasv	Move.l	DirJoue,D6
	Beq.s	.Nopd1
	Move.w	D6,Leg_MDY(A0)
	Clr.w	Leg_MDX(A0)
.Nopd1	Swap	D6
	Tst.w	D6
	Beq.s	.Nopd2
	Move.w	D6,Leg_MDX(A0)
	Clr.w	Leg_MDY(A0)
.Nopd2
	Tst.w	Leg_MDX(A0)		ARRET
	Bne.s	.newarX
	Tst.w	Leg_MDY(A0)
	Bne.s	.newarY
	Bra.s	.fvue	
.newarx	Cmp.w	 Leg_MDX(A0),D4		
	Beq.s	.ardro
	Move.w	#34,Leg_Im(A0)
	Bra.s	.fvue	
.ardro	Move.w	#32,Leg_Im(A0)
	Bra.s	.fvue
.newary	Cmp.w	Leg_MDY(A0),D4
	Beq.s	.arbas
	Move.w	#35,Leg_Im(A0)
	Bra.s	.fvue
.arbas	Move.w	#33,Leg_Im(A0)
.fvue	
	*** On a la vue du sprite: on teste si il est blanc ou non
	Tst.w	Leg_M7(A0)
	Beq.s	.NoM7
	Clr.w	Leg_ImBl(A0)	Par défaut: image normale
	Move.w	Leg_M7Mem(A0),D6
	Dbf	D6,.NoZM7

	Tst.w	Leg_Mort(A0)	Mort ou en train de mourir
	Bne.s	.NopM7
	Tst.w	WinnersPhase	En train de gagner
	Bne.s	.NopM7
	Tst.w	Leg_TelePhase(A0)	En train de téléporter
	Bne.s	.NopM7	

	Move.w	#36,Leg_ImBl(A0)	<-- Décalage images mouvements
.NopM7	Move.w	#Time_Clignote_Invincible,D6
.NoZM7	Move.w	D6,Leg_M7Mem(A0)
.NoM7	RTS


****************		Routine joystick de base (ports 0 & 1)
Joy	btst	#1,D2		Test Droite
	beq.s	.pasd
	Move.w	D4,D0
	bra.s	.finhor
.pasd	btst	#9,D2		Test Gauche
	beq.s	.pasg
	Move.w	D4,D0
	Neg.w	D0
	bra.s	.finhor
.pasg	Move.w	#0,D0	
.finhor	Move.w	D2,D5
	lsr.w	#1,D5
	eor.w	D2,D5
	btst	#0,D5		Test Bas
	beq.s	.pasb	
	Move.w	D4,D1		
	bra.s	.finvert
.pasb	btst	#8,D5		Test Haut
	beq.s	.pash
	Move.w	D4,D1
	Neg.w	D1
	bra.s	.finvert	
.pash	move.w	#0,D1	
.finvert	RTS

***************

Joy1	Move.w	Joy1Dat,D2	Joystick 1
	Bsr	Joy
	Clr.l	D4
	Btst	#7,$bfe001
	Seq	D4
	RTS

***************

Joy0	Move.w	Joy0Dat,D2	Joystick 0
	Bsr	Joy
	Clr.l	D4
	Btst	#6,$bfe001
	Seq	D4
	RTS

Joy0Menu	Clr.l	D0	Pas de souris dans les menus
	Clr.l	D1
	Btst	#6,$bfe001
	Seq	D4
	RTS

*************** 	Routine joystick pour le doubleur

Joy3	Move.b	$BFE101,D2
	Move.b	$BFD000,D5
	btst	#3,D2		Test droite
	bne.s	.pasd	
	Move.w	D4,D0
	bra.s	.finhor	
.pasd	btst	#2,D2		Test gauche
	bne.s	.pasg
	Move.w	D4,D0
	Neg.w	D0
	bra.s	.finhor
.pasg	Move.w	#0,D0
.finhor	btst	#1,D2		Test bas
	bne.s	.pasb
	Move.w	D4,D1
	bra.s	.finvert
.pasb	btst	#0,D2		Test haut
	bne.s	.pash
	Move.w	D4,D1
	Neg.w	D1
	bra.s	.finvert
.pash	Move.w	#0,D1
.finvert	Clr.l	D4
	Btst	#2,D5
	Seq	D4
	
	Clr.w	D0		Désactivation du Joy3
	Clr.w	D1
	Clr.w	D4
	
	RTS

********************

Joy4	Move.b	$BFE101,D2
	Move.b	$BFD000,D5
	btst	#7,D2		Test droite
	bne.s	.pasd	
	Move.w	D4,D0
	bra.s	.finhor	
.pasd	btst	#6,D2		Test gauche
	bne.s	.pasg
	Move.w	D4,D0
	Neg.w	D0
	bra.s	.finhor
.pasg	Move.w	#0,D0
.finhor	btst	#5,D2		Test bas
	bne.s	.pasb
	Move.w	D4,D1
	bra.s	.finvert
.pasb	btst	#4,D2		Test haut
	bne.s	.pash
	Move.w	D4,D1
	Neg.w	D1
	bra.s	.finvert
.pash	Move.w	#0,D1
.finvert	Clr.l	D4
	Btst	#0,D5
	Seq	D4

	Clr.w	D0		Désactivation du Joy4
	Clr.w	D1
	Clr.w	D4

	RTS

***********************	Ce clavier est prévu pour UN joueur au clavier
*			Dès son choix, on désactive le 2 et le 3

Clavier1	Movea.l	ClavierPtr,A1	Touches de direction
	Clr.l	D0
	Clr.l	D1
	Tst.b	78(A1)		Droite
	Beq.s	.NoDr
	Move.w	D4,D0
.NoDr	Tst.b	79(A1)		Gauche
	Beq.s	.NoGa
	Move.w	D4,D0
	Neg.w	D0
.NoGa	Tst.b	77(A1)		Bas
	Beq.s	.NoBa
	Move.w	D4,D1
.NoBa	Tst.b	76(A1)		Haut
	Beq.s	.NoHa
	Move.w	D4,D1
	Neg.w	D1
.NoHa	Clr.l	D4
	Tst.b	101(A1)		Feu: RAlt
	Sne	D4			
	RTS

*********
*

Clavier1Menu * Clavier spécial pour les menus
	Movea.l	ClavierPtr,A1	Touches de direction
	Clr.l	D0
	Clr.l	D1
	Tst.b	78(A1)		Droite
	Beq.s	.NoDr
	Move.w	D4,D0
.NoDr	Tst.b	79(A1)		Gauche
	Beq.s	.NoGa
	Move.w	D4,D0
	Neg.w	D0
.NoGa	Tst.b	77(A1)		Bas
	Beq.s	.NoBa
	Move.w	D4,D1
.NoBa	Tst.b	76(A1)		Haut
	Beq.s	.NoHa
	Move.w	D4,D1
	Neg.w	D1
.NoHa	Clr.l	D4
	Tst.b	67(A1)		Feu: Return,(Espace),Entree
	Bne.s	.FOn		Espace: SlideShow !
	Tst.b	68(A1)
	*Bne.s	.FOn
	Beq.s	.Foff
	*Tst.b	64(A1)
	*Beq.s	.FOff
.FOn	Move.w	#$FF,D4
.FOff	RTS



***********************	Keyboard 1/2 pour 1200 normal
*			On désactive le 1

Clavier2	Movea.l	ClavierPtr,A1
	Clr.l	D0
	Clr.l	D1
	Tst.b	19(A1)		Droite: r
	Beq.s	.NoDr
	Move.w	D4,D0
.NoDr	Tst.b	17(A1)		Gauche: z
	Beq.s	.NoGa
	Move.w	D4,D0
	Neg.w	D0
.NoGa	Tst.b	18(A1)		Bas: e
	Beq.s	.NoBa
	Move.w	D4,D1
.NoBa	Tst.b	4(A1)		Haut: ' (OU ")
	Beq.s	.NoHa1
	Move.w	D4,D1
	Neg.w	D1
	Bra.s	.NoHa
.NoHa1	Tst.b	3(A1)		Haut: "
	Beq.s	.NoHa
	Move.w	D4,D1
	Neg.w	D1	
.NoHa	Clr.l	D4
	Tst.b	64(A1)		Feu:Espace
	Sne	D4			
	RTS

***********************	Keyboard 2/2 pour 1200 normal
*			On désactive le 1

Clavier3	
	Clr.l	D0
	Clr.l	D1
	Movea.l	ClavierPtr,A1	
	Tst.b	63(A1)		Droite: 9
	Beq.s	.NoDr
	Move.w	D4,D0
.NoDr	Tst.b	61(A1)		Gauche: 7
	Beq.s	.NoGa
	Move.w	D4,D0
	Neg.w	D0
.NoGa	Tst.b	62(A1)		Bas: 8
	Beq.s	.NoBa
	Move.w	D4,D1
.NoBa	Tst.b	91(A1)		Haut: ]
	Beq.s	.NoHa
	Move.w	D4,D1
	Neg.w	D1
.NoHa	Clr.l	D4
	Tst.b	78(A1)		Feu: Fléche droite (ligne 3 nickée sur le clavier alpha)
	Sne	D4			
	RTS


*********************

************* Touche BackSpace : Création d'un micro
*
* Rapport à la nouvelle routine, il suffit d'une impulsion pour activer
* le joueur sur l'écran.
*
MicroDeclenchement
	Clr.l	D4
	Clr.l	D0
	Clr.l	D1
	Movea.l	ClavierPtr,A1
	Tst.b	65(A1)		BackSpace
	Beq.s	.NoNewMic

	* OKAY; On créée le micro
	Lea	Micro,A2		Routine gestion Micro
	Move.w	#$FF,D4		Fire ON
.NoNewMic	RTS

**********	Calculer la position du joueur sur l'écran
*
*
*
Plot_Activation	=	0

ScreenPos	
	Movem.l	D4-D6,-(A7)
	Move.w	Leg_X(A0),D5
	Add.w	#-128+HotX,D5
	Move.w	D5,XScr

	Move.w	Leg_Y(A0),D6
	Add.w	#-46+HotY,D6
	Move.w	D6,YScr
	
	IFNE Plot_Activation
	 Mulu.w	#40,D6
	 Move.l	Planar,A1
	 Move.w	D5,D4
	 And.b	#%111,D4
	 Neg.b	D4
	 Add.b	#7,D4
	 Lsr.w	#3,D5
	 Add.w	D5,D6
	 Bset	D4,(A1,D6.w)	
	ENDC	
	Movem.l	(A7)+,D4-D6
	RTS

**********	Recentrer le joueur (côtés de la direction) 
*
* D0: Direction X
* D1: Direction Y
*
CentreJ
	Move.l	D3,-(A7)
	Clr.l	D2
	Clr.l	D3

	Movea.l	Dim2,A1	Visible
	Move.w	XScr,D2		X centre
	Move.w	YScr,D3		Y centre

	Move.w	D0,D4	Pas de mouvement: que tchi...
	Lsl.w	#1,D4
	Add.w	D1,D4
	Bne.s	.Ok	Mouvement: Centrages Ok
		
	Tst.w	Leg_ForceCentre(A0)		Pas de mouvement
	Beq.s	.Fin			On ne force pas
	Bsr	.CGaDr
	Bsr	.CHauBa		
	Bra.s	.Fin

.Ok	Clr.w	Leg_ForceCentre(A0)
	Tst.w	D0
	Bne.s	.No1
	Bsr	.CGaDr
.No1	
	Tst.w	D1
	Bne.s	.No2
	Bsr	.CHauBa
.No2
.fin	Move.l	(A7)+,D3
	RTS
	

.CGaDr	* Pas de mouvement en X: on teste X gauche et X droite
	Clr.l	D4
	Clr.l	D5
	Move.w	D3,D5	Y actuel
	Lsr.w	#3,D5	Case actuelle en Y
	Lsl.l	#6,D5	

	Move.w	D2,D4		Droite
	Add.w	#LColDr,D4
	Lsr.w	#3,D4
	Add.l	D5,D4
	Lsl.l	#2,D4
	Move.w	(A1,D4.l),D6
	Beq.s	.Rien1	
	Cmp.w	#Type_Bombe,D6
	Beq.s	.Rien1
	Sub.w	#1,Leg_X(A0)

.Rien1	Move.w	D2,D4		Gauche
	Sub.w	#LColGa,D4
	Lsr.w	#3,D4
	Add.l	D5,D4
	Lsl.l	#2,D4
	Move.w	(A1,D4.l),D6
	Beq.s	.Rien2
	Cmp.w	#Type_Bombe,D6
	Beq.s	.Rien2
	Add.w	#1,Leg_X(A0)

.Rien2	RTS


.CHauBa	* Pas de mouvement en Y: on teste Y haut et Y bas
	Move.w	D2,D5	X
	Lsr.w	#3,D5
	
	Move.w	D3,D4		Haut
	Sub.w	#LColHa,D4
	Lsr.w	#3,D4
	Lsl.w	#6,D4
	Add.w	D5,D4
	Ext.l	D4
	Lsl.l	#2,D4		
	Move.w	(A1,D4.l),D6
	Beq.s	.Rien3
	Cmp.w	#Type_Bombe,D6
	Beq.s	.Rien3
	Add.w	#1,Leg_Y(A0)
	
.Rien3	Move.w	D3,D4		Bas
	Add.w	#LColBa,D4
	Lsr.w	#3,D4
	Lsl.w	#6,D4
	Add.w	D5,D4
	Ext.l	D4
	Lsl.l	#2,D4
	Move.w	(A1,D4.l),D6
	Beq.s	.Rien4
	Cmp.w	#Type_Bombe,D6
	Beq.s	.Rien4
	Sub.w	#1,Leg_Y(A0)
.Rien4
	RTS


**********	Un mur se cogne-t'il au joueur ? (ou l'inverse :-) )
*
* D0: Mouvement X
* D1: Mouvement Y
* XScr: X sur l'écran
* YScr: Y sur l'écran 
*
***** 
* On peut avancer si la case où on veut aller est la même
*
TestMur	Move.l	D3,-(A7)

	**** On commence le TestMur normal
	
	Clr.l	D2
	Clr.l	D3
	Move.w	XScr,D2		X centre
	Move.w	YScr,D3		Y centre

	***************  CALCUL des offsets de la position actuelle
	Move.w	D3,D6
	Lsr.w	#3,D6		Y/8
	Move.w	D2,D5	
	Lsr.w	#3,D5		X/8
	Lsl.w	#6,D6
	Add.w	D5,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Move.l	D6,LegCaseActPetite		Offset petite case ACTUELLE
	Move.w	D3,D6
	Lsr.w	#3,D6		Y/8
	Bclr	#0,D6		/16*16/8
	Bclr	#0,D5
	Lsl.w	#6,D6
	Add.w	D5,D6
	Ext.l	D6
	Move.w	D6,Leg_Offset(A0)	<-- Nécessaire ???
	Lsl.l	#2,D6
	Move.l	D6,LegCaseActGrosse		Offset grosse case ACTUELLE
		

	***************  CALCUL de l'offset du point de collision
	Clr.l	D4		
	Tst.w	D0	Mouvement désiré en X
	Beq.s	.t1
	Bgt.s	.Plg1		
	Moveq	#-ColGa,D4	
	Bra.s	.t1
.Plg1	Moveq	#ColDr,D4
.t1	*
	Clr.l	D5
	Tst.w	D1	Mouvement désiré en Y
	Beq.s	.t2
	Bgt.s	.Plg2
	Moveq	#-ColHa,D5
	Bra.s	.t2
.Plg2	Moveq	#ColBa,D5		On veut tester la collision 
.t2	*			dans la direction cible
	Add.l	D4,D2		D2: New X
	Bge.s	.OkNX1
	Clr.l	D2
.OkNX1	Add.l	D5,D3		D3: New Y
	Bge.s	.OkNY2
	Clr.l	D3	
.OkNY2
	***************  CALCUL des offsets de nouvelle position
	Lsr.w	#3,D2		X/8
	Lsr.w	#3,D3		Y/8
	Move.w	D3,D5
	Lsl.w	#6,D5
	Add.w	D2,D5
	Ext.l	D5
	Lsl.l	#2,D5
	Move.l	D5,LegCaseNewPetite
	Bclr	#0,D2
	Bclr	#0,D3
	Lsl.w	#6,D3
	Add.w	D2,D3
	Ext.l	D3
	Lsl.l	#2,D3
	Move.l	D3,LegCaseNewGrosse	

	Bra	.NoHarib


	***********************
	Movem.l	D1-D5/A1-A2,-(A7)
	** Bon ben on teste les cases précédentes du joueur.
	* pour le Hariiibaaa !
	Movea.l	Dim4,A1		Flammes
	Lea	(A1,D5.l*4),A2
	Tst.b	Dim4_Mask(A2)
	Beq.s	.NoFl0
	* La case ACTUELLE contient une flamme: On annule tout !
	Clr.l	Leg_LastPos(A0)
	Clr.l	Leg_LastPos2(A0)
	Bra.s	.NoFl2	
.NoFl0	Move.l	Leg_LastPos(A0),D5
	Lea	(A1,D5.l*4),A2
	Tst.b	Dim4_Mask(A2)
	Beq.s	.NoFl1
	* La case PRECEDENTE contient maintenant une flamme
	Movem.l	D1/D3,-(A7)	Bruit poils du cul cramés
	Moveq	#12,D3
	Moveq	#PriSonTresChaud,D1
	Clr.w	SampleLoops
*	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3
	Clr.l	Leg_LastPos(A0)
	Clr.l	Leg_LastPos2(A0)
	Bra.s	.Fl1
.NoFl1
	Move.l	Leg_LastPos2(A0),D5	
	Lea	(A1,D5.l*4),A2
	Tst.b	Dim4_Mask(A2)	
	Beq.s	.NoFl2
	* La case 2 fois précédente contient maintenant une flamme
	Movem.l	D1/D3,-(A7)	Bruit Mec chaud
	Moveq	#11,D3
	Moveq	#PriSonChaud,D1
	Clr.w	SampleLoops
*	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3
	Clr.l	Leg_LastPos2(A0)
.NoFl2
.Fl1	Movem.l	(A7)+,D1-D5/A1-A2
	*****************************


	*****************	Comparaisons de cases pour mouvements

.NoHarib	Move.l	LegCaseNewGrosse,D4		Même grosse case:
	Sub.l	LegCaseActGrosse,D4		Mouvement ok
	*Beq	.OkMv

	Move.l	LegCaseActPetite,D6		D6: Actuel
	Move.l	LegCaseNewPetite,D5		D5: But
	Cmp.l	D5,D6
	Beq	.OkMv

	Movea.l	Dim7,A1		DIM 7: Dalles
	Move.w	(A1,D5.l),D4
	Cmp.w	#Type_AntiMec,D4
	Beq	.NoB
	Cmp.w	#Type_AntiFeuMec,D4
	Beq	.NoB
	
	Movea.l	Dim2,A1		DIM 2: Visible
	Move.w	(A1,D5.l),D4
	Beq	.OkMv		Rien:Ok
	Cmp.w	#Type_Bonus,D4
	Beq	.OkMv		Bonus:Ok
	Cmp.w	#Type_Bonus_DestrAct,D4
	Beq	.OkMv		Bonus en destruction:Ok (pour mourir)

**************
* case où l'on veut aller n'est pas: vide, bonus, antifeu
* reste: BOMBE
* On sait que là on on veut aller c'est une bombe: D5
* on teste où l'on est: D6

	Cmp.w	#Type_Bombe,D4	Bombe où l'on veut aller ?
	Bne	.NoB		Pas une bombe: on vire	

	****
	
	Move.w	(A1,D6.l),D2	DIM 2: Visible
	Cmp.w	#Type_Bombe,D2
	Bne.s	.NormalBT		Pas une bombe: tests normaux
	
********
* On teste: si N°BOMBE où l'on est = N° BOMBE où l'on veut aller:ok

	Movea.l	Dim1,A1		DIM 1: Bombes
	Move.w	(A1,D5.l),D2	Offsets petites cases
	Sub.w	(A1,D6.l),D2	
	Bne	.NormalBT		Même bombe: OKAY !
	* C'est la même bombe, on vérifie son mouvement Vx=D3,Vy=D4
	* Mouvement sprite: D0,D1

	**** Ajout de test du pousse bombes ? si pas, OkMv ???

	Bsr	DirecOne		D0,D1->D3,D4 direction (-1,0,1)

	Movea.l	Dim1,A1		DIM 1: Bombes
	Move.w	(A1,D5.l),D7	Numéro Bombe case cible
	Mulu.w	#Bomb_SizeOf,D7
	Movea.l	BombPtr,A1
	Lea	(A1,D7.l),A2	Structure bombe CIBLE
	Add.w	Bomb_VX(A2),D3	
	Add.w	Bomb_VX(A2),D4
	* Si D3=0, alors soit les deux mouvements s'annulent, soit
	* les deux mouvements sont nuls au départ.

	Tst.w	D3
	Bne	.OkMv		ca ne s'annule pas: on bouge
	Tst.w	Bomb_VX(A2)
	Bne.s	.NormalBT		Ca s'annule: on pousse
	Tst.w	D4
	Bne	.OkMv
	Tst.w	Bomb_VY(A2)
	Bne.s	.NormalBT
	Bra	.OkMv
	****

********
* Pas la même bombe: on essaye de pousser
.NormalBT	Tst.w	Leg_PousseBombe(A0)	Pousse Bombes ?
	Beq	.NoB
	Tst.w	Leg_PousseOk(A0)
	Beq.s	.NoB
	Clr.w	Leg_PousseOk(A0)

	Movem.l	D1/D3,-(A7)
	Moveq	#4,D3
	Moveq	#PriSonChocBombe,D1
	Clr.w	SampleLoops
	Bsr	PlaySon		Bruit choc bombe
	Movem.l	(A7)+,D1/D3

	Movea.l	Dim1,A1		DIM 1: Bombes
	Move.w	(A1,D5.l),D7	Numéro Bombe case cible
	Mulu.w	#Bomb_SizeOf,D7
	Movea.l	BombPtr,A1
	Lea	(A1,D7.l),A2	Structure bombe
	Bsr	DirecOne
	Move.w	D3,Bomb_VX(A2)	On pousse!
	Move.w	D4,Bomb_VY(A2)			
	
.NoB	Clr.w	D0		On empêche le joueur de bouger
	Clr.w	D1	

	Clr.w	Leg_BumpX(A0)	On se cogne contre un mur: 
	Clr.w	Leg_BumpY(A0)	on arrête la folle course du bumper!

	* On met autorisation=1
	Tst.w	Leg_TelOk(A0)
	Bne.s	.Deja2
	Move.w	#1,Leg_TelOk(A0)
.Deja2
	** Bon ben on décale les cases: DANS TOUS LES CAS !!!
	* Mais de façon plus lente si on ne change pas de case
	
	Move.w	Leg_LastCount(A0),D6
	Addq.w	#1,D6
	Cmp.w	#TimeDecalChaud,D6
	Bge.s	.OkDecal
	Move.w	D6,Leg_LastCount(A0)
	Bra.s	.NotOkD
.OkDecal	Move.l	Leg_LastPos(A0),Leg_LastPos2(A0)
	Move.l	D5,Leg_LastPos(A0)
	Clr.w	Leg_LastCount(A0)
.NotOkD
.OkMv2	Move.l	(A7)+,D3		
	RTS

.OkMv	Move.w	#1,Leg_PousseOk(A0)
	Bra.s	.OkDecal

	**** Transformer D0,D1 (nX,nY) et mouvement normé D3,D4 (1,1)
DirecOne	
	* Inits pour pousse bombe
	Clr.l	D3
	Tst.w	D0
	Bgt.s	.PlGr1
	Beq.s	.Zer1
	Moveq	#-1,D3		Direction que va prendre la bombe
	Bra.s	.Zer1
.PlGr1	Moveq	#1,D3		D3 à GARDER
.Zer1	Clr.l	D4
	Tst.w	D1
	Bgt.s	.PlGr2
	Beq.s	.Zer2
	Moveq	#-1,D4
	Bra.s	.Zer2
.PlGr2	Moveq	#1,D4		D4 à GARDER
.Zer2	RTS	





**********	Tester l'état des maladies, et désactiver si besoin
*
*
TestMalad
	Moveq	#-1,D7
	Move.w	Leg_M1(A0),D4		Maladie inversion
	Beq.s	.NoM1
	Subq.w	#1,D4
	Move.w	D4,Leg_M1(A0)
	Bgt.s	.NoM1
	Clr.l	D7
	Move.w	#TBonus_MalInv,MemBonus
	Bra	.FinB	*** Pour faire une "file d'attente"
.NoM1	*	en cas de fin simultanée de maladies (ambulance)

	Move.w	Leg_M2(A0),D4		Maladie flamme
	Beq.s	.NoM2
	Subq.w	#1,D4
	Move.w	D4,Leg_M2(A0)
	Bgt.s	.NoM2		
	Move.w	Leg_M2Mem(A0),Leg_Flamme(A0)
	Clr.l	D7
	Move.w	Leg_M2Mem2(A0),MemBonus
	Bra	.FinB
.NoM2	
	Move.w	Leg_M3(A0),D4		Maladie time bombes 
	Beq.s	.NoM3
	Subq.w	#1,D4
	Move.w	D4,Leg_M3(A0)
	Bgt.s	.NoM3		
	Move.w	Leg_M3Mem2(A0),Leg_BTime(A0)
	Move.w	Leg_M3Mem3(A0),Leg_NbBoucles(A0)
	Clr.l	D7
	Move.w	Leg_M3Mem(A0),MemBonus
	Bra	.FinB
.NoM3
	Move.w	Leg_M4(A0),D4		Maladie mouvement sprite
	Beq.s	.NoM4
	Subq.w	#1,D4
	Move.w	D4,Leg_M4(A0)
	Bgt.s	.NoM4		
	Move.w	Leg_M4Mem(A0),Leg_VitJou(A0)	Restauration vitesse
	Clr.l	D7
	Move.w	Leg_M4Mem2(A0),MemBonus
	Bra	.FinB
.NoM4	
	Move.w	Leg_M5(A0),D4		Maladie pose plus de bombes
	Beq.s	.NoM5
	Subq.w	#1,D4
	Move.w	D4,Leg_M5(A0)
	Bgt.s	.NoM5
	Clr.l	D7
	Move.w	#TBonus_MalNoB,MemBonus
	Bra	.FinB
.NoM5	
	Move.w	Leg_M6(A0),D4		Maladie pose pleins de bombes
	Beq.s	.NoM6
	Subq.w	#1,D4
	Move.w	D4,Leg_M6(A0)
	Bgt.s	.NoM6
	Move.w	Leg_M6Mem(A0),D4
	Sub.w	D4,Leg_MaBomb(A0)		-N bombes
	Clr.l	D7
	Move.w	#TBonus_MalMB,MemBonus
	Bra	.FinB
.NoM6	
	Move.w	Leg_M7(A0),D4		Maladie goutte d'eau
	Beq.s	.NoM7
	Subq.w	#1,D4
	Move.w	D4,Leg_M7(A0)
	Bgt.s	.NoM7
	Clr.w	Leg_ImBl(A0)
	Clr.l	D7
	Move.w	#TBonus_MalGoutDo,MemBonus
	Bra.s	.FinB
.NoM7	
	Move.w	Leg_M8(A0),D4		Maladie rebond bombes
	Beq.s	.NoM8
	Subq.w	#1,D4
	Move.w	D4,Leg_M8(A0)
	Bgt.s	.NoM8
	Clr.l	D7
	Move.w	#TBonus_MalReBomb,MemBonus
	Bra.s	.FinB
.NoM8
	Move.w	Leg_M9(A0),D4		Maladie Collique (Pose B)
	Beq.s	.NoM9
	Subq.w	#1,D4
	Move.w	D4,Leg_M9(A0)
	Clr.l	D7
	Move.w	#TBonus_MalPoseB,MemBonus	Même icône que +10 bombes, pas d'images en rab dispo! :-)
	Bra	.FinB
.NoM9	
	Move.w	Leg_M10(A0),D4		Maladie ?
	Beq.s	.NoM10
	Subq.w	#1,D4
	Move.w	D4,Leg_M10(A0)
	Bgt.s	.NoM10
	Clr.l	D7
*	Move.w	#TBonus_,MemBonus
*	Bra	.FinB
.NoM10	
.FinB	Tst.l	D7
	Beq.s	BarreMAJFinMalad
	RTS

BarreMAJFinMalad
	Movem.l	D0-D1/D3/A0-A1,-(A7)

	**********************	BARRE JOUEURS
	Lea	BonusIdxHires,A1	Tableaux bonus... hires! hé oui
	Move.w	Leg_BarreBlocX(A0),D3
	Move.w	Leg_BarreY(A0),D4
	Move.w	MemBonus,D5
	Move.w	(A1,D5.w*2),D5	Image pour le bonus D5
	Add.w	#NombreBonusHires,D5
	Bsr	Bloc32x16cop
	
	***********************	BRUIT	
	Moveq	#13,D3
	Moveq	#PriSonFinMalad,D1
	Clr.w	SampleLoops
	Bsr	PlaySon

	Movem.l	(A7)+,D0-D1/D3/A0-A1
	RTS

************* Tests généraux sur les activations des bombes/flammes
*
*
*
TestGene
	Move.w	BombDGel,D4
	Ble.s	.NoGele	
	Subq.w	#1,D4
	Move.w	D4,BombDGel
	Bgt.s	.NoGele
	Movea.l	BombPtr,A1
	Move.w	LastNBomb,D5
	Subq.w	#1,D5
	Blt.s	.noGele	Aucune bombe sur l'écran
.Loop2	Tst.w	Bomb_Active(A1)
	Bne.s	.DejO	
	Move.w	#1,Bomb_Active(A1)
	Move.w	Bomb_Im(A1),D2
	Cmp.w	#BombImFin,D2
	Ble.s	.DejO
	Sub.w	#BombImGel,Bomb_Im(A1)
.DejO	Adda.w	#Bomb_SizeOf,A1
	Dbf	D5,.Loop2
.NoGele
	RTS

*********************	La joueur est sur un tapis roulant ?
*
*
*
TestFleche
	Move.w	XScr,D2		X en pixels
	Move.w	YScr,D4
	Lsr.w	#3,D2
	Lsr.w	#3,D4
	Move.w	D4,D6
	Lsl.w	#6,D6
	Add.w	D2,D6
	Ext.l	D6
	Lsl.l	#2,D6		Offset
	Movea.l	Dim7,A1		Dalles
	Move.w	(A1,D6.l),D4
	Cmp.w	#Type_FlecheH,D4
	Bne.s	.NoFH
	Subq.w	#1,D1
	Bra.s	.Roi	
.NoFH	Cmp.w	#Type_FlecheB,D4
	Bne.s	.NoFB
	Addq.w	#1,D1
	Bra.s	.Roi	
.NoFB	Cmp.w	#Type_FlecheG,D4
	Bne.s	.NoFG
	Subq.w	#1,D0
	Bra.s	.Roi	
.NoFG	Cmp.w	#Type_FlecheD,D4
	Bne.s	.NoFD
	Addq.w	#1,D0
	*Bra.s	.Roi	
.NoFD		
.Roi	RTS
	
**********	Le joueur s'est mangé une flamme ?
*
* On meurt si: position = mur
*	     position = flamme
*
* Spécial si:  position = bonus
*	     position = téléporteur
*
TestMort
	Move.w	XScr,D2		X en pixels
	Move.w	YScr,D4
	Lsr.w	#3,D2
	Lsr.w	#3,D4
	Move.w	D4,D6
	Lsl.w	#6,D6
	Add.w	D2,D6
	Ext.l	D6
	Lsl.l	#2,D6		Offset

	Movea.l	Dim4,A1		FLAMMES
	Lea	(A1,D6.l*4),A1
	Tst.b	Dim4_Mask(A1)
	Beq	.NoFl
.Mort	Tst.w	Leg_M7(A0)
	Bne	.NoFl		Invincible aux flammes !!! Goutte d'eau
	Move.w	#ImDebMortFl,Leg_Mort(A0)	On se mange une flamme
.MortEcr	* Si on arrive ici, on est mort d'une façon ou d'une autre
	* Le commutateur de mort est juste Leg_Mort(A0)

	Add.l	#1,Leg_GamesLooseT(A0)

	****
	Add.w	#1,Leg_DontMove(A0)

	Tst.w	SurvivorMode
	Beq.s	.NoSurviv
	Move.w	#20,Leg_DontMove(A0)
.NoSurviv
	

	****
	Bsr	non_app_mort	Joueurs non apparus: morts

	**** On déverrouille la bombe si le mec meurt et qu'il avait
	* l'horloge ainsi qu'une bombe bloquée.
	Tst.w	Leg_Horloge(A0)
	Beq.s	.NoH8
	Move.l	Leg_HMem(A0),A1
	Tst.l	A1
	Beq.s	.NoH8
	Clr.w	Bomb_Horloge(A1)
	Clr.l	Bomb_JMem(A1)
	Move.w	#BombImL,Bomb_Im(A1)
	Clr.l	Leg_HMem(A0)
.NoH8	****
	
	**** Son de la mort
	Movem.l	D1/D3,-(A7)
	Moveq	#1,D3
	Moveq	#PriSonMort,D1	Mort juste un peu prioritaire !
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3
	Bra	.EndTst		Mort prioritaire ;-)
.NoFl		
	Move.w	#ImDebMortEcr,Leg_Mort(A0)	SI on se fait écraser
	Movea.l	Dim2,A1		VISIBLE
	Move.w	(A1,D6.l),D5
	Cmp.w	#Type_Bloc_NoDestr,D5
	Beq	.MortEcr
	Cmp.w	#Type_Bloc_NoDestr2,D5
	Beq	.MortEcr
	Cmp.w	#Type_Bloc_Destr,D5
	Beq	.MortEcr
	Cmp.w	#Type_Bloc_DestrAct,D5
	Beq	.MortEcr
	Cmp.w	#Type_Bonus_DestrAct,D5
	Beq	.MortEcr
	
	Clr.w	Leg_Mort(A0)	Toujours pas mort ?

	Cmp.w	#Type_Bonus,D5
	Bne	.NoBonus

	And.w	#$FE,D2	Cases entières
	And.w	#$FE,D4
	Move.w	D4,D6
	Lsl.w	#6,D6
	Add.w	D2,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Movea.l	Dim5,A1

	*** Traitement en fonction du bonus
	* 0:flamme
	* 1:Bombe 
	Move.w	(A1,D6.l),D5	N° Bonus
	Beq	.EndBo		Pas un bonus
	Move.w	D5,MemBonus

	Add.l	#1,Leg_BonusTaken(A0)	STAT

	Cmp.w	#TBonus_Flamme,D5		Bonus Flamme
	Bne.s	.NoBo1
	Add.w	#1,Leg_Flamme(A0)
	Move.w	Leg_Flamme(A0),Leg_M2Mem(A0)	Au cas où maladie
	Bra	.EndBo
.NoBo1
	Cmp.w	#TBonus_Bombe,D5		Bonus Bombe
	Bne.s	.NoBo2
	Add.w	#1,Leg_MaBomb(A0)
	Bra	.EndBo
.NoBo2	
	Cmp.w	#TBonus_PousseB,D5		Bonus pousse bombe
	Bne.s	.NoBo3
	Bchg	#0,Leg_PousseBombe+1(A0)
	Tst.w	Leg_PousseBombe(A0)
	Bne	.EndBo
	Neg.w	MemBonus
	Bra	.EndBo
.NoBo3
	Cmp.w	#TBonus_MalInv,D5		Maladie inversion
	Bne.s	.NoBo4			MALADIE 1	
	Move.w	#Time_Malad,Leg_M1(A0)		
	Bra	.EndBo
.NoBo4	
	Cmp.w	#TBonus_MalFla,D5		Maladie petite flamme
	Bne.s	.NoBo5			MALADIE 2 (M=L Flam)
	Move.w	Leg_Flamme(A0),Leg_M2Mem(A0)
	Move.w	#Flam_LShort,Leg_Flamme(A0)
	Move.w	#Time_Malad,Leg_M2(A0)
	Move.w	D5,Leg_M2Mem2(A0)
	Bra	.EndBo
.NoBo5
	Cmp.w	#TBonus_MalTBF,D5		Maladie Time bombes Fast
	Bne.s	.NoBo6			MALADIE 3
	Tst.w	Leg_M3(A0)
	Bgt.s	.NoAf1
	Move.w	Leg_BTime(A0),Leg_M3Mem2(A0)	Sauve....
	Move.w	Leg_NbBoucles(A0),Leg_M3Mem3(A0)
.NoAf1	Move.w	#BTime_Fast,Leg_BTime(A0)
	Move.w	#BombNbBouclesF,Leg_NbBoucles(A0)
	Move.w	#Time_Malad,Leg_M3(A0)
	Move.w	D5,Leg_M3Mem(A0)
	Bra	.EndBo
.NoBo6
	Cmp.w	#TBonus_MalVitL,D5		Maladie Lente
	Bne.s	.NoBo7			MALADIE 4
	Tst.w	Leg_M4(A0)
	Bgt.s	.NoAf3
	Move.w	Leg_VitJou(A0),Leg_M4Mem(A0)
.NoAf3	Move.w	#Speed_Slow,Leg_VitJou(A0)	
	Move.w	#Time_Malad,Leg_M4(A0)
	Move.w	D5,Leg_M4Mem2(A0)
	Bra	.EndBo
.NoBo7
	Cmp.w	#TBonus_MalVitR,D5		Maladie Rapide
	Bne.s	.NoBo8			MALADIE 4
	Tst.w	Leg_M4(A0)
	Bgt.s	.NoAf4
	Move.w	Leg_VitJou(A0),Leg_M4Mem(A0)
.NoAf4	Move.w	#Speed_Fast,Leg_VitJou(A0)	
	Move.w	#Time_Malad,Leg_M4(A0)
	Move.w	D5,Leg_M4Mem2(A0)
	Bra	.EndBo
.NoBo8
	Cmp.w	#TBonus_MalTBS,D5		Maladie Time Bombes Slow
	Bne.s	.NoBo9			MALADIE 3
	Tst.w	Leg_M3(A0)
	Bgt.s	.NoAf2
	Move.w	Leg_BTime(A0),Leg_M3Mem2(A0)	Sauve....
	Move.w	Leg_NbBoucles(A0),Leg_M3Mem3(A0)
.NoAf2	Move.w	#BTime_Slow,Leg_BTime(A0)
	Move.w	#BombNbBouclesS,Leg_NbBoucles(A0)
	Move.w	#Time_Malad,Leg_M3(A0)
	Move.w	D5,Leg_M3Mem(A0)
	Bra	.EndBo	
.NoBo9
	Cmp.w	#TBonus_Camembert,D5	Explosion nucléaire
	Bne.s	.NoBo10
	Movea.l	BombPtr,A1
	Clr.l	D5
	Move.w	LastNBomb,D5
	Subq.w	#1,D5
	Blt	.EndBo
.Loop1	Tst.w	Bomb_Exist(A1)
	Beq	.FLoop
	Bset	#31,D5
	Clr.w	Bomb_Time(A1)
.FLoop	Adda.w	#Bomb_SizeOf,A1
	Dbf	D5,.Loop1
.NoBom1	Btst	#31,D5
	Beq	.EndBo

	Movem.l	A0-A1/D1/D3-D5,-(A7)
	Moveq	#14,D3
	Moveq	#PriSonHiroshima,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,A0-A1/D1/D3-D5
	Bra	.EndBoNoBruit

.NoBo10
	Cmp.w	#TBonus_GeleB,D5		Désactivation Bombes
	Bne.s	.NoBo11
	Move.w	#Time_GeleB,BombDGel	Temps avant réactivation
	Movea.l	BombPtr,A1
	Move.w	LastNBomb,D5
	Subq.w	#1,D5
	Blt.s	.noB2
.Loop2	Clr.w	Bomb_Active(A1)
	Move.w	#0,Bomb_FirstI(A1)	Pas d'image déjà affichée: Comme ca glace
	Adda.w	#Bomb_SizeOf,A1
	Dbf	D5,.Loop2
.NoB2	Bra	.EndBo

.NoBo11
	Cmp.w	#TBonus_MalFlaG,D5		Maladie grande flamme
	Bne.s	.NoBo12			MALADIE 2 (M=L Flam)
	Move.w	Leg_Flamme(A0),Leg_M2Mem(A0)
	Move.w	#Flam_LLong,Leg_Flamme(A0)
	Move.w	#Time_Malad,Leg_M2(A0)
	Move.w	D5,Leg_M2Mem2(A0)
	Bra	.EndBo
.NoBo12
	Cmp.w	#TBonus_MalNoB,D5		Maladie pose plus de bombes
	Bne.s	.NoBo13			MALADIE 5
	Move.w	#Time_Malad_Short,Leg_M5(A0)
	bra	.EndBo
.NoBo13
	* Ce bonus est spécial : on peut le prendre plusieurs fois de
	* suite, à chaque fois le nombre de bombes augmente !
	Cmp.w	#TBonus_MalMB,D5		Maladie double nb bombes
	Bne.s	.NoBo14			MALADIE 6
	Tst.w	Leg_M6(A0)
	Bne.s	.DejM6
	Clr.w	Leg_M6Mem(A0)	
.DejM6	Clr.w	Leg_M5(A0)
	Add.w	#NbBombMore,Leg_MaBomb(A0)	+N bombes !
	Add.w	#NbBombMore,Leg_M6Mem(A0)	Nombre à soustraire !
	Move.w	#Time_Malad,Leg_M6(A0)
	Bra	.EndBo
.NoBo14
	* Dans cette partie de détection des bonus, c'est seulement
	* quand on prend un bonus. Les temps sont donc cumulatoires.

	Cmp.w	#TBonus_MalGoutDo,D5	Maladie goutte d'eau
	Bne.s	.NoBo15			MALADIE 7
	Move.w	#Time_Malad_Short,Leg_M7(A0)
	Move.w	#Time_Clignote_Invincible,Leg_M7Mem(A0)
	Bra	.EndBo

.NoBo15
	Cmp.w	#TBonus_Ambulance,D5	AMBULANCE
	Bne.s	.NoBo16
	Movem.l	D3/A2,-(A7)
	Moveq	#1,D5
	Move.w	#0,Leg_ImBl(A0)	Décalage invincibilité
	Lea	Leg_M1(A0),A2
	Moveq	#9,D3
.Loop	Tst.w	(A2)
	Beq.s	.NoM
	Move.w	D5,(A2)
.NoM	Adda.w	#4,A2
	Dbf	D3,.Loop
	Movem.l	(A7)+,D3/A2
	Bra	.EndBo
.NoBo16
	Cmp.w	#TBonus_Horloge,D5
	Bne.s	.NoBo17
	Tst.w	Leg_Horloge(A0)	Si bombe actuellement bloquée
	Beq.s	.NoH7
	Move.l	Leg_HMem(A0),A1
	Tst.l	A1
	Beq.s	.NoH7
	* On a lâché le bouton, et on a l'horloge, et une bombe
	* était bloquée à cause de ça, donc on la libère
	Clr.w	Bomb_Horloge(A1)
	Clr.l	Bomb_JMem(A1)
	Move.w	#BombImL,Bomb_Im(A1)
	Clr.l	Leg_HMem(A0)
.NoH7	Not.w	Leg_Horloge(A0)	Comme pousse bombes... On/Off
	Bra	.EndBo	
.NoBo17

	Cmp.w	#TBonus_MalReBomb,D5	Maladie bombe REBONDI
	Bne.s	.NoBo18			MALADIE 8
	Move.w	#Time_Malad,Leg_M8(A0)
	Bra	.EndBo
.NoBo18

	Cmp.w	#TBonus_BombeFolle,D5	BOMBES "FOLLES"
	Bne.s	.NoBo19	
	Movem.l	D0-D1/D5-D6/A1-A2,-(A7)
	Movea.l	BombPtr,A1
	Move.w	LastNBomb,D5
	Subq.w	#1,D5
	Blt.s	.NoBom2
	Movem.w	MemRnd1,D0-D1
	Bsr	Rnd_Engine
	Movem.w	D0-D1,MemRnd1
	And.l	#%11,D0
	Move.w	D0,D6
.Loop17	Lea	FolleList,A2
	Dbf	D6,.OkD0
	Moveq.w	#3,D6
.OkD0	Lea	(A2,D6.w*4),A2
	Move.w	(A2)+,Bomb_VX(A1)
	Move.w	(A2),Bomb_VY(A1)
	Adda.w	#Bomb_SizeOf,A1
	Dbf	D5,.Loop17 
.NoBom2	Movem.l	(A7)+,D0-D1/D5-D6/A1-A2
	Bra	.EndBo	
.NoBo19
	Cmp.w	#TBonus_BcpBombes,D5	Bonus Beaucoup bombes
	Bne.s	.NoBo20
	Add.w	#5,Leg_MaBomb(A0)
	Bra	.EndBo
.NoBo20
	Cmp.w	#TBonus_BcpFlammes,D5	Bonus Beaucoup flammes
	Bne.s	.NoBo21
	Add.w	#10,Leg_Flamme(A0)
	Move.w	Leg_Flamme(A0),Leg_M2Mem(A0)	(Au cas où maladie)
	Bra	.EndBo
.NoBo21	
	Cmp.w	#TBonus_Cadeau,D5		Bonus Cadeau
	Bne	.NoBo22	
	* Pour l'instant ce bonus ne donne que l'invincibilité
	* aux membres de l'autre équipe ou aux autres joueurs
	* (en fonction du mode de jeu)
	Cmp.w	#1,PlayerMode	(0:Indiv/1:Teams)
	Bne.s	.Indiv
	Movem.l	D2/A1,-(A7)
	Movea.l	LegoPtr,A1
	Clr.l	D2	
	Btst	#0,D3	On est de l'équipe 1: ok
	Bne.s	.LoopJMA
	* On est de l'équipe 0: équipe 1 cadeau
	Adda.w	#Leg_SizeOf,A1
	Addq.w	#1,D2		
.LoopJMA	*
	Move.w	#Time_Malad_Short,Leg_M7(A1)
	Move.w	#Time_Clignote_Invincible,Leg_M7Mem(A1)
	*
	Bsr	.AffCad
	Adda.w	#Leg_SizeOf*2,A1
	Addq.w	#2,D2
	Cmp.w	#NbJoueurs,D2
	Blt.s	.LoopJMA
	Movem.l	(A7)+,D2/A1
	Bra.s	.EndCado
.Indiv	Movem.l	D2/A1,-(A7)
	Movea.l	LegoPtr,A1
	Clr.l	D2	
.LoopJMA2	Cmpa.l	A0,A1
	Beq.s	.NoNous	
	* Traitements
	Move.w	#Time_Malad_Short,Leg_M7(A1)
	Move.w	#Time_Clignote_Invincible,Leg_M7Mem(A1)
	*
	Bsr	.AffCad
.NoNous	Adda.w	#Leg_SizeOf,A1
	Addq.w	#1,D2
	Cmp.w	#NbJoueurs,D2
	Blt.s	.LoopJMA2
	Movem.l	(A7)+,D2/A1
.EndCado	* éventuellement un son de remerciement

	Bra	.EndBo
.AffCad	Tst.w	Leg_Activated(A1)
	Beq.s	.NoAff
	Tst.w	Leg_Mort(A1)
	Bne.s	.NoAff
	Movem.l	A0-A1/D1-D5,-(A7)	Afficher le cadeau fait
	Move.w	Leg_BarreBlocX(A1),D3
	Move.w	Leg_BarreY(A1),D4
	Move.w	#ImBonusCadeau,D5
	Bsr	Bloc32x16cop	(D3/D4/D5)
	Movem.l	(A7)+,A0-A1/D1-D5
.NoAff	Bra.s	.EndBo		<- Au lieu de RTS ?
	************	

.NoBo22
	Cmp.w	#TBonus_MalPoseB,D5		Maladie Collique (Pose B)
	Bne.s	.NoBo23			MALADIE 9
	Move.w	#Time_Malad,Leg_M9(A0)
	Clr.w	Leg_M5(A0)		Effacement maladie pose plus de bombes
	Bra	.EndBo
.NoBo23

	Move.w	#$0f0,$dff180	Bonus inconnu: flash vert

	Bra.s	.Unknown

.EndBo	
	***********************	BRUIT	
	Movem.l	A0-A1/D1/D3-D5,-(A7)
	Moveq	#0,D3
	Moveq	#PriSonBonus,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,A0-A1/D1/D3-D5

.EndBoNoBruit

	**********************	BARRE JOUEURS
	Movem.l	A0-A1/D1-D5,-(A7)
	Lea	BonusIdxHires,A1	Tableaux bonus... hires! hé oui
	Move.w	Leg_BarreBlocX(A0),D3
	Move.w	Leg_BarreY(A0),D4
	Clr.l	D2
	Move.w	MemBonus,D5
	Bge.s	.OkPos
	Neg.w	D5
	Move.w	#NombreBonusHires,D2
.OkPos	Move.w	(A1,D5.w*2),D5	Image pour le bonus D5
	Add.w	D2,D5
	Bsr	Bloc32x16cop
	Movem.l	(A7)+,A0-A1/D1-D5

	***


.Unknown	Movea.l	Dim2,A1
	Lea	(A1,D6.l),A1
	Moveq	#0,D5
	Move.w	D5,(A1)
	Move.w	D5,SizeStructure(A1)			
	Move.w	D5,SizeStructure*64(A1)			
	Move.w	D5,SizeStructure*65(A1)			

	Movea.l	LevelAct,A1		Effacer le bonus
*	Move.w	Level_Bloc(A1),D5
	Move.w	#Bloc_Vide,D5
	Movea.l	Planar,A1
	Movea.l	FontPtr,A2
	Move.l	D3,-(A7)
	Move.l	D2,D3
	Bsr	TraceBlocWithFont	(A2,D3=X,D4=Y,D5=Bloc)	
	Move.l	(A7)+,D3
	
	*********************************
.Nobonus	* Test pour savoir si on est sur une bombe
	
	Cmp.w	#Type_Bombe,D5
	Bne	.NoBomb

	Tst.w	Leg_LastBomb(A0)	X/Y
	Bne.s	.BombY

	Move.w	#-1,Leg_LastBomb(A0)	On vient de marcher sur une bombe

	Move.l	Dim1,A3
	Move.w	(A3,D6.l),D5
	Mulu.w	#Bomb_SizeOf,D5
	Move.l	BombPtr,A3
	Lea	(A3,D5.l),A3
	Clr.w	Bomb_VX(A3)
	Clr.w	Bomb_VY(A3)

	*********************************

.NoBomb
	Clr.w	Leg_LastBomb(A0)
.BombY	* Test téléporteurs	
	Movea.l	Dim3,A3
	Move.l	(A3,D6.l),D5	Téléporteur (Y,X)
	Beq	.NoTel
	* Si Game Over, téléportation interdite
	Tst.w	GameOver
	Bne	.NoTel
	
	* Droit de se téléporter ?
	Tst.w	Leg_TelOk(A0)
	Bge	.NoTelOk

	* Si on est en train d'être bumpé, on ne peut pas se
	* téléporter ! :-)	
	Tst.w	Leg_BumpX(A0)
	Bne	.NoTelOk
	Tst.w	Leg_BumpY(A0)
	Bne	.NoTelOk


	* Téléporteur: Destination libre ?

	Move.l	D5,D6	Position CIBLE
	Swap	D6
	Lsl.w	#6,D6
	Add.w	D5,D6
	Ext.l	D6
	Lsl.l	#2,D6

	Movea.l	Dim2,A1
	Lea	(A1,D6.l),A1	Visible

	Tst.w	(A1)
	Bne.s	.NoTelOk
	Tst.w	SizeStructure(A1)
	Bne.s	.NoTelOk
	Tst.w	SizeStructure*64(A1)
	Bne.s	.NoTelOk
	Tst.w	SizeStructure*65(A1)
	Bne.s	.NoTelOk
	* On a le droit de se téléporter

	Move.l	XAff,D6		Positions en pixels
	Add.l	#136-16,D6
	Move.l	YAff,D7
	Add.l	#42-16,D7
	Lsl.l	#3,D5
	Add.w	D5,D6
	Swap	D5
	Add.w	D5,D7

	Move.w	D6,Leg_TeleX(A0)
	Move.w	D7,Leg_TeleY(A0)
	Move.w	#ImDebTele,Leg_Tele(A0)	
	Clr.w	Leg_ImBl(A0)
	Move.w	#1,Leg_TelePhase(A0)
	Move.w	#0,Leg_TelOk(A0)
	Movem.l	D1/D3,-(A7)	Bruit téléportation
	Moveq	#3,D3
	Moveq	#PriSonTele,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3
.NoTelOk	Tst.w	Leg_TelOk(A0)	Temporisation de l'autorisation!
	Bgt.s	.NoTel
.EndTst	RTS
.NoTel	Move.w	#-1,Leg_TelOk(A0)
	RTS

*** Virer tous les sprites de la copper liste
*
* 
*
ClearSprites
	VblWait	#31
	Clr.l	InitSpr
	Move.l	CopAdrSprite0,A0
	CopInitSprites
	RTS

**********	Le joueur pose une nouvelle bombe
*
*	X,Y: Position
*
PoseBombe
	Tst.w	Leg_Horloge(A0)
	Beq.s	.NoH0
	Tst.l	Leg_HMem(A0)	Bombe en attente ?
	Beq.s	.NoH0
	Clr.l	D7		Bombe non posée
	* On laisse appuyé pour ne pas déclencher la bombe,
	* donc on ne pose rien...
	RTS
.NoH0
	Clr.l	D4
	Clr.l	D5
	Move.w	XScr,D4		X centre
	And.b	#$F0,D4
	Lsr.w	#3,D4
	Move.w	YScr,D5		Y centre
	And.b	#$F0,D5
	Lsr.w	#3,D5
	Move.w	Leg_BTime(A0),BTime
	Move.w	Leg_NbBoucles(A0),NbBoucles
	Tst.w	Leg_Horloge(A0)
	Beq.s	.NoH4	* Horloge: la bombe pète TRES bientôt ;-)
	Move.w	#BTime_VeryFast,BTime
	Move.w	#BombNbBouclesVF,NbBoucles
.NoH4	Move.w	Leg_Flamme(A0),EFlamme

	Move.l	D5,-(A7)
	Move.w	Leg_M8(A0),D5	Maladie bombe rebondi ?
	Beq.s	.NoReB42
	Move.w	#1,D5
.NoReB42	Move.w	D5,BombReb	Bombe rebondi....
	Move.l	(A7)+,D5

	Movem.l	D0-D1/D3/A0,-(A7)
	Bsr	NewBomb
	Movea.l	A0,A1
	Movem.l	(A7)+,D0-D1/D3/A0
	Tst.l	D7
	Beq.s	.NoH
	Tst.w	Leg_Horloge(A0)
	Beq.s	.NoH
	Move.w	#-1,Bomb_Horloge(A1) Bombe blockée par l'horloge
	Move.l	A0,Bomb_JMem(A1)	Pour l'horloge *Bombe->Leg
	Move.l	A1,Leg_HMem(A0)	Pour l'horloge *Leg->Bombe
.NoH	RTS

********** 	Gérer les collisions entre joueurs
*
*
*
SprCol
	

*
* 2 solutions  : faire une routine de collisions à la fin de la gestion
* de tous les joueurs, ou tester pour chaque joueur au fur et à mesure.
* problème : comment réagir lorsque l'on collisionne avec 2 ou 3
* joueurs ? 
* Choix: Lors de contacts, toutes les maladies sont refilées à l'autre 
* Maladie particulière: Vitesse : la vitesse fast remplace la slow.
*

	Movem.l	A0-A1,-(A7)
	Move.l	LegoPtr,A4	
	Lea	Tri,A3
	Move.w	(A3)+,D4
	Mulu.w	#Leg_SizeOf,D4
	Lea	(A4,D4.w),A0	Sprite 6

	Move.w	(A3)+,D4
	Mulu.w	#Leg_SizeOf,D4
	Lea	(A4,D4.w),A1	Sprite 4

	Move.w	(A3)+,D4
	Mulu.w	#Leg_SizeOf,D4
	Lea	(A4,D4.w),A2	Sprite 2

	Move.w	(A3)+,D4
	Mulu.w	#Leg_SizeOf,D4
	Lea	(A4,D4.w),A3	Sprite 0

	*
	* 4-6  (14)	SPRITE 0: Le Plus devant, donc le plus bas
	* 2-6  (13)
	* 2-4  (12)
	* 0-6  (11)
	* 0-4  (10)
	* 0-2  (09)
	*	
	Move.w	ClxDat,D4

*	And.w	#%0000111000000000,D4
*	Beq.s	.NoCol
*	Move.w	#$0FF,$dff180
*	Move.w	#1,Leg_VitJou(A3)
	
.NoCol	Btst	#14,D4		Transmettre les maladies
	Beq.s	.No46
	Movea.l	A0,A4
	Movea.l	A1,A5
	Bsr	FileMal
	Movea.l	A0,A5
	Movea.l	A1,A4
	Bsr	FileMal
.No46	Btst	#13,D4
	Beq.s	.No26
	Movea.l	A0,A4
	Movea.l	A2,A5
	Bsr	FileMal
	Movea.l	A0,A5
	Movea.l	A2,A4
	Bsr	FileMal	
.No26	Btst	#12,D4
	Beq.s	.No24
	Movea.l	A1,A4
	Movea.l	A2,A5
	Bsr	FileMal
	Movea.l	A1,A5
	Movea.l	A2,A4
	Bsr	FileMal
.No24	Btst	#11,D4
	Beq.s	.No06
	Movea.l	A0,A4
	Movea.l	A3,A5
	Bsr	FileMal
	Movea.l	A0,A5
	Movea.l	A3,A4
	Bsr	FileMal	
.No06	Btst	#10,D4
	Beq.s	.No04
	Movea.l	A1,A4
	Movea.l	A3,A5
	Bsr	FileMal
	Movea.l	A1,A5
	Movea.l	A3,A4
	Bsr	FileMal
.No04	Btst	#9,D4
	Beq.s	.No02
	Movea.l	A2,A4
	Movea.l	A3,A5
	Bsr	FileMal
	Movea.l	A2,A5
	Movea.l	A3,A4
	Bsr	FileMal
.No02	Movem.l	(A7)+,A0-A1
	RTS


********* Les autres joueurs non encore apparus sont considérés comme morts
*
*
non_app_mort
	Movem.l	D0-D3/A0,-(A7)
.NoMAJ	Movea.l	LegoPtr,A0
	Clr.l	D2	
.LoopJMA	Tst.w	Leg_Activated(A0)	Joueur en vie actuellement ?
	Bne.s	.OkJMA		Oui... Il ne "meurt" pas !
	Cmp.w	#4,D2	<=4° joueur ? pas de problème
	Blt.s	.NoProb
	Tst.w	ModeAct
	Beq.s	.NoMAJM	Si >4 et mode actuel=4: marche pas !
.NoProb	Move.w	Leg_BarreBlocX(A0),D3
	Move.w	Leg_BarreY(A0),D4
	Moveq	#15,D5		Croix: mecs absents
	Bsr	Bloc32x16cop
.NoMAJM	Move.w	#-1,Leg_Mort(A0)
	Move.w	#20,Leg_DontMove(A0)
.OkJMA	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D2	
	Cmp.w	#NbJoueurs,D2
	Blt.s	.LoopJMA
	Movem.l	(A7)+,D0-D3/A0
	RTS


******** Tous les joueurs sont tués, afin de préparer le retour au menu...
*
* Retour: D2: Nombre de joueurs tués
*
All_Mort
	Movem.l	D1/D3/A0,-(A7)
	Movea.l	LegoPtr,A0
	Clr.l	D2	Nombre de joueurs tués
	Clr.l	D3
.Loop	Tst.w	Leg_Mort(A0)
	Blt.s	.Deja
	Tst.w	Leg_Activated(A0)
	Beq.s	.Deja
	Addq.w	#1,D2
	Move.w	#ImDebMortFl,Leg_Mort(A0)
.Deja	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D3
	Cmp.w	#NbJoueurs,D3
	Blt.s	.Loop
	Tst.w	D2
	Beq.s	.NoS
	**** Son de la mort
	Moveq	#1,D3
	Moveq	#PriSonMort,D1	Mort juste un peu prioritaire !
	Clr.w	SampleLoops
	Bsr	PlaySon
.NoS	Movem.l	(A7)+,D1/D3/A0
	RTS


	**** Quand on commence un nouveau level qui n'est
	*    pas une reprise après un don't move...
	*
InitsDontMove
	Movem.l	D2/A0,-(A7)
	Move.w	#-1,NewLevel
	Movea.l	LegoPtr,A0
	Clr.l	D2	
.LoopJMA	Clr.w	Leg_DontMove(A0)
	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D2
	Cmp.w	#NbJoueurs,D2
	Blt.s	.LoopJMA
	Movem.l	(A7)+,D2/A0
	RTS

*** On affiche toutes les gueules des joueurs en vie pour changement
* info bar. Cette routine est appelée depuis la gestion (RequestForNewBar)
*
AffAllGueules
	Movem.l	D0-D3/A0,-(A7)
	Movea.l	LegoPtr,A0
	Clr.l	D2
.LoopAff	Tst.w	Leg_Activated(A0)	Joueur en vie actuellement ?
	Beq.s	.NoAff		Non: Pas affichage
	Tst.w	Leg_Mort(A0)	
	Bne.s	.NoAff	Pas de changement 4->6 si >0 joueur mort!
	* Affiche la gueule du mec
	Move.w	Leg_BarreX(A0),D3
	Move.w	Leg_BarreY(A0),D4
	Move.w	Leg_BarreBase(A0),D5	>Content<, dort, triste
	Bsr	Bloc32x16cop	
	* Affiche la case correspondante du mec
	Move.w	Leg_BarreBlocX(A0),D3
	Move.w	Leg_BarreY(A0),D4
	Moveq	#16,D5		Case vide... on va pas copier les
	Bsr	Bloc32x16cop	bonus en plus !
	*
.NoAff	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D2
	Cmp.w	#NbJoueurs,D2
	Blt.s	.LoopAff
	Movem.l	(A7)+,D0-D3/A0
	RTS


PosTo4	Movem.l	D0/A0,-(A7)
	Move.l	LegoPtr,A0
	Moveq	#NbJoueurs-1,D0	On fait tout...
.LoopJ	Move.w	Leg_BarreX4(A0),Leg_BarreX(A0)
	Move.w	Leg_BarreY4(A0),Leg_BarreY(A0)
	Move.w	Leg_BarreBase4(A0),Leg_BarreBase(A0)	
	Move.w	Leg_BarreBlocX4(A0),Leg_BarreBlocX(A0)
	Adda.w	#Leg_SizeOf,A0
	Dbf	D0,.LoopJ
	Movem.l	(A7)+,D0/A0
	RTS

PosTo8	Movem.l	D0/A0,-(A7)
	Move.l	LegoPtr,A0
	Moveq	#NbJoueurs-1,D0	On fait tout...
.LoopJ	Move.w	Leg_BarreX8(A0),Leg_BarreX(A0)
	Move.w	Leg_BarreY8(A0),Leg_BarreY(A0)
	Move.w	Leg_BarreBase8(A0),Leg_BarreBase(A0)	
	Move.w	Leg_BarreBlocX8(A0),Leg_BarreBlocX(A0)
	Adda.w	#Leg_SizeOf,A0
	Dbf	D0,.LoopJ
	Movem.l	(A7)+,D0/A0
	RTS


***************  Afficher tous les joueurs qui dorment (début level)
*		ou qui pleurent pour une reprise "don't move".
*
*
AffAllJoueurs
	Movea.l	LegoPtr,A0
	Moveq	#4-1,D7		MODE 4 joueurs		
	Tst.w	ModeAct
	Beq.s	.Loop
	Moveq	#NbJoueurs-1,D7	MODE 6 joueurs
.Loop	Move.w	Leg_BarreX(A0),D3
	Move.w	Leg_BarreY(A0),D4
	Move.w	Leg_BarreBase(A0),D5	
	Addq.w	#2,D5			+2: Triste
	Moveq	#30,D6			"WAIT"
	Tst.w	Leg_Mort(A0)
	Bne.s	.Cop	
	Moveq	#14,D6			"PRESS FIRE"
	Subq.w	#1,D5			+2-1=+1: Dort
.Cop	Bsr	Bloc32x16cop		(D3/D4/D5)
	Move.w	Leg_BarreBlocX(A0),D3
	Move.w	Leg_BarreY(A0),D4
	Move.l	D6,D5
	*Moveq	#14,D5
	Bsr	Bloc32x16cop
	Adda.w	#Leg_SizeOf,A0
	Dbf	D7,.Loop	
	RTS	






*****************

	*********** Trouver l'offset de la case en fonction du (X,Y)
	*
	* Registres utilisés: D2,D3,D5,D6
	*
	*    A0: Structure du joueur
	* -> D6: Offset (Grosses cases)
	*
FindOffsetFromXY
	
	Move.w	Leg_X(A0),D2
	Add.w	#-128+HotX,D2
	Move.w	Leg_Y(A0),D3
	Add.w	#-46+HotY,D3

	Move.w	D3,D6		Calcul offset normal
	Lsr.w	#3,D6
	Bclr	#0,D6		/8 avec arrondi sur 16: grosse case

	Lsl.w	#6,D6

	Move.w	D2,D5
	Lsr.w	#3,D5	
	Bclr	#0,D5

	Add.w	D5,D6		

	* D6 (.W) : N° de la case en absolu

	Ext.l	D6
	Lsl.l	#2,D6

	* D6 (.L) : OFFSET de la case dans les Dim (à part Dim4)

	RTS




	*********** Routine de collision par case
	*
	* Gestion des collisions de 2-8 joueurs.
	*
	* Compte tenu du fait que je me fous de l'ordre mais que je veux
	* juste trouver les joueurs qui sont sur la même case, je fais ça
	* simple.
	*
	*
ColJoue	*Movem.l	
	Clr.l	D7              Nombre de joueurs en vie (nbjoueursenvie ?)
	Move.l	LegoPtr,A4
	Lea	TriJoueWork,A2
	Movea.l	A2,A3
	Moveq	#NbJoueurs-1,D4
.LoopJ	Tst.w	Leg_Mort(A4)
	Bne.s	.nop
	Tst.w	Leg_TelePhase(A4)       pas de contact si téléporte
	Bne.s	.nop
	Tst.w	Leg_Activated(A4)
	Bge.s	.nop
	* Joueur accepté pour le test des collisions
	Movea.l	A4,A0
	Bsr	FindOffsetFromXY     (A0->D6) Utilisation de D2,D3,D5,D6
	Move.w	D6,(A2)+		Offset en cases, donc max 63*64<32768
	Move.l	A4,(A2)+		Struct
	Move.l	D7,D3
	Addq.w	#1,D7
	Tst.w	D7
	Beq.s	.Nop
	Movea.l	A3,A1
.ChchSame	Move.w	(A1),D5	
	Cmp.w	D6,D5
	Bne.s	.NexCh
	Move.l	2(A1),A5
	Bsr	FileMal      (A4->A5) Utilisation de D5
	Exg	A4,A5
	Bsr	FileMal
	Exg	A4,A5
.NexCh	Lea	6(A1),A1
	Dbf	D3,.ChchSame
	
.Nop	Adda.w	#Leg_SizeOf,A4
	Dbf	D4,.LoopJ

	RTS


	********** Filer des maladies
	*
	* A4: Mec donnant les maladies
	* A5: Mec recevant les maladies
	*
FileMal
	Move.w	#-1,DonneMalOK
	
	Tst.w	Leg_Mort(A4)	Mec mort(anti bug)...
	Bne	.EndM		
	Tst.w	Leg_Mort(A5)	Receveur mort(optz)...
	Bne	.EndM		

	Move.w	Leg_M1(A4),D5	MALADIE 1: Inversion
	Beq.s	.NoM1		
	Tst.w	Leg_M1(A5)	Il l'a déjà...
	Bne.s	.NoM1	
	Move.w	D5,Leg_M1(A5)	Temps actuel à l'autre
*	Move.w	#Time_Malad,Leg_M1(A5)	
	Lsr.w	#1,D5
	Move.w	D5,Leg_M1(A4)	Nous: Temps/2
	Clr.w	DonneMalOK
.NoM1
	Move.w	Leg_M2(A4),D5	MALADIE 2: Taille flammes
	Beq.s	.NoM2
	Tst.w	Leg_M2(A5)
	Bne.s	.NoM2		Il l'a déjà...		
	Move.w	Leg_Flamme(A5),Leg_M2Mem(A5)
	Move.w	Leg_Flamme(A4),Leg_Flamme(A5)
	Move.w	D5,Leg_M2(A5)
*	Move.w	#Time_Malad,Leg_M2(A5)
	Lsr.w	#1,D5
	Move.w	D5,Leg_M2(A4)
	Clr.w	DonneMalOK
.NoM2	
	Move.w	Leg_M3(A4),D5	MALADIE 3: Time bombes
	Beq.s	.NoM3
	Tst.w	Leg_M3(A5)
	Bne.s	.NoM3		Il l'a déjà...
	Move.w	Leg_M3Mem2(A4),Leg_M3Mem2(A5)
	Move.w	Leg_M3Mem3(A4),Leg_M3Mem3(A5)
	Move.w	Leg_BTime(A4),Leg_BTime(A5)
	Move.w	Leg_NbBoucles(A4),Leg_NbBoucles(A5)
	Move.w	D5,Leg_M3(A5)
*	Move.w	#Time_Malad,Leg_M3(A5)
	Lsr.w	#1,D5
	Move.w	D5,Leg_M3(A4)
	Clr.w	DonneMalOK
.NoM3
	Tst.w	Leg_M4(A4)	MALADIE 4: vitesse/Lenteur
	Beq.s	.NoM4		Maladie TRES agréable, je ne suis
	Move.w	Leg_VitJou(A4),D5	donc pas "radin" sur le temps...
	Tst.w	Leg_M4(A5)
	Beq.s	.All4			Il l'a pas
	Cmp.w	Leg_VitJou(A5),D5		Déjà... On prend le max
	Ble.s	.NoM4			Idem, pas de changement
.All4	Move.w	Leg_VitJou(A5),Leg_M4Mem(A5)
	Move.w	D5,Leg_VitJou(A5)
	Move.w	#Time_Malad,Leg_M4(A5)
	Clr.w	DonneMalOK
.NoM4
	Move.w	Leg_M5(A4),D5	MALADIE 5: pose plus de bombes (=0)
	Beq.s	.NoM5
	Tst.w	Leg_M5(A5)
	Bne.s	.NoM5		Il l'a déjà...	
	Move.w	D5,Leg_M5(A5)	Lui: Peine que l'on avait
*	Move.w	#Time_Malad,Leg_M5(A5)		
	Lsr.w	#1,D5
	Move.w	D5,Leg_M5(A4)	Nous: allégement de la peine
	Clr.w	DonneMalOK
.NoM5
	
	Move.w	Leg_M6(A4),D5	MALADIE 6: Plus de bombes (+10)
	Beq.s	.NoM6
	Tst.w	Leg_M6(A5)
	Bne.s	.NoM6	
	Add.w	#NbBombMore,Leg_MaBomb(A5)		+10 bombes !
	Add.w	#NbBombMore,Leg_M6Mem(A5)		Nombre à soustraire !
	Move.w	D5,Leg_M6(A5)
*	Move.w	#Time_Malad,Leg_M6(A5)
	Lsr.w	#1,D5
	Move.w	D5,Leg_M6(A4)	Idem: on se fait piquer du temps
	Clr.w	DonneMalOK
.NoM6
	Move.w	Leg_M7(A4),D5	MALADIE 7: Invincible aux flammes
	Beq.s	.NoM7
	Tst.w	Leg_M7(A5)
	Bne.s	.NoM7	
	Move.w	D5,Leg_M7(A5)	On file le temps ACTUEL (Pas de remise à 0 pour ce bonus)
*	Move.w	#Time_Malad,Leg_M7(A5)
	Lsr.w	#1,D5
	Move.w	D5,Leg_M7(A4)	On se fait niquer temps/2 !!! :-)
	Move.w	#Time_Clignote_Invincible,Leg_M7Mem(A5)		Par contre, on met le clignotement à 0 pour éviter les phases
	Clr.w	DonneMalOK
.NoM7

	Move.w	Leg_M8(A4),D5	MALADIE 8: Bombes rebondissent
	Beq.s	.NoM8
	Tst.w	Leg_M8(A5)
	Bne.s	.NoM8	
	Move.w	D5,Leg_M8(A5)	On file le temps ACTUEL (Pas de remise à 0 pour ce bonus)
	Lsr.w	#1,D5
	Move.w	D5,Leg_M8(A4)	On se fait niquer temps/2 !!! :-)
	Clr.w	DonneMalOK
.NoM8
	Move.w	Leg_M9(A4),D5	MALADIE 9: Collique
	Beq.s	.NoM9
	Tst.w	Leg_M9(A5)	A4:Donne A5:Reçoit
	Bne.s	.NoM9	
	Move.w	D5,Leg_M9(A5)	On file le temps ACTUEL (Pas de remise à 0 pour ce bonus)
	Lsr.w	#1,D5
	Move.w	D5,Leg_M9(A4)	On se fait niquer temps/2 !!! :-)
	Clr.w	DonneMalOK
.NoM9
	Move.w	Leg_M10(A4),D5	MALADIE 10: ?
	Beq.s	.NoM10
	Tst.w	Leg_M10(A5)
	Bne.s	.NoM10	
	Move.w	D5,Leg_M10(A5)	On file le temps ACTUEL (Pas de remise à 0 pour ce bonus)
	Lsr.w	#1,D5
	Move.w	D5,Leg_M10(A4)	On se fait niquer temps/2 !!! :-)
	Clr.w	DonneMalOK
.NoM10

.EndM

	Tst.w	DonneMalOK
	Bne.s	.NoDon

	Movem.l	D0-D7/A0-A6,-(A7)
	Move.w	Leg_BarreBlocX(A5),D3
	Move.w	Leg_BarreY(A5),D4
	Move.w	#ImMaladie,D5		Image récupère maladie
	Bsr	Bloc32x16cop
	Movem.l	(A7)+,D0-D7/A0-A6

.NoDon
	RTS



****************** Mettre la bonne valeur dans BarrePtrW
*
*
* D0: N° de la barre (I4,I6,T4,T6)
*
*
SetOneBarreJ
	Move.l	A0,-(A7)
	Lea	BarreJoueurs,A0
	Move.l	(A0,D0.w*4),BarrePtrW
	Move.l	(A7)+,A0
	RTS


**
*
* NbJoueursEnVie: Tout joueur non mort (Apparu ou non, affecté ou non)
* NbJact:         Joueurs actuellement sur le tableau de jeu
*	compteur modifié dans la VBL, on peut pas l'utiliser
*	n'importe quand.	
* NbJAct2:        = NbJAct mais utilisable n'importe quand
*
**


