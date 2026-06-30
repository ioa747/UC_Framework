; UC_Frame_GDI.au3
#include-once

;~ #include <GDIPlus.au3>

#Region ; ~~~~~~~~~~~~~ UC_Framework GDI Tools ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; #FUNCTION# ====================================================================================================================
; Name...........: __UC_DrawRoundedRect
; Description....: Internal helper for drawing and/or filling rounded rectangles.
; Parameters.....: $hBrush - Handle to a brush to fill the rect. Set to 0 to skip filling.
;                  $hPen   - Handle to a pen to draw the border. Set to 0 to skip border.
; ===============================================================================================================================
Func __UC_DrawRoundedRect($hGraphics, $iX, $iY, $iW, $iH, $iR, $hBrush = 0, $hPen = 0)

	; If we have neither Brush nor Pen, there is no point in continuing
	If $hBrush = 0 And $hPen = 0 Then Return

	; Case for simple rectangle (Radius = 0)
	If $iR <= 0 Then
		If $hBrush <> 0 Then _GDIPlus_GraphicsFillRect($hGraphics, $iX, $iY, $iW, $iH, $hBrush)
		If $hPen <> 0 Then _GDIPlus_GraphicsDrawRect($hGraphics, $iX, $iY, $iW, $iH, $hPen)
		Return
	EndIf

	; Creating the Path
	Local $id = $iR * 2
	Local $hPath = _GDIPlus_PathCreate()

	_GDIPlus_PathAddArc($hPath, $iX, $iY, $id, $id, 180, 90)
	_GDIPlus_PathAddArc($hPath, $iX + $iW - $id, $iY, $id, $id, 270, 90)
	_GDIPlus_PathAddArc($hPath, $iX + $iW - $id, $iY + $iH - $id, $id, $id, 0, 90)
	_GDIPlus_PathAddArc($hPath, $iX, $iY + $iH - $id, $id, $id, 90, 90)
	_GDIPlus_PathCloseFigure($hPath)

	; First the filling (so as not to cover the outline)
	If $hBrush <> 0 Then _GDIPlus_GraphicsFillPath($hGraphics, $hPath, $hBrush)

	; After the outline
	If $hPen <> 0 Then _GDIPlus_GraphicsDrawPath($hGraphics, $hPath, $hPen)

	_GDIPlus_PathDispose($hPath)
EndFunc   ;==>__UC_DrawRoundedRect

Func __UC_DrawStar($hGraphics, $iCenterX, $iCenterY, $iOuterRadius, $hBrush, $hPen, $bFilled = True)
	Local $hPath = _GDIPlus_PathCreate()

	Local Const $DEG2RAD = ACos(-1) / 180
	Local $iPoints = 5
	Local $aPoints[11][2]

	Local $iInnerRadius = $iOuterRadius * 0.38

	For $i = 0 To $iPoints - 1
		;external Point
		Local $fAngle = ($i * 72 - 90) * $DEG2RAD
		$aPoints[$i * 2][0] = $iCenterX + Cos($fAngle) * $iOuterRadius
		$aPoints[$i * 2][1] = $iCenterY + Sin($fAngle) * $iOuterRadius

		; Internal Point
		$fAngle = ($i * 72 - 54) * $DEG2RAD
		$aPoints[$i * 2 + 1][0] = $iCenterX + Cos($fAngle) * $iInnerRadius
		$aPoints[$i * 2 + 1][1] = $iCenterY + Sin($fAngle) * $iInnerRadius
	Next

	; Close Path
	$aPoints[10][0] = $aPoints[0][0]
	$aPoints[10][1] = $aPoints[0][1]

	; Add Lines
	_GDIPlus_PathAddLine($hPath, $aPoints[0][0], $aPoints[0][1], $aPoints[1][0], $aPoints[1][1])
	For $i = 1 To 9
		_GDIPlus_PathAddLine($hPath, $aPoints[$i][0], $aPoints[$i][1], $aPoints[$i + 1][0], $aPoints[$i + 1][1])
	Next

	If $bFilled Then _GDIPlus_GraphicsFillPath($hGraphics, $hPath, $hBrush)

	_GDIPlus_GraphicsDrawPath($hGraphics, $hPath, $hPen)

	_GDIPlus_PathDispose($hPath)
EndFunc   ;==>__UC_DrawStar

Func __UC_DrawArrow($hGraphics, $iIndex, $x, $y, $w, $h, $hBrushArrow)

	Local $hPath = _GDIPlus_PathCreate()

	Local $marginX = $w * 0.22
	Local $marginY = $h * 0.26
	Local $cx = $x + $w / 2
	Local $topY, $bottomY

	If Mod($iIndex, 2) = 0 Then
		$topY = $y + $marginY
		$bottomY = $y + $h - $marginY
		_GDIPlus_PathAddLine($hPath, $cx, $topY, $x + $marginX, $bottomY)
		_GDIPlus_PathAddLine($hPath, $x + $marginX, $bottomY, $x + $w - $marginX, $bottomY)
		_GDIPlus_PathAddLine($hPath, $x + $w - $marginX, $bottomY, $cx, $topY)
	Else
		$topY = $y + $marginY
		$bottomY = $y + $h - $marginY
		_GDIPlus_PathAddLine($hPath, $cx, $bottomY, $x + $marginX, $topY)
		_GDIPlus_PathAddLine($hPath, $x + $marginX, $topY, $x + $w - $marginX, $topY)
		_GDIPlus_PathAddLine($hPath, $x + $w - $marginX, $topY, $cx, $bottomY)
	EndIf

	_GDIPlus_GraphicsFillPath($hGraphics, $hPath, $hBrushArrow)
	_GDIPlus_PathDispose($hPath)

EndFunc   ;==>__UC_DrawArrow
#EndRegion ; ~~~~~~~~~~~~~ Helper GDI Tools ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
