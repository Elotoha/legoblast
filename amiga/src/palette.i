*
******************* Faire une palette (Sans "SWAP")
*
*	A0: Adresse de la palette
*	D0: Nombre de couleurs
*
* Cette routine procéde en deux passes:
*    - Première passe: Décomposition des mots forts et faibles 
* 		   et écriture des mots de poids fort
*    - Deuxième passe: Ecriture des mots de poids faible
*
	Section	code,code
MakePaletteNew
	Subq.w	#1,D0
	Move.w	D0,D4
	Lea	PalWorkFaible,A2
	Movea.l	A2,A3

	******* Pré-Phase: Sélection de la banque de couleurs
	*
	*Ror.w	#3,D7
	*And.w	#$E000,D7
	Move.w	#$0C00,D7		Valeur normale
	Move.w	D7,BplCon3	Banque 0
	Moveq	#31,D6		Décompteur de couleurs
	Movea.l	#$2000,A5		à ajouter à D5 pour incrémenter de 1
	Lea	$dff180,A4	Adresse couleurs
	Movea.l	A4,A6
	
	******* Phase 1: Décomposition des couleurs 
	*
.Passe1	Move.l	(A0)+,D1		Lecture 0RGB		
	Move.l	D1,D2
	And.l	#$00F0F0F0,D1	Poids forts
	Eor.l	D1,D2		Poids faibles

	***** Extraire le poids faible
	*
	Clr.l	D3
	Move.b	D2,D3
	Ror.l	#4,D3	BLUE faible
	Lsr.l	#8,D2
	Move.b	D2,D3
	Ror.l	#4,D3	GREEN faible
	Lsr.w	#8,D2
	Move.b	D2,D3	RED faible
	Rol.l	#8,D3	D3: RGB faible
	Move.w	D3,(A2)+		Ecriture dans les PRECALC
	
	***** Extraire le poids fort
	*
	Clr.l	D3
	Lsr.l	#4,D1
	Move.b	D1,D3
	Ror.l	#4,D3
	Lsr.l	#8,D1
	Move.b	D1,D3
	Ror.l	#4,D3
	Lsr.w	#8,D1
	Move.b	D1,D3
	Rol.l	#8,D3
	Move.w	D3,(A6)+		Ecriture dans les REGISTRES !!! :-)

	***** Traitements de changement de banque
	*
	Dbf	D6,.NoChang1
	Moveq	#31,D6
	Movea.l	A4,A6	Init Adresse couleur actuelle
	Add.l	A5,D7	Incrément N° banque
	Move.w	D7,BplCon3	
.NoChang1	******
	Dbf	D4,.Passe1		


	******* Phase intermédiaire: Changement de Poids
	*
	Move.w	#$0E00,D7		Mode poids faible+$0C00
	Move.w	D7,BplCon3   	Banque 0
	Moveq	#31,D6		Décompteur de couleurs
	Movea.l	A4,A6

	******* Phase 2: Ecriture des poids faibles
	*
	Move.w	D0,D4
.Passe2	Move.w	(A3)+,(A6)+
	***** Traitements de changement de banque
	*
	Dbf	D6,.NoChang2
	Moveq	#31,D6
	Movea.l	A4,A6	Init Adresse couleur actuelle
	Add.l	A5,D7	Incrément N° banque
	Move.w	D7,BplCon3	
.NoChang2	******
	Dbf	D4,.Passe2

	Move.w	#0,BplCon3	On restaure N° banque+bit L/H
	
	RTS
*
*
*   Couleur = 1 .w pour poids faible et un pour fort
*   pour 4 couleurs: 8.w
*	un poids fort ou faible se compose de 4 bits
*
*


******************* Faire tourner des couleurs en boucle
*
* A0: Adresse de la palette
* D0: Première couleur
* D1: Dernière couleur (>D0 !!!)
*
* Chaque couleur est un .L
*
CyclePalette
	Move.w	D0,Number	Première couleur
	Sub.w	D0,D1
	Lea	(A0,D0.w*4),A0	Première couleur
	Move.l	(A0),D2	Mémoire
	Subq.w	#1,D1
.Loop	Move.l	4(A0),(A0)+
   	Move.l	-4(A0),RGB
	Jsr	Colour
	Add.w	#1,Number
	Dbf	D1,.Loop
	Move.l	D2,(A0)	
	Move.l	(A0),RGB
	Jsr	Colour
	RTS

******************* Faire tourner des couleurs en boucle INVERSE
*
* A0: Adresse de la palette
* D0: Première couleur
* D1: Dernière couleur (>D0 !!!)
*
* Chaque couleur est un .L
*
CyclePaletteINVERSE
	Movea.l	A0,A1
	Move.w	D1,D3
	Sub.w	D0,D1
	Lea	4(A0,D3.w*4),A0	Dernière couleur+1
	Move.l	-4(A0),D2		Mémoire
	Move.w	D3,Number
	Subq.w	#1,D1
.Loop	Move.l	-8(A0),-(A0)	C(A)=C(A-1)
	Move.l	(A0),RGB
	Jsr	Colour
	Sub.w	#1,Number
	Dbf	D1,.Loop
	Move.l	D2,-4(A0)
	Move.l	D2,RGB
	Jsr	Colour

	Move.l	A1,A0
	Move.w	D3,D0
	Addq.w	#1,D0
	*Bsr	MakePaletteNew		A0/D0	
	RTS

	****

* 1
* 2
* 3  3-1=2-1=1

* 2	1
* 3	0
* 1

*******************	Initialiser les 4 couleurs d'un joueur
*
* Banques de couleur 6 et 7
*
* D0: N° du sprite (0-7) pour la banque et le registre
* D1: N° du joueur (0-7) pour la palette
* 
*	Pair=6 (0,2,4,6), Impair=7 (1,3,5,7)
*
MakeSprPal
	Lsl.w	#4,D1
	Moveq	#7,D2	N° Banque:6
	Lsr.w	#1,D0	D0:J/2 -> 0-3
	Bcc.s	.Bq6				PAIR
.Bq7	*Addq.w	#1,D2	D2:6/7 (%110/%111)		IMPAIR
	Add.w	#2*2,D0
.Bq6	Lsl.w	#3,D0	(0-3)*4 = (0,4,8,12) N° couleur : *2
	Ror.w	#3,D2				
	Move.w	#$0C00,D7		Valeur normale
	Or.w	D2,D7
	Move.w	D7,BplCon3	Banque 6/7
	Lea	($dff180,D0.w),A4		Pointeur cible
	* on a 2.W/couleur, et 4 couleurs/joueur => 16 octets/joueur


*	Move.l	MenuPtrOptP0,D2
*	Sub.l	MenuPtrOptP0+4,D2
*	Lea	Spr8ColIDX,A5
*	Move.l	(A5,D2.w),A5
	
	Lea	Spr8ColNormal,A5

	Lea	(A5,D1.w),A5		Pointeur palette
	Move.w	(A5),(A4)
	Move.w	4(A5),2(A4)	Poids forts des 3 couleurs + 0
	Move.w	8(A5),4(A4)	
	Move.w	12(A5),6(A4)		

	Bset	#9,D7		On passe au poids FAIBLE
	Move.w	D7,BplCon3	
	Move.w	2(A5),(A4)	
	Move.w	6(A5),2(A4)	Poids faibles des 3 couleurs + 0
	Move.w	10(A5),4(A4)	
	Move.w	14(A5),6(A4)

	Move.w	#0,BplCon3	On restaure N° banque+bit L/H	
	RTS




************* Palette pour les joueurs en fonction du mode
*
*	Cela sert à générer les 16 couleurs spécifiques
*	aux joueurs 15-31 (banque 0) ainsi que les couleurs
*	15-31 de la banque 2 (Sprites)
*
MAgiXPalette
	RTS
	Movem.l	D0-D7/A0-A6,-(A7)
	Move.l	MenuPtrOptP0,D2	4*Choix+Base	Indiv/Teams
	Sub.l	MenuPtrOptP0+4,D2	-Base = 4*Choix
	*Lea	Spr4ColIDX,A0	Spr8ColIDX, mais pour ANTIBUG	
	Cmp.w	#4,NbJAct2	et compilation...
	*Bgt.s	.J8
	*Lea	Spr4ColIDX,A0
.J8	Move.l	(A0,D2.w),A0	A0: Adresse palette
	
	* A: Il faut copier les couleurs 15-31
	* Poids fort, Poids faible
	
	Move.w	#$0C00,D7		Valeur normale
	Move.w	D7,BplCon3	Banque 0
	Lea	$dff180+2*16,A4	Pointeur registre couleur
.Cont	Movea.l	A4,A5		POIDS FORTS
	Move.w	(A1),(A5)+
	Move.w	4(A1),(A5)+
	Move.w	8(A1),(A5)+
	Move.w	12(A1),(A5)+
	Move.w	16(A1),(A5)+
	Move.w	20(A1),(A5)+
	Move.w	24(A1),(A5)+
	Move.w	28(A1),(A5)+
	Move.w	32(A1),(A5)+
	Move.w	36(A1),(A5)+
	Move.w	40(A1),(A5)+
	Move.w	44(A1),(A5)+
	Move.w	48(A1),(A5)+
	Move.w	52(A1),(A5)+
	Move.w	56(A1),(A5)+
	Move.w	60(A1),(A5)
	Bset	#9,D7		On passe au poids FAIBLE
	Bne.s	.Fini
	Move.w	D7,BplCon3
	Adda.w	#2,A1
	Bra.s	.Cont	
.Fini	Movem.l	(A7)+,D0-D7/A0-A6
	RTS
	
	
	
	
	
	*****************
	*
	* include Asm:Palette_data.i
	*

	
	Section	PAL_WORK,bss	
PalWorkFaible Ds.w	256	
	even
