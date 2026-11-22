***********************	BOMBES
BOMBES	
	Jsr	Micro_BombInit

	Clr.w	NbBombesEnVie
	Tst.w	LastNBomb
	Beq	.FinLoop
	Clr.l	D0
	Move.l	BombPtr,A0
	Movea.l	A0,A6   		A6 à STOCKER !
.Loop	Tst.w	Bomb_Exist(A0)
	Beq	.FLoop

	Add.w	#1,NbBombesEnVie

	Move.w	Bomb_Time(A0),D1	IMPORTANT: Une bombe explose... 

	Jsr	Micro_BombAdd	Ne pas toucher à 	D0-D1,A0/A6

	Subq.w	#1,D1   			   ...AVANT de bouger
	Ble.s	.ExOk

	Move.w	#-1,GeleState	Par défaut: bombe considérée gelée

	Tst.w	Bomb_Horloge(A0)	EXACTEMENT comme active, mais pour l'horloge...
*	Bne	.ExeNoOk		Retour en arrière... -1=Bloqué
	Bne	.NoExplode2	Elle peut pas péter, mais elle peut bouger
	
	Tst.w	Bomb_Active(A0)	On bloque sauf si explosion
	Bne	.ExOk		Pas active=GELEE !
.ExeNoOk	Tst.w	Bomb_FirstI(A0)	Pas d'image ? On force
	Bne	.FLoop		Image ? On quitte (Bomb gelée)
	Move.w	Bomb_Im(A0),D1
	Cmp.w	#BombImFin,D1
	Bgt.s	.DejO
	Add.w	#BombImGel,Bomb_Im(A0)	Décalage
.DejO	Move.w	Bomb_X(A0),D1   	Lecture position
	Move.w	Bomb_Y(A0),D2
	Bra	.TrBWF		On trace 
.ExOk	Clr.w	GeleState		Finalement, elle est pas gelée! ;-)

	Move.w	D1,Bomb_Time(A0)
	Bgt	.NoExplode

	Tst.w	Son_Activated
	Beq.s	.NoS1
	Movem.l	D0-D3,-(A7)
	Moveq	#2,D3	Son explosion
	Moveq	#PriSonExplosion,D1	Priorité
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D0-D3
.NoS1
	Clr.w	Bomb_Exist(A0)  	Bombe explose: on créée les flammes

	Move.w	Bomb_X(A0),D1   	Lecture position
	Move.w	Bomb_Y(A0),D2

	Movea.l	LegoPtr,A2
	Move.w	Bomb_Joue(A0),D5
	Mulu.w	#Leg_SizeOf,D5
	Addq.w	#1,Leg_MaBomb(A2,D5.w)	Augmentation pose bombe

	*** Pour désactiver l'attente du joueur
	Move.l	Bomb_JMem(A0),A3	Pour l'horloge *Bombe->Leg
	Tst.l	A3
	Beq.s	.NoH
	Clr.l	Leg_HMem(A3)	Le lego n'a plus de bombe en attente
.NoH
	**** Virer la bombe du visible	
	Move.w	D2,D6
	Lsl.w	#6,D6
	Add.w	D1,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Move.l	Dim2,A2
	Lea	(A2,D6.l),A2
	Moveq	#Type_Bloc_NoDestr,D3

	Cmp.w	(A2),D3	On ne met 0 que si <> bloc indestructible
	Beq.s	.Nop1
	Move.w	#0,(A2)
.Nop1
	Cmp.w	SizeStructure(A2),D3
	Beq.s	.Nop2
	Move.w	#0,SizeStructure(A2)
.Nop2
	Cmp.w	SizeStructure(A2),D3
	Beq.s	.Nop3
	Move.w	#0,SizeStructure*64(A2)
.Nop3
	Cmp.w	SizeStructure(A2),D3
	Beq.s	.Nop4
	Move.w	#0,SizeStructure*65(A2)
.Nop4	
	**** Creer les 4 Flammes
	Bsr	NewFlam		1ère flamme, donc MASTER
	Move.w	#-1,Flam_VX(A1)	Gauche
	Move.w	#0,Flam_VY(A1)
	Move.w	Flam_X(A1),Flam_XEff(A1)
	Move.w	Flam_Y(A1),Flam_YEff(A1)
	Move.w	Bomb_Energy(A0),Flam_Energy(A1)
	Movea.l	A1,A2

	Bsr	NewFlam
	Move.w	#0,Flam_VX(A1)	Haut
	Move.w	#-1,Flam_VY(A1)
	Move.w	Flam_X(A1),Flam_XEff(A1)
	Move.w	Flam_Y(A1),Flam_YEff(A1)
	Move.w	Bomb_Energy(A0),Flam_Energy(A1)
	Movea.l	A1,A3

	Bsr	NewFlam
	Move.w	#0,Flam_VX(A1)	Bas
	Move.w	#1,Flam_VY(A1)
	Addq.w	#1,Flam_Y(A1)
	Move.w	Flam_X(A1),Flam_XEff(A1)
	Move.w	Flam_Y(A1),Flam_YEff(A1)
	Move.w	Bomb_Energy(A0),Flam_Energy(A1)
	Movea.l	A1,A4

	Bsr	NewFlam
	Move.w	#1,Flam_VX(A1)	Droite
	Move.w	#0,Flam_VY(A1)
	Addq.w	#1,Flam_X(A1)
	Move.w	Flam_X(A1),Flam_XEff(A1)
	Move.w	Flam_Y(A1),Flam_YEff(A1)
	Move.w	Bomb_Energy(A0),Flam_Energy(A1)
	Movea.l	A1,A5

	Move.w	#-1,Flam_Master(A2)
	Move.l	A3,Flam_A1(A2)	Pointeurs autres flammes
	Move.l	A4,Flam_A2(A2)
	Move.l	A5,Flam_A3(A2)
		
	Move.w	#0,Flam_Master(A3)	Esclaves
	Move.l	A2,Flam_A1(A3)

	Move.w	#0,Flam_Master(A4)
	Move.l	A2,Flam_A1(A4)

	Move.w	#0,Flam_Master(A5)
	Move.l	A2,Flam_A1(A5)

	Bra	.FLoop

.NoExplode
	Move.w	Bomb_Im(A0),D3	Calcul de la nouvelle image
	Addq.w	#1,D3
	Cmp.w	#BombImT,D3	
	Ble.s	.OkIm1
	Subq.w	#1,Bomb_Cpt(A0)
	Ble.s	.OkIm1
	Move.w	#BombImL,D3
.OkIm1	Move.w	D3,Bomb_Im(A0)
.NoExplode2
	Clr.w	RebonON	
	Move.w	Bomb_X(A0),D1   	Lecture position
	Move.w	Bomb_Y(A0),D2
	Move.w	Bomb_VX(A0),D3  	Gestion mouvement
	Bne	.BombMouvX
	Move.w	Bomb_VY(A0),D4
	Bne	.BombMouvY
	Clr.w	Bomb_MouvOk(A0)
.TrBWF	* On ne trace que si la bombe n'est pas gelée, sauf si
	* la bombe vient juste d'être affichée
	Tst.w	GeleState	
	Beq.s	.NoGel
	Tst.w	Bomb_FirstI(A0)	Pas d'image ? On force
	Bne	.FLoop		Image ? On quitte (Bomb gelée)
	Move.w	Bomb_Im(A0),D3
	Cmp.w	#BombImFin,D3
	Bgt.s	.DejO2
	Add.w	#BombImGel,Bomb_Im(A0)	Décalage
.DejO2
	********
.NoGel
	Bsr	.TraceBombWithFont      On efface pas, donc on met le font
	Move.w	#1,Bomb_FirstI(A0)	Image tracée
	Bra.s	.FinNoM
.FinMov
	Tst.w	GeleState	
	Beq.s	.NoGel2
	Move.w	Bomb_Im(A0),D3
	Cmp.w	#BombImFin,D3
	Bgt.s	.NoGel2
	Add.w	#BombImGel,Bomb_Im(A0)
.NoGel2	Bsr	.TraceBomb      	On trace la nouvelle bombe sans font
	Move.w	#1,Bomb_FirstI(A0)

.FinNoM
.FLoop
	Adda.w	#Bomb_SIZEOF,A0
	Addq.w	#1,D0
	Cmp.w	LastNBomb,D0
	Blt	.Loop
.FinLoop
	RTS

	      
	***** Afficher une bombe (4 cases), avec l'image appropriée
	* A0: Structure bombe
	* D1: X
	* D2: Y
	* On ne touche pas a : D0,A0,A6
.TraceBomb
	Move.w	Bomb_Im(A0),D3    Nø de la vue (0-N)
	Movea.l	BlocDat,A2         Donnees brutes: Masque,BitMap*6
	Mulu.w	#(1+6)*2*16,D3
	Lea	(A2,D3.l),A2       Pointeur bitmap direct
	Movem.l	D0/A0,-(A7)
	Movea.l	A2,A0  	   >>> A0: Image bombe
	Mulu.w	#SizeLine*8,D2          Y*Largeur ecran*Hauteur case
	Ext.l	D1
	Add.l	D1,D2   	   Adresse relative de la case
	Move.l	Planar,A1
	Add.l	RenderBase,A1      Adresse premier pixel haut-gauche tableau
	Lea	(A1,D2.l),A1       >>> A1: Case cible sur l'écran (Adresse)
	Bsr	Trace   	   On ne restaure pas le font: si mouvement
			*          sur une flamme
	Movem.l	(A7)+,D0/A0
	RTS



	***** Afficher une bombe (4 cases), avec l'image ET LE FONT
	* A0: Structure bombe
	* D1: X
	* D2: Y
	* On ne touche pas a : D0,A0,A6
.TraceBombWithFont
	Move.w	Bomb_Im(A0),D3    Nø de la vue (0-N)
	Movea.l	BlocDat,A2         Donnees brutes: Masque,BitMap*6
	Mulu.w	#(1+6)*2*16,D3
	Lea	(A2,D3.l),A2       Pointeur bitmap direct
	Movem.l	D0/A0,-(A7)
	Movea.l	A2,A0  	   	>>> A0: Image bombe à copier
	*
	Move.w	D2,D6
	Lsl.w	#6,D6
	Add.w	D1,D6   	   Position dans DIM
	Ext.l	D6
	Lsl.l	#2,D6
*	Mulu.w	#SizeStructure,D6       
	*
	Mulu.w	#SizeLine*8,D2          Y*Largeur ecran*Hauteur case
	Ext.l	D1
	Add.l	D1,D2   	   Adresse relative de la case
	Move.l	Planar,A1
	Add.l	RenderBase,A1
	Lea	(A1,D2.l),A1	>>> A1: Case cible sur l'écran (Adresse)
	Move.l	FontPtr,A2	>>> A2: Adresse image font
	Adda.l	RenderBase,A2
	Lea	(A2,D2.l),A2
	Bsr	TraceWithFont	On restaure le font: Puisque pas de
			*	mouvement, pas de risque d'avoir une 
			*	flamme!
	Movem.l  (A7)+,D0/A0	
	RTS


	********** La bombe bouge en X
	* D1: X
	* D2: Y
	* D3: VX
	* D4: 0
.BombMouvX
	Move.w	D3,D5
	Add.w	D1,D3   		D3: Nouvelle position X

	Move.w	D3,-(A7)
	Tst.w	D5
	Ble.s	.Ok1
	Addq.w	#1,D3		Droite: case test+1
.Ok1	Bsr	Test2CasesY
	Move.w	(A7)+,D3

	Tst.l	A5
	Beq.s	.ChX    		Vide: OK	(Beq)
	Tst.w	RebonON
	Beq.s	.NoReb1
	Neg.w	Bomb_VX(A0)
	Neg.w	Bomb_VY(A0)
	Bra	.FinMov
.NoReb1	Clr.w	Bomb_VX(A0)     	Arret du mouvement
	Bra	.FinMov
.ChX
	Move.w	#1,Bomb_MouvOk(A0)

	Move.l	Dim1,A1 		On change la position de la bombe
	Move.l	Dim2,A3		Visible

	Move.w	D2,D7    		Y normal
	Lsl.w	#6,D7   		>>> MODIFICATION DES DIM <<<
	Move.w	D7,D6
	Add.w	D1,D6   		Y*64(D7)+Xancien(D1)

	Ext.l	D6
	Lsl.l	#2,D6
	Lea	(A1,D6.l),A2	Dim1: bombes
	Lea	(A3,D6.l),A4	Dim2: Visible

	Move.w	#0,(A2)			X,Y
	Move.w	#0,SizeStructure*64(A2)	X,Y+1
	Move.w	#0,SizeStructure(A2)	X+1,Y
	Move.w	#0,SizeStructure*65(A2)	X+1,Y+1

	Move.w	#0,(A4)			X,Y
	Move.w	#0,SizeStructure*64(A4)	X,Y+1
	Move.w	#0,SizeStructure*65(A4)	X+1,Y+1
	Move.w	#0,SizeStructure(A4)	X+1,Y


	Move.w	D2,D4

	* D1:X  D2:Y : Vérification téléportation

	Btst	#0,D3
	Bne	.NoTel
	Btst	#0,D2
	Bne	.NoTel

	Movea.l	Dim3,A4	
	Move.w	D7,D6		Nouvelle position
	Add.w	D3,D6		Y*64(D6)+XNouveau(D3)
	Ext.l	D6
	Lsl.l	#2,D6
	Move.l	(A4,D6.l),D6	Vérification téléporteur
	Beq.s	.NoTel
	Move.l	D6,D5		Vérification case arrivée libre
	Swap	D6
	Lsl.w	#6,D6
	Add.w	D5,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Lea	(A3,D6.l),A4
	Tst.w	(A4)		
	Bne.s	.NoTel
	Tst.w	SizeStructure(A4)
	Bne.s	.NoTel
	Tst.w	SizeStructure*64(A4)
	Bne.s	.NoTel
	Tst.w	SizeStructure*65(A4)
	Bne.s	.NoTel	

	Move.w	D5,D3	X	On téléporte la bombe
	Swap	D5
	Move.w	D5,D4	Y

	Move.w	D3,Bomb_X(A0) 
	Move.w	D4,Bomb_Y(A0)

	Bra.s	.Tel
	
.NoTel

	**** Modification des dims nouvelle position

	Move.w	D3,Bomb_X(A0)   	MAJ nouvelle position

	Move.w	D7,D6		Nouvelle position
	Add.w	D3,D6		Y*64(D6)+XNouveau(D3)
	Ext.l	D6
	Lsl.l	#2,D6

.Tel	* On efface l'ancienne bombe de l'écran
	Move.l	D6,-(A7)
	Move.w	D1,D6   		>>> MODIFICATION DE L'ECRAN <<<
	Move.w	D2,D7   		On efface l'ancienne bombe
	Bsr	Affiche
	Move.l	(A7)+,D6

	*

	Lea	(A1,D6.l),A2	Bombes
	Lea	(A3,D6.l),A4	Visible


	Move.w	D0,(A2) 			  X,Y	Dim bombes
	Move.w	D0,SizeStructure(A2)    	  X+1,Y
	Move.w	D0,SizeStructure*64(A2) 	  X,Y+1
	Move.w	D0,SizeStructure*65(A2) 	  X+1,Y+1

	Moveq	#Type_Bombe,D5
	Move.w	D5,(A4) 			  X,Y	Dim visible
	Move.w	D5,SizeStructure(A4)    	  X+1,Y
	Move.w	D5,SizeStructure*64(A4) 	  X,Y+1
	Move.w	D5,SizeStructure*65(A4) 	  X+1,Y+1

*	Move.w	D1,D6   		>>> MODIFICATION DE L'ECRAN <<<
*	Move.w	D2,D7   		On efface l'ancienne bombe
*	Bsr	Affiche
	Move.w	D3,D1   		Nouveau X : On peut virer D3
	Move.w	D4,D2
	Bra	.FinMov



	********** La bombe bouge en Y
	* D1: X
	* D2: Y
	* D3: 0
	* D4: VY
.BombMouvY
	Move.w	D4,D5   		-(Valeur mouvement)
	Add.w	D2,D4   		D4: Nouvelle position Y
	Move.w	D4,-(A7)
	
	Tst.w	D5
	Ble.s	.Ok2
	Addq.w	#1,D4		Bas: case test+1
.Ok2	Bsr	Test2CasesX
	Move.w	(A7)+,D4

	Tst.l	A5
	Beq.s	.ChY
	Tst.w	RebonON
	Beq.s	.NoReb2
	Neg.w	Bomb_VX(A0)
	Neg.w	Bomb_VY(A0)
	Bra	.FinMov
.NoReb2	Clr.w	Bomb_VY(A0)     	Arret du mouvement 
	Bra	.FinMov

.ChY	Move.w	#1,Bomb_MouvOk(A0)
	Move.l	Dim1,A1 		On change la position de la bombe
	Move.l	Dim2,A3		Visible
	Move.w	D2,D6   		Y ancien
	Lsl.w	#6,D6   		>>> MODIFICATION DES DIM <<<
	Add.w	D1,D6		YAncien*64(D6)+X(D1)
	Ext.l	D6
	Lsl.l	#2,D6
	Lea	(A1,D6.l),A2	Dim1: Bombes
	Lea	(A3,D6.l),A4	Dim2: Visible
	Move.w	#0,(A2)			X,Y
	Move.w	#0,SizeStructure*64(A2)	X,Y+1
	Move.w	#0,SizeStructure(A2)	X+1,Y
	Move.w	#0,SizeStructure*65(A2)	X+1,Y+1
	Move.w	#0,(A4)			X,Y
	Move.w	#0,SizeStructure*64(A4)	X,Y+1
	Move.w	#0,SizeStructure*65(A4)	X+1,Y+1
	Move.w	#0,SizeStructure(A4)	X+1,Y

	Move.w	D1,D3

	* D1:X  D2:Y : Vérification téléportation

	Btst	#0,D1
	Bne	.NoTel2
	Btst	#0,D4
	Bne	.NoTel2

	Movea.l	Dim3,A4	
	Move.w	D4,D6		Nouvelle position
	Lsl.w	#6,D6	
	Add.w	D1,D6		YNouveau*64+XNouveau
	Ext.l	D6
	Lsl.l	#2,D6
	Move.l	(A4,D6.l),D6	Vérification téléporteur
	Beq.s	.NoTel2
	Move.l	D6,D5		Vérification case arrivée libre
	Swap	D6
	Lsl.w	#6,D6
	Add.w	D5,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Lea	(A3,D6.l),A4
	Tst.w	(A4)		
	Bne.s	.NoTel2
	Tst.w	SizeStructure(A4)
	Bne.s	.NoTel2
	Tst.w	SizeStructure*64(A4)
	Bne.s	.NoTel2
	Tst.w	SizeStructure*65(A4)
	Bne.s	.NoTel2	

	Move.w	D5,D3	X	On téléporte la bombe
	Swap	D5
	Move.w	D5,D4	Y

	Move.w	D3,Bomb_X(A0) 
	Move.w	D4,Bomb_Y(A0)

	Bra.s	.Tel2
	
.NoTel2
	Move.w	D4,Bomb_Y(A0)

	******* Modification des Dims nouvelle position

	Move.w	D4,D6   		Nouvelle position
	Lsl.w	#6,D6		
	Add.w	D1,D6		YNouveau*64(D6)+X(D1)
	Ext.l	D6
	Lsl.l	#2,D6
.Tel2
	*************** On efface l'ancienne bombe de l'écran
	Move.l	D6,-(A7)
	Move.w	D1,D6   		>>> MODIFICATION DE L'ECRAN <<<
	Move.w	D2,D7   		On efface l'ancienne bombe
	Bsr	Affiche
	Move.l	(A7)+,D6

	Lea	(A1,D6.l),A2	Bombe
	Lea	(A3,D6.l),A4	Visible

	Move.w	D0,(A2)			  X,Y	Dim bombes
	Move.w	D0,SizeStructure(A2)    	  X+1,Y
	Move.w	D0,SizeStructure*64(A2) 	  X,Y+1
	Move.w	D0,SizeStructure*65(A2) 	  X+1,Y+1

	Moveq	#Type_Bombe,D5
	Move.w	D5,(A4) 			  X,Y	Dim visible
	Move.w	D5,SizeStructure(A4)    	  X+1,Y
	Move.w	D5,SizeStructure*64(A4) 	  X,Y+1
	Move.w	D5,SizeStructure*65(A4) 	  X+1,Y+1

*	Move.w	D1,D6   		>>> MODIFICATION DE L'ECRAN <<<
*	Move.w	D2,D7   		On efface l'ancienne bombe
*	Bsr	Affiche
	Move.w	D4,D2   		Nouveau Y : On peut virer D4
	Move.w	D3,D1
	Bra	.FinMov


	***** Tester pour savoir si la bombe peut aller sur ces cases
	*       	On ne teste que le dim general, le visible:
	*       	murs, bonus visibles, etc...
	*       	Mais SURTOUT PAS les flammes ! une bombe peut
	*       	aller dans les flammes. D'ailleurs il faut mettre
	*       	ICI le compteur de la bombe a 0 si une flamme est
	*       	sur une des cases cible.
	*
	*       	Si une bombe est choquée, on transmet l'énergie:
	*       	Si 3 Dans la Dim2, on regarde le Dim1 pour avoir
	*       	le NUMERO de la bombe
	****
	* D3: New X
	* D2: Y
	* On ne touche pas a D0,D1,D2,D3,D5,A0,A6
Test2CasesY
	Move.l	D5,-(A7)
	Moveq	#-1,D5
	Movea.l	#0,A5
	Move.w	D2,D4
	Lsl.w	#6,D4
	Add.w	D3,D4   		Position dans le tableau
	Ext.l	D4
	Lsl.l	#2,D4
	Move.l	Dim1,A1		Bombes
	Move.l	Dim2,A2		Visible
	Lea	(A1,D4.l),A1    	Dim1: Bombes
	Lea	(A2,D4.l),A2    	Dim2: Visible

.TEST1
	Movea.l	Dim7,A4
	Lea	(A4,D4.l),A4
	Move.w	(A4),D7
	Cmp.w	#Type_Explo,D7
	Bne.s	.NoExpl1
	Clr.w	Bomb_Time(A0)
	Bra	.noZer1	
.NoExpl1

	Move.w	(A2),D6 			TEST (Y)
	Beq	.Zer1   		Case vide: ok


	Tst.w	Bomb_MouvOk(A0)
	Beq.s	.NoSon1

	Tst.w	Bomb_Reb(A0)	Bombe rebondit ??? ;-)
	Beq.s	.NopRb1
	Movem.l	D1/D3,-(A7)	Bruit bombe rebondi
	Moveq	#15,D3
	Moveq	#PriSonBongBombe,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3	
	Move.w	#-1,RebonON
	Movea.l	#10,A5		>0: Pas d'arrêt de bombe !
	Bra.s	.NoSon1		Zer1
.NopRb1

	Movem.l	D1/D3,-(A7)	Bruit choc bombe
	Moveq	#4,D3
	Moveq	#PriSonChocBombe,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3
.NoSon1
	Cmp.w	#Type_Bombe,D6   			>>> BOMBES <<<
	Bne.s	.NoB1   		
	Move.w	(A1),D6 			Nø bombe
	Move.w	D6,D5
	Mulu.w	#Bomb_SIZEOF,D6
	Lea	(A6,D6.w),A3
	Move.w	Bomb_VX(A3),D4     Mouvement bombe touchée (réception)
	Move.w	Bomb_VY(A3),D7
	Tst.w	D7      			Si Autre bouge en Y
	Beq.s	.NoMovY
	Clr.w	Bomb_VY(A3)
	Move.w	Bomb_VX(A0),Bomb_VX(A3)
	Bra.s	.NoB1
.NoMovY	Tst.w	D4      			Si autre bouge en X
	Bne.s	.MovX
	Move.w	Bomb_VX(A0),Bomb_VX(A3)
	Bra.s	.NoB1
.MovX	Add.w	Bomb_VX(A0),D4
	Bne.s	.NoB1
	Clr.w	Bomb_VX(A3)		Total=0: Sens inverse et =      
.NoB1	suba.w	#1,A5  		 Pas de mouvement: Case non vide
	Bra.s	.NoZer1
.Zer1	Movea.l	Dim4,A4		Flammes
	Lea	(A4,D4.l*4),A4  	Dim4: Flammes (Masque+Compteurs!)
	Tst.b	Dim4_Mask(A4)    			>>> FLAMMES ???? <<<
	Beq.s	.NoZer1
	Clr.w	Bomb_Time(A0)   	Bombe touche flamme (Simple non?;)
.NoZer1


.TEST2	Movea.l	Dim7,A4
	Lea	(A4,D4.l),A4
	Move.w	SizeStructure*64(A4),D7
	Cmp.w	#Type_Explo,D7
	Bne.s	.NoExpl2
	Clr.w	Bomb_Time(A0)
	Bra	.noZer2	
.NoExpl2

	Move.w	SizeStructure*64(A2),D6 	TEST (Y+1)
	Beq	.Zer2

	Tst.w	Bomb_MouvOk(A0)
	Beq.s	.NoSon2

	Tst.w	Bomb_Reb(A0)	Bombe rebondit ??? ;-)
	Beq.s	.NopRb2
	Movem.l	D1/D3,-(A7)	Bruit bombe rebondi
	Moveq	#15,D3
	Moveq	#PriSonBongBombe,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3	
	Move.w	#-1,RebonON
	Movea.l	#10,A5		>0: Pas d'arrêt de bombe !
	Bra.s	.NoSon2		Zer2
.NopRb2

	Movem.l	D1/D3,-(A7)	Bruit choc bombe
	Moveq	#4,D3
	Moveq	#PriSonChocBombe,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3
.noson2
	Cmp.w	#Type_Bombe,D6		>>> BOMBES <<<
	Bne.s 	.NoB2
	Move.w	SizeStructure*64(A1),D6 	Nø Bombe
	Cmp.w	D5,D6
	Beq.s	.NoB2
	Mulu.w	#Bomb_SIZEOF,D6
	Move.w	Bomb_VX(A3),D4     Mouvement bombe touchée (réception)
	Move.w	Bomb_VY(A3),D7
	Tst.w	D7      			Si autre bouge en Y
	Beq.s	.NoMY2
	Clr.w	Bomb_VY(A3)
	Move.w	Bomb_VX(A0),Bomb_VX(A3)
	Bra.s	.NoB2
.NoMY2	Tst.w	D4      			Si Autre bouge en X
	Bne.s	.MoX2   
	Move.w	Bomb_VX(A0),Bomb_VX(A3)
	Bra.s	.NoB2
.MoX2	Add.w	Bomb_VX(A0),D4
	Bne.s	.NoB2
	Clr.w	Bomb_VX(A6,D6.w)		Total=0: Sens inverse et =      
.NoB2	suba.w	#1,A5
	Bra.s	.NoZer2
.Zer2	Move.l	Dim4,A4		Flammes
	Lea	(A4,D4.l*4),A4  	Dim4: Flammes (Masque+Compteurs!)
	Tst.b	Dim4_Mask+YPlusUN(A4)    	>>> FLAMMES ???? <<<
	Beq.s	.NoZer2
	Clr.w	Bomb_Time(A0)   	Bombe touche flamme (Simple non?;)
.NoZer2	Move.l	(A7)+,D5
	RTS




	***** Tester pour savoir si la bombe peut aller sur ces cases
	* D1: X
	* D4: New Y
	* On ne touche pas a D0-D2,D4-D5,A0,A6
Test2CasesX
	Move.l	D5,-(A7)
	Moveq	#-1,D5
	Movea.l	#0,A5
	Lsl.w	#6,D4
	Add.w	D1,D4   		Position dans le tableau
	Ext.l	D4
	Lsl.l	#2,D4
	Move.l	Dim1,A1
	Lea	(A1,D4.l),A1    	Dim1: Bombes
	Move.l	Dim2,A2
	Lea	(A2,D4.l),A2    	Dim2: Visible

.TEST1	Movea.l	Dim7,A4
	Lea	(A4,D4.l),A4
	Move.w	(A4),D7
	Cmp.w	#Type_Explo,D7
	Bne.s	.NoExpl1
	Clr.w	Bomb_Time(A0)
	Bra	.Zer1	
.NoExpl1

	Move.w	(A2),D6 			TEST (X)
	Beq	.Zer1   		Case vide: ok


	Tst.w	Bomb_MouvOk(A0)
	Beq.s	.NoSon3
	
	Tst.w	Bomb_Reb(A0)	Bombe rebondit ??? ;-)
	Beq.s	.NopRb3
	Movem.l	D1/D3,-(A7)	Bruit bombe rebondi
	Moveq	#15,D3
	Moveq	#PriSonBongBombe,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3	
	Move.w	#-1,RebonON
	Movea.l	#10,A5		>0: Pas d'arrêt de bombe !
	Bra.s	.NoSon3		Zer1
.NopRb3
	
	Movem.l	D1/D3,-(A7)	Bruit choc bombe
	Moveq	#4,D3
	Moveq	#PriSonChocBombe,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3
.noson3
	Cmp.w	#Type_Bombe,D6   			>>> BOMBES <<<
	Bne.s	.NoB1   		=3: Bombe

	Move.w	(A1),D6 			Nø bombe
	Move.w	D6,D5		Mémoire numéro de bombe
	Mulu.w	#Bomb_SIZEOF,D6
	Lea	(A6,D6.w),A3
	Move.w	Bomb_VX(A3),D4     Mouvement bombe touchée (réception)
	Move.w	Bomb_VY(A3),D7
	Tst.w	D4      			Si autre bouge en X
	Beq.s	.NoMovX
	Clr.w	Bomb_VX(A3)
	Move.w	Bomb_VY(A0),Bomb_VY(A3)
	Bra.s	.NoB1
.NoMovX	Tst.w	D7      			Si autre bouge en Y
	Bne.s	.MovY
	Move.w	Bomb_VY(A0),Bomb_VY(A3)	
	Bra.s	.NoB1
.MovY	Add.w	Bomb_VY(A0),D7
	Bne.s	.NoB1
	Clr.w	Bomb_VY(A3)		Total=0: Sens inverse et =      
.NoB1	suba.w	#1,A5  		 Pas de mouvement: Case non vide
	Bra.s	.NoZer1
.Zer1	Move.l	Dim4,A4
	Lea	(A4,D4.l*4),A4  	Dim4: Flammes (Masque+Compteurs!)
	Tst.b	Dim4_Mask(A4)		>>> FLAMMES ???? <<<
	Beq.s	.NoZer1
	Clr.w	Bomb_Time(A0)   	Bombe touche flamme (Simple non?;)
.NoZer1	

.TEST2	Movea.l	Dim7,A4
	Lea	(A4,D4.l),A4
	Move.w	SizeStructure(A4),D7
	Cmp.w	#Type_Explo,D7
	Bne.s	.NoExpl2
	Clr.w	Bomb_Time(A0)
	Bra	.Zer2	
.NoExpl2

	Move.w	SizeStructure(A2),D6         TEST (X+1)
	Beq	.Zer2

	Tst.w	Bomb_MouvOk(A0)
	Beq.s	.NoSon4

	Tst.w	Bomb_Reb(A0)	Bombe rebondit ??? ;-)
	Beq.s	.NopRb4
	Movem.l	D1/D3,-(A7)	Bruit bombe rebondi
	Moveq	#15,D3
	Moveq	#PriSonBongBombe,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3	
	Move.w	#-1,RebonON
	Movea.l	#10,A5		>0: Pas d'arrêt de bombe !
	Bra.s	.NoSon4		Zer2
.NopRb4
	Movem.l	D1/D3,-(A7)	Bruit choc bombe
	Moveq	#4,D3
	Moveq	#PriSonChocBombe,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3
.noson4
	Cmp.w	#Type_Bombe,D6   			>>> BOMBES <<<
	Bne.s	.NoB2

	Move.w	SizeStructure(A1),D6         Nø Bombe
	Cmp.w	D5,D6		Même bombe que l'autre case ?
	Beq.s	.NoB2	
.NopSame	Mulu.w	#Bomb_SIZEOF,D6
	Lea	(A6,D6.w),A3
	Move.w	Bomb_VX(A3),D4     Mouvement bombe touchée (réception)
	Move.w	Bomb_VY(A3),D7
	Tst.w	D4      			Si autre bouge en X
	Beq.s	.NoMX2
	Clr.w	Bomb_VX(A3)
	Move.w	Bomb_VY(A0),Bomb_VY(A3)
	Bra.s	.NoB2
.NoMX2	Tst.w	D7
	Bne.s	.MoY2   
	Move.w	Bomb_VY(A0),Bomb_VY(A3)
	Bra.s	.NoB2
.MoY2	Add.w	Bomb_VY(A0),D4
	Bne.s	.NoB2
	Clr.w	Bomb_VY(A3)		Total=0: Sens inverse et =      
.NoB2	suba.w	#1,A5
	Bra.s	.NoZer2
.Zer2	Move.l	Dim4,A4
	Lea	(A4,D4.l*4),A4  	Dim4: Flammes (Masque+Compteurs!)
	Tst.b	Dim4_Mask+XPlusUN(A4)            >>> FLAMMES ???? <<<
	Beq.s	.NoZer2
	Clr.w	Bomb_Time(A0)   	Bombe touche flamme (Simple non?;)
.NoZer2	Move.l	(A7)+,D5
	RTS

*
* Mettre une bombe dans les DIMS Adresse bombe,numéro(A0,D0)
*
BombToDim
	Move.l	Dim1,A1	Bombes
	Move.l	Dim2,A3	Visible
	Move.w	Bomb_Y(A0),D6
	Lsl.w	#6,D6
	Add.w	Bomb_X(A0),D6
	Ext.l	D6
	Lsl.l	#2,D6
	Lea	(A1,D6.l),A2	Bombes
	Lea	(A3,D6.l),A4	Visible

	Move.w	D0,(A2)			X,Y
	Move.w	D0,SizeStructure(A2)	X+1,Y
	Move.w	D0,64*SizeStructure(A2)	X,Y+1
	Move.w	D0,65*SizeStructure(A2)	X+1,Y+1

	Moveq	#Type_Bombe,D4
	Move.w	D4,(A4)			X,Y
	Move.w	D4,SizeStructure(A4)	X+1,Y
	Move.w	D4,64*SizeStructure(A4)	X,Y+1
	Move.w	D4,65*SizeStructure(A4)	X+1,Y+1
	RTS
	
************	Ajouter une bombe dans le tableau des bombes
*
* 	D4: X
*	D5: Y
*	EFlamme: Energies des flammes
*	BTime: Temps avant explosion
*	NbBoucles: Nombre de boucles 
*	BombReb: Maladie bombes rebondissent
*
NewBomb
	* On vérifie que la case du visible est vide

	Clr.l	D7		D7=0: Bombe non posée
	Movea.l	Dim2,A0		Case utilisée ?
	Move.w	D5,D6
	Lsl.w	#6,D6
	Add.w	D4,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Lea	(A0,D6.l),A2
	Tst.w	(A2)			X,Y
	Bne	.NoNewB
	Tst.w	SizeStructure*65(A2)	X+1,Y+1
	Bne	.NoNewB
	Tst.w	SizeStructure*64(A2)	X,Y+1
	Bne	.NoNewB
	Tst.w	SizeStructure(A2)		X+1,Y
	Bne	.NoNewB


	* On vérifie qu'on ne pose pas la bombe sur une flamme
	* (Test facultatif si mec non invincible)
	Move.l	Dim4,A1	Dim flammes
	Lea	(A1,D6.l*4),A2	Adresse case
	Tst.b	Dim4_Mask(A2)	Flammes ? :->
	Bne	.NoNewB
	Tst.b	Dim4_Mask+XPlusUN(A2)
	Bne	.NoNewB
	Tst.b	Dim4_Mask+YPlusUN(A2)
	Bne	.NoNewB
	Tst.b	Dim4_Mask+XPlusUN+YPlusUN(A2)
	Bne	.NoNewB

	* On la pose

	Movem.l	D1-D3,-(A7)	Bruit "posage" bombe
	Moveq	#5,D3
	Moveq	#PriSonPoseBombe,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1-D3
	
	Clr.l	D0		Recherche emplacement tableau
	Movea.l	BombPtr,A0
	Tst.w	LastNBomb
	Bne.s	.Search
	Move.w	#1,LastNBomb	
	Bra.s	.Ok
.Search	Tst.w	Bomb_Exist(A0)
	Beq.s	.Ok
	Adda.w	#Bomb_SizeOf,A0
	Addq.w	#1,D0
	Cmp.w	LastNBomb,D0
	Blt.s	.Search
	Addq.w	#1,LastNBomb	Plus de place ? on en créée	
.Ok	
	Move.w	#0,Bomb_FirstI(A0)	Pas d'image déjà affichée
	Move.w	D4,Bomb_X(A0)	Initialisation des nouvelles valeurs
	Move.w	D5,Bomb_Y(A0)
	Move.w	#0,Bomb_VX(A0)
	Move.w	#0,Bomb_VY(A0)
	Move.w	#BombImL,Bomb_Im(A0)
	Move.w	EFlamme,Bomb_Energy(A0)
	Move.w	BTime,Bomb_Time(A0)
	Move.w	BombReb,Bomb_Reb(A0)
	Move.w	#1,Bomb_Exist(A0)
	Move.w	#1,Bomb_Active(A0)
	Move.l	#0,Bomb_Routine(A0)
	Move.l	#0,Bomb_JMem(A0)	Pour l'horloge
	Move.w	D3,Bomb_Joue(A0)
	Clr.w	Bomb_Horloge(A0)
	Move.w	NbBoucles,Bomb_Cpt(A0)	
	Bsr	BombToDim	

	* On a le droit de la poser: est-ce sur une flamme ? ;->
	* D6: Offset dans le Dim
	Moveq	#-1,D7	D7=-1: Bombe posée avec succés
	Move.l	Dim4,A1	Dim flammes
	Lea	(A1,D6.l*4),A2	Adresse case
	Tst.b	Dim4_Mask(A2)	Flammes ? :->
	Bne.s	.Fl
	Tst.b	Dim4_Mask+XPlusUN(A2)
	Bne.s	.Fl
	Tst.b	Dim4_Mask+YPlusUN(A2)
	Bne.s	.Fl
	Tst.b	Dim4_Mask+XPlusUN+YPlusUN(A2)		
	Bne.s	.Fl
.NoNewB	RTS		
.Fl	* Y'a une flamme sous la bombe: elle explose !!! :->>>
	Move.w	#0,Bomb_Time(A0)
	RTS

