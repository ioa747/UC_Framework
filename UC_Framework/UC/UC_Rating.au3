; UC_Button.au3
#include-once

#include "Frame\UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC Rating API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func _UC_Rating_Create($hParent, $iX, $iY, $iStarSize = 24, $iSpacing = 5, $iValue = 0, $iReadOnly = 0, _
		$hFillColor = 0xFFD700, $hEmptyColor = 0xC0C0C0, $hHoverColor = 0xFFAA00)

	GUISwitch($hParent)
	Local $idDummy = GUICtrlCreateDummy()

	Local $iTotalWidth = ($iStarSize * 5) + ($iSpacing * 4)
	Local $hChild = GUICreate("UC_Control_" & $idDummy, $iTotalWidth, $iStarSize, _
			$iX, $iY, BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS, $WS_TABSTOP), _
			$WS_EX_TRANSPARENT, $hParent)

	__UC_Framework_Init($hParent)

	If Not $iReadOnly Then
		GUISetCursor(_UC_Get(1, "Cursor_Hand"), $GUI_CURSOR_OVERRIDE, $hChild)
	EndIf

	Local $m[]

	; Universal Properties
	$m.UC_Type = $UC_TYPE_RATING
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

	; Rating Specific Properties
	$m.State = 1                    ; 0=Disabled, 1=Normal, 2=Hover, 3=Pressed
	$m.Value = $iValue              ; Current rating (0 a 5)
	$m.HoverValue = 0               ; Temporary value on hover
	$m.ReadOnly = $iReadOnly
	$m.StarSize = $iStarSize
	$m.Spacing = $iSpacing
	$m.FillColor = $hFillColor      ; Filled Star Color
	$m.EmptyColor = $hEmptyColor    ; Empty Star Color
	$m.HoverColor = $hHoverColor    ; Hover Star Color
	$m.Min = 0
	$m.Max = 5
	$m.ShowTooltip = 0
	$m.TooltipPrefix = ""

	_WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)
	_UC_Properties($idDummy, $m)
	_UC_Properties(1, "UC_LastCreatedID", $idDummy)

	GUISwitch($hParent)
	Return $idDummy
EndFunc   ;==>_UC_Rating_Create

Func _UC_Rating_Draw($hWnd, ByRef $m, $bFullRedraw = False)
	; Το Bitmap/Back Graphics παραμένουν Static μόνο αν θέλουμε να διατηρήσουμε το Buffer,
	; αλλά τα Brushes/Pens γίνονται 100% τοπικά.
	Static $hBitmap = 0, $hBack = 0, $hFront = 0
	Static $iLastW = 0, $iLastH = 0

	Local $aSize = WinGetClientSize($hWnd)
	Local $iW = $aSize[0], $iH = $aSize[1]
	If $iW <= 0 Or $iH <= 0 Then Return

	; Δημιουργία Τοπικών Πόρων (Resources)
	Local $hBrushFill = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.FillColor, 6))
	Local $hBrushEmpty = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.EmptyColor, 6))
	Local $hBrushHover = _GDIPlus_BrushCreateSolid("0xFF" & Hex($m.HoverColor, 6))
	Local $hPenStar = _GDIPlus_PenCreate(0xFF333333, 1.5)

	; Double Buffering Context
	If $hBitmap = 0 Or $iW <> $iLastW Or $iH <> $iLastH Or $bFullRedraw Then
		If $hBack Then _GDIPlus_GraphicsDispose($hBack)
		If $hBitmap Then _GDIPlus_BitmapDispose($hBitmap)
		If $hFront Then _GDIPlus_GraphicsDispose($hFront)
		$hFront = _GDIPlus_GraphicsCreateFromHWND($hWnd)
		$hBitmap = _GDIPlus_BitmapCreateFromGraphics($iW, $iH, $hFront)
		$hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)
		$iLastW = $iW
		$iLastH = $iH
		_GDIPlus_GraphicsSetSmoothingMode($hBack, 4)
	EndIf

	_GDIPlus_GraphicsClear($hBack, "0xFF" & Hex(__UC_ParentColor($hWnd), 6))

	Local $iStarSize = $m.StarSize
	Local $iSpacing = $m.Spacing
	Local $iDisplayValue = ($m.State = 2 ? $m.HoverValue : $m.Value)

	For $i = 1 To 5
		Local $iX = ($i - 1) * ($iStarSize + $iSpacing) + ($iStarSize / 2)
		Local $iY = $iH / 2

		Local $hBrush
		If $m.State = 2 And $i <= $m.HoverValue Then
			$hBrush = $hBrushHover
		ElseIf $i <= $iDisplayValue Then
			$hBrush = $hBrushFill
		Else
			$hBrush = $hBrushEmpty
		EndIf

		__UC_DrawStar($hBack, $iX, $iY, $iStarSize / 2, $hBrush, $hPenStar, True)
	Next

	_GDIPlus_GraphicsDrawImageRect($hFront, $hBitmap, 0, 0, $iW, $iH)

	; --- ΚΑΘΑΡΙΣΜΟΣ (Cleanup) ---
	; Εδώ απελευθερώνουμε όλα τα τοπικά αντικείμενα
	_GDIPlus_BrushDispose($hBrushFill)
	_GDIPlus_BrushDispose($hBrushEmpty)
	_GDIPlus_BrushDispose($hBrushHover)
	_GDIPlus_PenDispose($hPenStar)
	; Το hBack/hBitmap/hFront δεν τα διαγράφουμε γιατί είναι Static Buffer
EndFunc   ;==>_UC_Rating_Draw

Func _UC_Rating_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Or $m.ReadOnly Then Return

	$m.State = 3 ; Pressed
	_UC_Properties($idDummy, $m)
	_WinAPI_SetCapture($hWnd)
EndFunc   ;==>_UC_Rating_WM_LBUTTONDOWN

Func _UC_Rating_WM_LBUTTONDBLCLK($idDummy, $hWnd, $iX, $iY)
	Return _UC_Rating_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_Rating_WM_LBUTTONDBLCLK

Func _UC_Rating_WM_LBUTTONUP($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iY
	_WinAPI_ReleaseCapture()
	Local $m = _UC_Properties($idDummy)
	If $m.State <> 3 Or $m.ReadOnly Then Return

	If _UC_IsMouseOver($hWnd) Then
		Local $iStarSize = $m.StarSize
		Local $iSpacing = $m.Spacing
		Local $iNewValue = Int($iX / ($iStarSize + $iSpacing)) + 1

		If $iNewValue < 0 Then $iNewValue = 0
		If $iNewValue > 5 Then $iNewValue = 5


		$m.Value = $iNewValue
		$m.HoverValue = $iNewValue
		$m.State = 2

		_UC_Properties($idDummy, $m)

		GUICtrlSendToDummy($idDummy, $iNewValue)
	Else
		$m.State = 1
		_UC_Properties($idDummy, $m)
	EndIf
EndFunc   ;==>_UC_Rating_WM_LBUTTONUP

Func _UC_Rating_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Or $m.ReadOnly Then Return

	Local $iStarSize = $m.StarSize
	Local $iSpacing = $m.Spacing
	Local $iHover = Int($iX / ($iStarSize + $iSpacing)) + 1

	If $iHover < 1 Then $iHover = 1
	If $iHover > 5 Then $iHover = 5

;~     If $m.HoverValue <> $iHover Then
	$m.HoverValue = $iHover
	$m.State = 2
	_UC_Properties($idDummy, $m)

	If $m.ShowTooltip Then
		_UC_ToolTip($m.TooltipPrefix & $iHover & "/5")
	EndIf
;~     EndIf
EndFunc   ;==>_UC_Rating_WM_MOUSEMOVE

Func _UC_Rating_WM_SETFOCUS($idDummy, $hWnd, $iX, $iY)
    _UC_Rating_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
EndFunc

Func _UC_Rating_WM_KEYDOWN($idDummy, $hWnd, $iKeyCode, $aXY)
    Switch $iKeyCode
        Case $VK_ADD
            _UC_Rating_UpdateFromValue($idDummy, 1)
        Case $VK_SUBTRACT
            _UC_Rating_UpdateFromValue($idDummy, -1)
        Case $VK_SPACE
            _UC_Rating_WM_LBUTTONDOWN($idDummy, $hWnd, $aXY[0], $aXY[1])
            Sleep(50)
            _UC_Rating_WM_LBUTTONUP($idDummy, $hWnd, -1, -1)
    EndSwitch
EndFunc

Func _UC_Rating_UpdateFromValue($idDummy = Default, $iValue = 1)
	If $idDummy = Default Then $idDummy = _UC_Properties(1, "UC_ActiveControlID")
	If Not $idDummy Then Return SetError(1, 0, 0)
	Local $m = _UC_Properties($idDummy)
	If Not ($m.UC_Type = $UC_TYPE_RATING) Then Return SetError(2, 0, 0)
	Local $iNewValue
	$iNewValue = $m.Value + $iValue
	$iNewValue = ($iNewValue > $m.Max ? $m.Max : $iNewValue)
	$iNewValue = ($iNewValue < $m.Min ? $m.Min : $iNewValue)
	$m.Value = $iNewValue
	_UC_Properties($idDummy, $m)
	GUICtrlSendToDummy($idDummy, $iNewValue)
EndFunc   ;==>_UC_Rating_UpdateFromValue

#EndRegion ; ~~~~~~~~~~~~~ UC Rating API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
