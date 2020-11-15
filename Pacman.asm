PROC PAC_MOVE
;{
	;START_PROC: {
		PUSH CX
		PUSH DX
	;}
	
	;SET CX & DX {
		MOV CX, [PACX]
		MOV DX, [PACY]
	;}
	
	;UPDATE X & Y ACCORDING TO DIRECTION ;{
		ADD CL, [BYTE PTR DIR + 1]
		ADD DL, [BYTE PTR DIR]
	;}
	
	;HANDLE OVERFLOW: {
		CMP CL, 0F7h
		JZ  @@OVERFLOW_L
		
		CMP CX, 207
		JZ  @@OVERFLOW_R
		JMP @@IS_CLEAR_MOVE
		;--------------------
		@@OVERFLOW_L:
		MOV CX, 198
		JMP @@PAC_PRINT
		
		@@OVERFLOW_R:
		MOV CX, 0
		JMP @@PAC_PRINT
	;}
	
	@@IS_CLEAR_MOVE: ;{
		PUSH CX
		PUSH DX
		CALL CLEAR_MOVE	;CHECK IF THESE X & Y ARE CLEAR
		
		JNC @@CHECK_NEXT_DIR;IF NOT CLEAR(NC), THEN DON'T PRINT.
	;}
	
	@@PAC_PRINT: ;{
		PUSH CX
		PUSH DX
		CALL PAC_EATDOTS
		
		CALL PAC_CLEAR
		
		MOV [PACX], CX
		MOV [PACY], DX
		CALL PAC_ANIMATION
	;}
	
	@@CHECK_NEXT_DIR: ;{
		CMP [NEXTDIR], DIR_N
		JZ  @@END_PROC
		
		;SET CX & DX TO PACX & PACY {
			MOV CX, [PACX]
			MOV DX, [PACY]
		;}
		
		;UPDATE X & Y ACCORDING TO NEXT_DIR {
			ADD CL, [BYTE PTR NEXTDIR + 1]
			ADD DL, [BYTE PTR NEXTDIR]
		;}
		
		;IS NEXT_DIR CLEAR? {
			PUSH CX
			PUSH DX
			CALL CLEAR_MOVE
			JNC @@END_PROC ;IF NO, EXIT PROCEDURE
			
			;IF YES, DIR = NEXT_DIR
			PUSH [NEXTDIR]
			POP  [DIR]
		;}
	;}
	
	@@END_PROC: ;{
		POP DX
		POP CX
		CALL GAME_INPUT
		RET
	;}
;}
ENDP PAC_MOVE
;*****************************************************************************
;*****************************************************************************

PROC PAC_PRINT
;{	
	PUSH OFFSET PACMAN_0
	PUSH YELLOW
	PUSH [PACX]
	PUSH [PACY]
	CALL GRAPHICS_PRINTIMAGE
	RET
;}
ENDP PAC_PRINT	

;==========================================


PROC PAC_CLEAR
;{
	;PUSH PARAMS & CALL PRINTRECT {
		PUSH [PACX]		;x
		PUSH [PACY]		;y
		
		PUSH 9			;width
		PUSH 9			;height
		
		PUSH black		;color
		
		CALL GRAPHICS_PRINTRECT
	;}
	
	RET
;}
ENDP PAC_CLEAR
	
;*****************************************************************************
;*****************************************************************************


PROC PAC_EATDOTS
;{
	;INTPUT: X, Y
	;OUTPUT: CF (1 = CLEAR, 0 = NOT CLEAR), BH = 1; BL = 1;
	
	;PARAMS {
		PX_X EQU [WORD PTR BP + 6]
		PX_Y EQU [WORD PTR BP + 4]
	;}
	
	;PUSH & BASEPOINTER {
		PUSH BP
		MOV  BP, SP
		
		PUSH AX
		PUSH BX
	;}
	
	;GET COLOR {
		ADD PX_X, 4
		ADD PX_Y, 4
	
		PUSH PX_X
		PUSH PX_Y
		CALL GRAPHICS_GETCOLOR
		
		;OBJ = WALL? {
			CMP AL, BLUE
			JZ  @@END_PROC
		;}
		
		;OBJ = VOID? {
			CMP AL, BLACK
			JZ  @@END_PROC
		;}
		
		;OBJ = DOT? {
			CMP AL, WHITE
			JZ  @@DOT
		;}
	
		;OBJ = PP? {
			CMP AL, PP_PINK
			JZ  @@PP
		;}
		
		;ELSE, OBJ = GHOST {
			;FIND THIS GHOST {
				SUB PX_X, 4
				SUB PX_Y, 4
				
				PUSH PX_X
				PUSH PX_Y
				CALL G_TRACE
				POP  BX			;BX = THE GHOST'S BASE ADDRESS
			;}
			
			CMP [WORD PTR G_OBJ], OBJ_DOT
			JZ  @@DOT
			
			CMP [WORD PTR G_OBJ], OBJ_PP
			JZ  @@PP
			
			JMP @@END_PROC
		;}
		
		@@DOT: ;{
			CALL EAT_DOT
			JMP @@END_PROC
		;}
		
		@@PP: ;{
			CALL EAT_PP
		;}
	;}
	
	@@END_PROC:
	;POP {
		POP BX
		POP AX
		POP BP
	;}
	
	RET 4
;}
ENDP PAC_EATDOTS

;*****************************************************************************
;*****************************************************************************
PROC PAC_ANIMATION
;{
	PUSH AX
	PUSH BX
	
	CALL PAC_CLEAR
	
	;CURRENT FRAME = [DIRECTION BASE] + [FRAME_POINTER]
	
	;RESTART ANIMATION IF NECESSARY {
		CMP [PAC_FP], 16
		JNZ @@CHECK_DIR
		
		MOV [PAC_FP], 0
	;}
	
	@@CHECK_DIR: ;{
		;DIRECTION = UP?
		CMP [DIR], DIR_U
		JZ  @@UP
		
		;DIRECTION = DOWN?
		CMP [DIR], DIR_D
		JZ  @@DOWN
		
		;DIRECTION = LEFT?
		CMP [DIR], DIR_L
		JZ  @@LEFT
		
		;DIRECTION = RIGHT?
		CMP [DIR], DIR_R
		JZ  @@RIGHT
		
		;ELSE, EXIT PROC:
		JMP @@END_PROC
	;}
	
	;UPDATE OFFSET {
		@@UP: ;{
			MOV BX, OFFSET PAC_ANI_U
			JMP @@PRINT_PAC
		;}
		
		@@DOWN: ;{
			MOV BX, OFFSET PAC_ANI_D
			JMP @@PRINT_PAC
		;}
		
		@@LEFT: ;{
			MOV BX, OFFSET PAC_ANI_L
			JMP @@PRINT_PAC
		;}
		
		@@RIGHT: ;{
			MOV BX, OFFSET PAC_ANI_R
		;}
	;}
	
	@@PRINT_PAC: ;{
		ADD BX, [PAC_FP]
		
		PUSH [BX]
		PUSH YELLOW
		PUSH [PACX]
		PUSH [PACY]
		
		CALL GRAPHICS_PRINTIMAGE
	;}
	
	@@END_PROC: ;{
		POP BX
		POP AX
		ADD [PAC_FP], 2	;FRAME POINTER POINTS TO THE NEXT FRAME
		RET
	;}
;}
ENDP PAC_ANIMATION
;*****************************************************************************
;*****************************************************************************

PROC EAT_PP
;{
	;SET GHOSTS TO FRIGHTENED MODE {
		MOV [IS_FRIGH], TRUE
		MOV [WORD PTR CNT_FRI],  0
		MOV [WORD PTR G_BLINK],  -1
	;}
	
	;DECREASE THE SPEED OF THE GHOSTS {
		MOV AX, [SPEED]
		INC AX
		MOV [INT_GMOV], AX
	;}
	
	;INCREMENT PACMAN'S DOT COUNTERS {
		INC [WORD PTR CNT_DOTS]
		INC [WORD PTR CNT_DOTS_TEMP]
	;}
	
	;INCREASE SCORE BY 50 {
		PUSH 50
		CALL UPDATE_SCORE
	;}
	
	;180 DEG TURN {
		MOV BX, OFFSET GHOSTS
		@@TURN_LOOP: ;{
			NEG [BYTE PTR G_DIR]
			NEG [BYTE PTR G_DIR + 1]
			
			ADD BX, [ARR_JMP]
			CMP BX, [ARR_END]
			JNZ @@TURN_LOOP
		;}
	;}
	
	@@END_PROC: ;{
		RET
	;}
;}
ENDP EAT_PP
	
;*****************************************************************************
;*****************************************************************************

PROC EAT_DOT
;{
	;INCREMENT PACMAN'S DOT COUNTERS {
		INC [CNT_DOTS]
		INC [CNT_DOTS_TEMP]
	;}
	
	;INCREASE SCORE BY 10 {
		PUSH 10
		CALL UPDATE_SCORE
	;}
	
	@@END_PROC: ;{
		RET
	;}
;}
ENDP EAT_DOT

;*****************************************************************************
;*****************************************************************************
