/*
 * _COMMON_INC_.inc
 *
 *  Created: 21.12.2014 14:21:51
 *  Author: Newton
 * File Name         : "SPI.inc"
 * Title             : DS18B20 thermometer library
 * Date              : 2014-12-21
 * Version           : 1.00
 * Support E-mail    : nagrom@inbox.ru
 * Target MCU        : ATtiny13A
 * 
 * DESCRIPTION
 * Provide functions for SPI interface 
*/

// *************************************	
// FUNCTIONS
// *************************************	
.CSEG

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
