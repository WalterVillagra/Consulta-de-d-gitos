;
; consulta de numeros.asm
;
; Created: 22/8/2024 10:18:29
; Author : Walter
;


; Replace with your application code
.ORG	0X0000
JMP	INICIO
.ORG	0X0024
JMP	ISR_RX

.INCLUDE	"division.inc"

.DSEG
		Recepcion: .BYTE 1 
		C_NUM: .BYTE 1
		V_NUM: .BYTE 4
		NUM: .BYTE 4
INICIO:
		LDI R18,4		;carga 4 en C_NUM
		STS C_NUM,R18

		;CONFIGURACION UART
		LDI		R16,0				
		STS		UCSR0A,R16			;Todo el registro UCSR0A en 0
		LDI		R16,(1<<RXCIE0)|(1<<TXEN0)|(1<<RXEN0)          
		STS		UCSR0B, R16         ;Del registro UCSR0B habilito la transmision
		LDI		R16,(1<<UCSZ01)|(1<<UCSZ00)
		STS		UCSR0C,R16          ;Del registro UCSR0C configuro el dato de 8 bits
		LDI		R16,103             ;Velocidad del micro
		STS		UBRR0L,R16
		LDI		R16,0
		STS		UBRR0H,R16
		;FIN CONFIGURACION UART

ISR_RX:
       PUSH    R16
       IN      R16,SREG
       PUSH    R16
       LDS     R16,UDR0
       STS     Recepcion,R16
       STS     UDR0,R16
	   CALL RX
       POP     R16
       OUT     SREG,R16
       POP     R16
       RETI

RX:
    LDS     R16,Recepcion                              
	CALL    PREGUNTAR
RET

	PREGUNTAR:
CPI	R16,13
BREQ	ENTER
;Si es numero el ascii esta entre 48 y 57
LDI R18,57
BUCLE_NUM:
CP	R16,R18		;Compara entre registros
BREQ	ES_NUM
DEC R18
CPI	R18,47		;compara hasta el 48, si no esta en el rango sigue comparando para las letras
BRNE BUCLE_NUM
RET

ES_NUMs:	;tengo que guardar los numeros en V_NUM	
LDS	R18,C_NUM
CPI	r18,4
BREQ	N_UNO
CPI	r18,3
BREQ	N_DOS
CPI	r18,2
BREQ	N_TRES 
CPI	r18,1
BREQ	N_CUATRO
RET

N_UNO:
LDI	R20,48
SUB	R16,R20
STS V_NUM+0,R16
DEC R18		;pasa a 3
STS C_NUM,R18
RET

N_DOS:	;Si C_NUM esta en 3 el numero de N_UNO pasa a N_DOS y R16 se guarda en N_UNO
LDS R20,V_NUM+0
STS V_NUM+1,R20
LDI R20,48
SUB	R16,R20
STS V_NUM+0,R16
DEC R18		;pasa a 2
STS C_NUM,R18
RET

N_TRES:
LDS R20,V_NUM+1		;Pasa de 1 a 2 y de 0 a 1, entonces despues carga en 0, teniendo cargados los digitos 0, 1 y 2
STS V_NUM+2,R20
LDS R20,V_NUM+0
STS V_NUM+1,R20
LDI R20,48
SUB	R16,R20
STS V_NUM+0,R16
DEC R18		;pasa a 1
STS C_NUM,R18
RET

N_CUATRO:
LDS R20,V_NUM+2		;Pasa los digitos 2 a 3, 1 a 2, 0 a 1 y guarda el nuevo en 0
STS V_NUM+3,R20
LDS R20,V_NUM+1		
STS V_NUM+2,R20
LDS R20,V_NUM+0
STS V_NUM+1,R20
LDI R20,48
SUB	R16,R20
STS V_NUM,R16
LDI R18,4		;carga 4 en C_NUM
STS C_NUM,R18
RET
;-----------------------------------------------------------------------------------------------
ENTERs:	;Hay que armar el numero con los digitos cargados
LDS R16,V_NUM+0		;Es la unidad
LDS R17,V_NUM+1		;Se multiplica por 10
LDI R20,10
MUL R17,R20			;MUL multiplica registros sin signo
LDS R18,V_NUM+2		;Se multiplica por 100
LDI R20,100
MUL R18,R20
LDS R19,V_NUM+3		;Se multiplica por 1000
MUL R19,R20		;Lo multiplica 2 veces porque no se puede directamente por 1000
MUL R19,R20
;Hay que sumar todos los valores y guardarlos en NUM
ADD R16,R17
ADD R18,R19
ADD R16,R18
STS NUM,R16

LDS r24,NUM		;Manda el valor
LDS r25,NUM+1		;Manda el valor
Call DESARMAR_ENVIAR1	
RET



DESARMAR_ENVIAR1:
;Obtenemos unidad de mil
		LDI		R23,HIGH(1000)
		LDI		R22,LOW(1000)
		CALL	DIVISION16
		MOV		R20,R24
CALL	ENVIO_UART
MOVW	R24,R26

;Obtenemos centena
		LDI		R23,HIGH(100)
		LDI		R22,LOW(100)
		CALL	DIVISION16
		MOV		R20,R24
CALL	ENVIO_UART
MOVW	R24,R26


;Obtenemos la decena
		LDI		R23,HIGH(10)
		LDI		R22,LOW(10)
		CALL	DIVISION16
		MOV		R20,R24
		CALL	ENVIO_UART

;Obtenemos la unidad
		MOV	    R20,R26	;r26 es el resto
		CALL	ENVIO_UART
	    
		RET