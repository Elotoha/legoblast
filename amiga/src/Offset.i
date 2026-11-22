FindOffsetFromXY
	
	Move.w	Leg_X(A0),D2
	Add.w	#-128+HotX,D2
	Move.w	Leg_Y(A0),D3
	Add.w	#-46+HotY,D3

	Move.w	D3,D6		Calcul offset normal
	Lsr.w	#3,D6
	Bclr	#0,D6

	Lsl.w	#6,D6

	Move.w	D2,D5
	Lsr.w	#3,D5	
	Bclr	#0,D5

	Add.w	D5,D6		

	* D6 (.W) : N° de la case en absolu

	Ext.l	D6
	Lsl.l	#2,D6

	* D6 (.L) : OFFSET de la case dans les Dim (à part Dim4)

	RTS
