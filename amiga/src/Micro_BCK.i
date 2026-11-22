

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
Routage_Nb	=	30

	RsReset	* Dim Routage
Route_Struct 	Rs.w	0	
Route_ID		Rs.b	1	N° du routage
Route_Danger	Rs.b	1	Danger de la case 
Route_DirSrc	Rs.b	1	D'ou on vient pour cette case
Route_FILL	Rs.b	5
Route_SizeOf 	Rs.w	0	Taille = 8 octets (2 ptts cases!)

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

Danger_TimeBombAlert=	16	

Micro_PeurFlamme	=	1	Nb de cases de marge par rapport au bout prévu de la flamme

Micro
	Clr.l	D0
	Clr.l	D1
	Clr.l	D4
	Movem.l	D2-D3/A0,-(A7)	REGISTRES VITAUX (Sprites2.i/Joueurs)
	*Clr.w	Leg_Fire(A0)	Contrairement aux joystick, il faut remettre à 0 "à la main"
	*********** Pour que le micro appuye sur FEU au début d'un Level
	Movea.l	ClavierPtr,A1
	Tst.b	65(A1)		BackSpace: On oblige le micro
	Bne.s	.Test		à apparaître le premier
	Tst.w	ExeLevel
	Bge	.EndMicro		Ce n'est pas le premier à apparaître
.Test	Tst.w	Leg_activated(A0)
	Bne.s	.DejaOk
.Feu	Move.b	#-1,Leg_Fire(A0)	Si Activated=0, on met Feu=1	
	Move.w	#$FF,D4
	Move.l	A0,MicroPtr
	Bra	.EndMicro
.DejaOk	***********

	*********************
	*** MICRO	ROUTAGE ***	toutes les Vbl
	*********************
	Jsr	VBLDEBUG_START
	*Movea.l	MicroPtr,A0	pour l'instant un seul micro
	*Tst.l	A0
	*Beq.s	.NoMicro
	Clr.w	Micro_RoutageEtat	Pour qu'il recommence à 0 !
	Jsr	Micro_Routage
.NoMicro	Jsr	VBLDEBUG_END


	Bra	.EndMicro

	******************************
	*******************************


	Move.w	Leg_VitJou(A0),D4	Vitesse actuelle du joueur à gérer
	
	Jsr	ScreenPos		A0 -> XScr,YScr

***********************************************************************
	* Exemple tout con: On teste le Dim Visible: Si il y a qq	*
	* chose à la position actuelle, on essaye de bouger vers	*
	* la droite.					*
	* Sinon si la case en dessus est vide, on monte		*
	*************************************************************

	********* Routine qui sert à trouver l'offset de la case
	* dans les dim en fonction de la position du joueur actuel.
	* Entrées: A0: Structure joueur
	* Sorties: D6: Offset dans les Dim


	Clr.l	D2
	Clr.l	D3
	Move.w	XScr,D2		Pixel sur l'écran
	Lsr.w	#3,D2		Petite case
	*BClr	#0,D2		Alignée sur grosse case
	Move.w	YScr,D3
	Lsr.w	#3,D3		Petite case	
	*BClr	#0,D3		Alignée sur grosse case
	Move.w	D2,Micro_MvtXMem
	Move.w	D3,Micro_MvtYMem
	Bsr	Micro_CalcOffset



	**** Pointeur sur le bon DIM (visible) 
	Movea.l	Dim2,A1
	Lea	(A1,D6.l),A3
	Tst.w	(A3)
	Bne	.FinMouv		Case occupée: on bouge pas <- DEBUG

	**** Le gars veut continuer son mouvement: on teste !
	Clr.l	D0
	Clr.l	D1
	Clr.l	D2		<0: -64   >0: 64    =0: 0
	Move.w	Micro_MvtXPix,D0
	Bne.s	.OkAncMvt
	Move.w	Micro_MvtYPix,D1	
	Beq	.ContOk
.OkAncMvt
	*Jsr	Micro_DirecOne		D0,D1 -> D3,D4
	Move.w	XScr,D2
	Add.w	D0,D2
	Move.w	YScr,D3
	Add.w	D1,D3
	Lsr.w	#3,D2
	Lsr.w	#3,D3
	Bsr	Micro_CalcOffset

	*Move.l	D6,Temp2
	*Move.l	(A1,D6.l),Temp1
	*Move.w	D2,Temp2
	*Move.w	D3,Temp2+2
	*Bsr	DEBUG

	Tst.w	(A1,D6.l)
	Beq.s	.FinMouv
	
	Clr.l	D0
	Clr.l	D1	

.ContOK

	**** On teste la case du Dim Visible (Dim2) en (X,Y)
	*Tst.w	(A3)
	*Beq.s	.PasDroit

	**** On veut bouger vers la droite
	*Move.w	D4,D0
	*Bra	.EndMicro

.PasDroit	**** Le Dim visible était vide: on bouge donc pas à droite,
	**** mais on teste la case au dessus dans le visible

	**** TEST 1: Case du Dim Visible (Dim2) en (X,Y-1)
	Tst.w	-SizeStructure*64(A3)
	Bne.s	.PasVideH
	* Mouvement HAUT
	Move.w	D4,D1
	Neg.w	D1
	*Move.w	#0,Micro_MvtX
	*Move.w	#-1,Micro_MvtY
	Bra.s	.FinMouv	
.PasVideH

	**** TEST 2: Case à gauche
	Tst.w	-SizeStructure(A3)
	Bne.s	.PasVideG
	* Mouvement GAUCHE
	Move.w	D4,D0
	Neg.w	D0
	*Move.w	#-1,Micro_MvtX
	*Move.w	#0,Micro_MvtY
	Bra.s	.FinMouv	
.PasVideG

	**** TEST 3: Case en bas
	Tst.w	SizeStructure*64(A3)
	Bne.s	.PasVideB
	* Mouvement BAS
	Move.w	D4,D1
	*Move.w	#0,Micro_MvtX
	*Move.w	#1,Micro_MvtY
	Bra.s	.FinMouv	
.PasVideB
.TestD
	**** TEST 4: Case à droite
	Tst.w	SizeStructure(A3)
	Bne.s	.PasVideD
	* Mouvement DROITE
	Move.w	D4,D0
	*Move.w	#1,Micro_MvtX
	*Move.w	#0,Micro_MvtY
	*Move.l	D0,Micro_MvtX
	*Move.l	#0,Micro_MvtY
	*Bra.s	.FinMouv	
.PasVideD


.FinMouv
	Move.w	D0,Micro_MvtXPix
	Move.w	D1,Micro_MvtYPix
	Clr.w	D4

***********************************************************************
*	 		FIN EXEMPLE			*
***********************************************************************


.EndMicro	
	Movem.l	(A7)+,D2-D3/A0
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

***** Transformer D0,D1 (nX,nY) et mouvement normé D3,D4 (1,1)
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
*	SizeDimIA1
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
*		
Micro_Routage
	Movem.l	D0-D7/A1-A6,-(A7)
	
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
	Clr.l	Temp1
	Clr.l	Temp2

	Moveq	#Routage_Nb,D0
.Loop
	Move.l	D0,-(A7)
	Bsr	Micro_Routage_Step
	Move.l	(A7)+,D0
	Dbf	D0,.Loop

	Tst.w	CHEAT_ENABLED
	Beq.s	.NoCheat
	Move.w	Micro_RoutageID,Temp1
	Move.w	Micro_RouteStep,Temp1+2
	Move.w	Micro_TotNb,Temp2

	Moveq	#0,D1
	Jsr	DEBUG
.NoCheat

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
	Movea.l	ClavierPtr,A1
	Tst.b	69(A1)		DEBUG: Eviter bloquages
	Bne	Micro_RoutageEnd

	
	Move.w	Micro_SrcLoop,D0	For...Next de la liste source
	Add.w	#1,D0		premier: 1
	Move.w	D0,Micro_SrcLoop
	Move.w	Micro_SrcNb,D1	nombre: 1..300
	Bgt.s	.LoopStartOk
	* 0 points dans la liste source: recommencer à 0
	Clr.w	Micro_RoutageEtat		
	Bra.s	.Init
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

	Movea.l	Dim2,A3		Dim Visible
	Move.w	D0,D1		Y.W
	Swap	D0		X.W
	Add.w	#2,D0		Case Droite
	Cmp.w	#36,D0		H: 19 cases = 36 petites 
	Bge.s	.NoD
	Move.w	Micro_RoutageID,D2	 	N° du routage
	Bsr	Micro_RoutageAjoutPoint
.NoD	Sub.w	#4,D0		Case gauche
	Blt.s	.NoG
	Move.w	Micro_RoutageID,D2	 	N° du routage
	Bsr	Micro_RoutageAjoutPoint
.NoG	Add.w	#2,D0
	Sub.w	#2,D1		Case Haut
	Blt.s	.NoH
	Move.w	Micro_RoutageID,D2	 	N° du routage
	Bsr	Micro_RoutageAjoutPoint		
.NoH	Add.w	#4,D1		Case Bas
	Cmp.w	#30,D1		V: 15 cases = 30 petites
	Bge.s	.NoB
	Move.w	Micro_RoutageID,D2	 	N° du routage
	Bsr	Micro_RoutageAjoutPoint
.NoB		
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

	Clr.w	Micro_TotNb
	RTS

	********************************
	*     Coordonnées du joueur    *
	********************************
Micro_Coords
	Jsr	ScreenPos		A0 -> XScr,YScr
	Clr.l	D2
	Clr.l	D3
	Move.w	XScr,D2		Pixel sur l'écran
	Lsr.w	#3,D2		Petite case
	BClr	#0,D2		Alignée sur grosse case
	Move.w	YScr,D3
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
* D3: Temporaire
* D4: Gestion Danger
* D5: Temporaire
* D6: Offset sur les DIM
* A4: Pointeur temporaire sur Dim Bombes, Flammes
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


	* Calcul offset dans tableau de routage (et autres du coup)
	Move.w	D1,D6
	Lsl.w	#6,D6
	Add.w	D0,D6
	Ext.l	D6
	Lsl.l	#2,D6	
	
	Move.b	Route_ID(A1,D6.l),D3	Test N° du routage
	Cmp.b	D3,D2
	Beq	.Micro_RoutageAjoutPointEnd

	Jsr	VBLDEBUG_START3


	Move.b	D2,Route_ID(A1,D6.l)	Ecriture N° du routage
	Move.w	(A3,D6.l),D3		Lecture Bloc Visible
	Beq	.SuitePt
	
	***************************************
	* Répandre les informations de danger *
	***************************************

	Bra	.SuitePt	Rien à répandre: je change de technique!

	Clr.l	D4		D4: Danger
	Cmp.w	#Type_Bombe,D3
	Bne.s	.NoT_Bomb
	Move.w	#Danger_Bomb,D4	Danger de la bombe	
	Bra.s	.CaseDang
.NoT_Bomb	Cmp.w	#Type_Toyo,D4
	Blt.s	.NoT_Toyo
	Cmp.w	#Type_Toyo+15,D4
	Bgt.s	.NoT_Toyo
	Move.w	#Danger_Toyo,D4
.NoT_Toyo	
.CaseDang
	Tst.l	D4		Pas de danger: rien à développer
	Beq	.SuitePt	
	*
	* Répandre en croix les informations d'une bombe	
	* comme on peut avoir 300 bombes, j'essaye une technique avec
	* moins de vérifications mais plus rapide. Je ne m'arrête que 
	* contre un mur.
	*
	Movea.l	Dim1,A4		Dim Bombes
	Move.w	(A4,D6.l),D3	N° Bombe 0-31767
	Mulu.w	#Bomb_SIZEOF,D3
	Movea.l	BombPtr,A4	Structures bombes
	Lea	(A4,D3.l),A4	Adresse bombe	
	Tst.w	Bomb_Exist(A4)
	Beq	.SuitePt		Bombe non active: on ignore
	*
	* Le temps est à prendre en compte de façon spéciale, 
	* cela dépend du temps que prend la décrémentation du danger
	*
	Move.w	Bomb_Time(A4),D3	
	
	*
	* Etaler les flammes en Horiz (HB) et Vert (GD)
	*
	Move.w	Bomb_Energy(A4),D4	Longueur flamme micro (>=3)
	Lsr.w	#1,D4		Convertir en grandes cases 
	Add.w	#Micro_PeurFlamme-1,D4		<<< OPTION: le micro a plus ou moins peur des flammes, donc s'en approche plus ou moins
	* D4= Nombre de cases à étendre de chaque côté au MAXI
	* Je ne teste pas les bounds, je compte sur le fait que le 
	* tour du niveau ne soit pas vide (normal quoi).

	* Marquer la case de la bombe comme dangereuse aussi
	Clr.l	D5	

	Move.l	#Danger_Bomb,D2	Danger bombe
	Cmp.w	#Danger_TimeBombAlert,D3
	Bgt.s	.NoAlert
	Lsl.w	#1,D2		Danger DOUBLE car bombe bientôt
.NoAlert	Move.b	D2,Route_Danger(A1,D6.l)
	*
	* Il faut faire les boucles. Comme c'est une explosion qui
	* va venir on sait que cela ne traverse rien: les bonus ne 
	* sont pas traversés.
	*

	*		*
	*** Boucle Droite ***
	*		*
.DebD	Move.l	D6,D7	Recup offset
	Move.w	D4,D3	Recup nombre de cases
.LoopD	Add.l	#SizeStructure*2,D7		prochaine grosse case	
	Move.w	(A3,D7.l),D5		Visible	
	*Beq.s	.OkD
	*Cmp.w	#Type_Bonus,D5	
	Bne.s	.DebG
.OkD	Move.b	Route_Danger(A1,D7.l),D5	Danger
	Cmp.w	D2,D5
	Bge.s	.FinD	
	Move.b	D2,Route_Danger(A1,D7.l)	
.FinD	Dbf	D3,.LoopD

	*		*
	*** Boucle Gauche ***
	*		*
.DebG	Move.l	D6,D7
	Move.w	D4,D3
.LoopG	Sub.l	#SizeStructure*2,D7		
	Move.w	(A3,D7.l),D5
	*Beq.s	.OkG
	*Cmp.w	#Type_Bonus,D5
	Bne.s	.DebH
.OkG	Move.b	Route_Danger(A1,D7.l),D5
	Cmp.w	D2,D5
	Bge.s	.FinG
	Move.b	D2,Route_Danger(A1,D7.l)		
.FinG	Dbf	D3,.LoopG

	*		*	
	***  Boucle Haut  ***
	*		*
.DebH	Move.l	D6,D7
	Move.w	D4,D3
.LoopH	Sub.l	#SizeStructure*64*2,D7		
	Move.w	(A3,D7.l),D5
	*Beq.s	.OkH
	*Cmp.w	#Type_Bonus,D5
	Bne.s	.DebB
.OkH	Move.b	Route_Danger(A1,D7.l),D5
	Cmp.w	D2,D5
	Bge.s	.FinH	
	Move.b	D2,Route_Danger(A1,D7.l)	
.FinH	Dbf	D3,.LoopH

	*		*
	***  Boucle Bas   ***
	*		*
.DebB	Move.l	D6,D7
	Move.w	D4,D3	
.LoopB	Add.l	#SizeStructure*64*2,D7		
	Move.w	(A3,D7.l),D5
	*Beq.s	.OkB
	*Cmp.w	#Type_Bonus,D5
	Bne.s	.FinHBGD
.OkB	Move.b	Route_Danger(A1,D7.l),D5
	Cmp.w	D2,D5
	Bge.s	.FinB
	Move.b	D2,Route_Danger(A1,D7.l)	
.FinB	Dbf	D3,.LoopD
.FinHBGD		
	
	Nop
.SuitePt	**************************************
	* Effacer les informations de danger *
	**************************************
	Clr.l	D4
	Move.b	Route_Danger(A1),D4
	Movea.l	Dim4,A4
	Move.b	Dim4_Mask(A4,D6.l*4),D3	Masque flammes
	Bne.s	.DangFl
	* Pas de flamme: danger de bombe ou tuyau à distance
	* Donc: si jamais le routage se fait toujours en ENTIER,
	* alors on sait que la bombe va être rajoutée au prochain routage,
	* on peut donc faire un danger = 3* décrémentation (temps que
	* la bombe explose et que la flamme arrive)
	* 
	* Si on décrémente trop peu, le micro aura peur d'une bombe
	* "fantôme" (si la flamme passe par là elle efface le danger!!!)	
	*
	Cmp.w	#Danger_Flamme,D4	Ancien danger = flamme ?
	Bne.s	.DangNorm
	Moveq	#Danger_Dec*2,D4	Danger =pas bcp  car plus de flamme...
	Bra.s	.SuiteFl
.DangNorm	Subq	#Danger_Dec,D4		
	Bra.s	.SuiteFl	
.DangFl	Moveq	#Danger_Flamme,D4		Flamme = DANGER ABSOLU
.SuiteFl	Move.b	D4,Route_Danger(A1)	
	
*.AjoutPt	
	**************************
	* Ajouter le point cible *
	**************************

	Move.w	Micro_CibNb,D6
	Add.w	#1,D6
	Move.w	D6,Micro_CibNb
	Sub.w	#1,D6
	Lsl.w	#3,D6		8 octets par point
	Add.w	Micro_CibID,D6	0 ou 4
	Move.w	D0,(A2,D6.w)	X
	Move.w	D1,2(A2,D6.w)	Y

	Add.w	#1,Micro_TotNb	DEBUG	Nb de points CREES !!!!
	Move.w	D6,Temp2+2	Offset dernière case
	
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
	Move.w	#1024,D1		Temps mini explosion ligne-colonne
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

	
Micro_RoutageEtat	Dc.w	0
Micro_RoutageID	Dc.w	0
Micro_SrcNb	Dc.w	0
Micro_SrcID	Dc.w	0
Micro_SrcLoop	Dc.w	0
Micro_CibNb	Dc.w	0
Micro_CibID	Dc.w	0
Micro_RouteStep	Dc.w	0
MicroPtr		Dc.l	0	Routage asynchrone (1 seul micro!)

Micro_TotNb	Dc.w	0	Total des points routés
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
*
* 
*
*
	
	