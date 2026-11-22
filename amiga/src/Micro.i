

*********** Routine de MICRO pour faire jouer l'ordinateur
*
* ENTREES:  (Ne pas modifier)
*  A0: Adresse de la structure du joueur à diriger (micro)
*     Dans structure: Leg_VitJou(A0)  VITESSE déplacement joueur (en pixels)
*  D0: $00000000
*  D1: $00000000
*  D2: ?
*  D3: N° du joueur à diriger (micro) (0-NbJoueurs)
*
* SORTIES:
*  D4: $FF=Feu  $00=Pas Feu  (.b)
*  D0: Mouvement en Pixels que l'on veut faire en X  
*  D1: Mouvement en Pixels que l'on veut faire en Y
*  (Personne n'a le droit aux diagonales, une routine est executée pour
*  tous les joueurs pour ça: Si diagonale, la première direction enclenchée
*  a la priorité: L'autre est mise à 0)
*
*
Routage_Nb	=	45	30: entre 1/3 et 1/4 VBL
MicroRoutageVBL	=	-1	Pour arrêter ou pas en fin routage

Micro_TempsSafe	=	255	Valeur par défaut temps case vide

	RsReset	* Dim Routage
Route_Struct 	Rs.w	0	
Route_ID		Rs.b	1	N° du routage
Route_NbFils	Rs.b	1	Danger de la case 
Route_DangerSrc	Rs.b	1
Route_Danger	Rs.b	1
Route_DirSrc	Rs.b	1	D'ou on vient pour cette case
Route_Points	Rs.b	1
Route_OK		Rs.b	1
Route_BombOk	Rs.b	1	Case <> ligne ou colonne actuelles!
Route_FILL	Rs.b	0
Route_DECAL	Rs.b	64*4


	RsReset
LiCo_Stuct	Rs.w	0
LiCo_Time		Rs.w	1
LiCo_DEBUG	Rs.w	1
LiCo_FILL		Rs.w	2
Lico_SizeOf	Rs.w	0

Danger_DEC	=	2	Le danger diminue de N à chq boucle

Danger_Bomb	=	10
Danger_Toyo	=	2
Danger_Flamme	=	50	Danger Absolu

*Danger_TimeBombAlert=	16	
*Micro_PeurFlamme	=	1	Nb de cases de marge par rapport au bout prévu de la flamme
*Micro_PeurCasesDanger	= 	3	0=Pas peur 10=Peur

Micro
	Clr.l	D0
	Clr.l	D1
	Clr.l	D4
	*Movem.l	D2-D3/A0,-(A7)	REGISTRES VITAUX (Sprites2.i/Joueurs)
	Movem.l	D2-D3/D5-D7/A0-A6,-(A7)

	*Clr.w	Leg_Fire(A0)	Contrairement aux joystick, il faut remettre à 0 "à la main"
	*********** Pour que le micro appuye sur FEU au début d'un Level
	Movea.l	ClavierPtr,A1
	Tst.b	65(A1)		BackSpace: On oblige le micro
	Bne.s	.Test		à apparaître le premier
	Tst.w	ExeLevel
	Bge	.EndMicro		Ce n'est pas le premier à apparaître
.Test	Tst.w	Leg_activated(A0)
	Bne.s	.DejaOk
.Feu	*Move.b	#-1,Leg_Fire(A0)	Si Activated=0, on met Feu=1	
	Move.w	#$FF,D4
	Move.l	A0,MicroPtr
	Bra	.EndMicro
.DejaOk	***********

	Move.w	Leg_VitJou(A0),D4	Vitesse actuelle du joueur à gérer
	Move.w	D4,Micro_Vitesse

	Move.l	A0,MicroActPtr

	*********************
	*** MICRO	ROUTAGE ***	toutes les Vbl
	*********************
	Move.w	#30,MicroConfig_BombRND		
	Move.w	#20,MicroConfig_BombDelai	
	Move.w	#70,MicroConfig_BonusBombPt	
	Move.w	#50,MicroConfig_BonusFlamPt
	Move.w	#0,MicroConfig_BonusAutrPt	Négatif: interdiction!	
	Move.w	#-1,MicroConfig_BestRoute	Booléen: pleutre ou pas ?
	Move.w	#15,MicroConfig_RouteDangPoints	valeur de 1 trigger
	Move.w	#-1,MicroConfig_PoseBombIfSafe	Booleen
	Move.w	#24,MicroConfig_PoseBombDangerMax	<=: pose pas
	Move.w	#3,MicroConfig_PeurCasesDanger

	Jsr	VBLDEBUG_START
	*Movea.l	MicroPtr,A0	pour l'instant un seul micro
	*Tst.l	A0
	*Beq.s	.NoMicro

	Clr.l	Temp1
	Clr.l	Temp2	

	Clr.w	Micro_RoutageEtat	Pour qu'il recommence à 0 !
	Jsr	Micro_Routage
.NoMicro	
	Jsr	Micro_RoutageChoixNewPointEnd

	Move.l	Micro_ChchCaseChoisie,Micro_ChchCaseChoisieSearch	
	*Move.l	Micro_ChchCaseChoisie,Temp2	


	Move.w	Micro_Vitesse,D5
	Clr.l	D4		Pas de feu
	Clr.l	D0
	Clr.l	D1

	Move.w	Micro_ChchFire,D4	Feu
	Movea.l	MicroActPtr,A0
	Tst.w	Leg_FireAnc(A0)
	Beq.s	.FeuOk
	Clr.w	D4		Simuler un autofire	
.FeuOk
	
	*Move.w	D4,Temp2+2

	Move.w	Micro_ChchDirSrc,D2
	Beq.s	.NoMvt
	Cmp.w	#1,D2
	Bne.s	.MvNoH
	Sub.w	D5,D1		Haut
	Bra.s	.NoMvt
.MvNoH	Cmp.w	#2,D2
	Bne.s	.MvNoD
	Move.w	D5,D0		Droite	
	Bra.s	.NoMvt
.MvNoD	Cmp.w	#3,D2
	Bne.s	.MvNoB
	Move.w	D5,D1		Bas
	Bra.s	.NoMvt
.MvNoB	Cmp.w	#4,D2
	Bne.s	.MvNoG
	Sub.w	D5,D0		Gauche	
	*Bra.s	.NoMvt
.MvNoG
	

.NoMvt
	Move.w	Micro_ChchDirSrc,Micro_DirSrcAnc

***********************************************************************
*	 		FIN MICRO				*
***********************************************************************


.EndMicro	
	Jsr	VBLDEBUG_END

	Tst.w	CHEAT_ENABLED
	Beq.s	.NoCheat
	Movem.l	D0/D1,-(A7)
	
	*Move.w	Micro_ChchDanger,Temp1
	*Move.w	Micro_ChchDangerSrc,Temp1+2
	Move.w	Micro_ChchDirSrc,Temp2
	Move.w	Micro_TotNb,Temp2+2


	*Move.w	Micro_RouteStep,Temp2
	*Move.w	Micro_RoutageID,Temp1
	*Move.l	Micro_ChchCaseChoisie,D0	DEBUG
	*Move.w	D0,Temp2+2

	Moveq	#0,D1
	Jsr	DEBUG
	Movem.l	(A7)+,D0/D1
.NoCheat

	*Movem.l	(A7)+,D2-D3/A0
	Movem.l	(A7)+,D2-D3/D5-D7/A0-A6
	RTS


***** Petite case(X,Y) -> Offset
* 
* Position (X=D2,Y=D3) -> Offset (D6.L)
*
Micro_CalcOffset
	Move.w	D3,D6
	Lsl.w	#6,D6		*64: Taille d'une ligne
	Add.w	D2,D6
	Ext.l	D6
	Lsl.l	#2,D6		*4: SizeStructure
	RTS

***** Transformer D0,D1 (nX,nY) en mouvement normé D3,D4 (1,1)
*
*
*
Micro_DirecOne	
	* Inits pour pousse bombe
	Clr.l	D2
	Tst.w	D0
	Bgt.s	.PlGr1
	Beq.s	.Zer1
	Moveq	#-1,D2		Direction que va prendre la bombe
	Bra.s	.Zer1
.PlGr1	Moveq	#1,D2		D3 à GARDER
.Zer1	Clr.l	D3
	Tst.w	D1
	Bgt.s	.PlGr2
	Beq.s	.Zer2
	Moveq	#-1,D3
	Bra.s	.Zer2
.PlGr2	Moveq	#1,D3		D4 à GARDER
.Zer2	RTS	


	
*Micro_MvtX 	Dc.l	0
*Micro_MvtY	Dc.l	0
Micro_MvtXPix 	Dc.l	0
Micro_MvtYPix	Dc.l	0
Micro_MvtXMem	Dc.w	0
Micro_MvtYMem	Dc.w	0
	
*
*
* Le micro est géré comme un joystick.
*
* Il faudrait que le micro fasse un routage global mais peu à peu si 
* nécessaire.
* C'est à dire qu'il faudrait qu'il analyse TOUT tout le temps, 
* mais un peu à chaque VBL !!! :-)
*
* Donc technique mixte:
* Une routine cherche sans arrêt à mettre à jour les informations
* des dims de réflexion. Il ne faut pas se priver car cela se 
* fait de manière asynchrone.
*
* Dans la VBL, le micro suit la route pré-définie. Une fois 
* que sa cible est atteinte, il route un nouveaut trajet en fonction
* du tableau mis à jour indéfiniment.
*
* La difficulté supplémentaire que je me fixe pour l'ordinateur est 
* qu'il faut que la réflexion serve pour TOUS les micros d'un coup.
* 
*  
* Routage depuis le micro:
* problème: comment prendre en compte les bombes ?
* 
* Routage long: dès que l'on trouve une bombe on revient pour marquer les
* cases comme dangereuses.
* 1 point de routage par bombe à la base. Mais routage des bombes 
* beaucoup moins difficile. Pbl: mouvement des bombes
*
*
*
* ROUTAGEDANGER.AMOS:
*	Sert à marquer dans un tableau toutes les cases de danger.
*	C'est à dire les cases en face directement de bombes,
*	et les cases en face de tuyaux. 
*	
*	Ce routage peut servir à tous les MICROS en même temps.
*
*	Ce routage peut être fait dans la routine qu sert aussi à gérer
*	les bombes, c'est à dire en dehors de la VBL. Il peut être fait
*	relativement rarement, mais il faudrait qu'il soit fait au 
*	moins deux fois pendant le temps d'attente avant explosion d'une
*	bombe. 
*	DONC PAS DE PBL!
*
*	Comme je route depuis le joueur, je peux en profiter pour faire 
*	absolument tout ?
*	- recherche d'une case sans danger (2ème routage, après 
*	  expansion maxi de toutes les bombes!). 
*	  Passer par le moins de case dangereuses pour rejoindre 
*	  une case safety.
*	- recherche d'un bonus
*
*	
* Reste à faire:
*	Routage pour CHOISIR la voie à prendre !!!
* 
*	Il faut router pour chercher une voie, dès que l'on a trouvé
* 	une cible il faut faire le chemin inverse et inscrire toutes les
*	cases dans un tableau, que le micro suivra.
*	- ? Il faut vérifier à chaque case que le danger n'a pas évolué.
*	- Si le chemin est bouché, il faut que le micro trouve un 
*	autre chemin. Il faut donc recommencer le routage à 0 pour 
*	accélérer le temps de réaction: il ne pourra réagir qu'une fois
*	que le routage aura trouvé une case libre.
*
*	
	
************ ROUTAGE DU MICRO
*
* Routine asynchrone de routage
* A0: Structure du joueur micro
* J'ai pris la même taille de Dim pour le micro pour que les 
* offsets soient utilisables facilement dans tous les cas.
*
* DimIA1: 64*64*4	
*		.B: N° du routage
*		.B: Danger
*		.B: Direction source
*
* DimIA2: 300*4*2	Souce(X.W,Y.W),Cible(X.W,Y.W)
*		8 octets par case
*
* DimIA3: 4*64*2	Danger des colonnes et des lignes
*			
*
* Faire une boucle et appeler ceci autant de fois que nécessaire
* en fonction de la puissance de la bécane.
* Sachant que un appel sert à lire 4 points de routage !!!
* (Vraiment très peu de temps machine !)
*
* Totalité du routage pour l'exemple AMOS: 288 pas.
* Donc si 30 par boucle, 10 boucles nécessaires pour couvrir
* tout le niveau. <- 10 = relativement énorme
*
*
*
* Avec une boucle de routage de 30 pas, la distance de vision est 
* très correcte.
*
*
*
Micro_Routage
	Movem.l	D0-D7/A1-A6,-(A7)


	*
	* Tests pour le temps entre deux bombes que le micro pose
	*
	* Délai respecté ?
	Move.w	#0,Micro_BombAllowed
	Move.w	Micro_BombDelai,D0
	Beq.s	.BBRNDOK
	Sub.w	#1,D0
	Move.w	D0,Micro_BombDelai
	Bra.s	.BBRNDNOk		Pas le droit
	* RND respecté ?
.BBRNDOK	Clr.l	D1
	Move.w	MicroConfig_BombRND,D1		N chances sur 65536...
	Jsr	Rnd_Bool		
	Tst.l	D0
	Beq.s	.BBRNDNOk
	Move.w	#$FF,Micro_BombAllowed
.BBRNDNOk


	Move.w	#-1,Micro_Routage_Active
	Moveq	#Routage_Nb,D0	En moyenne = Nb de cases vues
.Loop
	Move.l	D0,-(A7)
	Bsr	Micro_Routage_Step
	Move.l	(A7)+,D0
	Tst.w	Micro_Routage_Active
	Beq.s	.LoopEnd	
	Dbf	D0,.Loop
.LoopEnd
	Movem.l	(A7)+,D0-D7/A1-A6	
	RTS
	

	****************************************
	*    Un pas d'exécution des routages   *
	****************************************
Micro_Routage_Step	
.Init
	Tst.w	Micro_RoutageEtat	0:Init à faire
	Bne.s	.LoopStart	
	Bsr	InitsRoutage
	Bra	Micro_RoutageEnd	découpe (BEAUCOUP!) le temps machine

	**********************************
	* Routage: gestion des 2 boucles *
	**********************************
.LoopStart
	
	Move.w	Micro_SrcLoop,D0	For...Next de la liste source
	Add.w	#1,D0		premier: 1
	Move.w	D0,Micro_SrcLoop
	Move.w	Micro_SrcNb,D1	nombre: 1..300
	Bgt.s	.LoopStartOk
	* 0 points dans la liste source: 
	IFNE	MicroRoutageVBL
	* Mode routage VBL: Arrêter pour conserver le temps machine!
		Clr.w	Micro_Routage_Active
		Bra	Micro_RoutageEnd
	ELSE
	* Mode routage infini: recommencer à 0
		Clr.w	Micro_RoutageEtat		
		Bra.s	.Init
	ENDC
	*Bra	Micro_RoutageEnd	DEBUG: on découpe les opérations
.LoopStartOk
	Cmp.w	D0,D1
	Bge.s	.LoopOk	
	Move.w	Micro_CibID,D1		Swap listes Src <-> Cib
	Move.w	Micro_SrcID,Micro_CibID
	Move.w	D1,Micro_SrcID	
	Move.w	Micro_CibNb,Micro_SrcNb	Récup Nb points 
	Clr.w	Micro_SrcLoop	Remise à 0 compteur Loop
	Move.w	#0,Micro_CibNb	
	Add.w	#1,Micro_RouteStep
	* Nouveau For..Next pour prochaine étape liste de points
	Bra.s	.LoopStart	Etape suivante
	*Bra	Micro_RoutageEnd	DEBUG: on découpe les opérations
.LoopOk	
	****************************************************
	* Routage: avance des points autour d'UN point Src *
	****************************************************

	Movea.l	DimIA1,A1		Dim Tableau
	Movea.l	DimIA2,A2		Dim Liste de points (D0: 1..Nb)
	Subq.w	#1,D0
	Lsl.w	#3,D0
	Add.w	Micro_SrcID,D0	Bascule à chq nouveau pas: 0 ou 4
	Move.l	(A2,D0.w),D0	Point

	Clr.w	Micro_FilsNb

	Movea.l	Dim2,A3		Dim Visible
	Move.w	D0,D1		Y.W
	Swap	D0		X.W

	Move.w	D1,D7
	Lsl.w	#6,D7
	Add.w	D0,D7
	Ext.l	D7
	Lsl.l	#2,D7		Offset du point actuel (source)	

	Lea	(A1,D7.l),A4
	Move.l	A4,Micro_CaseActPtr	  Pointeur case actuelle Routage

* Marquer la direction de DEPART;
* Le premier point prend la bonne direction par rapport au joueur,
* puis tous les autres point issus garderont cette direction. Comme ça
* quand on trouve une bonne case, on sait quelle direction de DEPART
* il faut prendre. Cette technique est utilisable parce que le micro
* route à chaque fois qu'il fait un pas.
*
	Clr.w	D4
	Move.b	Route_DirSrc(A4),D4		Direction source
	Beq.s	.DirZ
	Move.w	D4,Micro_DirH
	Move.w	D4,Micro_DirD
	Move.w	D4,Micro_DirB
	Move.w	D4,Micro_DirG
	Bra.s	.DirF	
.DirZ
	Move.w	#1,Micro_DirH
	Move.w	#2,Micro_DirD
	Move.w	#3,Micro_DirB
	Move.w	#4,Micro_DirG
.DirF	
	*Move.w	#2*SizeStructure,D4
	*Move.w	#-2*SizeStructure,D4
	*Move.w	#-2*64*SizeStructure,D4
	*Move.w	#2*64*SizeStructure,D4
		
	
	* Lire le danger de la case actuelle
	Clr.w	D4
	Move.b	Route_DangerSrc(A4),D4
	Move.w	D4,Micro_DangerSrc		Danger actuel (src pour autres)
	Move.b	Route_DirSrc(A4),D4
	Move.w	D4,Micro_DirAnc
	Move.b	Route_BombOk(A4),D4
	Move.w	D4,Micro_BombOk

	Add.w	#2,D0		Case Droite
	Cmp.w	#36,D0		H: 19 cases = 36 petites 
	Bge.s	.NoD
	Move.w	Micro_RoutageID,D2	 	N° du routage
	Move.w	Micro_DirD,Micro_Dir
	Move.w	#2,Micro_DirBB
	Bsr	Micro_RoutageAjoutPoint
.NoD	Sub.w	#4,D0		Case gauche
	Blt.s	.NoG
	Move.w	Micro_RoutageID,D2	 	N° du routage
	Move.w	Micro_DirG,Micro_Dir
	Move.w	#4,Micro_DirBB
	Bsr	Micro_RoutageAjoutPoint
.NoG	Add.w	#2,D0
	Sub.w	#2,D1		Case Haut
	Blt.s	.NoH
	Move.w	Micro_RoutageID,D2	 	N° du routage
	Move.w	Micro_DirH,Micro_Dir
	Move.w	#1,Micro_DirBB
	Bsr	Micro_RoutageAjoutPoint		
.NoH	Add.w	#4,D1		Case Bas
	Cmp.w	#30,D1		V: 15 cases = 30 petites
	Bge.s	.NoB
	Move.w	Micro_RoutageID,D2	 	N° du routage
	Move.w	Micro_DirB,Micro_Dir
	Move.w	#3,Micro_DirBB
	Bsr	Micro_RoutageAjoutPoint
.NoB		
	Bsr	Micro_RoutageChoixNewPoint


Micro_RoutageEnd
	RTS




	********************************
	*        Inits du routage      *
	********************************
InitsRoutage
	Move.w	#0,Micro_SrcID
	Move.w	#1,Micro_SrcNb
	Move.w	#0,Micro_SrcLoop
	Move.w	#4,Micro_CibID
	Move.w	#0,Micro_CibNb
	Move.w	#1,Micro_RoutageEtat	0:Init 1:En cours
	Clr.w	Micro_RouteStep	0: Aucun pas
	Bsr	Micro_Coords
	Movea.l	DimIA2,A1		Dim liste de points
	Move.w	D2,(A1)		X joueur grosse case
	Move.w	D3,2(A1)		Y joueur grosse case
	** Changer de code de routage
	Move.w	Micro_RoutageID,D0
	Subq.w	#1,D0
	Bgt.s	.NoInitZ
	Move.w	#255,D0
.NoInitZ	Move.w	D0,Micro_RoutageID	
	** Inscrire le premier point dans le dim de routage!
	Movea.l	DimIA1,A2
	Move.w	D3,D6
	Lsl.w	#6,D6
	Add.w	D2,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Lea	(A2,D6.l),A2		Adresse point
	Move.l	A2,Micro_CaseActPtr
	Move.l	A2,Micro_CaseActPtrBase
	Move.b	D0,Route_ID(A2)
	Move.b	#Micro_TempsSafe,Route_DangerSrc(A2)	Danger nul: le micro ne reste jamais immobile ?
	*Move.b	#0,Route_Danger(A2)
	*Move.b	#0,Route_DangerSrc(A2)
	Move.b	#0,Route_DirSrc(A2)		Source: 0
	Move.b	#0,Route_BombOk(A2)		Pas possibilité poser bombe
	Clr.w	Micro_TotNb
	Bsr	Micro_RoutageChoixNewPoint_Init
	RTS

	********************************
	*     Coordonnées du joueur    *
	********************************
Micro_Coords
	Jsr	ScreenPos		A0 -> XScr,YScr
	Clr.l	D2
	Clr.l	D3
	Move.w	XScr,D2		Pixel sur l'écran
	Move.w	YScr,D3

	***** Mode spécial: faire croire au micro des choses !
	* But: qu'il se déplace sur le milieu des cases
	*
	* Il faut que j'arrondisse les angles du micro mais
	* seulement pendant les 2 premiers pas sur une case
	* donc double calcul nécessaire
	*
	Movem.w	D2-D3,-(A7)
	Lsr.w	#3,D2		Petite case
	BClr	#0,D2		Alignée sur grosse case
	Lsr.w	#3,D3		Petite case	
	BClr	#0,D3		Alignée sur grosse case
	Cmp.w	Micro_XCaseAnc,D2
	Beq.s	.FX
	Move.w	#2,Micro_CaseDiff
.FX	Move.w	D2,Micro_XCaseAnc

	Cmp.w	Micro_YCaseAnc,D3
	Beq.s	.FY
	Move.w	#2,Micro_CaseDiff
.FY	Move.w	D3,Micro_YCaseAnc

	Movem.w	(A7)+,D2-D3

	Move.w	Micro_CaseDiff,D5
	Beq.s	.NoChg
	Sub.w	#1,D5
	Move.w	D5,Micro_CaseDiff

	Move.w	Leg_MDX(A0),D5
	Beq.s	.NoX
	Blt.s	.XG
	Sub.w	#4,D2	
	Bra.s	.NoX
.XG	Add.w	#4,D2
.NoX
	Move.w	Leg_MDY(A0),D5
	Beq.s	.NoY
	Blt.s	.YH
	Sub.w	#4,D3	
	Bra.s	.NoY
.YH	Add.w	#4,D3	
.NoY	

.NoChg
	*****

	Lsr.w	#3,D2		Petite case
	BClr	#0,D2		Alignée sur grosse case
	Lsr.w	#3,D3		Petite case	
	BClr	#0,D3		Alignée sur grosse case
	Move.w	D2,Micro_MvtXMem
	Move.w	D3,Micro_MvtYMem
	*Bsr	Micro_CalcOffset
	RTS

	************************************
	*   Ajout d'un point de routage    *
**********************************************
*
* A0: Structure du joueur micro
* A1: DimIA1: Tableau de routage
* A2: DimIA2: Liste des points
* A3: Dim2:   Dim Visible Rien(-1), Font(0)
* D0: X
* D1: Y
* D2: N° du routage <- mis à jour à chaque appel
*
* Modifié:
* D2: Temporaire danger 
* D3: Temporaire
* D4: Temporaire danger
* D5: Temporaire
* D6: Offset sur les DIM
* A4: Pointeur temporaire DimIA3 Lig-Col
*
*
* Tous les DIM sont gérés par petites cases !
* DONC j'ai droit à 4*SizeStructure = 16 octets par case de routage!!!
*
* DimIA1: 64*64*4	
*		.B: N° du routage
*		.B: Danger
*		.B: Direction source
* 
Micro_RoutageAjoutPoint

	Clr.w	Micro_Points

	* Calcul offset dans tableau de routage (et autres du coup)
	Move.w	D1,D6
	Lsl.w	#6,D6
	Add.w	D0,D6
	Ext.l	D6
	Lsl.l	#2,D6	
	
	Lea	(A1,D6.l),A5
	
	Move.b	Route_ID(A5),D3	Test N° du routage
	Cmp.b	D3,D2
	Beq	.Micro_RoutageAjoutPointEnd

	Jsr	VBLDEBUG_START3

	Add.w	#1,Micro_Points	Toutes cases = 1 pour pouvoir éviter 
	*			certains bonus

	Move.w	(A3,D6.l),D3	Lecture Bloc Visible
	Beq	.SuitePt

	Cmp.w	#Type_Bonus,D3
	Bne.s	.NoBonus
	Movea.l	Dim5,A4
	Move.w	(A5),D3	Type du bonus
	
	Cmp.w	#TBonus_Bombe,D3	BOMBE priorité = 50 points
	Bne.s	.NoB01
	Move.w	MicroConfig_BonusBombPt,D3
	Blt.s	.NoBonus		-1=Interdiction de passer par dessus
	Add.w	D3,Micro_Points
	Bra	.SuitePt
.NoB01	
	Cmp.w	#TBonus_Flamme,D3	FLAMME = 20 points
	Bne.s	.NoB02
	Move.w	MicroConfig_BonusFlamPt,D3
	Blt.s	.NoBonus		-1=Interdiction de passer par dessus
	Add.w	D3,Micro_Points
	Bra	.SuitePt
.NoB02
	Move.w	MicroConfig_BonusAutrPt,D3
	Blt.s	.NoBonus		-1=Interdiction de passer par dessus
	Add.w	D3,Micro_Points
	Bra	.SuitePt
	
.NoBonus

	Bra	.Micro_RoutageAjoutPointEnd
	
	***************************************
	*    Le point n'est pas sur du vide   *
	***************************************
	Nop
.SuitePt
	**************************
	* Ajouter le point cible *
	**************************
	*
	* Gestion du tableau à 2 dimensions de routage
	*

	Move.b	D2,Route_ID(A5)	Ecriture N° du routage

	Move.w	Micro_Points,D4
	Cmp.w	#255,D4
	Ble.s	.OkPtV
	Move.w	#255,D4
.OkPtV	Move.b	D4,Route_Points(A5)

	Move.w	Micro_Dir,D4
	Move.b	D4,Route_DirSrc(A5)	Ecriture route source

	*
	* ceci ne sert qu'à mettre dans Route_BombOk()
	* le fait que l'on a le droit de poser une bombe, c'est à dire
	* qu'il faut que la case cible soit après un changement de
	* direction dans n'importe quel sens.
	*
	Move.w	Micro_BombOk,D2
	*Cmp.w	#5,D2
	*Beq.s	.TestBOk
	Tst.b	D2		<0.B : direction avec bit de flag!
	Blt.s	.TestBOk		>0.B : distance premier virage !!!
	Move.w	D2,D4		BombOk (ancienne direction)
	Move.w	Micro_DirBB,D2	Direction actuelle
	Cmp.w	D2,D4
	Beq.s	.TestBOk		
	Tst.w	D4
	Beq.s	.TestBOk
	
	Move.w	Micro_ChchDist,D2	Distance du virage
	Add.w	#2,D2		Pas encore incrémenté ici !
	Bset	#7,D2		Nombre= cases pour être quiet !
	
	*Move.w	#5,D2
.TestBOk	Move.b	D2,Route_BombOk(A5)	Bombe <> LiCo case visée

	*****


	*
	* Lecture du danger LigCol
	*
	Movea.l	DimIA3,A4			LigCol
	Move.w	D0,D4			X: colonne
	Lsl.w	#2,D4			Colonnes ou +64*4 = lignes
	Move.w	Lico_Time(A4,D4.w),D2	Temps bombe colonne
	Move.w	D1,D4
	Lsl.w	#2,D4			Y: ligne
	Add.w	#64*4,D4
	Move.w	Lico_Time(A4,D4.w),D4	Temps bombe ligne
	Cmp.w	D4,D2			Plus petit dans D2
	Ble.s	.D2Ok
	Move.w	D4,D2
.D2Ok
* Calculer le danger de la case en fonction de la distance	
* plus c'est loin plus la bombe sera prêt de l'explosion.
* Vitesse: Lente: 1 pixel/VBL, Normale: 2 pix/vbl, vite: 4 pix/vbl
* une case fait 16*16 pix
* DONC   Lente: 16 VBL/Case  Normale: 8 VBL/Case  Vite: 4 VBL/Case
* Sachant que les bombes sont gérées toutes les 2 VBL:
* Il faut décrémenter de 1 le danger si on bouge de 2 VBL
* Donc Lente: -8 par case, Normale: -4 par case, Vite: -2/Case
* DONC: 
* 1 -> -8,  2 -> -4, 4 -> -2 		Calcul:  -8/Vit
*
	Cmp.w	#Micro_TempsSafe,D2		Case vide de danger ? 
	Beq.s	.FinDimin			Oui: on touche pas
	Move.w	#8,D5
	Divu.w	Micro_Vitesse,D5		8/(Vitesse en Pix/VBL)	
	Mulu.w	Micro_RouteStep,D5		*Distance (profondeur rout)
	Sub.w	D5,D2
	Bge.s	.FinDimin
	Clr.w	D2			Mini = 0 (éviter les bugs)
.FinDimin
	Move.b	D2,Route_Danger(A5)	DANGER ACTUEL (Instant T)

	* Comparer le danger actuel avec le point source 
	Move.w	Micro_DangerSrc,D4
	Cmp.w	D2,D4
	Ble.s	.D4Ok
	Move.w	D2,D4
.D4Ok	Move.b	D4,Route_DangerSrc(A5)	DANGER SOURCE
	
	*
	* Gestion de la liste de points
	*
	Move.w	Micro_CibNb,D6
	Add.w	#1,D6
	Move.w	D6,Micro_CibNb
	Sub.w	#1,D6
	Lsl.w	#3,D6		8 octets par point
	Add.w	Micro_CibID,D6	0 ou 4
	Move.w	D0,(A2,D6.w)	X
	Move.w	D1,2(A2,D6.w)	Y

	Add.w	#1,Micro_FilsNb
	Add.w	#1,Micro_TotNb	DEBUG	Nb de points CREES !!!!
	
	
	
	
.Micro_RoutageAjoutPointEnd
	RTS


****************** INIT ROUTINE BOMBES
*
* Mettre à 0 le danger des lignes et colonnes pour les bombes
*
* Max 64 colonnes (en double pour compatibilité!)
* donc 64*4 octets pour chaque tableau lignes-colonnes
*
Micro_BombInit
	Movea.l	DimIA3,A1		Dim Lignes-Colonnes 64*4*2
	Moveq	#SizeDimIA3/Lico_SizeOf-1,D0
	Move.w	#Micro_TempsSafe,D1		Temps maxi explosion ligne-colonne
.Loop	Move.w	D1,Lico_Time(A1)
	Adda.w	#Lico_SizeOf,A1
	Dbf	D0,.Loop		
	RTS


****************** AJOUT D'UNE BOMBE
*
* Ajouter le danger d'une bombe dans le tableau de X et celui de Y
*
*
* Bomb_Vx,Vy:  entre -1 et +1: les bombes bougent par DEMI CASE !!!
*
* Cette routine arrondi pour simplifier à des grosses cases.
* on a donc droit à 2*4 = 8 octets par ligne et colonne pour les infos!
*
* Le danger est ajouté en négatif, donc 0:rien   -50
*
* Le Dim est X*64*4,Y*64*4
*
* NE PAS TOUCHER 	D0/D1,A0/A6	
* Utilisé:	D2-D4/D6,A1-A3
*
* A0: Structure bombe
* D1: Bomb_Time (en 1/25 s, car 2 Vbl au lieu de 1)
*
* Nouveauté: la bombe n'est ajoutée que si elle n'est pas entre
* deux blocs indestructibles
* 
Micro_BombAdd
	Movea.l	DimIA3,A1		Dim IA: Danger lignes-colonnes
	Move.w	Bomb_X(A0),D2   	Lecture position
	Move.w	Bomb_Y(A0),D3

	Bclr	#0,D2		Arrondi sur grosse case
	Bclr	#0,D3			

	* Adresse dim visible
	Move.w	D3,D6
	Lsl.w	#6,D6		Y*64
	Add.w	D2,D6		+X
	Ext.l	D6
	Lsl.l	#2,D6		*SizeStructure
	Movea.l	Dim2,A3
	Lea	(A3,D6.l),A3	Adresse bombe dans Dim2 (visible)


	* Tester si la bombe est entre deux murs en vertical
	Move.w	-2*64*SizeStructure(A3),D4	Y-1
	Beq.s	.AjoutCol
	Cmp.w	#Type_Bloc_NoDestr2,D4	1,2,3 = Arrêt bombe
	Bgt.s	.AjoutCol
.TestYPU	Move.w	2*64*SizeStructure(A3),D4	Y+1
	Beq.s	.AjoutCol
	Cmp.w	#Type_Bloc_NoDestr2,D4
	Ble.s	.NopTX			Pas d'ajout en colonne!
.AjoutCol
	* Gérer la colonne
	Lsl.w	#2,D2		X*SizeStructure
	Lea	(A1,D2.w),A2	Pointeur X
	Move.w	Lico_Time(A2),D2	Temps colonne (en X)
	Cmp.w	D2,D1
	Bge.s	.NopTX
	Move.w	D1,LiCo_Time(A2)	
	Move.w	D4,LiCo_DEBUG(A2)
.NopTX
	* Tester si la bombe est entre deux murs en horizontal
	Move.w	-2*SizeStructure(A3),D4	X-1
	Beq.s	.AjoutLig
	Cmp.w	#Type_Bloc_NoDestr2,D4	1,2,3 = Arrêt bombe
	Bgt.s	.AjoutLig
.TestXPU	Move.w	2*SizeStructure(A3),D4	X+1
	Beq.s	.AjoutLig
	Cmp.w	#Type_Bloc_NoDestr2,D4
	Ble.s	.NopTY			Pas d'ajout en ligne!
.AjoutLig
	* Gérer la ligne
	Lsl.w	#2,D3		Y*SizeStructure
	Add.w	#64*4,D3		Tableau des Y
	Lea	(A1,D3.w),A2	Pointeur Y
	Move.w	LiCo_Time(A2),D2	Temps ligne (en Y)
	Cmp.w	D2,D1
	Bge.s	.NopTY
	Move.w	D1,LiCo_Time(A2)	
	Move.w	D4,LiCo_DEBUG(A2)
.NopTY	
	RTS


***** 
*
* petites cases
* X: D6
* Y: D7
*
Micro_FlammeAdd
	Movem.l	D6-D7/A0,-(A7)
	Movea.l	DimIA3,A0		Dim Lig-Col
	Bclr	#0,D6		Grosses cases
	Lsl.w	#2,D6		X:Colonne
	Clr.w	Lico_Time(A0,D6.w)	
	Bclr	#0,D7		Y:Ligne
	Lsl.w	#2,D7
	Add.w	#64*4,D7
	Clr.w	Lico_Time(A0,D7.w)
	Movem.l	(A7)+,D6-D7/A0
	RTS
	

***************
*    INITS    *
***************
Micro_RoutageChoixNewPoint_Init
	
	*
	* La case choisie est mise comme case à chercher
	* puis la prochaine case choisie est la case actuelle
	* (pour pouvoir arrêter son mouvement si case actuelle plus sûre).

	Move.w	#0,Micro_ChchFire		Pas de feu

	* Search doit être égal à la case choisie, seulement si 
	* la case choisie n'est pas la position actuelle
	*
	Move.l	Micro_ChchCaseChoisie,Micro_ChchCaseChoisieSearch
	Move.l	#0,Micro_ChchCaseChoisieFound

	*Clr.l	D5
	*Bra.s	.CaNotOk


	* Cette affectation a pour effet de pouvoir rendre
	* le micro immobile. Si on met 0 il cherchera toujours
	* une autre case.
	*Clr.l	D5
	*Move.l	Micro_CaseActPtr,A0
	*Sub.l	DimIA1,A0		Calcul adresse visible
	*Add.l	Dim2,A0	
	*Tst.w	(A0)
	*Bne.s	.CaNotOk
	*Move.l	A0,D5		Case vide: autorisation immobile
	*Move.l	Micro_ChchCaseChoisieSearch,D6
	*Cmp.l	D5,D6
	*Bne.s	.CaNotOk
	*Move.l	#0,Micro_ChchCaseChoisieSearch    Search doit être<>act!
	*Move.w	#-1,Micro_ChchFire	

.CaNotOk	Move.l	D5,Micro_ChchCaseChoisie

	Move.w	#0,Micro_ChchDist
	Move.w	#0,Micro_ChchDanger
	Move.w	#0,Micro_ChchDangerSrc
	Move.w	#0,Micro_ChchDirSrc		Pas de mouvement
	Move.w	#0,Micro_ChchFilsNb	
	Move.w	#0,Micro_ChchPoints
	Move.w	#0,Micro_ChchChoix
	RTS

	

*************************************************************
*						*
*      TIRER PARTI DES INFORMATIONS PENDANT LE ROUTAGE 	*
*						*
*************************************************************
* Pour le point actuel, comparer avec la mémoire des meilleurs points 
* trouvés et remplacer les valeurs si nécessaire.
*  
*
*
* A1:Routage, A2: Liste Pts, A3:Visible
*
*	Micro_ChchDanger	
*	Micro_ChchDist 
*	*Micro_ChchPoints
*	Micro_ChchDirSrc	
*	Micro_FilsNb
*
*	Avec
*		Micro_RouteStep
*		Route_DangerSrc	
*		Route_Danger	
*		Route_DirSrc	
* 
* Je prends une case qui a moins de danger si le trajet est >0
*
* Les valeurs initiales doivent être la case du micro
*
*
Micro_RoutageChoixNewPoint

*
* Acceptation de la première case si aucune case choisie (même pas immobile)
*
	Clr.w	Micro_Priorite		Si -1: pas de tests points
	Clr.w	D0
	Move.l	Micro_CaseActPtr,A5
	Clr.w	D0
	Move.b	Route_Points(A5),D0
	Move.w	D0,Micro_Points


	Tst.l	Micro_ChchCaseChoisie
	Beq	.NewOk

	Tst.w	Micro_ChchDirSrc		Pas immobile STP !
	Beq	.NewOk	

	* Juste tester que l'on a le temps de se déplacer
	* sur la nouvelle case, si on n'a pas le temps
	* cela ne sert à rien de faire d'autres tests
	Move.b	Route_DangerSrc(A5),D0
	Cmp.w	MicroConfig_PeurCasesDanger,D0
	Ble	.NotOk

	Move.w	Micro_ChchDanger,D1	
	Move.b	Route_Danger(A5),D0
	Cmp.w	D0,D1
	Bgt	.DangSup		Nouvelle case +dangereuse
	Blt	.DangInf

.DangEga	*** DANGER CASE CIBLE EGAL A CASE DEJA TROUVEE
	Move.w	Micro_ChchDangerSrc,D1
	Move.b	Route_DangerSrc(A5),D0
	Cmp.w	D0,D1
	Bgt	.DR1Sup
	Blt	.DR1Inf

.DR1Ega	*** Danger route égal
	* Suite: pas de priorité spéciale, on laisse la comparaison
	* de la valeur des cases faire son office
	Bra	.SuiteOK

.DR1Sup	*** Danger route supérieur
	Tst.w	MicroConfig_BestRoute	
	Bne	.NotOk		<- fonction "prudent"

	Move.w	#1,Micro_Priorite	>0:danger ok seulement si
	*				ça vaut le coup
		
	Bra	.SuiteOK		<- fonction kamikaze

.DR1Inf	*** Danger route inférieur
	* Cela dépend du micro: si le micro est du genre 
	* prudent, il prend toujours la route la moins dangereuse
	* (Priorité = -1). Pour l'instant pour le debug je choisis cela.
	* Si jamais on veut qu'il prenne des routes très dangereuses
	* indifféremment, il suffit d'enlever la priorité
	Tst.w	MicroConfig_BestRoute	
	Beq.s	.NoSp
	Move.w	#-1,Micro_Priorite	<- fonction "prudent"
.NoSp	Clr.l	Micro_ChchCaseChoisieFound	
	Bra	.SuiteOk

.DangSup	*** DANGER CASE CIBLE SUPERIEUR A CASE DEJA TROUVEE
	Bra	.NotOk

.DangInf 	*** DANGER CASE CIBLE INFERIEUR A CASE DEJA TROUVEE
*	Move.w	Micro_ChchDangerSrc,D1
*	Move.b	Route_DangerSrc(A5),D0
*	Cmp.w	D0,D1
*	Bgt	.DR2Sup
*	Blt	.DR2Inf
*	Nop
*.DR2Ega	*** Danger route égal
*.DR2Sup	*** Danger route supérieur
*.DR2Inf	*** Danger route inférieur
	
	Move.w	#-1,Micro_Priorite
	Clr.l	Micro_ChchCaseChoisieFound
	Bra	.SuiteOk
		

*******************************************************************
*						      *
* Si l'on arrive ici, c 'est que le danger trouvé est égal au     *
* danger précédemment trouvé, donc on a le choix de l'initiative  *
*						      *
*******************************************************************
	Nop
.SuiteOK
	Move.l	Micro_ChchCaseChoisieSearch,D1
	Cmp.l	D1,A5
	Bne	.NotS		C'est la case qu'on cherche !
	Move.l	D1,Micro_ChchCaseChoisieFound
	Bra	.NewOk
.NotS	Tst.w	Micro_Priorite
	Blt	.NewOk		<0: Priorité danger donc okay

	* Le micro a rien à foutre de son but, il se balade si on 
	* enlève ces deux lignes.
	*
	Tst.l	Micro_ChchCaseChoisieFound	Pas de pri, déjà trouvé,ok
	*Bne	.NotOk
	Beq.s	.NotFound
	* au lieu d'interdire de trouver une autre case 
	* si l'on a déjà trouvé la cible, j'autorise mais avec
	* un trigger ! (meilleure solution je pense)
	*
	Move.w	#2,Micro_Priorite	>0:trigger	
	*Bra	.NotOk
.NotFound
		

	*
	* Tests supplémentaires (le danger est le plus important..)
	*
	
	
	
	*
	* Points (bonus...)
	*
	*** Distance
	Move.w	Micro_RouteStep,D0
	Add.w	D0,Micro_Points	Ajout distance

	*** Nombre de murs autour
	Move.w	Micro_FilsNb,D0
	Lsl.w	#1,D0
	Neg.w	D0
	Add.w	#8,D0
	Bge.s	.OkM
	Clr.w	D0
.OkM	Add.w	D0,Micro_Points

	*** Valoriser les cases qui sont dans une direction autre
	* que le demi-tour !
	
	Clr.l	D4
	Move.w	Micro_DirSrcAnc,D0
	Clr.w	D1
	Move.b	Route_DirSrc(A5),D1
	Cmp.w	#1,D0
	Bne.s	.TNoH
	Cmp.w	#3,D1
	Beq.s	.TFin
	Move.w	#10,D4
	
	Bra.s	.TFin
.TNoH	Cmp.w	#2,D0
	Bne.s	.TNoD
	Cmp.w	#4,D1
	Beq.s	.TFin
	Move.w	#10,D4

	Bra.s	.TFin	
.TNoD	Cmp.w	#3,D0
	Bne.s	.TNoB
	Cmp.w	#1,D1
	Beq.s	.TFin
	Move.w	#10,D4

	Bra.s	.TFin	
.TNoB	Cmp.w	#4,D0
	Bne.s	.TNoG
	Cmp.w	#2,D1
	Beq.s	.TFin
	Move.w	#10,D4
.TNoG		
.TFin	Add.w	D4,Micro_Points

	******************************
	*** Comparaison des points ***
	******************************	
	Move.w	Micro_Points,D0
	Cmp.w	#255,D0
	Ble.s	.OkPt
	Move.w	#255,Micro_Points
	Move.w	#255,D0
.OkPt	Move.b	D0,Route_Points(A5)		Ecriture des points (DEBUG)
	Clr.l	D1

	Move.w	Micro_Priorite,D4	Trigger: danger > seulement
	Ble.s	.NoTrigg			si ça vaut le coup
	Move.w	MicroConfig_RouteDangPoints,D1
	Lsl.w	D4,D1			trigger variable
.NoTrigg	Add.w	Micro_ChchPoints,D1
	Cmp.w	D0,D1
	Bgt	.NotOk

	
		


	*
	* Plus loin = moins cul de sac
	* 	
	
	*Move.w	Micro_ChchDist,D1
	*Cmp.w	D0,D1
	*Bgt.s	.NotOk	


.NewOk	**************************
	* Acceptation de la case *
	**************************

	* Je ne mets le feu à -1 QUE si BombOk=True !
	Clr.w	D0
	Move.w	#0,Micro_ChchFire			

	Tst.w	Micro_BombAllowed
	Beq	.BombNoOk
	Tst.w	Micro_CaseDiff
	Bne.s	.BombNoOk		Poser une bombe que sur milieu case
	* Droit de poser une bombe sur la case ?
	Move.b	Route_BombOk(A5),D0
	Bge.s	.BombNoOk
	BClr	#7,D0	on enlève le flag: reste la distance
	*
	* #ICI# il faut estimer le temps d'explosion de la bombe et
	* la distance qui nous sépare du virage avec notre vitesse
	* et une petite marge !!! le micro va être redoutable !
	*
	*
	*Cmp.w	#5,D0
	*Bne.s	.BombNoOk
	Move.w	#$FF,Micro_ChchFire			
	Move.w	MicroConfig_BombDelai,Micro_BombDelai	
.BombNoOk
	

	*	Relecture du danger
	Clr.w	D0
	Move.b	Route_Danger(A5),D0
	Move.w	D0,Micro_ChchDanger
	Move.b	Route_DangerSrc(A5),D0
	Move.w	D0,Micro_chchDangerSrc

	Move.w	Micro_RouteStep,Micro_ChchDist
	Move.l	A5,Micro_ChchCaseChoisie

	*	Relecture de la direction
	Clr.w	D0
	Move.b	Route_DirSrc(A5),D0
	Move.w	D0,Micro_ChchDirSrc

	Move.w	Micro_Points,D0
	Bge.s	.OkP
	Clr.l	D0
.OkP	Move.w	D0,Micro_ChchPoints
	Move.b	D0,Route_Points(A5)		Points

	Move.w	Micro_Priorite,Micro_ChchPriorite

	Move.w	Micro_ChchChoix,D0
	Add.w	#1,D0
	Move.w	D0,Micro_ChchChoix
	Move.b	D0,Route_Ok(A5)	

	Bra.s	.SuiteAll
.NotOk		
	Move.b	#0,Route_Ok(A5)	
.SuiteAll	


*
* Estimation du nombre de points de la case
* 
	*Move.w	Micro_FilsNb,D4

	*Micro_RouteStep

	RTS

**********************************************************
*  Test ultime: est-ce plus rentable de ne pas bouger ?  *
**********************************************************
*
* Si on ne bouge pas il faut:
* Que la case actuelle soit en danger et que la route choisie ait un
* danger supérieur (en route) à la tolérance du micro.
* 
* Si la case cible est de danger inférieur à la case en cours, on y
* va si le passage est dégagé.
*
*
Micro_RoutageChoixNewPointEnd
	RTS

	
	
	Clr.w	D0
	Clr.w	D1
	Move.l	Micro_CaseActPtrBase,A4	Pointeur de base routage
	Move.b	Route_Danger(A4),D0		Danger case actuelle	
*
* Tester si le micro est en mode "poser des bombes raisonnablement"
* si la case sur laquelle il est est sans danger. Dans le cas contraire,
* interdiction de faire ça.
*
	Cmp.w	#Micro_TempsSafe,D0
	Beq.s	.BombOk
	Tst.w	MicroConfig_PoseBombIfSafe
	Bne.s	.BombOk2
	Cmp.w	MicroConfig_PoseBombDangerMax,D0
	Bgt.s	.BombOk
.BombOk2	Clr.w	Micro_ChchFire		Interdiction fire	
.BombOk


	*Move.w	Micro_ChchDangerSrc,D1	Route trop dangereuse ?
	*Cmp.w	#Micro_PeurCasesDanger,D1
	*Ble.s	.TestAStop		Oui: on bouge pas	
.TestAOk	
	* Ici si la route n'est pas trop dangereuse
	* TEST: est-ce que la case visée est moins dangereuse ?
	* 	OUI: tout va bien (cas standard normal) 
	*	NON: on stoppe 
	*
	Move.w	Micro_ChchDanger,D1		Meilleur Danger trouvé	
	Cmp.w	D0,D1			Danger cible - important ?
	Blt.s	.TestAStop		Cas standard.. on y va
	
	
	BRA.S	.FIN	<- Empêchement d'aller-retour marche pas!
	
	* Est-ce que la case visée est la case d'oû l'on vient ?
	* Oui: si pas de priorité dûe au danger, on ne bouge plus.
	*
	*
	Move.l	Micro_ChchCaseChoisie,D1
	Cmp.l	Micro_CaseChoisie1,D1
	Bne.s	.TestB1Ok
	* Case d'avant égale
	Tst.w	Micro_ChchPriorite		-1: Danger: pas de choix à faire
	Bge.s	.TestAStop
	* Danger: on y va quand même
	Clr.l	Micro_CaseChoisie1
	Bra.s	.Fin
	
.TestB1Ok	Cmp.l	Micro_CaseChoisie2,D1
	Bne.s	.TestB2Ok
	* Case d'avant avant égale
	Tst.w	Micro_ChchPriorite		-1: Danger: pas de choix à faire
	Bge.s	.TestAStop
	* Danger: on y va quand même
	Clr.l	Micro_CaseChoisie2
	Bra.s	.Fin
					
.TestB2Ok	
	*
	* On ne décale la mémoire des cases du micro que 
	* si l'on a rejoint la case visée !!!
	*
	Move.l	Micro_CaseActPtr,D1
	Sub.l	Micro_ChchCaseChoisieSearch,D1
	Bne.s	.NoAj
	Move.l	Micro_CaseChoisie1,Micro_CaseChoisie2
	Move.l	Micro_ChchCaseChoisie,Micro_CaseChoisie1
.NoAj
	Bra.s	.Fin

	* Ici si la route est trop dangereuse
	* TEST: est-ce que la case en cours est TROP dangereuse ?
	* 	OUI: On se casse, quels que soient les risques
	*	NON: On reste
	*
.TestAStop
	
	Nop

.Arret	Clr.w	Micro_ChchDirSrc		ARRET du MICRO !
	* BUG détecté: le micro s'arrête mais croit encore
	* qu'il peut poser sa bombe car il se croit 
	* en mouvement ! Donc effacer le feu aussi !!!
	Clr.w	Micro_ChchFire

.Fin
	RTS

	
Micro_RoutageEtat	Dc.w	0
Micro_RoutageID	Dc.w	0
Micro_SrcNb	Dc.w	0
Micro_SrcID	Dc.w	0
Micro_SrcLoop	Dc.w	0
Micro_CibNb	Dc.w	0
Micro_CibID	Dc.w	0
Micro_RouteStep	Dc.w	0	Profondeur du routage
MicroPtr		Dc.l	0	Routage asynchrone (1 seul micro!)
Micro_Routage_Active Dc.w	0	Fin de routage si routage VBL

Micro_Vitesse	Dc.w	0	Vitesse en pixels par VBL
Micro_FilsNb	Dc.w	0	Total des points fils créés
Micro_TotNb	Dc.w	0	Total des points routés
Micro_DangerSrc	Dc.w	0
Micro_CaseActPtr	Dc.l	0	Pointeur case routage du micro
Micro_CaseActPtrBase Dc.l	0	Pointeur micro lui même
Micro_Points	Dc.w	0
Micro_ChchDist	Dc.w	0
Micro_ChchMur	Dc.w	0
Micro_ChchDanger	Dc.w	0	Valeur danger mini trouvé
Micro_ChchDangerSrc	Dc.w	0	Valeur danger source
Micro_ChchDangerDist Dc.w	0	Distance case danger mini
Micro_ChchPoints	Dc.w	0	Points de la position !
Micro_ChchDirSrc	Dc.w	0	Direction source de départ	
Micro_ChchCaseChoisieSearch Dc.l 0	Recherchée: résultat du routage préc.
Micro_ChchCaseChoisieFound Dc.l 0	Retrouvée dans ce routage et acceptée
Micro_ChchCaseChoisie Dc.l	0	Nouvelle meilleure case
Micro_ChchFilsNb	Dc.w	0
Micro_ChchPriorite	Dc.w	0	>0:Si points importants  <0:DANGER!
Micro_ChchChoix	Dc.w	0
Micro_ChchFire	Dc.w	0

Micro_Priorite	Dc.w	0
Micro_DirH	Dc.w	0
Micro_DirD	Dc.w	0
Micro_DirB	Dc.w	0
Micro_DirG	Dc.w	0
Micro_Dir		Dc.w	0
Micro_DirAnc	Dc.w	0
Micro_BombOk	Dc.w	0
MicroActPtr	Dc.l	0
Micro_DirBB	Dc.w	0
Micro_BombDelai	Dc.w	0	En nb de VBL
Micro_BombAllowed	Dc.w	0
Micro_DirSrcAnc	Dc.w	0
Micro_CaseDiff	Dc.w	0
Micro_XCaseAnc	Dc.w	0
Micro_YCaseAnc	Dc.w	0
Micro_CaseChoisie1	Dc.l	0
Micro_CaseChoisie2	Dc.l	0


MicroConfig_BombRND		Dc.w 0	1 chance sur N de poser une bombe
MicroConfig_BombDelai	Dc.w 0	Temps mini entre deux bombes (nerveux?)
MicroConfig_BonusBombPt	Dc.w 0	Points d'une bombe
MicroConfig_BonusFlamPt	Dc.w 0	Points d'une flamme
MicroConfig_BonusAutrPt	Dc.w 0	Points des autres bonus
MicroConfig_BestRoute	Dc.w 0	Oui/Non route moins dangereuse
MicroConfig_RouteDangPoints	Dc.w 0 	Gain mini de points pour traverser une route dangereuse
MicroConfig_PoseBombIfSafe	Dc.w 0	Ne pose une bombe que si pas en danger
MicroConfig_PoseBombDangerMax	Dc.w 0 	Limite de danger pour poser bombe
MicroConfig_PeurCasesDanger	Dc.w 0	Limite de danger pour la route
*
* au moment où je vais décrémenter le danger de tout le tableau,
* je vais aussi effacer par exemple les joueurs.
*
* Maintenant c'est le routage qui met à 0 le danger !!!
* en fait il ne met pas à 0 mais il décrémente !
*
* 
* Envisager: les flammes s'ajoutent toute seules au dim micro !!!
*
* Lig-Col: les bombes ne s'ajoutent que si elles ne sont pas entre
* deux murs, destructibles ou pas, comme ça on limite un peu. 
*
* Routage: il faudrait que si le routage "se rend compte" qu'il est
* dans une partie sans bombe il élimine le danger.
* Il faudrait que le fait de rencontrer une bombe durant le routage "active"
* en fait les Lig-Col pour avoir peur des bombes.
*
* Problème du routage à chaque VBL: Il est inutile de faire une liste de 
* points, le micro ne pourra pas la suivre car il route beaucoup plus vite
* qu'il ne marche.
*
* IMPORTANT:
* 
* En prenant ceci en compte... peut-être que le routage ne devrait pas 
* s'arrêter quand on a atteind le nombre max de cases routables.. il 
* devrait continuer tant que le micro n'a pas changé de grosse case, donc
* tant qu'il n'a pas rejoint la grosse case immédiatement à côté de lui
* qu'il devait rejoindre. <- Pbl si la grosse case comporte d'un coup
* une bombe ! ou du danger! 
* Dans ce cas le micro continuera son routage dans tout le tableau, puis
* re-retourera à 0 et se rendra compte qu'il doit choisir une autre route.
*
* Problème de router à tous les coups: 
* Le micro risque de changer sans arrêt d'avis concernant sa cible tant 
* qu'il n'y a pas de danger qui l'oblige à préférer une route de loin
* aux autres.
*
* Le top serait qu'il se fixe un but, par exemple une case entre 3 murs
* destructibles pour aller y poser une bombe, et il faudrait que
* le danger de son action soit estimé à chaque fois qu'il effectue une
* avance d'un pas.
* Il faudrait donner une note: 172 par exemple issu du danger combiné à 
* ce qu'il va en retirer, et il compare tout ce qu'il trouve à chaque 
* pas, et si les points sont différents de plus de 20 (trigger), alors
* il choisira la meilleure nouvelle solution.
* Problème ? Il risque de ne pas se rendre compte tout de suite du danger
* que risque de présenter sa situation ? (à réfléchir).
*
* CUL DE SAC:
* Il faudrait tirer parti des routages précédents ?
* par exemple pour reconnaître les culs de sac ???
* A chaque routage une info revient d'une case. <- trouver une soluce
* Autre voie:  
* Ne gérer que 2 cases de cul de sac pour éviter les pièges les plus gros;
*
* Simple: J'appelle les 4 créations de point depuis un point. Et je 
* marque le nombre créé depuis ce point DANS ce point. J'estime donc
* la valeur de ce point en question, puis (4 pointeurs stockés), je marque
* ce nombre aussi dans les 1-4 points créés.
*
* Question: garder en mémoire toute la route ou seulement 
* la coordonnée de la cible ?
* Il faudrait mémoriser la meilleure route pour chaque direction possible
* (h,b,g,d), et comparer les points.
*
* La cible choisie par le micro doit absolument être gérée dans la routine
* qui sert à appeler les nouveaux points et non dans l'ajout d'un nouveau
* point lui même (car on n'a pas encore toute l'info).
*
* J'ai deux dangers: le danger de la case actuelle, et le danger traçé,
* c'est à dire issu du danger maxi des cases précédentes (nb mini).
* Il faut choisir dans les danger mini (255) la traçe ayant le danger
* mini (255).
* Il faudrait mettre une distance, pour savoir si le danger mini rencontré
* était juste à côté ou plus loin.
* En fonction de la distance le micro devrait savoir s'il est en danger ou
* pas... compliqué.
*
* Il faudrait définir un mode "joueur", c'est à dire changer de
* comportement quand le micro détecte qu'il peut être en contact avec
* le joueur (éviter les culs de sac)
*
*
* DEUX REGLES FONDAMENTALES A INCULQUER AU MICRO:
*
* - Eviter les cases cible dangereuses
* - Eviter les chemins utilisant des cases dangereuses
*
* Problème: un seul couloir devant une bombe, le micro ne veut pas 
* s'éloigner de la bombe car il prévoit que le danger augmente
* avec la distance.
* Il faut qu'un danger minime le fasse tout de suite choisir.
* 
* Problème: bien qu'une case tranquille ait été trouvée, le micro 
* se rend compte que la route est plus dangereuse que la route 
* qu'il aura s'il reste en place.
*
* Danger supérieur
*	Route danger supérieur	NonOK
*	Route danger égal		NonOk
*	Route danger inférieur	NonOk
*
* Danger égal
*	Route danger supérieur	NonOk
*	Route danger égal		Rnd	ou choix case but
*	Route danger inférieur	Ok
*
* Danger inférieur
*	Route danger supérieur	X OK !!!!!!
*	Route danger égal		OK
*	Route danger inférieur	OK
*    Il faut juste TESTER que le temps de la route nous laisse le 
*    temps nécessaire à la traversée.
*
* 16/07/2000
* *But actuel: éviter que le micro ne fasse des aller et retour
*	sur place, donc il faut valoriser les cases qui ne sont pas
*	à l'inverse de la direction actuelle.
*  Solution: j'ai valorisé les cases qui sont dans toutes les directions
* 	qui ne demandent pas une direction inverse à la direction actuelle
*
* *But actuel: éviter que le micro ne fasse péter les bonus
*  Solution: ne pas utiliser la case privilégiée mais réestimer la meilleure
*	route à chaque VBL
*  Solution: prendre en compte la case trouvée en tant que Trigger
*
* *But actuel: éviter que le micro ne pose des bombes sur des cases
*	trop dangereuses
*  Solution 1: flag pour dire s'il a le droit ou pas
*  Solution 2: tester le temps de la case
*
* Le micro devrait prendre compte la présence d'autres joueurs, pour
* cela il pourrait tirer parti du résultat du routage précédent:
* au routage d'avant je sais que le joueur X est dans la direction de 
* départ 3, donc je valorise d'avantage les cases qui sont de dos
* (pour faire un fuyard), ou au moins s'il ne fuit pas il ne doit pas poser
* de bombe tant qu'il est dans la direction du joueur !
* Comme ça c'est beaucoup plus puissant, et comme on route à chaque VBL
* et que les joueurs mettent au mini 4 VBL pour changer de case, le micro
* aura 1/4 du temps d'une case de retard si le joueur est en mode rapide.
* (donc entre 1 et 4 pixels de retard)
*
* Si le micro détecte un cul de sac, et qu'il détecte un joueur dans le cul 
* de sac, immédiatement il valorise la case à mort pour poser une bombe.
* (Donc valorisation pour se rendre sur la case, et mémoire de la case=
* poser une bombe (car "joueur dedans"))
*
*
*
*
* -> But actuel: éviter que le micro fasse trop "d'imprudences"
*		c'est à dire qu'il ne passe par une route plus
*		dangereuse que pour:
*		- rejoindre une case d'au moins N points de plus 
*		- se balader en dessous d'un certain danger (N)
*
* -> But actuel: le micro n'estime pas le temps que va mettre la bombe 
* 	qu'il veut poser pour exploser en fonction de là où le micro
*	veut aller.
* Solution: il compte dans combien de cases il fait le premier virage
*	et en fonction de sa vitesse et du danger de la case il voit 
*	s'il a le temps ou non (il va devenir redoutable!)
*
* -> But actuel: faire en sorte que le micro soit plus zen, si jamais
*	il n'a plus aucune bombe à poser et qu'il n'a pas de case
*	de points de plus de N il ne bouge pas !
* Solution: il suffit de le faire.
*
* ->But actuel: que le micro voie les joueurs, et essaye tout le temps de
*	poser des bombes entre le joueur et lui
* Solution: "poser" les joueurs dans son tableau de routage, comme
*	case bonus (on peut passer par dessus et stockage info)
*
*
* -> But actuel: que le micro ne s'enfonce pas dans des culs de sac si
*	un joueur est à proximité 
* Solution: DISTANCE du joueur le plus proche, et comparaison de deux fois
*	le nombre de cases de la profondeur du cul de sac (en fonction
*	de la vitesse des deux joueurs ?)
*
* ->But actuel: quand le micro est dans la merde, il faut qu'il se rapproche 
*	le plus possible de la case la plus dangereuse ! car la case
*	la plus dangereuse est celle qui sera liberée le plus vite !
* Solution: ?
*
* ->But actuel: éviter que le micro ne se fasse avoir avec les blocs de
*	fin de niveau
* Solution: ? marquer la ligne ou la colonne comme une bombe prête à 
*	exploser ! (genre 10 pour avoir le temps d'échapper qd même)
*
* ->But actuel: le micro doit poser ses bombes en face de murs destructibles
* Solution: valoriser les cases, ou tester au moment où l'on pose 
*	la bombe ?
*	
*
*
*
*
	
	
	
	