*************	Trouver une place libre dans le tableau de flammes et
*		créer une flamme
*
*	D1: X
*	D2: Y
*	
NewFlam	
	Move.l	FlamPtr,A1
	Clr.l	D3
	Tst.w	LastNFlam
	Bne.s	.Search
	Move.w	#1,LastNFlam
	Bra.s	.Ok
.Search	Tst.w	Flam_Exist(A1)
	Beq.s	.Ok
	Adda.w	#Flam_SizeOf,A1
	Addq.w	#1,D3
	Cmp.w	LastNFlam,D3
	Blt.s	.Search
	Addq.w	#1,LastNFlam	Plus de place ? on en créée	
.Ok	
	Move.w	D3,Flam_Num(A1)
	Move.w	D1,Flam_X(A1)	(X,Y):Gauche,haut,bas (X+1,Y):droite
	Move.w	D2,Flam_Y(A1)
	Move.w	Flam_VAct,Flam_Vel(A1)
	Move.w	#1,Flam_Exist(A1)
	Move.w	#1,Flam_Active(A1)
	Move.w	#0,Flam_Phase(A1)
	Move.w	#0,Flam_Nb(A1)
	Move.w	#1,Flam_Bout(A1)
	Move.w	#0,Flam_BoutEff(A1)
	Move.w	#0,Flam_LastEff(A1)
	RTS

***********************	FLAMMES
FLAMMES	* Utiliser Affiche(X=D6,Y=D7)
	Clr.w	NbFlammesEnVie
	Tst.w	LastNFlam
	Beq	.FinLoop
	Move.l	FlamPtr,A0
	Clr.l	D0
	Movea.l	A0,A6
.Loop	Tst.w	Flam_Exist(A0)
	Beq	.FLoop

	Add.w	#1,NbFlammesEnVie

	Tst.w	Flam_Phase(A0)  	0:Phase1 -1:Phase3  1:Phase2
	Bgt	.Phase2
	Blt	.Phase3


.PHASE1	**** Phase 1: Expansion

	Move.w	Flam_Energy(A0),D5
	Subq.w	#1,D5	L'énergie de la flamme est à 0 ?
	Bgt.s	.NoEnd
	Move.w	Flam_XEff(A0),Flam_X(A0)	Données effacement
	Move.w	Flam_YEff(A0),Flam_Y(A0)
	Move.w	#-1,Flam_Phase(A0)
	Bra	.AllPh

	* >  |	1,0 	Phase I
	* => |    2,1
	* ==>|    3,2
	* ===|    3,3	On n'efface que les 
	*		morceaux droits!
	* On met bout=1 ou 0, en fonction si la
	* flamme s'est prise un mur ou autre chose
	*
	* .  |	2,3 	Phase II
	* .. |    1,2
	* ==>|    3,2
	* ===|    3,3	
.NoEnd	* La flamme ne s'est pas finie: on avance
	* Il ne faut tracer et gérer le bout de la 
	* flamme qu'à la fin de la boucle.
	*
	Move.w	D5,Flam_Energy(A0)
	Move.w	Flam_Vel(A0),D7	Vélocité (1-3)
	Move.w	Flam_X(A0),D1   	Position
	Move.w	Flam_Y(A0),D2
	Move.w	Flam_VX(A0),D3  	Mouvement 
	Bne	.FlMvX
	Move.w	Flam_VY(A0),D4
	Bne	.FlMvY

.FinMouv	Bra	.AllPh


.PHASE3	**** On attend que les autres flammes finissent leur trajet		

	Tst.w	Flam_Master(A0)	Seule la flamme MASTER a le droit
	Beq	.AllPh		de commander les 3 autres

	Move.l	Flam_A1(A0),A1
	Tst.l	A1	
	Beq.s	.OkPh1
	Tst.w	Flam_Phase(A1)
	Beq	.AllPh
.OkPh1
	Move.l	Flam_A2(A0),A2
	Tst.l	A2
	Beq.s	.OkPh2
	Tst.w	Flam_Phase(A2)
	Beq	.AllPh
.OkPh2
	Move.l	Flam_A3(A0),A3
	Tst.l	A3
	Beq.s	.OkPh3	
	Tst.w	Flam_Phase(A3)
	Beq	.AllPh
.OkPh3	
	Move.w	#1,Flam_Phase(A0)
	Tst.l	A1
	Beq.s	.NopA1
	Move.w	#1,Flam_Phase(A1)
.NopA1	Tst.l	A2
	Beq.s	.NopA2
	Move.w	#1,Flam_Phase(A2)
.NopA2	Tst.l	A3
	Beq.s	.NopA3
	Move.w	#1,Flam_Phase(A3)
.NopA3	

.PHASE2	**** Phase 2: Effacement

	Tst.w	Flam_LastEff(A0)
	Bne.s	.FinEff
	
	Move.w	Flam_X(A0),D1   	Position
	Move.w	Flam_Y(A0),D2
	Move.w	Flam_Vel(A0),D5	
	Move.w	Flam_VX(A0),D3  	Mouvement 
	Bne	.EfMvX
	Move.w	Flam_VY(A0),D4
	Bne	.EfMvY
	Bra	.AllPh	
	
.FinEff	* Fin effacement: on efface les 2 bouts
	Move.w	#0,Flam_Exist(A0)

.EfBoutAR	Tst.w	Flam_BoutEff(A0)		Bout arrière
	Beq.s	.EfBoutAV
	Move.w	Flam_X(A0),D1   	Position
	Move.w	Flam_Y(A0),D2
	Move.w	Flam_VX(A0),D3 
	Move.w	Flam_VY(A0),D4
	Neg.w	D3
	Neg.w	D4
	Add.w	D3,D1
	Add.w	D4,D2
	Move.w	D2,D6
	Lsl.w	#6,D6
	Add.w	D1,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Movea.l	Dim4,A1
	Lea	(A1,D6.l*4),A1	Adresse case
	Tst.w	D3	
	Beq.s	.NoERBX
	Bsr	.EffBoutX
	Bra.s	.NoERBY
.NoERBX	Tst.w	D4
	Beq.s	.NoERBY	
	Bsr	.EffBoutY
.NoERBY
.EfBoutAV	Tst.w	Flam_Bout(A0)		Bout avant
	Beq.s	.AllPh	
	Move.w	Flam_X(A0),D1   	Position
	Move.w	Flam_Y(A0),D2
 	Move.w	D2,D6
	Lsl.w	#6,D6
	Add.w	D1,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Move.l	Dim4,A1
	Lea	(A1,D6.l*4),A1
	Move.w	Flam_VX(A0),D3
	Beq.s	.NoEfBX
	Bsr	.EffBoutX
	Bra.s	.AllPh
.NoEfBX	Move.w	Flam_VY(A0),D4
	Beq.s	.AllPh
	Bsr	.EffBoutY			
.AllPh
.FLoop	Adda.w  #Flam_SIZEOF,A0
	Addq.w  #1,D0
	Cmp.w   LastNFlam,D0
	Blt   .Loop
.FinLoop
	RTS


	*********	Afficher un bout en hauteur
	* A1: Case
	* D1: X
	* D2: Y
	* D3: VX
	*
.AddBoutX
	Tst.w 	D3
	Bgt.s	.Droite2
.Gauche2	Addq.b	#1,Dim4_HG(A1)			(X,Y)
	Bset	#7,Dim4_Mask(A1)
	Addq.b	#1,Dim4_BG+YplusUN(A1)	(X,Y+1)
	Bset	#5,Dim4_Mask+YplusUN(A1)
	Bra.s	.GD2
.Droite2	Addq.b	#1,Dim4_HD(A1)			(X,Y)
	Bset	#6,Dim4_Mask(A1)
	Addq.b	#1,Dim4_BD+YplusUN(A1)	(X,Y+1)
	Bset	#4,Dim4_Mask+YplusUN(A1)
.GD2	Move.w	D1,D6
	Move.w	D2,D7
	Bsr	Affiche2Y		2 Little
	RTS

	********	Effacer le bout d'une flamme en hauteur
	* A1: Case
	* D1: X
	* D2: Y
	* D3: VX
	*
.EffBoutX	Tst.w	D3
	Bgt.s	.EfDr
.EfGa	Subq.b	#1,Dim4_HG(A1)
	Bgt.s	.no10
	Bclr	#7,Dim4_Mask(A1)
.no10	Subq.b	#1,Dim4_BG+YPlusUN(A1)
	Bgt.s	.no11
	Bclr	#5,Dim4_Mask+YPlusUN(A1)
.no11	Bra.s	.EfTr1
.EfDr	Subq.b	#1,Dim4_HD(A1)
	Bgt.s	.no12
	Bclr	#6,Dim4_Mask(A1)	
.no12	Subq.b	#1,Dim4_BD+YPlusUN(A1)
	Bgt.s	.EfTr1
	Bclr	#4,Dim4_Mask+YPlusUN(A1)
.EfTr1	Move.w	D1,D6
	Move.w	D2,D7
	Bsr	Affiche2Y
	RTS

	********	Créer un bout en largeur
	* A1: Case
	* D1: X
	* D2: Y
	* D4: Mv Y
	*
.AddBoutY
	Tst.w	D4	
	Bgt.s	.Bas2
.Haut2	Addq.b	#1,Dim4_HG(A1)		(X,Y)
	Bset	#7,Dim4_Mask(A1)
	Addq.b	#1,Dim4_HD+XplusUN(A1)	(X+1,Y)
	Bset	#6,Dim4_Mask+XPlusUN(A1)
	Bra.s	.HB2
.Bas2	Addq.b	#1,Dim4_BG(A1)		(X,Y)
	Bset	#5,Dim4_Mask(A1)	
	Addq.b	#1,Dim4_BD+XplusUN(A1)	(X+1,Y)
	Bset	#4,Dim4_Mask+XPlusUN(A1)	
.HB2	Move.w	D1,D6
	Move.w	D2,D7
	Bsr	Affiche2X		2 Little
	RTS
	
	********	Effacer le bout d'une flamme en largeur
	* A1: Case
	* D1: X
	* D2: Y
	* D4: VY
	*
.EffBoutY	Tst.w	D4
	Bgt.s	.EfBa
.EfHa	Subq.b	#1,Dim4_HG(A1)
	Bgt.s	.no14
	Bclr	#7,Dim4_Mask(A1)	
.no14	Subq.b	#1,Dim4_HD+XPlusUN(A1)
	Bgt.s	.No15
	Bclr	#6,Dim4_Mask+XplusUN(A1)
.no15	Bra.s	.EfTr2
.EfBa	Subq.b	#1,Dim4_BG(A1)
	Bgt.s	.no16
	Bclr	#5,Dim4_Mask(A1)
.no16	Subq.b	#1,Dim4_BD+XPlusUN(A1)
	Bgt.s	.EfTr2
	Bclr	#4,Dim4_Mask+XPlusUN(A1)
.EfTr2	Move.w	D1,D6
	Move.w	D2,D7
	Bsr	Affiche2X
	RTS

	************ Quand l'effacement avance en X
	* D1: X
	* D2: Y
	* D3: Mv X
	* D4: 0
	* D5: Nombre de pas
	*
.EfMvX	Tst.w	Flam_BoutEff(A0)
	Beq.s	.PasDB1
	Sub.w	D3,D1
	Move.w	D2,D6	Position antérieure
	Lsl.w	#6,D6
	Add.w	D1,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Move.l	Dim4,A1
	Lea	(A1,D6.l*4),A1
	Neg.w	D3
	Bsr	.EffBoutX
	Neg.w	D3
	Add.w	D3,D1
.PasDB1	Move.w	D2,D6
	Lsl.w	#6,D6
	Add.w	D1,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Move.l	Dim4,A1
	Lea	(A1,D6.l*4),A1

	Subq.b	#1,Dim4_HH(A1)	Effacement bout droit
	Bgt.s	.no5	
	Bclr	#3,Dim4_Mask(A1)
.no5	Subq.b	#1,Dim4_BH+YplusUN(A1)
	Bgt.s	.no6
	Bclr	#2,Dim4_Mask+YplusUN(A1)	
.no6	Move.w	D1,D6
	Move.w	D2,D7
	Tst.w	D5
	Beq.s	.Nop1
	Bsr	Affiche2Y
.Nop1	Add.w	D3,D1
	Move.w	D1,Flam_X(A0)

	Subq.w	#1,Flam_Nb(A0)
	Ble	.FBouc1		* Flamme terminée
	Dbf	D5,.EfMvX

	* Avance actuelle terminée: on met un bout arrière

	* On prend le pointeur A1: X antérieur
	* Il faudrait éviter de faire 2 Affiche2Y !
	
	Neg.w	D3
	Add.w	D3,D1
	Bsr	.AddBoutX
	Move.w	#1,Flam_BoutEff(A0)	
		
	Bra	.AllPh

.FBouc1	* Effacement global de la flamme terminé!	

	Neg.w	D3
	Add.w	D3,D1
	Bsr	.AddBoutX
	Move.w	#1,Flam_BoutEff(A0)	
	Move.w	#1,Flam_LastEff(A0)
	Bra	.AllPh
	
	************ Quand l'effacement avance en Y
	* D1: X
	* D2: Y
	* D3: 0
	* D4: Mv Y
	* D5: Nombre de pas
	*
.EfMvY	Tst.w	Flam_BoutEff(A0)
	Beq.s	.PasDB2
	Sub.w	D4,D2
	Move.w	D2,D6	Position antérieure
	Lsl.w	#6,D6
	Add.w	D1,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Move.l	Dim4,A1
	Lea	(A1,D6.l*4),A1
	Neg.w	D4
	Bsr	.EffBoutY
	Neg.w	D4
	Add.w	D4,D2
.PasDB2
	Move.w	D2,D6
	Lsl.w	#6,D6
	Add.w	D1,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Move.l	Dim4,A1
	Lea	(A1,D6.l*4),A1

	Subq.b	#1,Dim4_GV(A1)
	Bgt.s	.no7
	Bclr	#1,Dim4_Mask(A1)
.no7	Subq.b	#1,Dim4_DV+XPlusUN(A1)
	Bgt.s	.no8
	Bclr	#0,Dim4_Mask+XPlusUN(A1)
.no8	Move.w	D1,D6
	Move.w	D2,D7
	Tst.w	D5
	Beq.s	.Nop2
	Move.l	D5,-(A7)
	Bsr	Affiche2X
	Move.l	(A7)+,D5
.Nop2	Add.w	D4,D2
	Move.w	D2,Flam_Y(A0)		

	Subq.w	#1,Flam_Nb(A0)
	Ble	.FBouc2

	Dbf	D5,.EfMvY

	Neg.w	D4
	Add.w	D4,D2
	Bsr	.AddBoutY
	Move.w	#1,Flam_BoutEff(A0)	

	Bra	.AllPh

.FBouc2	
	Neg.w	D4
	Add.w	D4,D2
	Bsr	.AddBoutY
	Move.w	#1,Flam_BoutEff(A0)	
	Move.w	#1,Flam_LastEff(A0)
	Bra	.AllPh

	******** La flamme avance en X
	*
	* D1: X
	* D2: Y
	* D3: Vitesse X (-1,1)
	* D4: 0
	* D7: Nombre de "pas"
.FlMvX
	Movea.l	Dim2,A2	Dim visible (arrêt flammes)
	Movea.l	Dim4,A4	Dim des flammes (*16)
	Move.w	D2,D6
	Lsl.w	#6,D6
	Add.w	D1,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Lea	(A4,D6.l*4),A3	
*	Lea	(A2,D6.l),A5
*	Move.l	A5,MemOffAct
	
	* I: Effacement du bout (Gauche, droite ?)
	* On efface juste dans le DIM

	Tst.w 	D3
	Bgt.s	.Droite1
.Gauche1	Subq.b	#1,Dim4_HG(A3)			(X,Y)
	Bgt.s	.no1
	Bclr	#7,Dim4_Mask(A3)
.no1	Subq.b	#1,Dim4_BG+YplusUN(A3)	(X,Y+1)
	Bgt.s	.GD
	Bclr	#5,Dim4_Mask+YplusUN(A3)
	Bra.s	.GD
.Droite1	Subq.b	#1,Dim4_HD(A3)			(X,Y)
	Bgt.s	.no2
	Bclr	#6,Dim4_Mask(A3)
.no2	Subq.b	#1,Dim4_BD+YplusUN(A3)	(X,Y+1)
	Bgt.s	.GD
	Bclr	#4,Dim4_Mask+YplusUN(A3)
.GD	
*
* Si D7=0, la flamme avance d'une case (petite)
*
	
	* II: Boucle d'avance
	* 1) On met la flamme droite Dim+Ecran
	* 2) TantQue Vélocité>0  Vérif+(1)  FinTant
	* Dès que choc: sortie de la boucle sans BOUT!

	Move.w	D2,D6	Y
	Lsl.w	#6,D6
	Add.w	D1,D6	X
	Ext.l	D6
	Lsl.l	#2,D6
	Lea	(A4,D6.l*4),A3

*
* La flamme avance de façon horizontale. Donc il ne faut tester les
* deux cases en Y que dans le cas où elles sont décalées sur des 
* grosses cases différentes, sinon cela fait deux fois plus de tests,
* et surtout cela fait deux flammes générées dans les tuyaux!
*
*
.LoopAvX		
	**** Mise en place et traçage bout droit H

	Addq.b	#1,Dim4_HH(A3)	Haut Horizontal
	Bset	#3,Dim4_Mask(A3)
	Addq.b	#1,Dim4_BH+YplusUN(A3)	Bas Horizontal
	Bset	#2,Dim4_Mask+YplusUN(A3)

	Move.w	D7,-(A7)
	Move.w	D1,D6
	Move.w	D2,D7
	Bsr	Affiche2Y		Juste 2 little
	Move.w	(A7)+,D7

	Addq.w	#1,Flam_Nb(A0)

	**** Incrémentation de la position
	Add.w	D3,D1

	*** Recalcul des offsets dans les tableaux
	Move.w	D2,D6
	Lsl.w	#6,D6
	Add.w	D1,D6
	Ext.l	D6
	Lsl.l	#2,D6

	**** Test Dim 2	
	Movea.l	#0,A1	
.Tst1	Lea	(A2,D6.l),A5	Visible
	Move.w	(A5),D4	Valeur case	
	
	Movea.l	Dim7,A5		Dalles qui interdisent le Mvt
	Lea	(A5,D6.l),A5
	Move.w	(A5),D5
	Cmp.w	#Type_AntiFeuMec,D5
	Beq.s	.NTst2
	Cmp.w	#Type_AntiFeu,D5
	Beq.s	.NTst2

	Tst.w	D4
	Beq.s	.Tst2	Pas libre: flamme STOP + test quoicai
*.NTst2
*	Clr.l	D5
	Bsr	.TestToyoX
	Tst.w	D4
	Beq.s	.Tst2	On autorise la flamme à continuer
.NTst2	Bsr	.KoiCai	<- met A1 à -1
.Tst2	
	********** éviter le test de la case juste en dessous
	Btst	#0,D2	X:D1,Y:D2
	Beq	.StAv1	Flamme pile sur grosse case: test 2 évité
	**********

	Lea	(A2,D6.l),A5	Visible
	Move.w	64*SizeStructure(A5),D4	Case du dessous

	Movea.l	Dim7,A5		Dalles qui interdisent le Mvt
	Lea	(A5,D6.l),A5
	Move.w	(A5),D5
	Cmp.w	#Type_AntiFeuMec,D5
	Beq.s	.NTst3
	Cmp.w	#Type_AntiFeu,D5
	Beq.s	.NTst3
	
	Tst.w	D4
	Beq.s	.StAv1
*.NTst3
	
	Add.l	#64*SizeStructure,D6
	
	Addq.w	#1,D2
*	Clr.l	D5
	Bsr	.TestToyoX
	Tst.w	D4
	Bne.s	.NStAv1	On autorise la flamme à continuer
	
	Sub.l	#64*SizeStructure,D6
	
	Subq.w	#1,D2		Y=Y-1
	Bra.s	.StAv1
.NTst3
.NStAv1	Bsr	.KoiCai
	
	Sub.l	#64*SizeStructure,D6	Revenir à la case plus haut
	Subq.w	#1,D2		Y=Y-1
.StAv1	
	Lea	(A4,D6.l*4),A3	Dim4: Flammes: pour case haut
	Tst.l	A1
	Bgt.s	.MkBout2	(Pour faire un bout sur une bombe par ex.)
	Blt.s	.EndAvX	Flamme STOP : A1=-1

	Move.w	D1,Flam_X(A0)

	**** Bouclage
	Dbf	D7,.LoopAvX

	***********************
	
	* III: Création d'un bout
	* Vélocité=0(D7): La vérif est déjà faite: Case OK
.MkBout2	Movea.l	A3,A1
	Bsr	.AddBoutX
.EndAvX	Bra	.FinMouv
	



	******** La flamme avance en Y
	*
	* D1: Ancien X
	* D2: Ancien Y
	* D3: 0
	* D4: Vitesse Y (1,-1)
	* D7: Nombre de "pas"
.FlMvY
	Movea.l	Dim2,A2
	Movea.l	Dim4,A4
	Move.w	D2,D6
	Lsl.w	#6,D6
	Add.w	D1,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Lea	(A4,D6.l*4),A3
	*Lea	(A2,D6.l),A5
	*Move.l	A5,MemOffAct
	
	* Effacement du bout
	
	Tst.w	D4
	Bgt.s	.Bas1
.Haut1	Subq.b	#1,Dim4_HG(A3)		(X,Y)
	Bgt.s	.no3
	Bclr	#7,Dim4_Mask(A3)
.no3	Subq.b	#1,Dim4_HD+XplusUN(A3)	(X+1,Y)
	Bgt.s	.HB
	Bclr	#6,Dim4_Mask+XPlusUN(A3)		
	Bra.s	.HB
.Bas1	Subq.b	#1,Dim4_BG(A3)		(X,Y)
	Bgt.s	.no4
	Bclr	#5,Dim4_Mask(A3)
.no4	Subq.b	#1,Dim4_BD+XplusUN(A3)	(X+1,Y)
	Bgt.s	.HB
	Bclr	#4,Dim4_Mask+XplusUN(A3)
.HB
	** II: Boucle avance

	Move.w	D2,D6
	Lsl.w	#6,D6
	Add.w	D1,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Lea	(A4,D6.l*4),A3
.LoopAvY	
	**** Mise en place et traçage bout droit V
	
	Addq.b	#1,Dim4_GV(A3)	Gauche vertical
	Bset	#1,Dim4_Mask(A3)
	Addq.b	#1,Dim4_DV+XplusUN(A3)	Droite vertical
	Bset	#0,Dim4_Mask+XplusUN(A3)

	Move.w	D7,-(A7)
	Move.w	D1,D6
	Move.w	D2,D7
	Bsr	Affiche2X		Juste 2 Little
	Move.w	(A7)+,D7	

	Addq.w	#1,Flam_Nb(A0)


	*** Incrémentation de la position
	Add.w	D4,D2
	
	*** Recalcul des offsets dans les tableaux
	Move.w	D2,D6
	Lsl.w	#6,D6
	Add.w	D1,D6
	Ext.l	D6
	Lsl.l	#2,D6
	
	**** Test Dim 2
	Movea.l	#0,A1
.Tst3
	Lea	(A2,D6.l),A5	Visible
	Move.w	(A5),D3	

	Movea.l	Dim7,A5		Dalles qui interdisent le Mvt
	Lea	(A5,D6.l),A5
	Move.w	(A5),D5
	Cmp.w	#Type_AntiFeuMec,D5
	Beq.s	.NTst4
	Cmp.w	#Type_AntiFeu,D5
	Beq.s	.NTst4

	Tst.w	D3
	Beq.s	.Tst4

*.Ntst4
	*	Move.l	D4,-(A7)
	*	Move.l	D3,D4
	Exg	D3,D4
*	Clr.l	D5
	Bsr	.TestToyoY	
	Tst.w	D4
	Bne.s	.NopCont1
	Exg	D3,D4
	Bra.s	.Tst4
.NTst4
.NopCont1
	Bsr	.KoiCai
	Exg	D3,D4
	*	Move.l	(A7)+,D4
.Tst4
	********** éviter le test de la case juste en dessous
	Btst	#0,D1	X:D1,Y:D2
	Beq	.StAv2	Flamme pile sur grosse case: test 2 évité
	**********
	
	Lea	(A2,D6.l),A5	Visible
	Move.w	SizeStructure(A5),D3

	Movea.l	Dim7,A5		Dalles qui interdisent le Mvt
	Lea	(A5,D6.l),A5
	Move.w	(A5),D5
	Cmp.w	#Type_AntiFeuMec,D5
	Beq.s	.NTst5
	Cmp.w	#Type_AntiFeu,D5
	Beq.s	.NTst5

	Tst.w	D3
	Beq.s	.StAv2

*.NTst5
	Add.l	#SizeStructure,D6
	Addq.w	#1,D1
	*	Move.l	D4,-(A7)
	*	Move.l	D3,D4	
	Exg	D3,D4
	Bsr	.TestToyoY

	Tst.w	D4
	Bne.s	.NopCont2
	Exg	D3,D4
	Subq.w	#1,D1
	Sub.l	#SizeStructure,D6	
	Bra.s	.StAv2
.NTst5
.NopCont2
	Bsr	.KoiCai
	Exg	D3,D4
	*	Move.l	(A7)+,D4
	Subq.w	#1,D1
	Sub.l	#SizeStructure,D6	
.StAv2	Lea	(A4,D6.l*4),A3	Dim4: Flammes

	Tst.l	A1
	Bgt.s	.MkBout1		>0: Bombe
	Blt.s	.EndAvY		<0: Mur, bonus

	Move.w	D2,Flam_Y(A0)

	**** Bouclage
	Dbf	D7,.LoopAvY
	
	***********************
	
	* III: Création d'un bout
.MkBout1	Movea.l	A3,A1
	Bsr	.AddBoutY
.EndAvY	Bra	.FinMouv
	
	


	**** Teste une case et réagit en conséquence
	*
	* Bombe: faire exploser	OK
	* Bonus: Détruire		OK
	* Mur: Détruire		OK
	* Mur balaise: Rien		OK
	*
	* D4: Valeur de la case visible
	* D6: Offset dans les Dim
	*
.KoiCai	Suba.w	#1,A1		
	Move.w	#-1,Flam_Phase(A0)       Phase 2: On attend les autres
	Move.w	Flam_XEff(A0),Flam_X(A0)
	Move.w	Flam_YEff(A0),Flam_Y(A0)
	Move.w	#0,Flam_bout(A0)	     Pas de bout
	
	Cmp.w	#Type_Bombe,D4
	Bne.s	.NoB1			>>>> BOMBE <<<<
	Movea.l	Dim1,A3		Dim bombes
	Move.w	(A3,D6.l),D4	On sait que c'est une bombe!
	Movea.l	BombPtr,A3
	Mulu.w	#Bomb_SizeOf,D4
	Lea	(A3,D4.w),A3	Adresse structure bombe
	Move.w	#0,Bomb_Time(A3)
	Move.w	#0,Bomb_VX(A3)
	Move.w	#0,Bomb_VY(A3)
	Bra.s	.EndKoi
.NoB1	Cmp.w	#Type_Bonus,D4
	Beq.s	.OuiBo1
	Cmp.w	#Type_Bloc_Destr,D4
	Bne.s	.NoBD1
.OuiBo1	Bsr	NewMur	

.NoBD1
.EndKoi	RTS


*********** Tester si la flamme rencontre un tuyau !
*
* D1: X où l'on veut aller
* D2: Y où l'on veut aller
* D3: Valeur d'avance en X/Y
* D4: Valeur de la case
*	%GDHB
*	%3210
*	
*********** En X
.TestToyoX
	Btst	#5,D4
	Beq	.NoToyoX		Ce n'est pas un tuyau

	* Si la case où l'on veut aller est impaire en X, on PEUT y aller
	* Si on va vers la droite
	Btst	#0,D1
	Beq.s	.NOkXA1	Pair
	Tst.w	D3	Impair
	Bgt	.OkXA	Impair,>0 : OK
	Bra.s	.Suite1	Impair,<0, Pas OK
.NOkXA1	* Pair
	Tst.w	D3	
	Blt	.OkXA	Pair,<0 : OK

	******
.Suite1
	Tst.w	D3
	Bgt	.VDroite
.VGauche	* La flamme va vers la Gauche
	Btst	#2,D4	Ouvert à droite ?
	Beq	.NoToyoX	non, donc rien
	Btst	#3,D4
	Beq.s	.POuvGa
	* Ouvert à gauche : la flamme continue tout droit
	Clr.l	D4	Autorisation de continuer à la flamme
	Bra	.NoToyoX
.POuvGa	* La flamme va vers la Gauche, mais a gauche le tuyau n'a
	* pas d'ouverture à gauche
.TstHaBa	Btst	#1,D4	Haut ?
	Beq.s	.NopHa

	* On créée la flamme vers le Haut
	Movem.l	D1-D3/A1,-(A7)
	Tst.w	D3	VX<0 ? On fait D1-1
	Bge.s	.NopN3
	Subq.w	#1,D1
.NopN3
	Addq.w	#1,D2
	
	Bsr	NewFlam		
	Move.w	#0,Flam_VX(A1)	Haut
	Move.w	#-1,Flam_VY(A1)
	Move.w	Flam_X(A1),Flam_XEff(A1)
	Move.w	Flam_Y(A1),Flam_YEff(A1)
	Move.w	#-1,Flam_Master(A1)
	Clr.l	D3
	Move.l	D3,Flam_A1(A1)	Pointeurs autres flammes
	Move.l	D3,Flam_A2(A1)
	Move.l	D3,Flam_A3(A1)
	Move.w	Flam_Energy(A0),D3
	Subq.w	#1,D3
	Move.w	D3,Flam_Energy(A1)
	Movem.l	(A7)+,D1-D3/A1

.NopHa	Btst	#0,D4	Bas ?
	Beq.s	.NopBa

	* On créée la flamme vers le Bas
	Movem.l	D1-D3/A1,-(A7)
	Tst.w	D3	VX<0 ? On fait D1-1
	Bge.s	.NopN4
	Subq.w	#1,D1
.NopN4
	Bsr	NewFlam		
	Move.w	#0,Flam_VX(A1)	Bas
	Move.w	#1,Flam_VY(A1)
	Move.w	Flam_X(A1),Flam_XEff(A1)
	Move.w	Flam_Y(A1),Flam_YEff(A1)
	Move.w	#-1,Flam_Master(A1)
	Clr.l	D3
	Move.l	D3,Flam_A1(A1)	Pointeurs autres flammes
	Move.l	D3,Flam_A2(A1)
	Move.l	D3,Flam_A3(A1)
	Move.w	Flam_Energy(A0),D3
	Subq.w	#1,D3
	Move.w	D3,Flam_Energy(A1)
	Movem.l	(A7)+,D1-D3/A1

.NopBa
	Bra.s	.NoToyoX
.VDroite	* La flamme va vers la Droite
	Btst	#3,D4	Ouvert à gauche ?
	Beq.s	.NoToyoX	non, donc rien
	Btst	#2,D4	Ouvert à droite ?	
	Beq	.TstHaBa	.POuvDr	Non
	* Ouvert à droite : la flamme continue tout droit
.OkXA	Clr.l	D4	Autorisation continuer à la flamme
	Bra	.NoToyoX

.NoToyoX	RTS

*********** En Y
.TestToyoY
	Btst	#5,D4
	Beq	.NoToyoY		Ce n'est pas un tuyau

	* Si la case où l'on veut aller est impaire en Y, on PEUT y aller
	* si la direction est bas
	* Et inversement
	Btst	#0,D2
	Beq.s	.NOkYA1	Pair
	Tst.w	D3	Impair
	Bgt	.OkYA	Impair,>0 : OK
	Bra.s	.Suite2	Impair,<0, Pas OK
.NOkYA1	* Pair
	Tst.w	D3	
	Blt	.OkYA	Pair,<0 : OK
	********
.Suite2

	Tst.w	D3
	Bgt	.VBa
.VHa	* La flamme va vers le Haut
	Btst	#0,D4	Ouvert en bas ?
	Beq	.NoToyoY	non, donc rien
	Btst	#1,D4
	Beq.s	.POuvHa
	* Ouvert en haut : la flamme continue tout droit
	Clr.l	D4	Autorisation continuer à la flamme
	Bra	.NoToyoY
.POuvHa	* La flamme va vers la Haut, mais le tuyau n'est pas ouvert
	* en haut
.TstGaDr	Btst	#3,D4	Gauche ?
	Beq.s	.NopGa

	* On créée la flamme vers la gauche	
	Movem.l	D1-D3/A1,-(A7)
	Tst.w	D3	VY<0 ? On fait D2-1
	Bge.s	.NopN1
	Subq.w	#1,D2
.NopN1
	Addq.w	#1,D1

	Bsr	NewFlam		
	Move.w	#-1,Flam_VX(A1)	Gauche
	Move.w	#0,Flam_VY(A1)
	Move.w	Flam_X(A1),Flam_XEff(A1)
	Move.w	Flam_Y(A1),Flam_YEff(A1)
	Move.w	#-1,Flam_Master(A1)
	Clr.l	D3
	Move.l	D3,Flam_A1(A1)	Pointeurs autres flammes
	Move.l	D3,Flam_A2(A1)
	Move.l	D3,Flam_A3(A1)
	Move.w	Flam_Energy(A0),D3
	Subq.w	#1,D3
	Move.w	D3,Flam_Energy(A1)
	Movem.l	(A7)+,D1-D3/A1


.NopGa	Btst	#2,D4	Droite ?
	Beq.s	.NopDr

	* On créée la flamme vers la droite
	Movem.l	D1-D3/A1,-(A7)
	Tst.w	D3	VY<0 ? On fait D2-1
	Bge.s	.NopN2
	Subq.w	#1,D2
.NopN2
	Bsr	NewFlam		
	Move.w	#1,Flam_VX(A1)	Droite
	Move.w	#0,Flam_VY(A1)
	Move.w	Flam_X(A1),Flam_XEff(A1)
	Move.w	Flam_Y(A1),Flam_YEff(A1)
	Move.w	#-1,Flam_Master(A1)
	Clr.l	D3
	Move.l	D3,Flam_A1(A1)	Pointeurs autres flammes
	Move.l	D3,Flam_A2(A1)
	Move.l	D3,Flam_A3(A1)
*	Move.w	Flam_Energy(A0),Flam_Energy(A1)
	Move.w	Flam_Energy(A0),D3
	Subq.w	#1,D3
	Move.w	D3,Flam_Energy(A1)
	Movem.l	(A7)+,D1-D3/A1
.NopDr
	Bra.s	.NoToyoY
.VBa	* La flamme va vers le Bas
	Btst	#1,D4	Ouvert en haut ?
	Beq.s	.NoToyoY	non, donc rien
	Btst	#0,D4	Ouvert en bas ?	
	Beq	.TstGaDr	.POuvBa	Non
	* Ouvert en bas : la flamme continue tout droit
.OkYA	Clr.l	D4	Autorisation continuer à la flamme
*	Bra.s	.NoToyoY


.NoToyoY	RTS


