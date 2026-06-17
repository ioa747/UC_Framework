; UC_Stepper.au3
#include-once
#include "Frame\UC_Frame.au3"

#Region ; Create
Func _UC_Stepper_Create( _
        $hParent, _
        $iX, _
        $iY, _
        $iW, _
        $iH, _
        $aSteps, _
        $iCurrentStep = 0, _
        $iActiveColor = 0x0047AB, _
        $iActiveTextColor = 0x0047AB, _
        $iActiveBackColor = 0xFFC6D3E3, _
        $iCompletedColor = 0x0047AB, _
        $iCompletedTextColor = 0xFFC6D3E3, _
        $iPendingColor = 0xC0C4C7, _
        $iPendingTextColor = 0x9A9A9A, _
        $iBackColor = 0xF0F0F0, _
        $iLabelColor = 0x000000, _
        $iCircleRadius = 16, _
        $iCircleBorderRadius = 16, _
        $iLineThickness = 2, _
        $iGlyphSize = 18)

    GUISwitch($hParent)

    Local $idDummy = GUICtrlCreateDummy()

    Local $hChild = GUICreate( _
            "UC_Control_" & $idDummy, _
            $iW, _
            $iH, _
            $iX, _
            $iY, _
            BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS), _
            $WS_EX_TRANSPARENT, _
            $hParent)

    __UC_Framework_Init($hParent)

    Local $m[]

    ; ==============================================================
    ; Universal
    ; ==============================================================
    $m.UC_Type = $UC_TYPE_STEPPER
    $m.UC_ControlID = $idDummy
    $m.UC_hWnd = $hChild
    $m.UC_hParent = $hParent

    ; ==============================================================
    ; Events
    ; ==============================================================
    $m["UC_WM_" & $WM_LBUTTONDOWN] = "_WM_LBUTTONDOWN"
    $m["UC_WM_" & $WM_LBUTTONUP]   = "_WM_LBUTTONUP"
    $m["UC_WM_" & $WM_MOUSEMOVE]   = "_WM_MOUSEMOVE"


    $m.Steps       = $aSteps
    $m.CurrentStep = $iCurrentStep

    $m.Glyphs      = 0
    $m.GlyphFont   = "Segoe UI Symbol"
    $m.GlyphSize   = $iGlyphSize

    ; ==============================================================
    ; Layout
    ; ==============================================================
    $m.CircleRadius       = $iCircleRadius
    $m.CircleBorderRadius = $iCircleBorderRadius
    $m.LineThickness      = $iLineThickness

	; ==============================================================
	; Aparência
	; ==============================================================
	$m.ActiveColor        = $iActiveColor
	$m.ActiveTextColor    = $iActiveTextColor
	$m.ActiveBackColor    = $iActiveBackColor

	$m.CompletedColor     = $iCompletedColor
	$m.CompletedTextColor = $iCompletedTextColor

	$m.PendingColor       = $iPendingColor
	$m.PendingTextColor   = $iPendingTextColor

	$m.BackColor          = $iBackColor
	$m.LabelColor         = $iLabelColor


    $m.State = 1

    _WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)

    _UC_Properties($idDummy, $m)
    _UC_Properties(1, "UC_LastCreatedID", $idDummy)

    GUISwitch($hParent)

    Return $idDummy
EndFunc
#EndRegion

#Region ; Draw
Func _UC_Stepper_Draw($hWnd, ByRef $m)
    Local $aSize = WinGetClientSize($hWnd)
    Local $iW = $aSize[0]
    Local $iH = $aSize[1]
    If $iW <= 0 Or $iH <= 0 Then Return

    Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hWnd)
    Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics($iW, $iH, $hGraphics)
    Local $hBack = _GDIPlus_ImageGetGraphicsContext($hBitmap)

    _GDIPlus_GraphicsClear($hBack, BitOR(0xFF000000, $m.BackColor))
    _GDIPlus_GraphicsSetSmoothingMode($hBack, 2)
    _GDIPlus_GraphicsSetTextRenderingHint($hBack, 4)

    Local $iCount = UBound($m.Steps)
    If $iCount < 1 Then
        _GDIPlus_GraphicsDrawImage($hGraphics, $hBitmap, 0, 0)
        _GDIPlus_GraphicsDispose($hBack)
        _GDIPlus_BitmapDispose($hBitmap)
        _GDIPlus_GraphicsDispose($hGraphics)
        Return
    EndIf

    Local $iMargin = 35
    Local $iCenterY = 30
    Local $iSpacing = ($iCount > 1) ? ($iW - ($iMargin * 2)) / ($iCount - 1) : 0

    Local $rFill   = $m.CircleRadius
    Local $rBorder = $m.CircleBorderRadius
    Local $rGlyph = $rFill
	If $rBorder > $rGlyph Then $rGlyph = $rBorder

    ; === Brushes e Pens ===
    Local $hBrushCompleted = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, $m.CompletedColor))
    Local $hBrushPending   = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, $m.PendingColor))

    ; Active item background
	Local $hBrushActive = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, $m.ActiveBackColor))

    Local $hPenCompleted = _GDIPlus_PenCreate(BitOR(0xFF000000, $m.CompletedColor), $m.LineThickness)
    Local $hPenPending   = _GDIPlus_PenCreate(BitOR(0xFF000000, $m.PendingColor), $m.LineThickness)
    Local $hPenActive    = _GDIPlus_PenCreate(BitOR(0xFF000000, $m.ActiveColor), $m.LineThickness + 1)

    ; Glyphs
    Local $hBrushGlyphCompleted = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, $m.CompletedTextColor))
    Local $hBrushGlyphActive    = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, $m.ActiveTextColor))
    Local $hBrushGlyphPending  = _GDIPlus_BrushCreateSolid(BitOR(0xFFFFFFFF, $m.PendingTextColor))

    ; Labels
    Local $hBrushLabel = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, $m.LabelColor))

    ; === Fonts ===
    Local $hFamilyLabel = _GDIPlus_FontFamilyCreate("Segoe UI")
    Local $hFontLabel   = _GDIPlus_FontCreate($hFamilyLabel, 9)

    Local $hFamilyGlyph = _GDIPlus_FontFamilyCreate($m.GlyphFont)
    Local $hFontGlyph   = _GDIPlus_FontCreate($hFamilyGlyph, $m.GlyphSize, 1)

    ; === String Formats ===
    Local $hFormatLabel = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hFormatLabel, 1)

    Local $hFormatGlyph = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hFormatGlyph, 1)
    _GDIPlus_StringFormatSetLineAlign($hFormatGlyph, 1)

    For $i = 0 To $iCount - 1

        Local $x = $iMargin + ($i * $iSpacing)

        ; ==========================================================
        ; Connection
        ; ==========================================================
        If $i < $iCount - 1 Then

            Local $x2 = $iMargin + (($i + 1) * $iSpacing)

            If $i < $m.CurrentStep Then
                _GDIPlus_GraphicsDrawLine( _
                    $hBack, _
                    $x + $rBorder, _
                    $iCenterY, _
                    $x2 - $rBorder, _
                    $iCenterY, _
                    $hPenCompleted)
            Else
                _GDIPlus_GraphicsDrawLine( _
                    $hBack, _
                    $x + $rBorder, _
                    $iCenterY, _
                    $x2 - $rBorder, _
                    $iCenterY, _
                    $hPenPending)
            EndIf

        EndIf

        ; ==========================================================
        ; Circle
        ; ==========================================================
        Local $iCx = $x
        Local $iCy = $iCenterY

        If $i < $m.CurrentStep Then

            ; Fill
            _GDIPlus_GraphicsFillEllipse( _
                $hBack, _
                $iCx - $rFill, _
                $iCy - $rFill, _
                $rFill * 2, _
                $rFill * 2, _
                $hBrushCompleted)

            ; Border
            _GDIPlus_GraphicsDrawEllipse( _
                $hBack, _
                $iCx - $rBorder, _
                $iCy - $rBorder, _
                $rBorder * 2, _
                $rBorder * 2, _
                $hPenCompleted)

        ElseIf $i = $m.CurrentStep Then

            ; Fill
            _GDIPlus_GraphicsFillEllipse( _
                $hBack, _
                $iCx - $rFill, _
                $iCy - $rFill, _
                $rFill * 2, _
                $rFill * 2, _
                $hBrushActive)

            ; Border
            _GDIPlus_GraphicsDrawEllipse( _
                $hBack, _
                $iCx - $rBorder, _
                $iCy - $rBorder, _
                $rBorder * 2, _
                $rBorder * 2, _
                $hPenActive)

        Else

            ; Fill
            _GDIPlus_GraphicsFillEllipse( _
                $hBack, _
                $iCx - $rFill, _
                $iCy - $rFill, _
                $rFill * 2, _
                $rFill * 2, _
                $hBrushPending)

            ; Border
            _GDIPlus_GraphicsDrawEllipse( _
                $hBack, _
                $iCx - $rBorder, _
                $iCy - $rBorder, _
                $rBorder * 2, _
                $rBorder * 2, _
                $hPenPending)

        EndIf

        ; ==========================================================
        ; Glyph
        ; ==========================================================
        If IsArray($m.Glyphs) And $i < UBound($m.Glyphs) Then

            Local $sGlyph = $m.Glyphs[$i]

            If $sGlyph <> "" Then

                Local $tGlyphRect = _GDIPlus_RectFCreate( _
                    $iCx - $rGlyph - 1, _
                    $iCy - $rGlyph - 2, _
                    ($rGlyph * 2) + 2, _
                    ($rGlyph * 2) + 4)

                Local $hGlyphBrush

                If $i < $m.CurrentStep Then
                    $hGlyphBrush = $hBrushGlyphCompleted
                ElseIf $i = $m.CurrentStep Then
                    $hGlyphBrush = $hBrushGlyphActive
                Else
                    $hGlyphBrush = $hBrushGlyphPending
                EndIf

                _GDIPlus_GraphicsDrawStringEx( _
                    $hBack, _
                    $sGlyph, _
                    $hFontGlyph, _
                    $tGlyphRect, _
                    $hFormatGlyph, _
                    $hGlyphBrush)

            EndIf

        EndIf

        ; ==========================================================
        ; Label
        ; ==========================================================
        Local $tRect = _GDIPlus_RectFCreate($x - 60, 58, 120, 25)

        _GDIPlus_GraphicsDrawStringEx( _
            $hBack, _
            $m.Steps[$i], _
            $hFontLabel, _
            $tRect, _
            $hFormatLabel, _
            $hBrushLabel)

    Next

    ; ==============================================================
    ; Render
    ; ==============================================================
    _GDIPlus_GraphicsDrawImage($hGraphics, $hBitmap, 0, 0)

    ; ==============================================================
    ; Cleanup
    ; ==============================================================
    _GDIPlus_StringFormatDispose($hFormatLabel)
    _GDIPlus_StringFormatDispose($hFormatGlyph)

    _GDIPlus_BrushDispose($hBrushCompleted)
    _GDIPlus_BrushDispose($hBrushPending)
    _GDIPlus_BrushDispose($hBrushActive)

    _GDIPlus_BrushDispose($hBrushGlyphCompleted)
    _GDIPlus_BrushDispose($hBrushGlyphActive)
    _GDIPlus_BrushDispose($hBrushGlyphPending)

    _GDIPlus_BrushDispose($hBrushLabel)

    _GDIPlus_PenDispose($hPenCompleted)
    _GDIPlus_PenDispose($hPenPending)
    _GDIPlus_PenDispose($hPenActive)

    _GDIPlus_FontDispose($hFontGlyph)
    _GDIPlus_FontFamilyDispose($hFamilyGlyph)

    _GDIPlus_FontDispose($hFontLabel)
    _GDIPlus_FontFamilyDispose($hFamilyLabel)

    _GDIPlus_GraphicsDispose($hBack)
    _GDIPlus_BitmapDispose($hBitmap)
    _GDIPlus_GraphicsDispose($hGraphics)
EndFunc
#EndRegion

#Region ; Control
Func _UC_Stepper_SetCurrentStep($idControl, $iStep)
    Local $m = _UC_Properties($idControl)
    $m.CurrentStep = $iStep
    _UC_Properties($idControl, $m)
    _WinAPI_InvalidateRect($m.UC_hWnd, 0, True)
EndFunc

Func _UC_Stepper_Next($idControl)
    Local $m = _UC_Properties($idControl)
    If $m.CurrentStep < UBound($m.Steps) - 1 Then
        $m.CurrentStep += 1
        _UC_Properties($idControl, $m)
        _WinAPI_InvalidateRect($m.UC_hWnd, 0, True)
    EndIf
EndFunc

Func _UC_Stepper_Previous($idControl)
    Local $m = _UC_Properties($idControl)
    If $m.CurrentStep > 0 Then
        $m.CurrentStep -= 1
        _UC_Properties($idControl, $m)
        _WinAPI_InvalidateRect($m.UC_hWnd, 0, True)
    EndIf
EndFunc

Func _UC_Stepper_SetGlyphs($idControl, $aGlyphs)
    Local $m = _UC_Properties($idControl)
    $m.Glyphs = $aGlyphs
    _UC_Properties($idControl, $m)
    _WinAPI_InvalidateRect($m.UC_hWnd, 0, True)
EndFunc
#EndRegion