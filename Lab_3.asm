; Name: Arnoldo Perez-Chavez
; Date: 2/11/2025

	; LCD Bit Definitions
	RS  BIT  P3.0
	RW  BIT  P3.1
	EN  BIT  P3.2

	; Starting Address RAM Address High and Low Byte Definitions
	SAH  EQU  30H
	SAL  EQU  31H

	; Destination Address RAM Address High and Low Byte Defintions
	DAH  EQU  32H
	DAL  EQU  33H

	; Block Size RAM Address High and Low Byte Definitions
	BSH  EQU  34H
	BSL  EQU  35H

	; End Address RAM Address High and Low Byte Definitions
	EAH  EQU  36H
	EAL  EQU  37H

	; Current Address RAM Address High and Low Byte Definitions
	CAH  EQU  38H
	CAL  EQU  39H

	; Find and Count Address Array Base and Length Definitions
	COUNT_HIGH              EQU  4BH
	COUNT_LOW				EQU  4CH
	ADDR_ARRAY_LENGTH_HIGH  EQU  4DH
	ADDR_ARRAY_LENGTH_LOW   EQU  4EH
	ADDR_ARRAY_END          EQU  4FH
	ADDR_ARRAY_BASE         EQU  50H

	ORG 00H
	SJMP START

START:
	MOV SP, #3AH
	LCALL PORT_INIT				; Initialize LCD Data and Command Ports
	LCALL LCD_INIT				; Initialize LCD Setting

HOME_SCREEN:
	LCALL LCD_RESETDISPLAY			; Clear Display to Prepare for Print
	MOV DPTR, #HOME_TEXT_0
	LCALL LCD_STRING			; Print 1st Line of Home Page
	LCALL LCD_NEWLINE
	MOV DPTR, #HOME_TEXT_1
	LCALL LCD_STRING			; Print 2nd Line of Home Page

HOME_PAGE_0:
	LCALL KEY_PRESS				; Wait for User Input
	CJNE A, #'D', HERE			; Input = D?
	CLR F0
	LJMP DUMP_MOVE_SCREEN			; Jump to RAM Dump. Else Skip Line.
HERE:
	CJNE A, #'0', HOME_PAGE_0		; Input = 0?
	LCALL LCD_DSR				; Switch to Page 0. Else, Jump to HOME_PAGE_0.

HOME_PAGE_1:
	LCALL KEY_PRESS				; Wait for User Input
	CJNE A, #'A', HERE1			; Input = A?
	SETB F0
	LJMP DUMP_MOVE_SCREEN			; Jump to RAM Move. Else, Skip Line.
HERE1:
	CJNE A, #'B', HERE2			; Input = B?
	SJMP CHECK_SCREEN			; Jump to RAM Check. Else, Skip Line.
HERE2:
	CJNE A, #'1', HERE10			; Input = 1?
	LCALL LCD_DSL				; Switch to Page 0. Else, Jump to HOME_PAGE_1.
	SJMP HOME_PAGE_0
HERE10:
	CJNE A, #'0', HOME_PAGE_1
	LCALL LCD_DSR

HOME_PAGE_2:
	LCALL KEY_PRESS
	CJNE A, #'E', HERE11
	LCALL RAM_EDIT
	SJMP HOME_SCREEN
HERE11:
	CJNE A, #'F', HERE12
	CLR F0
	LCALL RAM_FIND
	JZ OVER5
	LJMP RAM_ERROR
OVER5:
	SJMP HOME_SCREEN
HERE12:
	CJNE A, #'1', HERE13
	LCALL LCD_DSL
	SJMP HOME_PAGE_1
HERE13:
	CJNE A, #'0', HOME_PAGE_2
	LCALL LCD_DSR

HOME_PAGE_3:
	LCALL KEY_PRESS
	CJNE A, #'C', HERE14
	SETB F0
	LCALL RAM_FIND
	JZ OVER10
	LJMP RAM_ERROR
OVER10:
	SJMP HOME_SCREEN
HERE14:
	CJNE A, #'1', HOME_PAGE_3
	LCALL LCD_DSL
	SJMP HOME_PAGE_2

CHECK_SCREEN:
	LCALL LCD_RESETDISPLAY			; Clear Display and Reset Cursor
	MOV DPTR, #CHECK_TEXT_0			; Print RAM Check Screen
	LCALL LCD_STRING			; Prompt User to Input 2-digit Hex Value
	LCALL LCD_NEWLINE
	MOV DPTR, #CHECK_TEXT_1
	LCALL LCD_STRING

	MOV A, #0CBH				; Set Cursor to Proper Location on LCD
	LCALL LCD_CMD

	LCALL KEY_PRESS				; Wait for 1st Hex Digit
	LCALL LCD_CHAR				; Print 1st Digit to LCD
	LCALL ASCII_TO_HEX			; Convert the ASCII value to the Corresponding Hex Digit
	SWAP A					; Move Value to Upper Nibble
	MOV R4, A				; Save a Temporary Copy in R4
	LCALL KEY_PRESS				; Wait for 2nd Hex Digit
	LCALL LCD_CHAR				; Print 2nd Digit to LCD
	LCALL ASCII_TO_HEX			; Convert the ASCII value to the Corresponding Hex Digit
	ORL A, R4				; Combine the 1st digit and the 2nd Digit into a Single Byte

	LCALL LCD_CSR				; Move Cursor Past 'H' to Improve Screen Clarity

	LJMP RAM_CHECK				; Perform the RAM Check with the Given Byte

CHECK_COMPLETE:

	LCALL LCD_RESETDISPLAY			; If No Error, Show Success Message on LCD
	MOV DPTR, #CHECK_SUCCESS_0
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #SUCCESS_1
	LCALL LCD_STRING

	LJMP WAIT_EXIT				; Await User Input to Exit Screen

DUMP_MOVE_SCREEN:
	LCALL LCD_RESETDISPLAY			; Clear Display and Reset Cursor
	MOV DPTR, #START_ADDR_TEXT_0		; Prompt User for Starting Address of Dump or Move
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #START_ADDR_TEXT_1
	LCALL LCD_STRING

	MOV A, #0C6H
	LCALL LCD_CMD

	MOV R0, #SAH				; Initialize R0 with RAM Address where Starting Address
						; of Dump or Move will be Stored
	LCALL GET_WORD				; Get Address from User

	LCALL LCD_RESETDISPLAY			; Clear Display and Reset Cursor
	MOV DPTR, #DUMP_MOVE_TEXT_2		; Prompt User to Enter Desired Data Type
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #DUMP_MOVE_TEXT_3
	LCALL LCD_STRING

DUMP_MOVE_PAGE_0:
	LCALL KEY_PRESS				; Wait for User Input
	CJNE A, #'A', HERE3			; Input = A?
	MOV R4, #1				; User Chose Byte, Jump to Next Section. Else, Skip Lines.
	SJMP BLOCK_SIZE
HERE3:
	CJNE A, #'0', DUMP_MOVE_PAGE_0		; Input = 0?
	LCALL LCD_DSR				; Switch to Page 1. Else, Jump to DUMP_PAGE_0

DUMP_MOVE_PAGE_1:
	LCALL KEY_PRESS				; Wait for User Input
	CJNE A, #'1', HERE4			; Input = 1?
	LCALL LCD_DSL				; Switch to Page 0. Else, Skip Lines.
	SJMP DUMP_MOVE_PAGE_0
HERE4:
	CJNE A, #'B', HERE5			; Input = B?
	MOV R4, #2				; User Chose Word, Jump to Next Section. Else, Skip Lines.
	SJMP BLOCK_SIZE
HERE5:
	CJNE A, #'C', DUMP_MOVE_PAGE_1		; Input = C?
	MOV R4, #4				; User Chose Double Word, Continue to Next Section. Else, Jump to DUMP_PAGE_1.

BLOCK_SIZE:
	LCALL LCD_RESETDISPLAY			; Clear Display and Reset Cursor
	MOV DPTR, #BLOCK_SIZE_TEXT_0		; Prompt User for Block Size
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #BLOCK_SIZE_TEXT_1
	LCALL LCD_STRING

	MOV A, #0C6H
	LCALL LCD_CMD

	MOV R0, #BSH				; Initialize R0 with RAM Address where Block Size will be Stored
	LCALL GET_WORD				; Get Block Size from User

	LCALL BLOCK_SIZE_CHECK
	JZ NO_ERROR
	LJMP RAM_ERROR

NO_ERROR:
	JNB F0, RAM_DUMP			; If the MOVE Option was Chosen on the Home Screen, Jump to RAM_MOVE.
	LJMP RAM_MOVE

RAM_DUMP:
	CLR C					; Clear the Carry For Subtraction Without Borrow
	MOV A, EAL				; Move Unadjusted End Address (Low Byte) into A
	SUBB A, R4				; Adjust the End Address for the Block Size
	MOV EAL, A				; Stored Adjusted Low Byte into EAL (2FH)

	MOV A, EAH				; Move Unadjusted End Address (High Byte) into A
	SUBB A, #0				; Subtract Carry from Previous Subtraction Operation
	MOV EAH, A				; Store Adjusted High Byte into EAH (2EH)

	MOV DPH, SAH				; Initialize DPTR with the Starting Address of the DUMP
	MOV DPL, SAL

	MOV A, SAL				; First, Check if Only 1 Page Exists.
	CJNE A, EAL, CHECK_PAGE			; Check if SAL = EAL. If not, There are Multiple Pages.
	MOV A, SAH				; If so, Continue to Check SAH
	CJNE A, EAH, CHECK_PAGE			; Check if SAH = EAH. If not, There are Multiple Pages.
	LJMP ONLY_PAGE				; If so, Continue to Display a Single Page

CHECK_PAGE:
	MOV R7, DPH				; Store the Current Upper Byte of the Address (DPH) in R7
	MOV R6, DPL				; Store the Current Lower Byte of the Address (DPL) in R6

	LCALL LCD_RESETDISPLAY			; Clear the Display and Reset the Cursor

	MOV A, SAL				; Check if Current Address is Pointing to First Page
	CJNE A, DPL, NOT_FIRST_PAGE		; Check if SAL = DPL. If not, Current Address is not the First Page.
	MOV A, SAH				; If so, Continue to Check SAH.
	CJNE A, DPH, NOT_FIRST_PAGE		; Check if SAH = DPH. If not, Current Address is not the First Page.
	SJMP FIRST_PAGE				; If so, Continue to Display the First Page.

NOT_FIRST_PAGE:
	MOV A, EAL				; Check if Current Address is Pointing to Last Page
	CJNE A, DPL, MIDDLE_PAGE		; Check if EAL = DPL. If not, Current Address Must be Middle Page.
	MOV A, EAH				; If so, Continue to Check EAH.
	CJNE A, DPH, MIDDLE_PAGE		; Check if EAH = DPH. If not, Current Address Must be Middle Page.
						; If so, Continue to Display the Last Page.
LAST_PAGE:
	MOV DPTR, #DUMP_PAGE_1			; Display Data and ASCII Representation Labels onto the LCD
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #DUMP_PAGE_3
	LCALL LCD_STRING

	MOV DPH, R7				; Move the High Byte of the Current Address back into DPH
	MOV DPL, R6				; Move the Low Byte of the Current Address back into DPL
	LCALL DUMP_DATA				; Display the Contents of the Current Memory Address
						; (and its ASCII Representation) onto the LCD
HANDLE_INPUT_0:
	LCALL KEY_PRESS				; Await User Input
	CJNE A, #'E', HERE6			; Input = E? No, Check for Other Inputs.
	LJMP HOME_SCREEN			; Yes, Go Back to Home Screen.
HERE6:
	CJNE A, #'1', HANDLE_INPUT_0		; Input = 1? No, Check for Other Inputs.
	MOV DPH, R7				; Yes, Move the High Byte of the Current Address back into DPH
	MOV DPL, R6				; Move the Low Byte of the Current Address back into DPL
	LCALL PREVIOUS_PAGE			; Adjust the Current Address to Point to Previous Byte, Word, or Double Word
	SJMP CHECK_PAGE				; Check Which Page the Current Address is Now Pointing to

MIDDLE_PAGE:
	MOV DPTR, #DUMP_PAGE_1			; Display Data and ASCII Representation Labels onto the LCD
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #DUMP_PAGE_2
	LCALL LCD_STRING

	MOV DPH, R7				; Move the High Byte of the Current Address back into DPH
	MOV DPL, R6				; Move the Low Byte of the Current Address back into DPL
	LCALL DUMP_DATA				; Display the Contents of the Current Memory Address
						; (and its ASCII Representation) onto the LCD
HANDLE_INPUT_1:
	LCALL KEY_PRESS				; Await User Input
	CJNE A, #'E', HERE7			; Input = E? No, Check for Other Inputs.
	LJMP HOME_SCREEN			; Yes, Go Back to Home Screen.
HERE7:
	CJNE A, #'1', HERE8			; Input = 1? No, Check for Other Inputs.
	MOV DPH, R7				; Yes, Move the High Byte of the Current Address back into DPH
	MOV DPL, R6				; Move the Low Byte of the Current Address back into DPL
	LCALL PREVIOUS_PAGE			; Adjust the Current Address to Point to the Previous Byte, Word, or Double Word
	SJMP CHECK_PAGE				; Check Which Page the Current Address is Now Pointing to
HERE8:
	CJNE A, #'0', HANDLE_INPUT_1		; Input = 0? No, Check for Other Inputs.
	MOV DPH, R7				; Yes, Move the High Byte of the Current Address back into DPH
	MOV DPL, R6				; Move the Low Byte of the Current Address back into DPL
	LCALL NEXT_PAGE				; Adjust the Current Address to Point to the Next Byte, Word, or Double Word
	SJMP CHECK_PAGE				; Check Which Page the Current Address is Now Pointing to

FIRST_PAGE:
	MOV DPTR, #DUMP_PAGE_0			; Display Data and ASCII Representation Labels onto the LCD
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #DUMP_PAGE_2
	LCALL LCD_STRING

	MOV DPH, R7				; Move the High Byte of the Current Address back into DPH
	MOV DPL, R6				; Move the Low Byte of the Current Address back into DPL
	LCALL DUMP_DATA				; Display the Contents of the Current Memory Address
						; (and its ASCII Representation) onto the LCD
HANDLE_INPUT_2:
	LCALL KEY_PRESS				; Await User Input
	CJNE A, #'E', HERE9			; Input = E? No, Check for Other Inputs.
	LJMP HOME_SCREEN			; Yes, Go Back to Home Screen.
HERE9:
	CJNE A, #'0', HANDLE_INPUT_2		; Input = 0? No, Check for Other Inputs.
	MOV DPH, R7				; Yes, Move the High Byte of the Current Address back into DPH
	MOV DPL, R6				; Move the Low Byte of the Current Address back into DPL
	LCALL NEXT_PAGE				; Adjust the Current Address to Point to the Next Byte, Word, or Double Word
	LJMP CHECK_PAGE				; Check Which Page the Current Address is Now Pointing to

ONLY_PAGE:
	LCALL LCD_RESETDISPLAY			; Display Data and ASCII Representation Labels onto the LCD
	MOV DPTR, #DUMP_PAGE_0
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #DUMP_PAGE_3
	LCALL LCD_STRING

	MOV DPH, SAH				; Move the High Byte of the Starting Address into DPH
	MOV DPL, SAL				; Move the Low Byte of the Starting Address into DPL
	LCALL DUMP_DATA				; Display the Contents of the Current Memory Address
						; (and its ASCII Representation) onto the LCD
HANDLE_INPUT_3:
	LCALL KEY_PRESS				; Await User Input
	CJNE A, #'E', HERE9			; Input = E? No, Check for Other Inputs.
	LJMP HOME_SCREEN			; Yes, Go Back to Home Screen.

RAM_MOVE:
	LCALL LCD_RESETDISPLAY			; Clear Display and Reset Cursor
	MOV DPTR, #MOVE_TEXT_0			; Prompt User to Input Destination Address for Data
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #MOVE_TEXT_1
	LCALL LCD_STRING

	MOV A, #0C6H				; Move Cursor the Correct Position
	LCALL LCD_CMD

	MOV R0, #DAH				; Initialize R0 with RAM Address where Destination Address will be Stored
	LCALL GET_WORD				; Get Destination Address from User

						; Check if Block Size Leads to Address Overflow at Destination
	MOV A, DAL				; Move Low Byte of Destination Address into A
	ADD A, BSL				; Add Low Bytes of Destination Address and Block Size

	MOV A, DAH				; Move High Byte of Destination Address into A
	ADDC A, BSH				; Add High Bytes of Destination Address and Block Size

	MOV A, #4				; Move Error Code 4 into A (Destination Address Overflow)
	JNC NO_ERROR1				; If High Byte Addition Did Not Result in a Carry, Overflow Did Not Occur
	LJMP RAM_ERROR				; If C = 1, Destination Address Overflow

NO_ERROR1:
	LCALL MOVE_BYTES			; Copy Block from Starting Address to Destination Address

	LCALL LCD_RESETDISPLAY			; Once Move is Complete, Display a Success Message
	MOV DPTR, #MOVE_SUCCESS_0
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #SUCCESS_1
	LCALL LCD_STRING

	LJMP WAIT_EXIT				; Wait for User Input to Exit

RAM_CHECK:
	MOV DPH, #0FFH				; Initialize DPTR to Point to Addresses Starting with 0xFF00
LOOP1:
	MOV DPL, #0FFH
LOOP:
	MOV R4, A				; Save Copy of Check Value in R4
	MOVX @DPTR, A				; Move Check Value into XRAM Pointed to by DPTR
	MOVX A, @DPTR				; Move Value in XRAM Pointed to by DPTR into A
	CJNE A, 4, CHECK_ERROR			; If Value in A is Not Equal to Value in R4, Display Error

	CPL A					; Complement Check Value
	MOV R4, A				; Save a Copy of the Complemented Check Value in R4
	MOVX @DPTR, A				; Move Check Value into XRAM Pointed to by DPTR
	MOVX A, @DPTR				; Move Value in XRAM Pointed to by DPTR into A
	CJNE A, 4, CHECK_ERROR			; If Value in A is Not Equal to Value in R4, Display Error
	CPL A					; Complement Check Value to Get Original Check Value for Next Iteration
	DJNZ DPL, LOOP

	MOV R4, A				; Handle Case when DPL = 0x00. Otherwise, these locations are skipped
	MOVX @DPTR, A
	MOVX A, @DPTR
	CJNE A, 4, CHECK_ERROR

	CPL A
	MOV R4, A
	MOVX @DPTR, A
	MOVX A, @DPTR
	CJNE A, 4, CHECK_ERROR
	CPL A

	DJNZ DPH, LOOP1

	MOV DPL, #0FFH
LOOP2:
	MOV R4, A				; Start New Loop to Iterate Over Memory Locations
	MOVX @DPTR, A				; From 0x0000 to 0x00FF
	MOVX A, @DPTR
	CJNE A, 4, CHECK_ERROR

	CPL A
	MOV R4, A
	MOVX @DPTR, A
	MOVX A, @DPTR
	CJNE A, 4, CHECK_ERROR
	CPL A
	DJNZ DPL, LOOP2
	LJMP CHECK_COMPLETE

CHECK_ERROR:
	MOV A, #5
	SJMP RAM_ERROR

RAM_ERROR:
	MOV R7, A
	LCALL LCD_RESETDISPLAY
	MOV DPTR, #ERROR_TEXT_0
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #ERROR_TEXT_1
	LCALL LCD_STRING

	MOV A, R7
	CJNE A, #4, OVER2
	SJMP DEST_MEMORY_OVERFLOW		; If A = 4, Destination Memory Overflow Occurred
OVER2:
	CJNE A, #3, OVER3
	SJMP INVALID_BLOCK_SIZE			; If A = 3, Invalid Block Size Error Occurred
OVER3:
	CJNE A, #2, OVER4
	SJMP START_MEMORY_OVERFLOW		; If A = 2, Starting Address Memory Overflow Occurred
OVER4:
	CJNE A, #1, XRAM_CORRUPTED		; If A = 1, Zero Block Size Error Occurred
						; If A = any other value, Corruped External Memory Error Occurred

ZERO_BLOCK_SIZE:
	MOV A, #90H
	LCALL LCD_CMD

	MOV DPTR, #ERROR_TEXT_2
	LCALL LCD_STRING

	MOV A, #0D0H
	LCALL LCD_CMD

	MOV DPTR, #ERROR_TEXT_3
	LCALL LCD_STRING

	LCALL LCD_DSR

	SJMP WAIT_EXIT

START_MEMORY_OVERFLOW:
	MOV A, #90H
	LCALL LCD_CMD

	MOV DPTR, #ERROR_TEXT_4
	LCALL LCD_STRING

	MOV A, #0D0H
	LCALL LCD_CMD

	MOV DPTR, #ERROR_TEXT_6
	LCALL LCD_STRING

	LCALL LCD_DSR

	SJMP WAIT_EXIT

INVALID_BLOCK_SIZE:
	MOV A, #90H
	LCALL LCD_CMD

	MOV DPTR, #ERROR_TEXT_9
	LCALL LCD_STRING

	MOV A, #0D0H
	LCALL LCD_CMD

	MOV DPTR, #ERROR_TEXT_10
	LCALL LCD_STRING

	LCALL LCD_DSR

	SJMP WAIT_EXIT


DEST_MEMORY_OVERFLOW:
	MOV A, #90H
	LCALL LCD_CMD

	MOV DPTR, #ERROR_TEXT_5
	LCALL LCD_STRING

	MOV A, #0D0H
	LCALL LCD_CMD

	MOV DPTR, #ERROR_TEXT_6
	LCALL LCD_STRING

	LCALL LCD_DSR

	SJMP WAIT_EXIT

XRAM_CORRUPTED:
	MOV A, #90H
	LCALL LCD_CMD

	MOV DPTR, #ERROR_TEXT_7
	LCALL LCD_STRING

	MOV A, #0D0H
	LCALL LCD_CMD

	MOV DPTR, #ERROR_TEXT_8
	LCALL LCD_STRING

	LCALL LCD_DSR

WAIT_EXIT:
	LCALL KEY_PRESS				; Wait for User Input
	CJNE A, #'E', WAIT_EXIT			; Input = E?
	LJMP HOME_SCREEN			; Exit and Return to Home Screen. Else, Wait for User Input.





;================String Definitions================

HOME_TEXT_0:  DB  'Arnold - ECEN433A - Move      ', 7FH, '1', 'E - Edit      ', 7FH, '1', 'C - Count     ', 7FH, '1', 00H
HOME_TEXT_1:  DB  'D - Dump      0', 7EH, 'B - Check     0', 7EH, 'F - Find      0', 7EH, 00H

CHECK_TEXT_0: DB  'Enter 2-Digit   ', 00H
CHECK_TEXT_1: DB  'Check Val:   H  ', 00H
CHECK_SUCCESS_0: DB 'RAM Check       ', 00H

ERROR_TEXT_0:  DB 'RAM Operation   ', 00H
ERROR_TEXT_1:  DB 'Failure         ', 00H

ERROR_TEXT_2:  DB 'Zero Length     ', 00H
ERROR_TEXT_3:  DB 'Block Error   E', 01H, 00H

ERROR_TEXT_4:  DB 'Start Address   ', 00H

ERROR_TEXT_5:  DB 'Dest. Address   ', 00H
ERROR_TEXT_6:  DB 'Overflow      E', 01H, 00H

ERROR_TEXT_7:  DB 'External Memory ', 00H
ERROR_TEXT_8:  DB 'Corrupted     E', 01H, 00H

ERROR_TEXT_9:  DB 'Block Size Too  ', 00H
ERROR_TEXT_10:  DB 'Small         E', 01H, 00H

START_ADDR_TEXT_0:  DB 'Start Addr XXXXH', 00H
START_ADDR_TEXT_1:  DB 'Addr:     H     ', 00H

BLOCK_SIZE_TEXT_0:  DB 'Block Size XXXXH', 00H
BLOCK_SIZE_TEXT_1:  DB 'Size:     H', 00H

DUMP_MOVE_TEXT_2:  DB 'Select Data TypeB - Word', 00H
DUMP_MOVE_TEXT_3:  DB 'A - Byte      0', 7EH, 'C - Double    ', 7FH, '1', 00H

DUMP_PAGE_0:  DB 'DAT:            ', 00H
DUMP_PAGE_1:  DB 'DAT:          ', 7FH, '1', 00H
DUMP_PAGE_2:  DB 'ASCII:        0', 7EH, 00H
DUMP_PAGE_3:  DB 'ASCII:          ', 00H

MOVE_TEXT_0:  DB 'Dest. Addr XXXXH', 00H
MOVE_TEXT_1:  DB 'Addr:     H     ', 00H
MOVE_SUCCESS_0:  DB 'RAM Move        ', 00H

SUCCESS_1:  DB 'Successful    E', 01H, 00H

EDIT_TEXT_0:  DB 'OLD:   H      1', 01H, 00H
EDIT_TEXT_1:  DB 'NEW:   H      0', 7EH, 00H

FIND_TEXT_0:  DB 'Enter Search Key', 00H
FIND_TEXT_1:  DB 'Key:   H', 00H
FIND_TEXT_2:  DB 'Found Match   ',7FH, '1', 00H
FIND_TEXT_3:  DB 'Addr:     H   0', 7EH, 00H
FIND_TEXT_4:  DB 'No Matches      ', 00H
FIND_TEXT_5:  DB 'Found         E', 01H, 00H
FIND_TEXT_6:  DB '#Matches:   H ', 7FH, '1', 00H

;===================Lookup Tables==================

KEYPAD0:  DB '1', '2', '3', 'A'  ; 0th Row
KEYPAD1:  DB '4', '5', '6', 'B'  ; 1st Row
KEYPAD2:  DB '7', '8', '9', 'C'  ; 2nd Row
KEYPAD3:  DB 'F', '0', 'E', 'D'  ; 3rd Row

CHAR_PATTERN: DB 0EH, 01H, 05H, 09H, 1EH, 08H, 04H, 00H		; Return Symbol Character Pattern

;====================Subroutines===================

KEY_PRESS:
	MOV P1, #0F0H				; Ground All Rows
	MOV A, P1				; Read Keypad Input
	CJNE A, #0F0H, CHECK_ROWS		; If Key is Pressed, Check Individual Rows
	SJMP KEY_PRESS				; Otherwise, Check is Key is Pressed Again

CHECK_ROWS:
	MOV P1, #0FEH				; Ground the 0th Row
	MOV A, P1				; Read Columns
	ANL A, #0F0H				; Mask Unused Bits
	CJNE A, #0F0H, ROW_0

	MOV P1, #0FDH				; Ground the 1st Row
	MOV A, P1				; Read Columms
	ANL A, #0F0H				; Mask Unused Bits
	CJNE A, #0F0H, ROW_1

	MOV P1, #0FBH				; Ground the 2nd Row
	MOV A, P1				; Read Columns
	ANL A, #0F0H				; Mask Unused Bits
	CJNE A, #0F0H, ROW_2

	MOV P1, #0F7H				; Ground the 3rd Row
	MOV A, P1				; Read Columns
	ANL A, #0F0H				; Mask Unused Bits
	CJNE A, #0F0H, ROW_3

	SJMP KEY_PRESS				; If Match is Not Found, Jump Back to KEY_PRESS

ROW_0:
	MOV DPTR, #KEYPAD0
	SJMP FIND_COLUMN
ROW_1:
	MOV DPTR, #KEYPAD1
	SJMP FIND_COLUMN
ROW_2:
	MOV DPTR, #KEYPAD2
	SJMP FIND_COLUMN
ROW_3:
	MOV DPTR, #KEYPAD3

FIND_COLUMN:
	SWAP A
AGAIN:
	RRC A					; Rotate LSB into C
	JNC MATCH				; Jump to Match if C = 0
	INC DPTR				; Otherwise, Increment DPTR to Point to Next Byte
	SJMP AGAIN				; Jump to Start of Subroutine

MATCH:
	CLR A					; Clear the Contents of A to Prepare for Indexing
	MOVC A, @A+DPTR				; Move Byte Pointed to by DPTR into A
	MOV R3, A				; Save ASCII value in R1

KEY_RELEASE:
	MOV P1, #0F0H
	MOV A, P1
	CJNE A, #0F0H, KEY_RELEASE		; Wait Until Key is Released to Write Character to LCD
	MOV A, R3
	RET


ASCII_TO_HEX:
	CLR C					; 41H - 46H -> A - F
	SUBB A, #41H				; 30H - 39H -> 0 - 9
	JNC OVER				; Greater than 40H?
	ADD A, #11H				; No, Remove Upper Nibble and Return Hex Digit
	RET
OVER:
	ADD A, #0AH				; Reverse Previous Subtraction Operation
	RET


HEX_TO_ASCII:
	CLR C
	SUBB A, #0AH
	JC OVER1
	ADD A, #41H
	RET
OVER1:
	ADD A, #3AH
	RET


CGRAM_INIT:
	MOV DPTR, #CHAR_PATTERN
	MOV R0, #8
	MOV A, #48H
	LCALL LCD_CMD
LOOP3:
	CLR A
	MOVC A, @A+DPTR
	LCALL LCD_DATA
	INC DPTR
	DJNZ R0, LOOP3
	RET


PORT_INIT:
	MOV P0, #00H				; Initialize Port 0 as Outputs
	MOV P1, #0F0H				; Initialize Port 1 as Inputs
	MOV P3, #00H				; Initialize Port 3 as Outputs
	RET


LCD_INIT:
	MOV A, #38H				; Initialize 2 Lines and 5x7 Matrix
	LCALL LCD_CMD
	MOV A, #0EH				; Turn Display On with Blinking Cursor
	LCALL LCD_CMD
	MOV A, #01H				; Clear Display Screen
	LCALL LCD_CMD
	MOV A, #06H				; Shift Cursor to the Right Once
	LCALL LCD_CMD
	LCALL LCD_HOME
	LCALL CGRAM_INIT			; Initialize Character Generator RAM on LCD for Custom Characters
	MOV A, #80H				; Move Cursor to Beginning of 1st Line
	LCALL LCD_CMD
	RET


LCD_DATA:
	MOV P0, A				; Move Data to LCD Data Pins
	SETB RS					; Select LCD Data Register
	CLR RW					; Clear the R/W Pin to Write Data to LCD
	SETB EN					; Set Enable for LCD to Latch Data
	CLR EN					; Clear Enable to Finish Data Transfer
	RET


LCD_CMD:
	MOV P0, A				; Move Command to LCD Command Pins
	CLR RS					; Select the LCD Command Register
	CLR RW					; Clear the R/W Pin to Write Data to LCD
	SETB EN					; Set Enable for LCD to Latch Data
	CLR EN					; Clear Enable to Finish Data Transfer
	RET


LCD_CHAR:
	LCALL LCD_DATA
	RET


LCD_CLEAR:
	MOV A, #01H				; Clear the Display Screen
	LCALL LCD_CMD
	RET


LCD_1STLINE:
	MOV A, #80H				; Move Cursor to the Beginning of the 1st Line
	LCALL LCD_CMD
	RET


LCD_NEWLINE:
	MOV A, #0C0H				; Move Cursor to the Beginning of the 2nd Line
	LCALL LCD_CMD
	RET


LCD_STRING:
	CLR A
	MOVC A, @A+DPTR				; Move Byte Pointed to by DPTR into A
	JZ EXIT					; If Byte is 0, Jump to the End of the Subroutine
	LCALL LCD_CHAR				; Otherwise, Write Character to the LCD
	INC DPTR				; Increment DPTR to Point to Next Byte in Memory
	SJMP LCD_STRING				; Jump Back to the Beginning of the Subroutine
EXIT:
	RET


LCD_RESETDISPLAY:
	LCALL LCD_CLEAR
	LCALL LCD_HOME
	LCALL LCD_1STLINE
	RET


LCD_CSL:
	PUSH ACC
	MOV A, #10H
	LCALL LCD_CMD				; Shift Cursor Left Once
	POP ACC
	RET


LCD_CSR:
	PUSH ACC
	MOV A, #14H				; Shift Cursor Right Once
	LCALL LCD_CMD
	POP ACC
	RET


LCD_DSL:
	PUSH ACC
	PUSH 0

	MOV R0, #16
LOOP5:
	MOV A, #18H				; Shift Display Left Once
	LCALL LCD_CMD
	DJNZ R0, LOOP5

	POP 0
	POP ACC
	RET


LCD_DSR:
	PUSH ACC
	PUSH 0

	MOV R0, #16
LOOP4:
	MOV A, #1CH				; Shift Display Right Once
	LCALL LCD_CMD
	DJNZ R0, LOOP4

	POP 0
	POP ACC
	RET


LCD_HOME:
	PUSH ACC
	MOV A, #02H				; Undoes Shifts
	LCALL LCD_CMD
	POP ACC
	RET


GET_WORD:
	PUSH ACC

	MOV R5, #2				; Initialize Loop Index
LOOP6:
	LCALL KEY_PRESS				; Wait for User Input
	LCALL LCD_CHAR				; Print Character to LCD
	LCALL ASCII_TO_HEX			; Convert ASCII to Corresponding Hex Digit
	SWAP A					; Move Digit to Upper Nibble
	MOV R6, A				; Save a Temporary Copy in R6
	LCALL KEY_PRESS				; Wait for 2nd Hex Digit
	LCALL LCD_CHAR				; Print Character to LCD
	LCALL ASCII_TO_HEX			; Convert ASCII to Corresponding Hex Digit
	ORL A, R6				; Pack Both Digits Together into a Single Byte
	MOV @R0, A				; Store Packed Byte into RAM Location
	INC R0					; Point to Next Free Memory Location
	DJNZ R5, LOOP6

	LCALL LCD_CSR

	POP ACC
	RET


DUMP_DATA:
	PUSH DPH
	PUSH DPL

	MOV A, #85H
	LCALL LCD_CMD
	LCALL PUT_BYTES

	MOV A, #0C7H
	LCALL LCD_CMD
	LCALL PUT_ASCII_BYTES

	POP DPL
	POP DPH
	RET


PUT_BYTES:
	PUSH DPH
	PUSH DPL
	PUSH ACC
	PUSH 02H
	PUSH 05H


	MOV R5, 04H
LOOP7:
	MOVX A, @DPTR
	MOV R2, A

	SWAP A
	ANL A, #0FH
	LCALL HEX_TO_ASCII
	LCALL LCD_CHAR

	MOV A, R2
	ANL A, #0FH
	LCALL HEX_TO_ASCII
	LCALL LCD_CHAR

	INC DPTR

	DJNZ R5, LOOP7

	POP 05H
	POP 02H
	POP ACC
	POP DPL
	POP DPH
	RET


PUT_ASCII_BYTES:
	PUSH DPH
	PUSH DPL
	PUSH ACC
	PUSH 02H
	PUSH 05H

	MOV R5, 04H
LOOP8:
	MOVX A, @DPTR
	MOV R2, A

	LCALL LCD_CHAR
	INC DPTR
	DJNZ R5, LOOP8

	POP 05H
	POP 02H
	POP ACC
	POP DPL
	POP DPH
	RET


NEXT_PAGE:
	PUSH ACC

	MOV A, DPL
	ADD A, R4
	MOV DPL, A

	MOV A, DPH
	ADDC A, #0
	MOV DPH, A

	POP ACC
	RET


PREVIOUS_PAGE:
	PUSH ACC

	CLR C
	MOV A, DPL
	SUBB A, R4
	MOV DPL, A

	MOV A, DPH
	SUBB A, #0
	MOV DPH, A

	POP ACC
	RET


MOVE_BYTES:
	MOV R7, SAH
	MOV R6, SAL
LOOP9:
	MOV R5, 04H
LOOP10:
	MOV DPH, R7
	MOV DPL, R6
	MOVX A, @DPTR				; Retrieve Data from Starting Address

	MOV DPH, DAH
	MOV DPL, DAL
	MOVX @DPTR, A				; Store Data at Destination Address

	MOV A, R6
	ADD A, #1				; Increment Current Address
	MOV R6, A

	MOV A, R7
	ADDC A, #0				; If Previous Addition Resulted in a Carry, Add
	MOV R7, A				; Carry to Upper Byte of Current Address

	MOV A, DAL
	ADD A, #1				; Increment Destination Address
	MOV DAL, A

	MOV A, DAH
	ADDC A, #0				; If Previous Addition Resulted in a Carry, Add
	MOV DAH, A				; Carry to Upper Bytes of Destination Address

	DJNZ R5, LOOP10

	MOV A, R6
	CJNE A, EAL, LOOP9
	MOV A, R7
	CJNE A, EAH, LOOP9

	RET


RAM_EDIT:
	LCALL LCD_RESETDISPLAY

	MOV DPTR, #START_ADDR_TEXT_0
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #START_ADDR_TEXT_1
	LCALL LCD_STRING

	MOV A, #0C6H
	LCALL LCD_CMD

	MOV R0, #SAH				; Initialize R0 with RAM Address where Block Size will be Stored
	LCALL GET_WORD				; Get Starting Address from User

	MOV CAH, SAH
	MOV CAL, SAL

	LCALL LCD_RESETDISPLAY

	MOV DPTR, #EDIT_TEXT_0
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #EDIT_TEXT_1
	LCALL LCD_STRING

	CLR F0
EDIT_ADDRESS_CHECK:
	MOV A, CAH
	CJNE A, #0FFH, END_ADDRESS_CHECK
	MOV A, CAL
	CJNE A, #0FFH, END_ADDRESS_CHECK

	MOV A, #0CEH
	LCALL LCD_CMD

	MOV A, #' '
	LCALL LCD_CHAR
	LCALL LCD_CHAR
	SETB F0

END_ADDRESS_CHECK:

	MOV A, #085H
	LCALL LCD_CMD

	MOV DPH, CAH
	MOV DPL, CAL
	LCALL PUT_BYTE

	MOV A, #0C5H
	LCALL LCD_CMD

	LCALL GET_BYTE
	LCALL LCD_CSR
	MOVX @DPTR, A

AWAIT_USER_INPUT:
	LCALL KEY_PRESS
	CJNE A, #'1', HERE15
	RET
HERE15:
	JB F0, AWAIT_USER_INPUT
	CJNE A, #'0', AWAIT_USER_INPUT

	MOV A, CAL
	ADD A, #1
	MOV CAL, A
	MOV A, CAH
	ADDC A, #0
	MOV CAH, A

	MOV A, #0C5H
	LCALL LCD_CMD

	MOV A, #' '
	LCALL LCD_CHAR
	LCALL LCD_CHAR

	SJMP EDIT_ADDRESS_CHECK


PUT_BYTE:
	MOVX A, @DPTR
	MOV R3, A
	SWAP A
	ANL A, #0FH
	LCALL HEX_TO_ASCII
	LCALL LCD_CHAR

	MOV A, R3
	ANL A, #0FH
	LCALL HEX_TO_ASCII
	LCALL LCD_CHAR

	RET


GET_BYTE:
	PUSH DPH
	PUSH DPL

	LCALL KEY_PRESS
	LCALL LCD_CHAR
	LCALL ASCII_TO_HEX
	SWAP A
	MOV R4, A
	LCALL KEY_PRESS
	LCALL LCD_CHAR
	LCALL ASCII_TO_HEX
	ORL A, R4

	POP DPL
	POP DPH

	RET


RAM_FIND:
	LCALL LCD_RESETDISPLAY
	MOV DPTR, #START_ADDR_TEXT_0
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #START_ADDR_TEXT_1
	LCALL LCD_STRING

	MOV A, #0C6H
	LCALL LCD_CMD

	MOV R0, #SAH
	LCALL GET_WORD

	LCALL LCD_RESETDISPLAY
	MOV DPTR, #BLOCK_SIZE_TEXT_0
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #BLOCK_SIZE_TEXT_1
	LCALL LCD_STRING

	MOV A, #0C6H
	LCALL LCD_CMD

	MOV R0, #BSH
	LCALL GET_WORD

	MOV R4, #0
	ACALL BLOCK_SIZE_CHECK
	JZ NO_ERROR2
	RET

NO_ERROR2:
	LCALL LCD_RESETDISPLAY
	MOV DPTR, #FIND_TEXT_0			; Prompt User to Enter Search Key
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #FIND_TEXT_1
	LCALL LCD_STRING

	MOV A, #0C5H
	LCALL LCD_CMD				; Move Cursor to Correct Position

	LCALL GET_BYTE				; Get Search Key from User
	MOV R4, A				; Save Search Key in R2

	LCALL LCD_RESETDISPLAY

	MOV R0, #ADDR_ARRAY_BASE		; Initialize Pointers to the Base of the Address Array
	MOV R1, #ADDR_ARRAY_LENGTH_LOW		; to Prepare for Memory Search
	LCALL SEARCH_MEM

	MOV A, ADDR_ARRAY_LENGTH_LOW
	JNZ MATCHES_FOUND
	MOV A, ADDR_ARRAY_LENGTH_HIGH
	JNZ MATCHES_FOUND

NO_MATCHES_FOUND:
	MOV DPTR, #FIND_TEXT_4
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #FIND_TEXT_5
	LCALL LCD_STRING

WAIT_EXIT1:
	LCALL KEY_PRESS
	CJNE A, #'E', WAIT_EXIT1
	RET

MATCHES_FOUND:
	MOV DPTR, #FIND_TEXT_6
	JB F0, RAM_COUNT
	MOV DPTR, #FIND_TEXT_2
RAM_COUNT:
	LCALL LCD_STRING
	LCALL LCD_NEWLINE
	MOV DPTR, #FIND_TEXT_3
	LCALL LCD_STRING

	JNB F0, DISPLAY_MATCHING_ADDRESSES

	MOV A, #8AH
	LCALL LCD_CMD

	MOV A, COUNT_LOW
	MOV R6, A
	SWAP A
	ANL A, #0FH
	LCALL HEX_TO_ASCII
	LCALL LCD_CHAR
	MOV A, R6
	ANL A, #0FH
	LCALL HEX_TO_ASCII
	LCALL LCD_CHAR

DISPLAY_MATCHING_ADDRESSES:
	CLR F0
	MOV R5, #0				; Keep Track of Index of Array in R5
	MOV R0, #ADDR_ARRAY_BASE		; Reset R0 to Address of the Base of the Array

	MOV A, #0C6H
	LCALL LCD_CMD
	LCALL DISPLAY_ADDRESS

AWAIT_USER_INPUT1:
	LCALL KEY_PRESS
	CJNE A, #'0', OVER8
	MOV A, ADDR_ARRAY_END
	CJNE A, 0H, THERE
	SJMP AWAIT_USER_INPUT1
THERE:

	MOV A, #0C6H
	LCALL LCD_CMD

	INC R0
	INC R0
	LCALL DISPLAY_ADDRESS
	SJMP AWAIT_USER_INPUT1

OVER8:
	CJNE A, #'1', OVER9
	MOV A, #ADDR_ARRAY_BASE
	CJNE A, 0H, THERE1
	SJMP AWAIT_USER_INPUT1
THERE1:

	MOV A, #0C6H
	LCALL LCD_CMD

	DEC R0
	DEC R0
	LCALL DISPLAY_ADDRESS
	SJMP AWAIT_USER_INPUT1

OVER9:
	CJNE A, #'E', AWAIT_USER_INPUT1
	RET


SEARCH_MEM:
	MOV DPH, SAH
	MOV DPL, SAL

	MOV A, EAL
	ADD A, #1
	MOV EAL, A

	MOV A, EAH
	ADDC A, #0
	MOV EAH, A

LOOP11:
	MOVX A, @DPTR
	CJNE A, 04H, NOT_FOUND

FOUND:
	LCALL ARR_INSERT

	MOV A, COUNT_LOW
	ADD A, #1
	MOV COUNT_LOW, A

	MOV A, COUNT_HIGH
	ADDC A, #0
	MOV COUNT_HIGH, A
NOT_FOUND:
	MOV A, DPL
	ADD A, #1
	MOV DPL, A

	MOV A, DPH
	ADDC A, #0
	MOV DPH, A

	MOV A, DPH
	CJNE A, EAH, LOOP11
	MOV A, DPL
	CJNE A, EAL, LOOP11
	DEC R0
	DEC R0
	MOV ADDR_ARRAY_END, R0
	RET

BLOCK_SIZE_CHECK:

ZERO_LENGTH_CHECK:				; Check for Non-Zero Block Size
	CLR A					; Clear the Contents of A (A = 0x00)
	CJNE A, BSH, ADDR_OV_CHECK		; Check if High Byte of Block Size is 0.
						; If so, Continue. Else, Skip Lower Byte Check.
	CJNE A, BSL, ADDR_OV_CHECK		; Check if Low Byte of Block Size is also 0.
						; If so, Continue. Else, go to Next Check.
	MOV A, #1
	RET					; The High and Low Bytes of Block Size are 0. Display Error.

ADDR_OV_CHECK:					; Check if Block Size Causes Memory Overflow
	MOV A, SAL				; Move Low Byte of Starting Address into A
	ADD A, BSL				; Add Low Bytes of Starting Address and Block Size
	MOV EAL, A				; Store Low Byte of End Address (For RAM Dump)
	MOV A, SAH				; Move High Byte of Starting Address into A
	ADDC A, BSH				; Add High Bytes of Starting Address and Block Size with Carry from Previous Addition
	MOV EAH, A
	JNC INVALID_LENGTH_CHECK_0		; If C = 1 After Previous Addition, Memory Overflow. Display Error.

	MOV A, #2
	RET

INVALID_LENGTH_CHECK_0:
	MOV A, R4
	JZ NO_ERROR_DETECTED

	MOV A, BSH				; Check if Block Size is Greater than Data Type Length
	JNZ NO_ERROR_DETECTED			; If High Byte of Block Size (BSH) is not 0, Valid Block Size

	MOV A, BSL
	CJNE A, 04H, INVALID_LENGTH_CHECK_1	; Check if Lower Byte of Block Size (BSL) is Greater than Data Type Length
	SJMP NO_ERROR_DETECTED			; If Equal, Valid Block Size

INVALID_LENGTH_CHECK_1:
	JNC NO_ERROR_DETECTED			; If Comparison Did Not Result in a Carry/Borrow, Valid Block Size
	MOV A, #3				; If Carry/Borrow Did Occur, Data Type Length was Greater than Block Size
	RET					; Invalid Block Size

NO_ERROR_DETECTED:
	CLR A
	RET


ARR_INSERT:
	MOV A, R0
	JNZ OVER6
	RET
OVER6:
	MOV @R0, DPH
	INC R0
	MOV @R0, DPL
	INC R0

	MOV A, @R1
	ADD A, #2
	MOV @R1, A

	MOV A, ADDR_ARRAY_LENGTH_HIGH
	ADDC A, #0
	MOV ADDR_ARRAY_LENGTH_HIGH, A

	RET


DISPLAY_ADDRESS:
	MOV R7, #2
LOOP14:
	MOV A, @R0
	MOV R6, A
	SWAP A
	ANL A, #0FH
	LCALL HEX_TO_ASCII
	LCALL LCD_CHAR
	MOV A, R6
	ANL A, #0FH
	LCALL HEX_TO_ASCII
	LCALL LCD_CHAR
	INC R0
	DJNZ R7, LOOP14

	DEC R0
	DEC R0

	LCALL LCD_CSR
	RET


END
