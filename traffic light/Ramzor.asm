;micro - traffic light
;DIMA LEVIN 317083509 42/5

;CONTROLS:
;SPACE -continue the sequence from the green light state
;ESC   -exit the program

dseg segment
    
    ;wait time const. 
    WAIT_TIME equ 10    ;approx. 10 sec.
    
    ;bulbs (1 word -location, 2 word -color and char)
    RED DW 1680, 07CDBh
    YELLOW DW 2000, 07EDBh
    GREEN DW 2320, 07ADBh
    
    ;off char
    OFF DW 077DBh
    
dseg ends   

sseg segment stack
    db 20h dup (?)    
sseg ends

cseg segment
    assume cs:cseg,ds:dseg,ss:sseg
        
    start:
       mov ax,dseg
       mov ds,ax
       
       ;use ES as video memory
       mov ax, 0b800h
       mov es, ax
    
    ;-------------   
    
    CALL FILL_SCREEN    ;fill the screen with white color
      
      
    ;traffic light loop
        
STATE_1:
    ;set the green bulb on
    MOV SI, GREEN
    MOV AX, GREEN[2]
    CALL SET_CHAR 

WAIT_L:    
    ;wait
    MOV BL, 1
    CALL WAIT_TIMER
    
    ;check input
    CALL CHECK_INPUT
    
    ;if exit 
    CMP BL, 2
    JZ SOF
             
    ;if not continue
    CMP BL, 1
    JNZ WAIT_L
    
    ;turn off the bulb
    MOV AX, OFF
    CALL SET_CHAR
                 
                
    ;STATE 2
    
    ;set the yellow bulb on
    MOV SI, YELLOW
    MOV AX, YELLOW[2]
    CALL SET_CHAR
              
    ;wait (T/2)
    MOV BL, WAIT_TIME/2
    CALL WAIT_TIMER
    
    ;check input
    CALL CHECK_INPUT
    
    ;if exit 
    CMP BL, 2
    JZ SOF
    
    ;turn off the bulb
    MOV AX, OFF
    CALL SET_CHAR    
       
       
    ;STATE 3
    
    ;set the red bulb on
    MOV SI, RED
    MOV AX, RED[2]
    CALL SET_CHAR
    
    ;wait (T)
    MOV BL, WAIT_TIME
    CALL WAIT_TIMER
    
    ;check input
    CALL CHECK_INPUT
    
    ;if exit 
    CMP BL, 2
    JZ SOF
    
    
    ;STATE 4
    
    ;set the yellow bulb on
    MOV SI, YELLOW
    MOV AX, YELLOW[2]
    CALL SET_CHAR
    
    ;wait (T/2)
    MOV BL, WAIT_TIME/2
    CALL WAIT_TIMER
    
    ;check input
    CALL CHECK_INPUT
    
    ;if exit 
    CMP BL, 2
    JZ SOF
    
    ;turn off both bulbs
    MOV AX, OFF
    CALL SET_CHAR
    MOV SI, RED
    MOV AX, OFF
    CALL SET_CHAR
    
    ;continue
    JMP STATE_1
                                
SOF: 
    ;------------- 
       mov ah,4ch
       int 21h


;FUNCTIONS

;FILL_SCREEN
;Fills the sreen with white color
FILL_SCREEN PROC
    
    ;save registers
    PUSH DS
    PUSH BX
    
    ;change DS register to video memory
    MOV BX, 0B800h
    MOV DS, BX
    
    MOV SI, 0       ;screen home
    MOV CX, 2000    ;total amount of chars to fill
    
LP1:MOV [SI], 7720h ;white space
    ADD SI, 2       ;advance pointer
    LOOP LP1
    
    ;restore registers
    POP BX
    POP DS
    
    RET	
FILL_SCREEN ENDP
    
    
;SET_CHAR
;sets a specific char in certain location on screen
;params: SI -location, AX -char
;assume that ES points to video memory
SET_CHAR PROC
 
    MOV ES:[SI], AX   
    
    RET
SET_CHAR ENDP


;WAIT_TIMER
;'wait' timer
;param: BL -time to wait in seconds
;note: BL=0 approx. 1 min. wait
WAIT_TIMER PROC
    
    ;store registers
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    
    ;get time
    MOV AH, 2Ch
    INT 21h
        
    ;save seconds value
    MOV BH, DH
    
    ;add amount of seconds to wait
    ADD BH, BL
    
    ;check if in valid range of sec.
    CMP BH, 3Bh
    JBE W1
    SUB BH, 3Bh ;adjust value
    
    ;wait and compare loop   
W1: MOV CX, 50
L1: LOOP L1
    INT 21h
    CMP DH, BH
    JNE W1      ;assume no delays in RM
    
    ;restore registers
    POP DX
    POP CX
    POP BX
    POP AX
    
    RET
WAIT_TIMER ENDP


;CHECK_INPUT
;check an input from the keyboard
;return: BL=1 -space pressed, BL=2 -esc pressed
;registers affected: AX, BX
CHECK_INPUT PROC
    
    ;reset registers
    MOV BL, 0
    MOV AL, 0
 
    MOV AH, 1
    INT 16h
    
    ;no/irrelivant buttons pressed
    CMP AL, 0
    JZ EX
    
    ;esc pressed
    CMP AL, 1Bh
    JNZ NXT
    MOV BL, 2
    JMP CLR_B

NXT:    
    ;space pressed
    CMP AL, 20h
    JNZ EX
    MOV BL, 1
    
CLR_B:
    ;clear keyboard buffer
    MOV AH, 7
    INT 21h   

EX:        
    RET
CHECK_INPUT ENDP

        
cseg ends
end start