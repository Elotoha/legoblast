

*	Move.l	,SaveSize		SAUVEGARDER UN FICHIER
*	Move.l	,SaveAdr
*	Move.l	#,SaveName
*	Jsr	SaveRoutine	


	bra	EndSave
	
***************
*
* => SaveSize : Nombre d'octets à sauver
*    SaveAdr  : Adresse du buffer à sauver	
*    SaveName : Nom du fichier à sauver
*
* >= D0 : Erreur
	
SaveRoutine
	Move.l	SaveName,Error
	Move.l	SaveSize,D0
	Move.l	$4.w,A6		Ouvrir Dos
	lea	SaveDosName,A1
	Clr.l	D0
	jsr	-$228(A6)	
	Move.l	D0,SaveDosBase
	beq	.Quit
	Move.l	D0,A6		Ouvrir le port fichier
	Move.l	SaveName,D1
	Move.l	#1006,D2		Mode_NewFile
	jsr	-30(A6)
	Move.l	D0,SaveHandler
	beq.s	.close
	Move.l	SaveDosBase,A6		Ecrire le fichier
	move.l	D0,D1
	move.l	SaveAdr,D2
	move.l	SaveSize,D3
	jsr	-48(a6)
	Move.l	D0,SaveEcrit
	Move.l	SaveHandler,D1
	jsr	-36(A6)		Fermer le port fichier
	Clr.l	Error	
.close	Move.l	$4.w,A6		Fermer Dos
	Move.l	SaveDosBase,A1
	jsr	-$19E(A6)

	Move.l	SaveEcrit,D0

.quit	RTS
	
SaveDosName Dc.b	'dos.library',0
SaveDosBase Dc.l	0
SaveSize	Dc.l	0
SaveAdr	Dc.l	0
SaveName	Dc.l	0
SaveHandler Dc.l	0
SaveEcrit	Dc.l	0

error	dc.l	0
	even
EndSave	


