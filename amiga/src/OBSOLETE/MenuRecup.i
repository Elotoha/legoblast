MENU                MOVE.L         #$2800,VARSIZEPLAN
                    MOVE.L         #$28,VARSIZELINE
                    MOVE.W         MUSICVOL,MUSICVOLBACK
                    CLR.W          FADEBTW_BREAKENABLE
                    MOVEQ          #$3,D0
                    BSR.L          FREEPIC
                    MOVEQ          #$0,D0
                    BSR.L          LAUNCHZIK
                    MOVE.L         #-$1,DO_NOT_RETAKE_SYSTEM
                    MOVEQ          #$1,D0
                    BSR.L          CHARGEPIC
                    MOVEQ          #$2,D0
                    BSR.L          CHARGEPIC
                    MOVE.W         #$4,D0
L8976               BSR.L          CHARGEPIC
                    ADDQ.W         #$1,D0
                    CMP.W          #$5,D0
                    BLE.S          L8976
                    CLR.L          DO_NOT_RETAKE_SYSTEM
                    BSR.L          TEMP_TAKE_SYSTEM
                    MOVE.W         #$40,MUSICVOL
                    MOVEQ          #$9,D0
                    BSR.L          LAUNCHZIK
                    MOVE.L         #$4,P61_CHANNELS
                    MOVE.L         #$4,SLIDEPICACT
                    BSR.L          MAIN_MENU
                    BSR.L          FREEMENUDATA
                    RTS

FREEALLPICS         MOVEQ          #$9,D0
L89BA               BSR.L          FREEPIC
                    DBRA           D0,L89BA
                    RTS

FREEPIC             MOVEM.L        D0-D7/A0-A6,-(SP)
                    LEA            PICTURESDEF,A0
                    MULU.W         #$C,D0
                    LEA            $0(A0,D0.W),A0
                    MOVEA.L        $0(A0),A1
                    TST.L          A1
                    BEQ.S          L89EE
                    CLR.L          $0(A0)
                    MOVE.L         $4(A0),D0
                    MOVEA.L        $4,A6
                    JSR            -$D2(A6)
L89EE               MOVEM.L        (SP)+,D0-D7/A0-A6
                    RTS

CHARGEPIC           MOVEM.L        D0-D7/A0-A6,-(SP)
                    LEA            PICTURESDEF,A1
                    MULU.W         #$C,D0
                    LEA            $0(A1,D0.W),A1
                    TST.L          $0(A1)
                    BNE.S          L8A32
                    MOVEA.L        $8(A1),A0
                    MOVE.L         #$10001,D1
                    MOVE.L         A1,-(SP)
                    BSR.L          TEMP_RESTORE_SYSTEM
                    JSR            CHARGEFICHIER
                    BSR.L          TEMP_TAKE_SYSTEM
                    MOVEA.L        (SP)+,A2
                    MOVE.L         D0,$4(A2)
                    BEQ.S          L8A32
                    MOVE.L         A1,$0(A2)
L8A32               MOVEM.L        (SP)+,D0-D7/A0-A6
                    RTS

CHARGECRP           MOVEM.L        D0-D7/A0-A6,-(SP)
                    LEA            PICTURESDEF,A1
                    MULU.W         #$C,D0
                    LEA            $0(A1,D0.W),A1
                    TST.L          $0(A1)
                    BNE.S          L8A76
                    MOVEA.L        $8(A1),A0
                    MOVE.L         #$10001,D1
                    MOVE.L         A1,-(SP)
                    BSR.L          TEMP_RESTORE_SYSTEM
                    JSR            CHARGEFICHIER
                    BSR.L          TEMP_TAKE_SYSTEM
                    MOVEA.L        (SP)+,A2
                    MOVE.L         D0,$4(A2)
                    BEQ.S          L8A76
                    MOVE.L         A1,$0(A2)
L8A76               MOVEM.L        (SP)+,D0-D7/A0-A6
                    RTS

MAIN_MENU           CLR.W          CYCLE_ACTIVATE
                    LEA            PLAYERSSET,A1
                    CLR.L          (A1)+
                    CLR.L          (A1)
                    CLR.W          NBJOUEURSACT
                    LEA            JOYLIST,A1
L8A98               TST.L          (A1)+
                    BEQ.S          L8AA0
                    CLR.W          (A1)+
                    BRA.S          L8A98
L8AA0               MOVE.W         #$20,D0
                    MOVE.W         #$3F,D1
                    MOVE.W         DEGRADEMENUA,D2
                    LEA            MENUACOL,A0
                    BSR.L          MAKEDEGRAD
                    MOVE.L         L45524,MENUACOL
                    LEA            MENUACOL,A0
                    MOVE.L         #$80,D0
                    LEA            LA098,A3
                    MOVEA.L        $0(A3),A3
                    MOVE.L         A3,PICPTR
                    TST.L          A3
                    BEQ.L          QUITMENU
                    MOVEQ          #$7,D1
                    MOVE.L         #$2800,D2
                    MOVEA.L        PLANAR,A2
                    MOVE.L         #$2800,D3
                    BSR.L          DISPLAYPIC2
                    MOVEQ          #$0,D2
                    MOVE.W         D2,D3
                    MULU.W         #$2D0,D3
                    ADDI.L         #$DA7,D3
                    BSR.L          BOBONMAIN
                    MOVE.W         #$0,$DFF108
                    MOVE.W         #$0,$DFF10A
                    MOVEA.L        PLANAR,A2
                    BSR.L          DISPLAYPIC2GO
                    MOVEM.L        D0-D7/A0-A6,-(SP)
                    MOVEA.L        #(PALSRC),A0
                    MOVEA.L        #(MENUACOL),A1
                    MOVEA.L        #(PALVEC),A2
                    MOVEA.L        #(PALACT),A4
                    MOVE.L         #$80,D0
                    MOVE.L         #$F,D1
                    BSR.L          FADEBETWEEN_RUN
                    MOVEA.L        #(MENUACOL),A0
                    MOVE.L         #$80,D0
                    JSR            MAKEPALETTENEW
                    MOVEM.L        (SP)+,D0-D7/A0-A6
                    CLR.W          CYCLE_WAIT
                    MOVE.W         #$5,CYCLE_SPEED
                    MOVE.W         #$60,CYCLE_FIRSTCOUL
                    MOVE.W         #$6F,CYCLE_LASTCOUL
                    MOVE.L         #(MENUACOL),CYCLE_PALADR
                    MOVE.W         #$1,CYCLE_ACTIVATE
                    CLR.L          AUTOCOUNTER
                    MOVE.L         D2,-(SP)
NOFIRE1             MOVE.L         D0,-(SP)
                    MOVE.L         #$1,D0
L8BAA               MOVE.L         D2,-(SP)
L8BAC               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$C8,D2
                    BNE.S          L8BAC
                    MOVE.L         (SP)+,D2
                    MOVE.L         D2,-(SP)
L8BC4               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$DC,D2
                    BNE.S          L8BC4
                    MOVE.L         (SP)+,D2
                    DBRA           D0,L8BAA
                    MOVE.L         (SP)+,D0
                    BSR.L          TESTINPUTS
                    TST.W          D4
                    BNE.S          NOFIRE1
                    MOVE.L         (SP)+,D2
MAIN_LOOP           MOVE.L         D2,-(SP)
L8BEC               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$2D,D2
                    BNE.S          L8BEC
                    MOVE.L         (SP)+,D2
                    MOVE.L         A0,-(SP)
                    MOVEA.L        CLAVIERPTR,A0
                    TST.B          $50(A0)
                    BEQ.S          L8C1A
                    MOVE.L         #$1,P61_CHANNELS
L8C1A               TST.B          $51(A0)
                    BEQ.S          L8C2A
                    MOVE.L         #$2,P61_CHANNELS
L8C2A               TST.B          $52(A0)
                    BEQ.S          L8C3A
                    MOVE.L         #$3,P61_CHANNELS
L8C3A               TST.B          $53(A0)
                    BEQ.S          L8C4A
                    MOVE.L         #$4,P61_CHANNELS
L8C4A               MOVEA.L        (SP)+,A0
                    MOVE.W         #-$1,CYCLE_ACTIVATE
                    MOVEA.L        CLAVIERPTR,A1
                    TST.B          $5F(A1)
                    BEQ.S          L8C6C
                    MOVE.L         #$5,SLIDEPICACT
                    BRA.S          L8C84
L8C6C               MOVE.L         AUTOCOUNTER,D3
                    CMP.L          #$3E8,D3
                    BLT.S          L8C9A
                    MOVE.L         #$4,SLIDEPICACT
L8C84               CLR.L          AUTOCOUNTER
                    CLR.W          CYCLE_ACTIVATE
                    JSR            SLIDE1
                    BRA.L          MAIN_MENU
L8C9A               BSR.L          TESTINPUTS
                    TST.W          D4
                    BNE.L          L8D22
                    TST.W          D1
                    BEQ.L          L8D1E
                    ADD.W          D2,D1
                    BLT.L          L8D1E
                    CMP.W          #$2,D1
                    BGT.L          L8D1E
                    CLR.L          AUTOCOUNTER
                    BSR.L          BOBOFFMAIN
                    MOVE.W         D1,D2
                    MOVE.W         D2,D3
                    MULU.W         #$2D0,D3
                    ADDI.L         #$DA7,D3
                    BSR.L          BOBONMAIN
                    MOVE.L         D0,-(SP)
                    MOVE.L         #$4,D0
L8CDC               MOVE.L         D2,-(SP)
L8CDE               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$C8,D2
                    BNE.S          L8CDE
                    MOVE.L         (SP)+,D2
                    MOVE.L         D2,-(SP)
L8CF6               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$DC,D2
                    BNE.S          L8CF6
                    MOVE.L         (SP)+,D2
                    DBRA           D0,L8CDC
                    MOVE.L         (SP)+,D0
L8D12               BSR.L          TESTINPUTS
                    TST.W          D4
                    BNE.S          L8D22
                    TST.W          D1
                    BNE.S          L8D12
L8D1E               BRA.L          MAIN_LOOP
L8D22               MOVE.L         D2,-(SP)
                    MOVEA.L        #(PALSRC),A0
                    MOVE.L         #$80,D0
                    CLR.L          D1
                    CMP.W          #$1,D2
                    BNE.S          L8D3E
                    MOVE.L         MENUACOL,D1
L8D3E               BSR.L          PALCLR
                    MOVEA.L        #(MENUACOL),A0
                    MOVEA.L        #(PALSRC),A1
                    MOVEA.L        #(PALVEC),A2
                    MOVEA.L        #(PALACT),A4
                    MOVE.L         #$80,D0
                    MOVE.L         (SP)+,D2
                    CMP.W          #$2,D2
                    BEQ.L          QUITMENU
                    MOVE.L         D2,-(SP)
                    MOVE.L         #$14,D1
                    CMP.W          #$0,D2
                    BEQ.S          L8D7E
                    BSR.L          FADEBETWEEN_RUN
                    BRA.S          L8D82
L8D7E               BSR.L          FADEBETWEENMUSIC_RUN
L8D82               MOVEA.L        #(PALSRC),A0
                    MOVE.L         #$80,D0
                    JSR            MAKEPALETTENEW
                    MOVE.L         (SP)+,D2
                    CMP.W          #$1,D2
                    BEQ.L          OPTIONS_MENU
                    BSR.L          BOBOFFMAIN
                    JSR            CLSALL
                    MOVE.L         #-$1,PALETTE_IN_PROGRESS
                    LEA            PALJAUGE,A0
                    MOVE.L         #$80,D0
                    CLR.L          D7
                    JSR            MAKEPALETTENEW
                    CLR.L          PALETTE_IN_PROGRESS
                    LEA            FMOB8,A0
                    LEA            OPT_LOADING,A1
                    MOVEA.L        PLANAR,A2
                    MOVE.W         #$6D,D0
                    MOVE.W         #$72,D1
                    MOVEQ          #$1F,D2
                    MOVEQ          #$7,D7
                    MOVE.L         #$2800,VARSIZEPLAN
                    MOVE.L         #$28,VARSIZELINE
                    BSR.L          GPRINT
                    RTS

QUITMENU            MOVE.L         D2,-(SP)
                    MOVE.L         #$64,D1
                    BSR.L          FADEBETWEENMUSIC_RUN
                    MOVEA.L        #(PALSRC),A0
                    MOVE.L         #$80,D0
                    JSR            MAKEPALETTENEW
                    MOVE.L         (SP)+,D2
                    BSR.L          FREEMENUDATA
                    ADDA.W         #$8,SP
                    BRA.L          QUIT
OPTIONS_MENU        CLR.W          CYCLE_ACTIVATE
                    MOVE.W         #$20,D0
                    MOVE.W         #$3F,D1
                    MOVE.W         DEGRADEMENUB,D2
                    LEA            MENUBCOL,A0
                    BSR.L          MAKEDEGRAD
                    MOVE.L         L45724,MENUBCOL
                    LEA            MENUBCOL,A0
                    MOVE.L         #$80,D0
                    LEA            LA0A4,A3
                    MOVEA.L        $0(A3),A3
                    MOVE.L         A3,PICPTR
                    TST.L          A3
                    BEQ.L          MAIN_MENU
                    MOVEQ          #$7,D1
                    MOVE.L         #$2800,D2
                    MOVEA.L        PLANAR,A2
                    MOVE.L         #$2800,D3
                    BSR.L          DISPLAYPIC2
                    BSR.L          CLS1
                    BSR.L          CLS2
                    BSR.L          CLS3
                    BSR.L          CLS4
                    BSR.L          CLS5
                    BSR.L          CLS6
                    BSR.L          CLS7
                    JSR            VERIF_POINTEURS_MENU
                    BSR.L          AFFARENAZONE
                    BSR.L          AFFARENAMODE
                    BSR.L          AFFMODEJEU
                    BSR.L          AFFMODEPLAYER
                    BSR.L          AFFCONTROL
                    BSR.L          AFFDEFINITION
                    MOVEQ          #$1,D2
                    MOVEQ          #$1,D3
                    BSR.L          BOBONOPT
                    MOVEA.L        PLANAR,A2
                    BSR.L          DISPLAYPIC2GO
                    MOVEM.L        D0-D7/A0-A6,-(SP)
                    MOVEA.L        #(PALSRC),A0
                    MOVEA.L        #(MENUBCOL),A1
                    MOVEA.L        #(PALVEC),A2
                    MOVEA.L        #(PALACT),A4
                    MOVE.L         #$80,D0
                    MOVE.L         #$F,D1
                    BSR.L          FADEBETWEEN_RUN
                    MOVEA.L        #(MENUBCOL),A0
                    MOVE.L         #$80,D0
                    JSR            MAKEPALETTENEW
                    MOVEM.L        (SP)+,D0-D7/A0-A6
                    CLR.W          CYCLE_WAIT
                    MOVE.W         #$5,CYCLE_SPEED
                    MOVE.W         #$60,CYCLE_FIRSTCOUL
                    MOVE.W         #$6F,CYCLE_LASTCOUL
                    MOVE.L         #(MENUBCOL),CYCLE_PALADR
                    MOVE.W         #$1,CYCLE_ACTIVATE
NOFIRE2             MOVE.L         D0,-(SP)
                    MOVE.L         #$1,D0
L8F58               MOVE.L         D2,-(SP)
L8F5A               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$C8,D2
                    BNE.S          L8F5A
                    MOVE.L         (SP)+,D2
                    MOVE.L         D2,-(SP)
L8F72               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$DC,D2
                    BNE.S          L8F72
                    MOVE.L         (SP)+,D2
                    DBRA           D0,L8F58
                    MOVE.L         (SP)+,D0
                    BSR.L          TESTINPUTS
                    TST.W          D4
                    BNE.S          NOFIRE2
MAIN_LOOP2          MOVE.L         D2,-(SP)
L8F98               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$2D,D2
                    BNE.S          L8F98
                    MOVE.L         (SP)+,D2
                    MOVE.W         #-$1,CYCLE_ACTIVATE
                    BSR.L          TESTINPUTS
                    TST.W          D4
                    BNE.L          L9052
                    CLR.L          D7
                    TST.W          D1
                    BEQ.L          L8FE2
                    ADD.W          D3,D1
                    BLT.L          L8FE2
                    CMP.W          #$1,D1
                    BGT.L          L8FE2
                    TST.W          D1
                    BEQ.S          L8FDE
                    MOVEQ          #$1,D2
                    CLR.W          D0
L8FDE               MOVE.W         D1,D3
                    MOVEQ          #-$1,D7
L8FE2               TST.W          D0
                    BEQ.L          L9002
                    ADD.W          D2,D0
                    BLT.L          L9002
                    CMP.W          #$1,D0
                    BGT.L          L9002
                    TST.W          D0
                    BGT.S          L8FFE
                    TST.W          D3
                    BGT.S          L9002
L8FFE               MOVE.W         D0,D2
                    MOVEQ          #-$1,D7
L9002               TST.W          D7
                    BEQ.L          L904E
                    BSR.L          BOBOFFOPT
                    BSR.L          BOBONOPT
                    MOVE.L         D0,-(SP)
                    MOVE.L         #$1,D0
L9018               MOVE.L         D2,-(SP)
L901A               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$C8,D2
                    BNE.S          L901A
                    MOVE.L         (SP)+,D2
                    MOVE.L         D2,-(SP)
L9032               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$DC,D2
                    BNE.S          L9032
                    MOVE.L         (SP)+,D2
                    DBRA           D0,L9018
                    MOVE.L         (SP)+,D0
L904E               BRA.L          MAIN_LOOP2
L9052               MOVEM.W        D2-D3,SAUVEOPTMAIN
                    ADD.W          D3,D3
                    ADD.W          D2,D3
                    CMP.W          #$3,D3
                    BEQ.L          MAIN_MENU_RETURN
                    BSR.L          BOBOFFOPT
                    CMP.W          #$0,D3
                    BEQ.L          ARENA_MENU
                    CMP.W          #$1,D3
                    BEQ.L          PLAYERS_MENU
CONTINUEMAINOPT     MOVEM.W        SAUVEOPTMAIN,D2-D3
                    BSR.L          BOBONOPT
                    BRA.L          NOFIRE2
MAIN_MENU_RETURN    MOVEA.L        #(PALSRC),A0
                    MOVE.L         #$80,D0
                    MOVE.L         MENUBCOL,D1
                    BSR.L          PALCLR
                    MOVEA.L        #(MENUBCOL),A0
                    MOVEA.L        #(PALSRC),A1
                    MOVEA.L        #(PALVEC),A2
                    MOVEA.L        #(PALACT),A4
                    MOVE.L         #$80,D0
                    MOVE.L         #$5,D1
                    BSR.L          FADEBETWEEN_RUN
                    MOVEA.L        #(PALSRC),A0
                    MOVE.L         #$80,D0
                    JSR            MAKEPALETTENEW
                    BRA.L          MAIN_MENU
ARENA_MENU          MOVEQ          #$0,D3
                    BSR.L          BOBONOPTINA
NOFIRE3             MOVE.L         D0,-(SP)
                    MOVE.L         #$1,D0
L90EC               MOVE.L         D2,-(SP)
L90EE               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$C8,D2
                    BNE.S          L90EE
                    MOVE.L         (SP)+,D2
                    MOVE.L         D2,-(SP)
L9106               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$DC,D2
                    BNE.S          L9106
                    MOVE.L         (SP)+,D2
                    DBRA           D0,L90EC
                    MOVE.L         (SP)+,D0
                    BSR.L          TESTINPUTS
                    TST.W          D4
                    BNE.S          NOFIRE3
                    CLR.W          OLDDIRX
MAIN_LOOP3          MOVE.L         D2,-(SP)
L9132               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$2D,D2
                    BNE.S          L9132
                    MOVE.L         (SP)+,D2
                    MOVE.W         #$1,CYCLE_ACTIVATE
                    BSR.L          TESTINPUTS
                    CMP.W          OLDDIRX,D0
                    BEQ.S          L9166
                    MOVE.W         D0,OLDDIRX
                    BSR.L          INITKEYS
L9166               TST.W          D1
                    BEQ.S          L91C8
                    ADD.W          D3,D1
                    BLT.S          L91D8
                    CMP.W          #$2,D1
                    BGT.S          L91D8
                    MOVE.W         D1,D3
                    BSR.L          BOBOFFOPT
                    BSR.L          BOBONOPTINA
                    MOVE.L         D0,-(SP)
                    MOVE.L         #$4,D0
L9186               MOVE.L         D2,-(SP)
L9188               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$C8,D2
                    BNE.S          L9188
                    MOVE.L         (SP)+,D2
                    MOVE.L         D2,-(SP)
L91A0               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$DC,D2
                    BNE.S          L91A0
                    MOVE.L         (SP)+,D2
                    DBRA           D0,L9186
                    MOVE.L         (SP)+,D0
L91BC               BSR.L          TESTINPUTS
                    TST.W          D1
                    BNE.S          L91BC
                    BRA.L          MAIN_LOOP3
L91C8               TST.W          D4
                    BNE.L          L91F4
                    TST.W          D0
                    BNE.L          L920E
                    BRA.L          MAIN_LOOP3
L91D8               TST.W          D3
                    BLE.S          L91EC
                    LEA            SAUVEOPTMAIN,A0
                    MOVE.W         #$1,(A0)
                    MOVE.W         #$1,$2(A0)
L91EC               BSR.L          BOBOFFOPT
                    BRA.L          CONTINUEMAINOPT
L91F4               CMP.W          #$1,D3
                    BNE.L          NOFIRE3
                    MOVEA.L        MENUPTROPTA1,A0
                    NOT.W          $4(A0)
                    BSR.L          AFFARENAZONE
                    BRA.L          NOFIRE3
L920E               BSR.L          KEYHANDLE
                    BNE.L          MAIN_LOOP3
                    TST.W          D3
                    BEQ.L          L92BA
                    CMP.W          #$2,D3
                    BEQ.L          L927A
                    MOVEA.L        MENUPTROPTA1,A0
                    TST.L          A0
                    BEQ.L          MAIN_LOOP3
                    MOVEA.L        A0,A2
                    TST.W          D0
                    BEQ.S          L926C
                    BGT.S          L924E
                    SUBA.W         #$8,A2
                    CMPA.L         #(LEVELS),A2
                    BGE.S          L926A
                    MOVEA.L        #(LEVELS),A2
                    BRA.L          MAIN_LOOP3
L924E               ADDA.W         #$8,A2
                    TST.L          (A2)
                    BEQ.L          MAIN_LOOP3
                    CMPA.L         #(LEVELSEND),A2
                    BLT.S          L926A
                    MOVEA.L        #(L661D4),A2
                    BRA.L          MAIN_LOOP3
L926A               MOVEA.L        A2,A0
L926C               MOVE.L         A0,MENUPTROPTA1
                    BSR.L          AFFARENAZONE
                    BRA.L          MAIN_LOOP3
L927A               MOVEA.L        MENUPTROPTA2,A0
                    TST.L          A0
                    BEQ.L          MAIN_LOOP3
                    MOVEA.L        A0,A2
                    TST.W          D0
                    BEQ.S          L92AC
                    BGT.S          L929E
                    SUBA.W         #$4,A2
                    CMPA.L         #(OPT_MODEJ1),A2
                    BGE.S          L92AA
                    BRA.L          MAIN_LOOP3
L929E               ADDA.W         #$4,A2
                    TST.L          (A2)
                    BNE.S          L92AA
                    BRA.L          MAIN_LOOP3
L92AA               MOVEA.L        A2,A0
L92AC               MOVE.L         A0,MENUPTROPTA2
                    BSR.L          AFFMODEJEU
                    BRA.L          MAIN_LOOP3
L92BA               MOVEA.L        MENUSPTR,A0
                    TST.L          A0
                    BEQ.L          MAIN_LOOP3
                    MOVEA.L        A0,A2
                    TST.W          D0
                    BEQ.S          L92EC
                    BGT.S          L92DE
                    SUBA.W         #$4,A2
                    CMPA.L         #(OPT_ARENA1),A2
                    BGE.S          L92EA
                    BRA.L          MAIN_LOOP3
L92DE               ADDA.W         #$4,A2
                    TST.L          (A2)
                    BNE.S          L92EA
                    BRA.L          MAIN_LOOP3
L92EA               MOVEA.L        A2,A0
L92EC               MOVE.L         A0,MENUSPTR
                    BSR.L          AFFARENAMODE
                    BRA.L          MAIN_LOOP3
PLAYERS_MENU        MOVEQ          #$0,D3
                    BSR.L          BOBONOPTINP
NOFIRE4             MOVE.L         D0,-(SP)
                    MOVE.L         #$1,D0
L9308               MOVE.L         D2,-(SP)
L930A               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$C8,D2
                    BNE.S          L930A
                    MOVE.L         (SP)+,D2
                    MOVE.L         D2,-(SP)
L9322               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$DC,D2
                    BNE.S          L9322
                    MOVE.L         (SP)+,D2
                    DBRA           D0,L9308
                    MOVE.L         (SP)+,D0
                    BSR.L          TESTINPUTS
                    TST.W          D4
                    BNE.S          NOFIRE4
                    CLR.W          OLDDIRX
MAIN_LOOP4          MOVE.L         D2,-(SP)
L934E               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$2D,D2
                    BNE.S          L934E
                    MOVE.L         (SP)+,D2
                    MOVE.W         #$1,CYCLE_ACTIVATE
                    BSR.L          TESTINPUTS
                    CMP.W          OLDDIRX,D0
                    BEQ.S          L9382
                    MOVE.W         D0,OLDDIRX
                    BSR.L          INITKEYS
L9382               TST.W          D1
                    BEQ.S          L93E4
                    ADD.W          D3,D1
                    BLT.S          L93F4
                    CMP.W          #$2,D1
                    BGT.S          L93F4
                    MOVE.W         D1,D3
                    BSR.L          BOBOFFOPT
                    BSR.L          BOBONOPTINP
                    MOVE.L         D0,-(SP)
                    MOVE.L         #$4,D0
L93A2               MOVE.L         D2,-(SP)
L93A4               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$C8,D2
                    BNE.S          L93A4
                    MOVE.L         (SP)+,D2
                    MOVE.L         D2,-(SP)
L93BC               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$DC,D2
                    BNE.S          L93BC
                    MOVE.L         (SP)+,D2
                    DBRA           D0,L93A2
                    MOVE.L         (SP)+,D0
L93D8               BSR.L          TESTINPUTS
                    TST.W          D1
                    BNE.S          L93D8
                    BRA.L          MAIN_LOOP4
L93E4               TST.W          D4
                    BNE.L          L9410
                    TST.W          D0
                    BNE.L          L9414
                    BRA.L          MAIN_LOOP4
L93F4               TST.W          D3
                    BLE.S          L9408
                    LEA            SAUVEOPTMAIN,A0
                    MOVE.W         #$1,(A0)
                    MOVE.W         #$1,$2(A0)
L9408               BSR.L          BOBOFFOPT
                    BRA.L          CONTINUEMAINOPT
L9410               BRA.L          MAIN_LOOP4
L9414               BSR.L          KEYHANDLE
                    BNE.L          MAIN_LOOP4
                    TST.W          D3
                    BEQ.S          L9434
                    CMP.W          #$1,D3
                    BEQ.L          L9474
                    CMP.W          #$2,D3
                    BEQ.L          L94B4
                    BRA.L          MAIN_LOOP4
L9434               MOVEA.L        MENUPTROPTP0,A0
                    TST.L          A0
                    BEQ.L          MAIN_LOOP4
                    MOVEA.L        A0,A2
                    TST.W          D0
                    BEQ.S          L9466
                    BGT.S          L9458
                    SUBA.W         #$4,A2
                    CMPA.L         #(OPT_MODEP1),A2
                    BGE.S          L9464
                    BRA.L          MAIN_LOOP4
L9458               ADDA.W         #$4,A2
                    TST.L          (A2)
                    BNE.S          L9464
                    BRA.L          MAIN_LOOP4
L9464               MOVEA.L        A2,A0
L9466               MOVE.L         A0,MENUPTROPTP0
                    BSR.L          AFFMODEPLAYER
                    BRA.L          MAIN_LOOP4
L9474               MOVEA.L        MENUPTROPTP1,A0
                    TST.L          A0
                    BEQ.L          MAIN_LOOP4
                    MOVEA.L        A0,A2
                    TST.W          D0
                    BEQ.S          L94A6
                    BGT.S          L9498
                    SUBA.W         #$4,A2
                    CMPA.L         #(OPT_MODEC1),A2
                    BGE.S          L94A4
                    BRA.L          MAIN_LOOP4
L9498               ADDA.W         #$4,A2
                    TST.L          (A2)
                    BNE.S          L94A4
                    BRA.L          MAIN_LOOP4
L94A4               MOVEA.L        A2,A0
L94A6               MOVE.L         A0,MENUPTROPTP1
                    BSR.L          AFFCONTROL
                    BRA.L          MAIN_LOOP4
L94B4               MOVEA.L        MENUPTROPTP2,A0
                    TST.L          A0
                    BEQ.L          MAIN_LOOP4
                    MOVEA.L        A0,A2
                    TST.W          D0
                    BEQ.S          L94E6
                    BGT.S          L94D8
                    SUBA.W         #$4,A2
                    CMPA.L         #(OPT_MODED1),A2
                    BGE.S          L94E4
                    BRA.L          MAIN_LOOP4
L94D8               ADDA.W         #$4,A2
                    TST.L          (A2)
                    BNE.S          L94E4
                    BRA.L          MAIN_LOOP4
L94E4               MOVEA.L        A2,A0
L94E6               MOVE.L         A0,MENUPTROPTP2
                    BSR.L          AFFDEFINITION
                    BRA.L          MAIN_LOOP4
STR                 LEA            LA084,A2
                    MOVE.L         D3,D5
                    BGE.S          L9500
                    NEG.L          D3
L9500               CLR.B          -(A2)
L9502               DIVSL.L        #$A,D4:D3
                    ADDI.W         #$30,D4
                    MOVE.B         D4,-(A2)
                    SUBQ.W         #$1,D6
                    TST.L          D3
                    BNE.S          L9502
                    TST.B          D7
                    BEQ.S          L9522
L951A               SUBQ.W         #$1,D6
                    BLT.S          L9522
                    MOVE.B         D7,-(A2)
                    BRA.S          L951A
L9522               MOVE.L         D5,D3
                    BGE.S          L952A
                    MOVE.B         #$2D,-(A2)
L952A               RTS

BOBONMAIN           MOVEM.L        D0-D3/D7,-(SP)
                    MULU.W         #$2D0,D2
                    ADDI.W         #$D7F,D2
                    MOVE.W         D2,D3
                    MOVEQ          #$0,D4
                    LEA            MAINBOX,A1
                    MOVEA.L        PLANAR,A2
                    BSR.L          DISPLAYBOB8
                    MOVEM.L        (SP)+,D0-D3/D7
                    RTS

BOBONOPT            MOVEM.L        D0-D5/D7,-(SP)
                    MOVE.W         D3,D5
                    ADD.W          D5,D5
                    ADD.W          D2,D5
                    LSL.W          #$3,D5
                    LEA            $A014(D5.W),A1
                    MOVEM.L        (A1)+,D3-D4
                    LEA            MAINBOX,A1
                    MOVEA.L        PLANAR,A2
                    BSR.L          DISPLAYBOB8
                    MOVEM.L        (SP)+,D0-D5/D7
                    RTS

BOBONOPTINA         MOVEM.L        D0-D5/D7,-(SP)
                    MULU.W         #$1E,D3
                    ADDI.W         #$70,D3
                    MULU.W         #$28,D3
                    ADDI.W         #$7,D3
                    MOVEQ          #$4,D4
                    LEA            MAINBOX,A1
                    MOVEA.L        PLANAR,A2
                    BSR.L          DISPLAYBOB8
                    MOVEM.L        (SP)+,D0-D5/D7
                    RTS

BOBONOPTINP         MOVEM.L        D0-D5/D7,-(SP)
                    MULU.W         #$1E,D3
                    ADDI.W         #$70,D3
                    MULU.W         #$28,D3
                    ADDI.W         #$1B,D3
                    MOVEQ          #$4,D4
                    LEA            MAINBOX,A1
                    MOVEA.L        PLANAR,A2
                    BSR.L          DISPLAYBOB8
                    MOVEM.L        (SP)+,D0-D5/D7
                    RTS

BOBOFFMAIN          BSR.L          DELBOB8
                    RTS

BOBOFFOPT           BSR.L          DELBOB8
                    RTS

TESTINPUTS          CLR.W          TOTFEU
                    CLR.W          TOTMVX
                    CLR.W          TOTMVY
                    MOVEM.L        D2-D3/A0-A2,-(SP)
                    LEA            JOYLIST2,A0
L9600               MOVEA.L        (A0)+,A2
                    TST.L          A2
                    BEQ.S          L961E
                    MOVEQ          #$1,D4
                    JSR            (A2)
                    ADD.W          D0,TOTMVX
                    ADD.W          D1,TOTMVY
                    OR.W           D4,TOTFEU
                    BRA.S          L9600
L961E               MOVEM.L        (SP)+,D2-D3/A0-A2
                    MOVEM.W        TOTMVX,D0-D1/D4
                    TST.W          D0
                    BEQ.L          L9638
                    BGT.S          L9636
                    MOVEQ          #-$1,D0
                    BRA.S          L9638
L9636               MOVEQ          #$1,D0
L9638               TST.W          D1
                    BEQ.L          L9646
                    BGT.S          L9644
                    MOVEQ          #-$1,D1
                    BRA.S          L9646
L9644               MOVEQ          #$1,D1
L9646               RTS

CLS1                MOVE.W         #$6C,D0
                    MOVE.W         #$81,D1
                    MOVE.W         #$81,D2
                    MOVE.W         #$8A,D3
                    MOVE.W         #$11,D6
                    MOVEQ          #$7,D7
                    MOVEA.L        PLANAR,A2
                    BSR.L          BAR
                    RTS

CLS2                MOVE.W         #$3B,D0
                    MOVE.W         #$72,D1
                    MOVE.W         #$89,D2
                    MOVE.W         #$7B,D3
                    MOVE.W         #$17,D6
                    MOVEQ          #$7,D7
                    MOVEA.L        PLANAR,A2
                    BSR.L          BAR
                    RTS

CLS3                MOVE.W         #$3B,D0
                    MOVE.W         #$90,D1
                    MOVE.W         #$89,D2
                    MOVE.W         #$99,D3
                    MOVE.W         #$17,D6
                    MOVEQ          #$7,D7
                    MOVEA.L        PLANAR,A2
                    BSR.L          BAR
                    RTS

CLS4                MOVE.W         #$3B,D0
                    MOVE.W         #$AE,D1
                    MOVE.W         #$89,D2
                    MOVE.W         #$B7,D3
                    MOVE.W         #$17,D6
                    MOVEQ          #$7,D7
                    MOVEA.L        PLANAR,A2
                    BSR.L          BAR
                    RTS

CLS5                MOVE.W         #$DB,D0
                    MOVE.W         #$72,D1
                    MOVE.W         #$129,D2
                    MOVE.W         #$7B,D3
                    MOVE.W         #$17,D6
                    MOVEQ          #$7,D7
                    MOVEA.L        PLANAR,A2
                    BSR.L          BAR
                    RTS

CLS6                MOVE.W         #$DB,D0
                    MOVE.W         #$90,D1
                    MOVE.W         #$129,D2
                    MOVE.W         #$99,D3
                    MOVE.W         #$17,D6
                    MOVEQ          #$7,D7
                    MOVEA.L        PLANAR,A2
                    BSR.L          BAR
                    RTS

CLS7                MOVE.W         #$DB,D0
                    MOVE.W         #$AE,D1
                    MOVE.W         #$129,D2
                    MOVE.W         #$B7,D3
                    MOVE.W         #$17,D6
                    MOVEQ          #$7,D7
                    MOVEA.L        PLANAR,A2
                    BSR.L          BAR
                    RTS

INITKEYS            MOVE.W         #$14,VARKEYSPEED
                    MOVE.W         #$0,VARKEYREPEAT
                    RTS

AFFDEFINITION       MOVEA.L        MENUPTROPTP2,A0
                    MOVEA.L        (A0),A1
                    TST.L          A1
                    BEQ.L          L97B8
                    MOVEM.L        D0-D3/A0-A1,-(SP)
                    MOVE.L         A1,-(SP)
                    MOVE.L         D2,-(SP)
L975E               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$23,D2
                    BNE.S          L975E
                    MOVE.L         (SP)+,D2
                    BSR.L          CLS7
                    MOVEA.L        (SP)+,A1
                    LEA            FTINYTXT8,A0
                    MOVEA.L        PLANAR,A2
                    MOVE.W         #$D9,D0
                    MOVE.W         #$AF,D1
                    MOVEQ          #$1F,D2
                    MOVEQ          #$7,D7
                    MOVE.L         #$2800,VARSIZEPLAN
                    MOVE.L         #$28,VARSIZELINE
                    MOVE.L         #$53,D3
                    BSR.L          CENTERX
                    BSR.L          GPRINT
                    MOVEM.L        (SP)+,D0-D3/A0-A1
L97B8               RTS

AFFCONTROL          MOVEA.L        MENUPTROPTP1,A0
                    MOVEA.L        (A0),A1
                    TST.L          A1
                    BEQ.L          L982A
                    MOVEM.L        D0-D3/A0-A1,-(SP)
                    MOVE.L         A1,-(SP)
                    MOVE.L         D2,-(SP)
L97D0               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$23,D2
                    BNE.S          L97D0
                    MOVE.L         (SP)+,D2
                    BSR.L          CLS6
                    MOVEA.L        (SP)+,A1
                    LEA            FTINYTXT8,A0
                    MOVEA.L        PLANAR,A2
                    MOVE.W         #$D9,D0
                    MOVE.W         #$91,D1
                    MOVEQ          #$1F,D2
                    MOVEQ          #$7,D7
                    MOVE.L         #$2800,VARSIZEPLAN
                    MOVE.L         #$28,VARSIZELINE
                    MOVE.L         #$53,D3
                    BSR.L          CENTERX
                    BSR.L          GPRINT
                    MOVEM.L        (SP)+,D0-D3/A0-A1
L982A               RTS

AFFMODEPLAYER       MOVEA.L        MENUPTROPTP0,A0
                    MOVEA.L        (A0),A1
                    TST.L          A1
                    BEQ.L          L989C
                    MOVEM.L        D0-D3/A0-A1,-(SP)
                    MOVE.L         A1,-(SP)
                    MOVE.L         D2,-(SP)
L9842               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$23,D2
                    BNE.S          L9842
                    MOVE.L         (SP)+,D2
                    BSR.L          CLS5
                    MOVEA.L        (SP)+,A1
                    LEA            FTINYTXT8,A0
                    MOVEA.L        PLANAR,A2
                    MOVE.W         #$D9,D0
                    MOVE.W         #$73,D1
                    MOVEQ          #$1F,D2
                    MOVEQ          #$7,D7
                    MOVE.L         #$2800,VARSIZEPLAN
                    MOVE.L         #$28,VARSIZELINE
                    MOVE.L         #$53,D3
                    BSR.L          CENTERX
                    BSR.L          GPRINT
                    MOVEM.L        (SP)+,D0-D3/A0-A1
L989C               RTS

AFFMODEJEU          MOVEA.L        MENUPTROPTA2,A0
                    MOVEA.L        (A0),A1
                    TST.L          A1
                    BEQ.L          L990E
                    MOVEM.L        D0-D3/A0-A1,-(SP)
                    MOVE.L         A1,-(SP)
                    MOVE.L         D2,-(SP)
L98B4               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$23,D2
                    BNE.S          L98B4
                    MOVE.L         (SP)+,D2
                    BSR.L          CLS4
                    MOVEA.L        (SP)+,A1
                    LEA            FTINYTXT8,A0
                    MOVEA.L        PLANAR,A2
                    MOVE.W         #$39,D0
                    MOVE.W         #$AF,D1
                    MOVEQ          #$1F,D2
                    MOVEQ          #$7,D7
                    MOVE.L         #$2800,VARSIZEPLAN
                    MOVE.L         #$28,VARSIZELINE
                    MOVE.L         #$53,D3
                    BSR.L          CENTERX
                    BSR.L          GPRINT
                    MOVEM.L        (SP)+,D0-D3/A0-A1
L990E               RTS

AFFARENAMODE        MOVEA.L        MENUSPTR,A0
                    MOVEA.L        (A0),A1
                    TST.L          A1
                    BEQ.L          L9980
                    MOVEM.L        D0-D3/A0-A1,-(SP)
                    MOVE.L         A1,-(SP)
                    MOVE.L         D2,-(SP)
L9926               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$23,D2
                    BNE.S          L9926
                    MOVE.L         (SP)+,D2
                    BSR.L          CLS2
                    MOVEA.L        (SP)+,A1
                    LEA            FTINYTXT8,A0
                    MOVEA.L        PLANAR,A2
                    MOVE.W         #$39,D0
                    MOVE.W         #$73,D1
                    MOVEQ          #$1F,D2
                    MOVEQ          #$7,D7
                    MOVE.L         #$2800,VARSIZEPLAN
                    MOVE.L         #$28,VARSIZELINE
                    MOVE.L         #$53,D3
                    BSR.L          CENTERX
                    BSR.L          GPRINT
                    MOVEM.L        (SP)+,D0-D3/A0-A1
L9980               RTS

AFFARENAZONE        MOVEA.L        MENUPTROPTA1,A0
                    MOVEA.L        (A0),A0
                    MOVEA.L        (A0),A1
                    TST.L          A1
                    BEQ.L          L9A9A
                    ADDA.L         A0,A1
                    TST.L          A1
                    BEQ.L          L9A9A
                    MOVEM.L        D0-D3/A0-A1,-(SP)
                    MOVE.L         A1,-(SP)
                    MOVE.L         D2,-(SP)
L99A2               MOVE.L         $DFF004,D2
                    ANDI.L         #$1FFFF,D2
                    LSR.L          #$8,D2
                    CMP.W          #$23,D2
                    BNE.S          L99A2
                    MOVE.L         (SP)+,D2
                    BSR.L          CLS1
                    BSR.L          CLS3
                    MOVEA.L        (SP)+,A1
                    MOVEA.L        MENUPTROPTA1,A0
                    TST.W          $4(A0)
                    BEQ.S          L99D2
                    MOVEQ          #$1A,D2
                    BRA.S          L99D4
L99D2               MOVEQ          #$1F,D2
L99D4               LEA            FTINYTXT8,A0
                    MOVEA.L        PLANAR,A2
                    MOVE.W         #$39,D0
                    MOVE.W         #$91,D1
                    MOVEQ          #$7,D7
                    MOVE.L         #$2800,VARSIZEPLAN
                    MOVE.L         #$28,VARSIZELINE
                    MOVE.L         #$53,D3
                    BSR.L          CENTERX
                    BSR.L          GPRINT
                    MOVEA.L        MENUPTROPTA1,A0
                    SUBA.L         #(LEVELS),A0
                    MOVE.L         A0,D0
                    LSR.W          #$3,D0
                    EXT.L          D0
                    DIVS.W         #$14,D0
                    LEA            STRWORK,A3
                    CLR.L          D3
                    MOVE.W         D0,D3
                    ADDQ.W         #$1,D3
                    MOVEQ          #$1,D6
                    MOVE.B         #$30,D7
                    BSR.L          STR
L9A38               MOVE.B         (A2)+,D2
                    BEQ.S          L9A40
                    MOVE.B         D2,(A3)+
                    BRA.S          L9A38
L9A40               MOVE.B         #$2D,(A3)+
                    SWAP           D0
                    ADDQ.W         #$1,D0
                    CLR.L          D3
                    MOVE.W         D0,D3
                    MOVEQ          #$2,D6
                    MOVE.B         #$30,D7
                    BSR.L          STR
L9A56               MOVE.B         (A2)+,D2
                    BEQ.S          L9A5E
                    MOVE.B         D2,(A3)+
                    BRA.S          L9A56
L9A5E               CLR.B          (A3)+
                    LEA            STRWORK,A1
                    LEA            FTINYTXT8,A0
                    MOVEA.L        PLANAR,A2
                    MOVE.W         #$6E,D0
                    MOVE.W         #$82,D1
                    MOVEQ          #$1F,D2
                    MOVEQ          #$7,D7
                    MOVE.L         #$2800,VARSIZEPLAN
                    MOVE.L         #$28,VARSIZELINE
                    BSR.L          GPRINT
                    MOVEM.L        (SP)+,D0-D3/A0-A1
L9A9A               RTS

KEYHANDLE           MOVE.W         VARKEYSPEED,D5
                    BLT.S          L9AB2
                    SUBQ.W         #$1,VARKEYSPEED
                    CMP.W          #$14,D5
                    BEQ.S          L9AD2
                    BRA.S          L9ACC
L9AB2               MOVE.W         VARKEYREPEAT,D5
                    DBRA           D5,L9AC6
                    MOVE.W         #$2,VARKEYREPEAT
                    BRA.S          L9AD2
L9AC6               MOVE.W         D5,VARKEYREPEAT
L9ACC               TST.B          #$1
                    RTS

L9AD2               TST.B          #$0
                    RTS

FREEMENUDATA        CLR.W          CYCLE_ACTIVATE
                    MOVEQ          #$0,D0
                    BSR.L          LAUNCHZIK
                    BSR.L          FREEALLPICS
                    MOVE.W         MUSICVOLBACK,MUSICVOL
