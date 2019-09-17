; #########################################################################

      .386
      .model flat, stdcall  ; 32 bit memory model
      option casemap :none  ; case sensitive

      include pacman.inc    ; local includes for this file


; #########################################################################

.code

start:
      invoke GetModuleHandle, NULL
      mov hInstance, eax

	;###### Initalize Random Routine
	invoke GetTickCount
	invoke pseed,eax,2342347,63452,eax

	;###### Set Variables
	invoke SetVariables 

	;###### Extract images from exe's resource file
	invoke LoadGraphics 

	;##### Read Level
	invoke ReadLevelFile 

	;#### Play Midi
	invoke ChooseNPlayMidi

      invoke GetCommandLine
      mov CommandLine, eax

      invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
      invoke ExitProcess,eax

; #########################################################################

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

      ;====================
      ; Put LOCALs on stack
      ;====================

      LOCAL wc   :WNDCLASSEX
      LOCAL msg  :MSG
      LOCAL Wwd  :DWORD
      LOCAL Wht  :DWORD
      LOCAL Wtx  :DWORD
      LOCAL Wty  :DWORD

	LOCAL Ps     :PAINTSTRUCT

      ;==================================================
      ; Fill WNDCLASSEX structure with required variables
      ;==================================================

      invoke LoadIcon,hInst,500    ; icon ID
      mov hIcon, eax

      szText szClassName,"Project_Class"

      mov wc.cbSize,         sizeof WNDCLASSEX
      mov wc.style,          CS_BYTEALIGNWINDOW
      mov wc.lpfnWndProc,    offset WndProc
      mov wc.cbClsExtra,     NULL
      mov wc.cbWndExtra,     NULL
      m2m wc.hInstance,      hInst
      mov wc.hbrBackground,  COLOR_BTNFACE+1
      mov wc.lpszMenuName,   NULL
      mov wc.lpszClassName,  offset szClassName
      m2m wc.hIcon,          hIcon
        invoke LoadCursor,NULL,IDC_ARROW
      mov wc.hCursor,        eax
      m2m wc.hIconSm,        hIcon

      invoke RegisterClassEx, ADDR wc

      ;================================
      ; Centre window at following size
      ;================================

      mov Wwd, 522
      mov Wht, 710

      invoke GetSystemMetrics,SM_CXSCREEN
      invoke TopXY,Wwd,eax
      mov Wtx, eax

      invoke GetSystemMetrics,SM_CYSCREEN
      invoke TopXY,Wht,eax
      mov Wty, eax

      invoke CreateWindowEx,WS_EX_LEFT,
                            ADDR szClassName,
                            ADDR szDisplayName,
                            WS_OVERLAPPEDWINDOW,
                            Wtx,Wty,Wwd,Wht,
                            NULL,NULL,
                            hInst,NULL
      mov   hWnd,eax

      invoke LoadMenu,hInst,600  ; menu ID
      invoke SetMenu,hWnd,eax

      invoke ShowWindow,hWnd,SW_SHOWNORMAL
      invoke UpdateWindow,hWnd

      ;===================================
      ; Set the Timer Event
      ;===================================
	
	invoke SetTimer,hWnd,NULL,GameTimerValue,NULL

	m2m hWin,hWnd


      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0
      cmp eax, 0
      je ExitLoop
      	invoke TranslateMessage, ADDR msg
      	invoke DispatchMessage,  ADDR msg
      jmp StartLoop
    ExitLoop:

        

      return msg.wParam

WinMain endp

; #########################################################################

WndProc proc hWinL  :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

	

    LOCAL var    :DWORD
    LOCAL caW    :DWORD
    LOCAL caH    :DWORD
    LOCAL Rct    :RECT
    LOCAL buffer1[128]:BYTE  ; these are two spare buffers
    LOCAL buffer2[128]:BYTE  ; for text manipulation etc..

    LOCAL Ps     :PAINTSTRUCT
    LOCAL tmpRect :RECT

    LOCAL tmpX	:DWORD
    LOCAL tmpY	:DWORD

    LOCAL tPoint	:POINT

    .if uMsg == WM_COMMAND
    ;======== menu commands ========
    .elseif uMsg == WM_CREATE

    .elseif uMsg == WM_SIZE

    .elseif uMsg == WM_PAINT
        	invoke BeginPaint,hWin,ADDR Ps
          		mov hDC, eax
		      invoke Paint_Proc
		invoke EndPaint,hWin,ADDR Ps
    	      return 0

    .elseif uMsg == WM_TIMER
		cmp dbging,1
		je [outn]
		invoke GameTimer 
		invoke RedrawWindow,hWin,NULL,NULL,RDW_INVALIDATE	
	outn:

    .elseif uMsg == WM_MOUSEMOVE
		;####Mouse move
       	mov eax, lParam
        	xor edx, edx
        	mov dx, ax
        	shr eax, 16
        	mov tmpX,edx
        	mov tmpY,eax

		invoke CheckCustomButtons,tmpX,tmpY,NewGameButtonX,NewGameButtonY,NewGameButtonW,NewGameButtonH
		cmp eax,0
		je [notOver]
			mov NewGameButtonStatus,1
			jmp [ifEndEnd]
		notOver:
			mov NewGameButtonStatus,0
		ifEndEnd:
		
    .elseif uMsg == WM_LBUTTONDOWN
		;####Mouse move
       	mov eax, lParam
        	xor edx, edx
        	mov dx, ax
        	shr eax, 16
        	mov tmpX,edx
        	mov tmpY,eax

		invoke CheckCustomButtons,tmpX,tmpY,NewGameButtonX,NewGameButtonY,NewGameButtonW,NewGameButtonH
		cmp eax,1
		jne [ifEndEnd1]
			mov GameStatus,1
		ifEndEnd1:

		
    .elseif uMsg == WM_KEYDOWN
		mov dTest,1
		.IF wParam == VK_I		;## UP
			mov NewKeyDir,1
		.ELSEIF wParam == VK_K  	;## Down
			mov NewKeyDir,3
		.ELSEIF wParam == VK_L   	;## Right
			mov NewKeyDir,0
		.ELSEIF wParam == VK_J   	;## Left
			mov NewKeyDir,2		
		.ELSEIF wParam == VK_P   	;## P -> Pause
			cmp GameStatus,1
			jne [notPause]
				mov GameStatus,2	
				jmp notDePause
			notPause:
			cmp GameStatus,2
			jne [notDePause]
				mov GameStatus,1
			notDePause:
		.ELSEIF wParam == VK_ESCAPE
			mov dbging,0
		.ENDIF		

    .elseif uMsg == MM_MCINOTIFY
    		; sent when media play completes and closes midi device
		invoke mciSendCommand,MidDeviceID,MCI_CLOSE,0,0
		mov PlayFlag,0


    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWinL,uMsg,wParam,lParam

    ret

WndProc endp

; ########################################################################

TopXY proc wDim:DWORD, sDim:DWORD

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY endp

; #########################################################################

GameTimer proc

	LOCAL cnt:DWORD

	;### keep the midi playing
	cmp PlayFlag,0
	jne [playing]
		invoke ChooseNPlayMidi
	playing:

	invoke DoAnimations 

	cmp GameStatus,0
	je [ExitFunction]

		cmp GameStatus,2
		je [ExitFunction]
			
			cmp GameStatus,3
			jne [notLost]
				invoke GetTickCount
				sub eax,PlayerLostLast
				cmp PlayerLostTime,eax
				jg [notYet]
					.IF PlayerLives<1
						mov PlayerLives,0
						mov GameStatus,0
						;### Restart Game
							;###### Set Variables
								invoke SetVariables 
							;##### Read Level
								invoke ReadLevelFile 
					.ELSE
						;### Reset Pacman Pos
							m2m PlayerX,PlayerXOriginal
							m2m PlayerY,PlayerYOriginal
						;### Reset Ghosts Pos
							push edi
							push edx

							mov cnt,-1	
							Forcnt:
								inc cnt

								mov eax,cnt
								mov edi,4
								mul edi
								push eax

								add eax,GhostX
								mov edi,eax
								mov eax,GhostsSpawnX
								mov [edi],eax
	
								pop eax

								add eax,GhostY
								mov edi,eax
								mov eax,GhostsSpawnY
								mov [edi],eax

							mov eax,cnt
							inc eax
							cmp eax,GhostsCount
							jl [Forcnt]
							pop edx
							pop edi
						mov GameStatus,1
					.ENDIF
				notYet:
				jmp ExitFunction
			notLost:
			

			cmp GameStatus,4
			jne [notWon]
				invoke GetTickCount
				sub eax,WonMsgTime
				cmp WonMsgStart,eax
				jg [notYet2]
					mov PlayerLives,0
					mov GameStatus,0
					;### Restart Game
						;###### Set Variables
							invoke SetVariables 
						;##### Read Level
							invoke ReadLevelFile 
				notYet2:
				jmp ExitFunction
			notWon:


			invoke CheckKeys
			invoke MovePlayer 

			invoke CheckDotEat 

			invoke MoveGhosts 

			invoke CheckCollisions

			invoke OtherStuff

	ExitFunction:


	return 0
GameTimer endp

; #########################################################################

Paint_Proc proc

	LOCAL tmpi1:DWORD
	LOCAL tmpi2:DWORD
	LOCAL tmpi3:DWORD

	LOCAL memDC:DWORD
	LOCAL hBmp:DWORD

	LOCAL cnt:DWORD

	invoke CreateCompatibleDC,hDC
	mov memDC,eax

	invoke CreateCompatibleBitmap,hDC,522,710
	mov hBmp,eax

	invoke SelectObject,memDC,hBmp

	m2m hDC2,memDC



	;### Paint BackRound
		invoke PaintBMP,hBmpBackround,0,0,522,710


	; ####  Paint Level
		invoke PaintLevel



	;### Draw High Score
		invoke MakeLongToString,Score,ADDR ScoreString
		invoke SetBkMode, hDC2, TRANSPARENT
		invoke SetTextColor, hDC2, BigDotColorAnim
		invoke TextOut, hDC2, ScoreX, ScoreY, addr ScoreString, 8
	


	;### Draw Door
		mov eax,BoxDim
		mov edi,DoorX
		mul edi
		add eax,LevelStartX
		mov tmpi1,eax
		mov eax,BoxDim
		mov edi,DoorY
		mul edi
		add eax,LevelStartY
		mov tmpi2,eax
		invoke PaintBMPMask,hBmpDoor,hBmpDoorMask,tmpi1,tmpi2,BoxDim,BoxDim		;### Paint Door


		

	;### Paint Ghosts

		push edi

		mov cnt,-1
		Forcnt:
			inc  cnt

			invoke GetPointerByIndex,GhostDir,cnt,1
			shl eax,3
			add eax,hBmpGhost
			add eax,GhostAnim
			mov eax,[eax]
			
			push eax

			invoke GetPointerByIndex,GhostX,cnt,1
			add eax,LevelStartX
			mov tmpi1,eax

			invoke GetPointerByIndex,GhostY,cnt,1
			add eax,LevelStartY
			mov tmpi2,eax

			;### Paint Ghosts Mask
			mov eax,hBmpGhostMask
			add eax,GhostAnim
			mov eax,[eax]
			mov tmpi3,eax

			pop eax
			cmp PlayerIsSuper,1
			je [DrawScaredGhost]
				invoke PaintBMPMask,eax,tmpi3,tmpi1,tmpi2,BoxDim,BoxDim		;### Paint Ghosts 
				jmp outG
			DrawScaredGhost:
				invoke GetTickCount
				sub eax,PlayerSuperLast
				add eax,GhostsTimePreRecover
				cmp PlayerSuperStart,eax
				jg [BlueGhost]
					inc GhostsRecoverCnt
					mov eax,GhostsRecoverCnt
					cmp GhostsRecoverKill,eax
					jg [notSwapYet]
						mov GhostsRecoverCnt,0
						cmp GhostsRecoverAnim,0
						je [makeone]
							mov GhostsRecoverAnim,0
							jmp [notSwapYet]
						makeone:
							mov GhostsRecoverAnim,1
					notSwapYet:
					mov eax,GhostAnim
					cmp GhostsRecoverAnim,0
					je [SetWhite]
						add eax,hBmpScared
						jmp [gEndif]
					SetWhite:
						add eax,hBmpScaredRecovery
					gEndif:
					mov eax,[eax]
					invoke PaintBMPMask,eax,tmpi3,tmpi1,tmpi2,BoxDim,BoxDim		;### Paint Ghosts
					jmp outG
				BlueGhost:
					mov eax,GhostAnim
					add eax,hBmpScared
					mov eax,[eax]
					invoke PaintBMPMask,eax,tmpi3,tmpi1,tmpi2,BoxDim,BoxDim		;### Paint Ghosts
			outG:

		mov eax,cnt
		inc eax
		cmp eax,GhostsCount
		jl [Forcnt]

		pop edi






	;### Paint PacMan
		mov eax,PDir		;|---------------------------------
		shl eax,3			;| Get Proper Handle For Direction
		mov tmpi3,eax		;|
		add eax,hBmpPacArray	;|---------------------------------
		add eax,PlayerAnim		;## Add Animation
		mov eax,[eax]		;### Get Pointer Value

		push eax
		
		m2m tmpi1,PlayerX
		mov eax,LevelStartX
		add tmpi1,eax

		m2m tmpi2,PlayerY
		mov eax,LevelStartY
		add tmpi2,eax

		mov eax,tmpi3
		add eax,hBmpPacMaskArray
		mov tmpi3,eax

		pop eax

		invoke PaintBMPMask,eax,tmpi3,tmpi1,tmpi2,BoxDim,BoxDim		;### Paint PacMan




	;### Paint Player Lives
	mov tmpi1,0
	cmp PlayerLives,0
	jle [NoLives]

	Fortmpi1:
		inc tmpi1
		
		mov eax,tmpi1
		dec eax
		mov edi,PlayerLivesDist
		add edi,BoxDim
		mul edi
		add eax,PlayerLivesX
		
		push eax

		mov eax,hBmpPacArray
		add eax,4
		mov eax,[eax]
		mov tmpi2,eax

		mov eax,hBmpPacMaskArray
		add eax,4
		mov eax,[eax]
		mov tmpi3,eax
		
		pop eax

		invoke PaintBMPMask,tmpi2,tmpi3,eax,PlayerLivesY,BoxDim,BoxDim		;### Paint PacMan Live
		
				
	mov eax,tmpi1
	cmp eax,PlayerLives
	jne [Fortmpi1]
	NoLives:



	cmp GameStatus,0
	jne [OutStatus0]
		cmp NewGameButtonStatus,0
		jne [itISOver]
			invoke PaintBMPMask,hBmpNewGameButtonNormal,hBmpNewGameButtonMask,NewGameButtonX,NewGameButtonY,NewGameButtonW,NewGameButtonH		;### Paint Button
			jmp EndIFThis
		itISOver:
			invoke PaintBMPMask,hBmpNewGameButtonOver,hBmpNewGameButtonMask,NewGameButtonX,NewGameButtonY,NewGameButtonW,NewGameButtonH		;### Paint Button
		EndIFThis:
	OutStatus0:



	cmp GameStatus,2
	jne [OutStatus2]
		invoke PaintBMPMask,hPausePanelBMP,hPausePanelMask,PausePanelX,PausePanelY,PausePanelW,PausePanelH		;### Paint Pause Panel
	OutStatus2:


	cmp GameStatus,3
	jne [OutStatus3]
		cmp PlayerLives,0
		jle [GameOver]
			invoke PaintBMPMask,hLostPanelBMP,hLostPanelMask,LostPanelX,LostPanelY,LostPanelW,LostPanelH		;### Paint Lost Panel
			jmp [OutStatus3]
		GameOver:
			invoke PaintBMPMask,hGameOverPanelBMP,hGameOverPanelMask,GameOverPanelX,GameOverPanelY,GameOverPanelW,GameOverPanelH		;### Paint GameOver Panel
	OutStatus3:


	cmp GameStatus,4
	jne [OutStatus4]
		invoke PaintBMPMask,hWonPanelBMP,hWonPanelMask,WonPanelX,WonPanelY,WonPanelW,WonPanelH		;### Paint Won Panel
	OutStatus4:


	invoke BitBlt,hDC,0,0,522,710,memDC,0,0,SRCCOPY

	invoke DeleteDC, memDC
	invoke DeleteObject,hBmp

    	return 0

Paint_Proc endp

; ########################################################################

PaintBMP proc BmpHandle:DWORD , PosX:DWORD , PosY:DWORD , BmpW:DWORD , BmpH:DWORD

    	LOCAL memDC:DWORD

    	invoke CreateCompatibleDC,hDC
   	mov memDC, eax
    
    	invoke SelectObject,memDC,BmpHandle

    	invoke BitBlt,hDC2,PosX,PosY,BmpW,BmpH,memDC,0,0,SRCCOPY

    	invoke DeleteDC,memDC

    return 0

PaintBMP endp


; ########################################################################

PaintBMPMask proc BmpHandle:DWORD ,BmpHandleMask:DWORD , PosX:DWORD , PosY:DWORD , BmpW:DWORD , BmpH:DWORD

      LOCAL memDC:DWORD

    	invoke CreateCompatibleDC,hDC
   	mov memDC, eax
    
    	invoke SelectObject,memDC,BmpHandleMask

    	invoke BitBlt,hDC2,PosX,PosY,BmpW,BmpH,memDC,0,0,SRCAND

    	invoke SelectObject,memDC,BmpHandle

    	invoke BitBlt,hDC2,PosX,PosY,BmpW,BmpH,memDC,0,0,SRCPAINT

    	invoke DeleteDC,memDC
	
    return 0

PaintBMPMask endp

; ########################################################################

PaintGDI proc PosX:DWORD , PosY:DWORD , PosX2:DWORD , PosY2:DWORD , CColor:DWORD

 	LOCAL hPen      :DWORD
    	LOCAL hPenOld   :DWORD
    	LOCAL hBrush    :DWORD
    	LOCAL hBrushOld :DWORD

    	LOCAL lb        :LOGBRUSH


    	invoke CreatePen,0,1,CColor
    	mov hPen, eax

    	mov lb.lbStyle, BS_SOLID
    	m2m lb.lbColor, CColor
    	mov lb.lbHatch, NULL

    	invoke CreateBrushIndirect,ADDR lb
    	mov hBrush, eax

    	invoke SelectObject,hDC2,hPen
    	mov hPenOld, eax

    	invoke SelectObject,hDC2,hBrush
    	mov hBrushOld, eax

	invoke Ellipse,hDC2,PosX,PosY,PosX2,PosY2	;Paint circle

    	invoke SelectObject,hDC2,hBrushOld
    	invoke DeleteObject,hBrush

    	invoke SelectObject,hDC2,hPenOld
    	invoke DeleteObject,hPen


	return 0
PaintGDI Endp

; ########################################################################

ReadLevelFile proc

    	LOCAL hFile   	:DWORD
	LOCAL ln      	:DWORD
	LOCAL br	  	:DWORD
    	LOCAL source$ 	:DWORD
	LOCAL cnt		:DWORD
	LOCAL tmpX		:DWORD
	LOCAL tmpY		:DWORD


	;##### READ FILE	

	invoke CreateFile,ADDR szNameFile,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
    	mov hFile, eax

    	invoke GetFileSize,hFile,NULL
    	mov ln, eax

    	stralloc ln
    	mov source$, eax

    	invoke ReadFile,hFile,source$,ln,ADDR br,NULL

    	invoke CloseHandle,hFile
	

	;### proccess file

	;#create array
	stralloc LevelSize
	mov hLevel,eax  ;### write our array buffer address to a variable


	push ecx 
	push ebx
	push edx

	;LOOP
	mov ebx,hLevel
	mov ecx,source$
	mov edx,-1

	mov tmpX,0
	mov tmpY,0

	dec ecx

	Forcnt:
			
		inc ecx
		inc edx

		mov eax,0
		mov al,[ecx]
		cmp al,10
		je [ignr]
		cmp al,13
		je [ignr]
		cmp al,80
		jne [notPPos]
			m2m PlayerX,tmpX
			m2m PlayerY,tmpY

			push eax
			push edi
			push edx

			mov eax,BoxDim			
			mov edi,PlayerX
			mul edi
			mov PlayerX,eax

			mov eax,BoxDim			
			mov edi,PlayerY
			mul edi
			mov PlayerY,eax

			m2m PlayerXOriginal,PlayerX
			m2m PlayerYOriginal,PlayerY

			pop edx
			pop edi
			pop eax

		notPPos:

		cmp al,70
		jne [notGhostPos]
			push edx
			push eax
			push edi

				mov eax,-1
				ForEAX:
					
					inc eax
					push eax

					mov edi,4
					mul edi
					push eax
					add eax,GhostX
					
					;eax now holds the pointer to the array item

					mov edi,eax
						push edi

						mov eax,BoxDim			
						mov edi,tmpX
						mul edi

						pop edi
					mov [edi],eax
					
					mov GhostsSpawnX,eax
					
					pop eax
					push eax

					add eax,GhostY
					mov edi,eax
						push edi

						mov eax,BoxDim			
						mov edi,tmpY
						mul edi

						pop edi
					mov [edi],eax					
					
					mov GhostsSpawnY,eax

					pop eax

					add eax,GhostDir
					mov edi,eax
					mov eax,1
					mov [edi],eax

					pop eax
				cmp eax,GhostsCount
				jne [ForEAX]

			pop edi
			pop eax
			pop edx
		notGhostPos:

			cmp eax,79
			je [byp]
			cmp eax,46		; char .
			jne [notaDot]
				byp:
				inc TotalDots		
			notaDot:
	
			cmp eax,38		; char &
			jne [notaplus]
				m2m DoorX,tmpX
				m2m DoorY,tmpY
			notaplus:

			;### Level Coords
				inc tmpX
				push eax
				mov eax,tmpX
				cmp eax,LevelMaxX
				pop eax
				jne [notNewRow]
					inc tmpY
					mov tmpX,0 
				notNewRow:
			mov [ebx],al
			inc ebx
		ignr:	

	cmp edx,ln
	jl [Forcnt]


	pop edx
	pop ebx
	pop ecx

	return 0

ReadLevelFile endp


; ########################################################################

LoadGraphics proc

      ;######## invoke LoadBitmap,hInstance,101

	push ebx



	;#### button
	invoke BitmapFromResource, hInstance, 10
      mov hBmpNewGameButtonNormal, eax

	;#### button
	invoke BitmapFromResource, hInstance, 11
      mov hBmpNewGameButtonOver, eax

	;### Button Mask
	invoke BitmapFromResource, hInstance, 3
      mov hBmpNewGameButtonMask, eax



	;#### Pause Panel
	invoke BitmapFromResource, hInstance, 12
      mov hPausePanelBMP, eax

	;#### Pause PanelMask
	invoke BitmapFromResource, hInstance, 2
      mov hPausePanelMask, eax


	;#### Lost Panel
	invoke BitmapFromResource, hInstance, 1004
      mov hLostPanelBMP, eax

	;#### Lost Panel
	invoke BitmapFromResource, hInstance, 4
      mov hLostPanelMask, eax


	;#### GameOver Panel
	invoke BitmapFromResource, hInstance, 1005
      mov hGameOverPanelBMP, eax

	;#### GameOver Panel Mask
	invoke BitmapFromResource, hInstance, 5
      mov hGameOverPanelMask, eax


	;#### Won Panel
	invoke BitmapFromResource, hInstance, 1006
      mov hWonPanelBMP, eax

	;#### Won Panel Mask
	invoke BitmapFromResource, hInstance, 6
      mov hWonPanelMask, eax


	;#### Door
	invoke BitmapFromResource, hInstance, 1007
      mov hBmpDoor, eax

	;#### Door Mask
	invoke BitmapFromResource, hInstance, 7
      mov hBmpDoorMask, eax


	;#### Wall.jpg
	invoke BitmapFromResource, hInstance, 1000
      mov hBmpWall , eax

	;#### Backround.jpg
	invoke BitmapFromResource, hInstance, 1001
      mov hBmpBackround , eax

	;#### Black.jpg
	invoke BitmapFromResource, hInstance, 1002
      mov hBmpBlack , eax

	;#### superWall.jpg
	invoke BitmapFromResource, hInstance, 1003
      mov hBmpSuperWall, eax


	;### Load Pacman Graphics

		;### Create Memory
		stralloc 32		;### 4[dword size] * 8[pacimgs] = 32[bytes]
		mov hBmpPacArray,eax
		mov ebx,eax

		invoke BitmapFromResource, hInstance, 500
      		mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance, 501
      		mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance, 510
      		mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance, 511
      		mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance, 520
      		mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance, 521
      		mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance, 530
      		mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance, 531
      		mov [ebx] , eax


		;### Load Mask
		;### Create Memory
		stralloc 32		;### 4[dword size] * 8[pacimgs] = 32[bytes]
		mov hBmpPacMaskArray,eax
		mov ebx,eax

		invoke LoadBitmap,hInstance,500
		mov [ebx],eax
		add ebx,4

		invoke LoadBitmap,hInstance,501
		mov [ebx],eax
		add ebx,4

		invoke LoadBitmap,hInstance,510
		mov [ebx],eax
		add ebx,4

		invoke LoadBitmap,hInstance,511
		mov [ebx],eax
		add ebx,4

		invoke LoadBitmap,hInstance,520
		mov [ebx],eax
		add ebx,4

		invoke LoadBitmap,hInstance,521
		mov [ebx],eax
		add ebx,4

		invoke LoadBitmap,hInstance,530
		mov [ebx],eax
		add ebx,4

		invoke LoadBitmap,hInstance,531
		mov [ebx],eax



	;### Load Ghosts Graphics
		;### Create Memory
		stralloc 32		;### 4[dword size] * 8[ghostimgs] = 32[bytes]
		mov hBmpGhost,eax
		mov ebx,eax

		invoke BitmapFromResource, hInstance,  210
      		mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance,  220
      		mov [ebx] , eax
		add ebx,4


		invoke BitmapFromResource, hInstance,  211
      		mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance,  221
      		mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance,  212
      		mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance,  222
      		mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance,  213
      		mov [ebx] , eax
		add ebx,4


		invoke BitmapFromResource, hInstance,  223
     	 	mov [ebx] , eax

		;### Load Mask
		stralloc 8
		mov hBmpGhostMask,eax
		mov ebx,eax

		invoke LoadBitmap,hInstance,200
		mov [ebx],eax
		add ebx,4

		invoke LoadBitmap,hInstance,201
		mov [ebx],eax


		;### Load Scared Ghost Image
		stralloc 8
		mov hBmpScared,eax
		mov ebx,eax

		invoke BitmapFromResource, hInstance,  280
      	mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance,  281
      	mov [ebx] , eax


		;### Load Scared Recovery Ghost Image
		stralloc 8
		mov hBmpScaredRecovery,eax
		mov ebx,eax

		invoke BitmapFromResource, hInstance,  290
      	mov [ebx] , eax
		add ebx,4

		invoke BitmapFromResource, hInstance,  291
      	mov [ebx] , eax



	pop ebx		

	return 0;
LoadGraphics endp

; ########################################################################

SetVariables proc

	LOCAL tmpi:DWORD

	push edx
	push edi

	mov Score,0
	;### clear score string
	mov edi,OFFSET ScoreString
	mov eax,20202020h
	mov [edi],eax
	add edi,4
	mov [edi],eax

	m2m LevelStartX,BoxDim
	m2m LevelStartY,BoxDim
	
	shl LevelStartY,2

	mov TotalDots,0

	mov PlayerIsSuper,0

	;### Create Ghosts Array Memory
		mov eax, GhostsCount
		mov edi,4
		mul edi
		mov tmpi,eax

		stralloc tmpi	;### 4[dword size] * [ghostcount] = x[bytes]
		mov GhostX,eax

		stralloc tmpi	;### 4[dword size] * [ghostcount] = x[bytes]
		mov GhostY,eax

		stralloc tmpi	;### 4[dword size] * [ghostcount] = x[bytes]
		mov GhostDir,eax


	mov PlayerLives,6

	mov GameStatus,0

	pop edi
	pop edx

	return 0

SetVariables endp

; ########################################################################

PaintLevel proc
	
	LOCAL tmpi1	:DWORD
	LOCAL tmpi2 :DWORD
	LOCAL tmpi3	:DWORD
	LOCAL tmpi4 :DWORD
	LOCAL LevelSizeDEC :DWORD

	push ebx
	push ecx
	push edx
	push esi
	push edi

	m2m LevelSizeDEC ,LevelSize
	dec LevelSizeDEC

	mov ecx,-1  ;### Counter
	mov edx,hLevel

	mov ebx,-1	; X
	mov esi,0	; Y

	dec edx

	ForECX:	
		
		inc ebx
		cmp ebx,LevelMaxX
		jne [ignr]
			;#### Change Line
			mov ebx,0
			inc esi
		ignr:


		inc edx
		inc ecx
		
		push ecx
		push edx

		mov eax,0

		mov al,[edx]

			;### Calculate Block Information
			push eax
			push edx

			mov eax,BoxDim
			mov edi,ebx
			mul edi
			add eax,LevelStartX
			mov tmpi1,eax 		;#### got X Pos

			mov eax,BoxDim
			mov edi,esi
			mul edi
			add eax,LevelStartY
			mov tmpi2,eax		;#### got Y Pos
			
			pop edx
			pop eax
				
		cmp al,35
		jne [notWALL]
			;#### Paint Wall
			cmp PlayerIsSuper,0
			jne [isSuper]
				invoke PaintBMP,hBmpWall ,tmpi1,tmpi2,BoxDim,BoxDim
				jmp okout
			isSuper:
				invoke PaintBMP,hBmpSuperWall ,tmpi1,tmpi2,BoxDim,BoxDim
			okout:
			jmp [OutEmpty]
		notWALL:

			push eax	;### Preserve register , it hold's our byte
	
			;#### Paint Black
			invoke PaintBMP,hBmpBlack ,tmpi1,tmpi2,BoxDim,BoxDim

			pop eax

			cmp al,46
			jne [notDot]
				;#Paint Dot
				push tmpi1
				push tmpi2

				mov eax,BoxDim
				shr eax,1
				mov tmpi3,eax
				mov eax,DotDim
				shr eax,1
				sub tmpi3,eax
				mov eax,tmpi3

				add tmpi1,eax
				add tmpi2,eax
				
				mov eax,tmpi1
				add eax,DotDim
				mov tmpi3,eax

				mov eax,tmpi2
				add eax,DotDim
				mov tmpi4,eax
				
				invoke PaintGDI,tmpi1,tmpi2,tmpi3,tmpi4,DotColorAnim

				pop tmpi2
				pop tmpi1
			notDot:

			cmp al,79
			jne [notBigDot]
				;#Paint BigDot
				push tmpi1
				push tmpi2

				mov eax,BoxDim
				shr eax,1
				mov tmpi3,eax
				mov eax,BigDotDim
				shr eax,1
				sub tmpi3,eax
				mov eax,tmpi3

				add tmpi1,eax
				add tmpi2,eax
				
				mov eax,tmpi1
				add eax,BigDotDim
				mov tmpi3,eax

				mov eax,tmpi2
				add eax,BigDotDim
				mov tmpi4,eax
				
				invoke PaintGDI,tmpi1,tmpi2,tmpi3,tmpi4,BigDotColorAnim

				pop tmpi2
				pop tmpi1
			notBigDot:

		OutEmpty:

		

		pop edx		
		pop ecx	

	cmp ecx,LevelSizeDEC
	jne [ForECX]

	
	push ebp
	push edx
	push ecx
	push ebx
		
	return 0

PaintLevel endp

; ########################################################################

DoAnimations proc
		

		;#### Animate PacMan
		inc PlayerAnimCnt
		mov eax,PlayerAnimCnt
		cmp eax,PlayerAnimKiller
		jl killit
			mov PlayerAnimCnt,0
			cmp PlayerAnim,4
			je [makezero]
				mov PlayerAnim,4
			jmp oklbl
			makezero:
				mov PlayerAnim,0
			oklbl:
		killit:



		;#### Animate Ghosts
		inc GhostAnimCnt
		mov eax,GhostAnimCnt
		cmp eax,GhostAnimKiller
		jl killitGhost
			mov GhostAnimCnt,0
			cmp GhostAnim,4
			je [makezeroGhost]
				mov GhostAnim,4
			jmp oklblGhost
			makezeroGhost:
				mov GhostAnim,0
			oklblGhost:
		killitGhost:



		;### Animate Dots
		cmp DotColorAnimDir,1
		je [goingUP]
			mov eax,DotColorAnimSpeed
			sub DotColorAnim,eax
			mov eax,DotColorResult
			cmp DotColorAnim,eax
			jg [NotF2]
				m2m DotColorAnim,DotColorResult	
				mov DotColorAnimDir,1
			NotF2:
			jmp Out1
		goingUP:
			mov eax,DotColorAnimSpeed
			add DotColorAnim,eax
			cmp DotColorAnim,00FFFFFFh
			jl [NotF1]
				mov DotColorAnim,00FFFFFFh
				mov DotColorAnimDir,0
			NotF1:
		Out1:


		;### Animate Big Dots
		cmp BigDotColorAnimDir,1
		je [goingUPBig]
			mov eax,BigDotColorAnimSpeed
			sub BigDotColorAnim,eax
			mov eax,BigDotColorResult
			cmp BigDotColorAnim,eax
			jg [NotF2Big]
				m2m BigDotColorAnim,BigDotColorResult
				mov BigDotColorAnimDir,1
			NotF2Big:
			jmp Out1Big
		goingUPBig:
			mov eax,BigDotColorAnimSpeed
			add BigDotColorAnim,eax
			cmp BigDotColorAnim,00FFFFFFh
			jl [NotF1Big]
				mov BigDotColorAnim,00FFFFFFh
				mov BigDotColorAnimDir,0
			NotF1Big:
		Out1Big:



	return 0
DoAnimations Endp


; ########################################################################

CheckKeys proc
	
	LOCAL i1:DWORD
	LOCAL i2:DWORD
	LOCAL i3:DWORD
	LOCAL i4:DWORD	
	
	LOCAL XmodW:DWORD
	LOCAL YmodH:DWORD

	LOCAL BoxX:DWORD
	LOCAL BoxY:DWORD

	push edi
	
	;Get X mod and div
	mov eax,PlayerX
	mov edi,BoxDim
	mov edx,0
	div edi
	mov XmodW,edx
	mov BoxX,eax

	;Get Y mod and div
	mov eax,PlayerY
	mov edi,BoxDim
	mov edx,0
	div edi
	mov YmodH,edx
	mov BoxY,eax
	

	;if both zero...
	cmp XmodW,0
	jne [notOK]
	cmp YmodH,0
	jne [notOK]
				
	
		.IF NewKeyDir == 0
			mov eax,BoxX
			.IF eax < LevelMaxX
				inc eax
				invoke GetIndexByCoord,hLevel,eax,BoxY,1	;### after this eax holds the array item address
				;## Test if this is the char we want
				cmp eax,35	;char #
				je Bad0
				cmp eax,64	;char @
				je Bad0
				cmp eax,38	;char &
				je Bad0
					mov PDir,0	;### set new direction
				Bad0:
			.ENDIF

		.ELSEIF NewKeyDir == 2
			mov eax,BoxX
			.IF eax > 0
				dec eax
				invoke GetIndexByCoord,hLevel,eax,BoxY,1	;### after this eax holds the array item address
				;## Test if this is the char we want
				cmp eax,35	;char #
				je Bad2
				cmp eax,64	;char @
				je Bad2
				cmp eax,38	;char &
				je Bad2
					mov PDir,2	;### set new direction
				Bad2:
			.ENDIF

		.ELSEIF NewKeyDir == 1
			mov eax,BoxY
			.IF eax > 0
				dec eax
				invoke GetIndexByCoord,hLevel,BoxX,eax,1	;### after this eax holds the array item address
				;## Test if this is the char we want
				cmp eax,35	;char #
				je Bad1
				cmp eax,64	;char @
				je Bad1
				cmp eax,38	;char &
				je Bad1
				
					mov PDir,1	;### set new direction
				Bad1:
			.ENDIF

		.ELSEIF NewKeyDir == 3
			mov eax,BoxY
			.IF eax < LevelMaxY
				inc  eax
				invoke GetIndexByCoord,hLevel,BoxX,eax,1	;### after this eax holds the array item address
				;## Test if this is the char we want
				cmp eax,35	;char #
				je Bad3
				cmp eax,64	;char @
				je Bad3
				cmp eax,38	;char &
				je Bad3
					mov PDir,3	;### set new direction
				Bad3:
			.ENDIF

		.ENDIF
		
		jmp ExitFun
	notOK:	

	;## Here i check for a turn back.. so you will not have to go to the end of the block to be able
	;## to turn back...

		mov eax,PDir
		cmp eax,NewKeyDir
		je ExitFun
			cmp NewKeyDir,0			
			je Good1
			cmp NewKeyDir,2
			jne BadBad1
			Good1:
				cmp XmodW,0
				je BadBad1
				cmp YmodH,0
				jne BadBad1
					m2m PDir,NewKeyDir
			BadBad1:
			
			cmp NewKeyDir,1	
			je Good2
			cmp NewKeyDir,3
			jne BadBad2
			Good2:
				cmp XmodW,0
				jne BadBad2
				cmp YmodH,0
				je BadBad2
					m2m PDir,NewKeyDir
			BadBad2:

	ExitFun:


	pop edi

	return 0
CheckKeys Endp

; ########################################################################


MovePlayer proc
	
	
	LOCAL XmodW:DWORD
	LOCAL YmodH:DWORD

	LOCAL BoxX:DWORD
	LOCAL BoxY:DWORD

	LOCAL ifcando:DWORD

	mov ifcando,1

	push edi
	
	;Get X mod and div
	mov eax,PlayerX
	mov edi,BoxDim
	mov edx,0
	div edi
	mov XmodW,edx
	mov BoxX,eax
	
	;Get Y mod and div
	mov eax,PlayerY
	mov edi,BoxDim
	mov edx,0
	div edi
	mov YmodH,edx
	mov BoxY,eax
	

	;if both zero...
	cmp XmodW,0
	jne [notOK]
	cmp YmodH,0
	jne [notOK]
					
		.IF PDir == 0
			mov eax,BoxX
			mov edi,LevelMaxX
			dec edi
			.IF eax < edi
				inc eax
				invoke GetIndexByCoord,hLevel,eax,BoxY,1	;### after this eax holds the array item address
				;## Test if this is the char we want
				cmp eax,35	;char #
				jne Bad0
				cmp eax,64	;char @
				je Bad0
				cmp eax,38	;char &
				je Bad0
					mov ifcando,0	;### disable direction
				Bad0:
			.ELSE
				m2m PlayerX,0
			.ENDIF

		.ELSEIF PDir == 2
			mov eax,BoxX
			.IF eax > 0
				dec eax
				invoke GetIndexByCoord,hLevel,eax,BoxY,1	;### after this eax holds the array item address
				;## Test if this is the char we want
				cmp eax,35	;char #
				jne Bad2
				cmp eax,64	;char @
				je Bad2
				cmp eax,38	;char &
				je Bad2
					mov ifcando,0	;### disable direction
				Bad2:
			.ELSE
				push edi
				push edx
					mov eax,BoxDim
					mov edi,LevelMaxX
					dec edi
					dec edi
					mul edi
					add eax,LevelStartX
					m2m PlayerX,eax
				pop edx
				pop edi
			.ENDIF

		.ELSEIF PDir == 1
			mov eax,BoxY
			.IF eax > 0
				dec eax
				invoke GetIndexByCoord,hLevel,BoxX,eax,1	;### after this eax holds the array item address
				;## Test if this is the char we want
				cmp eax,35	;char #
				jne Bad1
				cmp eax,64	;char @
				je Bad1
				cmp eax,38	;char &
				je Bad1
					mov ifcando,0	;### disable direction
				Bad1:
			.ELSE
				push edi
				push edx
					mov eax,BoxDim
					mov edi,LevelMaxY
					dec edi
					dec edi
					mul edi
					add eax,LevelStartY
					m2m PlayerY,eax
				pop edx
				pop edi
			.ENDIF


		.ELSEIF PDir == 3
			mov eax,BoxY
			mov edi,LevelMaxY
			dec edi
			.IF eax < edi
				inc  eax
				invoke GetIndexByCoord,hLevel,BoxX,eax,1	;### after this eax holds the array item address
				;## Test if this is the char we want
				cmp eax,35	;char #
				jne Bad3
				cmp eax,64	;char @
				je Bad3
				cmp eax,38	;char &
				je Bad3
					mov ifcando,0	;### disable direction
				Bad3:
			.ELSE
				m2m PlayerY,LevelStartY
			.ENDIF

		.ENDIF
		
	notOK:	

	.IF ifcando == 1
		mov eax,PlayerSpeed
		.IF PDir==0
			add PlayerX,eax
		.ELSEIF PDir==2
			sub PlayerX,eax
		.ELSEIF PDir==3
			add PlayerY,eax
		.ELSEIF PDir==1
			sub PlayerY,eax
		.ENDIF
	.ENDIF

	pop edi

	return 0
MovePlayer Endp


; ########################################################################


GetIndexByCoord proc ArrayPointer:DWORD , PosX:DWORD , PosY:DWORD , GetItemValue:DWORD
	
	push edi
	push edx

	mov eax,PosY
	mov edi,LevelMaxX
	mul edi
	add eax,PosX
	add eax,ArrayPointer

	cmp GetItemValue,0
	je notADR
		mov edi,eax
		mov eax,0
		mov al,[edi]
	notADR:
	
	pop edx
	pop edi
	
	return eax
GetIndexByCoord Endp


; ########################################################################


GetPointerByIndex proc ArrayPointer:DWORD , ItemInd:DWORD , GetItemValue:DWORD
	
	push edi
	push edx

	mov eax,ItemInd
	mov edi,4
	mul edi
	add eax,ArrayPointer

	cmp GetItemValue,0
	je notADR
		mov edi,eax
		mov eax,[edi]
	notADR:
	

	pop edx
	pop edi

	return eax
GetPointerByIndex Endp

; ########################################################################

CheckDotEat proc
	
	LOCAL XmodW:DWORD
	LOCAL YmodH:DWORD

	LOCAL tmpx:DWORD
	LOCAL tmpy:DWORD

	LOCAL X:DWORD
	LOCAL Y:DWORD

	LOCAL BoxX:DWORD
	LOCAL BoxY:DWORD


	push edx
	push edi

	
	mov Y,-3

	ForY:
		inc Y
		mov X,-3

		ForX:
			inc X
			
			;tmpx = PlayerX + ( PlayerSpeed * X )
			mov eax,PlayerSpeed
			mov edi,X
			mul edi
			add eax,PlayerX
			mov tmpx,eax

			;tmpy = PlayerY + ( PlayerSpeed * Y )
			mov eax,PlayerSpeed
			mov edi,Y
			mul edi
			add eax,PlayerY
			mov tmpy,eax
			
			;get mod and div for x
			mov eax,tmpx
			mov edx,0
			mov edi,BoxDim
			div edi
			mov XmodW,edx
			mov BoxX,eax
			
			;get mod and div for y
			mov eax,tmpy
			mov edx,0
			mov edi,BoxDim
			div edi
			mov YmodH,edx
			mov BoxY,eax			
			

			;both mod must be zero
			mov eax,XmodW
			cmp eax,0
			jne [BadCoord]
			mov eax,YmodH
			cmp eax,0
			jne [BadCoord]

				invoke GetIndexByCoord,hLevel,BoxX,BoxY,1
				cmp eax,46
				jne [NotDot]
					invoke GetIndexByCoord,hLevel,BoxX,BoxY,0
					mov edi,eax
					mov eax,32
					mov [edi],al	;Space
					add Score,10
					dec TotalDots
					invoke sndPlaySound ,ADDR SndEatDot,SND_ASYNC
				NotDot:
				
				cmp eax,79
				jne [NotBigDot]
					invoke GetIndexByCoord,hLevel,BoxX,BoxY,0
					mov edi,eax
					mov eax,32
					mov [edi],al	;Space
					add Score,50
					invoke GetTickCount
					mov PlayerSuperStart,eax
					mov PlayerIsSuper,1	;Make Pacman super
					dec TotalDots
					;### change & to @ to keep ghosts in
						invoke GetIndexByCoord,hLevel,DoorX,DoorY,0
						mov edi,eax
						mov eax,64
						mov [edi],al
				NotBigDot:
				
			BadCoord:

		cmp X,3
		jne [ForX]
		
	cmp Y,3
	jne [ForY]	


	pop edi
	pop edx
	
	return 0
CheckDotEat Endp

; ########################################################################

MakeLongToString proc Val:DWORD, lpString:DWORD
	
	LOCAL num:DWORD

	push ecx
	push edx
	push edi

	m2m num,Val
	mov ecx,8
        
	WhileECX:

		mov eax,num
		mov edx,0
		mov edi,10
		div edi

		mov num,eax 
		mov eax,edx
		add eax,48
	
		dec ecx

		mov edx ,lpString
        	add edx,ecx
		mov [edx],al
	
		cmp num,0
		jle [OutNow]

	cmp ecx,0
	jg [WhileECX]

	OutNow:
	
	pop edi
	pop edx
	pop ecx

	return 0
MakeLongToString Endp

; ########################################################################

MoveGhosts proc

	LOCAL XmodW:DWORD
	LOCAL YmodH:DWORD
	LOCAL Cnt:DWORD

	LOCAL BoxX:DWORD
	LOCAL BoxY:DWORD

	LOCAL RightBlocked:DWORD
	LOCAL LeftBlocked:DWORD
	LOCAL UpBlocked:DWORD
	LOCAL DownBlocked:DWORD


	LOCAL antiFreeze:DWORD
	LOCAL newDir:DWORD
	LOCAL tmpr:DWORD

	LOCAL PBoxX:DWORD
	LOCAL PBoxY:DWORD

	LOCAL tmpi:DWORD
	LOCAL n:DWORD

	push edi	
	push edx	
		
	mov Cnt,-1
	ForCnt:

		inc Cnt

		;#### Initialize Data ( took me some time to find out this problem :P )
		mov RightBlocked,0
		mov LeftBlocked,0
		mov UpBlocked,0
		mov DownBlocked,0

		;### XmodW=GhostX[ind] % boxWidth;
		invoke GetPointerByIndex,GhostX,Cnt,1
		mov edx,0
		mov edi,BoxDim
		div edi
		mov BoxX,eax
		mov XmodW,edx
		

		invoke GetPointerByIndex,GhostY,Cnt,1
		mov edx,0
		mov edi,BoxDim
		div edi
		mov BoxY,eax
		mov YmodH,edx
		
		.IF (XmodW==0) && (YmodH==0)
			mov eax,BoxX
			mov edi,LevelMaxX
			dec edi
			.IF eax < edi
				inc eax
				invoke GetIndexByCoord,hLevel,eax,BoxY,1	;### after this eax holds the array item address
				;## Test if this is the char we want
				cmp eax,35	;char #
				je Bad0
				cmp eax,64	;char @
				je Bad0
				jmp Out0
				Bad0:	
					mov RightBlocked,1	;### disable direction
				Out0:
			.ELSE
				mov RightBlocked,1	;### disable direction
			.ENDIF


			mov eax,BoxX
			.IF eax > 0
				dec eax
				invoke GetIndexByCoord,hLevel,eax,BoxY,1	;### after this eax holds the array item address
				;## Test if this is the char we want
				cmp eax,35	;char #
				je Bad2
				cmp eax,64	;char @
				je Bad2
				jmp Out2
				Bad2:	
					mov LeftBlocked,1	;### disable direction
				Out2:
			.ELSE
				mov LeftBlocked,1	;### disable direction
			.ENDIF


			mov eax,BoxY
			.IF eax > 0
				dec eax
				invoke GetIndexByCoord,hLevel,BoxX,eax,1	;### after this eax holds the array item address
				;## Test if this is the char we want
				cmp eax,35	;char #
				je Bad1
				cmp eax,64	;char @
				je Bad1
				jmp Out1
				Bad1:	
					mov UpBlocked,1	;### disable direction
				Out1:
			.ELSE
				mov UpBlocked,1	;### disable direction
			.ENDIF


			mov eax,BoxY
			mov edi,LevelMaxY
			dec edi
			.IF eax < edi
				inc  eax
				invoke GetIndexByCoord,hLevel,BoxX,eax,1	;### after this eax holds the array item address
				;## Test if this is the char we want
				cmp eax,35	;char #
				je Bad3
				cmp eax,64	;char @
				je Bad3
				jmp Out3
				Bad3:	
					mov DownBlocked,1	;### disable direction
				Out3:
			.ELSE
				mov DownBlocked,1	;### disable direction
			.ENDIF
			
			
			
			;now we know what is blocked... let's pick a random and check it
			

			invoke FakeRandom,15	;give a "random" value from 0-3
			mov tmpr,eax
			mov newDir,0
			mov antiFreeze,0

			WhileNewDir:


			.IF RightBlocked == 0 
				invoke GetPointerByIndex,GhostDir,Cnt,1
				cmp antiFreeze,100
				jge bypass0
				cmp tmpr,-10
				jle bypass0
				.IF (eax!=2)
					cmp tmpr,2
					jg [aElseIF0]
				bypass0:
						invoke GetPointerByIndex,GhostDir,Cnt,0
						mov edi,0
						mov [eax],edi
						mov tmpr,100
						mov newDir,1
						jmp [GotDir]
					aElseIF0:
						invoke FakeRandom,3	;give a "random" value from 0-7
						sub tmpr,eax
					aENDIF0:
				.ENDIF
			.ELSE
				invoke FakeRandom,3	;give a "random" value from 0-7
				sub tmpr,eax
			.ENDIF


			
			.IF LeftBlocked == 0 
				invoke GetPointerByIndex,GhostDir,Cnt,1
				cmp antiFreeze,100
				jge bypass2
				cmp tmpr,-10
				jle bypass2
				.IF (eax!=0)
					cmp tmpr,2
					jg [aElseIF2]
				bypass2:
						invoke GetPointerByIndex,GhostDir,Cnt,0
						mov edi,2
						mov [eax],edi
						mov tmpr,100
						mov newDir,1
						jmp [GotDir]
					aElseIF2:
						invoke FakeRandom,3	;give a "random" value from 0-7
						sub tmpr,eax
					aENDIF2:
				.ENDIF
			.ELSE
				invoke FakeRandom,3	;give a "random" value from 0-7
				sub tmpr,eax
			.ENDIF


			

			.IF DownBlocked == 0 
				invoke GetPointerByIndex,GhostDir,Cnt,1
				cmp antiFreeze,100
				jge bypass3
				cmp tmpr,-10
				jle bypass3
				.IF (eax!=1)
					cmp tmpr,2
					jg [aElseIF3]
				bypass3:
						invoke GetPointerByIndex,GhostDir,Cnt,0
						mov edi,3
						mov [eax],edi
						mov tmpr,100
						mov newDir,1
						jmp [GotDir]
					aElseIF3:
						invoke FakeRandom,3	;give a "random" value from 0-7
						sub tmpr,eax
					aENDIF3:
				.ENDIF
			.ELSE
				invoke FakeRandom,3	;give a "random" value from 0-7
				sub tmpr,eax	
			.ENDIF


			.IF UpBlocked == 0 
				invoke GetPointerByIndex,GhostDir,Cnt,1
				cmp antiFreeze,100
				jge bypass1
				cmp tmpr,-10
				jle bypass1
				.IF (eax!=3)
					cmp tmpr,2
					jg [aElseIF1]
				bypass1:
						invoke GetPointerByIndex,GhostDir,Cnt,0
						mov edi,1
						mov [eax],edi
						mov tmpr,100
						mov newDir,1
						jmp [GotDir]
					aElseIF1:
						invoke FakeRandom,3	;give a "random" value from 0-7
						sub tmpr,eax
					aENDIF1:
				.ENDIF
			.ELSE
				invoke FakeRandom,3	;give a "random" value from 0-7
				sub tmpr,eax	
			.ENDIF

			invoke FakeRandom,3	;give a "random" value from 0-7
			sub tmpr,eax

			inc antiFreeze

			cmp newDir,0	
			je [WhileNewDir]
			
			
			GotDir:

			
			;### This will make ghosts a bit smarter.... above they choose randomly a direction
			;### that could be taken
			
			;### Now bellow the look until the end of the line for pacman.. and follow him if they find him
			
			
			mov eax,PlayerX
			mov edi,BoxDim
			mov edx,0	
			div edi
			mov PBoxX,eax

			mov eax,PlayerY
			mov edi,BoxDim
			mov edx,0	
			div edi
			mov PBoxY,eax			
			
			
			mov tmpi,0
			m2m n,BoxX


			ForN1:
				cmp tmpi,0
				jne [ignr1]
					invoke GetIndexByCoord,hLevel,n,BoxY,1
					cmp eax,35
					jne [notWall1]
						mov tmpi,1
					notWall1:
						mov eax,n
						cmp eax,PBoxX
						jne [noPac1]
						mov eax,BoxY
						cmp eax,PBoxY
						jne [noPac1]
							.IF PlayerIsSuper==0
								invoke GetPointerByIndex,GhostDir,Cnt,0
								mov edi,0
								mov [eax],edi
							.ELSE
								.IF UpBlocked == 0
									invoke GetPointerByIndex,GhostDir,Cnt,0
									mov edi,1
									mov [eax],edi
								.ELSEIF DownBlocked==0
									invoke GetPointerByIndex,GhostDir,Cnt,0
									mov edi,3
									mov [eax],edi
								.ELSEIF LeftBlocked==0
									invoke GetPointerByIndex,GhostDir,Cnt,0
									mov edi,2
									mov [eax],edi
								;.ELSEIF RightBlocked==0
								;	invoke GetPointerByIndex,GhostDir,Cnt,0
								;	mov edi,0
								;	mov [eax],edi
								.ENDIF
							.ENDIF
						noPac1:
				ignr1:
			inc n
			mov eax,n
			cmp eax,LevelMaxX
			jl [ForN1]
			
			
			
			
			
			
			
			
			
			mov tmpi,0
			m2m n,BoxX


			ForN2:
				cmp tmpi,0
				jne [ignr2]
					invoke GetIndexByCoord,hLevel,n,BoxY,1
					cmp eax,35
					jne [notWall2]
						mov tmpi,1
					notWall2:
						mov eax,n
						cmp eax,PBoxX
						jne [noPac2]
						mov eax,BoxY
						cmp eax,PBoxY
						jne [noPac2]
							.IF PlayerIsSuper==0
								invoke GetPointerByIndex,GhostDir,Cnt,0
								mov edi,2
								mov [eax],edi
							.ELSE
								.IF UpBlocked == 0
									invoke GetPointerByIndex,GhostDir,Cnt,0
									mov edi,1
									mov [eax],edi
								.ELSEIF DownBlocked==0
									invoke GetPointerByIndex,GhostDir,Cnt,0
									mov edi,3
									mov [eax],edi
								;.ELSEIF LeftBlocked==0
								;	invoke GetPointerByIndex,GhostDir,Cnt,0
								;	mov edi,2
								;	mov [eax],edi
								.ELSEIF RightBlocked==0
									invoke GetPointerByIndex,GhostDir,Cnt,0
									mov edi,0
									mov [eax],edi
								.ENDIF
							.ENDIF
						noPac2:
				ignr2:
			dec n
			mov eax,n
			cmp eax,0
			jg [ForN2]
			
			
			
			
			
	
			
			
			
			
			
			mov tmpi,0
			m2m n,BoxY


			ForN3:
				cmp tmpi,0
				jne [ignr3]
					invoke GetIndexByCoord,hLevel,BoxX,n,1
					cmp eax,35
					jne [notWall3]
						mov tmpi,1
					notWall3:
						mov eax,n
						cmp eax,PBoxY
						jne [noPac3]
						mov eax,BoxX
						cmp eax,PBoxX
						jne [noPac3]
							.IF PlayerIsSuper==0
								invoke GetPointerByIndex,GhostDir,Cnt,0
								mov edi,1
								mov [eax],edi
							.ELSE
								;.IF UpBlocked == 0
								;	invoke GetPointerByIndex,GhostDir,Cnt,0
								;	mov edi,1
								;	mov [eax],edi
								.IF DownBlocked==0
									invoke GetPointerByIndex,GhostDir,Cnt,0
									mov edi,3
									mov [eax],edi
								.ELSEIF LeftBlocked==0
									invoke GetPointerByIndex,GhostDir,Cnt,0
									mov edi,2
									mov [eax],edi
								.ELSEIF RightBlocked==0
									invoke GetPointerByIndex,GhostDir,Cnt,0
									mov edi,0
									mov [eax],edi
								.ENDIF
							.ENDIF
						noPac3:
				ignr3:
			dec n
			mov eax,n
			cmp eax,0
			jg [ForN3]
			
			



			
			
			
			
			mov tmpi,0
			m2m n,BoxY


			ForN4:
				cmp tmpi,0
				jne [ignr4]
					invoke GetIndexByCoord,hLevel,BoxX,n,1
					cmp eax,35
					jne [notWall4]
						mov tmpi,1
					notWall4:
						mov eax,n
						cmp eax,PBoxY
						jne [noPac4]
						mov eax,BoxX
						cmp eax,PBoxX
						jne [noPac4]
							.IF PlayerIsSuper==0
								invoke GetPointerByIndex,GhostDir,Cnt,0
								mov edi,3
								mov [eax],edi
							.ELSE
								.IF UpBlocked == 0
									invoke GetPointerByIndex,GhostDir,Cnt,0
									mov edi,1
									mov [eax],edi
								;.ELSEIF DownBlocked==0
								;	invoke GetPointerByIndex,GhostDir,Cnt,0
								;	mov edi,3
								;	mov [eax],edi
								.ELSEIF LeftBlocked==0
									invoke GetPointerByIndex,GhostDir,Cnt,0
									mov edi,2
									mov [eax],edi
								.ELSEIF RightBlocked==0
									invoke GetPointerByIndex,GhostDir,Cnt,0
									mov edi,0
									mov [eax],edi
								.ENDIF
							.ENDIF
						noPac4:
				ignr4:
			inc n
			mov eax,n
			cmp eax,LevelMaxY
			jl [ForN4]
			
			
			
			
			
				
		.ENDIF


		invoke GetPointerByIndex,GhostDir,Cnt,1
		.IF eax==1
			invoke GetPointerByIndex,GhostY,Cnt,0
			mov edi,eax
			mov eax,[edi]
			sub eax,GhostSpeed
			mov [edi],eax

		.ELSEIF eax==3
			invoke GetPointerByIndex,GhostY,Cnt,0
			mov edi,eax
			mov eax,[edi]
			add eax,GhostSpeed
			mov [edi],eax

		.ELSEIF eax==0
			invoke GetPointerByIndex,GhostX,Cnt,0
			mov edi,eax
			mov eax,[edi]
			add eax,GhostSpeed
			mov [edi],eax

		.ELSEIF eax==2
			invoke GetPointerByIndex,GhostX,Cnt,0
			mov edi,eax
			mov eax,[edi]
			sub eax,GhostSpeed
			mov [edi],eax

		.ENDIF


	mov eax,Cnt
	inc eax
	cmp eax,GhostsCount
	jl [ForCnt]
	

	
	pop edx
	pop edi

	return 0
MoveGhosts Endp

; ########################################################################

FakeRandom proc MaskWord:DWORD
	
	push edi

	;invoke GetTickCount
	;mov edi ,MaskWord
	;and eax,edi

	invoke prand,435345345
	mov edi ,MaskWord
	and eax,edi

	pop edi	
	return eax
FakeRandom Endp

; ########################################################################

BoxCollisionDetection proc hBmpMask1:DWORD , X1:DWORD , Y1:DWORD , W1:DWORD , H1:DWORD ,  hBmpMask2:DWORD , X2:DWORD , Y2:DWORD , W2:DWORD , H2:DWORD
	
	LOCAL tX:DWORD
	LOCAL tY:DWORD
	LOCAL tW:DWORD
	LOCAL tH:DWORD

	LOCAL i1:DWORD
	LOCAL i2:DWORD
	LOCAL i3:DWORD

	LOCAL memDC:DWORD
	LOCAL hBmp:DWORD

	LOCAL tmpX:DWORD
	LOCAL tmpY:DWORD

	push edi
	push edx	
	
	


	mov eax,X1
	cmp eax,X2
	jle [LessTrue1]
		;X1>X2
		mov eax,X2
		add eax,W2
		sub eax,X1
		mov tW,eax

		mov eax,W2
		sub eax,tW
		mov tX,eax

		jmp [EndIF1]
	LessTrue1:
		;X1<=X2
		mov eax,X1
		add eax,W1
		sub eax,X2
		mov tW,eax

		mov eax,W1
		sub eax,tW
		mov tX,eax
	EndIF1:
	
	


	mov eax,Y1
	cmp eax,Y2
	jle [LessTrue2]
		;Y1>Y2
		mov eax,Y2
		add eax,H2
		sub eax,Y1
		mov tH,eax

		mov eax,H2
		sub eax,tH
		mov tY,eax

		jmp [EndIF2]
	LessTrue2:
		;Y1<=Y2
		mov eax,Y1
		add eax,H1
		sub eax,Y2
		mov tH,eax

		mov eax,H1
		sub eax,tH
		mov tY,eax
	EndIF2:

	mov eax,0

	cmp tW,0
	jle [ExitFunction]
	cmp tH,0
	jle [ExitFunction]

	mov eax,1
	jmp [ExitFunction]
	
	ExitFunction:

	pop edx
	pop edi
	
	return eax
BoxCollisionDetection Endp

; ########################################################################

CheckCollisions proc

	LOCAL i1:DWORD
	LOCAL i2:DWORD
	LOCAL i3:DWORD
	LOCAL i4:DWORD
	LOCAL i5:DWORD
	LOCAL cnt:DWORD

	mov cnt,-0
	ForCnt:

		invoke GetPointerByIndex,hBmpGhostMask,0,1
		mov i1,eax

		invoke GetPointerByIndex,GhostX,cnt,1
		mov i2,eax
		add i2,3

		invoke GetPointerByIndex,GhostY,cnt,1
		mov i3,eax
		add i3,3

		invoke GetPointerByIndex,hBmpPacMaskArray,0,1
		mov i4,eax

		m2m i5,BoxDim
		sub i5,6

		invoke BoxCollisionDetection ,i4,PlayerX,PlayerY,BoxDim,BoxDim,i1,i2,i3,i5,i5

		.IF eax==1
			;### got Collision
			.IF PlayerIsSuper == 0
				;### Player Lost
				mov GameStatus,3
				dec PlayerLives
				invoke GetTickCount
				mov PlayerLostTime,eax
				invoke sndPlaySound,ADDR SndLost,SND_ASYNC
				jmp [ExitFunction]
			.ELSE
				;### Reset Ghost Pos
					push edi
					push edx

					mov eax,cnt
					mov edi,4
					mul edi
					push eax

					add eax,GhostX
					mov edi,eax
					mov eax,GhostsSpawnX
					mov [edi],eax
	
					pop eax

					add eax,GhostY
					mov edi,eax
					mov eax,GhostsSpawnY
					mov [edi],eax



					;### Add Points based on the eaten in row ( base of 2 + 1 * mul )
					inc GhostEatenInRow
					mov eax,1
					mov edi,GhostEatenInRow
					inc edi
					Whileedi:
					shl eax,1
					dec edi
					cmp edi,0
					jg [Whileedi]
					mov edi , GhostEatenInRowMul
					mul edi
					
					add Score,eax
					
					pop edx
					pop edi

			.ENDIF
		.ENDIF
	
	inc cnt
	mov eax,cnt
	cmp eax,GhostsCount	
	jl [ForCnt]
	
	ExitFunction:

	return 0
CheckCollisions Endp

; ########################################################################

CheckCustomButtons proc MouseX:DWORD , MouseY:DWORD , ButtonX:DWORD , ButtonY:DWORD  ,ButtonW:DWORD , ButtonH:DWORD


	mov eax,MouseX
	cmp eax,ButtonX
	jl [notOver]
		mov eax,ButtonX
		add eax,ButtonW
		cmp MouseX,eax
		jg [notOver]
			mov eax,MouseY
			cmp eax,ButtonY
			jl [notOver]
				mov eax,ButtonY
				add eax,ButtonH
				cmp MouseY,eax
				jg [notOver]

				mov eax,1
				jmp [ExitFunction]
	notOver:

	mov eax,0

	ExitFunction:

	return eax
CheckCustomButtons Endp

; ########################################################################

OtherStuff proc

	;### Re Seed Random Num Generator
	invoke GetTickCount
	inc seed1
	inc seed2		
	inc seed3
	invoke pseed,seed1,seed1,seed3,eax

	
	;### Check for pacmans super timer timeout
	.IF PlayerIsSuper == 1
		invoke GetTickCount
		sub eax,PlayerSuperLast
		cmp PlayerSuperStart,eax
		jg [notYet]
			mov PlayerIsSuper,0
			mov GhostEatenInRow,0
			;### change & to @ to open the door so ghosts can get out
				invoke GetIndexByCoord,hLevel,DoorX,DoorY,0
				mov edi,eax
				mov eax,38
				mov [edi],al
		notYet:
	.ENDIF


	;### check for victory
	cmp TotalDots,0
	jg [notFinished]
		mov GameStatus,4
		invoke GetTickCount
		mov WonMsgStart,eax
	notFinished:
	
	return 0
OtherStuff EndP

; ########################################################################

ChooseNPlayMidi proc

	mov eax,OFFSET tmpString
	add eax,6
	
	mov edi,eax
	mov ax,3030h
	mov [edi],ax

	invoke FakeRandom,14
	inc eax

	invoke MakeLongToString,eax,ADDR tmpString

	mov edi,OFFSET PlayMidiFileName
	add edi,5

	mov eax,OFFSET tmpString
	add eax,6

	mov esi,eax
	
	mov ax,[esi]
	mov [edi],ax
	
	mov PlayFlag,1  
	invoke PlayMidiFile,ADDR PlayMidiFileName

	return 0;
ChooseNPlayMidi Endp

; ########################################################################



; ########################################################################

PlayMidiFile proc NameOfFile:DWORD

      LOCAL mciOpenParms:MCI_OPEN_PARMS,mciPlayParms:MCI_PLAY_PARMS

            mov eax,hWin        
            mov mciPlayParms.dwCallback,eax
            mov eax,OFFSET szMIDISeqr
            mov mciOpenParms.lpstrDeviceType,eax
            mov eax,NameOfFile
            mov mciOpenParms.lpstrElementName,eax
            invoke mciSendCommand,0,MCI_OPEN,MCI_OPEN_TYPE or MCI_OPEN_ELEMENT,ADDR mciOpenParms
            mov eax,mciOpenParms.wDeviceID
            mov MidDeviceID,eax
            invoke mciSendCommand,MidDeviceID,MCI_PLAY,MCI_NOTIFY,ADDR mciPlayParms
            ret  

PlayMidiFile endp

; ########################################################################

;RANDOM ROUTINE FROM http://www.masm32.com/board/index.php?PHPSESSID=b552497e20a62c0d96a7bd80a889b3bb&topic=4895.0

pseed PROC s1:DWORD,s2:DWORD,s3:DWORD,s4:DWORD

mov eax,s1 ;if s1 = 0 then use default value
.if eax!=0
mov seed1,eax
.endif
mov eax,s2 ;if s2 = 0 then use default value
.if eax!=0
mov seed2,eax
.endif
mov eax,s3 ;if s3 = 0 then use default value
.if eax!=0
mov seed3,eax
.endif
mov eax,s4 ;if s4 = 0 then use default value
.if eax!=0
mov seed4,eax
.endif
ret

pseed ENDP

prand PROC base:DWORD
;seed1 = AAAABBBB
;seed2 = CCCCDDDD
;seed3 = EEEEFFFF
;seed4 = 11112222

mov eax,seed1 ;AAAABBBB
mov ebx,seed2 ;CCCCDDDD
mov ecx,seed3 ;EEEEFFFF
mov edx,seed4 ;11112222
;start shifting
xchg ax,bx    ;eax = AAAADDDD, ebx = CCCCBBBB
xchg cx,dx   ;ecx = EEEE2222, edx = 1111FFFF
xchg al,cl   ;eax = AAAADD22, ecx = EEEE22DD
xchg bl,dl   ;ebx = CCCCBBFF, edx = 1111FFBB
push eax   ;AAAADD22
push ecx      ;EEEE22DD
shl eax,8   ;AADD2200
shr ecx,24   ;000000EE
add eax,ecx   ;AADD22EE
mov seed1,eax   ;s1 = AADD22EE
pop ecx   ;EEEE22DD
pop eax   ;AAAADD22
push ecx   ;EEEE22DD
shr eax,24   ;000000AA
push edx   ;1111FFBB
shl edx,8   ;11FFBB00
add edx,eax   ;11FFBBAA
mov seed2,edx    ;s2 = 11FFBBAA
pop edx   ;1111FFBB
shr edx,24   ;00000011
push ebx   ;CCCCBBFF
shl ebx,8   ;CCBBFF11
mov seed3,ebx   ;s3 = CCBBFF11
pop ebx   ;CCCCBBFF
shr ebx,24   ;000000CC
pop ecx   ;EEEE22DD
shl ecx,8   ;EE22DD00
add ecx,ebx   ;EE22DDCC
mov seed4,ecx    ;s4 = EE22DDCC
;start calculating
mov eax,seed1
mov ecx,16587
xor edx,edx
div ecx   ;AADD22EE / 16587, result in eax, remainder in edx
mov ebx,seed2    ;11FFBBAA
xchg ebx,eax 
sub eax,ebx   ;11FFBBAA - remainder
mov ecx,edx
xor edx,edx
mul ecx
mov seed2,eax    ;seed2 = (s1 / 16587)*(s2 - (s1 % 16587))

mov ecx,29753
xor edx,edx
div ecx ; (s2 / 29753)
mov ebx,seed3   ;CCBBFF11
xchg ebx,eax
sub eax,ebx  ;CCBBFF11 - remainder
mov ecx,edx
xor edx,edx
mul ecx
mov seed3,eax   ;seed3 = (s2 / 29753)*(s3 - (s2 % 29753))

mov ecx,39744
xor edx,edx
div ecx ; (s3 / 39744)
mov ebx,seed4   ;EE22DDCC
xchg ebx,eax
sub eax,ebx  ;EE22DDCC - remainder
mov ecx,edx
xor edx,edx
mul ecx
mov seed4,eax   ;seed4 = (s3 / 39744)*(s4 - (s3 % 39744))

mov ecx,59721
xor edx,edx
div ecx ; (s4 / 59721)
mov ebx,seed1   ;AADD22EE
xchg ebx,eax
sub eax,ebx  ;AADD22EE - remainder
mov ecx,edx
xor edx,edx
mul ecx
mov seed1,eax   ;seed1 = (s4 / 59721)*(s1 - (s4 % 59721))
;use every last byte of each new seed
shl eax,24
mov ebx,seed2
shl ebx,24
shr ebx,8
add eax,ebx
mov ebx,seed3
shl ebx,24
shr ebx,16
add eax,ebx
mov ebx,seed4
add al,bl
mov ebx,seed1
xor eax,ebx
xor edx,edx
div base
    mov eax,edx
    ret

prand ENDP

; ########################################################################


end start
