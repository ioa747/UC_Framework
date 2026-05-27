; UC_Button.au3
#include-once

#include "Frame\UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC Label  API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func _UC_Label_Create($hParent, $sText, $iX, $iY, $iW, $iH, $iRotationIdx = 0, $hColor = 0xFFFFFF, $hBkColor = -2)
	GUISwitch($hParent)
	Local $idDummy = GUICtrlCreateDummy()
	Local $hChild = GUICreate("UC_Control_" & $idDummy, $iW, $iH, $iX, $iY, BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS), $WS_EX_TRANSPARENT, $hParent)

	If $iRotationIdx > 3 Or $iRotationIdx < 0 Then $iRotationIdx = 0

	__UC_Framework_Init($hParent)

;~ 	GUISetCursor(_UC_Get(1, "Cursor_Hand"), $GUI_CURSOR_OVERRIDE, $hChild)

	Local $m[]
	$m.UC_Type = $UC_TYPE_LABEL
	$m.UC_ControlID = $idDummy
	$m.UC_hWnd = $hChild
	$m.UC_hParent = $hParent

	; Registered Event Handlers
	$m["UC_WM_" & $WM_LBUTTONDOWN] = "_WM_LBUTTONDOWN"
	$m["UC_WM_" & $WM_LBUTTONDBLCLK] = "_WM_LBUTTONDBLCLK"
	$m["UC_WM_" & $WM_LBUTTONUP] = "_WM_LBUTTONUP"
;~ 	$m["UC_WM_" & $WM_RBUTTONDOWN] = "_WM_RBUTTONDOWN"
;~ 	$m["UC_WM_" & $WM_RBUTTONUP] = "_WM_RBUTTONUP"
	$m["UC_WM_" & $WM_MOUSEMOVE] = "_WM_MOUSEMOVE"
	$m["UC_WM_" & $WM_SETFOCUS] = "_WM_SETFOCUS"
	$m["UC_WM_" & $WM_KEYDOWN] = "_WM_KEYDOWN"

	; Properties
	$m.Text = $sText
	$m.RotationIdx = $iRotationIdx ; 0=0, 1=90, 2=180, 3=270
	$m.Color = $hColor             ; Text Color
	$m.Color_Bk = $hBkColor        ; -2 = Transparent (Parent Color) ; $GUI_BKCOLOR_TRANSPARENT
	$m.Color_Hover = $hColor       ; Default: same as color
	$m.Font = "Segoe UI"           ; font name
	$m.FontSize = 9                ; Initial Size
	$m.FontStyle = 0               ; 0=Normal, 1=Bold, etc.
	$m.Padding = 4                 ; Internal safety margin
	$m.State = 1                   ; 0=Disable ; 1=Normal ; 2=Hover ; 3=Pressed

	_WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)
	_UC_Properties($idDummy, $m)
	_UC_Properties(1, "UC_LastCreatedID", $idDummy)

	GUISwitch($hParent)
	Return $idDummy
EndFunc   ;==>_UC_Label_Create

Func _UC_Label_Draw($hWnd, ByRef $m)
	Local $aClientSize = WinGetClientSize($hWnd)
	Local $iW = $aClientSize[0], $iH = $aClientSize[1]

	; GUISetCursor(_UC_Get(1, ($m.State == 0 ? "Cursor_Arrow" : "Cursor_Hand")), $GUI_CURSOR_OVERRIDE, $hWnd)

	Local $hBGColor = "0xFF" & Hex(($m.Color_Bk == -2 ? __UC_ParentColor($hWnd) : $m.Color_Bk), 6)

	Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hWnd)
	Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics($iW, $iH, $hGraphics)
	Local $hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)

	; Settings for Sharpening
	_GDIPlus_GraphicsSetSmoothingMode($hBack, 4)     ; HighQuality Antialiasing
	_GDIPlus_GraphicsSetPixelOffsetMode($hBack, 4)   ; HighQuality (Half-pixel offset)
	_GDIPlus_GraphicsSetTextRenderingHint($hBack, 5) ; TextRenderingHintClearTypeGridFit

	_GDIPlus_GraphicsClear($hBack, $hBGColor)

	; --- CLAMPING LOGIC ---
	Local $fFitSize = $m.FontSize
	Local $aSize
	Local $aAngles = [0, 90, 180, 270]
	Local $iAngle = $aAngles[$m.RotationIdx]
	While 1
		$aSize = _UC_GetTextSize($m.Text, $m.Font, $fFitSize, $m.FontStyle)

		Local $iTargetDim = ($iAngle = 90 Or $iAngle = 270) ? $iH : $iW

		If $aSize[0] > ($iTargetDim - $m.Padding) And $fFitSize > 4 Then
			$fFitSize -= 0.5
		Else
			ExitLoop
		EndIf
	WEnd
	$m.FontSize = $fFitSize

	; --- STYLING ---
	Local $iDrawCol = ($m.State = 2 ? $m.Color_Hover : $m.Color)
	Local $hBrushTxt = _GDIPlus_BrushCreateSolid("0xFF" & Hex($iDrawCol, 6))
	Local $hFamily = _GDIPlus_FontFamilyCreate($m.Font)
	Local $hFont = _GDIPlus_FontCreate($hFamily, $m.FontSize, $m.FontStyle)

	Local $hFormat = _GDIPlus_StringFormatCreate(0x1000)
	_GDIPlus_StringFormatSetAlign($hFormat, 1)
	_GDIPlus_StringFormatSetLineAlign($hFormat, 1)

	; --- ROTATION & TRANSLATION ---
	_GDIPlus_GraphicsTranslateTransform($hBack, $iW / 2, $iH / 2)
	_GDIPlus_GraphicsRotateTransform($hBack, $iAngle)

	; We use large values ​​to avoid clipping.
	Local $iDim = ($iW > $iH ? $iW : $iH) * 2
	Local $tLayout = _GDIPlus_RectFCreate(-$iDim / 2, -$iDim / 2, $iDim, $iDim)

	; Present to Screen
	_GDIPlus_GraphicsDrawStringEx($hBack, $m.Text, $hFont, $tLayout, $hFormat, $hBrushTxt)
	_GDIPlus_GraphicsDrawImage($hGraphics, $hBitmap, 0, 0)

	; Cleanup
	_GDIPlus_StringFormatDispose($hFormat)
	_GDIPlus_FontDispose($hFont)
	_GDIPlus_FontFamilyDispose($hFamily)
	_GDIPlus_BrushDispose($hBrushTxt)
	_GDIPlus_GraphicsDispose($hBack)
	_GDIPlus_BitmapDispose($hBitmap)
	_GDIPlus_GraphicsDispose($hGraphics)
EndFunc   ;==>_UC_Label_Draw

Func _UC_Label_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	$m.State = 3 ; is pressed
	_UC_Properties($idDummy, $m)
	_WinAPI_SetCapture($hWnd)
EndFunc   ;==>_UC_Label_WM_LBUTTONDOWN

Func _UC_Label_WM_LBUTTONDBLCLK($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	; For now, a double click on a button should behave exactly like a fast single click.
	; So we just forward the parameters straight to the Down handler.
	Return _UC_Label_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_Label_WM_LBUTTONDBLCLK

Func _UC_Label_WM_LBUTTONUP($idDummy, $hWnd, $iX, $iY)
	#forceref $idDummy, $iX, $iY
	Local $m = _UC_Properties($idDummy)

	If $m.State = 3 Then ; If is pressed
		_WinAPI_ReleaseCapture()

		; Area control
		If _UC_IsMouseOver($hWnd) Or ($iX = -1 And $iY = -1) Then
			$m.State = 2 ; Hover
			_UC_Properties($idDummy, $m)
			GUICtrlSendToDummy($idDummy, $m.Value) ; Execution!
		Else
			$m.State = 1 ; Normal (Cancel execution)
			_UC_Properties($idDummy, $m)
		EndIf
	EndIf
EndFunc   ;==>_UC_Label_WM_LBUTTONUP

Func _UC_Label_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	If $m.State = 1 Then ; If is normal
		$m.State = 2
		_UC_Properties($idDummy, $m)
	EndIf
EndFunc   ;==>_UC_Label_WM_MOUSEMOVE

Func _UC_Label_WM_SETFOCUS($idDummy, $hWnd, $iX, $iY)
	_UC_Label_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_Label_WM_SETFOCUS

Func _UC_Label_WM_KEYDOWN($idDummy, $hWnd, $iKeyCode, $aXY)
	Switch $iKeyCode
		Case $VK_SPACE
			_UC_Label_WM_LBUTTONDOWN($idDummy, $hWnd, $aXY[0], $aXY[1])
			Sleep(50)
			_UC_Label_WM_LBUTTONUP($idDummy, $hWnd, -1, -1)
	EndSwitch
EndFunc   ;==>_UC_Label_WM_KEYDOWN

#EndRegion ; ~~~~~~~~~~~~~ UC Label  API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
