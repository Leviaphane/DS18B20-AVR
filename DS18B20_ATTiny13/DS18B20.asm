/*
 * DS18B20.inc
 *
 *  Created: 21.12.2014 14:05:51
 *  Author: Newton
 * File Name         : "DS18B20.inc"
 * Title             : DS18B20 thermometer library
 * Date              : 2014-12-21
 * Version           : 1.00
 * Support E-mail    : nagrom@inbox.ru
 * Target MCU        : ATtiny13A
 * 
 * DESCRIPTION
 * Provide functions for control a DS18B20 digital thermometer
*/

// *************************************	
// FUNCTIONS
// *************************************	
.CSEG

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
	SBI		ThermoPort, ThermoPin
	SBI		DDRB, ThermoPin

	LDI		TimeReg, 5
	RCALL	Delay

	CBI		ThermoPort, ThermoPin
	
	LDI		TimeReg, 5
	RCALL	Delay

	SBI		ThermoPort, ThermoPin
	
	LDI		TimeReg, 60
	RCALL	Delay	
RET

; ---- Send bit 0
Write0:
	SBI		DDRB, ThermoPin
	SBI		ThermoPort, ThermoPin

	LDI		TimeReg, 5
	RCALL	Delay

	CBI		ThermoPort, ThermoPin

	LDI		TimeReg, 60
	RCALL	Delay

	SBI		ThermoPort, ThermoPin	
RET

; ---- Read bit
Read:
	SBI		ThermoPort, ThermoPin
	SBI		DDRB, ThermoPin

	LDI		TimeReg, 5
	RCALL	Delay

	CBI		ThermoPort, ThermoPin

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

	SBI		ThermoPort, ThermoPin
	SBI		DDRB, ThermoPin
RET

; ---- Send Reset pulse
ResetPulse:
	CBI		ThermoPort, ThermoPin

	LDI		TimeReg, 245
	RCALL	Delay
	RCALL	Delay

	CBI		DDRB, ThermoPin

	LDI		TimeReg, 65
	RCALL	Delay

	IN		TempReg, PINB
	SBRC	TempReg, ThermoPin
	LDI		CommandReg, 0xFF				; Sensor error

	LDI		TimeReg, 245
	RCALL	Delay
	RCALL	Delay

	SBI		ThermoPort, ThermoPin
	SBI		DDRB, ThermoPin
RET

