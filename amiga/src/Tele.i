

***************	Gestion de l'animation des téléporteurs ! ;-)
*
* AVANT: (l'intervention de Cobalt...), c'était trop simple
* 1/ On affiche la case 16x16 dans le font
* 2/ On retrace le visible correspondant
*
* MAINTENANT:
* 1/ On affiche la case 16x16 dans le font avec masque du bloc de font
* 2/ On retrace le visible correspondant.
*

GestionTele
	Movea.l	TelePtr,A0
	Move.w	LastNTele,D0
	Beq.s	.NoTele
	Subq.w	#1,D0	
.Loop	Move.w	Tele_X(A0),D6
	Move.w	Tele_Y(A0),D7
	Move.w	Tele_ImA(A0),D5
	Cmp.w	#ImFinBlocTele,D5
	Blt.s	.Nop
	Move.w	#ImDebBlocTele-1,D5	
.Nop	Addq.w	#1,D5
	Move.w	D5,Tele_ImA(A0)		Bloc téléporteur actuel
	Move.w	D6,D3
	Move.w	D7,D4
	Move.w	D6,-(A7)
	Movea.l	LevelAct,A2
	Move.w	Level_Bloc(A2),D6		Bloc font niveau
	Movea.l	FontPtr,A2

*	Bsr	TraceBloc		(D3,D4),D5,A2

	Bsr	TraceBlocWithBloc

	Move.w	(A7)+,D6
	Bsr	Affiche		(D6,D7)
	Adda.w	#Tele_SizeOf,A0
	Dbf	D0,.Loop
.NoTele	RTS

