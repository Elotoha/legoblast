
******************* Afficher les Volumes de la Musique et des Sons
BAffVols
	Jsr	BClearBois
	Lea	StrWork,A3

	*  VOLUME:
	Lea	Phrase_VolMusique,A2
	Jsr	BCopPh

	* 64
	Clr.l	D3
	Move.w	MusicVol,D3
	Moveq	#2,D6	2 chiffres
	Move.b	#'0',D7
	Jsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
	Jsr	BCopPh
 
 	* VOLUME:
	Lea	Phrase_VolSound,A2
	Jsr	BCopPh

	* 37
	Clr.l	D3
	Move.w	SoundVol,D3
	Moveq	#2,D6	2 chiffres
	Move.b	#'0',D7
	Jsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
	Jsr	BCopPh

	Clr.b	(A3)+	
	Lea	StrWork,A1
.AffPh	Move.w	#0,D0		X de début centrage
	Move.w	#5,D1
	Movea.l	FTinyTxt8,A0
	Move.w	#320,D3		Largeur écran
	Jsr	CenterX
	Jsr	AffichePhraseBarre2	(D0-D1/A0-A1)
	*****************
	VblWait	#150
	Jsr	Set4
	Move.l	#TimeBarreQ*Seconde,BarreDecounter
.NoZik2
.NoBarreSwap
	RTS
	
	
	

******************* Afficher le résultat du chargement d'un module
	
BAffNomMusique
	Jsr	BClearBois
	Lea	Phrase_Module,A2
	Lea	StrWork,A3
.Cop1	Move.b	(A2)+,D2
	Beq.s	.EndC1
	Move.b	D2,(A3)+
	Bra.s	.Cop1
.EndC1	Clr.l	D3
	Move.w	ActualZik,D3
	Moveq	#1,D6	1 chiffre
	Move.b	#'0',D7
	Jsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
.Cop2	Move.b	(A2)+,D2
	Beq.s	.EndC2
	Move.b	D2,(A3)+
	Bra.s	.Cop2
.EndC2	Move.w	#": ",(A3)+
	Tst.w	MemZikCh
	Bne	.NoMOff
	Lea	Phrase_MusicOff,A1
	Bra.s	.AffPh
.NoMOff	Lea	Phrase_ChOk,A2
	Move.w	MemZikCh,D2
	Cmp.w	MusicInProgress,D2
	Beq.s	.OkCO	
	Lea	Phrase_ChEr,A2	
.OkCO	
.Cop3	Move.b	(A2)+,D2
	Beq.s	.EndC3
	Move.b	D2,(A3)+
	Bra.s	.Cop3
.EndC3	Clr.b	(A3)+	
	Lea	StrWork,A1
.AffPh	Move.w	#0,D0		X de début centrage
	Move.w	#5,D1
	Movea.l	FTinyTxt8,A0
	Move.w	#320,D3		Largeur écran
	Jsr	CenterX
	Jsr	AffichePhraseBarre2	(D0-D1/A0-A1) MODULE
	*****************
	VblWait	#150
	Jsr	Set4
	Move.l	#TimeBarre2*Seconde,BarreDecounter
	RTS
	
*******************************

BAffNbSamples
	Jsr	BClearBois
	Lea	StrWork,A3

	* SAMPLES LOADED:
	Lea	Phrase_NbSamples,A2
	Jsr	BCopPh

	* 7
	Clr.l	D3
	Move.w	SamplesLoaded,D3
	Moveq	#2,D6	2 chiffres
	Move.b	#-1,D7
	Jsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
	Jsr	BCopPh
 
 	* /
 	Move.b	#"/",(A3)+

	* 10
	Clr.l	D3
	Move.w	SamplesTotal,D3
	Moveq	#2,D6	2 chiffres
	Move.b	#-1,D7
	Jsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
	Jsr	BCopPh

	Clr.b	(A3)+	
	Lea	StrWork,A1
.AffPh	Move.w	#0,D0		X de début centrage
	Move.w	#5,D1
	Movea.l	FTinyTxt8,A0
	Move.w	#320,D3		Largeur écran
	Jsr	CenterX
	Jsr	AffichePhraseBarre2	(D0-D1/A0-A1)
	*****************
	VblWait	#150
	Jsr	Set4
	Move.l	#TimeBarre2*Seconde,BarreDecounter
.NoZik2
.NoBarreSwap
	RTS

*******************************
		
*************
*
* A1: Message
*
AfficheMessageInfo
	Jsr	BClearBois
	Move.w	#0,D0		X de début centrage
	Move.w	#5,D1
	Movea.l	FTinyTxt8,A0
	Move.w	#320,D3		Largeur écran
	Jsr	CenterX
	Jsr	AffichePhraseBarre2	(D0-D1/A0-A1)
	VblWait	#150
	Jsr	Set4
	Move.l	#TimeBarre2*Seconde,BarreDecounter
	RTS

******************************* Initialiser l'écran de bois

BClearBois
	Move.l	Barre2,A2		Restaurer écran bois
	Movea.l	Bois,A3
	Move.l	#(SizePlanBarre2*NbPlansBarre2)/8-1,D2
.Cop7	Move.l	(A3)+,(A2)+
	Move.l	(A3)+,(A2)+
	Dbf	D2,.Cop7
	RTS

******************************* Copier un texte

BCopPh
.Cop1	Move.b	(A2)+,D2
	Beq.s	.EndC1
	Move.b	D2,(A3)+
	Bra.s	.Cop1
.EndC1
	RTS
