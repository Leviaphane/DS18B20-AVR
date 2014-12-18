.include "TN13ADEF.inc" 

	.def	TempReg		=	R16
	.def	TByteL		=	R17
	.def	TByteH		=	R18
	.def	CommandReg	=	R20
	.def	TimeReg		=	R25
	.def	DataSPI		=	R19
	.def	InputSPI	=	R21
	.def	OutputSPI	=	R22

	.equ	ThermoPin	=	3
	.equ	LedPin		=	3
	.equ	ComDelay	=	50

	.equ	MOSI		=	0
	.equ	MISO		=	1
	.equ	SCK			=	2
	.equ	CE			=	3
	.equ	SC			=	4

	; Thermo command
	.equ	SkipROM		=	0b11001100		; Skip ROM (0xCC)		
	.equ	WriteData	=	0b01001110		; Write SkratchPad(0x4E)		
	.equ	ReadData	=	0b10111110		; Read ScratchPad (0xBE)		
	.equ	Converse	=	0b01000100		; Convert T (0x44)

; MACRO ===================================================
; RAM =====================================================

.DSEG ; RAM

; FLASH ===================================================
.CSEG ; Code segment
	; Interupt table
	RJMP	M0 ; Reset Handler
	RJMP	M0 ; IRQ0 Handler
	RJMP	M0 ; PCINT0 Handler
	RJMP	M0 ; Timer0 Overflow Handler
	RJMP	M0 ; EEPROM Ready Handler
	RJMP	M0 ; Analog Comparator Handler
	RJMP	M0 ; Timer0 CompareA Handler
	RJMP	M0 ; Timer0 CompareB Handler
	RJMP	M0 ; Watchdog Interrupt Handler
	RJMP	M0 ; ADC Conversion Handler

	; Interupt handling

M0:	// Init stack 
	LDI		TempReg, low(RAMEND)
	OUT		SPL, TempReg
	CLI		

	// Configuring port
	SBI		DDRB,	ThermoPin
	SBI		PORTB,	ThermoPin

	LDI		TimeReg, 245
	RCALL	Delay

/*	// Setup DS18B20
	RCALL	ResetPulse					; Reset/Present signal
	
	LDI		CommandReg, SkipROM			; Skip ROM (0xCC)
	RCALL	SendCommand			

	LDI		CommandReg, WriteData		; Write SkratchPad(0x4E)
	RCALL	SendCommand
	
	LDI		CommandReg, 0b11111111		; Write Th (No alarm)
	RCALL	SendCommand
				
	LDI		CommandReg, 0b11111111		; Write Tl (No alarm)
	RCALL	SendCommand 

	LDI		CommandReg, 0b00000000		; Write ConfigReg (0.5C accuracy)
	RCALL	SendCommand			 
	
	LDI		TimeReg, ComDelay
	RCALL	Delay*/

	// Getting data from DS18B20
	RCALL	ResetPulse					; Reset/Present signal

	LDI		CommandReg, SkipROM			; Skip ROM (0xCC)
	RCALL	SendCommand			

	LDI		CommandReg, Converse		; Convert T (0x44)
	RCALL	SendCommand

W0:	RCALL	Read						; Waiting for conversion
	SBRS	CommandReg, 7				
	RJMP	W0

	RCALL	ResetPulse					; Reset/Present signal
	
	LDI		CommandReg, SkipROM			; Skip ROM (0xCC)
	RCALL	SendCommand			

	LDI		CommandReg, ReadData		; Read ScratchPad (0xBE)
	RCALL	SendCommand

	RCALL	ReadCommand					; Read Tl
	MOV		TByteL, CommandReg

	RCALL	ReadCommand					; Read Th
	MOV		TByteH, CommandReg

	// SPrepearing for send
E0:	SBI		DDRB,	MOSI
	CBI		DDRB,	MISO
	SBI		DDRB,	SC
	SBI		DDRB,	SCK
	SBI		DDRB,	CE
	
	SBI		PORTB,	SC
	CBI		PORTB,	CE
	CBI		PORTB,	SCK
	CBI		PORTB,	MISO
	
E1:	
	CBI		PORTB,	SC
	LDI		DataSPI, 0b00100111				; Write STATUS
	RCALL	SendSPI
	LDI		DataSPI, 0b01110000				; Init Data
	RCALL	SendSPI
	SBI		PORTB,	SC

	LDI		TimeReg,	15
	RCALL	Delay
	
	CBI		PORTB,	SC
	LDI		DataSPI, 0b00100000				; Write CONFIG
	RCALL	SendSPI
	LDI		DataSPI, 0b00001010				; Init CONFIG
	RCALL	SendSPI
	SBI		PORTB,	SC
	
	LDI		TimeReg,	15
	RCALL	Delay

	CBI		PORTB,	SC
	LDI		DataSPI, 0b10100000				; Send 
	RCALL	SendSPI
	MOV		DataSPI, TByteL					; Temp low byte
	RCALL	SendSPI
	MOV		DataSPI, TByteH					; Temp high byte
	RCALL	SendSPI
	SBI		PORTB,	SC

	SBI		PORTB,	CE						; In AIR mode
	LDI		TimeReg,	15
	RCALL	Delay
	CBI		PORTB,	CE						; Out AIR mode

	; Усыпляем передатчик
	CBI		PORTB,	SC
	LDI		DataSPI, 0b00100000				; Write CONFIG
	RCALL	SendSPI
	LDI		DataSPI, 0b00001000				; Init CONFIG
	RCALL	SendSPI
	SBI		PORTB,	SC
E2:
	LDI		TimeReg,	250
	RCALL	Delay
	RCALL	Delay
	RCALL	Delay
	RCALL	Delay

	RJMP	M0

// *************************************	
// FUNCTIONS
// *************************************	

; ---- Delay in us
Delay:
	PUSH	TempReg

	MOV		TempReg, TimeReg
L0:	NOP
	NOP
	DEC		TempReg
	BRBC	1, L0

	POP		TempReg
RET

; ---- Send command to DS18B20
SendCommand:
	PUSH	TempReg

	LDI		TempReg, 8
F0:	SBRS	CommandReg, 0
	RCALL	Write0
	SBRC	CommandReg, 0	
	RCALL	Write1

	ROR		CommandReg
	DEC		TempReg
	BRBC	1, F0

	POP		TempReg
	RET

; ---- Read data from DS18B20
ReadCommand:
	PUSH	TempReg

	LDI		TempReg, 8
F1:	
	LSR		CommandReg
	RCALL	Read
	DEC		TempReg
	BRBC	1, F1

	POP		TempReg
	RET

; ---- Send bit 1
Write1:
	SBI		PORTB, ThermoPin
	SBI		DDRB, ThermoPin

	LDI		TimeReg, 5
	RCALL	Delay

	CBI		PORTB, ThermoPin
	
	LDI		TimeReg, 5
	RCALL	Delay

	SBI		PORTB, ThermoPin
	
	LDI		TimeReg, 60
	RCALL	Delay	
RET

; ---- Send bit 0
Write0:
	SBI		DDRB, ThermoPin
	SBI		PORTB, ThermoPin

	LDI		TimeReg, 5
	RCALL	Delay

	CBI		PORTB, ThermoPin

	LDI		TimeReg, 60
	RCALL	Delay

	SBI		PORTB, ThermoPin	
RET

; ---- Read bit
Read:
	SBI		PORTB, ThermoPin
	SBI		DDRB, ThermoPin

	LDI		TimeReg, 5
	RCALL	Delay

	CBI		PORTB, ThermoPin

	LDI		TimeReg, 1
	RCALL	Delay

	CBI		DDRB, ThermoPin

	LDI		TimeReg, 15
	RCALL	Delay

	SBR		CommandReg, 0b10000000 
	SBIS	PINB, ThermoPin
	CBR		CommandReg, 0b10000000

	LDI		TimeReg, 45
	RCALL	Delay

	SBI		PORTB, ThermoPin
	SBI		DDRB, ThermoPin
RET

; ---- Send Reset pulse
ResetPulse:
	CBI		PORTB, ThermoPin

	LDI		TimeReg, 245
	RCALL	Delay
	RCALL	Delay

	CBI		DDRB, ThermoPin

	LDI		TimeReg, 65
	RCALL	Delay

	IN		TempReg, PINB
	SBRC	TempReg, ThermoPin
	RJMP	M0				; Sensor error

	LDI		TimeReg, 245
	RCALL	Delay
	RCALL	Delay

	SBI		PORTB, ThermoPin
	SBI		DDRB, ThermoPin
RET

; ---------------------------------------------------------
; ---- SPI Command ----------------------------------------
; ---------------------------------------------------------

; ---- Send Command to SPI
SendSPI:
	PUSH	TempReg

	LDI		TempReg, 8

S0:	SBRC	DataSPI, 7
	SBI		PORTB, MOSI
	SBRS	DataSPI, 7
	CBI		PORTB, MOSI
		
	LDI		TimeReg, 5
	RCALL	Delay	
	
	SBI		PORTB,	SCK
	
	LDI		TimeReg, 5
	RCALL	Delay	

	SBIC	PINB,	MISO
	SBR		DataSPI, 0b10000000
	SBIS	PINB,	MISO
	CBR		DataSPI, 0b10000000
	
	CBI		PORTB,	SCK
	
	ROL		DataSPI

	DEC		TempReg
	BRBC	1, S0

	LDI		TimeReg, 5
	RCALL	Delay	
			
	POP		TempReg	
RET

; EEPROM ==================================================
.ESEG ; 
