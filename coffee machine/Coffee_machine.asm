dseg segment
    
    ;ports
    IN_P  equ 4     ;machine status
    OUT_P equ 5     ;machine commands
    
    ;status bits
    NOCUPS         equ 00000001b
    NOHOTWATER     equ 00000010b
    NOCOFFEEPOWDER equ 00000100b
    NOSUGAR        equ 00001000b
    STOPPROGRAM    equ 00010000b
    WITHSUGAR      equ 00100000b
    COININSERTED   equ 01000000b
    
    ;conditions
    CONDITION1_BITS equ 00001111b    ;if OK -should be 0000b    
    
    ;commands bits
    CUPMOTOR          equ 00000001b
    COFFEEPOWDERMOTOR equ 00000010b
    HOTWATERVALVE     equ 00000100b
    SUGARMOTOR        equ 00001000b
    
    ;timers
    T1  equ 1       ;coffee motor timer
    T2  equ 2       ;sugar  motor timer
    T5  equ 5       ;general 5 sec.
    T10 equ 10      ;general 10 sec.
    
    ;messages
    MSG_NOCUPS      db 'no cups $'
    MSG_NOHOTWATER  db 'no hot water $'
    MSG_NOCOFFEE    db 'no coffee powder $'
    MSG_NOSUGAR     db 'no sugar $'
    MSG_INSERTCOIN  db 'insert coin$'
    MSG_INPROGRESS  db 'please wait...$'
    MSG_READY       db 'coffee is ready$'    
               
dseg ends   

sseg segment stack
    db 20h dup (?)    
sseg ends

cseg segment
    assume cs:cseg,ds:dseg,ss:sseg
        
    start:
       mov ax,dseg
       mov ds,ax
    
    ;-------------             
    
    ;STATE 1 -status check
ST_1: 
    ;get status
    IN AL, IN_P
    
    ;print status
    CALL PRINT_STATUS
    
    ;status check
    TEST AL, CONDITION1_BITS
    
    ;status is ok
    JZ ST_2
    
    ;else
    MOV BL, 1           ;wait amount
    CALL WAIT_TIMER     ;wait func.
    JMP ST_1
     
     
    ;STATE 2 -wait for coin
ST_2:
    ;get status
    IN AL, IN_P

    ;check if coin is inserted
    TEST AL, COININSERTED
    
    ;inserted
    JNZ INPROGRESS

    ;else
    MOV BL, 1           ;wait amount
    CALL WAIT_TIMER     ;wait func.
    JMP ST_2
     
     
    ;in progess message
INPROGRESS:
    MOV BL, 1               ;erase line
    LEA DX, MSG_INPROGRESS
    CALL PRINT_STRING
    
    
    ;STATE 3 -take a cup out
ST_3:
    ;power on
    MOV AL, CUPMOTOR
    OUT OUT_P, AL
    
    ;wait
    MOV BL, T5          ;wait amount
    CALL WAIT_TIMER     ;wait func.
    
    ;power off
    MOV AL, 0
    OUT OUT_P, AL
    
    
    ;STATE 4 -put coffee powder
ST_4:
    ;power on the motor
    MOV AL, COFFEEPOWDERMOTOR
    OUT OUT_P, AL
    
    ;wait
    MOV BL, T1          ;wait amount
    CALL WAIT_TIMER     ;wait func.
    
    ;power off
    MOV AL, 0
    OUT OUT_P, AL  
    
    
    ;STATE 5 -pour hot water
ST_5:
    ;open valve
    MOV AL, HOTWATERVALVE
    OUT OUT_P, AL
    
    ;wait
    MOV BL, T10         ;wait amount
    CALL WAIT_TIMER     ;wait func.
    
    ;close valve
    MOV AL, 0
    OUT OUT_P, AL     
    
    
    ;CHECK IF SUGAR NEEDED
        
    IN AL, IN_P        ;get status
    TEST AL, WITHSUGAR ;check sugar
    
    ;no sugar
    JZ ST_7
    
    
    ;STATE 6 -put sugar
ST_6:
    ;power on the motor
    MOV AL, SUGARMOTOR
    OUT OUT_P, AL
    
    ;wait
    MOV BL, T2          ;wait amount
    CALL WAIT_TIMER     ;wait func.
    
    ;power off
    MOV AL, 0
    OUT OUT_P, AL 
    

    ;STATE 7 -coffee ready
ST_7:    
    ;show message
    LEA DX, MSG_READY 
    MOV BL, 1
    CALL PRINT_STRING
     
    ;check stop condition
    IN AL, IN_P        ;get status
    TEST AL, STOPPROGRAM
     
    ;not stop
    JNZ ST_1

SOF:     
    ;------------- 
       mov ah,4ch
       int 21h
       
      
;FUNCTIONS
    
    
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
    
    
    ;get system time
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
    INT 21h     ;get system time
    CMP DH, BH
    JNE W1      ;assume no delays in RM
    
    ;restore registers
    POP DX
    POP CX
    POP BX
    POP AX
    
    RET
WAIT_TIMER ENDP

    
;PRINT_STATUS
;prints the status of the machine
;param: AL -current machine status
PRINT_STATUS PROC
    
    MOV BL, 1   ;clean the line
    
    ;check if items is ok 
    TEST AL, CONDITION1_BITS
    
    ;something is missing
    JNZ NOCUPS
    
    ;else
    LEA DX, MSG_INSERTCOIN
    CALL PRINT_STRING
    JMP END_PRINT_STATUS   
    
NOCUPS:    
    ;check if cups exists
    TEST AL, NOCUPS
    
    ;cups exists
    JZ NOHOTWATER
    
    ;else   -print message
    LEA DX, MSG_NOCUPS
    CALL PRINT_STRING
    MOV BL, 0           ;no clean line in next message
    
NOHOTWATER:
    ;check if a hot water is present
    TEST AL, NOHOTWATER
    
    ;hot water is present
    JZ NOCOFFEE
    
    ;else   -print message
    LEA DX, MSG_NOHOTWATER
    CALL PRINT_STRING
    MOV BL, 0           ;no clean line in next message

NOCOFFEE:
    ;check if there is coffee powder
    TEST AL, NOCOFFEEPOWDER
    
    ;coffee powder exists
    JZ NOSUGAR
    
    ;else   -print message
    LEA DX, MSG_NOCOFFEE
    CALL PRINT_STRING
    MOV BL, 0           ;no clean line in next message

NOSUGAR:
    ;check if sugar exists
    TEST AL, NOSUGAR
    
    ;sugar exists
    JZ END_PRINT_STATUS
    
    ;else   -print message
    LEA DX, MSG_NOSUGAR
    CALL PRINT_STRING

END_PRINT_STATUS:
    
    RET
PRINT_STATUS ENDP


;PRINT_STRING
;Print string
;Params: DX -string address.
;BL: 1 -Clean line, 0 -else  
PRINT_STRING PROC
    
    ;store registers
    PUSH AX
    
    CMP BL, 1
    JNZ PRINT1
    CALL CLN_LN     ;clean line

PRINT1:
    MOV AH, 9h      ;print string
	INT 21h
	
	;restore registers
    POP AX
   
    RET
PRINT_STRING ENDP
    
    
;CLN_LN
;Clean line (50 chars)
CLN_LN PROC
     
    ;store registers
    PUSH AX
    PUSH DX
    PUSH CX
    
    MOV AH, 2       ;char print interrupt
    
    ;carriage return
    MOV DL, 0Dh
    INT 21h
    
    MOV CX, 50      ;counter
    MOV DL, ' '     ;char to fill

CLN_LN1:
    INT 21h      ;print char
    LOOP CLN_LN1
    
    ;carriage return
    MOV DL, 0Dh
    INT 21h
    
    ;restore registers
    POP CX
    POP DX
    POP AX
    
    RET
CLN_LN ENDP

       
cseg ends
end start