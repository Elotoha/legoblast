
********** Chargement d'un fichier
*
* A0: Nom du fichier à charger en mémoire
* D1: Type : Chip/Fast etc....	
* 
* A1: Adresse en mémoire du fichier
* D0: Nombre d'octets lus dans le fichier
*	0=Erreur de lecture (fichier non trouvé, etc...)
*	Ce nombre est TOUJOURS égal à la taille de la zone réservée,
*	parce que dans le cas ou la taille différe, la routine
*	rend la zone mémoire et génére une erreur.
*
*
	Section 	prog,code
ChargeOneSon
	Move.l	A0,schfName
	Move.l	D1,schfMemType
	Clr.l	schfAdr
	Clr.l	schfRead

	*** Ouverture DOS
	Move.l	$4.w,A6
	Lea	schfDosName,A1
	Clr.l	D0
	Jsr	_LVOOpenLibrary(A6)
	Move.l	D0,schfDosBase
	Beq	.ErrDos
	
	*** Lock()
	Movea.l	schfDosBase,A6
	Move.l	schfName,D1
	Move.l	#Access_Read,D2
	Jsr	_LVOLock(A6)
	Move.l	D0,schfLock
	Beq	.CloseDos

	*** Examine()	
	Movea.l	schfDosBase,A6
	Move.l	schfLock,D1
	Move.l	#schfFileInfo,D2
	Jsr	_LVOExamine(A6)
	Tst.l	D0
	Beq	.UnLock

.UnLock2	*** Unlock()	UNLOCK pour Open() et pas OpenFromLock()
	Move.l	schfLock,D1
	Movea.l	schfDosBase,A6
	Jsr	_LVOUnLock(A6)
	Clr.l	schfLock

	*** Récup Taille fichier
	Lea	schfFileInfo,A0
*	Move.l	Fib_Size(A0),D0	$7c
	Move.l	$7C(A0),D0
	Move.l	D0,schfSize
	Addq.l	#4,D0

	*** AllocMem()
	Movea.l	$4.w,A6
	Move.l	schfMemType,D1
	Jsr	_LVOAllocMem(A6)
	Move.l	D0,schfAdr
	Beq	.UnLock

	*** OpenFromLock()
*	Movea.l	schfDosBase,A6
*	Move.l	schfLock,D1	
*	Jsr	-$17A(A6)		_LVOOpenFromLock(A6)
*	Move.l	D0,schfFile
*	Beq.s	.FreeMem
*	Clr.l	schfLock	Ouverture successfull : On détruit le Lock

	*** Open()
	Movea.l	schfDosBase,A6
	Move.l	schfName,D1
	Move.l	#Mode_OldFile,D2		Mode_OldFile=1005
	Jsr	_LVOOpen(A6)
	Move.l	D0,schfFile
	Beq.s	.FreeMem		On ne détruit pas le lock()
	
	*** Read()
	Movea.l	schfDosBase,A6
	Move.l	schfFile,D1
	Move.l	schfAdr,D2
	Add.l	#4,D2
	Move.l	schfSize,D3
	Jsr	_LVORead(A6)
	Cmp.l	schfSize,D0	
	Bne.s	.CloseF
	Move.l	D0,schfRead

	*** Ajout taille dans zone
	Move.l	schfAdr,A0
	Move.l	schfSize,D3
	Lsr.l	#1,D3
	Move.w	D3,(A0)
	Swap	D3
	Tst.w	D3
	Beq.s	.OKSi
	Move.w	#$FFFF,(A0)	Taille maxi : 2*65536 octets !
.OkSi	

	*** Close()
.CloseF	Movea.l	schfDosBase,A6
	Move.l	schfFile,D1
	Jsr	_LVOClose(A6)

	*** FreeMem()
.FreeMem	Tst.l	schfRead	On ne rend la mémoire que si erreur
	Bne.s	.UnLock
	Movea.l	$4.w,A6
	Move.l	schfAdr,A1
	Move.l	schfSize,D0
	Jsr	_LVOFreeMem(A6)

.UnLock	*** Unlock()
	Move.l	schfLock,D1
	Beq.s	.CloseDos
	Movea.l	schfDosBase,A6
	Jsr	_LVOUnLock(A6)

	*** Fermeture DOS
.CloseDos	Move.l	$4.w,A6
	Movea.l	schfDosBase,A1
	Jsr	_LVOCloseLibrary(A6)	

.ErrDos
	Movea.l	schfAdr,A1	Paramétres prêts pour le FreeMem()!
	Move.l	schfRead,D0	On TERMINE sur Move ,D0 (Beq.s ...)
	RTS

	Section	bordel,data	
schfDosName	Dc.b	'dos.library',0
	even
schfDosBase	Dc.l	0
schfName		Dc.l	0
schfSize		Dc.l	0
schfMemType	Dc.l	0
schfLock		Dc.l	0
schfFile		Dc.l	0
schfAdr		Dc.l	0
schfSiz		Dc.l	0
schfRead		Dc.l	0

	Section	Seul,Bss
schfFileInfo	Ds.b	Fib_SizeOf
schfMemReg	Ds.l	4
