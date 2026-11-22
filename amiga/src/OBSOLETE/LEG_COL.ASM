**************************************
*    ROUTINE DE LEGOBLAST by GOGO    *
**************************************
* Gestion des collisions de 2-8 joueurs.
*
* Compte tenu du fait que je me fous de l'ordre mais que je veux
* juste trouver les joueurs qui sont sur la mˆme case, je fais ‡a simple.
*
*
ColJoue * Movem.l
        Clr.l   D7              Nombre de joueurs en vie (nbjoueursenvie ?)
        Move.l  LegoPtr,A4
        Lea     TriJoueWork,A2
        Movea.l A2,A3
        Moveq #nbjoueurs-1,D4
.LoopJ  Tst.w   Leg_Mort(A4)
        Bne.s   .nop
        Tst.w   Leg_TelePhase(A4)       pas de contact si t‚l‚porte
        Bne.s   .nop
        Tst.w   Leg_Activated(A4)
        Bge.s   .nop
        * Joueur accept‚ pour le test des collisions
        * ?
        Bsr     FindOffsetFromXY     
        * ?
        Move.w  D4,(A2)+        Offset en cases, donc max 63*64<32768
        Move.l  A1,(A2)+
        Tst.w   D7
        Beq.s   .Nop
        Movea.l A3,A1
        Move.l  D7,D6
        Addq.w  #1,D7
.ChchSame
        Cmp.w   D4,(A1)
        Bne.s   .NexCh
        Move.l  2(A1),A5
        * ?
        Bsr     DonneMalad      (A4,A5)
        * ?
.NexCh  Adda.w  #6,A1
        Dbf     D6,.ChchSame

.Nop
        Adda.w  #Leg_SizeOf,A1
        Dbf     D4,.LoopJ


        RTS
