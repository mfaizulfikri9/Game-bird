;##############################################################################
;#     
;#     Copyright (C) 2007 George Papadopoulos - VirusFree ( VirusFree@phoenixbit.com )
;#     
;#     This program is free software; you can redistribute it and/or
;#     modify it under the terms of the GNU General Public License
;#     as published by the Free Software Foundation; either version 2
;#     of the License, or (at your option) any later version.
;#     
;#     This program is distributed in the hope that it will be useful,
;#     but WITHOUT ANY WARRANTY; without even the implied warranty of
;#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;#     GNU General Public License for more details.
;#     
;#     You should have received a copy of the GNU General Public License
;#     along with this program; if not, write to the Free Software
;#     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
;#     
;##############################################################################


; #########################################################################

;     include files
;     ~~~~~~~~~~~~~
      include d:\MASM32\INCLUDE\windows.inc
      include d:\MASM32\INCLUDE\MASM32.inc
      include d:\MASM32\INCLUDE\gdi32.inc
      include d:\MASM32\INCLUDE\user32.inc
      include d:\MASM32\INCLUDE\kernel32.inc
      include d:\MASM32\INCLUDE\Comctl32.inc
      include d:\MASM32\INCLUDE\comdlg32.inc
      include d:\MASM32\INCLUDE\shell32.inc
      include d:\masm32\include\oleaut32.inc
      include d:\masm32\include\ole32.inc
      include d:\masm32\include\winmm.inc


;     libraries
;     ~~~~~~~~~
      includelib d:\MASM32\LIB\MASM32.lib
      includelib d:\MASM32\LIB\gdi32.lib
      includelib d:\MASM32\LIB\user32.lib
      includelib d:\MASM32\LIB\kernel32.lib
      includelib d:\MASM32\LIB\Comctl32.lib
      includelib d:\MASM32\LIB\comdlg32.lib
      includelib d:\MASM32\LIB\shell32.lib
      includelib d:\masm32\lib\oleaut32.lib
      includelib d:\masm32\lib\ole32.lib
      includelib d:\masm32\lib\winmm.lib


; #########################################################################

        ;=================
        ; Local prototypes
        ;=================
        WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
        WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
        TopXY PROTO   :DWORD,:DWORD
        GameTimer    PROTO
	Paint_Proc   PROTO 
	PaintBMP     PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
	PaintBMPMask PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
	LoadGraphics PROTO 
	ReadLevelFile PROTO 
	SetVariables  PROTO
	PaintLevel    PROTO
	PaintGDI PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
	DoAnimations PROTO
	CheckKeys PROTO
	MovePlayer PROTO
	GetIndexByCoord PROTO :DWORD,:DWORD,:DWORD,:DWORD
	GetPointerByIndex PROTO :DWORD,:DWORD,:DWORD
	CheckDotEat PROTO
	MakeLongToString PROTO :DWORD,:DWORD
	MoveGhosts PROTO
	FakeRandom PROTO :DWORD
	prand PROTO :DWORD
	pseed PROTO  :DWORD,:DWORD,:DWORD,:DWORD
	BoxCollisionDetection PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
	CheckCollisions PROTO
	CheckCustomButtons PROTO  :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
	OtherStuff PROTO
	ChooseNPlayMidi PROTO
	PlayMidiFile PROTO :DWORD


      ;=============
      ; Local macros
      ;=============

      szText MACRO Name, Text:VARARG
        LOCAL lbl
          jmp lbl
            Name db Text,0
          lbl:
        ENDM

      m2m MACRO M1, M2
        push M2
        pop  M1
      ENDM

      return MACRO arg
        mov eax, arg
        ret
      ENDM

      stralloc MACRO ln
        invoke SysAllocStringByteLen,0,ln
      ENDM

      strfree MACRO strhandle
        invoke SysFreeString,strhandle
      ENDM



    .data
        szDisplayName 	db "FBIRD by jhe rani wati",0
        CommandLine   	dd 0
        hWnd          	dd 0
        hInstance     	dd 0
        hIcon         	dd 0
	hDC		dd 0
	hDC2		dd 0
	hWin          	dd 0

	

	
	szNameFile	db "Level.txt",0

        hBmpBackround 	dd 0
        hBmpBlack 	dd 0
        hBmpWall 	dd 0
        hBmpSuperWall 	dd 0

	GameTimerValue  dd 17
	
	BoxDim		dd 24
	LevelStartX	dd 0
	LevelStartY	dd 0
	LevelSize	dd 418    ; ### 22x19 (map blocks)
	hLevel		dd 0
	LevelMaxX	dd 19
	LevelMaxY	dd 22

	TotalDots	dd 0
	
	DotDim		dd 4
	DotColorAnim	dd 00000000h
	DotColorAnimDir	dd 0
	DotColorAnimSpeed	dd 080800h
	DotColorResult	dd 008888FFh


	BigDotDim		dd 12
	BigDotColorAnim		dd 00FFFFFFh
	BigDotColorAnimDir	dd 0
	BigDotColorAnimSpeed	dd 000808h
	BigDotColorResult	dd 00FF8888h


	PlayerSpeed	dd 8
	PlayerX		dd 0
	PlayerY		dd 0
	PlayerXOriginal	dd 0
	PlayerYOriginal	dd 0
	PlayerAnim	dd 0
	PlayerAnimKiller	dd 3
	PlayerAnimCnt	dd 0
	PlayerIsSuper	dd 0
	PlayerSuperStart	dd 0
	PlayerSuperLast		dd 7000
	PlayerLostTime	dd 0
	PlayerLostLast	dd 2500

	PlayerLives	dd 0
	PlayerLivesX	dd 76
	PlayerLivesY	dd 642
	PlayerLivesDist	dd 10


	hBmpPacArray	dd 0
	hBmpPacMaskArray	dd 0


	GameStatus	dd 0;0->New Game 
					;1->Playing
					;2->Pause
					;3->Lost
					;4->Win

	NewGameButtonX	dd 345
	NewGameButtonY	dd 635
	NewGameButtonW	dd 140
	NewGameButtonH	dd 34

	NewGameButtonStatus dd 0
	hBmpNewGameButtonMask	dd 0
	hBmpNewGameButtonNormal	dd 0
	hBmpNewGameButtonOver	dd 0


	PausePanelX	dd 111
	PausePanelY	dd 220
	PausePanelW	dd 300
	PausePanelH	dd 200

	hPausePanelMask	dd 0
	hPausePanelBMP	dd 0



	LostPanelX	dd 111
	LostPanelY	dd 250
	LostPanelW	dd 300
	LostPanelH	dd 160

	hLostPanelMask	dd 0
	hLostPanelBMP	dd 0



	GameOverPanelX	dd 111
	GameOverPanelY	dd 220
	GameOverPanelW	dd 300
	GameOverPanelH	dd 200

	hGameOverPanelMask	dd 0
	hGameOverPanelBMP	dd 0



	WonPanelX	dd 111
	WonPanelY	dd 250
	WonPanelW	dd 300
	WonPanelH	dd 160

	hWonPanelMask	dd 0
	hWonPanelBMP	dd 0

	
	WonMsgStart	dd 0
	WonMsgTime	dd 3000

	NewKeyDir	dd 0
	PDir		dd 0

	Score		dd 0
	ScoreX		dd 110
	ScoreY		dd 64
	ScoreString	db "        ",0	;size 8


	GhostEatenInRow	dd 0
	GhostEatenInRowMul	dd 200

	GhostsCount	dd 10
	GhostX		dd 0	; -> ARRAY
	GhostY		dd 0	; -> ARRAY
	GhostSpeed	dd 1
	GhostDir	dd 0	; -> ARRAY
	GhostScared	dd 0
	GhostAnim	dd 0
	GhostAnimCnt	dd 0
	GhostAnimKiller	dd 7
	GhostsSpawnX	dd 0
	GhostsSpawnY	dd 0
	GhostsTimePreRecover dd 2000
	GhostsRecoverAnim dd 0
	GhostsRecoverCnt dd 0
	GhostsRecoverKill dd 15

        hBmpGhost 	dd 0
        hBmpGhostMask 	dd 0

	hBmpScared	dd 0	
	hBmpScaredRecovery	dd 0	


	DoorX		dd 0
	DoorY		dd 0

	hBmpDoor	dd 0
	hBmpDoorMask	dd 0


	hPs		dd 0

	BackCnt		dd 0

	tmpString	db "        ",0
	
	MidiCount	dd 16
	PlayMidiFileName	db "data\%%.x",0
        PlayFlag    	dd 0
        MidDeviceID	dd 0
        szMIDISeqr	db "Sequencer",0

	SndLost		db "suara\kalah.wav",0
	SndEatDot	db "suara\makan.wav",0

	seed1  dd 0AAAABBBBh
	seed2  dd 0CCCCDDDDh
	seed3  dd 0EEEEFFFFh
	seed4  dd 11112222h

	dTest		dd 0
	dbging		dd 0
	;.IF dTest == 1
	;	ShowReturn NULL,1
	;.ENDIF


; ########################### Inserted modules ############################


; #########################################################################
