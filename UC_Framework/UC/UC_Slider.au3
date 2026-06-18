#include-once ; UC_Slider.au3

#include "Frame\UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC Slider API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func _UC_Slider_Create($hParent, $iX, $iY, $iW, $iH, $iMin = 0, $iMax = 100, $iValue = 0, $iType = 0, _
		$hCol = 0x4CD964, $hTrackCol = 0xD1D1D1, $hThumbCol = Default, $iTrackSize = 4)

	GUISwitch($hParent)
	Local $idDummy = GUICtrlCreateDummy()
	Local $hChild = GUICreate("UC_Control_" & $idDummy, $iW, $iH, $iX, $iY, BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS, $WS_TABSTOP), $WS_EX_TRANSPARENT, $hParent)

	__UC_Framework_Init($hParent)

	GUISetCursor(_UC_Get(1, "Cursor_Hand"), $GUI_CURSOR_OVERRIDE, $hChild)

	Local $m[], $iShowTooltip = 0, $iThumbType = 0

	; Universal Properties
	$m.UC_Type = $UC_TYPE_SLIDER
	$m.UC_ControlID = $idDummy
	$m.UC_hWnd = $hChild
	$m.UC_hParent = $hParent
	$m.UC_Width = $iW
	$m.UC_Height = $iH

	; Registered Event Handlers
	$m["UC_WM_" & $WM_LBUTTONDOWN] = "_WM_LBUTTONDOWN"
	$m["UC_WM_" & $WM_LBUTTONDBLCLK] = "_WM_LBUTTONDBLCLK"
	$m["UC_WM_" & $WM_LBUTTONUP] = "_WM_LBUTTONUP"
;~ 	$m["UC_WM_" & $WM_RBUTTONDOWN] = "_WM_RBUTTONDOWN"
;~ 	$m["UC_WM_" & $WM_RBUTTONUP] = "_WM_RBUTTONUP"
	$m["UC_WM_" & $WM_MOUSEMOVE] = "_WM_MOUSEMOVE"
	$m["UC_WM_" & $WM_SETFOCUS] = "_WM_SETFOCUS"
;~ 	$m["UC_WM_" & $WM_KEYDOWN] = "_WM_KEYDOWN"

	; Toggle Specific Properties
	$m.State = 1                    ; 0=Disable ; 1=Normal ; 2=Hover ; 3=Pressed
	$m.IsDragging = 0               ; Is now Dragging
	$m.DragOffset = 0               ; DragOffset property
	$m.Min = $iMin                  ; Min Value
	$m.Max = $iMax                  ; Max Value
	$m.Value = $iValue              ; curent Value
	$m.Type = $iType                ; 0=Horizontal; 1=Vertical
	$m.ThumbType = $iThumbType      ; 0=Round; 1=Rectangular
	$m.ShowTooltip = $iShowTooltip  ; show Tooltip while dragging
	$m.Color = $hCol                ; Color
	$m.TrackColor = $hTrackCol      ; TrackColor
	$m.ThumbColor = $hThumbCol      ; ThumbColor
	$m.TrackSize = $iTrackSize      ; Size of Color line

	_WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)
	_UC_Properties($idDummy, $m)
	_UC_Properties(1, "UC_LastCreatedID", $idDummy)

	GUISwitch($hParent)
	Return $idDummy
EndFunc   ;==>_UC_Slider_Create

Func _UC_Slider_Draw($hWnd, ByRef $m)

	Local $mTheme = _UC_Themes("Active")
	Local $hThumbCol = ($m.ThumbColor = Default ? $mTheme.Surface_Face : $m.ThumbColor)
	Local $iW = $m.UC_Width, $iH = $m.UC_Height
	Local $hBGColor = "0xFF" & Hex(__UC_ParentColor($hWnd), 6)
	Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hWnd)

	; Buffer Setup
	Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics($iW, $iH, $hGraphics)
	Local $hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)

	; Settings for Sharpening
	_GDIPlus_GraphicsSetSmoothingMode($hBack, 4)     ; HighQuality Antialiasing
	_GDIPlus_GraphicsSetPixelOffsetMode($hBack, 4)   ; HighQuality (Half-pixel offset)

	; Clear background
	_GDIPlus_GraphicsClear($hBack, $hBGColor)

	; Percentage calculation
	Local $iRange = $m.Max - $m.Min
	If $iRange <= 0 Then $iRange = 1
	Local $fPercent = ($m.Value - $m.Min) / $iRange

	; Brushes & Pens
	Local $hBrushTrack = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.TrackColor, 6))
	Local $hBrushFill = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.Color, 6))
	Local $hBrushThumb = _GDIPlus_BrushCreateSolid("0xFF" & Hex($hThumbCol, 6))
	Local $hPenThumbBorder = _GDIPlus_PenCreate("0xFF" & Hex($mTheme.Surface_Border, 6), 1)
	Local $hPenHotTrack = _GDIPlus_PenCreate("0x80" & Hex($mTheme.Surface_Border, 6), 3)

	Local $iThumbSizeW, $iThumbSizeH, $iR, $iTrackR

	If $m.Type = 0 Then ; HORIZONTAL

		; Define Thumb Dimensions
		$iThumbSizeH = $iH - 4
		$iThumbSizeW = ($m.ThumbType = 0 ? $iThumbSizeH : $iThumbSizeH / 2)
		$iR = ($m.ThumbType = 0 ? $iThumbSizeW / 2 : 0) ; Round or Rect Thumb
		$iTrackR = $m.TrackSize / 2 ; Rounded track ends

		Local $iXPos = (($iW - $iThumbSizeW - 1) * $fPercent)
		Local $iTrackY = ($iH - $m.TrackSize) / 2

		; Draw Track Background
		__UC_DrawRoundedRect($hBack, ($iThumbSizeW / 4), $iTrackY, $iW - ($iThumbSizeW / 2), $m.TrackSize, $iTrackR, $hBrushTrack, 0)

		; Draw Track Fill
		__UC_DrawRoundedRect($hBack, ($iThumbSizeW / 4), $iTrackY, $iXPos + ($iThumbSizeW / 2), $m.TrackSize, $iTrackR, $hBrushFill, 0)

		; Draw Thumb (With HotTrack Pen if hovered)
		__UC_DrawRoundedRect($hBack, $iXPos, 2, $iThumbSizeW, $iThumbSizeH, $iR, $hBrushThumb, ($m.State = 2 ? $hPenHotTrack : $hPenThumbBorder))

	Else ; VERTICAL

		; Define Thumb Dimensions
		$iThumbSizeW = $iW - 4
		$iThumbSizeH = ($m.ThumbType = 0 ? $iThumbSizeW : $iThumbSizeW / 2)
		$iR = ($m.ThumbType = 0 ? $iThumbSizeH / 2 : 0) ; Round or Rect Thumb
		$iTrackR = $m.TrackSize / 2

		Local $iYPos = ($iH - $iThumbSizeH - 1) - (($iH - $iThumbSizeH - 2) * $fPercent)
		Local $iTrackX = ($iW - $m.TrackSize) / 2

		; Draw Track Background
		__UC_DrawRoundedRect($hBack, $iTrackX, ($iThumbSizeH / 4), $m.TrackSize, $iH - ($iThumbSizeH / 2), $iTrackR, $hBrushTrack, 0)

		; Draw Track Fill
		__UC_DrawRoundedRect($hBack, $iTrackX, $iYPos + ($iThumbSizeH / 4), $m.TrackSize, $iH - $iYPos - ($iThumbSizeH / 2), $iTrackR, $hBrushFill, 0)

		; Draw Thumb (With HotTrack Pen if hovered)
		__UC_DrawRoundedRect($hBack, 2, $iYPos, $iThumbSizeW, $iThumbSizeH, $iR, $hBrushThumb, ($m.State = 2 ? $hPenHotTrack : $hPenThumbBorder))

	EndIf

	; Present to Screen
	_GDIPlus_GraphicsDrawImageRect($hGraphics, $hBitmap, 0, 0, $iW, $iH)

	; Cleanup
	_GDIPlus_PenDispose($hPenHotTrack)
	_GDIPlus_PenDispose($hPenThumbBorder)
	_GDIPlus_BrushDispose($hBrushTrack)
	_GDIPlus_BrushDispose($hBrushFill)
	_GDIPlus_BrushDispose($hBrushThumb)
	_GDIPlus_GraphicsDispose($hBack)
	_GDIPlus_BitmapDispose($hBitmap)
	_GDIPlus_GraphicsDispose($hGraphics)
EndFunc   ;==>_UC_Slider_Draw

Func _UC_Slider_UpdateFromMouse($hWnd, ByRef $m, $iX, $iY)
	Local $aSize = WinGetClientSize($hWnd)

	; Fix for negative values (when mouse moves left/up)
	; Windows sends 16-bit signed values in lParam
	If $iX > 32767 Then $iX -= 65536
	If $iY > 32767 Then $iY -= 65536

	; Calculate the offset to center the thumb on the mouse position
	Local $iThumbSize, $iAvailableTrack, $fPercent = 0

	If $m.Type = 0 Then ; HORIZONTAL
		; The thumb starts at 0 and reaches the GUI width minus its own width
		$iThumbSize = $aSize[1] ; In horizontal, the thumb's width is the height of the GUI
		$iAvailableTrack = $aSize[0] - $iThumbSize
		$fPercent = ($iX - ($iThumbSize / 2)) / $iAvailableTrack
	Else ; VERTICAL
		$iThumbSize = $aSize[0] ; In vertical, the thumb's height is the width of the GUI
		$iAvailableTrack = $aSize[1] - $iThumbSize
		; For vertical, by default 0 is below, so:
		$fPercent = ($aSize[1] - $iY - ($iThumbSize / 2)) / $iAvailableTrack
	EndIf

	; LIMITATION
	If $fPercent < 0 Then $fPercent = 0
	If $fPercent > 1 Then $fPercent = 1

	Local $iNewVal = Int($m.Min + ($fPercent * ($m.Max - $m.Min)))

	If $iNewVal <> $m.Value Then
		$m.Value = $iNewVal
		_UC_Properties($m.UC_ControlID, $m)
		GUICtrlSendToDummy($m.UC_ControlID, $iNewVal)
		If $m.ShowTooltip Then _UC_ToolTip($iNewVal)
	EndIf
EndFunc   ;==>_UC_Slider_UpdateFromMouse

Func _UC_Slider_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	$m.IsDragging = 1
	$m.State = 3 ; Pressed
	If $m.ShowTooltip Then _UC_ToolTip(String($m.Value))
	_UC_Properties($idDummy, $m)
	_WinAPI_SetCapture($hWnd)
	_UC_Slider_UpdateFromMouse($hWnd, $m, $iX, $iY)
EndFunc   ;==>_UC_Slider_WM_LBUTTONDOWN

Func _UC_Slider_WM_LBUTTONDBLCLK($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	; For now, a double click on a button should behave exactly like a fast single click.
	; So we just forward the parameters straight to the Down handler.
	Return _UC_Slider_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_Slider_WM_LBUTTONDBLCLK

Func _UC_Slider_WM_LBUTTONUP($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	$m.State = 2 ; Hover
	If $m.IsDragging Then
		$m.IsDragging = 0
		_UC_Properties($idDummy, $m)
		_WinAPI_ReleaseCapture()
		_UC_ToolTip("")
	EndIf
EndFunc   ;==>_UC_Slider_WM_LBUTTONUP

Func _UC_Slider_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return ; If is Disabled
	If $m.IsDragging Then
		_UC_Slider_UpdateFromMouse($hWnd, $m, $iX, $iY)
	Else
		If $m.State <> 0 And $m.State <> 2 And $m.State <> 3 Then
			$m.State = 2 ; Hover
			_UC_Properties($idDummy, $m)
		EndIf
	EndIf
EndFunc   ;==>_UC_Slider_WM_MOUSEMOVE

Func _UC_Slider_WM_SETFOCUS($idDummy, $hWnd, $iX, $iY)
    _UC_Slider_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
EndFunc

Func _UC_Slider_UpdateFromValue($idDummy = Default, $iValue = 1)
	If $idDummy = Default Then $idDummy = _UC_Properties(1, "UC_ActiveControlID")
	If Not $idDummy Then Return SetError(1, 0, 0)
	Local $m = _UC_Properties($idDummy)
	If Not ($m.UC_Type = $UC_TYPE_SLIDER) Then Return SetError(2, 0, 0)
	Local $iNewValue
	$iNewValue = $m.Value + $iValue
	$iNewValue = ($iNewValue > $m.Max ? $m.Max : $iNewValue)
	$iNewValue = ($iNewValue < $m.Min ? $m.Min : $iNewValue)
	$m.Value = $iNewValue
	_UC_Properties($idDummy, $m)
	GUICtrlSendToDummy($idDummy, $iNewValue)
EndFunc   ;==>_UC_Slider_UpdateFromValue

#EndRegion ; ~~~~~~~~~~~~~ UC Slider API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
