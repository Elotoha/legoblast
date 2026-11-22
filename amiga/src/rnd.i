*
* Routine de RND - By Gogo
*
*    D0: Valeur du RND précédent
* -> D0: Valeur du RND trouvé
*
*    D1: Pas touche
*
Rnd_Engine
*	Move.l	MemRnd1,D0
*	Move.w	MemRnd2,D1
	Ror.l	D1,D0	Comme ça le poids faible important est en rnd
	Add.l	#49877,D0	Nb premier !
	Muls.l	#271,D0	Nb premier <- si on vire ca: mauvais rnd !
	Sub.b	D0,D1
*	Move.l	D0,MemRnd1
*	Move.w	D1,MemRnd2
	RTS


*
*      -> D0: Valeur du RND trouvé
* 
*
Rnd_Go
	Move.l	D1,-(A7)
	Move.l	MemRnd1,D0
	Move.l	MemRnd2,D1
	Bsr	Rnd_Engine
	Move.l	D0,MemRnd1
	Move.l	D1,MemRnd2
	Move.l	(A7)+,D1
	RTS
	
*
*	D1: % sur 65535 d'avoir TRUE
*	Exemple: 40000 donne 2/3 de chances d'avoir true
*
*      -> D0: 0=FALSE   Autre=TRUE
* 
*
Rnd_Bool
	Bsr	Rnd_Go
	And.l	#$FFFF,D0
	Move.l	D0,Temp1
	Cmp.l	D0,D1
	Blt.s	.Nop	
	Clr.l	D0
.Nop	RTS



*
* Prend la VBL pour faire n'importe quoi !
*
Rnd_Init
	Move.l	VPosR,D0
	Add.l	D0,MemRnd1
	Move.l	MemRnd2,D1
	Eor.l	D1,D0
	Move.l	D0,MemRnd2	
	RTS	