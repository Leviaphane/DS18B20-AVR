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
#ifndef _DS18B20_INC_
#define _DS18B20_INC_
	.device ATtiny13A

	.def	TByteL		=	R17
	.def	TByteH		=	R18
	.def	CommandReg	=	R20

	; Thermo command
	.equ	SkipROM		=	0b11001100		; Skip ROM (0xCC)		
	.equ	WriteData	=	0b01001110		; Write SkratchPad(0x4E)		
	.equ	ReadData	=	0b10111110		; Read ScratchPad (0xBE)		
	.equ	Converse	=	0b01000100		; Convert T (0x44)

	.equ	ThermoPort	=	PORTB
	.equ	ThermoPin	=	3
	.equ	ComDelay	=	50
#endif  /* _DS18B20_INC_ */
