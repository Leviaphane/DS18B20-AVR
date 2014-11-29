.include "TN13ADEF.inc" 

	.undef	ZL
	.def	TimeReg = R25
	.equ	ComDelay = 50

; RAM =====================================================
.DSEG ; RAM

; FLASH ===================================================
.CSEG ; Code segment

M0:	// Init stack 
	LDI		R16, low(RAMEND)
	OUT		SPL, R16
	
	// Configuring port (PB0)
	LDI		R16, 0xFF
	LDI		R17, 0xFF
	OUT		DDRB, R16
	OUT		PORTB, R17

	LDI		TimeReg, ComDelay
	RCALL	Delay

	// Setup DS18B20
	RCALL	ResetPulse			; Reset/Present signal

	LDI		R20, 0b11001100		; Skip ROM (0xCC)
	RCALL	SendCommand			

	LDI		R20, 0b01001110		; Write SkratchPad(0x4E)
	RCALL	SendCommand
	
	LDI		R20, 0b11111111		; Write Th (No alarm)
	RCALL	SendCommand
				
	LDI		R20, 0b11111111		; Write Tl (No alarm)
	RCALL	SendCommand

	LDI		R20, 0b0			; Write ConfigReg (0.5C accuracy)
	RCALL	SendCommand			; 
	
	LDI		TimeReg, ComDelay
	RCALL	Delay

	// Getting data from DS18B20
	RCALL	ResetPulse			; Reset/Present signal

	LDI		R20, 0b11001100		; Skip ROM (0xCC)
	RCALL	SendCommand			

	LDI		R20, 0b01000100		; Convert T (0x44)
	RCALL	SendCommand

W0:	RCALL	Read				; Waiting for conversion
	SBRS	R18, 7				
	RJMP	W0

	RCALL	ResetPulse			; Reset/Present signal
	
	LDI		R20, 0b11001100		; Skip ROM (0xCC)
	RCALL	SendCommand			

	LDI		R20, 0b10111110		; Read ScratchPad (0xBE)
	RCALL	SendCommand

	RCALL	ReadCommand			; Read Tl
	MOV		R27, R18

	RCALL	ReadCommand			; Read Th
	MOV		R28, R18

	RJMP	M0

// *************************************	
// FUNCTIONS
// *************************************	

; ---- Delay in us
Delay:
	MOV		R16, TimeReg
L0:	NOP
	NOP
	DEC		R16
	BRBC	1, L0
RET

; ---- Send command to DS18B20
SendCommand:
	LDI		R21, 8
F0:	SBRS	R20, 0
	RCALL	Write0
	SBRC	R20, 0	
	RCALL	Write1

	ROR		R20
	DEC		R21
	BRBC	1, F0
	RET

; ---- Read data from DS18B20
ReadCommand:
	LDI		R21, 8
F1:	
	ROR		R18
	RCALL	Read
	DEC		R21
	BRBC	1, F1
	RET

; ---- Send bit 1
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

; ---- Send bit 0
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

; ---- Read bit
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

	SBR		R18, 0b10000000 
	SBIS	PINB, 0
	CBR		R18, 0b10000000

	LDI		TimeReg, 40
	RCALL	Delay

	SBI		PORTB, 0
	SBI		DDRB, 0
RET

; ---- Send Reset pulse
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
	RJMP	M0				; Sensor error

	LDI		TimeReg, 245
	RCALL	Delay
	RCALL	Delay

	SBI		PORTB, 0
	SBI		DDRB, 0
RET

; EEPROM ==================================================
.ESEG ; 
