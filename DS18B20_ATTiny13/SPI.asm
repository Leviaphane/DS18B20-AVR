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

// *************************************	
// FUNCTIONS
// *************************************
.CSEG	
; ---- Init SPI
SPI_Init:
	SBI		SPI_DDR,	SPI_MOSI
	CBI		SPI_DDR,	SPI_MISO
	SBI		SPI_DDR,	SPI_SC
	SBI		SPI_DDR,	SPI_SCK
	SBI		SPI_DDR,	SPI_CE
	
	SBI		SPI_Port,	SPI_SC
	CBI		SPI_Port,	SPI_CE
	CBI		SPI_Port,	SPI_SCK
	CBI		SPI_Port,	SPI_MISO
RET

; ---- Send Command to SPI
SPI_Send:
	PUSH	TempReg

	LDI		TempReg, 8

S0:	SBRC	SPI_Data, 7
	SBI		SPI_Port, SPI_MOSI
	SBRS	SPI_Data, 7
	CBI		SPI_Port, SPI_MOSI
		
	LDI		TimeReg, 5
	RCALL	Delay	
	
	SBI		SPI_Port,	SPI_SCK
	
	LDI		TimeReg, 5
	RCALL	Delay	

	SBIC	SPI_PIN,	SPI_MISO
	SBR		SPI_Data,	0b10000000
	SBIS	SPI_PIN,	SPI_MISO
	CBR		SPI_Data,	0b10000000
	
	CBI		SPI_Port,	SPI_SCK
	
	ROL		SPI_Data

	DEC		TempReg
	BRBC	1, S0

	LDI		TimeReg, 5
	RCALL	Delay	
			
	POP		TempReg	
RET

