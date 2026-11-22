*
**************************
* JE VEUX UN JEU PARFAIT * (Auto-Suggestion qu'y faut qu'elle marche!:*)
**************************
*
* 0,4,5,6: MEME BANQUE D'IMAGES		
* Donc par ex: 1:Vide 2:Passage,etc...
* (UNE FOIS CHAQUE NUMERO D'IMAGE)
*	
*  DIM_BlocDef	BlocType=0 :	Numéro du fond ?
*		BlocType=1 :	Numéro du décord	
*		BlocType=3 :	Numéro du bonus
*		BlocType=4 :	Numéro dans la liste des passages	
*		BlocType=5 :	Direction (4 bits X,4 bits Y)
*
*  DIM_BlocEnergy	Energie minimum que doit avoir la flamme pour pouvoir
*		détruire ce bloc
*
******************	GESTION DES BOMBES ET DES FLAMMES
GESTION
	Tst.w	VblPassed
	Beq	NoVbl
	Clr.w	VblPassed	
	IFNE	Vbl_Display
	 VblWait	#40
	ENDC

	Tst.w	CHEAT_ENABLED
	Beq.s	.NoCheat1
	Jsr	VBLDEBUG_START2
.NoCheat1

	Bsr	TestGene

	*** Affichage INFO BAR bois si besoin
	Move.l	MessageWaitPtr,A0
	Move.l	(A0),A1
	Tst.l	A1
	Beq.s	.NoMsg
	Move.l	A0,-(A7)
	Jsr	AfficheMessageInfo
	Move.l	(A7)+,A0
	*** suite messagewait
	Clr.l	(A0)
.NoMsg

	Movea.l	ClavierPtr,A0
	Tst.b	66(A0)	"TAB"
	Beq.s	.NoSauve
	Bsr	CaptureEcran
.NoSauve
	*** COPIE DE LA BARRE DES JOUEURS SI BESOIN EST

	Tst.w	RequestForNewBar
	Beq.s	.NoNewBar
	Clr.w	RequestForNewBar
	Bsr	CopyBarre		Peut prendre BEAUCOUP de temps !!!
	Bsr	AffAllJoueurs	Tous joueurs dorment
	Bsr	AffAllGueules	Tous joueurs activés
	Move.w	#-1,RequestAffAllDigit
	Bsr	AfficheAllVictoires
	***
	Tst.w	ModeAct
	Bne.s	.NoNewBar
	Bsr	AffNomLevel	Seulement en mode 4 joueurs.... nom level
.NoNewBar
	Tst.w	RequestForClearBois
	Beq.s	.NoClearBois
	Clr.w	RequestForClearBois
	Jsr	BClearBois
	Move.l	#1,BarreDecounter
.NoClearBois

	*** CLAVIER	toutes les Vbl
	Move.w	#-1,ExeClavier

	*** BOMBES 	une Vbl sur 2
	Not.w	ExeBomb	
	Beq.s	.NoB
	Jsr	Bombes
	Bra.s	.Bom
.NoB	*** MURS		une Vbl sur 2
	Jsr	Murs
*	*** BUMPERS	une Vbl sur 2
*	Jsr	GestionBumpers	

	*** TELEPORTEURS	une Vbl sur 4
	Not.w	ExeTele
	Beq.s	.NoM
	Move.w	LevelInfoState,D0
	Blt.s	.NoM
	Cmp.w	#1,D0
	Bgt.s	.NoM
	Jsr	GestionTele
	Bra.s	.Bom
.NoM
	*** BUMPERS	une Vbl sur 4
	Jsr	GestionBumpers	


.Bom	*** FLAMMES	toutes les Vbl
game 	Bsr	Flammes	
	Bsr	TestLevelEnd



	Bra.s	.NoMicroAll
	********
*	Jsr	VBLDEBUG_START
	********	
	*** MICRO		toutes les Vbl
	Movea.l	MicroPtr,A0	pour l'instant un seul micro
	Tst.l	A0
	Beq.s	.NoMicro
	Jsr	Micro_Routage
.NoMicro
	Jsr	VBLDEBUG_START
	********
*	Jsr	VBLDEBUG_END
	********
.NoMicroAll


	*****************
*	 Tst.w	ExeSprite
*	 Beq.s	.NoSpr
* 	 VblWait	#25		Pour les Sprites (25, OBLIGE<=30)
*	 Add.l	#1,TotalPlayingTime		temps de JEU !
*	 Bsr	GestionSprites
*.NoSpr



*	IFNE 	Vbl_Display
*	 Move.w	#0,$dff180
*	ENDC

NoVbl
	Tst.w	CHEAT_ENABLED
	Beq.s	.NoCheat2
	Jsr	VBLDEBUG_END
.NoCheat2

	RTS


******************
*
*	Afficher un niveau
*
*
InitLevel
	***************************
	Add.w	#1,GamesSincePodium
	Clr.w	RequestForNewLevel
	Clr.w	ExeSprite			Joueurs OFF
	Clr.w	ExeLevel			Level OFF
	Clr.w	ExeLevelRalent	
	Move.w	#1,LevelInfoState		Interdiction par défaut
	VblWait	#30	
	Bsr	ClearSprites
	
	Move.l	BumperPtr,BumperPtrAct
	Move.l	Dim2,A4
	Move.l	LevelsAdr,A0
	Move.w	NLevel,D0
	Bge.s	.OkLvl
	Movea.l	DynaBlaster,A6	
	Bra.s	.NoLvl	
.OkLvl	Movea.l	(A0,D0.w*8),A6
.NoLvl	Move.l	A6,LevelAct

	Tst.l	LevelAct
	Bne.s	.LvlOk
	Move.w	#-1,RequestForNewLevel
	Bra	.InitLevelEnd	
.LvlOk

	************* Palette pour le Level
	Move.l	#-1,PALETTE_IN_PROGRESS	
	Move.w	Level_Palette(A6),D0	N° Palette
	Move.l	(LvlPalINDEX,D0.w*4),A0
	Move.l	#64,D0			(+32 ?)
	Movem.l	D1-D7/A1-A6,-(A7)
	Jsr	MakePaletteNew
	Jsr	MAgiXPalette
	Movem.l	(A7)+,D1-D7/A1-A6
	Clr.l	PALETTE_IN_PROGRESS	
	**************

	Move.l	Level_Time1(A6),TimeLvl1
	Move.l	Level_Time2(A6),TimeLvl2
	Add.l	#49,TimeLvl1	Presque une seconde
	Add.l	#49,TimeLvl2
	Clr.w	LvlEndFill
	Move.l	TimeLvl2,D0
	Sub.l	TimeLvl1,D0
	Bgt.s	.OkL	
	Move.w	#-1,LvlEndFill	On a terminé le remplissage!
	Clr.l	TimeLvl1
.OkL	Move.w	Level_FillXMin(A6),D0
	Move.w	D0,LvlFillXMin
	Subq.w	#1,D0	
	Move.w	D0,LvlFillX
	Move.w	Level_FillYMin(A6),D0
	Move.w	D0,LvlFillY
	Addq.w	#1,D0
	Move.w	D0,LvlFillYMin
	Move.w	#1,LvlFillSensX
	Move.w	#0,LvlFillSensY
	Move.w	Level_FillNb(A6),LvlFillRemain	
	Move.w	Level_FillXMax(A6),LvlFillXMax
	Move.w	Level_FillYMax(A6),LvlFillYMax
	Clr.w	LvlFillAnim
	Bsr	MakeRndCorresp
	Lea	Level_Dat(A6),A1
	Bsr	Teleporteurs
	Clr.w	LastNBumper	
	Moveq	#19*2,D0	L
	Moveq	#15*2,D1	H
	Clr.l	D4		Y
.BY	Clr.l	D3		X
	Movea.l	A4,A5
.BX	Move.b	(A1)+,D5		N° suivant....
	And.w	#$FF,D5
	Btst	#6,D5		Si c'est un bonus,on met pas la même chose...
	Bne	.OuiBonux		On met 8 et pas son N° dans visible!

	Cmp.w	#Type_BumperH,D5	Bumper: pas le bon numéro et
	Beq	.OuiBumperH	traitements supplémentaires
	Cmp.w	#Type_BumperB,D5
	Beq	.OuiBumperB
	Cmp.w	#Type_BumperG,D5
	Beq	.OuiBumperG
	Cmp.w	#Type_BumperD,D5
	Beq	.OuiBumperD
	
	Cmp.w	#TYPE_DEBUTDALLES,D5
	Blt.s	.PasD2
	Cmp.w	#TYPE_FINDALLES,D5
	Ble	.OuiDalles
.PasD2	Cmp.w	#TYPE_DEBUTDALLES2,D5
	Blt.s	.PasD21
	Cmp.w	#TYPE_FINDALLES2,D5
	Ble	.OuiDalles
.PasD21
	Move.w	D5,(A5)	
	Move.w	D5,4(A5)	
	Move.w	D5,64*SizeStructure(A5)
	Move.w	D5,4+64*SizeStructure(A5)
.SuitBon	Adda.w	#2*SizeStructure,A5

	Move.w	D4,D6	On le fait, on en aura besoin...
	Lsl.w	#6,D6
	Add.w	D3,D6
	Ext.l	D6
	Lsl.l	#2,D6

	************ Le FONT
	Movem.w	D5/D6,-(A7)
	Move.w	Level_Bloc(A6),D5	Tracer le bloc de font
	Movea.l	Dim3,A3		Téléporteur ?
	Tst.l	(A3,D6.l)
 	Beq.s	.NoTele
	Move.w	Level_Bloc+2*_DECAL(A6),D5
	Move.w	Level_Bloc(A6),D6
	Movea.l	FontPtr,A2
	Bsr	TraceBlocWithBloc 	TRACE LE TELEPORTEUR		
	Bra.s	.EndT	
.NoTele	Movea.l	FontPtr,A2	TRACE LE FONT
	Bsr	TraceBloc
.EndT	Movem.w	(A7)+,D5/D6
	*************

	************* Le VISIBLE
	Cmp.w	#Type_Bloc_Destr,D5
	Bne.s	.S1

	*** Bonus derrière le bloc destructible

	*************** Génération RND
	Movem.l	D0-D1,-(A7)
	Movem.l	MemRnd1,D0-D1
	Bsr	Rnd_Engine
	Move.w	D0,D7
	Lsr.w	#8,D7	Nombre 0-255 .W
	Lea	RndCorresp,A3
	Move.b	(A3,D7.w),D7	Correspondance Nombre->Bonus

	Movea.l	Dim5,A3
	Move.w	D7,(A3,D6.l)	BONUS N° (ou 0)

	Movem.l	D0-D1,MemRnd1
	Movem.l	(A7)+,D0-D1
	Bra.s	.PasRien
	***************** Fin RND
	
	
.S1	Tst.w	D5		Type Font ??
	Bne.s	.TsRi

	* FONT
	Move.w	#Bloc_Vide,D5	Dessin case vide (+FONT)
	Bra	.Rien2	

	* VIDE
.TsRi	Cmp.b	#Type_Rien,D5	RIEN: Case noir (<>font !) (SANS FONT)
	Bne.s	.PasRien

*	WaitHard	#20

	Move.w	#Bloc_Vide,D5		Dessin case vide 
	Movea.l	Planar,A2		A2: plan0
	Bsr	TraceBloc		Visible D3:X, D4:Y, D5:Bloc
	Bra	.Rien

.PasRien	* BONUS dans le level au départ
	Btst	#6,D5
	Beq.s	.PasBonux
	Sub.w	#64,D5		D5-64 : N° du bonus

	Movea.l	Dim5,A3
	Move.w	D5,(A3,D6.l)	BONUS N° (ou 0)
	
	Lea	BonusIdx,A3	
	Move.w	(A3,D5.w*2),D5	Image pour le Bonus
	Bra.s	.Rien2		On trace le bonus

	* TUYAU 
.PasBonux	Bclr	#5,D5		Bclr, pas Btst (!bonus! >64)
	Beq.s	.PasToyo
	Lea	ToyoIdx,A2
	Move.w	(A2,D5.w*2),D5
	Bra.s	.Rien2

	* AUTRE ou DALLE
.PasToyo	Cmp.w	#TYPE_DEBUTDALLES,D5
	Blt.s	.PasD1
	Cmp.w	#TYPE_FINDALLES,D5
	Ble.s	.Dalles
.PasD1	Cmp.w	#TYPE_DEBUTDALLES2,D5
	Blt.s	.PasD12
	Cmp.w	#TYPE_FINDALLES2,D5
	Ble.s	.Dalles
.PasD12
	* AUTRE
	Move.w	Level_Bloc(A6,D5.w*2),D5	Image pour le bloc
	Bra.s	.Rien2

	* DALLE
.Dalles	Move.l	Dim7,A3
	Lea	(A3,D6.l),A3	Adresse dans dim dalles
	Move.w	D5,(A3)	
	Move.w	D5,4(A3)	
	Move.w	D5,64*SizeStructure(A3)
	Move.w	D5,4+64*SizeStructure(A3)

	Move.w	Level_Bloc(A6,D5.w*2),D5	Image pour le bloc
	Move.w	D6,-(A7)
	Move.w	Level_Bloc(A6),D6
	Movea.l	FontPtr,A2
	Bsr	TraceBlocWithBloc 	TRACE LE TELEPORTEUR		
	Move.w	(A7)+,D6
	Move.w	#Bloc_Vide,D5	pour restaurer le font !


	* AUTRE ou FONT ou DALLE
.Rien2	Move.l	A1,-(A7)
	Movea.l	Planar,A1		A2: plan0
	Movea.l	FontPtr,A2
	Bsr	TraceBlocWithFont		Visible D3:X, D4:Y, D5:Bloc
	Move.l	(A7)+,A1
	*****************
.Rien	Addq.w	#2,D3
	Cmp.w	D0,D3
	Blt	.BX
	Adda.w	#64*SizeStructure*2,A4   Next 2 lignes du dim (64 cases)
	Addq.w	#2,D4
	Cmp.w	D1,D4
	Blt	.BY

	************** Palette pour le Level
	*Move.l	#-1,PALETTE_IN_PROGRESS	
	*Move.w	Level_Palette(A6),D0	N° Palette
	*Move.l	(LvlPalINDEX,D0.w*4),A0
	*Move.l	#64,D0			(+32 ?)
	*Movem.l	D1-D7/A1-A6,-(A7)
	*Jsr	MakePaletteNew
	*Movem.l	(A7)+,D1-D7/A1-A6
	*Jsr	MAgiXPalette
	*Clr.l	PALETTE_IN_PROGRESS	
	
	************* Flammes pour le level

	Move.w	Level_Flam(A6),D0
	Move.l	(LvlFlamINDEX,D0.w*4),FlamDatPtr


	************* Préparer les joueurs
	Move.l	A6,-(A7)
	Bsr	PrepPos		Préparer tous les joueurs
	Bsr	CopyBarre		Mettre une barre (0=Indiv,2=Teams)
	Move.l	(A7)+,A6


	**** Initialisation de la barre des joueurs !	
	Bsr	AffAllJoueurs

	*** Affichage nom du level
	Bsr	AffNomLevel


	**** Initialisation du Timer de la barre des joueurs
	Clr.l	D0
	Move.w	#(2*SizeLine*4+PosDigit/8+5)*8,D4	En pixels
	Bsr	DigitCopy8
	Move.w	#(2*SizeLine*4+PosDigit/8+3)*8,D4
	Bsr	DigitCopy8	
	Move.w	#(2*SizeLine*4+PosDigit/8)*8,D4
	Bsr	DigitCopy8
	Moveq	#-1,D0
	Move.w	D0,MemTime1
	Move.w	D0,MemTime2
	Move.w	D0,MemTime3
	Move.w	D0,MemTime4
	Move.w	D0,MemTime5
	****

	**** Affichages des victoires en mode équipe barre joueurs
	Moveq	#0,D3
	Bsr	AfficheVictoiresTeams
	Moveq	#1,D3
	Bsr	AfficheVictoiresTeams


	************* Initialisations autres
	Clr.w	D0
 	Move.w	D0,LastNBomb
	Move.w	D0,LastNFlam
	Move.w	D0,LastNMur
	
	* OK

	************* Pré-lancement du niveau
	
	VblWait	#30
	Clr.w	GameOver
	IFNE	Music_Activation
	 Move.w	MusicVol,P61_Master		Restauration volume normal
	ENDC

	**********	Plantage
	*Move.w	#-1,ExeZik	Musique ON
	**********
	
	Move.w	#-1,ExeSprite	Joueurs ON
	Clr.w	VblPassed
	Clr.w	ExeBomb
	Clr.w	WinnersPhase
*	Move.w	#%1111,DmaCon		3 Sons OFF
	Clr.w	ChannelUse3
	Clr.w	ChannelUse2
	Clr.w	ChannelUse1
	Clr.w	ChannelUse0
	Move.w	#-32767,ChannelPri3
	Move.w	#-32767,ChannelPri2
	Move.w	#-32767,ChannelPri1
	Move.w	#-32767,ChannelPri0
	Clr.w	Son3Loops
	Clr.w	Son2Loops
	Clr.w	Son1Loops
	Clr.w	Son0Loops
	Clr.l	AutoCounter
	
	Tst.w	NewLevel
	Beq.s	.NoInfo
	Move.w	#0,LevelInfoState	Autorisation affichage....
.NoInfo

.InitLevelEnd
	Clr.l	MicroPtr

	RTS

	************ Bonus
.OuiBonux
	Moveq	#Type_Bonus,D6		Bonus	
	Move.w	D6,(A5)	
	Move.w	D6,4(A5)
	Move.w	D6,64*SizeStructure(A5)
	Move.w	D6,4+64*SizeStructure(A5)
	Bra	.SuitBon	


	*********** Dalles
.OuiDalles
	Clr.w	D6
	Move.w	D6,(A5)	
	Move.w	D6,4(A5)	
	Move.w	D6,64*SizeStructure(A5)
	Move.w	D6,4+64*SizeStructure(A5)
	Bra	.SuitBon


	****************
	*
	* On a rencontré un bumper: on l'ajoute à la liste des bumpers...
	*
.OuiBumperH
	Moveq	#0,D6	MvX
	Moveq	#-1,D7	MvY	
	Move.w	#0,D2	Offset dans image
	Bra.s	.ContBump	
.OuiBumperB
	Moveq	#0,D6	MvX
	Moveq	#1,D7	MvY	
	Move.w	#16,D2	Offset dans image
	Bra.s	.ContBump	
.OuiBumperG
	Moveq	#-1,D6	MvX
	Moveq	#0,D7	MvY	
	Move.w	#24,D2	Offset dans image
	Bra.s	.ContBump	
.OuiBumperD
	Moveq	#1,D6	MvX
	Moveq	#0,D7	MvY	
	Move.w	#8,D2	Offset dans image

.ContBump	Move.l	BumperPtrAct,A3
	Add.l	#Bumper_SizeOf,BumperPtrAct
	Add.w	#1,LastNBumper
	Move.w	#1,Bumper_Activate(A3)
	Move.w	D2,Bumper_ImBa(A3)	
	Move.w	D3,Bumper_X(A3)
	Move.w	D4,Bumper_Y(A3)
	Move.w	D6,Bumper_VX(A3)
	Move.w	D7,Bumper_VY(A3)
	Move.w	#-1,Bumper_Eta(A3)
	Move.w	#ImDebBlocBumper,Bumper_ImA(A3)

	Movea.l	Dim6,A2
	Move.l	D4,D2	Y Bumper
	Lsl.w	#6,D2
	Add.w	D3,D2	X Bumper
	Lsl.l	#2,D2	Offset bumper
	Lea	(A2,D2.l),A2
	Move.w	LastNBumper,D2	N° DU BUMPER (DIM 6)
	Subq.w	#1,D2
	Move.w	D2,(A2)
	Move.w	D2,SizeStructure(A2)
	Move.w	D2,64*SizeStructure(A2)
	Move.w	D2,65*SizeStructure(A2)

	
	* D0: Largeur
	* D1: Hauteur
	* D3: X
	* D4: Y
	* D5: Bloc actuel
	* A6: Level actuel

	* Reste: D2/D6-D7

	Tst.w	D6
	Ble.s	.NopXA
	Add.w	D6,D6	2...
.NopXA	Tst.w	D7
	Ble.s	.NopYA
	Add.w	D7,D7
.NopYA
	Move.l	D4,D2	Y Bumper
	Add.w	D7,D2	+VY Bumper
	Lsl.w	#6,D2
	Add.w	D3,D2	X Bumper
	Add.w	D6,D2	+VX Bumper
	Lsl.l	#2,D2	Offset bumper case 1
	Move.l	D2,Bumper_Off1(A3)		CASE 1

	Tst.w	D6
	Beq.s	.EnBas
	Clr.l	D6
	Addq.w	#1,D7
	Bra.s	.Parto	
.EnBas	Addq.w	#1,D6
	Clr.l	D7
.Parto
	Move.l	D4,D2	Y Bumper
	Add.w	D7,D2	+VY Bumper
	Lsl.w	#6,D2
	Add.w	D3,D2	X Bumper
	Add.w	D6,D2	+VX Bumper
	Lsl.l	#2,D2	Offset bumper case 2
	Move.l	D2,Bumper_Off2(A3)		CASE 2

	**** Fin trucs spéciaux bumper

	Moveq	#Type_Bumper,D6
	Move.w	D6,(A5)	
	Move.w	D6,4(A5)
	Move.w	D6,64*SizeStructure(A5)
	Move.w	D6,65*SizeStructure(A5)
	Bra	.SuitBon	


	*************


	********* Sert à créer le tableau de correspondance  
	*	Nombre RND -> Bonus Correspondant
	*
	*
MakeRndCorresp	
	Bsr	.Clear		Cases non initialisées=Pas de Bonus
	Lea	Level_BonusOk(A6),A1
	Clr.l	D0	Somme des probas
	Move.w	#NbBonus,D1	Faut pas abuser : seulement bonus existants (+1 pour case sans bonus)
	Movea.l	A1,A2
.Loop1	Add.w	(A2)+,D0
	Dbf	D1,.Loop1		On fait la somme des probas
	Tst.l	D0
	Beq.s	.Clear		Somme=0: Aucun bonus autorisé
	Lea	RndCorresp,A3
	Clr.w	D1	N° Bonus actuel (Boucle)
.Loop2	Move.w	(A1)+,D2	Proba du bonus actuel (Premier=proba pas bonus)
	Beq.s	.SuiteL2	Proba actuelle nulle: Bonus interdit: Next
	Ext.l	D2
	Lsl.l	#8,D2	.L
 	Divu.w	D0,D2	D2=N1*256/(N1+N2+N3...) : Nombre de cases
	Beq.s	.SuiteL2	0?- le nombre de cases est nul
	Subq.w	#1,D2
.Loop3	Move.b	D1,(A3)+
	Dbf	D2,.Loop3		
.SuiteL2	Addq.w	#1,D1
	Cmp.w	#NbBonus,D1
	Ble.s	.Loop2		+1: Bonus "vide" en plus
	RTS

.Clear	Move.w	#256/4,D1
	Lea	RndCorresp,A3
.Loop4	Clr.l	(A3)+
	Dbf	D1,.Loop4
	RTS

	*********	

Teleporteurs
	Move.l	A1,-(A7)
	Movea.l	TelePtr,A1
	Clr.w	LastNTele
	Lea	Level_Tele(A6),A5		Adresse liste téléporteurs
	Movea.l	Dim3,A3
.LoopTele	Move.w	(A5)+,D0		X Départ
	Blt.s	.EndTele
	Move.w	(A5)+,D1		Y Départ

	Move.w	D0,Tele_X(A1)	ECRIRE la structure téléporteur
	Move.w	D1,Tele_Y(A1)
	
	Movem.l	D0-D1,-(A7)	RANDOM pour la première vue
	Movem.l	MemRnd1,D0-D1
	Bsr	Rnd_Engine
	Movem.l	D0-D1,MemRnd1
	Clr.l	D1
	Divu.l	#ImFinBlocTele-ImDebBlocTele+1,D1:D0
	Add.w	#ImDebBlocTele,D1
	Move.w	D1,Tele_ImA(A1)
	Movem.l	(A7)+,D0-D1

*	Move.w	#ImDebBlocTele,Tele_ImA(A1)
	Addq.w	#1,LastNTele
	Adda.w	#Tele_SizeOf,A1
	
	Move.w	(A5)+,D2		X Arrivée
	Move.w	(A5)+,D3		Y Arrivée
	Move.w	D1,D6		Adresse source
	Lsl.w	#6,D6
	Add.w	D0,D6
	Ext.l	D6
	Lsl.l	#2,D6
	Lea	(A3,D6.l),A2	Dans Position départ, on met arrivée
	Swap	D3
	Move.w	D2,D3		On a YYYYY:XXXXX
	Move.l	D3,(A2)
	Move.l	D3,SizeStructure(A2)
	Move.l	D3,SizeStructure*64(A2)
	Move.l	D3,SizeStructure*65(A2)
	Bra.s	.LoopTele
.EndTele	Move.l	(A7)+,A1
	RTS	* Remarque: on ne peut jamais se téléporter en (0,0)


*********************************

*********************	Générer un tableau DYNABLASTER
*
*
* Avec un % de chances d'avoir un bloc plein....
*
*
DynaInit
	Movea.l	DynaBlaster,A6
	Lea	Level_PosDep(A6),A5
	Lea	Level_dat(A6),A6
	Movea.l	A6,A4
	Move.w	#19*15-1,D2
.Loop	Move.b	(A6),D3
	Blt.s	.Nex
	Cmp.b	#Type_Bloc_NoDestr,D3
	Beq.s	.Nex
	Cmp.b	#Type_Bloc_NoDestr2,D3
	Beq.s	.Nex	
	Move.b	#Type_Font,D5
	Movem.l	MemRnd1,D0-D1
	Bsr	Rnd_Engine
	Movem.l	D0-D1,MemRnd1
	And.l	#$FFFF,D0
	Cmp.w	#50,D0		>: mur	<=: Vide
	Ble.s	.Font
	Move.b	#Type_Bloc_Destr,D5
.Font	Move.b	D5,(A6)
.Nex	Adda.w	#1,A6
	Dbf	D2,.Loop
	*** On met des "étoiles" vides aux positions des joueurs
	Moveq	#NbJoueurs-1,D2
.LoopJ	Move.w	(A5)+,D5
	Move.w	(A5)+,D6
	Bsr	.Clear
	Subq.w	#1,D5
	Bsr	.Clear
	Addq.w	#2,D5
	Bsr	.Clear
	Subq.w	#1,D5
	Subq.w	#1,D6
	Bsr	.Clear
	Addq.w	#2,D6
	Bsr	.Clear
	Dbf	D2,.LoopJ
	
	RTS
	
.Clear	Move.w	D6,D7
	Mulu.w	#19,D7
	Add.w	D5,D7
	Move.b	(A4,D7.w),D3
	Cmp.b	#Type_Bloc_NoDestr,D3
	Beq.s	.nop	
	Cmp.b	#Type_Bloc_NoDestr2,D3
	Beq.s	.nop
	Clr.b	(A4,D7.w)
.Nop	RTS
	

******** Faire toutes les gestions nécessaires de début et fin de niveau
*
*
*
TestLevelEnd
*
*****************************************************************************
*                         TESTS DE DEBUT DE LEVEL                             *
*****************************************************************************

	****
	Move.w	WinnersPhase,D0	Seulement en fin de partie
	Beq.s	.NoAffN
	Cmp.w	#3,D0		Mode spécial don't move
	Bne	.AffPOk2		Seulement si <>don't move fin level
	Bra	.NoAffPod
.NoAffN	Tst.w	LevelInfoState	Ou en tout début
	Bge.s	.NoAffPod	
.AffPOk	Tst.w	NewLevel		Début de NEW level seulement
	Beq.s	.NoAffPod
.AffPOk2	
	Movea.l	ClavierPtr,A0
	Tst.b	13(A0)		Antislash
	Beq.s	.NoAffPod
	Movem.l	D1-D2/A0,-(A7)
	*Bra.s	.Ok1
	Movea.l	LegoPtr,A0
	Clr.l	D2	
.Loop	Move.l	Leg_GamesPlayed(A0),D1
	Cmp.l	#1,D1	au moins 1 partie(s) finie(s)
	Bge.s	.Ok1
	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D2
	Cmp.w	#NbJoueurs,D2
	Blt.s	.Loop
	Bra.s	.NoAffP0
.Ok1	Movem.l	(A7)+,D1-D2/A0
	Bsr	GosubAffPodium
	Adda.w	#8,A7		 Bsr	Gestion,TestLevelEnd
	JMP	INITS0		pour la musique
.NoAffP0	Movem.l	(A7)+,D1-D2/A0

.NoAffPod
	Cmp.w	#3,LevelInfoState
	Bne.s	.NoResWS
	Bsr	RestoreMainBox
.NoResWS
	Tst.w	NbJAct
	Bne	.NoZer
	Move.l	AutoCounter,D0
	Cmp.l	#LevelBeginWait,D0
	Blt	.NoZer
	Tst.w	LevelInfoState
	Bgt	.NoZer
	Blt	.TimerMAJ

	* On est sur le level depuis 25 à 50 Vbl
	Move.w	#2,LevelInfoState		SEMAPHORE !!!! (Int Vbl)
	*	0:Attente -1:Affiché 1:Déjà effacé
	Bsr	BackupWorkingScreen

BoxX1	set	60 
BoxY1	set	70
BoxX2	set	260
BoxY2	set	180
BoxBor	set	1
BonusX	set	2+14+1	en cases
BonusY	set	5+1	en cases
BoxX1a	set	(boxx1/8)*8
BoxY1a	set	(boxy1/8)*8
BoxX2a	set	(boxx2/8)*8
BoxY2a	set	(boxy2/8)*8


	Move.l	#SizeLine,VarSizeLine
	Move.l	#SizePlan,VarSizePlan

	Move.w	#boxx1-boxbor,D0	X1
	Move.w	#boxy1-boxbor,D1	Y1
	Move.w	#boxx2+boxbor,D2	X2
	Move.w	#boxy2+boxbor,D3	Y2
	Move.w	#15,D6	C
	Move.w	#6,D7	Pl
	Move.w	#BoxBor-1,D4	Nombre de pixels de bordure-1
	Movea.l	Planar,A2
	Bsr	BAR_OUTLINE

*	Move.w	#boxx1,D0	X1
*	Move.w	#boxy1,D1	Y1
*	Move.w	#boxx2,D2	X2
*	Move.w	#boxy2,D3	Y2
*	Move.w	#2,D6	C
*	Move.w	#6,D7	Pl
*	Movea.l	Planar,A2
*	Bsr	BAR	

	Move.w	#0,D0	X1	Effacer le plan 7
	Move.w	#0,D1	Y1
	Move.w	#319,D2	X2
	Move.w	#250,D3	Y2
	Move.w	#0,D6	C
	Move.w	#1,D7	Pl
	Movea.l	Planar,A2
	Adda.l	#SizePlan*6,A2
	Bsr	BAR	

	Move.w	#boxx1,D0	X1	Faire le carré sur le plan 7
	Move.w	#boxy1,D1	Y1
	Move.w	#boxx2,D2	X2
	Move.w	#boxy2,D3	Y2
	Move.w	#1,D6	C
	Move.w	#1,D7	Pl
	Movea.l	Planar,A2
	Adda.l	#SizePlan*6,A2
	Bsr	BAR	

	****** On affiche le titre de la belle fenêtre
	
	Move.w	#boxx1a+50+24,D0
	Move.w	#boxy1a+16+2,D1
	Movea.l	FAachen13,A0
	Movea.l	#Phrase_Ready,A1
	Bsr	AffichePhrase	(D0-D1/A0-A1)

	* Wood world, level 4: Smile!

	Lea	StrWork,A0

	Lea	Phrase_Lvl,A1	"LEVEL "
.cop1	Move.b	(A1)+,D0
	Beq.s	.fi1
	Move.b	D0,(A0)+
	Bra.s	.cop1
.fi1
	*********
	Movea.l	A0,A3	StrWork à l'état actuel...

	*** PRINT du N° Du Level   Normalement de "1-01" à "5-20"	
	Move.w	NLevel,D0
	Blt.s	.NoLevN
	Ext.l	D0
	Divs.w	#NbLevelsParWorld,D0	
	Move.w	D0,NWorld
	Swap	D0
	Addq.w	#1,D0
	Clr.l	D3
	Move.w	D0,D3	
	Moveq	#2,D6	2 chiffres
	Move.b	#'0',D7
	Bsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
.Cop2	Move.b	(A2)+,D2
	Beq.s	.EndC2
	Move.b	D2,(A3)+
	Bra.s	.Cop2
.EndC2	
	Move.w	#": ",(A3)+
	Movea.l	A3,A0

	*********

.NoLevN	Movea.l	LevelAct,A6
	Movea.l	Level_Nom(A6),A1	NOM LEVEL
	Adda.l	A6,A1
.cop3	Move.b	(A1)+,D0
	Beq.s	.fi3
	Move.b	D0,(A0)+
	Bra.s	.cop3
.fi3	Clr.b	(A0)+

DecLvl	Set	5
	
	Move.w	#boxx1a+10,D0
	Move.w	#boxy1a+54+DecLvl,D1
	Movea.l	FTinyTxt8,A0
	Lea	StrWork,A1
	Bsr	AffichePhrase	(D0-D1/A0-A1)	LEVEL

	Tst.w	NLevel
	Blt	.NoWorld	

	**************
	Lea	StrWork,A1		"WOOD"
	Lea	Worlds,A2
	Move.w	NWorld,D0
	Lsl.w	#2,D0
	Move.l	(A2,D0.w),A2	
.cop4	Move.b	(A2)+,D0
	Beq.s	.fi4
	Move.b	D0,(A1)+
	Bra.s	.cop4
.fi4	Move.b	#" ",(A1)+
	Lea	Phrase_World,A2		"WORLD"
.cop5	Move.b	(A2)+,D0
	Beq.s	.fi5
	Move.b	D0,(A1)+
	Bra.s	.cop5
.fi5	Clr.b	(A1)+
	*
	Move.w	#boxx1a+10,D0
	Move.w	#boxy1a+42+DecLvl,D1
	Movea.l	FTinyTxt8,A0
	Lea	StrWork,A1
	Bsr	AffichePhrase	(D0-D1/A0-A1)	"WOOD WORLD"

	*********************	Afficher les temps pour le level

.NoWorld	Move.l	LevelAct,A6
	Move.l	Level_Time1(A6),D3
	Move.l	Level_Time2(A6),D0
	Cmp.l	D0,D3
	Bge	.TotalTim

	Lea	StrWork,A3
	*
	Lea	Phrase_Time1,A2		"ALERT TIME: "
.cop10	Move.b	(A2)+,D0
	Beq.s	.fi10
	Move.b	D0,(A3)+
	Bra.s	.cop10
.fi10	*
	Move.l	Level_Time1(A6),D3
	Divu.w	#Minute,D3
	Lea	Phrase_Secondes,A4		"Secondes"
	Tst.w	D3
	Beq.s	.noMin
	Ext.l	D3
	Moveq	#1,D6	1 chiffre		"1"
	Move.b	#'0',D7
	Bsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
.Cop8	Move.b	(A2)+,D2
	Beq.s	.EndC8
	Move.b	D2,(A3)+
	Bra.s	.Cop8
.EndC8	Lea	Phrase_Minutes,A2		"Minutes"
.cop9	Move.b	(A2)+,D0
	Beq.s	.fi9
	Move.b	D0,(A3)+
	Bra.s	.cop9
.fi9	*Move.b	#"'",(A3)+
	*
	Lea	Phrase_Secondes2,A4		"0:27"
.NoMin	Move.l	Level_Time1(A6),D3
	Divu.w	#Seconde,D3
	Ext.l	D3
	Divu.w	#60,D3
	Clr.w	D3
	Swap	D3
	Moveq	#2,D6	2 chiffres	"07"
	Move.b	#'0',D7
	Bsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
.Cop6	Move.b	(A2)+,D2
	Beq.s	.EndC6
	Move.b	D2,(A3)+
	Bra.s	.Cop6
.EndC6	
.cop7	Move.b	(A4)+,D0
	Beq.s	.fi7
	Move.b	D0,(A3)+
	Bra.s	.cop7
.fi7	Clr.b	(A3)+
	*
	Move.w	#boxx1a+10,D0
	Move.w	#boxy1a+66+DecLvl+8,D1
	Movea.l	FTinyTxt8,A0
	Lea	StrWork,A1
	Bsr	AffichePhrase	(D0-D1/A0-A1) "ALERT TIME: 7'45"

	***********
	
.TotalTim	Move.l	LevelAct,A6
	Move.l	Level_Time2(A6),D3
	Lea	StrWork,A3
	*
	Lea	Phrase_Time2,A2		"TOTAL TIME: "
.cop110	Move.b	(A2)+,D0
	Beq.s	.fi110
	Move.b	D0,(A3)+
	Bra.s	.cop110
.fi110	*
	Move.l	Level_Time2(A6),D3
	Divu.w	#Minute,D3
	Lea	Phrase_Secondes,A4		"Secondes"
	Tst.w	D3
	Beq.s	.noMin2
	Ext.l	D3
	Moveq	#1,D6	1 chiffre		"1"
	Move.b	#'0',D7
	Bsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
.Cop18	Move.b	(A2)+,D2
	Beq.s	.EndC18
	Move.b	D2,(A3)+
	Bra.s	.Cop18
.EndC18	Lea	Phrase_Minutes,A2		"Minutes"
.cop19	Move.b	(A2)+,D0
	Beq.s	.fi19
	Move.b	D0,(A3)+
	Bra.s	.cop19
.fi19	*Move.b	#"'",(A3)+
	*
	Lea	Phrase_Secondes2,A4		"0:27"
.NoMin2	Move.l	Level_Time2(A6),D3
	Divu.w	#Seconde,D3
	Ext.l	D3
	Divu.w	#60,D3
	Clr.w	D3
	Swap	D3
	Moveq	#2,D6	2 chiffres	"07"
	Move.b	#'0',D7
	Bsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
.Cop16	Move.b	(A2)+,D2
	Beq.s	.EndC16
	Move.b	D2,(A3)+
	Bra.s	.Cop16
.EndC16	
.cop17	Move.b	(A4)+,D0
	Beq.s	.fi17
	Move.b	D0,(A3)+
	Bra.s	.cop17
.fi17	Clr.b	(A3)+
	*
	Move.w	#boxx1a+10,D0
	Move.w	#boxy1a+78+DecLvl+8,D1
	Movea.l	FTinyTxt8,A0
	Lea	StrWork,A1
	Bsr	AffichePhrase	(D0-D1/A0-A1) "TOTAL TIME: 7'45"

	

	****** On affiche les bonus que les joueurs ont au début du level
	* flammes=60:22, bombe=30:1, pousse bombe=55:23
	
	Movea.l	Planar,A1			FLAMMES
	Move.w	#boxx1a/8+bonusx+1,D3
	Move.w	#Boxy1a/8+bonusy+1,D4
	Move.w	#22,D5	
	Bsr	TraceBlocWithMask
	Movea.l	LevelAct,A6
	Clr.l	D3
	Move.w	Level_LongF(A6),D3
	Subq.w	#1,D3		Pour mini = 0 !
	Lsr.w	#1,D3		(N-1)/2 = Nombre de grosses cases !
	Moveq	#2,D6	2 chiffres
	Move.b	#' ',D7
	Bsr	STR	* Ne modifie pas : D0-D2/A0-A1/A3-A7
	Movea.l	A2,A1	Phrase
	Move.w	#boxx1a+bonusx*8+36,D0	96	(+36)
	Move.w	#boxy1a+bonusy*8+14,D1	10*8+4 = 84  (+14)
	Movea.l	FTinyTxt8,A0
	Bsr	AffichePhrase	A1:Phrase D0:X  D1:Y

	Movea.l	Planar,A1			BOMBES
	Move.w	#boxx1a/8+bonusx+1,D3	8,12
	Move.w	#Boxy1a/8+bonusy+2+1,D4
	Move.w	#23,D5	
	Bsr	TraceBlocWithMask
	Movea.l	LevelAct,A6
	Clr.l	D3
	Move.w	Level_NbB(A6),D3
	Moveq	#2,D6	2 chiffres
	Move.b	#' ',D7
	Bsr	STR
	Movea.l	A2,A1
	Move.w	#boxx1a+bonusx*8+36,D0	96	(+36)
	Move.w	#boxy1a+bonusy*8+14+16,D1	10*8+4 = 84  (+14)
	Movea.l	FTinyTxt8,A0
	Bsr	AffichePhrase	A1:Phrase D0:X  D1:Y

	Movea.l	Planar,A1			POUSSE-BOMBES
	Move.w	#boxx1a/8+bonusx+1,D3	8,14
	Move.w	#Boxy1a/8+bonusy+4+1,D4
	Move.w	#24,D5	
	Bsr	TraceBlocWithMask
	Movea.l	LevelAct,A6
	Movea.l	#Phrase_Oui,A1
	Move.w	Level_PousseB(A6),D3
	Bne.s	.NopPB
	Movea.l	#Phrase_Non,A1
.NopPB	Move.w	#boxx1a+bonusx*8+36,D0	96	(+36)
	Move.w	#boxy1a+bonusy*8+14+32,D1	10*8+4 = 84  (+14)
	Movea.l	FTinyTxt8,A0
	Bsr	AffichePhrase	A1:Phrase D0:X  D1:Y
	
	Moveq	#2,D0
	Bsr	MakePaletteEHB
	Bsr	RestoreWorkingScreenEHB

	Move.l	CopAdrBplCon0,A0
	CopMove	#%0111001000000001,#$100	BplCon0: 7 plans


	Move.w	#-1,LevelInfoState	0:Attente -1:Affiché 1:Déjà effacé
.TimerMAJ
	* à faire à chaque VBL sans la fenêtre d'état du level

.NoZer
*****************************************************************************
*                         TESTS DE FIN DE LEVEL                             *
*****************************************************************************
	
	Tst.w	WinnersPhase	0: Rien ne se passe
	Bne	WinnersPh	
	Tst.w	GameOver		FIN LEVEL Si: Temps global écoulé
	Beq.s	.NopFin		ou s'il ne reste que <=1 joueurs
	Tst.w	NbFlammesEnVie
	Bgt.s	.NopFin
	Tst.w	NBBombesEnVie
	Ble.s	.Fin
.NopFin	RTS
.Fin
	IFNE	Music_Activation
	Cmp.w	#20,P61_Master
	Ble.s	.NoR	
	Subq.w	#1,P61_Master
	ENDC
.NoR
	****************
	*Move.w	LvlEndFill,Temp1	$FFFF = -1
	*Move.w	ExeLevel,Temp2	=0
	*BSR	DEBUG
	****************

	Tst.w	ExeLevel
	Beq.s	.NoE
	Tst.w	LvlEndFill	-1:Fini  0:Pas Fini
	*Blt.s	.NoE
	*Move.w	#1,ExeLevel	On stoppe le massacre des blocs dès la fin du bloc actuel
.NoE	***** Pour la fin du jeu, on attend que les anims de mort soient terminées
	Move.l	LegoPtr,A0
	Clr.l	D3	
.LoopJ	Tst.w	Leg_Mort(A0)
	Beq.s	.NoCassos		0: Pas mort
	Blt.s	.OkJ		-1: Mort (>1:En cours)
	RTS			Si anim en cours... on attend
.NoCassos	Tst.w	Leg_TelePhase(A0)
	Beq.s	.OkJ		0: Pas téléporte
	RTS			Si anim en cours... on attend
.OkJ	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D3
	Cmp.w	#NbJoueurs,D3
	Blt.s	.LoopJ

	*************************************************************
.ContEndN	Cmp.w	#3,WinnersPhase	Au cas où l'interruption VBL
	Beq	.NopFin		ait eu lieu juste pour Test GameOver!

	Jsr	CopStatsT

	*RTS

	Move.w	#1,WinnersPhase	Phase suivante...
	Move.w	NbJoueursEnVie,D2
	Cmp.w	#1,D2		*** CAS II: Il ne reste qu'un joueur
	Bgt	.Egalite		>1: Egalité: Test à l'intérieur pour
	Blt	.Perdu		cas joueurs même équipe (Bra .win)
	Cmp.w	#2,NbJActMax	Pour victoire seulement si >1 joueur
	Blt	.Egalite		a joué...	(.Perdu ?)


	********* VICTOIRE : Il ne reste qu'un joueur

.Win	Moveq	#8,D3
	Move.w	#PriSonWin,D1	Priorité
	Clr.w	SampleLoops
	Bsr	PlaySon		SON victoire
	**************
	Clr.w	ExeSprite
	Move.l	#LastPhaseTime,AutoDecounter

	Clr.w	Anim_Type		0=Victoire
	
.LaunchAnim1 *** Initialisation des anims de fin des sprites
	Movea.l	LegoPtr,A0
	Clr.l	D3	N° Joueur actuel
	Clr.w	D4	Eq0
	Clr.w	D5	Eq1
	Bsr	ChooseAnim
.LoopJLA1	Move.w	D0,Leg_Im(A0)
	Tst.w	Leg_Mort(A0)
	Bne.s	.Mort1
	Tst.w	Leg_Activated(A0)
	Beq.s	.Mort1
	Bsr	ChooseAnim
	Lea	Victoires,A1
	Add.w	#1,(A1,D3.w*2)
	Add.l	#1,Leg_GamesWonT(A0)
	Move.w	D3,WinGuy
	Movem.w	D4-D5,-(A7)
	Bsr	AfficheVictoires	(D3/A0) Utilise D4/A1-A2
	Movem.w	(A7)+,D4-D5
	Jsr	CopStatsT

	**********************	BARRE JOUEURS: BOMBE EN OR
	Movem.l	A0-A1/D1/D3-D5,-(A7)
	Lea	BonusIdxHires,A1	Tableaux bonus... hires! hé oui
	Move.w	Leg_BarreBlocX(A0),D3
	Move.w	Leg_BarreY(A0),D4
	Move.w	#24,D5			
	Bsr	Bloc32x16cop
	Movem.l	(A7)+,A0-A1/D1/D3-D5
	***********************
	
	Btst	#0,D3	Joueur actuel
	Bne.s	.Eq1_2
.Eq0_2	Addq.w	#1,D4
	Bra.s	.EqA_2
.Eq1_2	Addq.w	#1,D5
.EqA_2
.Mort1	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D3
	Cmp.w	#NbJoueurs,D3
	Blt	.LoopJLA1

	Move.w	#-1,ExeSprite


	***********************	BRUIT bombe Or
	*Movem.l	A0-A1/D1/D3-D5,-(A7)
	*Moveq	#0,D3
	*Moveq	#PriSonBombeOr,D1
	*Clr.w	SampleLoops
	*Bsr	PlaySon
	*Movem.l	(A7)+,A0-A1/D1/D3-D5
	************************

	Tst.w	D4	******* TEST victoire équipe 1
	Beq.s	.NoWEq1
	Add.w	#1,VictoiresEq
	Moveq	#0,D3
	Bsr	AfficheVictoiresTeams	
	Cmp.w	#1,PlayerMode	Tst.w
	Bne.s	.NoWEq1		beq
	Cmp.w	#5,VictoiresEq
	Blt.s	.NoWEq1
	*Bra	.AffPODIUM
	Move.w	#-1,RequestForPodium	
	Bra	.OkAnim
.NoWEq1	Tst.w	D5	******* TEST victoire équipe 2
	Beq.s	.NoWEq2
	Add.w	#1,VictoiresEq+2
	Moveq	#1,D3
	Bsr	AfficheVictoiresTeams
	Cmp.w	#1,PlayerMode
	Bne.s	.NoWEq2		beq
	Cmp.w	#5,VictoiresEq+2
	Blt.s	.NoWEq2	
	*Bra	.AffPODIUM
	Move.w	#-1,RequestForPodium	
	Bra	.OkAnim
.NoWEq2	Cmp.w	#1,PlayerMode
	Beq.s	.Tim
	Move.w	WinGuy,D0	
	Lea	Victoires,A1
	Move.w	(A1,D0.w*2),D0
	Divu.w	#5,D0	5/5=1 reste 0   10/5=2 reste 0
	Swap	D0
	Tst.w	D0	Si reste=0, alors 5 parties écoulées
	Bne.s	.Tim
	Tst.w	GameMode		1=5 win match
	Beq.s	.Tim	
	* 5 victoires: podium mais seulement en mode 5 win match
	Move.w	#-1,RequestForPodium	
.Tim	Bra	.OkAnim


	********* EGALITE : Il reste au moins 2 joueurs

.Egalite	Move.l	#LastPhaseTime,AutoDecounter

	*Move.w	#ImDebFin1,D0	Anim mec montre poing

	Move.w	#1,Anim_Type	1=égalité
	
.LaunchAnim2 *** Initialisation des anims de fin des sprites
	* D4: Eq 0
	* D5: Eq 1
	Clr.w	ExeSprite
	Movea.l	LegoPtr,A0
	Clr.l	D3
	Clr.w	D4
	Clr.w	D5	
	Moveq	#-1,D6
	Bsr	ChooseAnim
.LoopJLA2	Move.w	D0,Leg_Im(A0)
	Tst.w	Leg_Mort(A0)		Mecs vivants même équipe ?
	Bne.s	.Mort2
	Tst.w	Leg_Activated(A0)
	Beq.s	.Mort2
	Bsr	ChooseAnim
	Btst	#0,D3
	Bne.s	.Eq1
	Addq.w	#1,D4
	Bra.s	.Mort2
.Eq1	Addq.w	#1,D5
.Mort2	Adda.w	#Leg_SizeOf,A0
	Addq.w	#1,D3
	Cmp.w	#NbJoueurs,D3
	Blt.s	.LoopJLA2
	Cmp.w	#1,PlayerMode	0:Individual 1:Teams
	Bne.s	.OkAnimAv		EGALITE confirmée

	* On teste si les joueurs restants sont dans la même équipe
	* pour le mode équipe. Auquel cas ce n'est pas une égalité
	* mais une victoire.	
	Tst.w	D4		N° équipe= joueur and $0001
	Beq.s	.NoEq1W
	Tst.w	D5
	Beq	.Win		Branchement WIN: EGALITE non fondée
	Bra.s	.OkAnimAv
.NoEq1W	Tst.w	D5		D4=0 + D5=1 (LaunchAnim1 ?)
	Bne	.Win		Branchement WIN: EGALITE non fondée
.OkAnimAv	Movem.l	A0-A1/D1/D3-D5,-(A7)
	Moveq	#9,D3		SON
	Move.w	#PriSonWin,D1	Priorité
	Clr.w	SampleLoops
	Bsr	PlaySon
	Movem.l	(A7)+,A0-A1/D1/D3-D5
.OkAnim	Move.w	#2,WinnersPhase	2: Animation de fin en cours
	Move.w	#-1,ExeSprite
	RTS


	********* TOUS LES JOUEURS SONT MORTS

.Perdu	Movem.l	A0-A1/D1/D3-D5,-(A7)
	Moveq	#9,D3		JUSTE UN SON
	Move.w	#PriSonWin,D1	Priorité
	Clr.w	SampleLoops
	Bsr	PlaySon		Aucune animation: personne visible!
	Movem.l	(A7)+,A0-A1/D1/D3-D5
	Move.l	#LastPhaseTime,AutoDecounter	
	RTS


****************** Choisir une animation en fonction du mode Winner/Egalité
ChooseAnim
	Tst.w	Anim_Type
	Bne.s	.Eg
	Move.l	Anim_Act0,A3
.RW	Move.w	(A3)+,D0
	Bne.s	.OkW
	Move.l	#Winning_List,A3
	Bra.s	.RW
.OkW	Move.l	A3,Anim_Act0
	Bra.s	.Al
.Eg	Move.w	NbJActMax,A3
	Cmp.w	#1,A3
	Bgt.s	.EgN
	Move.w	#ImDebFin1,D0	Mec montre poing
	Bra.s	.Al
.EgN	Move.l	Anim_Act1,A3
.REg	Move.w	(A3)+,D0
	Bne.s	.OkE
	Move.l	#Egalite_List,A3
	Bra.s	.REg
.OkE	Move.l	A3,Anim_Act1
.Al	RTS

******************* On doit gérer le jeu pendant les animations
*
*
WinnersPh	
	Cmp.w	#3,WinnersPhase
	Beq.s	.Nop
	Tst.l	AutoDecounter
	Bgt.s	.Nop
	* On a terminé : Fading au noir
	Move.w	#-1,GameOver	ANTIBUG Si GameOver=0 et WinnersPh<>0
	Movem.l	D0-D1,-(A7)
	Bsr	TestInputs
	Movem.l	(A7)+,D0-D1
	Tst.w	D4
	Beq.s	.Nop		Aucun feu enclenché
	Jsr	InitsDontMove
	Clr.w	ExeSprite
	Tst.w	RequestForPodium		PODIUM...
	Beq.s	.NoPodium
	Clr.w	RequestForPodium		
	Bra	LaunchAffPodium
.NoPodium	Move.w	#1,TypTouche	Regénérer un nouveau level si "Random"
	Move.w	#-1,RequestForNewLevel	ou NOUVEAU LEVEL...
.Nop	RTS


******************* On doit lancer le PODIUM et sauter au menu !
*
* On pourrait par exemple venir ici tous les 5 matchs en
* mode free play et donc dans ce cas ne pas retourner au menu.(?) 
*
*
LaunchAffPODIUM
	Jsr	AFF_PODIUM
	*Bsr	STATISTIQUES
	Adda.l	#2*4,A7		Bsr Gestion, Bsr TestLevelEnd 
	Jmp	ORCHESTRE2

GosubAffPODIUM
	Jsr	AFF_PODIUM
	Jsr	InitsDontMove
	RTS
	


*****************	Gérer la pause du jeu

PAUSE	Clr.w	ExeSprite		Plus de sprites
	Move.w	ExeLevel,TempExe	Plus de temps de level
	Clr.w	ExeLevel

	********************	Message écran bois
	Jsr	BClearBois
	Move.w	#0,D0		X de début centrage
	Move.w	#5,D1
	Movea.l	FTinyTxt8,A0
	Lea	Phrase_Pause,A1
	Move.w	#320,D3		Largeur écran
	Bsr	CenterX
	Bsr	AffichePhraseBarre2	(D0-D1/A0-A1) MODULE
	Bsr	Set4
	Move.l	#Heure*5,BarreDecounter
	********************
	
	IFNE	Music_Activation
	 Move.w	#5,P61_Master		Musique en sourdine
	ENDC
	Move.l	ClavierPtr,A0
.Pause	Tst.b	25(A0)	Attend relachement
	Bne.s	.Pause
.Pause2	Tst.b	69(A0)
	Bne.s	.QuitP
	Tst.b	25(A0)	Attend appui
	Beq.s	.Pause2
.Pause3	Tst.b	25(A0)	Attend relachement
	Bne.s	.Pause3
.QuitP	
	Move.l	#0,BarreDecounter
	*VblWait	#200
	*VblWait	#100
	Jsr	BClearBois
	Bsr	Set3
	IFNE 	Music_Activation
	 Move.w	MusicVol,P61_Master		Musique Full
	ENDC
	Move.w	#1,ExeSprite		Sprites ON
	Move.w	TempExe,ExeLevel		récupération état level
	RTS


*
* 
*	CHARGEMENT DE TOUS LES LEVELS EN MEMOIRE
*
*

LoadLevels

	*** Ouverture du DOS pour affichage... (Surtout DEBUG)
	*
	Move.l	$4.w,A6
	Lea	DosName,A1
	Clr.l	D0
	Jsr	-$228(A6)		OpenDos
	Move.l	D0,DosBase
	Beq	.ErrDos
	Move.l	D0,A6
	Jsr	_LVOOutPut(A6)
	Move.l	D0,DefOutPut
	Beq	.ClosDos	
	
	Move.l	#OK_Load,D2
	*Jsr	Print
	

	*** Chargement des fichiers Levels
	*
	Lea	Levels,A0		Adresse travail
	Movea.l	A0,A2
	Move.l	#LevelsPtrZone/8-1,D0	Taille travail
.ClrZLvl	Clr.l	(A0)
	Adda.w	#8,A0		Ne pas effacer l'activation ON/OFF!
	Dbf	D0,.ClrZLvl	

	Lea	LevelsN,A0	binary/lego_level000.dat
	Lea	17(A0),A1		000
	Moveq	#48,D0
	Move.b	D0,(A1)
	Move.b	D0,1(A1)
	Move.b	D0,2(A1)
	Movea.l	A2,A4		A4: Constituer l'adresse "limite"
	Adda.w	#LevelsPtrZone,A4
	* D5,D6,D7
	Clr.l	D5
.LoopW	* Boucle sur les Worlds (D5=0...5+999 pour 1 level dyna)
	Movea.l	A2,A3		Adresse "Levels"
	Move.w	D5,D0
	Add.w	#48,D0		0-> "0"  1-> "1" ...
	Move.b	D0,(A1)		000,100,200,300,400,500	
	Moveq	#1,D6
.LoopLvl	* Boucle sur les Levels (D6=1...NbLevelsParWorld)

	* Vérifier que l'adresse est bien dans la zone Levels
	Cmpa.l	A3,A4
	Bgt.s	.OkPosMem
	Bsr	PrintStateAbort	
	Bra.s	.EndLoopW
.OkPosMem
	
	* Constituer le nom du fichier
	Move.l	D6,D0	
	Divu.w	#10,D0
	Add.w	#48,D0	Dividende: Dizaines
	Move.b	D0,1(A1)
	Swap	D0	Reste: Unités
	Add.w	#48,D0
	Move.b	D0,2(A1)		
		
	** Chargement du fichier lui même
	Moveq	#Memf_Public,D1
	Movem.l	A0-A1,-(A7)
	Jsr	ChargeFichier	A0/D1 -> A1/D0
	Move.l	A1,D1
	Movem.l	(A7)+,A0-A1

	Tst.l	D0
	Bne.s	.FOk
	Clr.l	D1	Erreur de fichier: Pointeur = 0
	Bsr 	PrintStateErr
	Bra.s	.Fall
.FOk	Bsr 	PrintStateOk

	Move.l	A0,-(A7)
	Move.l	D0,D7	Taille	
	Move.l	D1,D0	Adresse
	Jsr	AddStack	Pour rendu de mémoire automatique
	Move.l	(A7)+,A0

.FAll	Move.l	D1,(A3)
	Adda.w	#8,A3
	**

	Addq.w	#1,D6
	Cmp.w	#NbLevelsParWorld,D6
	Ble.s	.LoopLvl

	Adda.w	#NbLevelsParWorld*2*4,A2	Nouveau monde	
	Addq.w	#1,D5
	Cmp.w	#5,D5
	Ble.s	.LoopW
.EndLoopW					


.ClosDos
	Movea.l	$4.w,A6
	Move.l	DosBase,A1
	Jsr	-$19E(A6)
.ErrDos
	RTS	
	
	
PrintStateErr
	RTS

	*** Erreur de chargement d'un fichier
	Move.l	#Err_Load,D2
	Jsr	Print
	Move.l	A0,D2
	Jsr	Print	Sauve: D0-D1/D3/A0-A4,-(A7)
	Move.l	#Err_END,D2
	Jsr	Print
	RTS

PrintStateOK
	RTS

	*** Chargement d'un fichier effectué
	Move.l	#OK_LoadP,D2
	Jsr	Print

	RTS

	Move.l	A0,D2
	Jsr	Print
	Move.l	#Err_END,D2
	Jsr	Print
	RTS
	
PrintStateAbort
	*** Annulation
	Move.l	#Err_Abort,D2
	Jsr	Print
	RTS
	
	
