*
* Le clavier fonctionne de manière simple: l'interruption met à
* jour un tableau représentant toutes les touches du clavier, et il 
* suffit de tester au moment opportun ce tableau.
* Il y a deux interruptions: une d'appui sur la touche, et une de 
* relâchement de la touche.
*
*
IntRoutine2 *** CLAVIER
	Movem.l	D0-D3/A0-A1,-(A7)
	Moveq	#127,D0
	Clr.l	D1
 	Move.b	$bfec01,D1
	Move.w	SomClav,D3
	Addq.w	#1,D3
	Clr.l	D2
	Lsr.b	#1,D1	
	Addx.l	D2,D2	recupère le bit 0 de $bfec01
	Bne.s	.App	1: on appuie sur la touche
.Lach	Subq.w	#2,D3
	Bge.s	.App
	Clr.w	D3	0: on relâche la touche
.App	Sub.b	D1,D0	127-Code = Vrai code (= AMOS quoi !)
	Movea.l	ClavierPtr,A0
	And.w	#$FF,D0
	Lea	(A0,D0.w),A1
	* Sauvegarde ancienne valeur dans tableau 2 à la suite
	*Move.b	(A1),128(A1) 	Ancienne valeur stockée
	Move.b	D2,(A1)
	*** Spécial pour les cheatcodes
	Tst.b	D2
	Beq	.End
	Tst.l	CHEAT_ENABLED
	Bne	.End
	Movea.l	CHEAT_PTR,A1
	Cmp.b	(A1),D0
	Beq.s	.OkC
	Cmp.b	-1(A1),D0
	Beq.s	.Dej
	Move.l	#CHEAT_SEQUENCE,CHEAT_PTR
	Bra.s	.Dej	
.OkC	Adda.w	#1,A1
	Tst.b	(A1)
	Bne.s	.Nop
	Move.l	#3,CHEAT_ENABLED
.Nop	Move.l	A1,CHEAT_PTR	
.Dej
	*** Spécial pour la répétition des touches
.End	Move.w	D3,SomClav
	Movem.l	(A7)+,D0-D3/A0-A1
	Lea	$dff000,a0
	RTS

* 58 -> 69	127-58 = 69
* 63 -> 64	127-63 = 64
* 127-C

* INTERRUPTION:
* On peut virer D0-D1/A0-A1/A5-A6
* DONC 	Movem.l	D2-D7/A2-A4,-(A7)
*	Movem.l	(A7)+,D2-D7/A2-A4
*
*
