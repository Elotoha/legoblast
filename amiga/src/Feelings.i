
********************************
* GESTION DES VUES DE FEELINGS *
********************************

VueHeight		=	23	22 lignes à copier sur 23
VueLarg		=	19	Pour le centrage sur le podium
VueSize		=	(24/8)*VueHeight
SizeLineFeelings	=	192/8
SizePlanFeelings	=	SizeLineFeelings*160
NbPlansFeelings	=	7

*****************   Copier une vue dans un écran avec une
*		précision d'un pixel en X et en Y.
*
* A2: Adresse de l'écran cible
* D0: X
* D1: Y
* D2: N° de l'anim (0-7)
* D3: N° de la vue (0-6)
*
*******	TOUS LES REGISTRES SONT SAUVES
* 
* Une vue fait 24*22, soit 66 octets pour un plan
*
*
CopVue
	Movem.l	D0-D5/A0-A3,-(A7)
	Movea.l	Source_AdrPlan,A2	
	Movea.l	FeelDat,A0
	Mulu.w	#VueSize*8,D3	N° de la vue *8*TailleVue
	Move.w	D2,D4
	Add.w	D2,D2
	Add.w	D4,D2		N° de l'anim*3
	Add.w	D3,D2	
	Lea	(A0,D2.w),A0	Adresse vue à copier

	Mulu.w	Source_SizeLine,D1
	Lea	(A2,D1.w),A2	Ligne cible

	* D1,D2,D3 : !OK!	

	Move.w	D0,D1
	And.w	#%111,D1	Nombre de bits à partir de la gauche (0-7)
	Lsr.w	#3,D0	Nombre d'octets en plus en X
	Lea	(A2,D0.w),A2

	* D0,D2,D3 : !OK!	

	* A0: Source
	* A2: Cible avec décalage de D1 bits à droite

	Moveq	#VueHeight-2,D0
.CopY	Move.l	(A0),D2		Lecture masque
	Move.b	#$FF,D2		Largeur=24 et pas 32... 
	Movea.l	A0,A1		Back source
	Movea.l	A2,A3		Back plan
	Adda.w	#SizePlanFeelings,A1	on passe au plan 0
	Moveq	#7-1,D3		Plans
.CopPl	Move.l	(A3),D4		Image plan
	And.l	D2,D4		Image masquée (0=Vue future)
	Move.l	(A1),D5		Image source
	Clr.b	D5
	Or.l	D5,D4		Plan masqué avec image
	Move.l	D4,(A3)		ECRITURE plan
	Adda.w	#SizePlanFeelings,A1
	Adda.w	Source_SizePlan,A3
	Dbf	D3,.CopPl
	Adda.w	#SizeLineFeelings,A0	
	Adda.w	Source_SizeLine,A2
	Dbf	D0,.CopY
	Movem.l	(A7)+,D0-D5/A0-A3
	RTS
	
	
************************** COLORIAGE !!!!!! Du jamais vu !!!
* Je vais me prendre la tête pour faire cette routine, ca va être
* incroyable je sens...
*
* Bon ben cette routine sert à recoloriser les vues pour les feelings
* de la couleur du joueur actuel. Mais je ne veux recoloriser que
* l'animation concernée afin de perdre le moins de temps possible !
*
*
* D2: N° de l'anim (0-6)
*
* D5-D7/A2-A6 ne sont pas utilisés pas les routines Plot/Point
* D0-D1/A0 ne sont pas modifiés par ces routines
*
COLORIAGE
	Movem.l	D0-D5/A0-A1,-(A7)

	Cmp.w	#6,D2
	Bgt	FinColori
	Move.w	D2,D4
	Blt	FinColori
	Add.w	D2,D2
	Add.w	D4,D2		N° de l'anim*3

	Movea.l	FeelDat,A0
	Lea	(A0,D2.w),A0	Adresse vue 0 de l'anim à copier


	****** Balayer toutes les vues en les coloriant
	Moveq	#6,D5
.LoopVue	Clr.l	D0	X
.LoopX	Clr.l	D1	Y
.LoopY	Bsr	ReadPointF
	Tst.w	D2
	Ble.s	.NoW
	Bsr	TestCoulF		On regarde si la couleur
	Tst.w	D2		est intéressante
	Ble.s	.NoW
	Bsr	WritePointF	
.NoW	Addq.w	#1,D1
	Cmp.w	#21,D1	0-21
	Ble.s	.LoopY
	Addq.w	#1,D0	0-18 (normalement 0-23)
	Cmp.w	#VueLarg-1,D0
	Ble.s	.LoopX
	Adda.w	#VueSize*8,A0	Prochaine vue de l'anim
	Dbf	D5,.LoopVue		

FinColori	Movem.l	(A7)+,D0-D5/A0-A1
	RTS

****************** Lire une couleur dans la vue actuelle
*
* A0: Adresse de la vue (masque)
* D0: X 0-VueLarg-1
* D1: Y 0-21
* D2: Couleur de retour (-1=Rien)
*
ReadPointF
	Movem.l	D0-D1,-(A7)
	Moveq	#-1,D2
	Movea.l	A0,A1	
	Move.w	D0,D3
	And.w	#%111,D3
	Neg.w	D3
	Add.w	#7,D3	D3: N° du bit à tester
	Lsr.w	#3,D0
	Adda.w	D0,A1
	Mulu.w	#SizeLineFeelings,D1
	Adda.w	D1,A1	A1: Adresse finale de l'octet concerné
	Btst	D3,(A1)	Test masque
	*Beq	.FinPF
	Clr.l	D2
	Clr.l	D4	N° du plan actuellement testé
.LoopPl	Adda.w	#SizePlanFeelings,A1	Plan 0-6
	Btst	D3,(A1)
	Beq.s	.Zer	
	Bset	D4,D2
.Zer	Addq.w	#1,D4
	Cmp.w	#6,D4
	Ble.s	.LoopPl		7 plans = 0-6 !!!
.FinPF	Movem.l	(A7)+,D0-D1
	RTS



****************** Ecrire une couleur dans la vue actuelle
*
* A0: Adresse de la vue (masque)
* D0: X 0-VueLarg-1
* D1: Y 0-21
* D2: Couleur à écrire
*
WritePointF
	Movem.l	D0-D1,-(A7)
	Movea.l	A0,A1	
	Move.w	D0,D3
	And.w	#%111,D3
	Neg.w	D3
	Add.w	#7,D3	D3: N° du bit à tester
	Lsr.w	#3,D0
	Adda.w	D0,A1
	Mulu.w	#SizeLineFeelings,D1
	Adda.w	D1,A1	A1: Adresse finale de l'octet concerné	
	Clr.l	D4	N° du plan actuellement testé
.LoopPl	Adda.w	#SizePlanFeelings,A1	Plan 0-6
	Btst	D4,D2
	Beq.s	.Clir
*	Cmpa.l	#FeelDat+30720,A1		ANTIBUG
*	Ble.s	.Ok	
*	Adda.w	#3*4,A7
*	Bra	FinColori	
*.Ok
	Bset	D3,(A1)
	Addq.w	#1,D4
	Cmp.w	#6,D4
	Ble.s	.LoopPl	
	Bra.s	.FinPF	2ème fin pour économiser un Bra.s
.Clir	Bclr	D3,(A1)
	Addq.w	#1,D4
	Cmp.w	#6,D4	
	Ble.s	.LoopPl		7 plans = 0-6 !!!	
.FinPF	Movem.l	(A7)+,D0-D1
	RTS



************************* REMAPER LES COULEURS DES JOUEURS
*
* E/S: D2: <0: Ne pas réécrire ce point
*
*
*
* Ne pas toucher à D0-D1/D5/A0
*

J1_Deb	=	21	Vert
J1_Fin	=	23
J2_Deb	=	24	Bleu
J2_Fin	=	26
J3_Deb	=	27	Rouge	
J3_Fin	=	29
J4_Deb	=	38	17	Jaune
J4_Fin	=	40	19
J5_Deb	=	56	Marron...
J5_Fin	=	58
J6_Deb	=	44	Violet...
J6_Fin	=	46


TestCoulF
	Cmp.w	#J1_Deb,D2
	Blt.s	.No1
	Cmp.w	#J1_Fin,D2
	Bgt.s	.No1
	Sub.w	#J1_Deb,D2
	Bra	.OKAY
.No1	Cmp.w	#J2_Deb,D2
	Blt.s	.No2
	Cmp.w	#J2_Fin,D2
	Bgt.s	.No2
	Sub.w	#J2_Deb,D2
	Bra	.OKAY
.No2	Cmp.w	#J3_Deb,D2
	Blt.s	.No3
	Cmp.w	#J3_Fin,D2
	Bgt.s	.No3
	Sub.w	#J3_Deb,D2
	Bra	.OKAY
.No3	*Bra.s	.No4		******* BIG PROBLEME !!!!
	Cmp.w	#J4_Deb,D2
	Blt.s	.No4
	Cmp.w	#J4_Fin,D2
	Bgt.s	.No4
	Sub.w	#J4_Deb,D2
	Bra	.OKAY
.No4	Cmp.w	#J5_Deb,D2
	Blt.s	.No5
	Cmp.w	#J5_Fin,D2
	Bgt.s	.No5
	Sub.w	#J5_Deb,D2
	Bra	.OKAY
.No5	Cmp.w	#J6_Deb,D2
	Blt.s	.No6
	Cmp.w	#J6_Fin,D2
	Bgt.s	.No6
	Sub.w	#J6_Deb,D2
	Bra	.OKAY
.No6	Moveq	#-1,D2
	Bra.s	.FIN
.OKAY	Add.w	FeelCol,D2	Pour joueur couleur voulue
.FIN	RTS

*
* 17: Jaune
* 21: Vert
* 24: Bleu
* 27: Rouge
*











	