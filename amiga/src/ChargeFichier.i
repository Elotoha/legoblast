
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
	Section	prog,code
ChargeFichier
	Move.l	A0,ChFName
	Move.l	D1,ChFMemType
	Clr.l	ChFAdr
	Clr.l	ChFRead

	*** Ouverture DOS
	Move.l	$4.w,A6
	Lea	ChFDosName,A1
	Clr.l	D0
	Jsr	_LVOOpenLibrary(A6)
	Move.l	D0,ChFDosBase
	Beq	.ErrDos
	
	*** Lock()
	Movea.l	ChFDosBase,A6
	Move.l	ChFName,D1
	Move.l	#Access_Read,D2
	Jsr	_LVOLock(A6)
	Move.l	D0,ChFLock
	Beq	.CloseDos

	*** Examine()	
	Movea.l	ChFDosBase,A6
	Move.l	ChFLock,D1
	Move.l	#ChFFileInfo,D2
	Jsr	_LVOExamine(A6)
	Tst.l	D0
	Beq	.UnLock

.UnLock2	*** Unlock()	UNLOCK pour Open() et pas OpenFromLock()
	Move.l	ChFLock,D1
	Movea.l	ChFDosBase,A6
	Jsr	_LVOUnLock(A6)
	Clr.l	ChFLock

	*** Récup Taille fichier
	Lea	ChFFileInfo,A0
*	Move.l	Fib_Size(A0),D0	$7c
	Move.l	$7C(A0),D0
	Move.l	D0,ChFSize

	*** AllocMem()
	Movea.l	$4.w,A6
	Move.l	ChFMemType,D1
	Jsr	_LVOAllocMem(A6)
	Move.l	D0,ChFAdr
	Beq.s	.UnLock

	*** OpenFromLock()
*	Movea.l	ChFDosBase,A6
*	Move.l	ChFLock,D1	
*	Jsr	-$17A(A6)		_LVOOpenFromLock(A6)
*	Move.l	D0,ChFFile
*	Beq.s	.FreeMem
*	Clr.l	ChFLock	Ouverture successfull : On détruit le Lock

	*** Open()
	Movea.l	ChFDosBase,A6
	Move.l	ChFName,D1
	Move.l	#Mode_OldFile,D2		Mode_OldFile=1005
	Jsr	_LVOOpen(A6)
	Move.l	D0,ChFFile
	Beq.s	.FreeMem		On ne détruit pas le lock()
	
	*** Read()
	Movea.l	ChFDosBase,A6
	Move.l	ChFFile,D1
	Move.l	ChFAdr,D2
	Move.l	ChFSize,D3
	Jsr	_LVORead(A6)
	Cmp.l	ChFSize,D0	
	Bne.s	.CloseF
	Move.l	D0,ChFRead

	*** Close()
.CloseF	Movea.l	ChFDosBase,A6
	Move.l	ChFFile,D1
	Jsr	_LVOClose(A6)

	*** FreeMem()
.FreeMem	Tst.l	ChFRead	On ne rend la mémoire que si erreur
	Bne.s	.UnLock
	Movea.l	$4.w,A6
	Move.l	ChFAdr,A1
	Move.l	ChFSize,D0
	Jsr	_LVOFreeMem(A6)

.UnLock	*** Unlock()
	Move.l	ChFLock,D1
	Beq.s	.CloseDos
	Movea.l	ChFDosBase,A6
	Jsr	_LVOUnLock(A6)

	*** Fermeture DOS
.CloseDos	Move.l	$4.w,A6
	Movea.l	ChFDosBase,A1
	Jsr	_LVOCloseLibrary(A6)	

.ErrDos
	Movea.l	ChFAdr,A1		Paramétres prêts pour le FreeMem()!
	Move.l	ChFRead,D0	On TERMINE sur Move ,D0 (Beq.s ...)
	RTS

	Section	bordel,data	
ChFDosName	Dc.b	'dos.library',0
	even
ChFDosBase	Dc.l	0
ChFName		Dc.l	0
ChFSize		Dc.l	0
ChFMemType	Dc.l	0
ChFLock		Dc.l	0
ChFFile		Dc.l	0
ChFAdr		Dc.l	0
ChFSiz		Dc.l	0
ChFRead		Dc.l	0

	Section	Seul,Bss
ChFFileInfo	Ds.b	Fib_SizeOf
ChFMemReg		Ds.l	4
