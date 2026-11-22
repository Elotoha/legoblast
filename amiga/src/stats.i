
StatsCoul_Vert	=	110	Vert		23
StatsCoul_VertF	=	108	Vert		21
StatsCoul_Jaune	=	98	Jaune		20
StatsCoul_Rouge	=	99	Rouge		29
StatsCoul_RougeF	=	100	Rouge		28
StatsCoul_Gris	=	101	Gris (barres)	10
StatsCoul_GrisF	=	102	Gris (ombre)	15
StatsCoul_Blanc	=	103	Blanc (texte)	3
StatsSizeGames	=	60
StatsSizeBombs	=	45
StatsSizeBonus	=	45
StatsY		=	117
StatsTitreY	=	104	
StatsTitreX1	=	52	DEADS
StatsTitreX2	=	86	GAMES
StatsTitreX3	=	153	WINS
StatsTitreX4	=	196	BOMBS
StatsTitreX5	=	248	BONUS
StatsBaseX4	=	54
StatsBaseX1	=	87
StatsBaseX5	=	157
StatsBaseX2	=	191
StatsBaseX3	=	243
StatsPasY		=	16
StatsHautJauge	=	9


************ STATISTIQUES DE FIN DE JEU (ESC ou PODIUM)
*
*
*
*
STATISTIQUES
*
* ICI j'écris 5 .L pour les statistiques.
* c'est important pour l'indexage du traçage
*
	Lea	StatsWork,A1
	Movea.l	LegoPtr,A0
	Clr.l	D2	Max de parties jouées
	Clr.l	D3	Max de bombes posées
	Clr.l	D4	Max de bonus pris
	Moveq	#NbJoueurs-1,D0
.LoopJ	Move.l	Leg_GamesPlayed(A0),D1
	Cmp.l	D1,D2
	Bge.s	.Nop
	Move.l	D1,D2
.Nop	Move.l	D1,(A1)+
	*
	Move.l	Leg_GamesLoose(A0),(A1)+
	*
	Move.l	Leg_GamesWon(A0),(A1)+
	*
	Move.l	Leg_BombesPosees(A0),D1
	Cmp.l	D1,D3
	Bge.s	.Nop2
	Move.l	D1,D3		
.Nop2	Move.l	D1,(A1)+
	*
	Move.l	Leg_BonusTaken(A0),D1
	Cmp.l	D1,D4
	Bge.s	.Nop3
	Move.l	D1,D4		
.Nop3	Move.l	D1,(A1)+
	*
	Adda.w	#Leg_SizeOf,A0
	Dbf	D0,.LoopJ


	Tst.l	D2
	Bgt.s	.Ok1
	Moveq	#1,D2
.Ok1	
	Tst.l	D3
	Bgt.s	.Ok2
	Moveq	#1,D3
.Ok2	
	Tst.l	D4
	Bgt.s	.Ok3
	Moveq	#1,D4
.Ok3	



***************** Je transforme les données stockées en pourcentage
*
* (plus exactement en nombre de pixels sur la jauge maxi) 
*
*
	Lea	StatsWork,A1
	Lea	StatsWork2,A2
	Moveq	#NbJoueurs-1,D0
.LoopJP	Move.l	(A1)+,D1		GamesPlayed
	Mulu.l	#StatsSizeGames,D1
	Divu.l	D2,D1
	Move.l	D1,(A2)+		
	*
	Move.l	(A1)+,D1		GamesLoose
	Mulu.l	#StatsSizeGames,D1
	Divu.l	D2,D1
	Move.l	D1,(A2)+
	*
	Move.l	(A1)+,D1		GamesWon
	Mulu.l	#StatsSizeGames,D1
	Divu.l	D2,D1
	Move.l	D1,(A2)+
	*
	Move.l	(A1)+,D1		BombesPosées
	Mulu.l	#StatsSizeBombs,D1
	Divu.l	D3,D1
	Move.l	D1,(A2)+
	*
	Move.l	(A1)+,D1		BonusTaken
	Mulu.l	#StatsSizeBonus,D1
	Divu.l	D4,D1
	Move.l	D1,(A2)+
	Dbf	D0,.LoopJP

*
* 
* Je lis et trace
*
*
******** DEBUT DU TRACAGE A L'ECRAN

	Move.w	#StatsTitreX1,D0	
	Move.w	#StatsTitreY,D1
	Move.l	#Phrase_Titre3,StatsMem1	3:WINS
	Bsr	LaunchGene

	Move.w	#StatsTitreX2,D0	
	Move.w	#StatsTitreY,D1
	Move.l	#Phrase_Titre2,StatsMem1	2:GAMES
	Bsr	LaunchGene

	Move.w	#StatsTitreX3,D0	
	Move.w	#StatsTitreY,D1
	Move.l	#Phrase_Titre1,StatsMem1	1:DEADS
	Bsr	LaunchGene

	Move.w	#StatsTitreX4,D0	
	Move.w	#StatsTitreY,D1
	Move.l	#Phrase_Titre4,StatsMem1	4:BOMBS
	Bsr	LaunchGene

	Move.w	#StatsTitreX5,D0	
	Move.w	#StatsTitreY,D1
	Move.l	#Phrase_Titre5,StatsMem1	5:BONUS
	Bsr	LaunchGene

	Lea	Tri,A5
	Move.w	#StatsY,StatsYBase
	Moveq	#NbJoueurs-1,D5
.LoopJT	Move.w	(A5)+,D0
	Mulu.w	#5*4,D0
	Lea	(StatsWork,D0.w),A2
	Lea	(StatsWork2,D0.w),A1

	Move.w	StatsYBase,D1
	Move.w	D1,D3				Y1
	Add.w	#StatsHautJauge-1,D3		Y2
	Move.w	#StatsBaseX1,D0			X1
	**********************

	Tst.l	(A1)		Si Nb de parties jouées=0... quitte
	Beq.s	.EmptyPl

	Movem.l	D0-D2,-(A7)
	Moveq	#4,D0
	Move.w	StatsYBase,D1
	Move.w	-2(A5),D2
	Bsr	CopyOneHead
	Movem.l	(A7)+,D0-D2

	**********************
	Move.l	(A2)+,StatsMem3
	Move.l	(A1)+,D2		GamesPlayed
	Move.w	D2,StatsMem4
	Bne.s	.OkB0
	*Bra.s	.OkB00		On affiche pas le jaune
	* Aucune partie jouée: on affiche RIEN
.EmptyPl
	Adda.w	#4*4,A2
	Adda.w	#4*4,A1
	Bra	.NoStatsForHim
.OkB0	Add.w	D0,D2				X2
	Move.w	#StatsCoul_Jaune,D6			C
	Bsr	LaunchBAROmbre	BAR (D0,D1)-(D2,D3),D6
.OkB00	**********************
.NoB0	Move.l	(A2)+,D7	Nb
	Move.l	(A1)+,D0	%	GamesLoose
	Beq.s	.NoB1

	Move.w	#StatsBaseX1,D2		X2
	Add.w	StatsMem4,D2	Taille parties jouées
	Neg.w	D0		-Taille
	Add.w	D2,D0		X=Fin-Taille	X1

	Move.w	#StatsCoul_Rouge,D6			C
	Bsr	LaunchBAR		BAR (D0,D1)-(D2,D3),D6
	*
	Move.w	D0,D2
	Move.w	#StatsCoul_RougeF,D6
	Bsr	LaunchBAR		Limite jauge GAUCHE !	

	Move.w	#StatsBaseX1,D2		X2
	Add.w	StatsMem4,D2
	Move.w	D2,D0
	Bsr	LaunchBAR		Limite jauge DROITE !	

.NoB1	
	Movem.l	D0-D1,-(A7)
	Move.w	#StatsBaseX5,D0	X4
	Bsr	LaunchTXT		(D7:Nombre)
	Movem.l	(A7)+,D0-D1

	**********************
	Move.w	#StatsBaseX1,D0		X1
	Move.l	(A2)+,D7
	Move.l	(A1)+,D2		GamesWon
	Beq.s	.NoB2
	
	Add.w	D0,D2		X2
	Move.w	#StatsCoul_Vert,D6			C
	Bsr	LaunchBAR		BAR (D0,D1)-(D2,D3),D6
	*
	Move.w	D2,D0
	Move.w	#StatsCoul_VertF,D6
	Bsr	LaunchBAR		Limite jauge DROITE !	

	Move.w	#StatsBaseX1,D0		X1
	Move.w	D0,D2
	Move.w	#StatsCoul_VertF,D6
	Bsr	LaunchBAR		Limite jauge GAUCHE !	

.NoB2

	Movem.l	D0-D1,-(A7)	Parties gagnées
	Move.w	#StatsBaseX4,D0	X5
	Bsr	LaunchTXT
	Movem.l	(A7)+,D0-D1

	Movem.l	D0-D1,-(A7)	Parties jouées (après les BAR !!!)
	Move.l	StatsMem3,D7
	Move.w	#StatsBaseX1,D0
	Bsr	LaunchTXT
	Movem.l	(A7)+,D0-D1

	**********************
	Move.w	#StatsBaseX2,D0	Bombs		X1
	Move.w	#StatsBaseX2+StatsSizeBombs,D2
	Move.w	#StatsCoul_Gris,D6			C
	Bsr	LaunchBAROmbre

	Move.l	(A2)+,D7
	Move.l	(A1)+,D2		Bombs
	Beq.s	.NoB3
	Add.w	D0,D2				X2
	Move.w	#StatsCoul_Rouge,D6			C
	Bsr	LaunchBAR		BAR (D0,D1)-(D2,D3),D6
	*
	Move.w	D2,D0
	*Subq.w	#1,D0
	Move.w	#StatsCoul_RougeF,D6
	Bsr	LaunchBAR		Limite jauge !	

	Movem.l	D0-D1,-(A7)
	Move.w	#StatsBaseX2,D0
	Bsr	LaunchTXT
	Movem.l	(A7)+,D0-D1
.NoB3
	**********************
	Move.w	#StatsBaseX3,D0	Bonus		X1
	Move.w	#StatsBaseX3+StatsSizeBonus,D2
	Move.w	#StatsCoul_Gris,D6			C
	Bsr	LaunchBAROmbre

	Move.w	#StatsBaseX3,D0			X1
	Move.l	(A2)+,D7
	Move.l	(A1)+,D2		Bonus
	Beq.s	.NoB4
	Add.w	D0,D2				X2
	Move.w	#StatsCoul_Rouge,D6			C
	Bsr	LaunchBAR		BAR (D0,D1)-(D2,D3),D6
	*
	Move.w	D2,D0
	*Subq.w	#1,D0
	Move.w	#StatsCoul_RougeF,D6
	Bsr	LaunchBAR		Limite jauge !	

	Movem.l	D0-D1,-(A7)
	Move.w	#StatsBaseX3,D0
	Bsr	LaunchTXT
	Movem.l	(A7)+,D0-D1
.NoB4
	**********************
.NoStatsForHim
	Add.w	#StatsPasY,StatsYBase	Next Y
	Dbf	D5,.LoopJT

	*Bsr	CopyHeads


	RTS

*********	
*
* BAR (D0,D1)-(D2,D3),D6
*
*
LaunchBAR	Move.l	#SizePlan,VarSizePlan
	Move.l	#SizeLine,VarSizeLine
	Movem.l	D0-D7/A0-A6,-(A7)
	Moveq	#7,D7		BAR NORMAL
	Movea.l	Planar,A2
	Jsr	BAR
	Movem.l	(A7)+,D0-D7/A0-A6
	RTS

LaunchBAROmbre
	Move.l	#SizePlan,VarSizePlan
	Move.l	#SizeLine,VarSizeLine

	Movem.l	D0-D7/A0-A6,-(A7)

	Movem.l	D0-D4/D6,StatsMem2	Max 16 .L
	Move.w	#StatsCoul_GrisF,D6
	Moveq	#0,D4
	Moveq	#7,D7		BOX pour l'ombre
	Movea.l	Planar,A2
	Addq.w	#1,D0
	Addq.w	#1,D1
	Addq.w	#1,D2
	Addq.w	#1,D3
	Bsr	BAR_OUTLINE

	Movem.l	StatsMem2,D0-D4/D6
	Moveq	#7,D7		BAR NORMALE
	Movea.l	Planar,A2
	Jsr	BAR
	
	Movem.l	(A7)+,D0-D7/A0-A6
	RTS

* D0: Position X (pixels)
* D1: Position Y (pixels)

*********	
*
* D7: Valeur à afficher 
*
*
LaunchTXT	Movem.l	D2-D7/A1-A3,-(A7)
	Add.w	#2,D0	Pour pas collé à gauche de la jauge
	Lea	StrWork,A3	PREPARATION
	Move.l	D7,D3
	Moveq	#6,D6	N chiffres
	Move.b	#0,D7
	Jsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
	Bsr	BCopPh	* Utilise D2/A2/A3
	Clr.b	(A3)
	Move.l	#StrWork,StatsMem1
	Movem.l	(A7)+,D2-D7/A1-A3
	Bsr	LaunchGene
	RTS

*******
*
* D0: X
* D1: Y
* A1: Adresse phrase
*
LaunchGene
	*RTS
	Movem.l	D0-D7/A0-A6,-(A7)
	Move.l	StatsMem1,A1
	Move.l	#SizePlan,VarSizePlan
	Move.l	#SizeLine,VarSizeLine
	Movea.l	FTinyTxt8,A0	PRINT
	Movea.l	Planar,A2
	Moveq	#7,D7
	Addq.w	#1,D0
	Addq.w	#2,D1
	Movem.l	D0-D2/D7/A0-A2,-(A7)
	Move.w	#StatsCoul_GrisF,D2
	Jsr	GPrint
	Movem.l	(A7)+,D0-D2/D7/A0-A2
	Subq.w	#1,D0
	Subq.w	#1,D1
	Move.w	#StatsCoul_Blanc,D2
	Jsr	GPrint
	Movem.l	(A7)+,D0-D7/A0-A6
	RTS

	

******************** Copier les 6 têtes des joueurs à gauche
*
* Technique non optimizée, mais pas besoin de plus.
*
*
*
CopyHeads
	Movea.l	Planar,A2
	Adda.w	#4+(StatsY-3)*SizeLine,A2	Adresse cible

	Movea.l	StatsBlocs,A0	SizePlanStatsBlocs Masque+7 plans
	
	* Chaque ligne fait 24 pixels
	
	Move.w	#95-1,D2		Hauteur
.LoopY	Move.l	(A0),D0	Masque:          %00001100 objet en 1
	Clr.b	D0
	Not.l	D0	Masque inversé:  %11110011
	Movea.l	A0,A1	Back Source
	Movea.l	A2,A3	Back Planar
	Moveq	#7,D1	Plans
.LoopPl	Adda.w	#SizePlanStatsBlocs,A1
	Move.l	(A3),D4	Plan actuel
	And.l	D0,D4
	Move.l	(A1),D5
	Clr.b	D5
	Or.l	D5,D4
	Move.l	D4,(A3)	
	Adda.w	#SizePlan,A3
	Dbf	D1,.LoopPl	
	Adda.w	#3,A0		Prochaines lignes source
	Adda.w	#SizeLine,A2	et cible
	Dbf	D2,.LoopY
	RTS

******************** Copier une tête des joueurs à gauche
*
* D0: X sur l'écran (en octets)
* D1: Y sur l'écran
* D2: N° de la tête (0-5)
*
CopyOneHead
	Movem.l	D4-D5/A0-A4,-(A7)
	Movea.l	Planar,A2
	Subq.w	#2,D1		Centrage "à la main"
	Mulu.w	#SizeLine,D1
	Adda.w	D1,A2
	Adda.w	D0,A2			Adresse cible
	Movea.l	StatsBlocs,A0	SizePlanStatsBlocs Masque+7 plans
	Mulu.w	#3*16,D2
	Lea	(A0,D2.w),A0	Tête source
	Move.w	#15-1,D2		Hauteur
.LoopY	Move.l	(A0),D0	Masque:          %00001100 objet en 1
	Clr.b	D0
	Not.l	D0	Masque inversé:  %11110011
	Movea.l	A0,A1	Back Source
	Movea.l	A2,A3	Back Planar
	Moveq	#7,D1	Plans
.LoopPl	Adda.w	#SizePlanStatsBlocs,A1
	Move.l	(A3),D4	Plan actuel
	And.l	D0,D4
	Move.l	(A1),D5
	Clr.b	D5
	Or.l	D5,D4
	Move.l	D4,(A3)	
	Adda.w	#SizePlan,A3
	Dbf	D1,.LoopPl	
	Adda.w	#3,A0		Prochaines lignes source
	Adda.w	#SizeLine,A2	et cible
	Dbf	D2,.LoopY
	Movem.l	(A7)+,D4-D5/A0-A4
	RTS



