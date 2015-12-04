; ===========================================================================
align macro alignment
	cnop 0,\alignment
    endm
; ===========================================================================
; this macro exists simply so I can be lazy. Instead of incbin/even combo you can just use this.
inceven		macro file
	incbin \file
	even
    endm
; ===========================================================================
vdpComm		macro ins,addr,type,rwd,end,end2
	if narg=5
		\ins #(((\type&\rwd)&3)<<30)|((\addr&$3FFF)<<16)|(((\type&\rwd)&$FC)<<2)|((\addr&$C000)>>14), \end

	elseif narg=6
		\ins #(((((\type&\rwd)&3)<<30)|((\addr&$3FFF)<<16)|(((\type&\rwd)&$FC)<<2)|((\addr&$C000)>>14))\end, \end2

	else
		\ins (((\type&\rwd)&3)<<30)|((\addr&$3FFF)<<16)|(((\type&\rwd)&$FC)<<2)|((\addr&$C000)>>14)
	endif
    endm

; ===========================================================================
; values for the type argument
VRAM =  %100001
CRAM =  %101011
VSRAM = %100101

; values for the rwd argument
READ =  %001100
WRITE = %000111
DMA =   %100111

; ===========================================================================
; tells the VDP to copy a region of 68k memory to VRAM or CRAM or VSRAM
dma68kToVDP macro source,dest,length,type
		lea	VDP_control_port,a5
		move.l	#(($9400|((((length)>>1)&$FF00)>>8))<<16)|($9300|(((length)>>1)&$FF)),(a5)
		move.l	#(($9600|((((source)>>1)&$FF00)>>8))<<16)|($9500|(((source)>>1)&$FF)),(a5)
		move.w	#$9700|(((((source)>>1)&$FF0000)>>16)&$7F),(a5)
	vdpComm	move.w,\dest,\type,DMA,>>16)&$FFFF,(a5)
	vdpComm	move.w,\dest,\type,DMA,)&$FFFF,DMA_Data_Thunk.w
		move.w	DMA_Data_Thunk.w,(a5)
    endm

; ===========================================================================
; tells the VDP to fill a region of VRAM with a certain byte
dmaFillVRAM macro byte,addr,length
	lea	VDP_control_port,a5
	move.w	#$8F01,(a5) ; VRAM pointer increment: $0001
	move.l	#(($9400|((((length)-1)&$FF00)>>8))<<16)|($9300|(((length)-1)&$FF)),(a5) ; DMA length ...
	move.w	#$9780,(a5) ; VRAM fill
	move.l	#$40000080|(((addr)&$3FFF)<<16)|(((addr)&$C000)>>14),(a5) ; Start at ...
	move.w	#(byte)<<8,(VDP_data_port).l ; Fill with byte
.loop\@	move.w	(a5),d1
	btst	#1,d1
	bne.s	.loop\@	; busy loop until the VDP is finished filling...
	move.w	#$8F02,(a5) ; VRAM pointer increment: $0002
    endm

; ==========================================================================
; fills a region of 68k RAM with 0
clearRAM	macro addr,length,dregsz,dregclr
	if (addr&$8000)=0
		lea	(addr).l,a1
	else
		lea	(addr).w,a1
	endif

	if narg<4
		moveq	#0,d0
 		if (addr&1)
			move.b	d0,(a1)+
		endif
	else
		moveq	#0,\dregclr
 		if (addr&1)
			move.b	\dregclr,(a1)+
		endif
	endif

	if narg<3
		move.w	#(length-(addr&1))/4-1,d1
	else
		move.w	#(length-(addr&1))/4-1,\dregsz
	endif

.loop\@
	if narg<4
		move.l	d0,(a1)+
	else
		move.l	\dregclr,(a1)+
	endif

	if narg<3
		dbf	d1,.loop\@
	else
		dbf	\dregsz,.loop\@
	endif

	if narg<4
		if ((length-(addr&1))&2)
			move.w	d0,(a1)+
		endif

		if ((length-(addr&1))&1)
			move.b	d0,(a1)+
		endif
	else
		if ((length-(addr&1))&2)
			move.w	\dregclr,(a1)+
		endif

		if ((length-(addr&1))&1)
			move.b	\dregclr,(a1)+
		endif
	endif
    endm

; this is same as clearRAM, but omits the moveq #0
clearRAM2	macro addr,length,dregsz,dregclr
	if (addr&$8000)=0
		lea	(addr).l,a1
	else
		lea	(addr).w,a1
	endif

	if (addr&1)
		if narg<4
			move.b	d0,(a1)+
		else
			move.b	\dregclr,(a1)+
		endif
	endif

len	= (length-(addr&1))/4-1
	if narg<3
		if len<$80
			moveq	#len,d1
		else
			move.w	#len,d1
		endif
	else
		if len<$80
			moveq	#len,\dregsz
		else
			move.w	#len,\dregsz
		endif
	endif

.loop\@
	if narg<4
		move.l	d0,(a1)+
	else
		move.l	\dregclr,(a1)+
	endif

	if narg<3
		dbf	d1,.loop\@
	else
		dbf	\dregsz,.loop\@
	endif

	if narg<4
		if ((length-(addr&1))&2)
			move.w	d0,(a1)+
		endif

		if ((length-(addr&1))&1)
			move.b	d0,(a1)+
		endif
	else
		if ((length-(addr&1))&2)
			move.w	\dregclr,(a1)+
		endif

		if ((length-(addr&1))&1)
			move.b	\dregclr,(a1)+
		endif
	endif
    endm

; ===========================================================================
; helper macro to recreate correct moveq statements from 0-$FF numbers
_moveq macro	val,dn
	if val<$80
		moveq	#val,\dn
	elseif val<=$FF
		moveq	#val|$FFFFFF00,\dn
	else
		inform 1,"value of \val is not expected"
	endif
    endm

; ===========================================================================
SRAMEnable	macro
	move.b	#1,$A130F1		; enable SRAM
	endm

SRAMDisable	macro
	move.b	#0,$A130F1		; disable SRAM
	endm
; ===========================================================================
; tells the Z80 to stop, and waits for it to finish stopping (acquire bus)
stopZ80 macro
		move.w	#$100,(Z80_bus_request).l ; stop the Z80
.loop\@		btst	#0,(Z80_bus_request).l
		bne.s	.loop\@ ; loop until it says it's stopped
    endm

; tells the Z80 to start again
startZ80 macro
		move.w	#0,(Z80_bus_request).l    ; start the Z80
    endm

; ===========================================================================
tribyte macro val
	rept narg
		dc.b (val>>16)&$FF,(val>>8)&$FF,val&$FF
	shift
	endr
    endm

; ===========================================================================
levselstr macro str
	dc.b strlen(\1)-1
.lc = 0
	rept strlen(\1)
.cc		substr .lc+1,.lc+1,\1

		if '\.cc'=' '
			dc.b 0

		elseif ('\.cc'>='0')&('\.cc'<='9')
			dc.b '\.cc'-'0'+16

		elseif ('\.cc'>='a')&('\.cc'<='z')
			dc.b '\.cc'-'a'+30

		elseif ('\.cc'>='A')&('\.cc'<='Z')
			dc.b '\.cc'-'A'+30

		elseif '\.cc'='*'
			dc.b 26

		elseif '\.cc'='©'
			dc.b 27

		elseif '\.cc'=':'
			dc.b 28

		elseif '\.cc'='.'
			dc.b 29
		endif

.lc =		.lc+1
	endr
    endm
; ===========================================================================
; this function allows creating files outside of the main assembly
; used mainly to create variable files for z80 drivers.
StartFile	macro name, file, org
	PUSHS
s_\name		SECTION	file(\file), org(\org)
    endm

; this ends a created file and returns assembly on main file
EndFile		macro
	POPS
    endm
; ===========================================================================
; this created DAC banks file, for S3 and S&K
DoDacFile	macro
	StartFile	DACbanks_\Z80DriverName, "Sound/Driver/DACbanks_\Z80DriverName\.bin", 0
	SetFileProperties

	DACMakeBankID 81, 81, 82_85, 82_85, 82_85, 82_85, 86, 87
	DACMakeBankID 88, 89, 8A_8B, 8A_8B, 8C, 8D_8E, 8D_8E, 8F
	DACMakeBankID 90_93, 90_93, 90_93, 90_93, 94_97, 94_97, 94_97, 94_97
	DACMakeBankID 98_9A, 98_9A, 98_9A, 9B
	chkChgDriver	id, "S3"	; hack to address DAC from S3's driver
	DACMakeBankID 9C, 9D, 9E, 9F
	DACMakeBankID A0, A1, A2, A3, A4, A5, A6, A7, A8
	DACMakeBankID A9, AA, AB, AC, AD_AE, AD_AE, AF_B0
	DACMakeBankID AF_B0, B1

	if id=0	; Sonic 3 and Sonic & Knuckles have separate sample for B2 & B3
		chkChgDriver	id, "SK"; hack to address DAC from SK's driver
		DACMakeBankID B2_B3, B2_B3
		chkChgDriver	id, "S3"; hack to address DAC from S3's driver
	else
		DACMakeBankID B2_B3_S3, B2_B3_S3
	endif

	DACMakeBankID B4C1_C4, B5, B6, B7
	DACMakeBankID B8_B9, B8_B9, BA, BB, BC, BD, BE, BF
	DACMakeBankID C0, B4C1_C4, B4C1_C4, B4C1_C4, B4C1_C4
	chkChgDriver	id, "SK"	; hack to address DAC from SK's driver

	EndFile
    endm

; used to setup variables for DAC files.
SetFileProperties	macro
	if "\Z80DriverName"="SK"
id = 	0
offs =	0
	else
id = 	1
offs =	-$200000
	endif
    endm

; ===========================================================================
; used to set a name for a sound driver, as to separate DAC sample listings.
; it helps to separate S3's and S&K's samples with the same name
StartDriver	macro name
Z80DriverName	equs \name
    endm
; ===========================================================================
; alignments possible to use with the macros
Z80BankAlign_None =	0
Z80BankAlign_Start =	1
Z80BankAlign_End =	2
Z80BankAlign_Both =	3

; declares start of a bank, and sets some variables
Z80Bank_Start	macro	alignbits, name
	if (\alignbits&Z80BankAlign_Start)<>0
		align $8000
	endif

z80BankAddr =	(offset(*)&$FF8000)
z80BankName 	equs \name
z80BankAlign =	alignbits
    endm

; macro to do everything needed for end of bank.
; also warns if the back overflows
Z80Bank_End	macro
	if offset(*)>z80BankAddr+$8000
		inform 1,"Z80 bank %s is too large! Its size is $%h, $%h bytes larger than max.", "\z80BankName", offset(*)-z80BankAddr, (offset(*)-z80BankAddr)-$8000
	else
		inform 0,"Z80 bank %s has $%h free bytes.", "\z80BankName", $8000-(offset(*)-z80BankAddr)
	endif

	if (z80BankAlign&Z80BankAlign_End)<>0
		align $8000
	endif
    endm

; ===========================================================================
; this special macro is used to generate music bank 00 and 02, as it uses custom padding
; which needs to be accounted for by using the length of each file
; and padding until only so much free space is in the bank
Z80Bank_StartBank	macro bankid, lable, filename
	; get total size of all the files
	Z80Bank_Mus00_GetSize \_

	; pad to the start of the first music file; calculated above
	dcb.b (($8000-(offset(*)&$7FFF))-Z80Bank_Mus00_Sz),$FF
	Z80Bank_Start Z80BankAlign_End,"Mus0\bankid"

	; include the files
	rept narg/2
\lable		incbin \filename
		shift
		shift
	endr

	; end the bank.
	Z80Bank_End
    endm

; macro for getting the total size of all files to include in bank Mus01
Z80Bank_Mus00_GetSize	macro bankid, lable, filename
Z80Bank_Mus00_Sz = 	0

	rept narg/2
Z80Bank_Mus00_Sz =	Z80Bank_Mus00_Sz+filesize(\filename)
		shift
		shift
	endr
    endm

; ===========================================================================
; macro to create multiple pointers with macro below
Z80PtrROMBank	macro addr
	rept narg
		Z80PtrROM \addr
		shift
	endr
    endm

; creates a single Z80 pointer (relative to bank) to a lable of choice
Z80PtrROM	macro addr, lable
	if narg>1
\lable
	endif

	dc.w	(((((addr-z80BankAddr)&$7FFF)+$8000)<<8)&$FF00)+((((addr-z80BankAddr)&$7FFF)+$8000)>>8)
    endm

; creates Z80 bank ID from ROM address
MakeBankID	macro addr
	rept narg
		dc.b ((addr&$7F8000)/$8000)
		shift
	endr
    endm

; creates Z80 bank ID from ROM address
MakeBankIDvar	macro addr, lable
\lable equ	((addr&$7F8000)/$8000)
    endm

; macro to create bank ID from DAC numbers (to simplify expressions)
DACMakeBankID	macro num
	rept narg
		MakeBankID (DAC\Z80DriverName\_\num\_Inc+offs)
		shift
	endr
    endm

; macro to create bank ID from DAC numbers (to simplify expressions)
MusMakeBankID	macro lable
	rept narg
		MakeBankID (\lable+offs)
		shift
	endr
    endm

; ===========================================================================
; simple macro to create little endian word values
littleEndian	macro value, lable
\lable equ 	(((value)<<8)&$FF00)|(((value)>>8)&$FF)
    endm

; simple macro to put a Z80 pointer (relative to bank) to a lable of choice
Z80PtrDo	macro addr, lable
\lable =	(((((addr-z80BankAddr)&$7FFF)+$8000)<<8)&$FF00)+((((addr-z80BankAddr)&$7FFF)+$8000)>>8)
    endm

; ===========================================================================
; special macro for including a DAC. This not only includes the file,
; but also creates the length and pointer information for later use in DAC_Setup
incDAC		macro name, ext
DAC\Z80DriverName\_\name\_Inc =	offset(*)
	incbin 'Sound/DAC/\name\.\ext'
		littleEndian offset(*)-DAC\Z80DriverName\_\name\_Inc, DAC\Z80DriverName\_\name\_Len
		Z80PtrDo DAC\Z80DriverName\_\name\_Inc, DAC\Z80DriverName\_\name\_Ptr
    endm

; ===========================================================================
; macro used to set up a DAC definition (pitch, length, pointer)
DAC_Setup macro rate, dacptr
	dc.b	\rate
	dc.w	DAC\Z80DriverName\_\dacptr\_Len
	dc.w	DAC\Z80DriverName\_\dacptr\_Ptr
    endm

; ===========================================================================
; this macro lists the universal DAC list definitions for each bank
; used to simplify the disassembly view.
DACBank_Defs	macro	id
	Z80Bank_Start Z80BankAlign_End,"DAC0\id"
	Z80PtrROMBank	DAC_81_Setup\id, DAC_82_Setup\id, DAC_83_Setup\id, DAC_84_Setup\id
	Z80PtrROMBank	DAC_85_Setup\id, DAC_86_Setup\id, DAC_87_Setup\id, DAC_88_Setup\id
	Z80PtrROMBank	DAC_89_Setup\id, DAC_8A_Setup\id, DAC_8B_Setup\id, DAC_8C_Setup\id
	Z80PtrROMBank	DAC_8D_Setup\id, DAC_8E_Setup\id, DAC_8F_Setup\id

	Z80PtrROMBank	DAC_90_Setup\id, DAC_91_Setup\id, DAC_92_Setup\id, DAC_93_Setup\id
	Z80PtrROMBank	DAC_94_Setup\id, DAC_95_Setup\id, DAC_96_Setup\id, DAC_97_Setup\id
	Z80PtrROMBank	DAC_98_Setup\id, DAC_99_Setup\id, DAC_9A_Setup\id, DAC_9B_Setup\id
	Z80PtrROMBank	DAC_9C_Setup\id, DAC_9D_Setup\id, DAC_9E_Setup\id, DAC_9F_Setup\id

	Z80PtrROMBank	DAC_A0_Setup\id, DAC_A1_Setup\id, DAC_A2_Setup\id, DAC_A3_Setup\id
	Z80PtrROMBank	DAC_A4_Setup\id, DAC_A5_Setup\id, DAC_A6_Setup\id, DAC_A7_Setup\id
	Z80PtrROMBank	DAC_A8_Setup\id, DAC_A9_Setup\id, DAC_AA_Setup\id, DAC_AB_Setup\id
	Z80PtrROMBank	DAC_AC_Setup\id, DAC_AD_Setup\id, DAC_AE_Setup\id, DAC_AF_Setup\id

	Z80PtrROMBank	DAC_B0_Setup\id, DAC_B1_Setup\id, DAC_B2_Setup\id, DAC_B3_Setup\id
	Z80PtrROMBank	DAC_B4_Setup\id, DAC_B5_Setup\id, DAC_B6_Setup\id, DAC_B7_Setup\id
	Z80PtrROMBank	DAC_B8_B9_Setup\id, DAC_B8_B9_Setup\id, DAC_BA_Setup\id, DAC_BB_Setup\id
	Z80PtrROMBank	DAC_BC_Setup\id, DAC_BD_Setup\id, DAC_BE_Setup\id, DAC_BF_Setup\id

	Z80PtrROMBank	DAC_C0_Setup\id, DAC_C1_Setup\id, DAC_C2_Setup\id, DAC_C3_Setup\id
	Z80PtrROMBank	DAC_C4_Setup\id
; ===========================================================================

DAC_81_Setup\id:	DAC_Setup $04,81
DAC_82_Setup\id:	DAC_Setup $0E,82_85
DAC_83_Setup\id:	DAC_Setup $14,82_85
DAC_84_Setup\id:	DAC_Setup $1A,82_85
DAC_85_Setup\id:	DAC_Setup $20,82_85
DAC_86_Setup\id:	DAC_Setup $04,86
DAC_87_Setup\id:	DAC_Setup $04,87
DAC_88_Setup\id:	DAC_Setup $06,88
DAC_89_Setup\id:	DAC_Setup $0A,89
DAC_8A_Setup\id:	DAC_Setup $14,8A_8B
DAC_8B_Setup\id:	DAC_Setup $1B,8A_8B
DAC_8C_Setup\id:	DAC_Setup $08,8C
DAC_8D_Setup\id:	DAC_Setup $0B,8D_8E
DAC_8E_Setup\id:	DAC_Setup $11,8D_8E
DAC_8F_Setup\id:	DAC_Setup $08,8F
DAC_90_Setup\id:	DAC_Setup $03,90_93
DAC_91_Setup\id:	DAC_Setup $07,90_93
DAC_92_Setup\id:	DAC_Setup $0A,90_93
DAC_93_Setup\id:	DAC_Setup $0E,90_93
DAC_94_Setup\id:	DAC_Setup $06,94_97
DAC_95_Setup\id:	DAC_Setup $0A,94_97
DAC_96_Setup\id:	DAC_Setup $0D,94_97
DAC_97_Setup\id:	DAC_Setup $12,94_97
DAC_98_Setup\id:	DAC_Setup $08,98_9A
DAC_99_Setup\id:	DAC_Setup $13,98_9A
DAC_9A_Setup\id:	DAC_Setup $16,98_9A
DAC_9B_Setup\id:	DAC_Setup $16,9B
	chkChgDriver	\id, "S3"	; hack to address DAC from S3's driver
DAC_A2_Setup\id:	DAC_Setup $0A,A2
DAC_A3_Setup\id:	DAC_Setup $18,A3
DAC_A4_Setup\id:	DAC_Setup $18,A4
DAC_A5_Setup\id:	DAC_Setup $0C,A5
DAC_A6_Setup\id:	DAC_Setup $09,A6
DAC_A7_Setup\id:	DAC_Setup $18,A7
DAC_A8_Setup\id:	DAC_Setup $18,A8
DAC_A9_Setup\id:	DAC_Setup $0C,A9
DAC_AA_Setup\id:	DAC_Setup $0A,AA
DAC_AB_Setup\id:	DAC_Setup $0D,AB
DAC_AC_Setup\id:	DAC_Setup $06,AC
DAC_AD_Setup\id:	DAC_Setup $10,AD_AE
DAC_AE_Setup\id:	DAC_Setup $18,AD_AE
DAC_AF_Setup\id:	DAC_Setup $09,AF_B0
DAC_B0_Setup\id:	DAC_Setup $12,AF_B0
DAC_B1_Setup\id:	DAC_Setup $18,B1

	if id=0	; Sonic 3 and Sonic & Knuckles have separate sample for B2 & B3
		chkChgDriver	\id, "SK"; hack to address DAC from SK's driver
DAC_B2_Setup\id:	DAC_Setup $16,B2_B3
DAC_B3_Setup\id:	DAC_Setup $20,B2_B3
		chkChgDriver	\id, "S3"; hack to address DAC from S3's driver
	else
DAC_B2_Setup\id:	DAC_Setup $16,B2_B3_S3
DAC_B3_Setup\id:	DAC_Setup $20,B2_B3_S3
	endif

DAC_B4_Setup\id:	DAC_Setup $0C,B4C1_C4
DAC_B5_Setup\id:	DAC_Setup $0C,B5
DAC_B6_Setup\id:	DAC_Setup $0C,B6
DAC_B7_Setup\id:	DAC_Setup $18,B7
DAC_B8_B9_Setup\id:	DAC_Setup $0C,B8_B9
DAC_BA_Setup\id:	DAC_Setup $18,BA
DAC_BB_Setup\id:	DAC_Setup $18,BB
DAC_BC_Setup\id:	DAC_Setup $18,BC
DAC_BD_Setup\id:	DAC_Setup $0C,BD
DAC_BE_Setup\id:	DAC_Setup $0C,BE
DAC_BF_Setup\id:	DAC_Setup $1C,BF
DAC_C0_Setup\id:	DAC_Setup $0B,C0
DAC_C1_Setup\id:	DAC_Setup $0F,B4C1_C4
DAC_C2_Setup\id:	DAC_Setup $11,B4C1_C4
DAC_C3_Setup\id:	DAC_Setup $12,B4C1_C4
DAC_C4_Setup\id:	DAC_Setup $0B,B4C1_C4
DAC_9C_Setup\id:	DAC_Setup $0A,9C
DAC_9D_Setup\id:	DAC_Setup $18,9D
DAC_9E_Setup\id:	DAC_Setup $18,9E
DAC_9F_Setup\id:	DAC_Setup $0C,9F
DAC_A0_Setup\id:	DAC_Setup $0C,A0
DAC_A1_Setup\id:	DAC_Setup $0A,A1
	chkChgDriver	\id, "SK"	; hack to address DAC from SK's driver
    endm

; this macro is used to quickly change between driver definitions
; S&K driver uses this to address S3's DAC samples on a few occasion
chkChgDriver	macro isS3, drvName
	if isS3=0
		StartDriver \drvName
	endif
    endm
; ===========================================================================
; this macro includes Sega PCM and all sound effects into the sfx bank
; used both by S3 and S&K drivers and is identical.
Z80Bank_SFX	macro	bankName
	Z80Bank_Start Z80BankAlign_End, \bankName
SEGA_PCM\Z80DriverName\:	incbin 'Sound/DAC/SEGA PCM.bin'
		even

Sound\Z80DriverName\_33:	incbin 'sound/sfx/33.bin'
Sound\Z80DriverName\_34:	incbin 'sound/sfx/34.bin'
Sound\Z80DriverName\_35:	incbin 'sound/sfx/35.bin'
Sound\Z80DriverName\_36:	incbin 'sound/sfx/36.bin'
Sound\Z80DriverName\_37:	incbin 'sound/sfx/37.bin'
Sound\Z80DriverName\_38:	incbin 'sound/sfx/38.bin'
Sound\Z80DriverName\_39:	incbin 'sound/sfx/39.bin'
Sound\Z80DriverName\_3A:	incbin 'sound/sfx/3A.bin'
Sound\Z80DriverName\_3B:	incbin 'sound/sfx/3B.bin'
Sound\Z80DriverName\_3C:	incbin 'sound/sfx/3C.bin'
Sound\Z80DriverName\_3D:	incbin 'sound/sfx/3D.bin'
Sound\Z80DriverName\_3E:	incbin 'sound/sfx/3E.bin'
Sound\Z80DriverName\_3F:	incbin 'sound/sfx/3F.bin'
Sound\Z80DriverName\_40:	incbin 'sound/sfx/40.bin'
Sound\Z80DriverName\_41:	incbin 'sound/sfx/41.bin'
Sound\Z80DriverName\_42:	incbin 'sound/sfx/42.bin'
Sound\Z80DriverName\_43:	incbin 'sound/sfx/43.bin'
Sound\Z80DriverName\_44:	incbin 'sound/sfx/44.bin'
Sound\Z80DriverName\_45:	incbin 'sound/sfx/45.bin'
Sound\Z80DriverName\_46:	incbin 'sound/sfx/46.bin'
Sound\Z80DriverName\_47:	incbin 'sound/sfx/47.bin'
Sound\Z80DriverName\_48:	incbin 'sound/sfx/48.bin'
Sound\Z80DriverName\_49:	incbin 'sound/sfx/49.bin'
Sound\Z80DriverName\_4A:	incbin 'sound/sfx/4A.bin'
Sound\Z80DriverName\_4B:	incbin 'sound/sfx/4B.bin'
Sound\Z80DriverName\_4C:	incbin 'sound/sfx/4C.bin'
Sound\Z80DriverName\_4D:	incbin 'sound/sfx/4D.bin'
Sound\Z80DriverName\_4E:	incbin 'sound/sfx/4E.bin'
Sound\Z80DriverName\_4F:	incbin 'sound/sfx/4F.bin'
Sound\Z80DriverName\_50:	incbin 'sound/sfx/50.bin'
Sound\Z80DriverName\_51:	incbin 'sound/sfx/51.bin'
Sound\Z80DriverName\_52:	incbin 'sound/sfx/52.bin'
Sound\Z80DriverName\_53:	incbin 'sound/sfx/53.bin'
Sound\Z80DriverName\_54:	incbin 'sound/sfx/54.bin'
Sound\Z80DriverName\_55:	incbin 'sound/sfx/55.bin'
Sound\Z80DriverName\_56:	incbin 'sound/sfx/56.bin'
Sound\Z80DriverName\_57:	incbin 'sound/sfx/57.bin'
Sound\Z80DriverName\_58:	incbin 'sound/sfx/58.bin'
Sound\Z80DriverName\_59:	incbin 'sound/sfx/59.bin'
Sound\Z80DriverName\_5A:	incbin 'sound/sfx/5A.bin'
Sound\Z80DriverName\_5B:	incbin 'sound/sfx/5B.bin'
Sound\Z80DriverName\_5C:	incbin 'sound/sfx/5C.bin'
Sound\Z80DriverName\_5D:	incbin 'sound/sfx/5D.bin'
Sound\Z80DriverName\_5E:	incbin 'sound/sfx/5E.bin'
Sound\Z80DriverName\_5F:	incbin 'sound/sfx/5F.bin'
Sound\Z80DriverName\_60:	incbin 'sound/sfx/60.bin'
Sound\Z80DriverName\_61:	incbin 'sound/sfx/61.bin'
Sound\Z80DriverName\_62:	incbin 'sound/sfx/62.bin'
Sound\Z80DriverName\_63:	incbin 'sound/sfx/63.bin'
Sound\Z80DriverName\_64:	incbin 'sound/sfx/64.bin'
Sound\Z80DriverName\_65:	incbin 'sound/sfx/65.bin'
Sound\Z80DriverName\_66:	incbin 'sound/sfx/66.bin'
Sound\Z80DriverName\_67:	incbin 'sound/sfx/67.bin'
Sound\Z80DriverName\_68:	incbin 'sound/sfx/68.bin'
Sound\Z80DriverName\_69:	incbin 'sound/sfx/69.bin'
Sound\Z80DriverName\_6A:	incbin 'sound/sfx/6A.bin'
Sound\Z80DriverName\_6B:	incbin 'sound/sfx/6B.bin'
Sound\Z80DriverName\_6C:	incbin 'sound/sfx/6C.bin'
Sound\Z80DriverName\_6D:	incbin 'sound/sfx/6D.bin'
Sound\Z80DriverName\_6E:	incbin 'sound/sfx/6E.bin'
Sound\Z80DriverName\_6F:	incbin 'sound/sfx/6F.bin'
Sound\Z80DriverName\_70:	incbin 'sound/sfx/70.bin'
Sound\Z80DriverName\_71:	incbin 'sound/sfx/71.bin'
Sound\Z80DriverName\_72:	incbin 'sound/sfx/72.bin'
Sound\Z80DriverName\_73:	incbin 'sound/sfx/73.bin'
Sound\Z80DriverName\_74:	incbin 'sound/sfx/74.bin'
Sound\Z80DriverName\_75:	incbin 'sound/sfx/75.bin'
Sound\Z80DriverName\_76:	incbin 'sound/sfx/76.bin'
Sound\Z80DriverName\_77:	incbin 'sound/sfx/77.bin'
Sound\Z80DriverName\_78:	incbin 'sound/sfx/78.bin'
Sound\Z80DriverName\_79:	incbin 'sound/sfx/79.bin'
Sound\Z80DriverName\_7A:	incbin 'sound/sfx/7A.bin'
Sound\Z80DriverName\_7B:	incbin 'sound/sfx/7B.bin'
Sound\Z80DriverName\_7C:	incbin 'sound/sfx/7C.bin'
Sound\Z80DriverName\_7D:	incbin 'sound/sfx/7D.bin'
Sound\Z80DriverName\_7E:	incbin 'sound/sfx/7E.bin'
Sound\Z80DriverName\_7F:	incbin 'sound/sfx/7F.bin'
Sound\Z80DriverName\_80:	incbin 'sound/sfx/80.bin'
Sound\Z80DriverName\_81:	incbin 'sound/sfx/81.bin'
Sound\Z80DriverName\_82:	incbin 'sound/sfx/82.bin'
Sound\Z80DriverName\_83:	incbin 'sound/sfx/83.bin'
Sound\Z80DriverName\_84:	incbin 'sound/sfx/84.bin'
Sound\Z80DriverName\_85:	incbin 'sound/sfx/85.bin'
Sound\Z80DriverName\_86:	incbin 'sound/sfx/86.bin'
Sound\Z80DriverName\_87:	incbin 'sound/sfx/87.bin'
Sound\Z80DriverName\_88:	incbin 'sound/sfx/88.bin'
Sound\Z80DriverName\_89:	incbin 'sound/sfx/89.bin'
Sound\Z80DriverName\_8A:	incbin 'sound/sfx/8A.bin'
Sound\Z80DriverName\_8B:	incbin 'sound/sfx/8B.bin'
Sound\Z80DriverName\_8C:	incbin 'sound/sfx/8C.bin'
Sound\Z80DriverName\_8D:	incbin 'sound/sfx/8D.bin'
Sound\Z80DriverName\_8E:	incbin 'sound/sfx/8E.bin'
Sound\Z80DriverName\_8F:	incbin 'sound/sfx/8F.bin'
Sound\Z80DriverName\_90:	incbin 'sound/sfx/90.bin'
Sound\Z80DriverName\_91:	incbin 'sound/sfx/91.bin'
Sound\Z80DriverName\_92:	incbin 'sound/sfx/92.bin'
Sound\Z80DriverName\_93:	incbin 'sound/sfx/93.bin'
Sound\Z80DriverName\_94:	incbin 'sound/sfx/94.bin'
Sound\Z80DriverName\_95:	incbin 'sound/sfx/95.bin'
Sound\Z80DriverName\_96:	incbin 'sound/sfx/96.bin'
Sound\Z80DriverName\_97:	incbin 'sound/sfx/97.bin'
Sound\Z80DriverName\_98:	incbin 'sound/sfx/98.bin'
Sound\Z80DriverName\_99:	incbin 'sound/sfx/99.bin'
Sound\Z80DriverName\_9A:	incbin 'sound/sfx/9A.bin'

	if "\Z80DriverName"="SK"; this sound effect is different (a little) in S3
Sound\Z80DriverName\_9B:	incbin 'sound/sfx/9B.bin'
	else
Sound\Z80DriverName\_9B:	incbin 'sound/sfx/9B.S3.bin'
	endif

Sound\Z80DriverName\_9C:	incbin 'sound/sfx/9C.bin'
Sound\Z80DriverName\_9D:	incbin 'sound/sfx/9D.bin'
Sound\Z80DriverName\_9E:	incbin 'sound/sfx/9E.bin'
Sound\Z80DriverName\_9F:	incbin 'sound/sfx/9F.bin'
Sound\Z80DriverName\_A0:	incbin 'sound/sfx/A0.bin'
Sound\Z80DriverName\_A1:	incbin 'sound/sfx/A1.bin'
Sound\Z80DriverName\_A2:	incbin 'sound/sfx/A2.bin'
Sound\Z80DriverName\_A3:	incbin 'sound/sfx/A3.bin'
Sound\Z80DriverName\_A4:	incbin 'sound/sfx/A4.bin'
Sound\Z80DriverName\_A5:	incbin 'sound/sfx/A5.bin'
Sound\Z80DriverName\_A6:	incbin 'sound/sfx/A6.bin'
Sound\Z80DriverName\_A7:	incbin 'sound/sfx/A7.bin'
Sound\Z80DriverName\_A8:	incbin 'sound/sfx/A8.bin'
Sound\Z80DriverName\_A9:	incbin 'sound/sfx/A9.bin'
Sound\Z80DriverName\_AA:	incbin 'sound/sfx/AA.bin'
Sound\Z80DriverName\_AB:	incbin 'sound/sfx/AB.bin'
Sound\Z80DriverName\_AC:	incbin 'sound/sfx/AC.bin'

	if "\Z80DriverName"="SK"; this sound effect is different (a little) in S3
Sound\Z80DriverName\_AD:	incbin 'sound/sfx/AD.bin'
	else
Sound\Z80DriverName\_AD:	incbin 'sound/sfx/AD.S3.bin'
	endif

Sound\Z80DriverName\_AE:	incbin 'sound/sfx/AE.bin'
Sound\Z80DriverName\_AF:	incbin 'sound/sfx/AF.bin'
Sound\Z80DriverName\_B0:	incbin 'sound/sfx/B0.bin'
Sound\Z80DriverName\_B1:	incbin 'sound/sfx/B1.bin'
Sound\Z80DriverName\_B2:	incbin 'sound/sfx/B2.bin'
Sound\Z80DriverName\_B3:	incbin 'sound/sfx/B3.bin'
Sound\Z80DriverName\_B4:	incbin 'sound/sfx/B4.bin'
Sound\Z80DriverName\_B5:	incbin 'sound/sfx/B5.bin'
Sound\Z80DriverName\_B6:	incbin 'sound/sfx/B6.bin'
Sound\Z80DriverName\_B7:	incbin 'sound/sfx/B7.bin'
Sound\Z80DriverName\_B8:	incbin 'sound/sfx/B8.bin'
Sound\Z80DriverName\_B9:	incbin 'sound/sfx/B9.bin'
Sound\Z80DriverName\_BA:	incbin 'sound/sfx/BA.bin'
Sound\Z80DriverName\_BB:	incbin 'sound/sfx/BB.bin'
Sound\Z80DriverName\_BC:	incbin 'sound/sfx/BC.bin'
Sound\Z80DriverName\_BD:	incbin 'sound/sfx/BD.bin'
Sound\Z80DriverName\_BE:	incbin 'sound/sfx/BE.bin'
Sound\Z80DriverName\_BF:	incbin 'sound/sfx/BF.bin'
Sound\Z80DriverName\_C0:	incbin 'sound/sfx/C0.bin'
Sound\Z80DriverName\_C1:	incbin 'sound/sfx/C1.bin'
Sound\Z80DriverName\_C2:	incbin 'sound/sfx/C2.bin'
Sound\Z80DriverName\_C3:	incbin 'sound/sfx/C3.bin'
Sound\Z80DriverName\_C4:	incbin 'sound/sfx/C4.bin'
Sound\Z80DriverName\_C5:	incbin 'sound/sfx/C5.bin'
Sound\Z80DriverName\_C6:	incbin 'sound/sfx/C6.bin'
Sound\Z80DriverName\_C7:	incbin 'sound/sfx/C7.bin'
Sound\Z80DriverName\_C8:	incbin 'sound/sfx/C8.bin'
Sound\Z80DriverName\_C9:	incbin 'sound/sfx/C9.bin'
Sound\Z80DriverName\_CA:	incbin 'sound/sfx/CA.bin'
Sound\Z80DriverName\_CB:	incbin 'sound/sfx/CB.bin'
Sound\Z80DriverName\_CC:	incbin 'sound/sfx/CC.bin'
Sound\Z80DriverName\_CD:	incbin 'sound/sfx/CD.bin'
Sound\Z80DriverName\_CE:	incbin 'sound/sfx/CE.bin'
Sound\Z80DriverName\_CF:	incbin 'sound/sfx/CF.bin'
Sound\Z80DriverName\_D0:	incbin 'sound/sfx/D0.bin'
Sound\Z80DriverName\_D1:	incbin 'sound/sfx/D1.bin'
Sound\Z80DriverName\_D2:	incbin 'sound/sfx/D2.bin'
Sound\Z80DriverName\_D3:	incbin 'sound/sfx/D3.bin'
Sound\Z80DriverName\_D4:	incbin 'sound/sfx/D4.bin'
Sound\Z80DriverName\_D5:	incbin 'sound/sfx/D5.bin'
Sound\Z80DriverName\_D6:	incbin 'sound/sfx/D6.bin'
Sound\Z80DriverName\_D7:	incbin 'sound/sfx/D7.bin'
Sound\Z80DriverName\_D8:	incbin 'sound/sfx/D8.bin'
Sound\Z80DriverName\_D9:	incbin 'sound/sfx/D9.bin'
Sound\Z80DriverName\_DA:	incbin 'sound/sfx/DA.bin'
Sound\Z80DriverName\_DB:	incbin 'sound/sfx/DB.bin'
	Z80Bank_End
    endm
; ===========================================================================
; this creates pointers for all SFX in S3 and S&K.
Z80createSFXptrs	macro
	Z80PtrROMBank	Sound\Z80DriverName\_33, Sound\Z80DriverName\_34
	Z80PtrROMBank	Sound\Z80DriverName\_35, Sound\Z80DriverName\_36
	Z80PtrROMBank	Sound\Z80DriverName\_37, Sound\Z80DriverName\_38
	Z80PtrROMBank	Sound\Z80DriverName\_39, Sound\Z80DriverName\_3A
	Z80PtrROMBank	Sound\Z80DriverName\_3B, Sound\Z80DriverName\_3C
	Z80PtrROMBank	Sound\Z80DriverName\_3D, Sound\Z80DriverName\_3E
	Z80PtrROMBank	Sound\Z80DriverName\_3F, Sound\Z80DriverName\_40

	Z80PtrROMBank	Sound\Z80DriverName\_41, Sound\Z80DriverName\_42
	Z80PtrROMBank	Sound\Z80DriverName\_43, Sound\Z80DriverName\_44
	Z80PtrROMBank	Sound\Z80DriverName\_45, Sound\Z80DriverName\_46
	Z80PtrROMBank	Sound\Z80DriverName\_47, Sound\Z80DriverName\_48
	Z80PtrROMBank	Sound\Z80DriverName\_49, Sound\Z80DriverName\_4A
	Z80PtrROMBank	Sound\Z80DriverName\_4B, Sound\Z80DriverName\_4C
	Z80PtrROMBank	Sound\Z80DriverName\_4D, Sound\Z80DriverName\_4E
	Z80PtrROMBank	Sound\Z80DriverName\_4F, Sound\Z80DriverName\_50

	Z80PtrROMBank	Sound\Z80DriverName\_51, Sound\Z80DriverName\_52
	Z80PtrROMBank	Sound\Z80DriverName\_53, Sound\Z80DriverName\_54
	Z80PtrROMBank	Sound\Z80DriverName\_55, Sound\Z80DriverName\_56
	Z80PtrROMBank	Sound\Z80DriverName\_57, Sound\Z80DriverName\_58
	Z80PtrROMBank	Sound\Z80DriverName\_59, Sound\Z80DriverName\_5A
	Z80PtrROMBank	Sound\Z80DriverName\_5B, Sound\Z80DriverName\_5C
	Z80PtrROMBank	Sound\Z80DriverName\_5D, Sound\Z80DriverName\_5E
	Z80PtrROMBank	Sound\Z80DriverName\_5F, Sound\Z80DriverName\_60

	Z80PtrROMBank	Sound\Z80DriverName\_61, Sound\Z80DriverName\_62
	Z80PtrROMBank	Sound\Z80DriverName\_63, Sound\Z80DriverName\_64
	Z80PtrROMBank	Sound\Z80DriverName\_65, Sound\Z80DriverName\_66
	Z80PtrROMBank	Sound\Z80DriverName\_67, Sound\Z80DriverName\_68
	Z80PtrROMBank	Sound\Z80DriverName\_69, Sound\Z80DriverName\_6A
	Z80PtrROMBank	Sound\Z80DriverName\_6B, Sound\Z80DriverName\_6C
	Z80PtrROMBank	Sound\Z80DriverName\_6D, Sound\Z80DriverName\_6E
	Z80PtrROMBank	Sound\Z80DriverName\_6F, Sound\Z80DriverName\_70

	Z80PtrROMBank	Sound\Z80DriverName\_71, Sound\Z80DriverName\_72
	Z80PtrROMBank	Sound\Z80DriverName\_73, Sound\Z80DriverName\_74
	Z80PtrROMBank	Sound\Z80DriverName\_75, Sound\Z80DriverName\_76
	Z80PtrROMBank	Sound\Z80DriverName\_77, Sound\Z80DriverName\_78
	Z80PtrROMBank	Sound\Z80DriverName\_79, Sound\Z80DriverName\_7A
	Z80PtrROMBank	Sound\Z80DriverName\_7B, Sound\Z80DriverName\_7C
	Z80PtrROMBank	Sound\Z80DriverName\_7D, Sound\Z80DriverName\_7E
	Z80PtrROMBank	Sound\Z80DriverName\_7F, Sound\Z80DriverName\_80

	Z80PtrROMBank	Sound\Z80DriverName\_81, Sound\Z80DriverName\_82
	Z80PtrROMBank	Sound\Z80DriverName\_83, Sound\Z80DriverName\_84
	Z80PtrROMBank	Sound\Z80DriverName\_85, Sound\Z80DriverName\_86
	Z80PtrROMBank	Sound\Z80DriverName\_87, Sound\Z80DriverName\_88
	Z80PtrROMBank	Sound\Z80DriverName\_89, Sound\Z80DriverName\_8A
	Z80PtrROMBank	Sound\Z80DriverName\_8B, Sound\Z80DriverName\_8C
	Z80PtrROMBank	Sound\Z80DriverName\_8D, Sound\Z80DriverName\_8E
	Z80PtrROMBank	Sound\Z80DriverName\_8F, Sound\Z80DriverName\_90

	Z80PtrROMBank	Sound\Z80DriverName\_91, Sound\Z80DriverName\_92
	Z80PtrROMBank	Sound\Z80DriverName\_93, Sound\Z80DriverName\_94
	Z80PtrROMBank	Sound\Z80DriverName\_95, Sound\Z80DriverName\_96
	Z80PtrROMBank	Sound\Z80DriverName\_97, Sound\Z80DriverName\_98
	Z80PtrROMBank	Sound\Z80DriverName\_99, Sound\Z80DriverName\_9A
	Z80PtrROMBank	Sound\Z80DriverName\_9B, Sound\Z80DriverName\_9C
	Z80PtrROMBank	Sound\Z80DriverName\_9D, Sound\Z80DriverName\_9E
	Z80PtrROMBank	Sound\Z80DriverName\_9F, Sound\Z80DriverName\_A0

	Z80PtrROMBank	Sound\Z80DriverName\_A1, Sound\Z80DriverName\_A2
	Z80PtrROMBank	Sound\Z80DriverName\_A3, Sound\Z80DriverName\_A4
	Z80PtrROMBank	Sound\Z80DriverName\_A5, Sound\Z80DriverName\_A6
	Z80PtrROMBank	Sound\Z80DriverName\_A7, Sound\Z80DriverName\_A8
	Z80PtrROMBank	Sound\Z80DriverName\_A9, Sound\Z80DriverName\_AA
	Z80PtrROMBank	Sound\Z80DriverName\_AB, Sound\Z80DriverName\_AC
	Z80PtrROMBank	Sound\Z80DriverName\_AD, Sound\Z80DriverName\_AE
	Z80PtrROMBank	Sound\Z80DriverName\_AF, Sound\Z80DriverName\_B0

	Z80PtrROMBank	Sound\Z80DriverName\_B1, Sound\Z80DriverName\_B2
	Z80PtrROMBank	Sound\Z80DriverName\_B3, Sound\Z80DriverName\_B4
	Z80PtrROMBank	Sound\Z80DriverName\_B5, Sound\Z80DriverName\_B6
	Z80PtrROMBank	Sound\Z80DriverName\_B7, Sound\Z80DriverName\_B8
	Z80PtrROMBank	Sound\Z80DriverName\_B9, Sound\Z80DriverName\_BA
	Z80PtrROMBank	Sound\Z80DriverName\_BB, Sound\Z80DriverName\_BC
	Z80PtrROMBank	Sound\Z80DriverName\_BD, Sound\Z80DriverName\_BE
	Z80PtrROMBank	Sound\Z80DriverName\_BF, Sound\Z80DriverName\_C0

	Z80PtrROMBank	Sound\Z80DriverName\_C1, Sound\Z80DriverName\_C2
	Z80PtrROMBank	Sound\Z80DriverName\_C3, Sound\Z80DriverName\_C4
	Z80PtrROMBank	Sound\Z80DriverName\_C5, Sound\Z80DriverName\_C6
	Z80PtrROMBank	Sound\Z80DriverName\_C7, Sound\Z80DriverName\_C8
	Z80PtrROMBank	Sound\Z80DriverName\_C9, Sound\Z80DriverName\_CA
	Z80PtrROMBank	Sound\Z80DriverName\_CB, Sound\Z80DriverName\_CC
	Z80PtrROMBank	Sound\Z80DriverName\_CD, Sound\Z80DriverName\_CE
	Z80PtrROMBank	Sound\Z80DriverName\_CF, Sound\Z80DriverName\_D0

	Z80PtrROMBank	Sound\Z80DriverName\_D1, Sound\Z80DriverName\_D2
	Z80PtrROMBank	Sound\Z80DriverName\_D3, Sound\Z80DriverName\_D4
	Z80PtrROMBank	Sound\Z80DriverName\_D5, Sound\Z80DriverName\_D6
	Z80PtrROMBank	Sound\Z80DriverName\_D7, Sound\Z80DriverName\_D8
	Z80PtrROMBank	Sound\Z80DriverName\_D9, Sound\Z80DriverName\_DA
	Z80PtrROMBank	Sound\Z80DriverName\_DB, Sound\Z80DriverName\_DB
	Z80PtrROMBank	Sound\Z80DriverName\_DB, Sound\Z80DriverName\_DB
			; last SFX is repeated until $E0;
			; after that coordination flags are reserved.
	Z80PtrROMBank	Sound\Z80DriverName\_DB
    endm
; ===========================================================================
