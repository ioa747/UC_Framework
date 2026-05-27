; UC_Button.au3
#include-once

#include "Frame\UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC Radial Progress API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; #FUNCTION# ====================================================================================================================
; Name...........: _UC_RadialProgress_Create
; Description....: Creates a custom GDI+ Radial ProgressBar control.
; Syntax.........: _UC_RadialProgress_Create($hParent, $iX, $iY, $iSize [, ...])
; Author.........: Polar
; ===============================================================================================================================
Func _UC_RadialProgress_Create($hParent, $iX, $iY, $iSize, _
		$iMin = 0, $iMax = 100, $iValue = 0, $hProgressColor = 0x0078D7, $hTrackColor = 0x404040)

	GUISwitch($hParent)
	Local $idDummy = GUICtrlCreateDummy()
	Local $hChild = GUICreate("UC_Control_" & $idDummy, $iSize, $iSize, $iX, $iY, BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS), $WS_EX_TRANSPARENT, $hParent)

	__UC_Framework_Init($hParent)

	Local $m[]

	; Universal
	$m.UC_Type = $UC_TYPE_RADIALPROGRESS
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

	; Values
	$m.Min = $iMin
	$m.Max = $iMax
	$m.Value = $iValue

	; Appearance
	$m.ProgressColor = $hProgressColor
	$m.TrackColor = $hTrackColor

	; Ring
	$m.RingThickness = 10
	$m.StartAngle = -90
	$m.RoundCap = 1

	; Text
	$m.ShowPercent = 1
	$m.TextColor = 0xFFFFFF
	$m.Font = "Segoe UI"
	$m.FontSize = 18
	$m.FontStyle = 1

	; Optional glow
	$m.Glow = 0

	; Background center
	$m.CenterColor = 0x202020

	_WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)
	_UC_Properties($idDummy, $m)
	_UC_Properties(1, "UC_LastCreatedID", $idDummy)
	GUISwitch($hParent)
	Return $idDummy
EndFunc   ;==>_UC_RadialProgress_Create

Func _UC_RadialProgress_Draw($hWnd, ByRef $m)

	Local $aSize = WinGetClientSize($hWnd)
	Local $iW = $aSize[0]
	Local $iH = $aSize[1]

	If $iW <= 0 Or $iH <= 0 Then Return

	Local $hBGColor = "0xFF" & Hex(__UC_ParentColor($hWnd), 6)

	; GDI+ Initialization
	Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hWnd)
	Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics($iW, $iH, $hGraphics)
	Local $hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)

	; Quality
	_GDIPlus_GraphicsSetSmoothingMode($hBack, 4)
	_GDIPlus_GraphicsSetPixelOffsetMode($hBack, 4)
	_GDIPlus_GraphicsSetTextRenderingHint($hBack, 5)

	; Clear
	_GDIPlus_GraphicsClear($hBack, $hBGColor)

	; Percent
	Local $iRange = $m.Max - $m.Min
	If $iRange <= 0 Then $iRange = 1

	Local $fPercent = ($m.Value - $m.Min) / $iRange

	If $fPercent < 0 Then $fPercent = 0
	If $fPercent > 1 Then $fPercent = 1

	Local $fSweep = 360 * $fPercent

	; Geometry
	Local $iThickness = $m.RingThickness

	Local $iPad = Ceiling($iThickness / 2) + 2

	Local $iArcW = $iW - ($iPad * 2)
	Local $iArcH = $iH - ($iPad * 2)

	; Pens
	Local $hTrackPen = _GDIPlus_PenCreate( _
			"0xFF" & Hex($m.TrackColor, 6), _
			$iThickness)

	Local $hProgPen = _GDIPlus_PenCreate( _
			"0xFF" & Hex($m.ProgressColor, 6), _
			$iThickness)

	; Round caps
	If $m.RoundCap Then
		_GDIPlus_PenSetStartCap($hProgPen, 2)
		_GDIPlus_PenSetEndCap($hProgPen, 2)
	EndIf

	; Track
	_GDIPlus_GraphicsDrawArc( _
			$hBack, _
			$iPad, _
			$iPad, _
			$iArcW, _
			$iArcH, _
			0, _
			360, _
			$hTrackPen)

	; Glow
	If $m.Glow Then

		Local $hGlowPen = _GDIPlus_PenCreate( _
				"0x40" & Hex($m.ProgressColor, 6), _
				$iThickness + 8)

		If $m.RoundCap Then
			_GDIPlus_PenSetStartCap($hGlowPen, 2)
			_GDIPlus_PenSetEndCap($hGlowPen, 2)
		EndIf

		_GDIPlus_GraphicsDrawArc( _
				$hBack, _
				$iPad, _
				$iPad, _
				$iArcW, _
				$iArcH, _
				$m.StartAngle, _
				$fSweep, _
				$hGlowPen)

		_GDIPlus_PenDispose($hGlowPen)

	EndIf

	; Progress arc
	_GDIPlus_GraphicsDrawArc( _
			$hBack, _
			$iPad, _
			$iPad, _
			$iArcW, _
			$iArcH, _
			$m.StartAngle, _
			$fSweep, _
			$hProgPen)

	; Center fill
	If $m.CenterColor <> -1 Then

		Local $hCenterBrush = _GDIPlus_BrushCreateSolid( _
				"0xFF" & Hex($m.CenterColor, 6))

		Local $iCenter = $iThickness + 4

		_GDIPlus_GraphicsFillEllipse( _
				$hBack, _
				$iCenter, _
				$iCenter, _
				$iW - ($iCenter * 2), _
				$iH - ($iCenter * 2), _
				$hCenterBrush)

		_GDIPlus_BrushDispose($hCenterBrush)

	EndIf

	; Percentage text
	If $m.ShowPercent Then

		Local $sText = Int($fPercent * 100) & "%"

		Local $hFamily = _GDIPlus_FontFamilyCreate($m.Font)

		Local $hFont = _GDIPlus_FontCreate( _
				$hFamily, _
				$m.FontSize, _
				$m.FontStyle)

		Local $hBrushTxt = _GDIPlus_BrushCreateSolid( _
				"0xFF" & Hex($m.TextColor, 6))

		Local $hFormat = _GDIPlus_StringFormatCreate()

		_GDIPlus_StringFormatSetAlign($hFormat, 1)
		_GDIPlus_StringFormatSetLineAlign($hFormat, 1)

		Local $tLayout = _GDIPlus_RectFCreate(0, 0, $iW, $iH)

		_GDIPlus_GraphicsDrawStringEx( _
				$hBack, _
				$sText, _
				$hFont, _
				$tLayout, _
				$hFormat, _
				$hBrushTxt)

		_GDIPlus_StringFormatDispose($hFormat)
		_GDIPlus_BrushDispose($hBrushTxt)
		_GDIPlus_FontDispose($hFont)
		_GDIPlus_FontFamilyDispose($hFamily)

	EndIf

	; Present
	_GDIPlus_GraphicsDrawImageRect( _
			$hGraphics, _
			$hBitmap, _
			0, _
			0, _
			$iW, _
			$iH)

	; Cleanup
	_GDIPlus_PenDispose($hTrackPen)
	_GDIPlus_PenDispose($hProgPen)

	_GDIPlus_GraphicsDispose($hBack)
	_GDIPlus_BitmapDispose($hBitmap)
	_GDIPlus_GraphicsDispose($hGraphics)

EndFunc   ;==>_UC_RadialProgress_Draw

Func _UC_RadialProgress_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	$m.State = 3 ; Pressed
	_UC_Properties($idDummy, $m)
	_WinAPI_SetCapture($hWnd)
EndFunc   ;==>_UC_RadialProgress_WM_LBUTTONDOWN

Func _UC_RadialProgress_WM_LBUTTONDBLCLK($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	; For now, a double click on a button should behave exactly like a fast single click.
	; So we just forward the parameters straight to the Down handler.
	Return _UC_RadialProgress_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_RadialProgress_WM_LBUTTONDBLCLK

Func _UC_RadialProgress_WM_LBUTTONUP($idDummy, $hWnd, $iX, $iY)
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
EndFunc   ;==>_UC_RadialProgress_WM_LBUTTONUP

Func _UC_RadialProgress_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	If $m.State = 1 Then ; If is normal
		$m.State = 2 ; Hover
		_UC_Properties($idDummy, $m)
		If $m.ShowTooltip And _UC_IsMouseOver($hWnd) Then _UC_ToolTip($m.Tooltip)
	EndIf
EndFunc   ;==>_UC_RadialProgress_WM_MOUSEMOVE

#EndRegion ; ~~~~~~~~~~~~~ UC Radial Progress API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
