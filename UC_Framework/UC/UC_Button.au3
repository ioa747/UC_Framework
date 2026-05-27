; UC_Button.au3
#include-once

#include "Frame\UC_Frame.au3"


#Region ; ~~~~~~~~~~~~~ UC Button API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func _UC_Button_Create($hParent, $sText, $iX, $iY, $iW, $iH, $iCorner = 0, $hBtnCol = 0xFFFFFF, $hTxtCol = 0x000000)
	GUISwitch($hParent)
	Local $idDummy = GUICtrlCreateDummy()
	Local $hChild = GUICreate("UC_Control_" & $idDummy, $iW, $iH, $iX, $iY, BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS, $WS_TABSTOP), $WS_EX_TRANSPARENT, $hParent)

	; Store the button text in the Dummy control
	GUICtrlSetData($idDummy, $sText)

	__UC_Framework_Init($hParent)

	GUISetCursor(_UC_Get(1, "Cursor_Hand"), $GUI_CURSOR_OVERRIDE, $hChild)

	; Calculate Hover and Pressed colors (Logic: BGR for WinAPI)
	Local $iBGR = _WinAPI_SwitchColor($hBtnCol)
	Local $iHov = _WinAPI_SwitchColor(_WinAPI_ColorAdjustLuma($iBGR, 20))  ; 20% Lighter
	Local $iPre = _WinAPI_SwitchColor(_WinAPI_ColorAdjustLuma($iBGR, -10)) ; 10% Darker

	Local $m[]

	; Universal Properties
	$m.UC_Type = $UC_TYPE_BUTTON
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

	; Button Specific Properties
	$m.State = 1 ; 0=Disable ; 1=Normal ; 2=Hover ; 3=Pressed
	$m.CornerRadius = $iCorner
	$m.BtnColor = $hBtnCol
	$m.HoverColor = $iHov
	$m.PressColor = $iPre
	$m.TextColor = $hTxtCol
	$m.DisableColor = 0xCCCCCC
	$m.DisableTxtColor = 0x888888
	$m.Text = $sText
	$m.Font = "Segoe UI"
	$m.FontSize = 9
	$m.FontStyle = 0  ; 0=Normal ; 1=Bold ; 2=Italic ; 4=Underline; 8=Strikethrough
	$m.FontHorAlg = 1 ; Horizontal aligned ; 0=left ; 1=Center ; 2=right
	$m.FontVerAlg = 1 ; Vertical aligned  ; 0=left ; 1=Center ; 2=right
	$m.ShowTooltip = 0
	$m.Tooltip = ""

	_WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)
	_UC_Properties($idDummy, $m)
	_UC_Properties(1, "UC_LastCreatedID", $idDummy)

	GUISwitch($hParent)
	Return $idDummy
EndFunc   ;==>_UC_Button_Create

Func _UC_Button_Draw($hWnd, ByRef $m)
	Local $aSize = WinGetClientSize($hWnd)
	Local $iW = $aSize[0], $iH = $aSize[1]
	If $iW <= 0 Or $iH <= 0 Then Return

	Local $iR = $m.CornerRadius
	Local $hBGColor = "0xFF" & Hex(__UC_ParentColor($hWnd), 6)
	Local $hDrawCol, $hTextCol = $m.TextColor

	; State-based color selection
	Switch $m.State
		Case 0 ; Disabled
			$hDrawCol = $m.DisableColor
			$hTextCol = $m.DisableTxtColor
		Case 2 ; Hover
			$hDrawCol = $m.HoverColor
		Case 3 ; Pressed
			$hDrawCol = $m.PressColor
		Case Else ; Normal (1)
			$hDrawCol = $m.BtnColor
	EndSwitch

	; Initialize GDI+ Context
	Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hWnd)
	Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics($iW, $iH, $hGraphics)
	Local $hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)

	; Settings for Sharpening
	_GDIPlus_GraphicsSetSmoothingMode($hBack, 4)     ; HighQuality Antialiasing
	_GDIPlus_GraphicsSetPixelOffsetMode($hBack, 4)   ; HighQuality (Half-pixel offset)
	_GDIPlus_GraphicsSetTextRenderingHint($hBack, 5) ; TextRenderingHintClearTypeGridFit

	; Clear background with parent color
	_GDIPlus_GraphicsClear($hBack, $hBGColor)

	; Create Background Brush
	Local $hBrushBg = _GDIPlus_BrushCreateSolid("0xFF" & Hex($hDrawCol, 6))

	; Apply "Golden Rule" for Pill Shape: Radius cannot exceed Height / 2
	Local $iMaxR = $iH / 2
	If $iR > $iMaxR Then $iR = $iMaxR

	; Draw Button Shape
	; We pass 0 for the Pen because the button currently uses only Fill
	__UC_DrawRoundedRect($hBack, 0, 0, $iW - 1, $iH - 1, $iR, $hBrushBg, 0)

	; Draw Text
	Local $hFamily = _GDIPlus_FontFamilyCreate($m.Font)
	Local $hFont = _GDIPlus_FontCreate($hFamily, $m.FontSize, $m.FontStyle)
	Local $hFormat = _GDIPlus_StringFormatCreate()

	_GDIPlus_StringFormatSetAlign($hFormat, $m.FontHorAlg)     ; Horizontal alignment
	_GDIPlus_StringFormatSetLineAlign($hFormat, $m.FontVerAlg) ; Vertical alignment

	Local $hBrushTxt = _GDIPlus_BrushCreateSolid("0xFF" & Hex($hTextCol, 6))
	Local $tLayout = _GDIPlus_RectFCreate(0, 0, $iW, $iH)
	_GDIPlus_GraphicsDrawStringEx($hBack, $m.Text, $hFont, $tLayout, $hFormat, $hBrushTxt)

	; Present to Screen (Double Buffering)
	_GDIPlus_GraphicsDrawImage($hGraphics, $hBitmap, 0, 0)

	; Cleanup Section
	_GDIPlus_BrushDispose($hBrushBg)
	_GDIPlus_BrushDispose($hBrushTxt)
	_GDIPlus_FontDispose($hFont)
	_GDIPlus_FontFamilyDispose($hFamily)
	_GDIPlus_StringFormatDispose($hFormat)
	_GDIPlus_GraphicsDispose($hBack)
	_GDIPlus_BitmapDispose($hBitmap)
	_GDIPlus_GraphicsDispose($hGraphics)
EndFunc   ;==>_UC_Button_Draw

Func _UC_Button_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	$m.State = 3 ; Pressed
	_UC_Properties($idDummy, $m)
	_WinAPI_SetCapture($hWnd)
EndFunc   ;==>_UC_Button_WM_LBUTTONDOWN

Func _UC_Button_WM_LBUTTONDBLCLK($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY

	; For now, a double click on a button should behave exactly like a fast single click.
	; So we just forward the parameters straight to the Down handler.
	Return _UC_Button_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_Button_WM_LBUTTONDBLCLK

Func _UC_Button_WM_LBUTTONUP($idDummy, $hWnd, $iX, $iY)
	#forceref $idDummy, $iX, $iY
	Local $m = _UC_Properties($idDummy)

	If $m.State = 3 Then ; If is pressed
		_WinAPI_ReleaseCapture()

		; Area control
		If _UC_IsMouseOver($hWnd) Or ($iX = -1 And $iY = -1) Then
			$m.State = 2 ; Hover
			_UC_Properties($idDummy, $m)
			GUICtrlSendToDummy($idDummy, $m.Text) ; Execution!
		Else
			$m.State = 1 ; Normal (Cancel execution)
			_UC_Properties($idDummy, $m)
		EndIf
	EndIf
EndFunc   ;==>_UC_Button_WM_LBUTTONUP

Func _UC_Button_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	If $m.State = 1 Then ; If is normal
		$m.State = 2 ; Hover
		_UC_Properties($idDummy, $m)
		If $m.ShowTooltip And _UC_IsMouseOver($hWnd) Then _UC_ToolTip($m.Tooltip)
	EndIf
EndFunc   ;==>_UC_Button_WM_MOUSEMOVE

Func _UC_Button_WM_SETFOCUS($idDummy, $hWnd, $iX, $iY)
	_UC_Button_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_Button_WM_SETFOCUS

Func _UC_Button_WM_KEYDOWN($idDummy, $hWnd, $iKeyCode, $aXY)
	Switch $iKeyCode
		Case $VK_SPACE
			_UC_Button_WM_LBUTTONDOWN($idDummy, $hWnd, $aXY[0], $aXY[1])
			Sleep(50)
			_UC_Button_WM_LBUTTONUP($idDummy, $hWnd, -1, -1)
	EndSwitch
EndFunc   ;==>_UC_Button_WM_KEYDOWN

#EndRegion ; ~~~~~~~~~~~~~ UC Button API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
