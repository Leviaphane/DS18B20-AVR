.include "TN13ADEF.inc" ; Используем ATMega16

	.undef	ZL
	.def	TimeReg = R25
	.equ	ComDelay = 50
;= Start macro.inc ========================================
;= End macro.inc ========================================

; RAM =====================================================
.DSEG ; Сегмент ОЗУ

; FLASH ===================================================
.CSEG ; Кодовый сегмент

M0:	// Инициализация стека
	LDI		R16, low(RAMEND)
	OUT		SPL, R16
	
	// Конфигурация порта для термометра (PB0)
	LDI		R16, 0xFF
	LDI		R17, 0xFF
	OUT		DDRB, R16
	OUT		PORTB, R17

	LDI		TimeReg, 250
	RCALL	Delay

	// Начинаем обмен с датчиком
	RCALL	ResetPulse

	LDI		TimeReg, ComDelay
	RCALL	Delay

	// Посылаем Skip ROM (11001100b)
	LDI		R20, 0b11001100
	RCALL	SendCommand

	LDI		TimeReg, ComDelay
	RCALL	Delay

	// Посылаем Convert (01000100b)
	LDI		R20, 0b01000100
	RCALL	SendCommand

	// Ждем, пока завершится преобразование
Wait0:
	RCALL	Read
	SBRS	R18, 0
	RJMP	Wait0

	// Посылаем Reset pulse
	RCALL	ResetPulse

	LDI		TimeReg, ComDelay
	RCALL	Delay
	
	// Посылаем Skip ROM (11001100b)
	LDI		R20, 0b11001100
	RCALL	SendCommand

	LDI		TimeReg, ComDelay
	RCALL	Delay

	// Посылаем Read 
	LDI		R20, 0b10111110
	RCALL	SendCommand

	LDI		TimeReg, ComDelay
	RCALL	Delay

	// Считываем ответ
	RCALL	ReadCommand
	MOV		R27, R18

	RCALL	ReadCommand
	MOV		R28, R18

	LDI		TimeReg, ComDelay
	RCALL	Delay

// Читаем
	RJMP	M0



// *************************************	
// Функции
// *************************************	

; ---- Задержка в милисекундах
Delay:
	MOV		R16, TimeReg
L0:	NOP
	NOP
	DEC		R16
	BRBC	1, L0
RET

; ---- Посылка команды
SendCommand:
	LDI		R21, 7
F0:	
	SBRS	R20, 0
	RCALL	Write0
	SBRC	R20, 0	
	RCALL	Write1

	ROR		R20
	DEC		R21
	BRBC	1, F0
	RET

; ---- Прием команды
ReadCommand:
	LDI		R21, 7
F1:	
	ROL		R18
	RCALL	Read
	DEC		R21
	BRBC	1, F1
	RET

; ---- Послать 1
Write1:
	SBI		PORTB, 0
	SBI		DDRB, 0

	LDI		TimeReg, 5
	RCALL	Delay

	CBI		PORTB, 0
	
	LDI		TimeReg, 5
	RCALL	Delay

	SBI		PORTB, 0
	
	LDI		TimeReg, 60
	RCALL	Delay	
RET

; ---- Послать 0
Write0:
	SBI		DDRB, 0
	SBI		PORTB, 0

	LDI		TimeReg, 5
	RCALL	Delay

	CBI		PORTB, 0

	LDI		TimeReg, 60
	RCALL	Delay

	SBI		PORTB, 0	
RET

; ----- Чтение 
Read:
	SBI		PORTB, 0
	SBI		DDRB, 0

	LDI		TimeReg, 5
	RCALL	Delay

	CBI		PORTB, 0

	LDI		TimeReg, 5
	RCALL	Delay

	CBI		DDRB, 0

	LDI		TimeReg, 20
	RCALL	Delay

	SBR		R18, 1 
	SBIS	PINB, 0
	CBR		R18, 1

	LDI		TimeReg, 40
	RCALL	Delay

	SBI		PORTB, 0
	SBI		DDRB, 0
RET

; ------ Посылаем Reset pulse
ResetPulse:
	CBI		PORTB, 0

	LDI		TimeReg, 245
	RCALL	Delay
	RCALL	Delay

	CBI		DDRB, 0

	LDI		TimeReg, 65
	RCALL	Delay

	IN		R16, PINB
	SBRC	R16, 0
	RJMP	M0			// Если датчик не отозвался, уходим в ресет

	LDI		TimeReg, 210
	RCALL	Delay
	RCALL	Delay

	SBI		PORTB, 0
	SBI		DDRB, 0
RET
; EEPROM ==================================================
.ESEG ; Сегмент EEPROM
