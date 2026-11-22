
	bra	EndLoad
	
***************
*
* => LoadSize : Nombre d'octets à charger
*    LoadName : Adresse du nom à charger    
*    D1   : Code mémoire:  Fast/Chip/Public
*
* >= A0 : Adresse à laquelle le fichier a été chargé
*    D0 : Nombre d'octets chargés
*
	
LoadRoutine
	Move.l	LoadSize,D0

	Move.l	#0,LoadLu
	Move.l	#0,LoadAdr

	Move.l	$4.w,A6		AllocMem
*	Move.l	#$10002,D1	Chip	
	jsr	-198(A6)
	Move.l	D0,LoadAdr
	beq.s	.quit
	Move.l	$4.w,A6		Ouvrir Dos
	lea	LoadDosName,A1
	sub.l	D0,D0
	jsr	-$228(A6)		
	tst.l	D0
	beq.s	.rendre
	Move.l	D0,LoadDosBase
	Move.l	D0,A6		Ouvrir le port fichier
	Move.l	LoadName,D1
	Move.l	#1005,D2
	jsr	-30(A6)
	tst.l	D0
	beq.s	.close
	Move.l	D0,LoadHandler
	Move.l	LoadDosBase,A6		Lire le fichier
	move.l	D0,d1
	move.l	LoadAdr,D2
	move.l	LoadSize,D3
	jsr	-42(a6)
	Move.l	D0,LoadLu
	Move.l	LoadDosBase,A6		Fermer le port fichier
	Move.l	LoadHandler,D1
	jsr	-36(A6)
	
.close	Move.l	$4.w,A6		Fermer Dos
	Move.l	LoadDosBase,A1
	jsr	-$19E(A6)

	Tst.l	LoadLu		Sert à rendre la mémoire
	beq.s	.rendre		si rien n'a été lu

.quit	Move.l	LoadLu,D0
	Move.l	LoadAdr,A0
	RTS
	
.Rendre	Move.l	$4.w,A6		FreeMem
	Move.l	LoadAdr,A1
	Cmp.l	#0,A1		Teste si le mémoire a été réservée
	beq.s	.Quit		Rien n'a à être rendu
	Move.l	LoadSize,D0
	jsr	-210(A6)
	Move.l	#0,LoadAdr
	bra.s	.quit


LoadDosName Dc.b	'dos.library',0
LoadDosBase Dc.l	0
LoadSize	Dc.l	0
LoadAdr	Dc.l	0
LoadName	Dc.l	0
LoadLu	Dc.l	0
LoadHandler Dc.l	0

	even
EndLoad	


