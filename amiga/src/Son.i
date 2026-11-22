

	************* Jouer un son sur n'importe quelle piste
	*
	* D3: N° du Sample
	* D1: Priorité du son à jouer
	*
***********
*>1/ On regarde si le canal utilisé pour le meme son avant est utilisable (quitte à détruire un son en cours)
* 2/ On cherche un canal de même priorité pour ne pas saturer les 4 voies
* 3/ On cherche un canal libre
* 4/ On lance la recherche bourrin : toute priorité inférieure est écrasée.
*
*
PlaySon
	Movem.l	D0-D7/A0-A6,-(A7)
	*Movem.l	D0-D1/D2/D3,-(A7)

	Lea	SonIdx,A0
	Move.l	(A0,D0.w*4),A0	Adresse son	
	Cmp.l	#SVide,A0
	Beq	.ErrSon

	* RECHERCHE 2 : Canal en utilisation et de même priorité 
	Tst.w	ChannelUse3
	Beq.s	.NoSam3	
	Cmp.w	ChannelPri3,D1
	Bne.s	.NoSam3
	Move.l	D3,D0
	Bsr	PlaySon3
	Beq	.PlayOk
.NoSam3	Tst.w	ChannelUse2
	Beq.s	.NoSam2	
	Cmp.w	ChannelPri2,D1
	Bne.s	.NoSam2
	Move.l	D3,D0
	Bsr	PlaySon2
	Beq	.PlayOk
.NoSam2	Tst.w	ChannelUse1
	Beq.s	.NoSam1	
	Cmp.w	ChannelPri1,D1
	Bne.s	.NoSam1
	Move.l	D3,D0
	Bsr	PlaySon1
	Beq	.PlayOk
.NoSam1	Tst.w	ChannelUse0
	Beq.s	.NoSam0
	Cmp.w	ChannelPri0,D1
	Bne.s	.NoSam0
	Move.l	D3,D0
	Bsr	PlaySon0
	Beq.s	.PlayOk
.NoSam0
	* RECHERCHE 3: Canal libre
	Tst.w	ChannelUse3
	Bne.s	.Use3
	Move.l	D3,D0
	Bsr	PlaySon3
	Beq.s	.PlayOk
.Use3	Tst.w	ChannelUse2
	Bne.s	.Use2
	Move.l	D3,D0
	Bsr	PlaySon2
	Beq.s	.PlayOk
.Use2	Tst.w	ChannelUse1
	Bne.s	.Use1
	Move.l	D3,D0
	Bsr	PlaySon1
	Beq.s	.PlayOk
.Use1	Tst.w	ChannelUse0
	Bne.s	.Use0
	Move.l	D3,D0
	Bsr	PlaySon0
	Beq.s	.PlayOk
.Use0
	* RECHERCHE 4 : On essaye tous les canaux pour écraser un son
	Move.l	D3,D0
	Bsr	PlaySon0	
	Beq.s	.PlayOk
	Move.l	D3,D0
	Bsr	PlaySon1	
	Beq.s	.PlayOk
	Move.l	D3,D0
	Bsr	PlaySon2	
	Beq.s	.PlayOk
	Move.l	D3,D0
	Bsr	PlaySon3
.PlayOk	*Movem.l	(A7)+,D0-D1/D2/D3
.ErrSon	Movem.l	(A7)+,D0-D7/A0-A6
	RTS


	************* Jouer un son sur la piste 3 (Avec sémaphore)
	*
	*
	* D0: N° Du sample
	* D1: Priorité du son à jouer
	* -> D2=0:Ok    D2=-1:Erreur
	*
PlaySon3	Moveq	#-1,D2
	Tst.w	Voice3Free	Voie utilisée par la musique ?
	Beq	.Nop
	Bset	#0,ChannelUse3+1
	Beq.s	.Ok
	Cmp.w	ChannelPri3,D1
	Blt	.Nop	
.Ok	Move.w	#0,Son3Loops
	Clr.l	D2
	Move.l	A0,-(A7)
	Lea	SonIdx,A0
	Move.l	(A0,D0.w*4),A0	Adresse son	
	Move.w	#0,OkSon3
	Move.w	#$C000+1<<10,IntEna
	Adda.w	#4,A0

*	Move.w	(A0)+,Aud3Len
*	Move.w	(A0)+,Aud3Per
	Move.l	A0,Aud3LCh	Lch
	Move.w	-4(A0),Aud3Len	Len
	Move.w	-2(A0),Aud3Per	Per

	Move.w	SoundVol,Aud3Vol	Vol
	Move.w	D1,ChannelPri3
	Move.w	#1<<3,DmaCon	DMA Audio 3 Off 
	Moveq	#3,D0
	Bsr	RasterWaitH	
	Move.w	#1,OkSon3
	Move.w	#1,ChannelUse3
	Move.w	SampleLoops,Son3Loops
	Move.w	#$C000+1<<10,IntEna
	Move.w	#$8000+1<<3,DmaCon	Audio 3 On
	Move.l	(A7)+,A0
.Nop	Tst.l	D2
	RTS

	************* Jouer un son sur la piste 2 (Avec sémaphore)
	*
	*
	* D0: N° Du sample
	* D1: Priorité du son à jouer
	*
PlaySon2	Moveq	#-1,D2
	Tst.w	Voice2Free	Voie utilisée par la musique ?
	Beq	.Nop
	Bset	#0,ChannelUse2+1
	Beq.s	.Ok
	Cmp.w	ChannelPri2,D1
	Blt	.Nop	
.Ok	Move.w	#0,Son2Loops	
	Clr.l	D2
	Move.l	A0,-(A7)
	Lea	SonIdx,A0
	Move.l	(A0,D0.w*4),A0	Adresse son	
	Move.w	#0,OkSon2
	Move.w	#$C000+1<<9,IntEna
	Adda.w	#4,A0
*	Move.w	(A0)+,Aud2Len
*	Move.w	(A0)+,Aud2Per
	Move.l	A0,Aud2LCh	Lch
	Move.w	-4(A0),Aud2Len	Len
	Move.w	SoundVol,Aud2Vol	Vol
	Move.w	-2(A0),Aud2Per	Per
	Move.w	D1,ChannelPri2
	Move.w	#1<<2,DmaCon	DMA Audio 2 Off 
	Moveq	#3,D0
	Bsr	RasterWaitH	
	Move.w	#1,OkSon2
	Move.w	SampleLoops,Son2Loops		
	Move.w	#1,ChannelUse2
	Move.w	#$C000+1<<9,IntEna
	Move.w	#$8000+1<<2,DmaCon	Audio 2 On
	Move.l	(A7)+,A0
.Nop	Tst.l	D2
	RTS


	************* Jouer un son sur la piste 1 (Avec sémaphore)
	*
	*
	* D0: N° Du sample
	* D1: Priorité du son à jouer
	*
PlaySon1	Moveq	#-1,D2
	Tst.w	Voice1Free	Voie utilisée par la musique ?
	Beq	.Nop
	Bset	#0,ChannelUse1+1
	Beq.s	.Ok
	Cmp.w	ChannelPri1,D1
	Blt	.Nop	
.Ok	Move.w	#0,Son1Loops
	Clr.l	D2
	Move.l	A0,-(A7)
	Lea	SonIdx,A0
	Move.l	(A0,D0.w*4),A0	Adresse son	
	Move.w	#0,OkSon1
	Move.w	#$C000+1<<8,IntEna
	Adda.w	#4,A0
*	Move.w	(A0)+,Aud1Len
*	Move.w	(A0)+,Aud1Per
	Move.l	A0,Aud1LCh	Lch
	Move.w	-4(A0),Aud1Len	Len
	Move.w	SoundVol,Aud1Vol	Vol
	Move.w	-2(A0),Aud1Per	Per
	Move.w	D1,ChannelPri1
	Move.w	#1<<1,DmaCon	DMA Audio 1 Off 
	Moveq	#3,D0
	Bsr	RasterWaitH	
	Move.w	#1,OkSon1
	Move.w	SampleLoops,Son1Loops	
	Move.w	#1,ChannelUse1
	Move.w	#$C000+1<<8,IntEna
	Move.w	#$8000+1<<1,DmaCon	Audio 1 On
	Move.l	(A7)+,A0
.Nop	Tst.l	D2
	RTS


	************* Jouer un son sur la piste 0 (Avec sémaphore)
	*
	*
	* D0: N° Du sample
	* D1: Priorité du son à jouer
	*
PlaySon0	Moveq	#-1,D2
	Tst.w	Voice0Free	Voie utilisée par la musique ?
	Beq	.Nop
	Bset	#0,ChannelUse0+1
	Beq.s	.Ok
	Cmp.w	ChannelPri0,D1
	Blt	.Nop	
.Ok	Move.w	#0,Son0Loops
	Clr.l	D2
	Move.l	A0,-(A7)
	Lea	SonIdx,A0
	Move.l	(A0,D0.w*4),A0	Adresse son	
	Move.w	#0,OkSon0
	Move.w	#$C000+1<<7,IntEna
	Adda.w	#4,A0
*	Move.w	(A0)+,Aud0Len
*	Move.w	(A0)+,Aud0Per
	Move.l	A0,Aud0LCh	Lch
	Move.w	-4(A0),Aud0Len	Len
	Move.w	SoundVol,Aud0Vol	Vol
	Move.w	-2(A0),Aud0Per	Per
	Move.w	D1,ChannelPri0
	Move.w	#1,DmaCon		DMA Audio 0 Off 
	Moveq	#3,D0
	Bsr	RasterWaitH	
	Move.w	#1,OkSon0
	Move.w	SampleLoops,Son0Loops
	Move.w	#1,ChannelUse0
	Move.w	#$C000+1<<7,IntEna
	Move.w	#$8000+1,DmaCon	Audio 0 On
	Move.l	(A7)+,A0
.Nop	Tst.l	D2
	RTS

*********************
* Routine piquée dans Hired Guns

RasterWaitH	MOVEM.L   	D1-D2,-(SP)
		Lea	$dff000,a6
L11FC		MOVE.B    	$6(A6),D1		Position Horizontale
L1200		MOVE.B    	$6(A6),D2
		CMP.B		D1,D2		Synchro Vbl H
		BEQ.S		L1200		Boucle compteur
		DBRA 		D0,L11FC
		MOVEM.L   	(SP)+,D1-D2
		RTS
*********************


