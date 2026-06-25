; UC_Toggle.au3
#include-once

#include "Frame\UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC Toggle API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func _UC_Toggle_Create($hParent, $iX, $iY, $iW, $iH, $iType = 0, $hOnCol = Default, $hOffCol = Default, $hBtnCol = Default)
	GUISwitch($hParent)
	Local $idDummy = GUICtrlCreateDummy()
	Local $hChild = GUICreate("UC_Control_" & $idDummy, $iW, $iH, $iX, $iY, BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS, $WS_TABSTOP), $WS_EX_TRANSPARENT, $hParent)

	__UC_Framework_Init($hParent)

	GUISetCursor(_UC_Get(1, "Cursor_Hand"), $GUI_CURSOR_OVERRIDE, $hChild)

	Local $m[]

	; Universal Properties
	$m.UC_Type = $UC_TYPE_TOGGLE
	$m.UC_ControlID = $idDummy
	$m.UC_hWnd = $hChild
	$m.UC_hParent = $hParent
	$m.UC_Width = $iW
	$m.UC_Height = $iH
	$m.UC_Shadow = 1  ; 💡 1 = Shadow active, 0 = Inactive

	; Registered Event Handlers
	$m["UC_WM_" & $WM_LBUTTONDOWN] = "_WM_LBUTTONDOWN"
	$m["UC_WM_" & $WM_LBUTTONDBLCLK] = "_WM_LBUTTONDBLCLK"
	$m["UC_WM_" & $WM_LBUTTONUP] = "_WM_LBUTTONUP"
;~ 	$m["UC_WM_" & $WM_RBUTTONDOWN] = "_WM_RBUTTONDOWN"
;~ 	$m["UC_WM_" & $WM_RBUTTONUP] = "_WM_RBUTTONUP"
	$m["UC_WM_" & $WM_MOUSEMOVE] = "_WM_MOUSEMOVE"
	$m["UC_WM_" & $WM_SETFOCUS] = "_WM_SETFOCUS"
	$m["UC_WM_" & $WM_KEYDOWN] = "_WM_KEYDOWN"

	; Specific properties for the toggle control
	$m.State = 1           ; Initially enabled (State 0=Disabled, 1=Normal, 2=Hover, 3=Pressed)
	$m.Type = $iType       ; Type of toggle (0=ROUNDED, 1=RECTANGLE)
	$m.Value = 0           ; Initial value (0=off, 1=on)
	$m.OnColor = $hOnCol   ; Color when the toggle is on
	$m.OffColor = $hOffCol ; Color when the toggle is off
	$m.BtnColor = $hBtnCol ; Color of the Thumb button

	_WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)
	_UC_Properties($idDummy, $m, Default, "UC_Toggle.au3") ; ℹ️ Default trigger redraw
	_UC_Properties(1, "UC_LastCreatedID", $idDummy, "UC_Toggle.au3")

	GUISwitch($hParent)
	Return $idDummy
EndFunc   ;==>_UC_Toggle_Create

Func _UC_Toggle_Draw($hWnd, ByRef $m)
	Local $mTheme = _UC_Themes("Active")

;~ 	; Theme-Aware Resolution
	Local $iBgColor = ($m.Value ? ($m.OnColor == Default ? $mTheme.Themes_Accent : $m.OnColor) : ($m.OffColor == Default ? $mTheme.Themes_Accent : $m.OffColor))

	Local $iBtnColor = ($m.BtnColor == Default ? $mTheme.Surface_Face : $m.BtnColor)

	Local $hBGColor = "0xFF" & Hex(__UC_ParentColor($hWnd), 6)

	Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hWnd)
;~ 	Local $aSize = WinGetClientSize($hWnd)
;~ 	Local $iW = $aSize[0], $iH = $aSize[1]
	Local $iW = $m.UC_Width, $iH = $m.UC_Height

	; Buffer Setup
	Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics($iW, $iH, $hGraphics)
	Local $hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)

	; Settings for Sharpening
	_GDIPlus_GraphicsSetSmoothingMode($hBack, 4)     ; HighQuality Antialiasing
	_GDIPlus_GraphicsSetPixelOffsetMode($hBack, 4)   ; HighQuality (Half-pixel offset)

	; Clear background
	_GDIPlus_GraphicsClear($hBack, $hBGColor)

	; Resources
	Local $hBrushBg = _GDIPlus_BrushCreateSolid("0xff" & Hex($iBgColor, 6))
	Local $hBrushBtn = _GDIPlus_BrushCreateSolid("0xff" & Hex($iBtnColor, 6))
	Local $hPenHotTrack = _GDIPlus_PenCreate("0x80" & Hex($iBtnColor, 6), 4) ; HotTrack semi-transparent

	Local $iR, $iXPos, $iBtnW

	If $m.Type = 0 Then ; ROUND TYPE
		$iR = $iH / 2 ; Fully rounded corners (Pill shape)

		; Draw Toggle Background
		__UC_DrawRoundedRect($hBack, 0, 0, $iW - 1, $iH - 1, $iR, $hBrushBg, 0)

		; Calculate Slider Button Position
		$iXPos = $m.Value ? ($iW - $iH + 2) : 2
		$iBtnW = $iH - 5 ; Circle diameter

		; Draw Slider Button
		__UC_DrawRoundedRect($hBack, $iXPos, 2, $iBtnW, $iBtnW, $iBtnW / 2, $hBrushBtn, ($m.State = 2 ? $hPenHotTrack : 0))

	Else ; RECT TYPE
		$iR = 0 ; Sharp corners

		; Draw Toggle Background
		__UC_DrawRoundedRect($hBack, 0, 0, $iW, $iH, $iR, $hBrushBg, 0)

		; Calculate Slider Button Position
		Local $iSqW = ($iW / 3) - 4
		Local $iSqX = $m.Value ? ($iW - $iSqW - 2) : 2

		; Draw Slider Button
		__UC_DrawRoundedRect($hBack, $iSqX, 2, $iSqW, $iH - 4, $iR, $hBrushBtn, ($m.State = 2 ? $hPenHotTrack : 0))
	EndIf

	; Present to Screen
	_GDIPlus_GraphicsDrawImageRect($hGraphics, $hBitmap, 0, 0, $iW, $iH)

	; 💡AUTOMATED SHADOW ENGINE
	If $m.UC_Shadow = 1 Then _UC_Shadow_Overlay($m.UC_ControlID, 150, 10, True, -1)

	; Cleanup
	_GDIPlus_PenDispose($hPenHotTrack)
	_GDIPlus_BrushDispose($hBrushBg)
	_GDIPlus_BrushDispose($hBrushBtn)
	_GDIPlus_GraphicsDispose($hBack)
	_GDIPlus_BitmapDispose($hBitmap)
	_GDIPlus_GraphicsDispose($hGraphics)
EndFunc   ;==>_UC_Toggle_Draw

Func _UC_Toggle_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy, Default, Default, "UC_Toggle.au3")

	__DW("_UC_Toggle_WM_LBUTTONDOWN :: $idDummy=" & $idDummy & " :: $m.State=" & $m.State & @CRLF, 1, ">> UC_Toggle.au3")

	If $m.State = 0 Then Return ; If is Disabled
	$m.State = 3 ; is pressed
	_UC_Properties($idDummy, $m, Default, "UC_Toggle.au3")
	_WinAPI_SetCapture($hWnd)
EndFunc   ;==>_UC_Toggle_WM_LBUTTONDOWN

Func _UC_Toggle_WM_LBUTTONDBLCLK($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	__DW("_UC_Toggle_WM_LBUTTONDBLCLK :: $idDummy=" & $idDummy & @CRLF, 1, ">> UC_Toggle.au3")

	; For now, a double click on a button should behave exactly like a fast single click.
	; So we just forward the parameters straight to the Down handler.
	Return _UC_Toggle_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_Toggle_WM_LBUTTONDBLCLK

Func _UC_Toggle_WM_LBUTTONUP($idDummy, $hWnd, $iX, $iY)
	#forceref $idDummy, $iX, $iY
	Local $m = _UC_Properties($idDummy, Default, Default, "UC_Toggle.au3")
	__DW("_UC_Toggle_WM_LBUTTONUP :: $idDummy=" & $idDummy & " :: $m.State=" & $m.State & @CRLF, 1, ">> UC_Toggle.au3")

	If $m.State = 3 Then ; If is pressed
		_WinAPI_ReleaseCapture()

		; Area control
		If _UC_IsMouseOver($hWnd) Or ($iX = -1 And $iY = -1) Then
			$m.State = 2 ; Hover
			$m.Value = ($m.Value = 1 ? 0 : 1)
			_UC_Properties($idDummy, $m, Default, "UC_Toggle.au3")
			GUICtrlSendToDummy($idDummy, $m.Value) ; Execution!
		Else
			$m.State = 1 ; Normal (Cancel execution)
			_UC_Properties($idDummy, $m, Default, "UC_Toggle.au3")
		EndIf
	EndIf
EndFunc   ;==>_UC_Toggle_WM_LBUTTONUP

Func _UC_Toggle_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy, Default, Default, "UC_Toggle.au3")
	__DW("_UC_Toggle_WM_MOUSEMOVE :: $idDummy=" & $idDummy & " :: $m.State=" & $m.State & @CRLF, 1, ">> UC_Toggle.au3")

	If $m.State = 0 Then Return ; If is Disabled
	If $m.State = 1 Then ; If is normal
		$m.State = 2 ; Hover
		_UC_Properties($idDummy, $m, Default, "UC_Toggle.au3")
	EndIf
EndFunc   ;==>_UC_Toggle_WM_MOUSEMOVE

Func _UC_Toggle_WM_SETFOCUS($idDummy, $hWnd, $iX, $iY)
	__DW("_UC_Toggle_WM_SETFOCUS :: $idDummy=" & $idDummy & @CRLF, 1, ">> UC_Toggle.au3")
	_UC_Toggle_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_Toggle_WM_SETFOCUS

Func _UC_Toggle_WM_KEYDOWN($idDummy, $hWnd, $iKeyCode, $aXY)
	__DW("_UC_Toggle_WM_KEYDOWN :: $idDummy=" & $idDummy & @CRLF, 1, ">> UC_Toggle.au3")
	Switch $iKeyCode
		Case $VK_SPACE
			_UC_Toggle_WM_LBUTTONDOWN($idDummy, $hWnd, $aXY[0], $aXY[1])
			Sleep(50)
			_UC_Toggle_WM_LBUTTONUP($idDummy, $hWnd, -1, -1)
	EndSwitch
EndFunc   ;==>_UC_Toggle_WM_KEYDOWN

#EndRegion ; ~~~~~~~~~~~~~ UC Toggle API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
