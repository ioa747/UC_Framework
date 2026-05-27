; UC_HourMinute.au3
#include-once

#include "Frame\UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC HourMinute ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func _UC_HourMinute_Create($hParent, $iX, $iY, $iHour = 0, $iMinute = 30, $iWidth = 80, $iHeight = 26)
	GUISwitch($hParent)
	Local $idDummy = GUICtrlCreateDummy()
	Local $hChild = GUICreate("UC_Control_" & $idDummy, $iWidth, $iHeight, $iX, $iY, _
			BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS, $WS_TABSTOP), $WS_EX_TRANSPARENT, $hParent)

	__UC_Framework_Init($hParent)

	Local $m[]
	$m.UC_Type = $UC_TYPE_HOURMINUTE
	$m.UC_ControlID = $idDummy
	$m.UC_hWnd = $hChild
	$m.UC_hParent = $hParent

	; Registered Event Handlers
	$m["UC_WM_" & $WM_LBUTTONDOWN] = "_WM_LBUTTONDOWN"
	$m["UC_WM_" & $WM_LBUTTONDBLCLK] = "_WM_LBUTTONDBLCLK"
	$m["UC_WM_" & $WM_LBUTTONUP] = "_WM_LBUTTONUP"
	;$m["UC_WM_" & $WM_RBUTTONDOWN] = "_WM_RBUTTONDOWN"
	;$m["UC_WM_" & $WM_RBUTTONUP] = "_WM_RBUTTONUP"
	$m["UC_WM_" & $WM_MOUSEMOVE] = "_WM_MOUSEMOVE"
	$m["UC_WM_" & $WM_SETFOCUS] = "_WM_SETFOCUS"
	$m["UC_WM_" & $WM_KEYDOWN] = "_WM_KEYDOWN"

	$m.State = 1
	$m.Hour = $iHour
	$m.Minute = $iMinute
	$m.HoverIndex = -1

	; Colors
	$m.BoxColor = 0xFFFFFF
	$m.ButtonColor = 0xEDEDED
	$m.TextColor = 0x000000
	$m.ArrowColor = 0x202020
	$m.BorderColor = 0xA8A8A8

	_WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)
	_UC_Properties($idDummy, $m)
	_UC_Properties(1, "UC_LastCreatedID", $idDummy)

	GUISwitch($hParent)
	Return $idDummy
EndFunc   ;==>_UC_HourMinute_Create

Func _UC_HourMinute_Draw($hWnd, ByRef $m)
	; 1. Setup Graphics Context
	Local $hFront = _GDIPlus_GraphicsCreateFromHWND($hWnd)
	Local $aSize = WinGetClientSize($hWnd)
	Local $iW = $aSize[0], $iH = $aSize[1]
	If $iW <= 0 Or $iH <= 0 Then
		_GDIPlus_GraphicsDispose($hFront)
		Return
	EndIf

	Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics($iW, $iH, $hFront)
	Local $hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)

	_GDIPlus_GraphicsSetSmoothingMode($hBack, 2)
	_GDIPlus_GraphicsSetPixelOffsetMode($hBack, 2)
	_GDIPlus_GraphicsSetTextRenderingHint($hBack, 3)
	_GDIPlus_GraphicsClear($hBack, "0xFF" & Hex(__UC_ParentColor($hWnd), 6))

	; 2. Initialize Local Resources
	Local $hBrushBox = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.BoxColor, 6))
	Local $hBrushBtn = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.ButtonColor, 6))
	Local $hBrushText = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.TextColor, 6))
	Local $hBrushArrow = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.ArrowColor, 6))
	Local $hPenBorder = _GDIPlus_PenCreate("0xFF" & Hex($m.BorderColor, 6), 1)
	Local $hPenBtn = _GDIPlus_PenCreate("0xFF" & Hex($m.BorderColor, 6), 1)

	Local $iHoverColor = ($m.ButtonColor < 0x888888 ? 0x80FFFFFF : 0x80000000)
;~ 	Local $iHoverColor  = (_UC_IsLightColor($m.ButtonColor) ? 0x80000000 : 0x80FFFFFF)

	Local $hPenBtnHover = _GDIPlus_PenCreate($iHoverColor, 1.5)

	Local $hFamily = _GDIPlus_FontFamilyCreate("Segoe UI")
	Local $fFontSize = Ceiling($iH * 0.50)
	If $fFontSize < 9 Then $fFontSize = 9
	Local $hFont = _GDIPlus_FontCreate($hFamily, $fFontSize, 0)
	Local $hFormat = _GDIPlus_StringFormatCreate()
	_GDIPlus_StringFormatSetAlign($hFormat, 1)
	_GDIPlus_StringFormatSetLineAlign($hFormat, 1)

	; 3. Drawing Logic
	Local $BTN_W = $iH / 2, $BTN_H = $iH / 2
	Local $BOX_X = $BTN_W, $BOX_W = $iW - ($BTN_W * 2)

	_GDIPlus_GraphicsFillRect($hBack, $BOX_X, 0, $BOX_W, $iH, $hBrushBox)
	_GDIPlus_GraphicsDrawRect($hBack, $BOX_X, 0, $BOX_W, $iH, $hPenBorder)

	Local $aRect[4][4] = [[0, 0, $BTN_W, $BTN_H], [0, $BTN_H, $BTN_W, $BTN_H], [$BOX_X + $BOX_W, 0, $BTN_W, $BTN_H], [$BOX_X + $BOX_W, $BTN_H, $BTN_W, $BTN_H]]

	For $i = 0 To 3
		Local $bIsHovered = ($m.State = 2 And $i = $m.HoverIndex)
		_GDIPlus_GraphicsFillRect($hBack, $aRect[$i][0], $aRect[$i][1], $aRect[$i][2], $aRect[$i][3], $hBrushBtn)
		_GDIPlus_GraphicsDrawRect($hBack, $aRect[$i][0], $aRect[$i][1], $aRect[$i][2], $aRect[$i][3], ($bIsHovered ? $hPenBtnHover : $hPenBtn))
		__UC_DrawArrow($hBack, $i, $aRect[$i][0], $aRect[$i][1], $aRect[$i][2], $aRect[$i][3], $hBrushArrow)
	Next

	_GDIPlus_GraphicsDrawStringEx($hBack, StringFormat("%02d:%02d", $m.Hour, $m.Minute), $hFont, _GDIPlus_RectFCreate($BOX_X, 0, $BOX_W, $iH), $hFormat, $hBrushText)
	_GDIPlus_GraphicsDrawImageRect($hFront, $hBitmap, 0, 0, $iW, $iH)

	; 4. Cleanup (Όλα τα resources απελευθερώνονται εδώ)
	_GDIPlus_FontDispose($hFont)
	_GDIPlus_FontFamilyDispose($hFamily)
	_GDIPlus_StringFormatDispose($hFormat)
	_GDIPlus_BrushDispose($hBrushBox)
	_GDIPlus_BrushDispose($hBrushBtn)
	_GDIPlus_BrushDispose($hBrushText)
	_GDIPlus_BrushDispose($hBrushArrow)
	_GDIPlus_PenDispose($hPenBorder)
	_GDIPlus_PenDispose($hPenBtn)
	_GDIPlus_PenDispose($hPenBtnHover)
	_GDIPlus_GraphicsDispose($hBack)
	_GDIPlus_BitmapDispose($hBitmap)
	_GDIPlus_GraphicsDispose($hFront)
EndFunc   ;==>_UC_HourMinute_Draw

Func _UC_HourMinute_HitTest($hWnd, $iX, $iY)
	Local $aSize = WinGetClientSize($hWnd)
	Local $iW = $aSize[0], $iH = $aSize[1]

	; Ίδια low-level γεωμετρία
	Local $BTN_W = $iH / 2
	Local $BTN_H = $iH / 2
	Local $BOX_W = $iW - ($BTN_W * 2)

	Local $aRect[4][4] = [ _
			[0, 0, $BTN_W, $BTN_H], _
			[0, $BTN_H, $BTN_W, $BTN_H], _
			[$BTN_W + $BOX_W, 0, $BTN_W, $BTN_H], _
			[$BTN_W + $BOX_W, $BTN_H, $BTN_W, $BTN_H]]

	For $i = 0 To 3
		If $iX >= $aRect[$i][0] And $iX <= $aRect[$i][0] + $aRect[$i][2] And _
				$iY >= $aRect[$i][1] And $iY <= $aRect[$i][1] + $aRect[$i][3] Then
			Return $i
		EndIf
	Next
	Return -1
EndFunc   ;==>_UC_HourMinute_HitTest

Func _UC_HourMinute_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	$m.State = 3 ; Pressed
	_UC_Properties($idDummy, $m)
	_WinAPI_SetCapture($hWnd)
EndFunc   ;==>_UC_HourMinute_WM_LBUTTONDOWN

Func _UC_HourMinute_WM_LBUTTONDBLCLK($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	; For now, a double click on a button should behave exactly like a fast single click.
	; So we just forward the parameters straight to the Down handler.
	Return _UC_HourMinute_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_HourMinute_WM_LBUTTONDBLCLK

Func _UC_HourMinute_WM_LBUTTONUP($idDummy, $hWnd, $iX, $iY)
	#forceref $idDummy, $iX, $iY
	Local $m = _UC_Properties($idDummy)

	If $m.State = 3 Then ; If is pressed
		_WinAPI_ReleaseCapture()

		; Area control
		If _UC_IsMouseOver($hWnd) Or ($iX = -1 And $iY = -1) Then

			Local $iHit = _UC_HourMinute_HitTest($hWnd, $iX, $iY)
			If $iHit = -1 Then Return

			Switch $iHit
				Case 0
					$m.Hour += 1
					If $m.Hour > 23 Then $m.Hour = 0

				Case 1
					$m.Hour -= 1
					If $m.Hour < 0 Then $m.Hour = 23

				Case 2
					$m.Minute += 1
					If $m.Minute > 59 Then $m.Minute = 0

				Case 3
					$m.Minute -= 1
					If $m.Minute < 0 Then $m.Minute = 59
			EndSwitch

			$m.State = 2 ; Hover
			_UC_Properties($idDummy, $m)
			GUICtrlSendToDummy($idDummy, StringFormat("%02d:%02d", $m.Hour, $m.Minute))
		Else
			$m.State = 1 ; Normal (Cancel execution)
			_UC_Properties($idDummy, $m)
		EndIf
	EndIf
EndFunc   ;==>_UC_HourMinute_WM_LBUTTONUP

Func _UC_HourMinute_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled

	; We do the "Test Drive" to see which part the mouse is targeting
	Local $iHit = _UC_HourMinute_HitTest($hWnd, $iX, $iY)

	; If the mouse moved to another button or went out of
	If $iHit <> $m.HoverIndex Then
		$m.HoverIndex = $iHit
		$m.State = ($iHit = -1 ? 1 : 2) ; 1 = Normal (off buttons), 2 = Hover (over a button)

		_UC_Properties($idDummy, $m)

	EndIf
EndFunc   ;==>_UC_HourMinute_WM_MOUSEMOVE

Func _UC_HourMinute_WM_SETFOCUS($idDummy, $hWnd, $iX, $iY)
    _UC_HourMinute_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
EndFunc

Func _UC_HourMinute_WM_KEYDOWN($idDummy, $hWnd, $iKeyCode, $aXY)
    Switch $iKeyCode
        Case $VK_SPACE
            _UC_HourMinute_WM_LBUTTONDOWN($idDummy, $hWnd, $aXY[0], $aXY[1])
            Sleep(50)
            _UC_HourMinute_WM_LBUTTONUP($idDummy, $hWnd, -1, -1)
    EndSwitch
EndFunc

#EndRegion ; ~~~~~~~~~~~~~ UC HourMinute ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
