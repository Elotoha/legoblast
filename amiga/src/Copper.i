***************************

SetCopList
	Bsr	Set1
*	Bsr	Set5
	Bsr	Set2
	Bsr	Set3
	Move.l	CopList1,Cop1Lch
	Clr.w	CopJmp1

	RTS


Set1	* Sprites et écran 320*256*128
	Move.w	#$7FFF,DMACon
	Move.w	#0,BplCon0
	Clr.l	Rien
	Move.l	CopList1,A0	************** DEBUT COPPERLISTE
	CopMove	#%01,#$1FC		FMode %10 ou %01 pour Hires 6 plans
	Move.l	A0,CopAdrSprite0
	CopSprite	#rien,0
	Move.l	A0,CopAdrSprite1
	CopSprite	#Rien,1
	Move.l	A0,CopAdrSprite2
	CopSprite	#rien,2	
	Move.l	A0,CopAdrSprite3
	CopSprite #rien,3
	Move.l	A0,CopAdrSprite4
	CopSprite	#rien,4	
	Move.l	A0,CopAdrSprite5
	CopSprite #rien,5
	Move.l	A0,CopAdrSprite6
	CopSprite	#rien,6	
	Move.l	A0,CopAdrSprite7
	CopSprite #rien,7
	Move.l	A0,CopPlanAdr
	CopPlan	Planar,#SizePlan,#NbPlans+1	7 plans... ehb ???
	CopMove	#$2c81-$100*YOFFNEG,#$8E	DiwStrt	$2c81
	CopMove	#$2bc1,#$90		DiwStop	$2bc1
	CopMove	#$38,#$92			ddfstrt	$38
	CopMove	#$d0-8,#$94		ddfstop	$d0
	RTS

Set2	*  Attente de la position de l'info bar
	Move.l	A0,CopAdrBplCon0
*	CopMove	#%0110001000000001,#$100	BplCon0: 6 plans (lowres)
	CopMove	#%0111001000000001,#$100	BplCon0: 7 plans (lowres)
	CopMove	#$8100,#$96	DmaCon Bpls ON
	Move.l	A0,CopEndPtr	***********
	
*	Bsr	Set5
	
	CopWaitXY	#440,#255		#448
	CopWait	#28-YOFFNEG
	CopMove	#$100,#$96	DmaCon Bpls OFF
	Move.l	A0,CopBarrePtr
	RTS

Set3	* Barre des joueurs en pierre (640*18*6)
	Move.l	CopBarrePtr,A0
	*** Début
	CopMove	#$3081-$60,#$8E		Diw/CopEnd
	CopMove	#$30c1,#$92
	CopMove	#$3c-$8,#$92			DDf
	CopMove	#$3c+(640/4-8)-$8,#$94
	*Move.l	A0,Mem1
	*CopPlan	BarrePtr,#SizePlanBarre,#NbPlansBarre
	CopPlan	BarrePtr,#SizePlanBarre,#NbPlansBarre	
	CopWait	#30-YOFFNEG
	CopMove	#$8100,#$96	DmaCon	ON
	CopMove	#%1110001000000001,#$100	BplCon0: Hi-Res
	CopWait	#30+18-YOFFNEG
	CopMove	#$100,#$96	DmaCon	OFF	
	CopEnd
	RTS
	
Set4	* Barre d'informations en bois (320*18*6)
	Move.l	CopBarrePtr,A0
	CopPlan	Barre2,#SizePlanBarre2,#NbPlansBarre2
	CopWait	#30-YOFFNEG
	CopMove	#$8100,#$96	DmaCon	ON
	CopMove	#%0110001000000001,#$100	BplCon0: Lo-Res
	CopWait	#30+18-YOFFNEG
	CopMove	#$100,#$96	DmaCon	OFF		
	CopEnd
	*Move.l	CopList1,Cop1Lch
	*Clr.w	CopJmp1
	RTS
	
Set5	RTS
	* Attente de la position de la barre de chargement
	* YJaugeSamples,HautJaugeSamples
	CopWaitXY	#440,#YJaugeSamples		#448
	Movem.l	D0-D2,-(A7)
	Move.w	#Jauge_Rouge,D2
	Lsl.l	#2,D2
	Add.w	#$180,D2
	Move.w	#YJaugeSamples-1,D0
	Move.w	#$F00,D1
.Loop	CopWait	D0
	CopMove	D1,D2
	Subq.w	#1,D1
	Addq.w	#1,D0
	Cmp.w	#YJaugeSamples+HautJaugeSamples,D0
	Blt.s	.Loop	
	Movem.l	(A7)+,D0-D2
	RTS


SetVierge
	Move.l	CopList1,A0	************** DEBUT COPPERLISTE
	CopMove	#$0100,#$096	Bpl off
	CopMove	#0,#$180
	CopEnd	
	Move.l	CopList1,Cop1Lch
	Clr.w	CopJmp1
	RTS

SetSimple
	Move.l	CopList1,A0	************** DEBUT COPPERLISTE
	*CopInitSprites
	CopMove	#$8100,#$96		Bitplans on
	CopMove	#$0020,#$96		Sprites OFF
	CopMove	#%0111001000000001,#$100	BplCon0
	CopPlan	Planar,#SizePlan,#NbPlans+1	7 plans...
	CopMove	#%01,#$1FC		FMode %10 ou %01 pour Hires 6 plans
	CopMove	#$2c81-$100*YOFFNEG,#$8E	DiwStrt	$2c81
	CopMove	#$2bc1,#$90		DiwStop	$2bc1
	CopMove	#$38,#$92			ddfstrt	$38
	CopMove	#$d0-8,#$94		ddfstop	$d0
*	Bsr	set5
	CopWaitXY	#440,#255			#448
	CopWait	#28-YOFFNEG
	CopMove	#%0000001000000001,#$100	BplCon0: Hi-Res
	CopMove	#$0100,#$96		Bitplans OFF
	CopEnd
	*VblWait	#30
	Move.l	CopList1,Cop1Lch
	Clr.w	CopJmp1
	RTS


SetScreenRegisters
*	Move.w	#$3081,DiwStrt	Machins a thunder
*	Move.w	#$30c1,DiwStop
*	Move.w	#$3c,ddfstrt
*	Move.w	#$3c+(320/4-8),ddfstop	
	
*	Move.w	#$2C81-$100*YOFFNEG,DiwStrt	YX   	$8E	
*	Move.w	#$2BC1+$500+$1,DiwStop			$90
*	Move.w	#$38,DDFStrt	=>Display Data Fetch Start (start et stop pour une seule ligne)
*	Move.w	#$D0+$1,DDFStop	=>Display Data Fetch Stop	
	Move.w	#%0110001000000000,BplCon0	hires,nb bitplans,64c,dual,couleur,genlock,0000,lpen,lace,synchro ext,0
	Move.w	#%0000000000000000,BplCon1	ScrollBitplan=0
	Move.w	#%0000001000111111,BplCon2	Kill EHB+ Priorités Sprites
	Move.w	#%0000110000000010,BplCon3		%10
	Move.w	#%0000000001010101,BplCon4	Palette sprites (Pair,Impair)
*	Move.w	#0,Bpl1Mod
*	Move.w	#0,Bpl2Mod
	
	*Bsr	ClearSprites
	*VblWait	#20
	DMASet	BitPlan|Copper|Sprite
	Move.w	#$C000+1<<5+1<<3,IntEna	Interruption Vbl+Clav $8020+Son 3
	Move.w	#$F000,ClxCon		Contrôle collisions sprites
	*Move.w	#%00,FMode
	Move.w	#$00FF,AdkCon

	
*	Move.w	#$8000+1<<3,DmaCon
*	Move.w	#0,IntReq
*	Move.b	#%00010111,$bfed01
*	Move.b	#%10001000,$bfed01
	RTS


