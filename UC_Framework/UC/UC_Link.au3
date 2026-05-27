; UC_Link.au3
#include-once

#include "Frame\UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC Link   API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func _UC_Link_Create($hParent, $sText, $sURL, $iX, $iY, $iW, $iH, $iFontSize = 9, $hColor = 0x0094FF, $hHoverColor = 0xFF0000)
	GUISwitch($hParent)
	Local $idDummy = GUICtrlCreateDummy()
	Local $hChild = GUICreate("UC_Control_" & $idDummy, $iW, $iH, $iX, $iY, BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS, $WS_TABSTOP), $WS_EX_TRANSPARENT, $hParent)

	__UC_Framework_Init($hParent)

	GUISetCursor(_UC_Get(1, "Cursor_Hand"), $GUI_CURSOR_OVERRIDE, $hChild)

	Local $m[]
	$m.UC_Type = $UC_TYPE_LINK
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

	; Link Specific
	$m.Text = $sText               ; text to display
	$m.Value = $sURL               ; link (local or remote)
	$m.State = 1                   ; 0=Disable ; 1=Normal ; 2=Hover ; 3=Pressed
	$m.Color = $hColor             ; Text Color
	$m.HoverColor = $hHoverColor   ; hover Color
	$m.DisableTxtColor = 0x888888  ; Disabled Text Color
	$m.Font = "Segoe UI"
	$m.FontSize = $iFontSize
	$m.ShowTooltip = 0

	_WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)
	_UC_Properties($idDummy, $m)
	_UC_Properties(1, "UC_LastCreatedID", $idDummy)

	GUISwitch($hParent)
	Return $idDummy
EndFunc   ;==>_UC_Link_Create

Func _UC_Link_Draw($hWnd, ByRef $m)
	Local $aSize = WinGetClientSize($hWnd)
	Local $iW = $aSize[0], $iH = $aSize[1]
	Local $hBGColor = "0xFF" & Hex(__UC_ParentColor($hWnd), 6)

;~ 	GUISetCursor(_UC_Get(1, ($m.State == 0 ? "Cursor_Arrow" : "Cursor_Hand")), $GUI_CURSOR_OVERRIDE, $hWnd)

	Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hWnd)
	Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics($iW, $iH, $hGraphics)
	Local $hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)

	; Settings for Sharpening
	_GDIPlus_GraphicsSetSmoothingMode($hBack, 4)     ; HighQuality Antialiasing
	_GDIPlus_GraphicsSetPixelOffsetMode($hBack, 4)   ; HighQuality (Half-pixel offset)
	_GDIPlus_GraphicsSetTextRenderingHint($hBack, 5) ; TextRenderingHintClearTypeGridFit

	; Clear background with parent color
	_GDIPlus_GraphicsClear($hBack, $hBGColor)

	; Color and style selection based on State
	Local $iDrawCol
	Local $iStyle ; 0=Normal, 1=Bold, 2=Italic, 4=Underline, 8=Strikethrough

	Switch $m.State
		Case 0 ; Disabled
			$iDrawCol = $m.DisableColor
			$iStyle = 2
		Case 1 ; Normal
			$iDrawCol = $m.Color
			$iStyle = 0
		Case 2 ; Hover
			$iDrawCol = $m.HoverColor
			$iStyle = 4
		Case Else ; Normal (1)
			$iDrawCol = $m.Color
			$iStyle = 0
	EndSwitch

	Local $hBrushTxt = _GDIPlus_BrushCreateSolid("0xFF" & Hex($iDrawCol, 6))
	Local $hFamily = _GDIPlus_FontFamilyCreate($m.Font)
	Local $hFont = _GDIPlus_FontCreate($hFamily, $m.FontSize, $iStyle)
	Local $tLayout = _GDIPlus_RectFCreate(0, 0, $iW, $iH)
	Local $hFormat = _GDIPlus_StringFormatCreate()

	; Present to Screen
	_GDIPlus_GraphicsDrawStringEx($hBack, $m.Text, $hFont, $tLayout, $hFormat, $hBrushTxt)
	_GDIPlus_GraphicsDrawImage($hGraphics, $hBitmap, 0, 0)

	; Cleanup
	_GDIPlus_FontDispose($hFont)
	_GDIPlus_FontFamilyDispose($hFamily)
	_GDIPlus_BrushDispose($hBrushTxt)
	_GDIPlus_GraphicsDispose($hBack)
	_GDIPlus_BitmapDispose($hBitmap)
	_GDIPlus_GraphicsDispose($hGraphics)
EndFunc   ;==>_UC_Link_Draw

Func _UC_Link_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	$m.State = 3 ; is pressed
	_UC_Properties($idDummy, $m)
	_WinAPI_SetCapture($hWnd)
	_UC_ToolTip("")
EndFunc   ;==>_UC_Link_WM_LBUTTONDOWN

Func _UC_Link_WM_LBUTTONDBLCLK($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	; For now, a double click on a button should behave exactly like a fast single click.
	; So we just forward the parameters straight to the Down handler.
	Return _UC_Link_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_Link_WM_LBUTTONDBLCLK

Func _UC_Link_WM_LBUTTONUP($idDummy, $hWnd, $iX, $iY)
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
EndFunc   ;==>_UC_Link_WM_LBUTTONUP

Func _UC_Link_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	If $m.State = 1 Then ; If is normal
		$m.State = 2 ; Hover
		_UC_Properties($idDummy, $m)
		If $m.ShowTooltip And _UC_IsMouseOver($hWnd) Then _UC_ToolTip($m.Value)
	EndIf
EndFunc   ;==>_UC_Link_WM_MOUSEMOVE

Func _UC_Link_WM_SETFOCUS($idDummy, $hWnd, $iX, $iY)
	_UC_Link_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_Link_WM_SETFOCUS

Func _UC_Link_WM_KEYDOWN($idDummy, $hWnd, $iKeyCode, $aXY)
	Switch $iKeyCode
		Case $VK_SPACE
			_UC_Link_WM_LBUTTONDOWN($idDummy, $hWnd, $aXY[0], $aXY[1])
			Sleep(50)
			_UC_Link_WM_LBUTTONUP($idDummy, $hWnd, -1, -1)
	EndSwitch
EndFunc   ;==>_UC_Link_WM_KEYDOWN

#EndRegion ; ~~~~~~~~~~~~~ UC Link   API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
