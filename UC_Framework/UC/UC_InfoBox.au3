; UC_Button.au3
#include-once

#include "Frame\UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC InfoBox API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func _UC_InfoBox_Create( _
		$hParent, $iX, $iY, $iW, $iH, _
		$sTitle, $sValue, _
		$sGlyph = "$", $sGlyphFont = "Segoe UI", $iGlyphSize = 34, _
		$iGlyphColor = 0x0F52BA, $iBorderColor = 0x0F52BA, _
		$iBackColor = 0x90D5FF, $iTitleColor = 0x0F52BA, _
		$iValueColor = 0x3A3A3A, _
		$iBorderLeft = 6, $iBorderRight = 0, $iBorderTop = 0, $iBorderBottom = 0)

	GUISwitch($hParent)
	Local $idDummy = GUICtrlCreateDummy()
	Local $hChild = GUICreate("UC_Control_" & $idDummy, $iW, $iH, $iX, $iY, _
			BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS), $WS_EX_TRANSPARENT, $hParent)

	__UC_Framework_Init($hParent)

	Local $m[]
	; Universal Properties
	$m.UC_Type = $UC_TYPE_INFOBOX
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

	; InfoBox Properties
	$m.Title = $sTitle
	$m.Value = $sValue
	$m.Glyph = $sGlyph
	$m.GlyphFont = $sGlyphFont
	$m.GlyphSize = $iGlyphSize
	$m.GlyphColor = $iGlyphColor
	$m.BorderColor = $iBorderColor
	$m.BackColor = $iBackColor
	$m.TitleColor = $iTitleColor
	$m.ValueColor = $iValueColor
	$m.Tooltip = ""
	$m.ShowTooltip = 0

	; Borders
	$m.BorderLeft = $iBorderLeft
	$m.BorderRight = $iBorderRight
	$m.BorderTop = $iBorderTop
	$m.BorderBottom = $iBorderBottom

	$m.State = 1

	_WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)
	_UC_Properties($idDummy, $m)
	_UC_Properties(1, "UC_LastCreatedID", $idDummy)

	GUISwitch($hParent)
	Return $idDummy
EndFunc   ;==>_UC_InfoBox_Create


Func _UC_InfoBox_Draw($hWnd, ByRef $m)
	Local $aSize = WinGetClientSize($hWnd)
	Local $iW = $aSize[0], $iH = $aSize[1]
	If $iW <= 0 Or $iH <= 0 Then Return

	Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hWnd)
	Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics($iW, $iH, $hGraphics)
	Local $hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)

	_GDIPlus_GraphicsSetSmoothingMode($hBack, 2)
	_GDIPlus_GraphicsSetTextRenderingHint($hBack, 4)

	; === Colors ===
	Local $hBrushBack = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.BackColor, 6))
	Local $hBrushBorder = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.BorderColor, 6))
	Local $hBrushTitle = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.TitleColor, 6))
	Local $hBrushValue = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.ValueColor, 6))
	Local $hBrushGlyph = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.GlyphColor, 6))

	; === Background ===
	_GDIPlus_GraphicsFillRect($hBack, 0, 0, $iW, $iH, $hBrushBack)


	; Left
	If $m.BorderLeft > 0 Then
		_GDIPlus_GraphicsFillRect($hBack, 0, 0, $m.BorderLeft, $iH, $hBrushBorder)
	EndIf
	; Right
	If $m.BorderRight > 0 Then
		_GDIPlus_GraphicsFillRect($hBack, $iW - $m.BorderRight, 0, $m.BorderRight, $iH, $hBrushBorder)
	EndIf
	; Top
	If $m.BorderTop > 0 Then
		_GDIPlus_GraphicsFillRect($hBack, 0, 0, $iW, $m.BorderTop, $hBrushBorder)
	EndIf
	; Bottom
	If $m.BorderBottom > 0 Then
		_GDIPlus_GraphicsFillRect($hBack, 0, $iH - $m.BorderBottom, $iW, $m.BorderBottom, $hBrushBorder)
	EndIf

	; ====================== SCALE ======================
	Local $bLarge = ($iW >= 300 And $iH >= 90)
	Local $bMedium = ($iW >= 180 And $iW < 300 And $iH >= 70)
	Local $bSmall = ($iW <= 170 Or $iH <= 62)

	Local $iLeftOffset = $m.BorderLeft > 0 ? $m.BorderLeft + 4 : 12

	; Glyph
	Local $iGlyphAreaW = $bLarge ? Int($iW * 0.27) : ($bMedium ? Int($iW * 0.305) : ($bSmall ? Int($iW * 0.37) : Int($iW * 0.32)))
	If $iGlyphAreaW < 52 Then $iGlyphAreaW = 52
	If $iGlyphAreaW > 115 Then $iGlyphAreaW = 115

	Local $iGlyphFontSize = $bLarge ? Int($iH * 0.63) : ($bMedium ? Int($iH * 0.57) : ($bSmall ? Int($iH * 0.44) : Int($iH * 0.53)))
	If $iH <= 58 Then $iGlyphFontSize = Int($iH * 0.42)
	If $iGlyphFontSize < 15 Then $iGlyphFontSize = 15
	If $iGlyphFontSize > 48 Then $iGlyphFontSize = 48

	If StringLen($m.Glyph) >= 4 Then $iGlyphFontSize = Int($iGlyphFontSize * 0.76)
	If StringLen($m.Glyph) >= 6 Then $iGlyphFontSize = Int($iGlyphFontSize * 0.72)

	; Title e Value
	Local $iTitleFontSize = $bLarge ? 11 : ($bMedium ? 9.5 : 8)
	Local $iValueFontSize = $bLarge ? 26 : ($bMedium ? 21 : ($iH >= 70 ? 17 : 14))

	Local $iTextMaxWidth = $iW - $iGlyphAreaW - $iLeftOffset - 18

	; ====================== DRAW ======================

	; GLYPH
	Local $hFamilyGlyph = _GDIPlus_FontFamilyCreate($m.GlyphFont)
	Local $hFontGlyph = _GDIPlus_FontCreate($hFamilyGlyph, $iGlyphFontSize, 1)
	Local $hFormatGlyph = _GDIPlus_StringFormatCreate()
	_GDIPlus_StringFormatSetAlign($hFormatGlyph, 1)
	_GDIPlus_StringFormatSetLineAlign($hFormatGlyph, 1)

	Local $tGlyphRect = _GDIPlus_RectFCreate($iW - $iGlyphAreaW - 8, 0, $iGlyphAreaW, $iH)
	_GDIPlus_GraphicsDrawStringEx($hBack, $m.Glyph, $hFontGlyph, $tGlyphRect, $hFormatGlyph, $hBrushGlyph)

	; TITLE
	Local $hFamilyText = _GDIPlus_FontFamilyCreate("Segoe UI")
	Local $hFontTitle = _GDIPlus_FontCreate($hFamilyText, $iTitleFontSize, 1)
	Local $hFormat = _GDIPlus_StringFormatCreate()
	Local $tTitleRect = _GDIPlus_RectFCreate($iLeftOffset, $bLarge ? 13 : 7, $iTextMaxWidth, 20)
	_GDIPlus_GraphicsDrawStringEx($hBack, $m.Title, $hFontTitle, $tTitleRect, $hFormat, $hBrushTitle)

	; VALUE
	Local $hFontValue = _GDIPlus_FontCreate($hFamilyText, $iValueFontSize, 0)
	Local $tValueRect = _GDIPlus_RectFCreate($iLeftOffset, $bLarge ? Int($iH * 0.41) : Int($iH * 0.38), $iTextMaxWidth, $iH * 0.55)
	_GDIPlus_GraphicsDrawStringEx($hBack, $m.Value, $hFontValue, $tValueRect, $hFormat, $hBrushValue)

	; Render
	_GDIPlus_GraphicsDrawImage($hGraphics, $hBitmap, 0, 0)

	; Cleanup
	_GDIPlus_BrushDispose($hBrushBack)
	_GDIPlus_BrushDispose($hBrushBorder)
	_GDIPlus_BrushDispose($hBrushTitle)
	_GDIPlus_BrushDispose($hBrushValue)
	_GDIPlus_BrushDispose($hBrushGlyph)

	_GDIPlus_FontDispose($hFontTitle)
	_GDIPlus_FontDispose($hFontValue)
	_GDIPlus_FontDispose($hFontGlyph)
	_GDIPlus_FontFamilyDispose($hFamilyText)
	_GDIPlus_FontFamilyDispose($hFamilyGlyph)

	_GDIPlus_StringFormatDispose($hFormat)
	_GDIPlus_StringFormatDispose($hFormatGlyph)

	_GDIPlus_GraphicsDispose($hBack)
	_GDIPlus_BitmapDispose($hBitmap)
	_GDIPlus_GraphicsDispose($hGraphics)
EndFunc   ;==>_UC_InfoBox_Draw

Func _UC_InfoBox_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	$m.State = 3 ; Pressed
	_UC_Properties($idDummy, $m)
	_WinAPI_SetCapture($hWnd)
EndFunc   ;==>_UC_InfoBox_WM_LBUTTONDOWN

Func _UC_InfoBox_WM_LBUTTONDBLCLK($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	; For now, a double click on a button should behave exactly like a fast single click.
	; So we just forward the parameters straight to the Down handler.
	Return _UC_InfoBox_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_InfoBox_WM_LBUTTONDBLCLK

Func _UC_InfoBox_WM_LBUTTONUP($idDummy, $hWnd, $iX, $iY)
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
EndFunc   ;==>_UC_InfoBox_WM_LBUTTONUP

Func _UC_InfoBox_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	If $m.State = 1 Then ; If is normal
		$m.State = 2 ; Hover
		_UC_Properties($idDummy, $m)
		If $m.ShowTooltip And _UC_IsMouseOver($hWnd) Then _UC_ToolTip($m.Tooltip)
	EndIf
EndFunc   ;==>_UC_InfoBox_WM_MOUSEMOVE

Func _UC_InfoBox_WM_SETFOCUS($idDummy, $hWnd, $iX, $iY)
    _UC_InfoBox_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
EndFunc

Func _UC_InfoBox_WM_KEYDOWN($idDummy, $hWnd, $iKeyCode, $aXY)
    Switch $iKeyCode
        Case $VK_SPACE
            _UC_InfoBox_WM_LBUTTONDOWN($idDummy, $hWnd, $aXY[0], $aXY[1])
            Sleep(50)
            _UC_InfoBox_WM_LBUTTONUP($idDummy, $hWnd, -1, -1)
    EndSwitch
EndFunc
#EndRegion ; ~~~~~~~~~~~~~ UC InfoBox API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
