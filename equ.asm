; ---------------------------------------------------------------------------
	opt l+		; . is local lable symbol
	opt ae-		; no automatic even on dc/ds/rs w/l
	opt w-		; fuck the errors

; ---------------------------------------------------------------------------
; Z80 addresses
Z80_RAM =			$A00000 ; start of Z80 RAM
Z80_RAM_end =			$A02000 ; end of non-reserved Z80 RAM
Z80_bus_request =		$A11100
Z80_reset =			$A11200

SRAM_access_flag =		$A130F1
Security_addr =			$A14000

; ---------------------------------------------------------------------------
; I/O Area
HW_Version =			$A10001
HW_Port_1_Data =		$A10003
HW_Port_2_Data =		$A10005
HW_Expansion_Data =		$A10007
HW_Port_1_Control =		$A10009
HW_Port_2_Control =		$A1000B
HW_Expansion_Control =		$A1000D
HW_Port_1_TxData =		$A1000F
HW_Port_1_RxData =		$A10011
HW_Port_1_SCtrl =		$A10013
HW_Port_2_TxData =		$A10015
HW_Port_2_RxData =		$A10017
HW_Port_2_SCtrl =		$A10019
HW_Expansion_TxData =		$A1001B
HW_Expansion_RxData =		$A1001D
HW_Expansion_SCtrl =		$A1001F

; ---------------------------------------------------------------------------
; VDP addresses
VDP_data_port =			$C00000
VDP_control_port =		$C00004
PSG_input =			$C00011
; ---------------------------------------------------------------------------
; some equates for Sprite_table_input
PriorLayerObjs	= $40

; priority level definitions
	rsset 0
priority0	rs.b PriorLayerObjs*2; $000 ; priority level 0
priority1	rs.b PriorLayerObjs*2; $080 ; priority level 1
priority2	rs.b PriorLayerObjs*2; $100 ; priority level 2
priority3	rs.b PriorLayerObjs*2; $180 ; priority level 3
priority4	rs.b PriorLayerObjs*2; $200 ; priority level 4
priority5	rs.b PriorLayerObjs*2; $280 ; priority level 5
priority6	rs.b PriorLayerObjs*2; $300 ; priority level 6
priority7	rs.b PriorLayerObjs*2; $380 ; priority level 7
SpriteTableSize	rs.b 0; size of the sprite_table_input array

; ---------------------------------------------------------------------------
; main object variables.
	rsset 0		; set __rs to 0
		rs.l 1; $00 ; long ; object ID. Is actually direct address of the object in ROM.
render		rs.b 1; $04 ; byte ; flags used to render the object, but BuildSprites. See Status.
routine		rs.b 1; $05 ; byte ; routine ID of the object, usually multiple of 2. Not necessary for many objects in S3K anymore. see ID.
height		rs.b 1; $06 ; byte ; height of the object in pixels.
width		rs.b 1; $07 ; byte ; width of the object in pixels.
priority	rs.w 1; $08 ; word ; priority of the object. Multiple of $80 ($80 = 1, $380 = 7)
tile		rs.w 1; $0A ; word ; tile setup to display. Usually known as Art_Tile.
mappings	rs.l 1; $0C ; long ; ROM offset of the mappings.
xpos		rs.l 1; $10 ; long ; the horizontal pixel and subpixel coordinate of the object. Some objects only use first word
ypos		rs.l 1; $14 ; long ; the vertical pixel and subpixel coordinate of the object. Some objects only use first word
xvel		rs.w 1; $18 ; word ; the horizontal speed of an object in moving objects.
yvel		rs.w 1; $1A ; word ; the vertical speed of an object in moving objects.
oboff1C		rs.b 1; $1C
oboff1D		rs.b 1; $1D
yrad		rs.b 1; $1E ; byte ; the vertical radius of an object
xrad		rs.b 1; $1F ; byte ; the horizontal radius of an object
anim		rs.b 1; $20 ; byte ; animation ID of an object
anilast		rs.b 1; $21 ; byte ; animation ID for last frame. If not same as anim, animation starts from the start.
mapframe	rs.b 1; $22 ; byte ; mappings frame to use. Animation routines will write the frame to use next.
anioff		rs.b 1; $23 ; byte ; animation offset. Next animation data will be read from this offset
anitime		rs.b 1; $24 ; byte ; time until next animation frame should be shown.
oboff25		rs.b 1; $25
angle		rs.w 1; $26 ; word ; angle of the object in scale of 0-255
collision	rs.b 1; $28 ; byte ; type of the objects collision. 2 high bits determine type, rest of the bits determine size. 0 = no collision
collhits	rs.b 1; $29 ; byte ; secondary counter. Bosses use this as the hit counters. Some objects may have other uses
status		rs.b 1; $2A ; byte ; few bits describing things about the object. Few of these bits are transferred to render as well, namely flip bits.
shireact	rs.b 1; $2B ; byte ; shield rection. depending on settings, this object will get negated by specific shields
subtype		rs.b 1; $2C ; byte ; this usually gets assigned only by object loader, which will have own slot for object subtype, copied here.
	rsset __rs+$10-2; advance __rs to get the next things,
rssbit		rs.b 1; $3B ; byte ; the bit to clear if object is set to be destroyable
rssaddr		rs.b 1; $3C ; word ; address of the RSS entry for this object
	rsset __rs+3; advance __rs to get the next things,
vramoff		rs.w 1; $40 ; word ; VRAM address to DMA art to. Mostly used by objects with Dynamic PLC's
parent		rs.w 0; $42 ; word ; address of a possible parent object.
childx		rs.b 1; $42 ; byte ; x-offset relative to parent
chidly		rs.b 1; $43 ; byte ; y-offset relative to parent
	rsset __rs+2; advance __rs to get the next things,
parent2		rs.w 1; $46 ; word ; address of a possible parent object.
parent3		rs.w 0; $48 ; word ; address of a possible parent object.
respawn		rs.w 1; $48 ; word ; address of this objects entry in respawn table

; ---------------------------------------------------------------------------
; these equates are specific to Player Objects
inertia =	oboff1C; $1C ; word ; the ground velocity of an object. It has no specific direction, and usually depends on the object's angle.
jumpmove2 =	oboff25; $25 ; byte ; something to do with double jump moves, depending on player
angle2 =	angle+1; $27 ; byte ; something to do with angle.

	rsset $2B; skip to this equate because nothing before of it is meaningful
shistatus	rs.b 1; $2B ; byte ; stores information about shields, invinciblity and speed shoes
airleft		rs.b 1; $2C ; byte ; amount of air the player has left.
unk2D		rs.b 1; $2D ; byte ;
unk2E		rs.b 1; $2E ; byte ;
jumpmove	rs.b 1; $2F ; byte ; information about double jump moves. Depends on the player
unk30		rs.b 1; $30 ; byte ;
unk31		rs.b 1; $31 ; byte ;
movelock	rs.w 1; $32 ; word ; the amount of frames player cannot move left or right.
invultime	rs.b 1; $33 ; byte ; amount of time player is invulnerable for
invistime	rs.b 1; $34 ; byte ; amount of time player is invincible for
speedtime	rs.b 1; $35 ; byte ; amount of time player has speed shoes for
unk37		rs.b 1; $37 ; byte ;
charnum		rs.b 1; $38 ; byte ; player ID. 0 = Sonic, 1 = Tails, 2 = Knuckles
scrolldelay	rs.b 1; $39 ; byte ; tbe scroll delay timer, incremented for as long as player looks up or down.
tiltfront	rs.b 1; $3A ; byte ; check later
tiltback	rs.b 1; $3B ; byte ; check later
unk3C		rs.b 1; $3C ; byte ;
spindash	rs.b 1; $3D ; byte ; bit 1 indicates spindash active, bit 7 is forced roll active
spdashtime	rs.w 1; $3E ; word ;
jumping		rs.b 1; $40 ; byte ; set if jumping
		rs.b 1; $41 ; byte ; unused
interact	rs.w 1; $42 ; word ; the RAM address of the object stood on
yraddef		rs.b 1; $44 ; byte ; the default y-radius of the object
xraddef		rs.b 1; $45 ; byte ; the default x-radius of the object
topsolid	rs.b 1; $46 ; byte ; the bit used to check top solidity with
lrbsolid	rs.b 1; $47 ; byte ; the bit used to check lrb solidity with

; ---------------------------------------------------------------------------
; offsets objects may use
oboff12	= 	xpos+2	; $12
oboff16	= 	ypos+2	; $16
oboff27	=	angle+1	; $27

	rsset $20	; set __rs for these equates
oboff20		rs.b 1; $20
oboff21		rs.b 1; $21
oboff22		rs.b 1; $22
oboff23		rs.b 1; $23
oboff24		rs.b 1; $24
		rs.b 1; $25 ; already defined
oboff26		rs.b 1; $26
		rs.b 1; $27 ; already defined
oboff28		rs.b 1; $28
oboff29		rs.b 1; $29
oboff2A		rs.b 1; $2A
oboff2B		rs.b 1; $2B
oboff2C		rs.b 1; $2C
oboff2D		rs.b 1; $2D
oboff2E		rs.b 1; $2E
oboff2F		rs.b 1; $2F
oboff30		rs.b 1; $30
oboff31		rs.b 1; $31
oboff32		rs.b 1; $32
oboff33		rs.b 1; $33
oboff34		rs.b 1; $34
oboff35		rs.b 1; $35
oboff36		rs.b 1; $36
oboff37		rs.b 1; $37
oboff38		rs.b 1; $38
oboff39		rs.b 1; $39
oboff3A		rs.b 1; $3A
oboff3B		rs.b 1; $3B
oboff3C		rs.b 1; $3C
oboff3D		rs.b 1; $3D
oboff3E		rs.b 1; $3E
oboff3F		rs.b 1; $3F
oboff40		rs.b 1; $40
oboff41		rs.b 1; $41
oboff42		rs.b 1; $42
oboff43		rs.b 1; $43
oboff44		rs.b 1; $44
oboff45		rs.b 1; $45
oboff46		rs.b 1; $46
oboff47		rs.b 1; $47
oboff48		rs.b 1; $48
oboff49		rs.b 1; $49
objsize		rs.b 1; $4A ; this is the defined object size. Next object starts right after.

; ---------------------------------------------------------------------------
; offsets used by child sprites
childnum	= oboff16	; $16 ; word ; number of child sprites
childdata	= childnum+2	; $18 ; data of child sprites. See below

	rsset 0
child_x		rs.w 1; word ; x-offset of the child sprite
child_y		rs.w 1; word ; y-offset of the child sprite
		rs.b 1; unused
child_frm	rs.b 1; byte ; mappings frame of the child sprite
child_sz	rs.b 0; size of a single child sprite

; ---------------------------------------------------------------------------
; Main RAM variables
	rsset $FFFF0000
Chunk_table:				rs.b $8000	; $FFFF0000
Level_layout_header:			rs.b 8		; $FFFF8000
Level_layout_main:			rs.b $ff8	; $FFFF8008
Block_table:				rs.b $1a00	; $FFFF9000
Nemdec_buffer:				rs.b $200	; $FFFFAA00
Sprite_table_input:			rs.b SpriteTableSize; $FFFFAC00
Object_RAM:				rs.b objsize	; $FFFFB000
Obj_player_2:				rs.b objsize	; $FFFFB04A
Object_RAM_misc:			rs.b objsize	; $FFFFB094
Object_RAM_free:			rs.b objsize*90	; $FFFFB0DE
Object_RAM_static:			rs.b objsize*3	; $FFFFCAE2
Obj_super_stars:			rs.b objsize	; $FFFFCBC0
Obj_tails_tails:			rs.b objsize	; $FFFFCC0A
Obj_dust:				rs.b objsize	; $FFFFCC54
Obj_dust_2:				rs.b objsize	; $FFFFCC9E
Obj_shield:				rs.b objsize	; $FFFFCCE8
Obj_shield_2:				rs.b objsize*5	; $FFFFCD32
Obj_invis_stars:			rs.b objsize*4	; $FFFFCEA4
Object_RAM_End:				rs.b 0		; $FFFFCFCC
					rs.b $34	; $FFFFCFCC	; unknown
Kos_decomp_buffer:			rs.b $1000	; $FFFFD000
Horiz_Scroll_Buffer:			rs.b $380	; $FFFFE000
Coll_response_list:			rs.b $80	; $FFFFE380
Position_table_P2:			rs.b $100	; $FFFFE400
Position_table:				rs.b $100	; $FFFFE500
Competition_Save_Data:			rs.b $AC	; $FFFFE600
Current_Save_Slot:			rs.b $54	; $FFFFE6AC
Ring_Status_Table:			rs.b $400	; $FFFFE700
Object_respawn_table:			rs.b $300	; $FFFFEB00
Camera_X_Pos_Diff:			rs.w 1		; $FFFFEE00
Camera_Y_Pos_Diff:			rs.w 1		; $FFFFEE02
Camera_X_Pos_Diff_P2:			rs.w 1		; $FFFFEE04
Camera_Y_Pos_Diff_P2:			rs.w 1		; $FFFFEE06
Screen_Shaking_Flag_HTZ:		rs.b 1		; $FFFFEE08
Screen_Shaking_Flag:			rs.b 1		; $FFFFEE09
Scroll_Lock:				rs.b 1		; $FFFFEE0A
Scroll_Lock_P2:				rs.b 1		; $FFFFEE0B
Camera_target_min_X:			rs.w 1		; $FFFFEE0C
Camera_target_max_X:			rs.w 1		; $FFFFEE0E
Camera_target_min_Y:			rs.w 1		; $FFFFEE10
Camera_target_max_Y:			rs.w 1		; $FFFFEE12
Camera_min_X:				rs.w 1		; $FFFFEE14
Camera_max_X:				rs.w 1		; $FFFFEE16
Camera_min_Y:				rs.w 1		; $FFFFEE18
Camera_max_Y:				rs.w 1		; $FFFFEE1A
Camera_min_X_P2:			rs.w 1		; $FFFFEE1C
Camera_max_X_P2:			rs.w 1		; $FFFFEE1E
Camera_min_Y_P2:			rs.w 1		; $FFFFEE20
Camera_max_Y_P2:			rs.w 1		; $FFFFEE22
Horiz_Scroll_Delay_Val:			rs.w 1		; $FFFFEE24
Sonic_Pos_Record_Index:			rs.w 1		; $FFFFEE26
Horiz_Scroll_Delay_Val_P2:		rs.w 1		; $FFFFEE28
Tails_Pos_Record_Index:			rs.w 1		; $FFFFEE2A
Distance_from_screen_top:		rs.w 1		; $FFFFEE2C
Distance_from_screen_top_P2:		rs.w 1		; $FFFFEE2E
Deform_Lock:				rs.b 1		; $FFFFEE30
Max_X_Pos_Change_Flag:			rs.b 1		; $FFFFEE31
Max_Y_Pos_Change_Flag:			rs.b 1		; $FFFFEE32
Dynamic_Resize_Routine:			rs.b 6		; $FFFFEE33
Fast_V_scroll_flag:			rs.b 1		; $FFFFEE39
V_scroll_value_P2_copy:			rs.l 1		; $FFFFEE3A
Camera_X_Pos_Relative_To_BG:		rs.w 1		; $FFFFEE3E
Camera_Y_Pos_Relative_To_BG:		rs.w 1		; $FFFFEE40
Ring_start_addr_ROM:			rs.l 1		; $FFFFEE42
Ring_end_addr_ROM:			rs.l 1		; $FFFFEE46
Ring_start_addr_RAM:			rs.l 1		; $FFFFEE4A
Current_Zone_Secondary:			rs.b 1		; $FFFFEE4E
Current_Act_Secondary:			rs.b 1		; $FFFFEE4F
PalCycle_Delay:				rs.w 1		; $FFFFEE50
Transition_Routine:			rs.w 1		; $FFFFEE52
Transition_Revert_Flag:			rs.b $a		; $FFFFEE54
Lvl_No_TitleCard:			rs.w 1		; $FFFFEE5E
Camera_X_P2:				rs.l 1		; $FFFFEE60
Camera_Y_P2:				rs.l 1		; $FFFFEE64
Camera_X_P2_Copy:			rs.l 1		; $FFFFEE68
Camera_Y_P2_Copy:			rs.l 1		; $FFFFEE6C
Camera_BG_X_P2:				rs.l 1		; $FFFFEE70
Camera_BG_Y_P2:				rs.l 1		; $FFFFEE74
Camera_X:				rs.l 1		; $FFFFEE78
Camera_Y:				rs.l 1		; $FFFFEE7C
Camera_X_Copy:				rs.l 1		; $FFFFEE80
Camera_Y_Copy:				rs.l 1		; $FFFFEE84
Camera_X_Rounded:			rs.w 1		; $FFFFEE88
Camera_Y_Rounded:			rs.w 1		; $FFFFEE8A
Camera_BG_X:				rs.l 1		; $FFFFEE8C
Camera_BG_Y:				rs.l 1		; $FFFFEE90
Camera_BG_X_Rounded:			rs.w 1		; $FFFFEE94
Camera_BG_Y_Rounded:			rs.w 1		; $FFFFEE96
Camera_BG2_X:				rs.w 1		; $FFFFEE98
Camera_BG2_X2:				rs.w 1		; $FFFFEE9A
Camera_BG2_Y:				rs.l 1		; $FFFFEE9C
Camera_BG2_X_Rounded:			rs.w 1		; $FFFFEEA0
Camera_BG2_Y_Rounded:			rs.w 1		; $FFFFEEA2
Plane_double_update:			rs.w 1		; $FFFFEEA4
Special_VInt_FX_Routine:		rs.w 1		; $FFFFEEA6
Screen_X_wrap_value:			rs.w 1		; $FFFFEEA8
Screen_Y_wrap_value:			rs.w 1		; $FFFFEEAA
Camera_Y_pos_mask:			rs.w 1		; $FFFFEEAC
Layout_row_index_mask:			rs.w 1		; $FFFFEEAE
Plane_Buffer_Pos_OnScr:			rs.w 1		; $FFFFEEB0
Lvl_AutoScroll_Routine:			rs.w 1		; $FFFFEEB2
Camera_X_Before_Transition:		rs.w 1		; $FFFFEEB4
Camera_X_Before_Transition2:		rs.b 6		; $FFFFEEB6
AutoScroll_X_SubValue:			rs.l 1		; $FFFFEEBC
Dynamics_Routine:			rs.w 1		; $FFFFEEC0
Triggers_Routine:			rs.w 1		; $FFFFEEC2
Update_Lvl_FG_Flag:			rs.w 1		; $FFFFEEC4
Level_Property:				rs.w 1		; $FFFFEEC6
LevelUpdate_Pos:			rs.w 1		; $FFFFEEC8
LevelUpdate_Counter:			rs.w 1		; $FFFFEECA
ScreenShake_Flag:			rs.w 1		; $FFFFEECC
ScreenShake_Value:			rs.w 1		; $FFFFEECE
ScreenShake_Value_prev:			rs.b $6a	; $FFFFEED0
Sprite_Draw_Flag:			rs.w 1		; $FFFFEF3A
Use_normal_sprite_table:		rs.w 1		; $FFFFEF3C
Sprite_Table_Flag_2P:			rs.b 6		; $FFFFEF3E
VInt_Interrupt_Addr:			rs.b 5		; $FFFFEF44
Multiplayer_Player2Flag:		rs.b 7		; $FFFFEF49
Demo_Button_Press:			rs.w 1		; $FFFFEF50
Current_Demo_Data:			rs.l 1		; $FFFFEF52
SRAM_WriteFlag:				rs.l 1		; $FFFFEF56
Object_index_addr:			rs.b $a		; $FFFFEF5A
ObjMgr_Camera_X_Left:			rs.w 1		; $FFFFEF64
ScreenShakeBG_Value:			rs.b 6		; $FFFFEF66
Unk_HPZ_EmeraldFlag:			rs.b 6		; $FFFFEF6C
Pause_Ignore:				rs.w 1		; $FFFFEF72
Secondary_Plane_Buffer:			rs.l 1		; $FFFFEF74
Demo_Press_Counter:			rs.b 1		; $FFFFEF78
Player2_Demo_Button_Press:		rs.b 7		; $FFFFEF79
Ring_consumption_count:			rs.w 1		; $FFFFEF80
Ring_consumption_list:			rs.b $7e	; $FFFFEF82
Water_Pal_FadeTo:			rs.b $20	; $FFFFF000
Water_Pal_FadeTo_Line2:			rs.b $20	; $FFFFF020
Water_Pal_FadeTo_Line3:			rs.b $20	; $FFFFF040
Water_Pal_FadeTo_Line4:			rs.b $20	; $FFFFF060
Water_Pal:				rs.b $20	; $FFFFF080
Water_Pal_Line2:			rs.b $20	; $FFFFF0A0
Water_Pal_Line3:			rs.b $20	; $FFFFF0C0
Water_Pal_Line4:			rs.b $20	; $FFFFF0E0
Plane_buffer:				rs.b $480	; $FFFFF100
VRAM_Buffer:				rs.b $80	; $FFFFF580
GameMode:				rs.w 1		; $FFFFF600
Ctrl_1_Held_Logical:			rs.b 1		; $FFFFF602
Ctrl_1_Press_Logical:			rs.b 1		; $FFFFF603
Ctrl_1_Held:				rs.b 1		; $FFFFF604
Ctrl_1_Press:				rs.b 1		; $FFFFF605
Ctrl_2_Held:				rs.b 1		; $FFFFF606
Ctrl_2_Press:				rs.b 7		; $FFFFF607
VDP_Reg1_Val:				rs.b 6		; $FFFFF60E
Demo_Time:				rs.w 1		; $FFFFF614
VScroll_Factor_FG:			rs.w 1		; $FFFFF616
VScroll_Factor_BG:			rs.w 1		; $FFFFF618
HScroll_Factor_FG:			rs.w 1		; $FFFFF61A
HScroll_Factor_BG:			rs.w 1		; $FFFFF61C
Camera_Y_Pos_P2_Relative:		rs.w 1		; $FFFFF61E
Camera_BG_Y_Pos_Relative:		rs.b 3		; $FFFFF620
Stop_Referenced_Objs:			rs.b 1		; $FFFFF623
Hint_Counter_Reserve:			rs.w 1		; $FFFFF624
Palette_Fade_Range:			rs.b 1		; $FFFFF626
Palette_Fade_Length:			rs.b 1		; $FFFFF627
Level_Lag_Frames:			rs.w 1		; $FFFFF628
VInt_Routine:				rs.w 1		; $FFFFF62A
Sprite_Count:				rs.w 1		; $FFFFF62C
HInt_Water_Data:			rs.l 1		; $FFFFF62E
PalCycle_Frame:				rs.w 1		; $FFFFF632
PalCycle_Timer:				rs.w 1		; $FFFFF634
RNG_Seed:				rs.l 1		; $FFFFF636
Paused_Flag:				rs.b 6		; $FFFFF63A
DMA_Data_Thunk:				rs.l 1		; $FFFFF640
HInt_Flag:				rs.w 1		; $FFFFF644
Water_Height_Default:			rs.w 1		; $FFFFF646
Current_Water_Height:			rs.w 1		; $FFFFF648
Target_Water_Height:			rs.w 1		; $FFFFF64A
Water_Speed:				rs.b 1		; $FFFFF64C
Water_Routine:				rs.b 1		; $FFFFF64D
Water_Fullscrn_Flag:			rs.w 1		; $FFFFF64E
PalCycle_Flag:				rs.w 1		; $FFFFF650
PalCycle_Frame2:			rs.w 1		; $FFFFF652
PalCycle_Frame3:			rs.w 1		; $FFFFF654
PalCycle_Frame4:			rs.w 1		; $FFFFF656
PalCycle_Timer2:			rs.w 1		; $FFFFF658
PalCycle_Timer3:			rs.w 1		; $FFFFF65A
Super_PalCycle_Frame:			rs.w 1		; $FFFFF65C
Super_PalCycle_Timer:			rs.b 1		; $FFFFF65E
Super_PalCycle_Flag:			rs.b 1		; $FFFFF65F
BG_Layer_Scroll_Timer:			rs.w 1		; $FFFFF660
BG_Layer_Scroll_Timer2:			rs.l 1		; $FFFFF662
Flash_Timer:				rs.b 1		; $FFFFF666
Super_Tails_Flag:			rs.b 1		; $FFFFF667
SuperTails_PalCycle_Frame:		rs.b 1		; $FFFFF668
SuperTails_PalCycle_Timer:		rs.b 1		; $FFFFF669
Ctrl_2_Held_Logical:			rs.b 1		; $FFFFF66A
Ctrl_2_Press_Logical:			rs.b 1		; $FFFFF66B
Super_RingDrain_Counter:		rs.l 1		; $FFFFF66C
Super_SecondCounter:			rs.b 6		; $FFFFF670
Scroll_Force_Pos:			rs.w 1		; $FFFFF676
Scroll_Force_X_Pos:			rs.l 1		; $FFFFF678
Scroll_Force_Y_Pos:			rs.l 1		; $FFFFF67C
PLC_Buffer:				rs.l 1		; $FFFFF680
PLC_Buffer_Slot1_VRAM:			rs.b $5c	; $FFFFF684
Art_Decomp_Routine:			rs.l 1		; $FFFFF6E0
Art_Decomp_Variable1:			rs.l 1		; $FFFFF6E4
Art_Decomp_Variable2:			rs.l 1		; $FFFFF6E8
Art_Decomp_Variable3:			rs.l 1		; $FFFFF6EC
Art_Decomp_Variable4:			rs.l 1		; $FFFFF6F0
Art_Decomp_Variable5:			rs.l 1		; $FFFFF6F4
Total_Tiles_Left:			rs.w 1		; $FFFFF6F8
Current_Tiles_Left:			rs.b 6		; $FFFFF6FA
Player2_CPU_Flag:			rs.w 1		; $FFFFF700
Player2_CPU_Control_Counter:		rs.w 1		; $FFFFF702
Player2_CPU_Respawn:			rs.l 1		; $FFFFF704
Player2_CPU_Routine:			rs.w 1		; $FFFFF708
Player2_CPU_Target_XPos:		rs.w 1		; $FFFFF70A
Player2_CPU_Target_YPos:		rs.w 1		; $FFFFF70C
Player2_CPU_Last_Obj_interact:		rs.b 1		; $FFFFF70E
Player2_CPU_UnkFlag:			rs.b 1		; $FFFFF70F
Rings_Manager_Routine:			rs.b 1		; $FFFFF710
Level_Start_Flag:			rs.b 1		; $FFFFF711
Current_Respawn_Index:			rs.b $1e	; $FFFFF712
Water_Flag:				rs.b $e		; $FFFFF730
Player2_CPU_UnkArray:			rs.b 6		; $FFFFF73E
Tails_PreviousFlying_X_Speed:		rs.w 1		; $FFFFF744
Player2_CPU_StarpoleFlag:		rs.w 1		; $FFFFF746
Cheat_Button_Press1:			rs.b 1		; $FFFFF748
Cheat_Button_Press2:			rs.b 1		; $FFFFF749
Player1_RestartFlag_2P:			rs.b 1		; $FFFFF74A
Player2_RestartFlag_2P:			rs.b 1		; $FFFFF74B
Tails_PreviousFlying_Y_Speed:		rs.w 1		; $FFFFF74C
Knuckles_GlideStateFlag:		rs.b 1		; $FFFFF74E
Knuckles_GlideStateFlag2:		rs.b $11	; $FFFFF74F
Player1_TopSpeed:			rs.w 1		; $FFFFF760
Player1_Acceleration:			rs.w 1		; $FFFFF762
Player1_Deceleration:			rs.w 1		; $FFFFF764
Player1_Current_Frame:			rs.w 1		; $FFFFF766
Player_NextTilt:			rs.w 1		; $FFFFF768
Player_CurrentTilt:			rs.w 1		; $FFFFF76A
Objects_Manager_Routine:		rs.w 1		; $FFFFF76C
ObjMgr_Camera_X_Last:			rs.w 1		; $FFFFF76E
ObjMgr_Camera_X_Right:			rs.w 1		; $FFFFF770
Next_ObjLoad_Address:			rs.l 1		; $FFFFF772
Previous_ObjLoad_Address:		rs.l 1		; $FFFFF776
Next_Respawn_Address:			rs.w 1		; $FFFFF77A
Previous_Respawn_Address:		rs.b $18	; $FFFFF77C
Demo_Fade_Counter:			rs.w 1		; $FFFFF794
Current_Collision:			rs.b $14	; $FFFFF796
Boss_Active_Flag:			rs.b 6		; $FFFFF7AA
Player1_Rotation_Angle:			rs.b 1		; $FFFFF7B0
Player2_Rotation_Angle:			rs.b 3		; $FFFFF7B1
Primary_Collision:			rs.l 1		; $FFFFF7B4
Secondary_Collision:			rs.b $e		; $FFFFF7B8
ReverseGravity_Flag:			rs.w 1		; $FFFFF7C6
Player1_OnWater_Flag:			rs.b 1		; $FFFFF7C8
Player2_OnWater_Flag:			rs.b 1		; $FFFFF7C9
Control_Locked:				rs.b 1		; $FFFFF7CA
Control_Locked_P2:			rs.b 5		; $FFFFF7CB
MidAir_Bonus_Counter:			rs.w 1		; $FFFFF7D0
Time_Bonus_Counter:			rs.w 1		; $FFFFF7D2
Ring_Bonus_Counter:			rs.b 6		; $FFFFF7D4
CameraScroll_Counter:			rs.w 1		; $FFFFF7DA
Player2_CameraScroll_Counter:		rs.w 1		; $FFFFF7DC
Player2_Current_Frame:			rs.b 1		; $FFFFF7DE
TailsTails_Current_Frame:		rs.b 1		; $FFFFF7DF
Button_Press_Array:			rs.b $10	; $FFFFF7E0
Level_Anim:				rs.b $10	; $FFFFF7F0
Sprite_Attribute_Table:			rs.b $280	; $FFFFF800
BossSpecific_Ram:			rs.b 8		; $FFFFFA80
Ending_VInt_Trigger:			rs.b $a		; $FFFFFA88
Previous_Max_X_Pos:			rs.w 1		; $FFFFFA92
Previous_Min_X_Pos:			rs.w 1		; $FFFFFA94
Previous_Min_Y_Pos:			rs.w 1		; $FFFFFA96
Previous_Max_Y_Pos:			rs.b $a		; $FFFFFA98
Boss_Secondary_Status:			rs.l 1		; $FFFFFAA2
Signpost_Bonus_Pointer:			rs.b 6		; $FFFFFAA6
Unk_FAAC:				rs.l 1		; $FFFFFAAC
Boss_Top_Y_Bound:			rs.w 1		; $FFFFFAB0
Boss_Bottom_Y_Bound:			rs.w 1		; $FFFFFAB2
Boss_Left_X_Bound:			rs.w 1		; $FFFFFAB4
Boss_Right_X_Bound:			rs.w 1		; $FFFFFAB6
Boss_Anim_Status:			rs.b 7		; $FFFFFAB8
CyclePalette_Flag:			rs.b $f		; $FFFFFABF
Pal_FadeIn_Delay:			rs.b $10	; $FFFFFACE
CyclePalette_Array:			rs.b $22	; $FFFFFADE
VDP_Command_Buffer:			rs.b $fc	; $FFFFFB00
VDP_Command_Buffer_Slot:		rs.l 1		; $FFFFFBFC
Main_Palette:				rs.b $20	; $FFFFFC00
Main_Palette_Line2:			rs.b $20	; $FFFFFC20
Main_Palette_Line3:			rs.b $20	; $FFFFFC40
Main_Palette_Line4:			rs.b $20	; $FFFFFC60
Main_Palette_FadeTo:			rs.b $20	; $FFFFFC80
Main_Palette_FadeTo_Line2:		rs.b $20	; $FFFFFCA0
Main_Palette_FadeTo_Line3:		rs.b $20	; $FFFFFCC0
Main_Palette_FadeTo_Line4:		rs.b $20	; $FFFFFCE0
System_Stack_Start:			rs.b $100	; $FFFFFD00
System_Stack:				rs.w 1		; $FFFFFE00
Level_Restart_Flag:			rs.w 1		; $FFFFFE02
Level_Frame_Timer:			rs.w 1		; $FFFFFE04
Current_Debug_Obj:			rs.w 1		; $FFFFFE06
Debug_Routine:				rs.b 1		; $FFFFFE08
Debug_Placement_Flag:			rs.b 3		; $FFFFFE09
VInt_RunCount:				rs.l 1		; $FFFFFE0C
Current_Zone:				rs.b 1		; $FFFFFE10
Current_Act:				rs.b 1		; $FFFFFE11
Life_Count:				rs.l 1		; $FFFFFE12
Current_SpecialStage:			rs.w 1		; $FFFFFE16
Continue_Count:				rs.b 1		; $FFFFFE18
Super_Flag:				rs.b 1		; $FFFFFE19
Time_Over_Flag:				rs.b 1		; $FFFFFE1A
Get_Extra_Life_Flag:			rs.b 1		; $FFFFFE1B
Update_HUD_Lives:			rs.b 1		; $FFFFFE1C
Update_HUD_Rings:			rs.b 1		; $FFFFFE1D
Update_HUD_Timer:			rs.b 1		; $FFFFFE1E
Update_HUD_Score:			rs.b 1		; $FFFFFE1F
Ring_Count:				rs.w 1		; $FFFFFE20
Timer:					rs.b 1		; $FFFFFE22
Timer_Minute:				rs.b 1		; $FFFFFE23
Timer_Second:				rs.b 1		; $FFFFFE24
Timer_Frame:				rs.b 1		; $FFFFFE25
Score:					rs.l 1		; $FFFFFE26
Last_Starpole_Hit:			rs.b 1		; $FFFFFE2A
Saved_Last_Starpole_Hit:		rs.b 1		; $FFFFFE2B
Saved_Zone:				rs.w 1		; $FFFFFE2C
Saved_Starpole_X_Pos:			rs.w 1		; $FFFFFE2E
Saved_Starpole_Y_Pos:			rs.w 1		; $FFFFFE30
Saved_Ring_Count:			rs.w 1		; $FFFFFE32
Saved_Timer:				rs.l 1		; $FFFFFE34
Saved_Player_VRAM:			rs.w 1		; $FFFFFE38
Saved_Player_Layer:			rs.w 1		; $FFFFFE3A
Saved_Camera_X_Pos:			rs.w 1		; $FFFFFE3C
Saved_Camera_Y_Pos:			rs.w 1		; $FFFFFE3E
Saved_Current_Water_Height:		rs.w 1		; $FFFFFE40
Saved_Water_Fullscreen_Flag:		rs.b 1		; $FFFFFE42
Saved_Get_Extra_Life_Flag:		rs.b 1		; $FFFFFE43
Saved_Current_Max_Y_Pos:		rs.w 1		; $FFFFFE44
Saved_Dynamic_Resize_Routine:		rs.b 1		; $FFFFFE46
Saved_Powerup:				rs.b 1		; $FFFFFE47
BigRing_Flag:				rs.b 1		; $FFFFFE48
Saved_Last_Starpole_Hit_BigRing:	rs.b 1		; $FFFFFE49
Saved_Zone_BigRing:			rs.w 1		; $FFFFFE4A
Saved_X_Pos_BigRing:			rs.w 1		; $FFFFFE4C
Saved_Y_Pos_BigRing:			rs.w 1		; $FFFFFE4E
Saved_Ring_Count_BigRing:		rs.w 1		; $FFFFFE50
Saved_Timer_BigRing:			rs.l 1		; $FFFFFE52
Saved_Player_VRAM_BigRing:		rs.w 1		; $FFFFFE56
Saved_Player_Layer_BigRing:		rs.w 1		; $FFFFFE58
Saved_Camera_X_Pos_BigRing:		rs.w 1		; $FFFFFE5A
Saved_Camera_Y_Pos_BigRing:		rs.w 1		; $FFFFFE5C
Saved_Current_Water_Height_BigRing:	rs.w 1		; $FFFFFE5E
Saved_Water_Fullscreen_Flag_BigRing:	rs.b 1		; $FFFFFE60
Saved_Get_Extra_Life_Flag_BigRing:	rs.b 1		; $FFFFFE61
Saved_Current_Max_Y_Pos_BigRing:	rs.w 1		; $FFFFFE62
Saved_Dynamic_Resize_Routine_BigRing:	rs.b $a		; $FFFFFE64
Osc_Num:				rs.b $44	; $FFFFFE6E
Ring_Anim_Counter:			rs.b 1		; $FFFFFEB2
Ring_Anim_Frame:			rs.b 3		; $FFFFFEB3
SpillRing_Anim_Counter:			rs.b 1		; $FFFFFEB6
SpillRing_Anim_Frame:			rs.b 1		; $FFFFFEB7
SpillRing_Anim_Accum:			rs.w 1		; $FFFFFEB8
AIZ_VineSwing_Angle:			rs.l 1		; $FFFFFEBA
Player2_Update_HUD_Rings:		rs.b 1		; $FFFFFEBE
Player2_Get_Extra_Life_Flag:		rs.b 1		; $FFFFFEBF
Player2_TopSpeed:			rs.w 1		; $FFFFFEC0
Player2_Acceleration:			rs.w 1		; $FFFFFEC2
Player2_Deceleration:			rs.w 1		; $FFFFFEC4
Player2_Life_Count:			rs.b 1		; $FFFFFEC6
Player2_Update_HUD_Timer:		rs.b 1		; $FFFFFEC7
Total_Rings_Collected:			rs.w 1		; $FFFFFEC8
Player2_Total_Rings_Collected:		rs.w 1		; $FFFFFECA
Monitors_Broken:			rs.w 1		; $FFFFFECC
Player2_Monitors_Broken:		rs.w 1		; $FFFFFECE
Player2_Ring_Count:			rs.w 1		; $FFFFFED0
Player2_Timer:				rs.l 1		; $FFFFFED2
Player2_Score:				rs.b $2c	; $FFFFFED6
Unk_S2_2PResultsScreen:			rs.w 1		; $FFFFFF02
Rings_To_Collect:			rs.w 1		; $FFFFFF04
Unk_Rings_Ram:				rs.w 1		; $FFFFFF06
Player_Mode:				rs.w 1		; $FFFFFF08
Player_Mode_OnMenu:			rs.l 1		; $FFFFFF0A
Kos_Data_Pieces:			rs.w 1		; $FFFFFF0E
Kos_Queue_Backup:			rs.b $28	; $FFFFFF10
Kos_Queue_Status_Backup:		rs.w 1		; $FFFFFF38
Kos_Queue_PC_Backup:			rs.l 1		; $FFFFFF3A
Kos_Queue_Stack:			rs.w 1		; $FFFFFF3E
Kos_Decomp_Queue:			rs.l 1		; $FFFFFF40
Kos_Destination_RAM:			rs.l 1		; $FFFFFF44
Kos_Decomp_Queue_Slot2:			rs.b $18	; $FFFFFF48
Kos_Module_Count:			rs.w 1		; $FFFFFF60
Kos_Last_Module_Size:			rs.w 1		; $FFFFFF62
Kos_Module_Decomp_Queue:		rs.l 1		; $FFFFFF64
Kos_Module_Destination_VRAM:		rs.w 1		; $FFFFFF68
Kos_Module_Decomp_Queue_Slot2:		rs.b $16	; $FFFFFF6A
LvlSel_Delay:				rs.w 1		; $FFFFFF80
LevelSelect_Selection:			rs.w 1		; $FFFFFF82
SoundTest_Selection:			rs.w 1		; $FFFFFF84
TitleMenu_Selection:			rs.b 5		; $FFFFFF86
Pause_Reset_Flag:			rs.b 3		; $FFFFFF8B
Total_Bonus_Countdown:			rs.w 1		; $FFFFFF8E
Current_Song:				rs.w 1		; $FFFFFF90
BigRingCollected_Bitfield:		rs.l 1		; $FFFFFF92
Saved_Powerup_BigRing:			rs.b 1		; $FFFFFF96
Transport_Flag:				rs.b 3		; $FFFFFF97
Saved_Current_Zone_Secondary:		rs.w 1		; $FFFFFF9A
Saved_Current_Zone_Secondary_BigRing:	rs.b $12	; $FFFFFF9C
S3Active_Flag:				rs.w 1		; $FFFFFFAE
Chaos_Emerald_Count:			rs.b 1		; $FFFFFFB0
Super_Emerald_Count:			rs.b 1		; $FFFFFFB1
EmeraldArray_1st:			rs.b 1		; $FFFFFFB2
EmeraldArray_2nd:			rs.b 1		; $FFFFFFB3
EmeraldArray_3rd:			rs.b 1		; $FFFFFFB4
EmeraldArray_4th:			rs.b 1		; $FFFFFFB5
EmeraldArray_5th:			rs.b 1		; $FFFFFFB6
EmeraldArray_6th:			rs.b 1		; $FFFFFFB7
EmeraldArray_7th:			rs.w 1		; $FFFFFFB8
Player_SkipSuper_Flag:			rs.b 1		; $FFFFFFBA
SpecialStage_SKFlag:			rs.b 5		; $FFFFFFBB
Next_Extra_Life_Score:			rs.l 1		; $FFFFFFC0
Player2_Next_Extra_Life_Score:		rs.b 6		; $FFFFFFC4
Debug_Saved_Mapping:			rs.l 1		; $FFFFFFCA
Debug_Saved_VRAM:			rs.w 1		; $FFFFFFCE
Demo_Mode_Flag:				rs.w 1		; $FFFFFFD0
Demo_Number:				rs.w 1		; $FFFFFFD2
BlueSphere_Flag:			rs.w 1		; $FFFFFFD4
HInt_Water_Counter:			rs.w 1		; $FFFFFFD6
Graphics_Flags:				rs.w 1		; $FFFFFFD8
Debug_Mode_Flag:			rs.b 6		; $FFFFFFDA
Level_Select_Flag:			rs.b 1		; $FFFFFFE0
Slow_Motion_Flag:			rs.b 1		; $FFFFFFE1
Debug_Enable_Flag:			rs.w 1		; $FFFFFFE2
Unused_Cheat:				rs.w 1		; $FFFFFFE4
Unused_Cheat2:				rs.w 1		; $FFFFFFE6
Multiplayer_Flag:			rs.w 1		; $FFFFFFE8
Multiplayer_Player1_Character:		rs.b 1		; $FFFFFFEA
Multiplayer_Player2_Character:		rs.b 5		; $FFFFFFEB
VInt_Jmp_Code:				rs.w 1		; $FFFFFFF0
VInt_Addr:				rs.l 1		; $FFFFFFF2
HInt_Jmp_Code:				rs.w 1		; $FFFFFFF6
HInt_Addr:				rs.l 1		; $FFFFFFF8
Checksum_String:			rs.l 1		; $FFFFFFFC

; ---------------------------------------------------------------------------
Sprite_attribute_table_2 	equ   $FF7880
Sprite_attribute_table_P2	equ   $FF7B00
Sprite_attribute_table_P2_2 	equ   $FF7D80

; ---------------------------------------------------------------------------
