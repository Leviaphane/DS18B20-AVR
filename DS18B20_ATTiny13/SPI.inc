/*
 * SPI.inc
 *
 *  Created: 21.12.2014 14:21:51
 *  Author: Newton
 * File Name         : "SPI.inc"
 * Title             : SPI interface library
 * Date              : 2014-12-21
 * Version           : 1.00
 * Support E-mail    : nagrom@inbox.ru
 * Target MCU        : ATtiny13A
 * 
 * DESCRIPTION
 * Provide functions for SPI interface 
*/
#ifndef _SPI_INC_
#define _SPI_INC_
	.device ATtiny13A

	.def	SPI_Data	=	R19
	.def	SPI_Input	=	R21
	.def	SPI_Output	=	R22

	// Pins defenition
	.equ	SPI_Port		=	PORTB
	.equ	SPI_PIN			=	PINB
	.equ	SPI_DDR			=	DDRB
	.equ	SPI_MOSI		=	0
	.equ	SPI_MISO		=	1
	.equ	SPI_SCK			=	2
	.equ	SPI_CE			=	3
	.equ	SPI_SC			=	4
#endif  /* _SPI_INC_ */

