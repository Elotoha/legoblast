

***************	Gestion des Bumpers
*
* Pour pousser les bombes et les mecs.
* 
* C'est dans la routine des mecs que l'on teste si l'on est devant un
* bumper. Si c'est le cas, on le met "ON"
*

GestionBumpers
	Move.l	#2,TravK
	Movea.l	BumperPtr,A0
	Move.w	LastNBumper,D0
	Beq	.NoBumper
	Subq.w	#1,D0	
.Loop	Tst.w	Bumper_Activate(A0)
	Beq	.Nex
	Move.w	Bumper_X(A0),D6
	Move.w	Bumper_Y(A0),D7
	Move.w	Bumper_ImA(A0),D5
	Tst.w	Bumper_Eta(A0)
	Bne	.NexT		0: Attente

*	Move.w	#1,Bumper_Eta(A0)	
*	Bra	.Nex

.TestJD	Movem.l	D4-D6/A1,-(A7)
	Clr.l	D6
	Tst.w	Bumper_VY(A0)
	Bge.s	.nopDecD
	Sub.w	#SizeStructure*64,D6	
.nopDecD	Movea.l	LegoPtr,A1
	Clr.l	D3	
.LoopJBD	Tst.w	Leg_OkBump(A1)
	Beq.s	.NoBJo1D
	Move.w	Leg_Offset(A1),D5
	Lsl.w	#2,D5
	Move.l	Bumper_Off1(A0),D4
	And.w	#$FFF8,D4
	Add.l	D6,D4
	Cmp.w	D5,D4	
	Beq.s	.OkBJo1D	
	Move.l	Bumper_Off2(A0),D4
	And.w	#$FFF8,D4
	Add.l	D6,D4
	Cmp.w	D5,D4
	Bne.s	.NoBJo1D
.OkBJo1D	Move.w	#1,Bumper_Eta(A0)		Déclenchement
	Bra.s	.EndJD
.NoBJo1D	Adda.w	#Leg_SizeOf,A1
	Addq.w	#1,D3
	Cmp.w	#NbJoueurs,D3
	Blt.s	.LoopJBD
.EndJD	Movem.l	(A7)+,D4-D6/A1
	
	Tst.w	Bumper_Eta(A0)	Pas besoin tester bombe 
	Bne	.Nex

	***** Si le bumper est en attente, on cherche le moyen
	* de le déclencher, comme la présence d'une bombe devant lui
	* (bombe arrêtée).
	Movea.l	Dim2,A3	
	Move.l	Bumper_Off1(A0),D4
	Move.w	(A3,D4.l),D4
	Cmp.w	#Type_Bombe,D4
	Bne.s	.NoB01
	* Il y a une bombe: on déclenche!  : TEST POUR BOMBE ARRETEE ???
	Bsr	.TestMov
	Beq	.Nex
	Move.w	#1,Bumper_Eta(A0)	
	Bra	.Nex
.NoB01	Movea.l	Dim2,A3	
	Move.l	Bumper_Off2(A0),D4
	Move.w	(A3,D4.l),D4
	Cmp.w	#Type_Bombe,D4
	Bne	.Nex
	* Il y a une bombe: on déclenche!  : TEST POUR BOMBE ARRETEE ???
	Bsr	.TestMov
	Beq	.Nex
	Move.w	#1,Bumper_Eta(A0)	
	Bra	.Nex
.NexT	Bgt.s	.cont		-1: Juste pour afficher au début
	Clr.w	Bumper_Eta(A0)	on met en attente
	Move.w	Bumper_ImA(A0),D5
	Bra	.Aff
	
.cont	Cmp.w	#ImActBlocBumper,D5
	Bne.s	.NoActive
	*** Le bumper est en bout de course : on pousse une bombe si
	* il y en a.

	Movem.l	D1/D3,-(A7)	Bruit bumper....
	Moveq	#16,D3
	Moveq	#PriSonZoingBump,D1
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,D1/D3

	Movea.l	Dim2,A3			TEST CASE 1
	Move.l	Bumper_Off1(A0),D4
	Move.w	(A3,D4.l),D1
	Cmp.w	#Type_Bombe,D1	Type objet
	Bne.s	.NoB1
	Bsr	.IlYaBombe
.NoB1	Movea.l	Dim2,A3			TEST CASE 2
	Move.l	Bumper_Off2(A0),D4
	Move.w	(A3,D4.l),D1
	Cmp.w	#Type_Bombe,D1
	Bne.s	.NoB2
	Bsr	.IlYaBombe
.NoB2
	Bsr	.TestJ	Bumper les joueurs qui seraient devant !


.NoActive	Cmp.w	#ImFinBlocBumper,D5		ETA>0: Actif
	Blt.s	.Nop
	Move.w	#ImDebBlocBumper-1,D5	Fin du cycle
	Clr.w	Bumper_Eta(A0)		ETA=0: Attente!
.Nop	Addq.w	#1,D5
	Move.w	D5,Bumper_ImA(A0)		Bloc téléporteur actuel
.Aff	Move.w	D6,D3
	Move.w	D7,D4
	Add.w	Bumper_ImBa(A0),D5
	Move.w	D6,-(A7)
	Movea.l	LevelAct,A2
	Move.w	Level_Bloc(A2),D6		Bloc font niveau
	Movea.l	Planar,A2
	Bsr	TraceBlocWithBloc
	Move.w	(A7)+,D6
.Nex	Adda.w	#Bumper_SizeOf,A0
	Dbf	D0,.Loop
.NoBumper	RTS

.TestMov
	Movea.l	Dim1,A3	
	Move.l	Bumper_Off1(A0),D4		
	Move.w	(A3,D4.l),D4		N° de bombe
	Move.l	BombPtr,A3
	Mulu.w	#Bomb_SizeOf,D4
	Lea	(A3,D4.w),A3		Pointeur struct bombe
	Tst.w	Bomb_Vx(A3)
	Bne.s	.NopMv		
	Tst.w	Bomb_Vy(A3)
	Bne.s	.NopMv		
	Tst.w	#1
	RTS
.NopMv	Tst.w	#0
	RTS

.IlYABombe
	* Il Y A une bombe !
	Movea.l	Dim1,A3
	Move.w	(A3,D4.l),D4	N° Bombe
	Mulu.w	#Bomb_SizeOf,D4
	Movea.l	BombPtr,A3
	Lea	(A3,D4.l),A3	Adresse bombe
	Move.w	Bumper_VX(A0),Bomb_VX(A3)
	Move.w	Bumper_VY(A0),Bomb_VY(A3)
	RTS

	*****************
.TestJ	* (VOIR AUSSI LIGNE "SPRITES2"-1481)
	Movem.l	D4-D6/A1,-(A7)
	Clr.l	D6
	Tst.w	Bumper_VY(A0)
	Bge.s	.nopDec
	Sub.w	#SizeStructure*64,D6	
.nopDec	
	Movea.l	LegoPtr,A1
	Clr.l	D3	
.LoopJB	Tst.w	Leg_OkBump(A1)
	Beq.s	.NoBJo1
	Move.w	Leg_Offset(A1),D5
	Lsl.w	#2,D5
	Move.l	D5,Temp2

 	*Move.l	D1,-(A7)
	*Moveq	#0,D1
	*Bsr	DEBUG
	*Move.l	(A7)+,D1

	Move.l	Bumper_Off1(A0),D4
	And.w	#$FFF8,D4
	Add.l	D6,D4
	*Move.l	D4,Temp1

	* tout est multiplié par 4! donc %101 -> %10100 donc and $FFF8
	Cmp.w	D5,D4	
	Beq.s	.OkBJo1	
	Move.l	Bumper_Off2(A0),D4
	And.w	#$FFF8,D4
	Add.l	D6,D4
	*Move.l	D4,Temp2

	*Move.l	D1,-(A7)
	*Add.l	#1,TravK
	*Move.l	TravK,D1	
	*Bsr	DEBUG
	*Move.l	(A7)+,D1

	Cmp.w	D5,D4
	Bne.s	.NoBJo1
.OkBJo1	Move.w	Bumper_VX(A0),D4
	Muls.w	#6,D4	< 9
	Move.w	D4,Leg_BumpX(A1)	
	Move.w	Bumper_VY(A0),D4
	Muls.w	#6,D4	< 9
	Move.w	D4,Leg_BumpY(A1)
.NoBJo1	Adda.w	#Leg_SizeOf,A1
	Addq.w	#1,D3
	Cmp.w	#NbJoueurs,D3
	Blt.s	.LoopJB
	Movem.l	(A7)+,D4-D6/A1

	RTS


