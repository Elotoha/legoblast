
********* Ajouter une destruction à la liste
* 
* D1: X
* D2: Y
* D4: Type
*
NewMur	Movem.l	D1-D3/D6/A1-A2/A6,-(A7)
	And.w	#$FE,D1		case entière
	And.w	#$FE,D2
	Move.w	D2,D6
	Lsl.w	#6,D6
	Add.w	D1,D6
	Ext.l	D6
	Lsl.l	#2,D6
	
	Move.l	MurPtr,A1
	Clr.l	D3
	Tst.w	LastNMur
	Bne.s	.Search
	Move.w	#1,LastNMur
	Bra.s	.Ok
.Search	Tst.w	Mur_Exist(A1)
	Beq.s	.Ok
	Adda.w	#Mur_SizeOf,A1
	Addq.w	#1,D3
	Cmp.w	LastNMur,D3
	Blt.s	.Search
	Addq.w	#1,LastNMur	Plus de place ? on en créée	
.Ok	

	Move.w	D1,Mur_X(A1)	(X,Y):Gauche,haut,bas (X+1,Y):droite
	Move.w	D2,Mur_Y(A1)
	Move.w	D4,Mur_Type(A1)
	Move.w	#1,Mur_Exist(A1)
	Move.l	LevelAct,A6

	Cmp.w	#Type_Bloc_Destr,D4
	Bne.s	.NoM
	Move.w	Level_Bloc+4(A6),D3		Mur
	Move.w	D3,Mur_ImA(A1)	Image actuelle 
	Add.w	#MurDestrNbIms,D3
	Move.w	D3,Mur_ImF(A1)	Image finale
	Move.w	#Type_Bloc_DestrAct,D3	On met état cours destruction
	Bra.s	.NoBon
.NoM
	Cmp.w	#Type_Bonus,D4
	Bne.s	.NoBon
	Movea.l	Dim5,A2		Dim bonus
	Move.w	(A2,D6.l),D3	N° Bonus
	Lea	BonusIdx,A2
	Move.w	(A2,D3.w*2),D3	Image(N°Bonus)
	Move.w	D3,Mur_ImA(A1)	Image actuelle bonus	
	Add.w	#BonusDestrNbIms,D3
	Move.w	D3,Mur_ImF(A1)	
	Move.w	#Type_Bonus_DestrAct,D3	On met état cours destruction
*	Move.w	#$f00,$dff180
.NoBon

	Movea.l	Dim2,A1		Visible
	Lea	(A1,D6.l),A1
	Move.w	D3,(A1)
	Move.w	D3,SizeStructure(A1)
	Move.w	D3,SizeStructure*64(A1)
	Move.w	D3,SizeStructure*65(A1)
	Movem.l	(A7)+,D1-D3/D6/A1-A2/A6
	RTS




******* Gestion de la destruction des murs/bombes
*
*
*
Murs	Movea.l	MurPtr,A0
	Tst.w	LastNMur
	Beq	.NoMur
	Clr.l	D0
.Loop	Tst.w	Mur_Exist(A0)
	Beq	.NotEx
	Move.w	Mur_X(A0),D3
	Move.w	Mur_Y(A0),D4
	Move.w	Mur_ImA(A0),D5
	Addq.w	#1,D5
	Cmp.w	Mur_ImF(A0),D5
	Ble.s	.Ok			FINI
	* Fin animation		
	Movea.l	LevelAct,A6
	Move.w	D4,D6
	Lsl.w	#6,D6
	Add.w	D3,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Moveq	#0,D7		Type Font	
	Move.w	Mur_Type(A0),D1
	Cmp.w	#Type_Bloc_Destr,D1
	Bne.s	.NoMurD
	* Mur destructible: Bonus ?
	Movea.l	Dim5,A1
	Move.w	(A1,D6.l),D2	N° Bonus	
	Beq.s	.NoMurD		Pas de bonus derrière le mur	
	Moveq	#Type_Bonus,D7	Type Bonus
	Lea	BonusIdx,A3	
	Move.w	(A3,D2.w*2),D5	Image pour le Bonus
	*** On met un bonus
	Movea.l	Planar,A1
	Movea.l	FontPtr,A2
	Bsr	TraceBlocWithFont		A2=Pl,D3=X,D4=Y,D5=Bloc
	Bra.s	.All	
.NoMurD	*** On met un vide
	Movea.l	Planar,A1
	Movea.l	FontPtr,A2
	*Move.w	Level_Bloc(A6),D5	N° bloc de font actuel
	Move.w	#Bloc_Vide,D5
	Bsr	TraceBlocWithFont		A2=Pl,D3=X,D4=Y,D5=Bloc


.All	Movea.l	Dim2,A1	Visible
	Lea	(A1,D6.l),A1
	Move.w	D7,(A1)			Type Bloc vide/Bonus
	Move.w	D7,SizeStructure(A1)	
	Move.w	D7,SizeStructure*64(A1)	
	Move.w	D7,SizeStructure*65(A1)		

	Move.w	#0,Mur_Exist(A0)		
	Bra.s	.NotEx

.Ok	Move.w	D5,Mur_ImA(A0)		PAS FINI
	Movea.l	Planar,A1
	Movea.l	FontPtr,A2
	Bsr	TraceBlocWithFont	A1=Pl,A2=Font,D3=X,D4=Y,D5=Bloc
.NotEx	Adda.w	#Mur_SizeOf,A0
	Addq.w	#1,D0
	Cmp.w	LastNMur,D0
	Blt	.Loop	

.NoMur	RTS

	
	
	


	