; UC_Framework-main/UC/UC_Chart_Bar.au3
#include-once
#include "Frame\UC_Frame.au3"
#include <WinAPI.au3>

#Region ; ~~~~~~~~~~~~~ UC Bar Chart API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func _UC_Chart_Bar_Create($hParent, $iX, $iY, $iW, $iH, _
        $aData, $aLabels, _
        $sTitle = "", $sYTitle = "", $sXTitle = "", _
        $iPrimaryColor = 0x2563EB, $iGridColor = 0x000000)

    GUISwitch($hParent)
    Local $idDummy = GUICtrlCreateDummy()
    Local $hChild = GUICreate("UC_Chart_Bar_" & $idDummy, $iW, $iH, $iX, $iY, _
            BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS), $WS_EX_TRANSPARENT, $hParent)

    __UC_Framework_Init($hParent)

    Local $m[]
    $m.UC_Type = $UC_TYPE_CHART_BAR
    $m.UC_ControlID = $idDummy
    $m.UC_hWnd = $hChild
    $m.UC_hParent = $hParent

    $m["UC_WM_" & $WM_LBUTTONDOWN] = "_WM_LBUTTONDOWN"
    $m["UC_WM_" & $WM_LBUTTONDBLCLK] = "_WM_LBUTTONDBLCLK"
    $m["UC_WM_" & $WM_LBUTTONUP] = "_WM_LBUTTONUP"
    $m["UC_WM_" & $WM_MOUSEMOVE] = "_WM_MOUSEMOVE"
    $m["UC_WM_" & $WM_SETFOCUS] = "_WM_SETFOCUS"
    $m["UC_WM_" & $WM_KEYDOWN] = "_WM_KEYDOWN"

    $m.Data = $aData
    $m.Labels = $aLabels
    $m.Title = $sTitle
    $m.YTitle = $sYTitle
    $m.XTitle = $sXTitle
    $m.PrimaryColor = $iPrimaryColor
    $m.GridColor = $iGridColor
    $m.Mode = 0
    $m.State = 1
    $m.HoverIndex = -1
    $m.SetFocus = 1
	$m.BorderColor = $iGridColor
	$m.BorderSize = 1
	$m.BorderRadius = 8

    _WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)
    _UC_Properties($idDummy, $m)
    _UC_Properties(1, "UC_LastCreatedID", $idDummy)

    GUISwitch($hParent)
    Return $idDummy
EndFunc   ;==>_UC_Chart_Bar_Create

Func _UC_Chart_Bar_SetMode($idDummy, $iMode)

    Local $m = _UC_Properties($idDummy)

    $m.Mode = $iMode

    _UC_Properties($idDummy, $m)

    _WinAPI_InvalidateRect($m.UC_hWnd)

EndFunc   ;==>_UC_Chart_Bar_SetMode

Func _UC_Chart_Bar_UpdateFromValue($idDummy = Default, $iDelta = 1)

    If $idDummy = Default Then _
        $idDummy = _UC_Properties(1, "UC_ActiveControlID")

    Local $m = _UC_Properties($idDummy)

    $m.Data[0][0] += $iDelta

    If $m.Data[0][0] < 0 Then _
        $m.Data[0][0] = 0

    _UC_Properties($idDummy, $m)

	_WinAPI_InvalidateRect($m.UC_hWnd)

EndFunc   ;==>_UC_Chart_Bar_UpdateFromValue

Func _UC_Chart_Bar_Draw($hWnd, ByRef $m)

    If Not IsArray($m.Data) Then Return
    If UBound($m.Data, 0) <> 2 Then Return

    Local $aSize = WinGetClientSize($hWnd)
    If @error Then Return

    Local $iW = $aSize[0]
    Local $iH = $aSize[1]
	Local Const $BORDER_MARGIN = 2

    If $iW < 10 Or $iH < 10 Then Return

    Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hWnd)
    If $hGraphics = 0 Then Return

    Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics($iW, $iH, $hGraphics)

    If $hBitmap = 0 Then
        _GDIPlus_GraphicsDispose($hGraphics)
        Return
    EndIf

    Local $hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)

    _GDIPlus_GraphicsSetSmoothingMode($hBack, 2)

    Local $iBackColor = __UC_ParentColor($hWnd)
    _GDIPlus_GraphicsClear($hBack, "0xFF" & Hex($iBackColor, 6))

    Local $iBars = UBound($m.Data, 1)
    Local $iSeries = UBound($m.Data, 2)

    If $iBars = 0 Then Return

    ; ==========================================================
    ; Layout
    ; ==========================================================

    Local $iChartLeft = 120
    Local $iChartTop = 70
    Local $iChartRight = $iW - 25
	Local $iChartBottom = $iH - 85

    Local $iChartWidth = $iChartRight - $iChartLeft
    Local $iChartHeight = $iChartBottom - $iChartTop

    Local $fBarWidth = $iChartWidth / $iBars

    ; ==========================================================
    ; Max Value
    ; ==========================================================

	Local $fMax = 0
	Local $fMin = 0
	Local $fVal

	For $i = 0 To $iBars - 1

		If $m.Mode Then

			Local $fPos = 0
			Local $fNeg = 0

			For $j = 0 To $iSeries - 1

				$fVal = Number($m.Data[$i][$j])

				If $fVal >= 0 Then
					$fPos += $fVal
				Else
					$fNeg += $fVal
				EndIf

			Next

			If $fPos > $fMax Then $fMax = $fPos
			If $fNeg < $fMin Then $fMin = $fNeg

		Else

			For $j = 0 To $iSeries - 1

				$fVal = Number($m.Data[$i][$j])

				If $fVal > $fMax Then $fMax = $fVal
				If $fVal < $fMin Then $fMin = $fVal

			Next

		EndIf

	Next

	; ==========================================================
	; Scale
	; ==========================================================

	Local $fRange
	Local $iZeroY

	If $fMin < 0 Then

		Local $fAbsMax = Abs($fMax)

		If Abs($fMin) > $fAbsMax Then
			$fAbsMax = Abs($fMin)
		EndIf

		If $fAbsMax = 0 Then
			$fAbsMax = 1
		EndIf

		$fMax = $fAbsMax
		$fMin = -$fAbsMax

		$fRange = $fMax - $fMin

		; zero centralizado
		$iZeroY = $iChartTop + ($iChartHeight / 2)

	Else

		If $fMax <= 0 Then
			$fMax = 1
		EndIf

		$fMin = 0
		$fRange = $fMax

		; zero na base
		$iZeroY = $iChartBottom

	EndIf

    ; ==========================================================
    ; Colors
    ; ==========================================================

    Local $aSeriesColors[] = [ _
        0x2563EB, _
        0x10B981, _
        0xF59E0B, _
        0xEF4444, _
        0x8B5CF6, _
        0x06B6D4, _
        0xEC4899, _
        0x84CC16 _
    ]

    ; ==========================================================
    ; Fonts
    ; ==========================================================

    Local $hFamily = _GDIPlus_FontFamilyCreate("Segoe UI")

    Local $hFontTitle = _GDIPlus_FontCreate($hFamily, 16)
    Local $hFontAxis  = _GDIPlus_FontCreate($hFamily, 9)
    Local $hFontValue = _GDIPlus_FontCreate($hFamily, 8)
    Local $hBrushText = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.GridColor, 6))
    Local $hPenGrid   = _GDIPlus_PenCreate("0x30" & Hex($m.GridColor, 6), 1)
    Local $hPenAxis   = _GDIPlus_PenCreate("0xFF" & Hex($m.GridColor, 6), 2)
	Local $hPenBorder = _GDIPlus_PenCreate("0xFF" & Hex($m.GridColor, 6), 1)
	Local $hFormat    = _GDIPlus_StringFormatCreate()

    ; ==========================================================
    ; Border
    ; ==========================================================

	_GDIPlus_GraphicsDrawRect( _
    $hBack, _
    $BORDER_MARGIN, _
    $BORDER_MARGIN, _
    $iW - ($BORDER_MARGIN * 2) - 1, _
    $iH - ($BORDER_MARGIN * 2) - 1, _
    $hPenBorder)

	_GDIPlus_StringFormatSetAlign($hFormat, 1)

    ; ==========================================================
    ; Title
    ; ==========================================================

    If $m.Title <> "" Then

        Local $tTitle = _GDIPlus_RectFCreate(0, 8, $iW, 40)
        _GDIPlus_GraphicsDrawStringEx($hBack, $m.Title, $hFontTitle, $tTitle, $hFormat, $hBrushText)

    EndIf

    ; ==========================================================
	; Y Title
	; ==========================================================

	If $m.YTitle <> "" Then

		Local $hState = _GDIPlus_GraphicsSave($hBack)

		; Point where the text will be next to the Y-axis.
		Local $iScaleLeft = $iChartLeft - 70
		Local $iRotX = $iScaleLeft - 18
		Local $iRotY = $iChartTop + ($iChartHeight / 2)

		; Move the origin to the desired center.
		_GDIPlus_GraphicsTranslateTransform($hBack, $iRotX, $iRotY)

		; Counterclockwise rotation
		_GDIPlus_GraphicsRotateTransform($hBack, -90)
		Local $tYTitle = _GDIPlus_RectFCreate(-($iChartHeight / 2), -15, $iChartHeight, 30)
		_GDIPlus_GraphicsDrawStringEx($hBack, $m.YTitle, $hFontAxis, $tYTitle, $hFormat, $hBrushText)

		; Restores transformations
		_GDIPlus_GraphicsRestore($hBack, $hState)

	EndIf

	; ==========================================================
	; Grid + Y Scale
	; ==========================================================

	Local Const $iTicks = 5

	For $i = 0 To $iTicks

		Local $fScale

		If $fMin < 0 Then
			$fScale = $fMax - (($fRange / $iTicks) * $i)
		Else
			$fScale = $fMax - (($fMax / $iTicks) * $i)
		EndIf

		; converte valor em posição Y

		Local $y = $iChartBottom - _
			((($fScale - $fMin) / $fRange) * $iChartHeight)

		If Abs($fScale) < 0.0001 Then _
			$fScale = 0

		_GDIPlus_GraphicsDrawLine( _
			$hBack, _
			$iChartLeft, _
			$y, _
			$iChartRight, _
			$y, _
			$hPenGrid)

		Local $tScale = _GDIPlus_RectFCreate( _
			$iChartLeft - 70, _
			$y - 8, _
			55, _
			16)

		_GDIPlus_GraphicsDrawStringEx( _
			$hBack, _
			String(Round($fScale, 1)), _
			$hFontAxis, _
			$tScale, _
			$hFormat, _
			$hBrushText)

	Next

	; ==========================================================
	; Zero Line
	; ==========================================================

	If $fMin < 0 And $fMax > 0 Then

		Local $hPenZero = _GDIPlus_PenCreate( _
			"0x80" & Hex($m.GridColor, 6), _
			1)

		_GDIPlus_GraphicsDrawLine( _
			$hBack, _
			$iChartLeft, _
			$iZeroY, _
			$iChartRight, _
			$iZeroY, _
			$hPenZero)

		_GDIPlus_PenDispose($hPenZero)

	EndIf

    ; ==========================================================
	; Axis
	; ==========================================================

	; Axis Y

	_GDIPlus_GraphicsDrawLine($hBack, $iChartLeft, $iChartTop, $iChartLeft, $iChartBottom, $hPenAxis)

	; Axis X

	If $fMin < 0 And $fMax > 0 Then
		; both
		_GDIPlus_GraphicsDrawLine($hBack, $iChartLeft, $iZeroY, $iChartRight, $iZeroY, $hPenAxis)
	ElseIf $fMin >= 0 Then
		; only positives
		_GDIPlus_GraphicsDrawLine($hBack, $iChartLeft, $iChartBottom, $iChartRight, $iChartBottom, $hPenAxis)
	Else
		; only negatives
		_GDIPlus_GraphicsDrawLine($hBack, $iChartLeft, $iChartTop, $iChartRight, $iChartTop, $hPenAxis)
	EndIf

    ; ==========================================================
	; Bars
	; ==========================================================

	Local $hBar, $iColor, $hBrush

	For $i = 0 To $iBars - 1

		Local $x = $iChartLeft + ($i * $fBarWidth)

		If $m.Mode Then

			; --------------------------------------------------
			; STACKED
			; --------------------------------------------------

			Local $iAccumPos = 0
			Local $iAccumNeg = 0
			Local $fTotalPos = 0
			Local $fTotalNeg = 0
			For $j = 0 To $iSeries - 1

				$fVal = Number($m.Data[$i][$j])

				If $fVal = 0 Then ContinueLoop

				$hBar = 0

				If $fMin < 0 And $fMax > 0 Then
					$hBar = (Abs($fVal) / $fMax) * ($iChartHeight / 2)
				ElseIf $fMin >= 0 Then
					$hBar = ($fVal / $fMax) * $iChartHeight
				Else
					$hBar = (Abs($fVal) / Abs($fMin)) * $iChartHeight
				EndIf

				$iColor = $aSeriesColors[Mod($j, UBound($aSeriesColors))]

				$hBrush = _GDIPlus_BrushCreateSolid("0xFF" & Hex($iColor, 6))

				If $fVal > 0 Then
					_GDIPlus_GraphicsFillRect($hBack, $x + 2, $iZeroY - $iAccumPos - $hBar, $fBarWidth - 6, $hBar, $hBrush)
					$iAccumPos += $hBar
				Else
					_GDIPlus_GraphicsFillRect($hBack, $x + 2, $iZeroY + $iAccumNeg, $fBarWidth - 6, $hBar, $hBrush)
					$iAccumNeg += $hBar
				EndIf

				If $fVal > 0 Then
					$fTotalPos += $fVal
				Else
					$fTotalNeg += $fVal
				EndIf

				_GDIPlus_BrushDispose($hBrush)

			Next

			Local $fTotal = $fTotalPos + $fTotalNeg

			; ==================================================
			; TOTAL STACKED
			; ==================================================

			If $fTotal <> 0 Then

				Local $tTotal

				If $fTotal > 0 Then

					$tTotal = _GDIPlus_RectFCreate($x, $iZeroY - $iAccumPos - 18, $fBarWidth, 16)
				Else

					$tTotal = _GDIPlus_RectFCreate( $x, $iZeroY + $iAccumNeg + 2, $fBarWidth, 16)
				EndIf

				_GDIPlus_GraphicsDrawStringEx($hBack, String(Round($fTotal, 1)), $hFontValue, $tTotal, $hFormat, $hBrushText)

			EndIf


		Else

			; --------------------------------------------------
			; GROUPED
			; --------------------------------------------------

			Local $fGroupWidth = ($fBarWidth - 6) / $iSeries

			For $j = 0 To $iSeries - 1

				$fVal = Number($m.Data[$i][$j])

				If $fVal = 0 Then ContinueLoop

				$hBar = 0

				If $fMin < 0 And $fMax > 0 Then
					$hBar = (Abs($fVal) / $fMax) * ($iChartHeight / 2)
				ElseIf $fMin >= 0 Then
					$hBar = ($fVal / $fMax) * $iChartHeight
				Else
					$hBar = (Abs($fVal) / Abs($fMin)) * $iChartHeight
				EndIf

				$iColor = $aSeriesColors[Mod($j, UBound($aSeriesColors))]

				$hBrush = _GDIPlus_BrushCreateSolid("0xFF" & Hex($iColor, 6))

				Local $iBarX = $x + 2 + ($j * $fGroupWidth)

				If $fVal > 0 Then
					_GDIPlus_GraphicsFillRect( $hBack, $iBarX, $iZeroY - $hBar, $fGroupWidth - 2, $hBar, $hBrush)
				Else
					_GDIPlus_GraphicsFillRect( $hBack, $iBarX, $iZeroY, $fGroupWidth - 2, $hBar, $hBrush)
				EndIf

				Local $tValue

				If $fVal > 0 Then
					$tValue = _GDIPlus_RectFCreate($iBarX, $iZeroY - $hBar - 16, $fGroupWidth, 14)
				Else
					$tValue = _GDIPlus_RectFCreate($iBarX, $iZeroY + $hBar + 2, $fGroupWidth, 14)
				EndIf

				_GDIPlus_GraphicsDrawStringEx($hBack, String(Round($fVal, 1)), $hFontValue, $tValue, $hFormat, $hBrushText)

				_GDIPlus_BrushDispose($hBrush)

			Next

		EndIf

	Next

    ; ==========================================================
    ; X Labels
    ; ==========================================================

    If IsArray($m.Labels) Then

        For $i = 0 To $iBars - 1

            If $i >= UBound($m.Labels) Then ExitLoop

            Local $tLabel = _GDIPlus_RectFCreate($iChartLeft + ($i * $fBarWidth), $iChartBottom + 8, $fBarWidth, 22)

			_GDIPlus_GraphicsDrawStringEx($hBack, String($m.Labels[$i]), $hFontAxis, $tLabel, $hFormat, $hBrushText)

        Next

    EndIf

    ; ==========================================================
    ; X Title
    ; ==========================================================

    If $m.XTitle <> "" Then

        Local $tXTitle = _GDIPlus_RectFCreate(0, $iH - 28, $iW, 20)
        _GDIPlus_GraphicsDrawStringEx($hBack, $m.XTitle, $hFontAxis, $tXTitle, $hFormat, $hBrushText)

    EndIf

    ; ==========================================================
    ; Render
    ; ==========================================================

    _GDIPlus_GraphicsDrawImageRect($hGraphics, $hBitmap, 0, 0, $iW, $iH)

    ; ==========================================================
    ; Cleanup
    ; ==========================================================

    _GDIPlus_StringFormatDispose($hFormat)
	_GDIPlus_PenDispose($hPenBorder)
    _GDIPlus_PenDispose($hPenAxis)
    _GDIPlus_PenDispose($hPenGrid)

    _GDIPlus_BrushDispose($hBrushText)

    _GDIPlus_FontDispose($hFontValue)
    _GDIPlus_FontDispose($hFontAxis)
    _GDIPlus_FontDispose($hFontTitle)

    _GDIPlus_FontFamilyDispose($hFamily)

    _GDIPlus_GraphicsDispose($hBack)
    _GDIPlus_BitmapDispose($hBitmap)
    _GDIPlus_GraphicsDispose($hGraphics)

EndFunc   ;==>_UC_Chart_Bar_Draw

Func _UC_Chart_Bar_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
    #forceref $hWnd, $iX, $iY
    Local $m = _UC_Properties($idDummy)
    If $m.State = 0 Then Return
    $m.State = 3
    _UC_Properties($idDummy, $m)
    _WinAPI_SetCapture($hWnd)
EndFunc   ;==>_UC_Chart_Bar_WM_LBUTTONDOWN

Func _UC_Chart_Bar_WM_LBUTTONDBLCLK($idDummy, $hWnd, $iX, $iY)
    Return _UC_Chart_Bar_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_Chart_Bar_WM_LBUTTONDBLCLK

Func _UC_Chart_Bar_WM_LBUTTONUP($idDummy, $hWnd, $iX, $iY)
    #forceref $idDummy, $iX, $iY
    Local $m = _UC_Properties($idDummy)
    If $m.State = 3 Then
        _WinAPI_ReleaseCapture()
        If _UC_IsMouseOver($hWnd) Or ($iX = -1 And $iY = -1) Then
            $m.State = 2
            _UC_Properties($idDummy, $m)
            GUICtrlSendToDummy($idDummy, $m.UC_ControlID)
        Else
            $m.State = 1
            _UC_Properties($idDummy, $m)
        EndIf
    EndIf
EndFunc   ;==>_UC_Chart_Bar_WM_LBUTTONUP

Func _UC_Chart_Bar_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)

    #forceref $hWnd, $iX, $iY

    Local $m = _UC_Properties($idDummy)

    If $m.State = 0 Then Return

    Local $aSize = WinGetClientSize($hWnd)

    Local $iNumBars = UBound($m.Data, 1)

    Local $fBarWidth = 0

    If $iNumBars > 0 Then
        $fBarWidth = ($aSize[0] - 80) / $iNumBars
    EndIf

    Local $iBarIndex = -1

    If $fBarWidth > 0 Then
        $iBarIndex = Int(($iX - 40) / $fBarWidth)
    EndIf

    If $iBarIndex < 0 Or $iBarIndex >= $iNumBars Then
        $iBarIndex = -1
    EndIf

    If $iBarIndex <> $m.HoverIndex Then

        $m.HoverIndex = $iBarIndex

        If $iBarIndex = -1 Then
            $m.State = 1
        Else
            $m.State = 2
        EndIf

        _UC_Properties($idDummy, $m)

    EndIf

EndFunc   ;==>_UC_Chart_Bar_WM_MOUSEMOVE

Func _UC_Chart_Bar_WM_SETFOCUS($idDummy, $hWnd, $iX, $iY)
    _UC_Chart_Bar_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
EndFunc

Func _UC_Chart_Bar_WM_KEYDOWN($idDummy, $hWnd, $iKeyCode, $aXY)
    Switch $iKeyCode
        Case $VK_ADD
            _UC_Chart_Bar_UpdateFromValue($idDummy, 1)
        Case $VK_SUBTRACT
            _UC_Chart_Bar_UpdateFromValue($idDummy, -1)
        Case $VK_SPACE
            _UC_Chart_Bar_WM_LBUTTONDOWN($idDummy, $hWnd, $aXY[0], $aXY[1])
            Sleep(50)
            _UC_Chart_Bar_WM_LBUTTONUP($idDummy, $hWnd, -1, -1)
    EndSwitch
EndFunc   ;==>_UC_Chart_Bar_WM_KEYDOWN
#EndRegion ; ~~~~~~~~~~~~~ UC Bar Chart API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~