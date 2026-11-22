*
* Charger chaque son après avoir réservé
* la taille en mémoire
*
*
*
LoadSamples

	Movem.l	D0-D7/A0-A6,-(A7)

	Bsr	TEMP_RESTORE_SYSTEM

	Clr.w	SamplesLoaded
	Clr.w	SamplesTotal

*	Lea	SonIdx,A0
*	Move.l	#SVide,D1
*	Moveq	#MaxSamples-1,D0
*.InitSmp	Move.l	D1,(A0)+
*	Dbf	D0,.InitSmp

	Lea	FichSamplesDef,A0	Charge fichier samples.def
	Move.l	#Public,D1
	Jsr	ChargeFichier	A0/D1->A1/D0: Comme chargefichier
	Tst.l	D0
	Ble	.Err
	Move.l	A1,FichAdr
	Move.l	D0,FichSiz
	** On a le fichier de définition des samples en mémoire:
	* on le scanne et on charge tous les sons correspondants.
	* Si on n'a pas pu charger tous les sons, on met le message
	* d'erreur: ERREUR: SEULS 8 SONS SUR 17 ONT PU ETRE CHARGES
	* (EN PLUS DE : Module 4 chargé)
	* Avec un scrolling: 4 lignes de message + 30 mémoires, consultables
	* avec "pause".


	* La taille du son est déjà dans la zone correspondante:
	* il ne manque plus que le nom du fichier à charger dans la zone
	* et surtout la fréquence

	* A1: Pointeur fichier

	Lea	SonIdx,A2
	Move.l	A2,SonIdxPtr
	Move.l	A1,ActPtr
.NEXTSON
	Move.l	ActPtr,A1
.chchdp	* On recherche les ":"
	Move.b	(A1)+,D1		Lecture octets fichier def
	Cmp.b	#"*",D1
	Beq	.FreeMem
	Cmp.b	#":",D1
	Bne.s	.chchdp
	
	Lea	TNomFich,A0
	Move.l	#"sons",(A0)+
	Move.b	#"/",(A0)+
	
.copvir	Move.b	(A1)+,D1
	Cmp.b	#",",D1
	Beq.s	.Endcopv
	Move.b	D1,(A0)+
	Bra.s	.copvir
.endcopv	Clr.b	(A0)+

	Clr.l	D1
	Clr.l	D3
.copnu	Move.b	(A1)+,D1
	Cmp.b	#10,D1
	Beq.s	.endcopnu
	Sub.b	#"0",D1
	Mulu.w	#10,D3
	Add.w	D1,D3
	Bra.s	.copnu
.endcopnu
	Move.l	A1,ActPtr
	* D3: Freq
	Move.w	D3,TFreq	


	*** On charge le fichier de son

	Move.l	SonIdxPtr,A3
	Move.l	(A3)+,D0
	Cmp.l	#SVide,D0		On ne remplace pas si le son
	Beq.s	.OkS2		est déjà en mémoire
	Move.l	A3,SonIdxPtr
	Bra	.NEXTSON

.OkS2	Add.w	#1,SamplesTotal
	Lea	TNomFich,A0
	Move.l	#Chip,D1
	Jsr	ChargeOneSon	A0/D1->A1/D0: Comme chargefichier
	Tst.l	D0
	Bne.s	.Oks
	Move.l	SonIdxPtr,A3
	Move.l	#SVide,(A3)+	Dans liste sonidx
	Move.l	A3,SonIdxPtr
	Bra	.NEXTSON
.oks	Move.l	SonIdxPtr,A3
	Move.l	A1,(A3)+		Dans liste sonidx
	Move.l	A3,SonIdxPtr
	Move.w	TFreq,2(A1)
	Add.w	#1,SamplesLoaded
	Add.w	#1,JaugeCpt	Jauge de chargement
	Jsr	LoadingJaugeMAJ
	Bra	.NEXTSON

.FreeMem
	Move.l	FichAdr,A1
	Move.l	FichSiz,D0
	Jsr	_LVOFreeMem(A6)	(A1/D0)


.Err

	Bsr	TEMP_TAKE_SYSTEM

*	Moveq	#1,D1
*	Move.w	SamplesTotal,Temp1+2
*	Move.w	SamplesLoaded,Temp2+2
*	Bsr	DEBUG
*	lwait

	Move.w	#-1,SamplesWait

	Movem.l	(A7)+,D0-D7/A0-A6

	RTS
	
	
************** Rendre la mémoire des sons
*
* !!!SamplesToKeep: liste des N° .W des sons à ne pas rendre
*
*
FreeSamples
	Move.w	#-1,D7	Pas de liste: on met -1 à chercher
	Move.l	SamplesToKeep,A4
	Tst.l	A4
	Beq.s	.NoR
	Move.w	(A4)+,D7		Nombre à garder
.NoR	Clr.w	SampleAct		Samples.Def: 1...N
	Lea	SonIdx,A0
	Move.l	#SVide,D1
	Move.w	#MaxSamples-1,D0
.LoopR	Move.l	(A0)+,A1
	Add.w	#1,SampleAct	N° du sample 1...N
	Cmp.l	D1,A1
	Beq.s	.NoSmp	Pas de son en mémoire à ce N°

	Cmp.w	SampleAct,D7	Son à garder ?
	Bne.s	.OkLib		Non: on libère
	* Avant de sauter ce son on cherche le prochain N°
	Move.w	(A4)+,D7		N° à garder
	Bra.s	.NoSmp

.OkLib	Movem.l	D0-D1/D7/A0-A1/A4,-(A7)
	Clr.l	D0
	Move.w	(A1),D0	*2+4
	Lsl.l	#1,D0
	Add.l	#4,D0		

	Move.l	$4.w,A6
	Jsr	_LVOFreeMem(A6)	A1/D0
	
	Movem.l	(A7)+,D0-D1/D7/A0-A1/A4
	Move.l	D1,-4(A0)	
.NoSmp
	Dbf	D0,.LoopR

	RTS







*********** Charger les deux banques de sprites en mémoire
*
*
*
LoadSpritesData
	Tst.l	AdrSprites
	Bne.s	.OkD1
	Bsr	TEMP_RESTORE_SYSTEM
	Move.l	#Spr4Name,A0
	Move.l	#Chip,D1
	Jsr	ChargeFichier	
	Bsr	TEMP_TAKE_SYSTEM
	Add.w	#3,JaugeCpt
	Jsr	LoadingJaugeMAJ
	Move.l	D0,SpritesLength
	Ble.s	.OkD2	On quitte
.OkC1	Move.l	A1,AdrSprites
.OkD1	Tst.l	AdrSprites8
	Bne.s	.OkD2
	Bsr	TEMP_RESTORE_SYSTEM
	Move.l	#Spr8Name,A0
	Move.l	#Chip,D1
	Jsr	ChargeFichier	
	Bsr	TEMP_TAKE_SYSTEM
	Add.w	#3,JaugeCpt
	Jsr	LoadingJaugeMAJ
	Move.l	D0,Sprites8Length
	Ble.s	.OkD2	On quitte
.OkC2	Move.l	A1,AdrSprites8
.OkD2	RTS



*********** Libérer les espaces mémoires réservés pour les sprites
*
*
FreeSpritesData
	Move.l	AdrSprites,A1	Adresse
	Tst.l	A1
	Beq.s	.NoF4
	Move.l	SpritesLength,D0	Longueur
	Move.l	$4.w,A6
	Jsr	_LVOFreeMem(A6)
.NoF4	Clr.l	AdrSprites
	Clr.l	SpritesLength
	Move.l	AdrSprites8,A1
	Tst.l	A1
	Beq.s	.NoF8
	Move.l	Sprites8Length,D0
	Move.l	$4.w,A6
	Jsr	_LVOFreeMem(A6)		
.NoF8	Clr.l	AdrSprites8
	Clr.l	Sprites8Length
	RTS


LoadingJaugeMAJ
	********************** PRIORITE ABSOLUE...
	Movem.l	D0-D7/A0-A6,-(A7)
	*Tst.w	ExeBarSamples
	*Beq.s	.NoExBarS

	Move.l	Planar,A2
	Move.w	#Jauge_Rouge,D6		Rouge
	Moveq	#6,D7
	Clr.l	D2
	Move.w	JaugeCpt,D2	Pix=(SamplesAct/NbSamples)*larg
	Mulu.w	#LargJaugeSamples,D2
	Divu.w	#JaugeNbElements,D2
	Cmp.w	#LargJaugeSamples,D2
	Ble.s	.Ok
	Move.w	#LargJaugeSamples,D2	ANTIBUG dépassement
.Ok	Add.w	#XJaugeSamples,D2	
	Move.w	D2,JaugeMem1	Utilisation var déjà existante...
	Move.w	#XJaugeSamples,D0
	Move.w	#YJaugeSamples,D1
	Move.w	#YJaugeSamples+HautJaugeSamples,D3


	Movem.l	D0-D2/D7/A2,-(A7)
	Bsr	BAR			Grosse jauge
	Movem.l	(A7)+,D0-D2/D7/A2

	Move.w	#YJaugeSamples+HautJaugeSamples/2,D1
	Move.w	D1,D3
	Addq.w	#1,D3
	Move.w	#Jauge_Milieu,D6		
	Bsr	BAR			Barre du milieu

	Move.l	Planar,A2
	Move.w	#Jauge_Gris,D6	Gris foncé
	Moveq	#6,D7
	Move.w	JaugeMem1,D0
	Move.w	#YJaugeSamples,D1
	Move.w	#XJaugeSamples+LargJaugeSamples,D2
	Move.w	#YJaugeSamples+HautJaugeSamples,D3
	Cmp.w	D0,D2		Pas de gris si rouge remplit tout
	Ble.s	.NoExBarS
	Bsr	BAR
.NoExBarS
	Movem.l	(A7)+,D0-D7/A0-A6
	RTS
