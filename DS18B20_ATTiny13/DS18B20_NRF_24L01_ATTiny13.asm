.include "TN13ADEF.inc" 
.include "Common.inc"
.include "DS18B20.inc"
.include "SPI.inc"

	.equ	DeviceID	=	0b10101010
	.equ	TimeLim1	=	150
	.equ	TimeLim2	=	0
	.equ	TimeLim3	=	0

; MACRO ===================================================
; RAM =====================================================
.DSEG ; RAM
TimeCount:	.BYTE		3	;  Time counter	
ThermoData:	.BYTE		10	;  Data to transmit

; FLASH ===================================================
.CSEG ; Code segment
	; Interupt table
	.ORG	0
	RJMP	M0 ; Reset Handler
	RJMP	M0 ; IRQ0 Handler
	RJMP	M0 ; PCINT0 Handler
	RJMP	M1 ; Timer0 Overflow Handler
	RJMP	M0 ; EEPROM Ready Handler
	RJMP	M0 ; Analog Comparator Handler
	RJMP	M0 ; Timer0 CompareA Handler
	RJMP	M0 ; Timer0 CompareB Handler
	RJMP	M0 ; Watchdog Interrupt Handler
	RJMP	M0 ; ADC Conversion Handler

	; Interupt handling
M1: ; Timer0 Overflow
	LDI		R30,	low(TimeCount)
	LDI		R31,	high(TimeCount)
	LD		TempReg, Z
	DEC		TempReg
	ST		Z+, TempReg
	CPI		TempReg, 0xFF
	BRNE	M2

	LD		TempReg, Z
	DEC		TempReg
	ST		Z+, TempReg
	CPI		TempReg, 0xFF
	BRNE	M2
			
	LD		TempReg, Z
	DEC		TempReg
	ST		Z, TempReg
	CPI		TempReg, 0xFF
	BRNE	M2

	RJMP	M0

M2:	
	RETI

M0:	
	CLI	
	
	// Init stack 
	LDI		TempReg, low(RAMEND)
	OUT		SPL, TempReg
	
	// Setup timer
	LDI		TempReg, 0b00000101
	OUT		TCCR0B,	TempReg
	LDI		TempReg, 0b00000010
	OUT		TIMSK0, TempReg

	// Configuring port
	SBI		DDRB,	ThermoPin
	SBI		ThermoPort,	ThermoPin

	LDI		TimeReg, 245
	RCALL	Delay

	//RJMP	E2

	// Setup DS18B20
	RCALL	ResetPulse					; Reset/Present signal
	
	LDI		CommandReg, SkipROM			; Skip ROM (0xCC)
	RCALL	SendCommand			

	LDI		CommandReg, WriteData		; Write SkratchPad(0x4E)
	RCALL	SendCommand
	
	LDI		CommandReg, 0b11111111		; Write Th (No alarm)
	RCALL	SendCommand
				
	LDI		CommandReg, 0b11111111		; Write Tl (No alarm)
	RCALL	SendCommand 

	LDI		CommandReg, 0b01100000		; Write ConfigReg (0.5C accuracy)
	RCALL	SendCommand			 
	
	LDI		TimeReg, ComDelay
	RCALL	Delay

	// Getting data from DS18B20
	RCALL	ResetPulse					; Reset/Present signal

	LDI		CommandReg, SkipROM			; Skip ROM (0xCC)
	RCALL	SendCommand			

	LDI		CommandReg, Converse		; Convert T (0x44)
	RCALL	SendCommand

W0:	RCALL	Read						; Waiting for conversion
	SBRS	CommandReg, 7				
	RJMP	W0

	LDI		TimeReg, ComDelay
	RCALL	Delay

	RCALL	ResetPulse					; Reset/Present signal
	
	LDI		CommandReg, SkipROM			; Skip ROM (0xCC)
	RCALL	SendCommand			

	LDI		CommandReg, ReadData		; Read ScratchPad (0xBE)
	RCALL	SendCommand

	LDI		R30, low(ThermoData)
	LDI		R31, high(ThermoData)
	LDI		TempReg, DeviceID
	ST		Z+, TempReg

	LDI		TempReg, 9
W1:
	RCALL	ReadCommand					; Read data
	ST		Z+, CommandReg

	DEC		TempReg
	BRNE	W1

	// SPrepearing for send
E0:	
	RCALL	SPI_Init
	
E1:	
	CBI		SPI_Port,	SPI_SC
	LDI		SPI_Data,	0b00100111				; Write STATUS
	RCALL	SPI_Send
	LDI		SPI_Data,	0b01110000				; Init Data
	RCALL	SPI_Send
	SBI		SPI_Port,	SPI_SC

	LDI		TimeReg,	15
	RCALL	Delay
	
	CBI		SPI_Port,	SPI_SC
	LDI		SPI_Data,	0b00100000				; Write CONFIG
	RCALL	SPI_Send
	LDI		SPI_Data,	0b00001010				; Init CONFIG
	RCALL	SPI_Send
	SBI		SPI_Port,	SPI_SC

	LDI		TimeReg,	15
	RCALL	Delay
	
	CBI		SPI_Port,	SPI_SC
	LDI		SPI_Data,	0b11100001				; Flush TX
	RCALL	SPI_Send
	SBI		SPI_Port,	SPI_SC
	
	LDI		TimeReg,	15
	RCALL	Delay

	CBI		SPI_Port,	SPI_SC
	LDI		SPI_Data,	0b10100000				; Payload TX 
	RCALL	SPI_Send
	
	// Load data
	LDI		R30, low(ThermoData)
	LDI		R31, high(ThermoData)

	LDI		TempReg, 10
W2:
	LD		SPI_Data, Z+
	RCALL	SPI_Send

	DEC		TempReg
	BRNE	W2
	SBI		SPI_Port,	SPI_SC
	
	// Transmit data
	LDI		TimeReg,	15
	RCALL	Delay

	SBI		SPI_Port,	SPI_CE					; In AIR mode
	LDI		TimeReg,	25
	RCALL	Delay
	CBI		SPI_Port,	SPI_CE					; Out AIR mode

	; Усыпляем передатчик
	CBI		SPI_Port,	SPI_SC
	LDI		SPI_Data,	0b00100000				; Write CONFIG
	RCALL	SPI_Send
	LDI		SPI_Data,	0b00001000				; Init CONFIG
	RCALL	SPI_Send
	SBI		SPI_Port,	SPI_SC

E2: ; Turn on the timer and go to sleep
	

	LDI		R30, low(TimeCount)
	LDI		R31, high(TimeCount)

	LDI		TempReg, TimeLim1		
	ST		Z+,		TempReg

	LDI		TempReg, TimeLim2		
	ST		Z+,		TempReg

	LDI		TempReg, TimeLim3		
	ST		Z,		TempReg

	IN		TempReg, TIFR0
	ORI		TempReg, 0b00000010
	OUT		TIFR0, TempReg

	LDI		TempReg, 0
	OUT		TCNT0, TempReg
						
	SEI

	IN		TempReg, MCUCR
	ORI		TempReg, 0b00100000
	OUT		MCUCR,	TempReg 



E3:
	SLEEP	
	RJMP	E3

// Function ===============================================
.include "Common.asm"
.include "DS18B20.asm"
.include "SPI.asm"

; EEPROM ==================================================
.ESEG ; 
