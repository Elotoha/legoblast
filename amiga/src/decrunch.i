
*******************************************************************
* Compression/Decompression de données by Gogo, finit le 05/01/98 *
*******************************************************************
*
* Décomptacteur des fichiers compressés à la HuffMan non dynamique.
*
* A0: Séquence de bits à décruncher
* A1: Zone de mémoire pour le fichier décompacté.
* D6: Taille attendue du fichier décompacté en octets
*	TOUT ce qui a trait à D6 dans ce programme n'est là que pour
*	servir d'anti-bug. Pour ne pas dépasser la taille allouée 
*	pour le décompactage.
*
* Retour D6=0: OK    Sinon D6>0: Nombre d'octets manquants au fichier final.
*
MaNbBit	=	10	ANTIBUG

DECRUNCH
	Lea	BitList,A2	
	*** SOURCE
	Clr.l	D2	Nombre de 1

	*** CIBLE
	Clr.l	D3	Chaine de sortie
	Move.l	#32,D4	Pointeur de sortie
	Clr.l	D5	Juste pour clearer une fois en .L
	Bra.s	.LoopBytes

.No4	Addq.l	#1,D6		3
	Blt.s	.No3
	Sub.w	#8,D4
	Lsl.l	D4,D3

	Ror.l	#8,D3
	Move.w	D3,(A1)+
	Rol.l	#8,D3
	Move.b	D3,(A1)+
	Bra.s	.End
	
.No3	Addq.l	#1,D6		2
	Blt.s	.No2
	Sub.w	#16,D4
	Lsl.l	D4,D3
	Move.w	D3,(A1)+
	Bra.s	.End
	
.No2	Addq.l	#1,D6		1
	Blt.s	.End
	Sub.w	#24,D4
	Lsl.l	D4,D3
	Move.b	D3,(A1)+	
	Bra.s	.End

.LoopBytes
	Move.l	(A0)+,D0	Lecture
	Moveq	#32,D1	Nb bits
.LoopAct	Add.l	D0,D0
	Bcc.s	.EndCod
	Addq.w	#4,D2
.Cont	*Dbf	D1,.LoopAct
	Subq.w	#1,D1
	Bgt.s	.LoopAct
	Bra.s	.LoopBytes
.EndPr	Cmp.w	#32,D4
	Beq.s	.End	
	Subq.l	#4,D6
	Blt.s	.No4
	Lsl.l	D4,D3
	Move.l	D3,(A1)+
.End	RTS	

.EndCod	* Trouver la suite de bits à copier en fonction du nombre de 1
	Cmp.w	#MaNbBit*4,D2
	Bgt.s	.EndPr		BUG! (ou fin si pas prévu)
	Lea	(A2,D2.w),A3
	Clr.l	D2
	Move.w	2(A3),D5		Nombre de N à produire
	Blt.s	.EndPr
	Tst.w	(A3)
	Bne.s	.Un	
.Zero	*********************
	Sub.w	D5,D4		32-7=25
	Ble.s	.DepassZ
	Lsl.l	D5,D3		0 qui ne dépasse pas	
	Bra.s	.Cont
.DepassZ	* Dépassement avec ZERO
	Add.w	D5,D4
	Lsl.l	D4,D3
	Subq.l	#4,D6
	Blt.s	.End
	Move.l	D3,(A1)+	On fait autant de .L que nécessaire
	Clr.l	D3	Chaine de sortie	
	Sub.w	D4,D5	Tant que c'est >=0, on continue
.FillZ	Sub.w	#32,D5
	Ble.s	.EndFillZ
	Subq.l	#4,D6
	Blt.s	.End
	Clr.l	(A1)+
	Bra.s	.FillZ
.EndFillZ	* D5: Nombre de bits à remplir encore	(D5>=0)
	Add.w	#32,D5
	Move.w	#32,D4	Pointeur de sortie
	Sub.w	D5,D4
	Bra.s	.Cont
.Un	*********************
	Sub.w	D5,D4		32-7=25
	Ble.s	.DepassU	
	* Cela ne dépasse pas du .L actuel: on peut mettre les 1
	Lsl.l	D5,D3		1 qui ne dépasse pas
	Moveq	#-1,D7		On produit des "1"
	Lsl.l	D5,D7
	Not.l	D7
	Or.l	D7,D3		On les insère	
	Bra.s	.Cont
.DepassU	* Dépassement avec UN
	Add.w	D5,D4
	Lsl.l	D4,D3
	Moveq	#-1,D7		On remplit le reste du .L en "1"
	Lsl.l	D4,D7
	Not.l	D7
	Or.l	D7,D3		
	Subq.l	#4,D6
	Blt.s	.End
	Move.l	D3,(A1)+	* On fait autant de .L que nécessaire
	Moveq	#-1,D3
	Sub.w	D4,D5	Tant que c'est >=0, on continue
.FillU	Sub.w	#32,D5
	Ble.s	.EndFillU
	Subq.l	#4,D6
	Blt.s	.End
	Move.l	D3,(A1)+
	Bra.s	.FillU
.EndFillU	* D5=Nombre de bits à remplir encore	(D5>=0)
	Add.w	#32,D5
	Move.w	#32,D4	Pointeur de sortie
	Sub.w	D5,D4
	Lsl.l	D5,D3
	Not.l	D3
	Bra	.Cont
	*********************

BitList	Dc.w	%0,1		0			0
	Dc.w	%1,3		10			+1
	Dc.w	%1,1		110			-2
	Dc.w	%1,5		1110			+1
	Dc.w	%1,2		11110	4		-4
	Dc.w	%0,32		111110	5		
	Dc.w	%1,256		1111110	6
	Dc.w	%0,256		11111110	7
	Dc.w	%1,4096		111111110		8
	Dc.w	%0,4096		1111111110	9
	Dc.w	0,-1		11111111110 = Fin MaNbBit
	******************
ORIGINAL_SIZE Dc.l	0
DECRUNCHED_SIZE Dc.l 0
	even
	