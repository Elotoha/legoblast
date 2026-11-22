IntRoutine3 *** SONS CHANNEL 3	
	Tst.w	OkSon3		Départ de son au lieu de fin ?
	Bne.s	.Ok
	Subq.w	#1,Son3Loops	Son pas terminé: en boucle
	Bge.s	.Ok
	Move.w	#0,Aud3Dat
	Move.w	#1<<3,DmaCon	Channel 3 Off	
	Moveq	#3,D0
	Bsr	RasterWaitH	
	Move.w	#0,ChannelUse3
	Move.w	#1<<10,IntEna	Off Son 3 (-> Interrupt départ son!)
.Ok	Clr.w	OkSon3
	Move.w	#1<<10,IntReq	Aud3 à 0
	RTS

IntRoutine4 *** SONS CHANNEL 2
	Tst.w	OkSon2
	Bne.s	.Ok
	Subq.w	#1,Son2Loops	Son pas terminé: en boucle
	Bge.s	.Ok
	Move.w	#0,Aud2Dat
	Move.w	#1<<2,DmaCon	Channel 2 Off	
	Moveq	#3,D0
	Bsr	RasterWaitH	
	Move.w	#0,ChannelUse2
	Move.w	#1<<9,IntEna	Off Son 2 (-> Interrupt départ son!)
.Ok	Clr.w	OkSon2
	Move.w	#1<<9,IntReq	Aud2 à 0
	RTS

IntRoutine5 *** SONS CHANNEL 1
	Tst.w	OkSon1
	Bne.s	.Ok
	Subq.w	#1,Son1Loops	Son pas terminé: en boucle
	Bge.s	.Ok
	Move.w	#0,Aud1Dat
	Move.w	#1<<1,DmaCon	Channel 1 Off	
	Moveq	#3,D0
	Bsr	RasterWaitH	
	Move.w	#0,ChannelUse1
	Move.w	#1<<8,IntEna	Off Son 1 (-> Interrupt départ son!)
.Ok	Clr.w	OkSon1
	Move.w	#1<<8,IntReq	Aud1 à 0
	RTS

IntRoutine6 *** SONS CHANNEL 0
	Tst.w	OkSon0
	Bne.s	.Ok
	Subq.w	#1,Son0Loops	Son pas terminé: en boucle
	Bge.s	.Ok
	Move.w	#0,Aud0Dat
	Move.w	#1,DmaCon		Channel 0 Off	
	Moveq	#6,D0
	Bsr	RasterWaitH	
	Move.w	#0,ChannelUse0
	Move.w	#1<<7,IntEna	Off Son 0 (-> Interrupt départ son!)
.Ok	Clr.w	OkSon0
	Move.w	#1<<7,IntReq	Aud0 à 0
	RTS

IntRoutine7 *** COPPER (SOFT)

*	Move.w	#$0FF,$dff180

	RTS

