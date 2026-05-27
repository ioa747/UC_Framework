; UC_Button.au3
#include-once

#include "Frame\UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC ProgressBar API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; #FUNCTION# ====================================================================================================================
; Name...........: _UC_ProgressBar_Create
; Description....: Creates a custom GDI+ ProgressBar control.
; Syntax.........: _UC_ProgressBar_Create($hParent, $iX, $iY, $iW, $iH [, ...])
; Author.........: Polar
; ===============================================================================================================================
Func _UC_ProgressBar_Create($hParent, $iX, $iY, $iW, $iH, $iMin = 0, $iMax = 100, $iValue = 0, _
		$iType = 0, $iCornerRadius = 0, $hFillColor = 0x4CD964, $hTrackColor = 0xD1D1D1, $hBorderColor = 0xA0A0A0)

	GUISwitch($hParent)
	Local $idDummy = GUICtrlCreateDummy()
	Local $hChild = GUICreate("UC_Control_" & $idDummy, $iW, $iH, $iX, $iY, BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS), $WS_EX_TRANSPARENT, $hParent)

	__UC_Framework_Init($hParent)

	Local $m[]

	; Universal Properties
	$m.UC_Type = $UC_TYPE_PROGRESSBAR
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
	;$m["UC_WM_" & $WM_SETFOCUS] = "_WM_SETFOCUS"
	;$m["UC_WM_" & $WM_KEYDOWN] = "_WM_KEYDOWN"

	; ProgressBar Properties
	$m.State = 1
	$m.Min = $iMin
	$m.Max = $iMax
	$m.Value = $iValue
	$m.Type = $iType ; 0=Horizontal | 1=Vertical
	$m.CornerRadius = $iCornerRadius

	$m.FillColor = $hFillColor
	$m.TrackColor = $hTrackColor
	$m.BorderColor = $hBorderColor
	$m.ShowPercent = False
	$m.TextColor = 0x000000

	$m.Font = "Segoe UI"
	$m.FontSize = 9
	$m.FontStyle = 1

	_WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)
	_UC_Properties($idDummy, $m)
	_UC_Properties(1, "UC_LastCreatedID", $idDummy)
	GUISwitch($hParent)
	Return $idDummy
EndFunc   ;==>_UC_ProgressBar_Create

Func _UC_ProgressBar_Draw($hWnd, ByRef $m)
	Local $aSize = WinGetClientSize($hWnd)
	Local $iW = $aSize[0]
	Local $iH = $aSize[1]

	If $iW <= 0 Or $iH <= 0 Then Return

	Local $hBGColor = "0xFF" & Hex(__UC_ParentColor($hWnd), 6)

	; Clamp value
	If $m.Value < $m.Min Then $m.Value = $m.Min
	If $m.Value > $m.Max Then $m.Value = $m.Max

	; Calculate Percentage
	Local $iRange = ($m.Max - $m.Min)
	If $iRange <= 0 Then $iRange = 1
	Local $fPercent = ($m.Value - $m.Min) / $iRange

	; GDI+ Initialization
	Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hWnd)
	Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics($iW, $iH, $hGraphics)
	Local $hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)

	; Set High Quality Rendering
	_GDIPlus_GraphicsSetSmoothingMode($hBack, 4)
	_GDIPlus_GraphicsSetPixelOffsetMode($hBack, 4)
	_GDIPlus_GraphicsSetTextRenderingHint($hBack, 5)

	; Clear Background
	_GDIPlus_GraphicsClear($hBack, $hBGColor)

	; Create Resources
	Local $hBrushTrack = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.TrackColor, 6))
	Local $hBrushFill = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.FillColor, 6))
	Local $hBrushText = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.TextColor, 6))
	Local $hPenBorder = _GDIPlus_PenCreate("0xFF" & Hex($m.BorderColor, 6), 1)

	; Radius Calculation
	Local $iR = $m.CornerRadius
	Local $iMaxR = (($iH < $iW) ? $iH : $iW) / 2
	If $iR > $iMaxR Then $iR = $iMaxR

	; Draw Track (Background of the Progress Bar)
	__UC_DrawRoundedRect($hBack, 0, 0, $iW - 1, $iH - 1, $iR, $hBrushTrack, $hPenBorder)

	; Draw Fill (The actual progress)
	Local $iFillX, $iFillY, $iFillW, $iFillH

	If $m.Type = 0 Then ; Horizontal
		$iFillW = Int(($iW - 2) * $fPercent)
		If $iFillW > 0 Then
			; Fill only, no border for the inner bar
			__UC_DrawRoundedRect($hBack, 1, 1, $iFillW, $iH - 3, $iR, $hBrushFill, 0)
		EndIf
	Else ; Vertical
		$iFillH = Int(($iH - 2) * $fPercent)
		If $iFillH > 0 Then
			$iFillX = 1
			$iFillY = $iH - $iFillH - 1
			; Fill only, no border for the inner bar
			__UC_DrawRoundedRect($hBack, $iFillX, $iFillY, $iW - 3, $iFillH, $iR, $hBrushFill, 0)
		EndIf
	EndIf

	; Draw Percent Text (Optional)
	If $m.ShowPercent Then
		Local $iPercent = Int($fPercent * 100)
		Local $hFamily = _GDIPlus_FontFamilyCreate($m.Font)
		Local $hFont = _GDIPlus_FontCreate($hFamily, $m.FontSize, $m.FontStyle)
		Local $hFormat = _GDIPlus_StringFormatCreate()

		_GDIPlus_StringFormatSetAlign($hFormat, 1) ; Center
		_GDIPlus_StringFormatSetLineAlign($hFormat, 1) ; Center

		Local $tLayout = _GDIPlus_RectFCreate(0, 0, $iW, $iH)
		_GDIPlus_GraphicsDrawStringEx($hBack, $iPercent & "%", $hFont, $tLayout, $hFormat, $hBrushText)

		; Text Resources Cleanup
		_GDIPlus_StringFormatDispose($hFormat)
		_GDIPlus_FontDispose($hFont)
		_GDIPlus_FontFamilyDispose($hFamily)
	EndIf

	; Present to Screen
	_GDIPlus_GraphicsDrawImageRect($hGraphics, $hBitmap, 0, 0, $iW, $iH)

	; Final Cleanup
	_GDIPlus_PenDispose($hPenBorder)
	_GDIPlus_BrushDispose($hBrushTrack)
	_GDIPlus_BrushDispose($hBrushFill)
	_GDIPlus_BrushDispose($hBrushText)
	_GDIPlus_GraphicsDispose($hBack)
	_GDIPlus_BitmapDispose($hBitmap)
	_GDIPlus_GraphicsDispose($hGraphics)
EndFunc   ;==>_UC_ProgressBar_Draw

Func _UC_ProgressBar_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	$m.State = 3 ; Pressed
	_UC_Properties($idDummy, $m)
	_WinAPI_SetCapture($hWnd)
EndFunc   ;==>_UC_ProgressBar_WM_LBUTTONDOWN

Func _UC_ProgressBar_WM_LBUTTONDBLCLK($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	; For now, a double click on a button should behave exactly like a fast single click.
	; So we just forward the parameters straight to the Down handler.
	Return _UC_ProgressBar_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_ProgressBar_WM_LBUTTONDBLCLK

Func _UC_ProgressBar_WM_LBUTTONUP($idDummy, $hWnd, $iX, $iY)
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

Func _UC_ProgressBar_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	If $m.State = 1 Then ; If is normal
		$m.State = 2 ; Hover
		_UC_Properties($idDummy, $m)
		If $m.ShowTooltip And _UC_IsMouseOver($hWnd) Then _UC_ToolTip($m.Tooltip)
	EndIf
EndFunc   ;==>_UC_ProgressBar_WM_MOUSEMOVE

#EndRegion ; ~~~~~~~~~~~~~ UC ProgressBar API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
