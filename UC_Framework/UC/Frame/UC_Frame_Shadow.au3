#include-once ; UC_Frame_Shadow.au3

#include "UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC_Framework Shadow API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; #FUNCTION# ====================================================================================================================
; Name...........: _UC_Shadow_Overlay
; Description ...: Creates and manages a layered window overlay to render a drop shadow effect for a UC_control.
; Syntax.........: _UC_Shadow_Overlay($idCtrl, $iDirection, $iDistance, $bOutline, $iInflate, $iOpacity, $iMethod)
; Parameters ....: $idCtrl     - The ID of the control to apply the shadow to.
;                  $iDirection - [optional] The angle of the shadow in degrees (0-360). (Default = 150)
;                  $iDistance  - [optional] The distance of the shadow from the control in pixels. (Default = 10)
;                  $bOutline   - [optional] Boolean to toggle outline rendering logic. (Default = True)
;                  $iInflate   - [optional] Pixel value to expand or shrink the shadow area. (Default = 0)
;                  $iOpacity   - [optional] Shadow opacity percentage (0-100).
;                                Set to 0 for automatic adaptive opacity based on
;                                parent background brightness (Light=1%, Dark=7%). (Default = 0)
;                  $iMethod    - [optional] Rendering method (1 = Multi-layer blur, 2 = Offset spread). (Default = 2)
; Return values .: Success - Returns the handle (HWND) of the created shadow overlay window.
;                  Failure - Returns False and sets @error if the control properties are not found.
; ===============================================================================================================================
Func _UC_Shadow_Overlay($idCtrl, $iDirection = Default, $iDistance = Default, $bOutline = Default, $iInflate = Default, $iOpacity = Default, $iMethod = Default)
	If $iDirection = Default Then $iDirection = 150
	If $iDistance = Default Then $iDistance = 10
	If $bOutline = Default Then $bOutline = True
	If $iInflate = Default Then $iInflate = 0
	If $iOpacity = Default Then $iOpacity = 0
	If $iMethod = Default Then $iMethod = 2

	Local $m = _UC_Properties($idCtrl)
	If Not IsMap($m) Then Return SetError(1, 0, False)

	Local $hOverlayWnd = MapExists($m, "UC_Shadow_Overlay_hWnd") ? $m.UC_Shadow_Overlay_hWnd : 0

	Local $iState = $m.State
	If $iState = 2 Then Return

	; 2. 💡 DRAGGING FILTER (State = 3): Update every 8 pixels of movement
	If $hOverlayWnd And $iState = 3 Then
		; We read where the mouse was the last time we drew the shadow
		Local $iLastX = MapExists($m, "UC_Shadow_LastX") ? $m.UC_Shadow_LastX : -999
		Local $iLastY = MapExists($m, "UC_Shadow_LastY") ? $m.UC_Shadow_LastY : -999

		Local $aMPos = MouseGetPos()

		; We calculate the absolute difference
		Local $iDiffX = Abs($aMPos[0] - $iLastX)
		Local $iDiffY = Abs($aMPos[1] - $iLastY)

		; If the mouse moved less than 8 pixels in both axes, do Return!
		If $iDiffX < 4 And $iDiffY < 4 Then Return

		; If it passed the 8 pixel test, we store the NEW coordinates as the last
		$m.UC_Shadow_LastX = $aMPos[0]
		$m.UC_Shadow_LastY = $aMPos[1]
		_UC_Properties($idCtrl, $m, False)
	EndIf

	Local $hCtrl = $m.UC_hWnd
	Local $hParent = $m.UC_hParent
	Local $iW = $m.UC_Width, $iH = $m.UC_Height
	Local $iPad = $iDistance ; Padding based on shadow distance

	Local $iParentColor = __UC_ParentColor($hCtrl)
	Local $iGDIColor = "0xFF" & Hex($iParentColor, 6)

	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; 0. ADAPTIVE OPACITY LOGIC & COLOR MATRIX
	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Local $fFinalOpacity = $iOpacity

	; If Opacity is set to 0, automatically detect Dark/Light theme
	If $iOpacity = 0 Then
		; Since $iParentColor is already standard RGB from UC_Properties,
		; we pass it directly to your framework's function!
		If _UC_IsLightColor($iParentColor) Then
			$fFinalOpacity = 1 ; Light Theme: Soft, elegant shadow (1%)
		Else
			$fFinalOpacity = 7 ; Dark Theme: Stronger shadow (5%) to stand out
		EndIf
	EndIf

	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; 1. COORDINATE CALCULATION (WS_CHILD MODE)
	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Local $tRect = _WinAPI_GetWindowRect($hCtrl)
	_WinAPI_ScreenToClient($hParent, $tRect)

	Local $iCtrlX = DllStructGetData($tRect, "Left")
	Local $iCtrlY = DllStructGetData($tRect, "Top")

	Local $iOverX = $iCtrlX - $iPad
	Local $iOverY = $iCtrlY - $iPad
	Local $iOverW = $iW + ($iPad * 2)
	Local $iOverH = $iH + ($iPad * 2)

	If Not WinExists($hOverlayWnd) Then
		$hOverlayWnd = GUICreate("UC_Digital_Shadow_" & $idCtrl, $iOverW, $iOverH, $iOverX, $iOverY, _
				$WS_CHILD, BitOR($WS_EX_TRANSPARENT, $WS_EX_LAYERED), $hParent)

		$m.UC_Shadow_Overlay_hWnd = $hOverlayWnd
		_UC_Properties($idCtrl, $m, False)
	Else
		_WinAPI_MoveWindow($hOverlayWnd, $iOverX, $iOverY, $iOverW, $iOverH, False)
	EndIf

	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; 2. CAPTURE CONTROL IMAGE
	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Local $hGDIScr = _WinAPI_GetDC($hCtrl)
	Local $hCtrlBmp = _GDIPlus_BitmapCreateFromHBITMAP(_WinAPI_CreateCompatibleBitmap($hGDIScr, $iW, $iH))
	Local $hCtrlGraphics = _GDIPlus_ImageGetGraphicsContext($hCtrlBmp)

	; Native DllCall for Graphics DC
	Local $hGraphicsDC = _GDIPlus_GraphicsGetDC($hCtrlGraphics)
	_WinAPI_BitBlt($hGraphicsDC, 0, 0, $iW, $iH, $hGDIScr, 0, 0, $SRCCOPY)
	_GDIPlus_GraphicsReleaseDC($hCtrlGraphics, $hGraphicsDC)

	_GDIPlus_GraphicsDispose($hCtrlGraphics)
	_WinAPI_ReleaseDC($hCtrl, $hGDIScr)

	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; 3. GDI+ BUFFER SETUP
	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hOverlayWnd)
	Local $hBitmap = _GDIPlus_BitmapCreateFromScan0($iOverW, $iOverH, 0x0026200A)
	Local $hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)
	_GDIPlus_GraphicsSetSmoothingMode($hBack, 4)
	_GDIPlus_GraphicsClear($hBack, 0x00000000)

	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; 4. PREPARE UNIVERSAL ERASER (Pixel-Perfect Exclude Region)
	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; Create Region from Bitmap pixels
	Local $hCtrlRegion = __UC_GDIP_RegionCreateFromBitmap($hCtrlBmp, $iGDIColor, $bOutline, $iInflate)

	Local $hMatrix = _GDIPlus_MatrixCreate()
	_GDIPlus_MatrixTranslate($hMatrix, $iPad, $iPad)
	_GDIPlus_RegionTransform($hCtrlRegion, $hMatrix)

	Local $hFullRegion = _GDIPlus_RegionCreateFromRect(0, 0, $iOverW, $iOverH)

	; Exclude the exact shape of the Control from the Buffer's Clip Region
	_GDIPlus_RegionCombineRegion($hFullRegion, $hCtrlRegion, 3) ; 3 = CombineModeExclude
	_GDIPlus_GraphicsSetClipRegion($hBack, $hFullRegion)

	; Cleanup Step 4 temporary objects
	_GDIPlus_MatrixDispose($hMatrix)
	_GDIPlus_RegionDispose($hCtrlRegion)


	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; 5. USE $iParentColor VIA IMAGE ATTRIBUTES & PREPARE BMP
	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Local $hRenderBmp = $hCtrlBmp

	; If in Outline mode, use the patched Bitmap
	If $bOutline Then
		$hRenderBmp = __UC_GDIP_BitmapPrepareForShadow($hCtrlBmp, $iGDIColor, $iInflate)
	EndIf

	Local $hIA = _GDIPlus_ImageAttributesCreate()
	_GDIPlus_ImageAttributesSetColorKeys($hIA, 0, True, $iGDIColor, $iGDIColor)

	; COLOR MATRIX: Convert to Black Alpha
	Local $tMatrix = DllStructCreate("float[5];float[5];float[5];float[5];float[5]")
	DllStructSetData($tMatrix, 1, 0, 1)
	DllStructSetData($tMatrix, 2, 0, 2)
	DllStructSetData($tMatrix, 3, 0, 3)
	DllStructSetData($tMatrix, 4, $fFinalOpacity / 100, 4) ; Set shadow opacity
	_GDIPlus_ImageAttributesSetColorMatrix($hIA, 0, True, DllStructGetPtr($tMatrix))

	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; 6. TRIGONOMETRY CALCULATION
	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Local Const $PI = 3.14159265358979
	Local $fRad = ($iDirection - 90) * $PI / 180
	Local $fOffsetX = Cos($fRad) * $iDistance
	Local $fOffsetY = Sin($fRad) * $iDistance

	If $iMethod = 1 Then
		; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		; 7. UNIVERSAL MULTI-LAYER BLUR ; METHOD 1 (Size-scaling blur)
		; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		For $i = 1 To Int($iDistance / 2)
			Local $fBlur = $i * 1
			_GDIPlus_GraphicsDrawImageRectRect($hBack, $hRenderBmp, 0, 0, $iW, $iH, _
					($iPad + $fOffsetX) - ($fBlur / 2), ($iPad + $fOffsetY) - ($fBlur / 2), _
					$iW + $fBlur, $iH + $fBlur, $hIA)
		Next

	Else
		; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		; 7. UNIVERSAL MULTI-LAYER BLUR ; METHOD 2 (Jitter spread blur)
		; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		Local $iLayers = Int($iDistance / 2)
		If $iLayers < 4 Then $iLayers = 4

		For $i = 1 To $iLayers
			Local $fSpread = ($i - 1) * 0.5

			Local $fXMod = Mod($i, 2) = 0 ? $fSpread : -$fSpread
			Local $fYMod = Mod($i, 3) = 0 ? $fSpread : -$fSpread

			_GDIPlus_GraphicsDrawImageRectRect($hBack, $hRenderBmp, 0, 0, $iW, $iH, _
					($iPad + $fOffsetX) + $fXMod, ($iPad + $fOffsetY) + $fYMod, _
					$iW, $iH, $hIA)
		Next

	EndIf

	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; 8. WIN32 BITMAP HANDSHAKE
	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Local $hHBITMAP = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hBitmap)
	Local $hScrDC = _WinAPI_GetDC(0)
	Local $hMemDC = _WinAPI_CreateCompatibleDC($hScrDC)
	Local $hOldBmp = _WinAPI_SelectObject($hMemDC, $hHBITMAP)
	Local $tSize = DllStructCreate($tagSIZE)
	DllStructSetData($tSize, "X", $iOverW)
	DllStructSetData($tSize, "Y", $iOverH)
	Local $tPointSrc = DllStructCreate($tagPOINT)
	Local $tBlend = DllStructCreate("byte BlendOp; byte BlendFlags; byte SourceConstantAlpha; byte AlphaFormat;")
	DllStructSetData($tBlend, "BlendOp", 0)
	DllStructSetData($tBlend, "BlendFlags", 0)
	DllStructSetData($tBlend, "SourceConstantAlpha", 255)
	DllStructSetData($tBlend, "AlphaFormat", 1)

	_WinAPI_UpdateLayeredWindow($hOverlayWnd, $hScrDC, 0, $tSize, $hMemDC, $tPointSrc, 0, DllStructGetPtr($tBlend), 2)

	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; 9. CLEANUP
	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	_WinAPI_SelectObject($hMemDC, $hOldBmp)
	_WinAPI_DeleteDC($hMemDC)
	_WinAPI_ReleaseDC(0, $hScrDC)
	_WinAPI_DeleteObject($hHBITMAP)
	_GDIPlus_ImageAttributesDispose($hIA)
	_GDIPlus_RegionDispose($hFullRegion)

	; Safe disposal of bitmaps to prevent double-free crashes
	If $hRenderBmp <> $hCtrlBmp Then _GDIPlus_BitmapDispose($hRenderBmp)
	_GDIPlus_BitmapDispose($hCtrlBmp)

	_GDIPlus_GraphicsDispose($hBack)
	_GDIPlus_BitmapDispose($hBitmap)
	_GDIPlus_GraphicsDispose($hGraphics)

	GUISetState(@SW_SHOWNOACTIVATE, $hOverlayWnd)
	Return $hOverlayWnd
EndFunc   ;==>_UC_Shadow_Overlay

Func __UC_GDIP_RegionCreateFromBitmap($hBitmap, $iColorKey, $bOutline = True, $iInflate = 0)
	; 1. Convert GDI+ Bitmap to Win32 HBITMAP
	Local $hHBITMAP = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hBitmap)
	Local $iW = _GDIPlus_ImageGetWidth($hBitmap)
	Local $iH = _GDIPlus_ImageGetHeight($hBitmap)

	; 2. Setup temporary DC
	Local $hScrDC = _WinAPI_GetDC(0)
	Local $hMemDC = _WinAPI_CreateCompatibleDC($hScrDC)
	Local $hOldBmp = _WinAPI_SelectObject($hMemDC, $hHBITMAP)

	; 3. Correct ColorKey to Win32
	Local $iGDIColorKey = BitAND($iColorKey, 0xFFFFFF)

	Local $hWin32Region = _WinAPI_CreateRectRgn(0, 0, 0, 0)
	Local $hTempRgn, $iXStart, $iXEnd

	; 4. SCANLINE WITH OUTLINE OR PIXEL-PERFECT + INFLATE LOGIC
	For $y = 0 To $iH - 1
		If $bOutline Then
			; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			; OUTLINE LOGIC: Find only the external boundaries
			; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			$iXStart = -1
			$iXEnd = -1

			For $x = 0 To $iW - 1
				If _WinAPI_GetPixel($hMemDC, $x, $y) <> $iGDIColorKey Then
					$iXStart = $x
					ExitLoop
				EndIf
			Next

			If $iXStart <> -1 Then
				For $x = $iW - 1 To $iXStart Step -1
					If _WinAPI_GetPixel($hMemDC, $x, $y) <> $iGDIColorKey Then
						$iXEnd = $x + 1
						ExitLoop
					EndIf
				Next

				If $iXEnd <> -1 Then
					; APPLY INFLATE (Shrink/expand strip)
					; If $iInflate is negative (e.g., -1), XStart increases and XEnd decreases
					If $iInflate <> 0 Then
						$iXStart = $iXStart - $iInflate
						$iXEnd = $iXEnd + $iInflate
					EndIf

					; Check to prevent canceling the strip if the control is too small
					If $iXStart < $iXEnd Then
						$hTempRgn = _WinAPI_CreateRectRgn($iXStart, $y, $iXEnd, $y + 1)
						_WinAPI_CombineRgn($hWin32Region, $hWin32Region, $hTempRgn, 2) ; 2 = RGN_OR
						_WinAPI_DeleteObject($hTempRgn)
					EndIf
				EndIf
			EndIf
		Else
			; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			; CLASSIC LOGIC: Pixel-Perfect (Handles internal holes)
			; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			Local $iNewStart, $iNewEnd
			$iXStart = -1
			For $x = 0 To $iW - 1
				If _WinAPI_GetPixel($hMemDC, $x, $y) <> $iGDIColorKey Then
					If $iXStart = -1 Then $iXStart = $x
				Else
					If $iXStart <> -1 Then
						; Apply inflate to internal strips as well
						$iNewStart = $iXStart - $iInflate
						$iNewEnd = $x + $iInflate
						If $iNewStart < $iNewEnd Then
							$hTempRgn = _WinAPI_CreateRectRgn($iNewStart, $y, $iNewEnd, $y + 1)
							_WinAPI_CombineRgn($hWin32Region, $hWin32Region, $hTempRgn, 2)
							_WinAPI_DeleteObject($hTempRgn)
						EndIf
						$iXStart = -1
					EndIf
				EndIf
			Next
			If $iXStart <> -1 Then
				$iNewStart = $iXStart - $iInflate
				$iNewEnd = $iW + $iInflate
				If $iNewStart < $iNewEnd Then
					$hTempRgn = _WinAPI_CreateRectRgn($iNewStart, $y, $iNewEnd, $y + 1)
					_WinAPI_CombineRgn($hWin32Region, $hWin32Region, $hTempRgn, 2)
					_WinAPI_DeleteObject($hTempRgn)
				EndIf
			EndIf
		EndIf
	Next

	; 5. Convert Win32 Region to GDI+ Region
	Local $aResult = DllCall($__g_hGDIPDll, "int", "GdipCreateRegionHrgn", "handle", $hWin32Region, "handle*", 0)
	Local $hGdipRegion = 0
	If Not @error And $aResult[0] = 0 Then $hGdipRegion = $aResult[2]

	; Cleanup
	_WinAPI_SelectObject($hMemDC, $hOldBmp)
	_WinAPI_DeleteDC($hMemDC)
	_WinAPI_ReleaseDC(0, $hScrDC)
	_WinAPI_DeleteObject($hHBITMAP)
	_WinAPI_DeleteObject($hWin32Region)

	If $hGdipRegion = 0 Then Return SetError(4, 0, 0)
	Return $hGdipRegion
EndFunc   ;==>__UC_GDIP_RegionCreateFromBitmap

Func __UC_GDIP_BitmapPrepareForShadow($hBitmap, $iColorKey, $iInflate = 0)
	; 1. Create a copy of the original Bitmap to avoid modifying it
	Local $hNewBitmap = _GDIPlus_BitmapCloneArea($hBitmap, 0, 0, _GDIPlus_ImageGetWidth($hBitmap), _GDIPlus_ImageGetHeight($hBitmap))

	; 2. Convert GDI+ Bitmap to Win32 HBITMAP for efficient drawing with GetPixel/SetPixel
	Local $hHBITMAP = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hNewBitmap)
	Local $iW = _GDIPlus_ImageGetWidth($hNewBitmap)
	Local $iH = _GDIPlus_ImageGetHeight($hNewBitmap)

	; Setup temporary DC for drawing
	Local $hScrDC = _WinAPI_GetDC(0)
	Local $hMemDC = _WinAPI_CreateCompatibleDC($hScrDC)
	Local $hOldBmp = _WinAPI_SelectObject($hMemDC, $hHBITMAP)

	; 3. Convert ColorKey for matching and setup Win32 Pen Color (BGR)
	Local $iGDIColorKey = BitAND($iColorKey, 0xFFFFFF)

	; For the Win32 Pen (which uses native GDI), we NEED the BGR structure:
	Local $iR = BitAND(BitShift($iColorKey, 16), 0xFF)
	Local $iG = BitAND(BitShift($iColorKey, 8), 0xFF)
	Local $iB = BitAND($iColorKey, 0xFF)
	Local $iWin32BGR = BitAND(BitOR(BitShift($iB, -16), BitShift($iG, -8), $iR), 0xFFFFFF)

	; Shift the Win32 pen color by 1 unit so it never equals the background
	Local $iPenColor = $iWin32BGR + 1
	If $iPenColor > 0xFFFFFF Then $iPenColor = $iWin32BGR - 1


	Local $hPen = _WinAPI_CreatePen(0, 1, $iPenColor)
	Local $hOldPen = _WinAPI_SelectObject($hMemDC, $hPen)

	Local $iXStart, $iXEnd

	; 4. SCANLINE AND INSTANT FILL
	For $y = 0 To $iH - 1
		$iXStart = -1
		$iXEnd = -1

		; Find the first non-transparent pixel of the control from the left
		For $x = 0 To $iW - 1
			If _WinAPI_GetPixel($hMemDC, $x, $y) <> $iGDIColorKey Then
				$iXStart = $x
				ExitLoop
			EndIf
		Next

		If $iXStart <> -1 Then
			; Find the last non-transparent pixel of the control from the right
			For $x = $iW - 1 To $iXStart Step -1
				If _WinAPI_GetPixel($hMemDC, $x, $y) <> $iGDIColorKey Then
					$iXEnd = $x + 1
					ExitLoop
				EndIf
			Next

			If $iXEnd <> -1 Then
				; Apply Inflate (shrink/expand)
				If $iInflate <> 0 Then
					$iXStart = $iXStart - $iInflate
					$iXEnd = $iXEnd + $iInflate
				EndIf

				; THE MAGIC: Instead of using Regions, draw a horizontal black line
				; from XStart to XEnd. This fills the entire interior (including the Thumb)!
				If $iXStart < $iXEnd Then
					_WinAPI_MoveToEx($hMemDC, $iXStart, $y)
					_WinAPI_LineTo($hMemDC, $iXEnd, $y)
				EndIf
			EndIf
		EndIf
	Next

	; Cleanup Win32 objects
	_WinAPI_SelectObject($hMemDC, $hOldPen)
	_WinAPI_DeleteObject($hPen)
	_WinAPI_SelectObject($hMemDC, $hOldBmp)
	_WinAPI_DeleteDC($hMemDC)
	_WinAPI_ReleaseDC(0, $hScrDC)

	; 5. Transfer changes from Win32 HBITMAP back to GDI+ Bitmap
	Local $hFinalBitmap = _GDIPlus_BitmapCreateFromHBITMAP($hHBITMAP)
	_WinAPI_DeleteObject($hHBITMAP)

	_GDIPlus_BitmapDispose($hNewBitmap)

	Return $hFinalBitmap ; Returns the processed, solid GDI+ Bitmap
EndFunc   ;==>__UC_GDIP_BitmapPrepareForShadow
#EndRegion ; ~~~~~~~~~~~~~ UC_Framework Shadow API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
