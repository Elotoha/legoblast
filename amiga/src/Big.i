
************************************	VITAL DES LIBRAIRIES

**********	INCLUDES

	include	Exec/Execbase.i
	include	Exec/Memory.i

**********	EQU

*Memf_Public = 1<<0
*Memf_Chip   = 1<<1
*Memf_Fast   = 1<<2
*Memf_Clear  = 1<<16
*Memf_Largest = 1<<17
*Memf_Reverse = 1<<18
*Memf_Total  = 1<<19

*AttnFlags = $128 

***********	OFFSETS

	include	Main_Lib.i

************************************	REGISTRES

*			Registres Joy
Joy0Dat	=  $DFF00A
Joy1Dat	=  $DFF00C
Joy3Dat1  =  $BFE101
Joy3Dat2  =  $BFD000
JoyTest	=  $DFF036
*			Registres raster
VPosR	=  $DFF004 
VHPosR	=  $DFF006
ClxDat	=  $DFF00E
*			Registres DMA
DMACON	=  $DFF096
DMACONr	=  $DFF002
*			Registres copper
Cop1Lch	=  $DFF080
Cop2Lch	=  $DFF084
CopJmp1	=  $DFF088
CopJmp2	=  $DFF08A
*			Registres bitplan
DiwStrt	=  $DFF08E
DiwStop	=  $DFF090
DiwHigh	=  $DFF1E4
DDFStrt	=  $DFF092
DDFStop	=  $DFF094
BplCon0	=  $DFF100
BplCon1	=  $DFF102
BplCon2	=  $DFF104
BplCon3	=  $DFF106
BplCon4   =  $DFF10C
Bpl1Mod	=  $DFF108
Bpl2Mod	=  $DFF10A
Lisaid	=  $DFF07C
AdkCon	=  $DFF09E
AdkConr	=  $DFF010
FMode	=  $DFF1FC
HBStrt	=  $DFF1C4
HBStop	=  $DFF1C6
BeamCon0	=  $DFF1DC
*			Registres blitter
BltCon0	=  $DFF040	Contrôle 0
BltCon1	=  $DFF042	Contrôle 1
BltCon0L	=  $DFF05A	Contrôle 0 Lower Bits
BltCpth	=  $DFF048	Pointeur source C
BltCptl	=  $DFF04A		
BltBpth	=  $DFF04C	Pointeur source B
BltBptl	=  $DFF04E	
BltApth	=  $DFF050	Pointeur source A
BltAptl	=  $DFF052	
BltDpth	=  $DFF054	Pointeur cible D
BltDptl	=  $DFF056	
BltCMod	=  $DFF060	Modulo C
BltBMod	=  $DFF062	Modulo B
BltAMod	=  $DFF064	Modulo A
BltDMod	=  $DFF066	Modulo D
BltSize  	=  $DFF058	Hauteur et largeur fenêtre
BltSizV	=  $DFF05C
BltSizH	=  $DFF05E
BltCdat	=  $DFF070	Registre données C
BltBdat	=  $DFF072	Registre données B
BltAdat	=  $DFF074	Registre données A
BltAfwm	=  $DFF044	Masque 1er mot A
BltAlwm	=  $DFF046	Masque 1er mot B
*
IntEna	=  $DFF09A	Autorisation interruptions
IntReq	=  $DFF09C	
IntEnaR	=  $DFF01C
IntReqR	=  $DFF01E
*			Registres sprites
Spr0pth	=	$120
Spr0ptl	=	$122
Spr1pth	=	$124
Spr1ptl	=	$126
Spr2pth	=	$128
Spr2ptl	=	$12A
Spr3pth	=	$12C
Spr3ptl	=	$12E
Spr4pth	=	$130
Spr4ptl	=	$132
Spr5pth	=	$134
Spr5ptl	=	$136
Spr6pth	=	$138
Spr6ptl	=	$13A
Spr7pth	=	$13C
Spr7ptl	=	$13E
ClxCon	=	$DFF098
*			Registres son
Aud0Lch	=  $DFF0A0
Aud0Len	=  $DFF0A4
Aud0Per	=  $DFF0A6
Aud0Vol	=  $DFF0A8
AdkCon0	=  $DFF09E
AdkCon0r	=  $DFF010

Aud1Lch	=  $DFF0B0
Aud1Len	=  $DFF0B4
Aud1Per	=  $DFF0B6
Aud1Vol	=  $DFF0B8
*AdkCon1	=  $DFF09E
*AdkCon1r	=  $DFF010

Aud2Lch	=  $DFF0C0
Aud2Len	=  $DFF0C4
Aud2Per	=  $DFF0C6
Aud2Vol	=  $DFF0C8
*AdkCon2	=  $DFF09E
*AdkCon2r	=  $DFF010

Aud3Lch	=  $DFF0D0
Aud3Len	=  $DFF0D4
Aud3Per	=  $DFF0D6
Aud3Vol	=  $DFF0D8
*AdkCon3	=  $DFF09E
*AdkCon3r	=  $DFF010

Aud0Dat	=  $DFF0AA
Aud1Dat	=  $DFF0BA
Aud2Dat	=  $DFF0CA
Aud3Dat	=  $DFF0DA
*			Co-Pros
Pra	=  $BFD000
Prb	=  $BFD100
Tal0	=  $BFD400
Tahi	=  $BFD500
Tbl0	=  $BFD600
Tbhi	=  $BFD700
ELsb	=  $BFD800
EMsb	=  $BFDA00

****	Valeurs pour le DMA

Clr	= 0
Set	= 1<<15
Aud	= %1111
Aud0	= 1
Aud1	= 1<<1 
Aud2	= 1<<2
Aud3	= 1<<3
Disque	= 1<<4
Sprite	= 1<<5
Blitter	= 1<<6
Copper	= 1<<7
BitPlan	= 1<<8
PriBlitter= 1<<10
DmaAll	= $7FFF

************************************
************************************

************************************	MACROS A INCLURE DANS LE CODE

CPUMini	MACRO	Numéro mini accepté 
Cpu\@	Move.l	$4.w,A6
	Move.w	$128(A6),D0	AttnFlags(Exec)
	Move.l	#$68040,D2	Processeur
	Moveq	#3,D1
.PLoop	btst	D1,D0
	bne.s	.Found	
	Sub.l	#$10,D2
	dbf	D1,.PLoop
.Found	And.w	#$0140,D0
	Cmp.w	#$140,D0
	Bne.s	.No060
	Move.l	#$68060,D2
.No060	Cmp.l	#$\1,D2
	Bge.s	.AGAO1
	RTS	
.AGAO1		
	ENDM

TestFPU	MACRO	Teste si il y a un FPU (<>0 = Ok)
	Move.l	$4.w,A6
	Move.w	$128(A6),D0	AttnFlags(Exec)
	Clr.l	D3		Co-Processeur
	btst	#5,D0
	beq.s	.No68882	
	Move.l	#$68882,D3
	Jmp	.No68881
.No68882	btst	#4,D0
	beq.s	.No68881
	Move.l	#$68881,D3	
.No68881	Clr.l	D4		68040 Only
	Cmp.l	#$68040,D2
	bne.s	.No68040Fpu
	btst	#6,D0
	bne.s	.No68040Fpu
	Move.l	#$68040,D4	
.No68040Fpu	*	Il faudra faire le 060 !!!! :-(
	Tst.l	D3
	ENDM


FPUOnly	MACRO
	TestFP
	Bne.s	.OkFP
	RTS	
.OkFP
	ENDM
	
AGAOnly	MACRO  		  
Cpu\@	Cmp.b	#$F8,Lisaid+1		Lisaid
	beq.s	.AGAO2
	Clr.l	D0
	Rts
.AGAO2
	ENDM
	
***********************	GESTION DE LA MEMOIRE

*** Dans le code
	
InitMemStack MACRO
	Move.l	#AdrTab,AdrPtr	
	ENDM

ResMemStack MACRO	Taille,Type mémoire,Variable,Adresse si erreur
	Move.l	\1,D0
	Move.l	D0,D7
	Move.l	\2,D1
	Jsr	ResMem
	Move.l	D0,\3
	Beq	\4
	Jsr	AddStack
	ENDM

FreMemStack MACRO
	Move.l	AdrPtr,A4
	Lea	AdrTab,A5
	Move.l	$4.w,A6
BFre	Cmpa.l	A4,A5
	Bge.s	BFreEnd
	Move.l	-(A4),D0	Taille
	Move.l	-(A4),A1	Adresse
	Jsr	_LVOFreeMem(A6)	
	Bra.s	BFre	
BFreEnd	Move.l	A5,AdrPtr
	ENDM

*** Dans les sous-routines

CodeMemStack	MACRO	

ResMem	Move.l	$4.w,A6
	Jsr	_LVOAllocMem(A6)	 D0=(D0:Taille,D1:Type)
	RTS

AddStack	Move.l	AdrPtr,A0		
	Move.l	D0,(A0)+	Adresse
	Move.l	D7,(A0)+	Taille
	Move.l	A0,AdrPtr		
	RTS

	ENDM

*** Dans les data

DataMemStack MACRO		Nombre maxi de zones mémoires allouables
AdrPtr	Ds.l	1
AdrTab	Ds.l	2*\1
	ENDM

	
***********************	GESTION DU MULTITACHE

*** Dans le code



IntOff	MACRO
	Move.w	DmaConR,D0
	Bset	#15,D0
	Move.w	D0,MemDma
	Move.w	IntEnaR,D0
	Bset	#15,D0
	Bset	#14,D0
	Move.w	D0,MemEna	
	Move.w	AdkConR,D0
	Bset	#15,D0
	Move.w	D0,MemAdk
	Move.w	#$7FFF,IntEna	Coupe tout
	Move.w	#$7FFF,IntReq
	Move.w	#$7FFF,DmaCon
	Move.w	#$7FFF,AdkCon
	ENDM

IntOn	MACRO
	Move.w	MemDma,D0
	Move.w	D0,DmaCon
	Not.w	D0
	Move.w	D0,DmaCon
	Move.w	MemEna,D0
	Move.w	D0,IntEna
	Not.w	D0
	Move.w	D0,IntEna
	Move.w	MemAdk,D0
	Move.w	D0,AdkCon
	Not.w	D0
	Move.w	D0,AdkCon
	ENDM

*** Dans les Data

DataInt	MACRO
MemEna	Dc.w	0
MemDma	Dc.w	0	
MemAdk	Dc.w	0
	ENDM
	

***********************	LES LIBRAIRIES

OpenLib	MACRO    Nom,Variable en cas d'erreur
	Move.l	$4.w,A6
	Lea	\1Name,A1
	Move.l	A1,Error
	Clr.l	D0
	Jsr	-$228(A6)
	Lea	\1Name,A1		Si erreur
	Move.l	D0,\1Base
	Beq	\2
	ENDM

CloseLib	MACRO	Nom
	Move.l	$4.w,A6
	Move.l	\1Base,A1
	Jsr	_LVOCloseLibrary(A6)
	ENDM
	
	
***********************	TOUT CE QUI A RAPPORT A L'ECRAN


***********************	LE COPPER

*  Utilisé :  D0-D3/A0/A2
*
*

CopInit1200 MACRO
*	Move.l	#$01060000,(A0)+	Move.w	#$00,$106(A5) BplCon3
	Move.l	#$01FC0000,(A0)+	Move.w	#$00,$1FC(A5) Fetch contrôl (modulos additionnels spéciaux 1200, sur 1,2,4 ou 8 octets)
*	Move.l	#$01E40000,(A0)+	Move.w	#$00,$1E4(A5) DiwHigh
	ENDM


CopWait	MACRO       Y (peut-être un registre)
	Move.b	\1,(A0)+
	Move.b	#%00000001,(A0)+ 
	Move.w	#%1111111111111110,(A0)+  
	ENDM

CopWaitXY	MACRO       X,Y
	Move.b	\2,(A0)+
	Move.w	\1,D2
	lsr.l	#1,D2
	bset	#0,D2
	Move.b	D2,(A0)+
	Move.w	#$FFFE,(A0)+
	ENDM

CopSkip	MACRO       Y (peut-être un registre)
	Move.b	\1,(A0)+
	Move.b	#%00000001,(A0)+ 
	Move.w	#%1111111111111111,(A0)+  
	ENDM

CopMove	MACRO       Valeur,Adresse
	Move.w	\2,(A0)+
	Move.w	\1,(A0)+
	ENDM

CopPlan	MACRO	Adresse planar,Size planar,Nb planar
	Move.l	\1,A2
	Move.w	\3,D0
	Move.w	#$0E0,D2
	Subq.w	#1,D0
.Pl\@	Move.l	A2,D1
	Swap	D1
	CopMove	D1,D2
	Swap	D1
	Addq.w	#2,D2
	CopMove	D1,D2
	Addq.w	#2,D2	
	Adda.l	\2,A2
	Dbf	D0,.Pl\@
	ENDM

CopSprite	MACRO       Adresse sprite,Numéro sprite 
	Move.l	\1,D1
	CopMove	D1,#Spr\2ptl
	Swap	D1
	CopMove	D1,#Spr\2pth
	ENDM

CopInitSprites MACRO
	Move.l	#InitSpr,D1
	Move.w	D1,D2	D2: bits 1-15 
	Swap	D1	D1: bits 16-18
	Move.l	#$120,D3
	Moveq.l	#7,D0
Spr\@	CopMove	D1,D3
	Addq.l	#2,D3
	CopMove	D2,D3
	addq.l	#2,D3
	Dbf	D0,Spr\@
	ENDM

CopEnd	MACRO
	move.w   #$FFFF,(A0)+   Wait Position Impossible
	move.w   #$FFFE,(A0)+
	ENDM


*** Dans les data

DataInitSprites MACRO
InitSpr	Dc.l	0
	ENDM
***********************	BITPLANS

BoucleAdr	MACRO	Adresse allocmem,Adresse adresses,Taille,Nombre
	Clr.l	D0
	Moveq	#\4,D1
	Lea	\2,A0
	Move.l	\1,A1
BouclePl\@ Move.l	A1,(A0)+
	adda.l	\3,A1
	dbf	D1,BouclePl\@
	ENDM
	


***********************	WAIT DIVERS

BlitWait	MACRO
	tst.b	$dff002
w\@	btst	#6,$dff002
	bne.s	w\@
	ENDM

VblLook	MACRO		Retour : D2 N° ligne
.L\@	Move.l	VPosR,D2
	And.l	#$0001FFFF,D2
	Lsr.l	#8,D2
	ENDM

VblWait	MACRO		Ligne à attendre: Y
	Move.l	D2,-(A7)
	VblLook
	Cmp.w	\1,D2
	bne.s	.L\@
	Move.l	(A7)+,D2
	ENDM
	
LWait	MACRO
w1\@	LTest
	bne.s	w1\@
	EndM
	
RWait	MACRO
w2\@	RTest
	bne.s	w2\@
	EndM

WhileL	MACRO
w3\@	LTest
	beq.s	w3\@
	EndM
	
WhileR	MACRO
w4\@	RTest
	beq.s	w4\@
	EndM

LWaitP	MACRO
.w1\@	LTest
	bne.s	.w1\@
	EndM
	
RWaitP	MACRO
.w2\@	RTest
	bne.s	.w2\@
	EndM

WhileLp	MACRO
.w3\@	LTest
	beq.s	.w3\@
	EndM
	
WhileRp	MACRO
.w4\@	RTest
	beq.s	.w4\@
	EndM


WaitSys	MACRO	Temps (50émes de seconde)
	Move.l	DosBase,A6
	Move.l	\1,D1
	Jsr	_LVODelay(A6)	
	EndM

WaitHard	MACRO	Temps (idem)
	Move.l	D0,-(A7)
	Move.l	\1,D0
.Oua\@	VblWait	#200
	VblWait	#220
	Dbf	D0,.Oua\@
	Move.l	(A7)+,D0
	ENDM

***********************	TESTS DIVERS


Ltest	MACRO
	btst  #6,$BFE001
	ENDM  

Rtest	MACRO
	btst  #2,$DFF016
	ENDM
	
***********************	MACROS HARD

* Set/Clr,BBusy,BZero,X,X,Blt Pri,ALL,Bpl,Cop,Blit,Spr,Disk,Son3,Son2,Son1,Son0

DMASet	MACRO
	Move.w	#$9A00|\1,DMACon
	ENDM

DMAClr	MACRO
	Move.w	#\1,DmaCon
	ENDM

OpenScreenHard	MACRO	BplCon0
	* Il manque: DiwStrt,DiwStop,BplCon0
	Lea	$DFF000,A5
	Ori.B	#$80,Prb		Prb (page 1048 libs) mettre MTR à 1 (%10000000)
	Andi.B	#$87,Prb		And 10000111 (il reste MTR,SIDE,DIR,STEP) Arrêt du drive DF0:
	Move.w	#0,BplCon1	
	Move.w	#0,BplCon2
	Move.w	#0,Bpl1Mod	Valeur modulo pair
	Move.w	#0,Bpl2Mod	Valeur modulo impair
	Move.w	#$38,DDFStrt	=>Display Data Fetch Start (start et stop pour une seule ligne)
	Move.w	#$D0,DDFStop	=>Display Data Fetch Stop	
	Move.w	#0,FMode	
	Move.w	#$0010,BplCon3		Border blank
	ENDM

CloseScreenHard	MACRO
	Move.w	#$7FFF,DMACON
	Move.w	#$7FFF,INTENA
	Move.l	$4.w,A6
	Move.l	$9C(A6),A6	
	Move.l	$26(A6),Cop1Lch	
	Move.l	$32(A6),Cop2Lch
	Clr.w	CopJmp1	
	ENDM

************************************	MACROS A DECLARER EN BAS DU CODE

*** En bas du programme dans le code

CodeMemCopy	MACRO
	*******	Copier une zone de mémoire (Précision=.L)
	* A0: Début Source
	* A1: Fin Source
	* A2: Cible
MemCopy	Move.l	(A0)+,(A2)+	
	Cmpa.l	A0,A1
	Bge.s	MemCopy	

	ENDM

Colour	MACRO
	Move.w	\1,Number
   	Move.l	\2,RGB
	Bsr	Colour
	ENDM

CodeColour	MACRO
*********************************        Composer une couleur AGA
*
*      Number : Numéro de la couleur 0-255	.w
*      Red    : Coefficient Rouge 0-255		.b
*      Green  : Coefficient Vert  0-255		.b
*      Blue   : Coefficient Bleu  0-255		.b
*
Colour	* Palette AGA
	Movem.l	D0-D1/D3-D7,-(A7)
	*
	*   Trouver le N° de la banque de couleurs
	*
	Clr.w	D6
	Move.w	Number,D6
	clr.w	D5	Compteur de N°banque
f	cmp.w	#31,D6
	ble.s	.ok
	addq.b	#1,D5
	sub.w	#32,D6		
	Jmp	f
.ok	lsl.w	#1,D6	D6=N°Couleur (0-31) *2
	lsl.b	#5,D5
	lsl.w	#8,D5	D5 est en place (3 bits collés à gauche de 16)
	*
	*   Séparer les poids forts (D0) des faibles (D1)
	*
	Clr.w	D0
	Move.b	Red,D1
	Move.b	D1,D0
	and.b	#$F0,D0
	lsl.w	#4,D0		Red Fort
	and.b	#$0F,D1
	lsl.w	#8,D1		Red Faible
	Move.b	Green,D1
	Move.b	D1,D0
	And.b	#$F0,D0		Green Fort
	lsl.b	#4,D1		Green Faible
	Move.b	Blue,D3
	Move.b	D3,D4
	lsr.b	#4,D4
	Or.b	D4,D0		Blue Fort  : D0 est fini !
	And.b	#$0F,D3
	Or.b	D3,D1		Blue faible : D1 est fini !
	*
	*   Faire les move
	*
	Move.w	#0,D7		Sprites hires
	Or.w	D5,D7		Sélectionner la bonne banque
	Move.w	D7,BplCon3          
	Move.w	D0,($dff180,D6.w)	Poid Fort	
	Or.w	#$200,D7		Mode poids faible
	Move.w	D7,BplCon3   	
	Move.w	D1,($dff180,D6.w)	Poid Faible
	Movem.l	(A7)+,D0-D1/D3-D7
	Rts
	ENDM

CodeMakePalette	MACRO
**********************************  Créer une palette AGA de N couleurs AGA
*
*	A0: Adresse de la palette
*	D1: Nombre N de couleurs à lire dans la palette et à composer
*
MakePalette
	Clr.l	D0		
.Paloop	Move.w	D0,Number
	Move.l	(A0)+,RGB
	Bsr	Colour	
	addq.w	#1,D0
	cmp.l	D1,D0
	blt.s	.Paloop
	RTS
	ENDM

CodePalInit	MACRO
**********************************  Mettre à noir les 256 couleurs AGA
*
PalInit
	Move.l	#256,D1
	Clr.l	D0		
.Paloop	Move.l	#0,RGB		Red,Green,Blue à 0
	Move.w	D0,Number
	Bsr	Colour	
	addq.w	#1,D0
	cmp.w	D1,D0
	bne.s	.Paloop
	RTS
	ENDM

*** Dans les data

DataColour MACRO
Number	Dc.w	0
RGB	Dc.b	0	Octet qui sert pour les Move.l	
Red	Dc.b	0
Green	Dc.b	0
Blue	Dc.b	0
	ENDM



*********************************	PRINT


*** Dans le code

QPrint	MACRO	
	Move.l	\1,A1	Bitplan
	Move.b	\2,D0	X
	Move.b	\3,D1	Y
	Move.l	\4,A0	Texte
	Move.b	\5,D2	Long maxi
	Bsr	QPrint
	ENDM


CodeQPrint  MACRO
*******************
*
*   =>	A0: Adresse du texte
*	A1: Adresse du bitplan
*	D0: X  0-79	.B
*	D1: Y		.B
*	D2: Longueur max .B, non signé
*	SizeLine8 : Nb de colonnes
*
*   >=    D0: Nvelle position X	
*	D1: Nvelle position Y
*
SizeLine8	= 40

QPrint	Movem.l	D3-D4/A0-A1/A3-A4,-(A7)
	And.l	#$FF,D0
	And.l	#$FF,D1
	And.l	#$FF,D2

.BLettre	

	Move.l	D1,D3		Adresse bitmap
	Mulu.w	#SizeLine8,D3
	Lsl.l	#3,D3
	Add.l	D0,D3	

	Clr.w	D4		Lecture Lettre
	Move.b	(A0)+,D4
	Beq.s	.EndPh		Fin phrase ?
	
	Sub.w	#32,D4	Si Num<32, Num=32
	Bgt.s	.OK
	Clr.w	D4	
.Ok	Lsl.w	#3,D4
	Movea.l	Fonte,A3
	Lea	(A3,D4.w),A3	Adresse source fonte	
	Lea	(A1,D3.l),A4	Adresse cible plan
	Move.b	(A3)+,(A4)		Ecriture lettre
	Move.b	(A3)+,SizeLine8(A4)
	Move.b	(A3)+,2*SizeLine8(A4)
	Move.b	(A3)+,3*SizeLine8(A4)
	Move.b	(A3)+,4*SizeLine8(A4)
	Move.b	(A3)+,5*SizeLine8(A4)
	Move.b	(A3)+,6*SizeLine8(A4)
	Move.b	(A3),7*SizeLine8(A4)
	
	Addq.w	#1,D0		Next position
	Cmp.w	#SizeLine8,D0
	Blt.s	.OkPos
	Clr.w	D0
	Addq.w	#1,D1
	Cmp.w	#32,D1
	Blt.s	.OkPos
	Clr.w	D1
.OkPos

	Subq.w	#1,D2	Nb de lettres <= D2 ?
	Tst.w	D2
	Bgt.s	.BLettre	

.EndPh
	Movem.l	(A7)+,D3-D4/A0-A1/A3-A4
	RTS

	ENDM

****************

QPrintH	MACRO		BitPlan,X,Y,Nombre,Remplissage ""
	Move.l	\1,A1
	Move.b	\2,D0
	Move.b	\3,D1
	Move.l	\4,D2
	Move.b	\5,D3
	Bsr	QPrintH
	ENDM


CodeQPrintD  MACRO
*******************
*
*   =>	A1: Adresse du bitplan
*	D0: X  0-79	.B
*	D1: Y		.B
*	D2: Nombre à transcrire 
*	D3: Caractére à mettre début nb ("0", " ", ou -1 pour "") .B
*	SizeLine8 : Nb de colonnes
*
*   >=    D0: Nvelle position X	
*	D1: Nvelle position Y
*
	ENDM

CodeQPrintH	MACRO
*******************		AFFICHER EN HEXA
*
*   =>	A1: Adresse du bitplan 		<--- INUTILE
*	D0: X  0-79	.B		<--- INUTILE
*	D1: Y		.B		<--- INUTILE
*	D2: Nombre à transcrire 
*	D3: Caractére à mettre début nb ("0", " ", ou -1 pour "") .B
*	SizeLine8 : Nb de colonnes		<--- INUTILE
*
QPrintH	
	Lea	AscTrav,A0
	Lea	34(A0),A2		
	Move.b	#0,-(A2)
	Movea.l	A2,A3

	Moveq	#3,D6
.BH	Move.b	D2,D4
	And.b	#$0F,D4
	Cmp.b	#9,D4
	Ble.s	.Dec0
	Add.b	#7,D4
.DEc0	Add.b	#48,D4
	Lsr.b	#4,D2
	And.b	#$0F,D2
	Cmp.b	#9,D2
	Ble.s	.Dec
	Addq.b	#7,D2	On passe de 10 à A	
.Dec	Add.b	#48,D2
	Move.b	D2,D5
	Lsl.w	#8,D5
	Move.b	D4,D5
	Move.w	D5,-(A2)
	Lsr.l	#8,D2
	Dbf	D6,.BH	
	
	Move.l	A2,A0

.Bcl	Move.b	(A0),D2
	Beq.s	.F
	Cmp.b	#48,D2
	Bne.s	.F
	Move.b	D3,(A0)
	Adda.w	#1,A0
	Bra.s	.Bcl			

.F	Cmp.b	#-1,D3
	Bne.s	.Ok1
	Suba.l	A2,A0	Différence
	Adda.w	#1,A0 	+1 : "$"
	Move.w	A0,D2			
	Move.b	#'$',-(A2)
	Move.l	A2,A0		
	Bra	QPrint
.Ok1	Move.b	#'$',-(A2)
	Suba.l	A2,A3		
	Move.l	A2,A0
	Move.l	A3,D2
.END	Bra	QPrint	
	RTS
	ENDM






CodeQPrintB  MACRO
QPrintB	
	* On appelle la routine de conversion en Binaire



	RTS
	ENDM


*** Dans les Data

DataQPrint  MACRO
AscTrav	Ds.b	34	Pour le binaire ! (besoin de 33, mais...)
*Fonte	Incbin	Binary/Font1.QuickFont
*
* La fonte est en 1 plan. 
* Chaque caractére fait 8 octets à la suite.
* Il y a 224 caractéres (32-255)
*
*
	ENDM	



	
************************************		QUE EN DATA !
DataIntVbl	MACRO
	******		Pour l'interruption Vbl/Clavier
Int	Dc.l	0,0
	Dc.b	2,127
	Dc.l	0,IrqDat,IntRoutine
IrqDat	Dc.l	0,0,0,0
Irq	Dc.l	0	
IntNoNa	Dc.b	'GoGo interrupt',0
	ENDM

DataIntM	MACRO	Numéro,Priorité
	******		Pour l'interruption Vbl/Clavier
Int\1	Dc.l	0,0
	Dc.b	2,\2
	Dc.l	0,IrqDat\1,IntRoutine\1
IrqDat\1	Dc.l	0,0,0,0
Irq\1	Dc.l	0	
IntNoNa\1	Dc.b	'GogO interrupt',0
	ENDM


************************************	



