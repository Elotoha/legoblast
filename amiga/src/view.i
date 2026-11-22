
	incdir	include:graphics
*	include	view.i
	include	graphics/gfxbase.i
	include	graphics/graphics_lib.i

TakeSystem
	Bsr	Take1
	Bsr	Take2
	Bsr	Take3
	Bsr	Take4
	RTS

TakeSystem2
	Bsr	Take1
	*Bsr	Take3
	Bsr	Take4
	RTS


Take1	
	Move.l	$4.w,A6
	Jsr	_LVOForbid(A6)
	RTS

Take2
	Move.w	DmaConR,D0
	Move.w	IntEnaR,D1
	Move.w	AdkConR,D2
	Move.w	IntReqR,D3
	Move.w	#$8000,D4
	Or.w	#$8200,D0
	Or.w	D4,D1
	Or.w	D4,D2
	Or.w	D4,D3
	Move.w	D0,MemDma
	Move.w	D1,MemEna	
	Move.w	D2,MemAdk
	Move.w	D3,MemReq

	RTS
	
Take3	
	Move.l	$4.w,A6
	Lea	_GfxName,A1
	Clr.l	D0
	Jsr	-$228(A6)
	Move.l	D0,_GfxBase
	Beq.s	.Error
	Move.l	D0,A6
	Move.l	gb_ActiView(A6),Stored_VIEW
	Suba.l	A1,A1	
	Jsr	_LVOLoadView(A6)
	Jsr	_LVOWaitTOF(A6)
.Error	Jsr	_LVOWaitTOF(A6)
	Jsr	_LVOWaitBlit(A6)
	RTS
Take4
	*Move.w	#$7FFF,DmaCon
	Move.w	#$7E7F,DmaCon
	Move.w	#$7FFF,IntEna	Coupe tout
	Move.w	#$7FFF,AdkCon
	Move.w	#$7FFF,IntReq	
	RTS

********************************

RestoreSystem
	Bsr	Restore1
	Bsr	Restore2	
	RTS

RestoreSystem2
	Bsr	Restore2	
	RTS		
	
Restore1
	Move.l	_GfxBase,A6
	Cmpa.l	#0,A6
	Beq.s	.Error
	Move.l	$26(A6),Cop1Lch
	Move.l	$32(A6),Cop2Lch
*	Move.l	gb_copinit(A6),cop1lch
	Move.l	Stored_VIEW,A1
	Jsr	_LVOLoadView(A6)	
.Error	RTS
	
Restore2
	*Move.w	#$7FFF,DmaCon
	Move.w	#$7E7F,DmaCon
	Move.w	#$7FFF,IntEna	Coupe tout
	Move.w	#$7FFF,AdkCon
	Move.w	#$7FFF,IntReq
	Move.w	MemDma,DmaCon
	Move.w	MemEna,IntEna
	Move.w	MemAdk,AdkCon
	Move.w	MemReq,IntReq
*	Move.l	$4.w,A6
*	Move.l	$9C(A6),A6
*	Move.l	$26(A6),Cop1Lch
*	Move.l	$32(A6),Cop2Lch
*	Clr.w	CopJmp1	
	Move.l	$4.w,A6
	Jsr	_LVOPermit(A6)
	RTS
	
	
_GfxBase	Dc.l	0
Stored_VIEW Dc.l	0
_GfxName	Dc.b	'graphics.library',0
	even
	
MemDma	Dc.w	0
MemEna	Dc.w	0
MemAdk	Dc.w	0
MemReq	Dc.w	0	