; UC_Image.au3
#include-once

#include "Frame\UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC Image API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func _UC_Image_Create($hParent, $sFilename, $iX, $iY, $fScale = 1.0)
	GUISwitch($hParent)
	Local $idDummy = GUICtrlCreateDummy()

	Local $hImage = _GDIPlus_ImageLoadFromFile($sFilename)
	Local $iW = Int(_GDIPlus_ImageGetWidth($hImage) * $fScale)
	Local $iH = Int(_GDIPlus_ImageGetHeight($hImage) * $fScale)

	Local $hChild = GUICreate("UC_Control_" & $idDummy, $iW, $iH, $iX, $iY, BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS), $WS_EX_TRANSPARENT, $hParent)

	__UC_Framework_Init($hParent)

	Local $m[]
	$m.UC_Type = $UC_TYPE_IMAGE
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

	$m.State = 1                ; 1=Normal, 2=Hover, 3=Pressed
	$m.Filename = $sFilename
	$m.Scale = $fScale
	$m.Image = $hImage
	$m.Width = $iW
	$m.Height = $iH
	$m.Resampling = 7           ; HighQualityBicubic
	$m.ShowTooltip = 0
	$m.Tooltip = ""
	$m.SetFocus = 0

	_WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)
	_UC_Properties($idDummy, $m)
	_UC_Properties(1, "UC_LastCreatedID", $idDummy)

	GUISwitch($hParent)
	Return $idDummy
EndFunc   ;==>_UC_Image_Create

Func _UC_Image_Draw($hWnd, ByRef $m)
	Local $aSize = WinGetClientSize($hWnd)
	Local $iW = $aSize[0], $iH = $aSize[1]
	If $iW <= 0 Or $iH <= 0 Then Return

	Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hWnd)
	Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics($iW, $iH, $hGraphics)
	Local $hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)

	_GDIPlus_GraphicsSetInterpolationMode($hBack, $m.Resampling)
	_GDIPlus_GraphicsSetPixelOffsetMode($hBack, 4)

	Local $hBGColor = "0xFF" & Hex(__UC_ParentColor($hWnd), 6)
	_GDIPlus_GraphicsClear($hBack, $hBGColor)

	If $m.Image <> 0 Then
		_GDIPlus_GraphicsDrawImageRect($hBack, $m.Image, 0, 0, $iW, $iH)
	EndIf

	; Visual feedback for Hover/Pressed (Optional)
	If $m.State = 3 And $m.SetFocus Then ; Pressed: Slight darkening
		Local $hBrushOver = _GDIPlus_BrushCreateSolid(0x30000000)
		_GDIPlus_GraphicsFillRect($hBack, 0, 0, $iW, $iH, $hBrushOver)
		_GDIPlus_BrushDispose($hBrushOver)
	EndIf

	_GDIPlus_GraphicsDrawImage($hGraphics, $hBitmap, 0, 0)

	_GDIPlus_GraphicsDispose($hBack)
	_GDIPlus_BitmapDispose($hBitmap)
	_GDIPlus_GraphicsDispose($hGraphics)
EndFunc   ;==>_UC_Image_Draw

Func _UC_Image_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Then Return
	$m.State = 3 ; Pressed
	_UC_Properties($idDummy, $m) ; ReDraw to show feedback
	_WinAPI_SetCapture($hWnd)
EndFunc   ;==>_UC_Image_WM_LBUTTONDOWN

Func _UC_Image_WM_LBUTTONDBLCLK($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	; For now, a double click on a button should behave exactly like a fast single click.
	; So we just forward the parameters straight to the Down handler.
	Return _UC_Image_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_Image_WM_LBUTTONDBLCLK

Func _UC_Image_WM_LBUTTONUP($idDummy, $hWnd, $iX, $iY)
	Local $m = _UC_Properties($idDummy)
	If $m.State = 3 Then
		_WinAPI_ReleaseCapture()
		If _UC_IsMouseOver($hWnd) Or ($iX = -1 And $iY = -1) Then
			$m.State = 2 ; Hover
			_UC_Properties($idDummy, $m)
			GUICtrlSendToDummy($idDummy, $m.UC_ControlID)
		Else
			$m.State = 1 ; Normal
			_UC_Properties($idDummy, $m, True)
		EndIf
	EndIf
EndFunc   ;==>_UC_Image_WM_LBUTTONUP

Func _UC_Image_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY
	Local $m = _UC_Properties($idDummy)
	If $m.State = 0 Or $m.State = 3 Then Return
	If $m.State = 1 Then
		$m.State = 2 ; Hover
		_UC_Properties($idDummy, $m) ; ReDraw for hover effect
		If $m.ShowTooltip Then _UC_ToolTip($m.Tooltip)
	EndIf
EndFunc   ;==>_UC_Image_WM_MOUSEMOVE

Func _UC_Image_WM_SETFOCUS($idDummy, $hWnd, $iX, $iY)
	_UC_Image_WM_MOUSEMOVE($idDummy, $hWnd, $iX, $iY)
EndFunc   ;==>_UC_Image_WM_SETFOCUS

Func _UC_Image_WM_KEYDOWN($idDummy, $hWnd, $iKeyCode, $aXY)
	Switch $iKeyCode
		Case $VK_SPACE
			_UC_Image_WM_LBUTTONDOWN($idDummy, $hWnd, $aXY[0], $aXY[1])
			Sleep(50)
			_UC_Image_WM_LBUTTONUP($idDummy, $hWnd, -1, -1)
	EndSwitch
EndFunc   ;==>_UC_Image_WM_KEYDOWN

#EndRegion ; ~~~~~~~~~~~~~ UC Image API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
