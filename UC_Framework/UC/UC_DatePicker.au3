; UC_DatePicker.au3
#include-once
#include "Frame\UC_Frame.au3"
#include "UC_Calendar.au3"

Global $g_hUC_DatePicker_Popup = 0
Global $g_idUC_DatePicker_PopupOwner = 0
Global Const $WA_INACTIVE = 0x0000


#Region ; ~~~~~~~~~~~~~ UC DatePicker API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Func _UC_DatePicker_Create( _
        $hParent, _
        $iX, _
        $iY, _
        $iW = -1, _
        $iH = 28 _
        )

    If $iW <= 0 Then
        $iW = _UC_DatePicker_GetIdealWidth()
    EndIf

    GUISwitch($hParent)
    Local $idDummy = GUICtrlCreateDummy()

    Local $hChild = GUICreate( _
        "UC_Control_" & $idDummy, _
        $iW, $iH, $iX, $iY, _
        BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS, $WS_TABSTOP), _
        0, _
        $hParent)

    __UC_Framework_Init($hParent)

    Local $m[]
    ; Universal Properties
    $m.UC_Type = $UC_TYPE_DATEPICKER
    $m.UC_ControlID = $idDummy
    $m.UC_hWnd = $hChild
    $m.UC_hParent = $hParent
    $m.Width = $iW
    $m.Height = $iH

    ; Event Handlers (mantido o padrão do framework)
    $m["UC_WM_" & $WM_LBUTTONDOWN] = "_WM_LBUTTONDOWN"
    $m["UC_WM_" & $WM_LBUTTONUP]   = "_WM_LBUTTONUP"
    $m["UC_WM_" & $WM_MOUSEMOVE]   = "_WM_MOUSEMOVE"
    $m["UC_WM_" & $WM_SETFOCUS]    = "_WM_SETFOCUS"
    $m["UC_WM_" & $WM_SHOWWINDOW]  = "_WM_SHOWWINDOW"
    $m["UC_WM_" & $WM_PAINT]       = "_WM_PAINT"

    ; DatePicker Properties
    $m.Year   = @YEAR
    $m.Month  = @MON
    $m.Day    = @MDAY

    $m.BgColor      = 0xFFFFFF
    $m.TextColor    = 0x202020
    $m.BorderColor  = 0xC8C8C8
    $m.AccentColor  = 0x0078D4
    $m.IconColor    = 0x505050

    $m.PopupGUI    = 0
    $m.CalendarID  = 0
    $m.DropdownOpen = False

    _WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)
    _UC_Properties($idDummy, $m)
    _UC_Properties(1, "UC_LastCreatedID", $idDummy)
    _UC_Calendar_SetOnDateSelected("__UC_DatePicker_OnDateSelected")
	GUIRegisterMsg($WM_ACTIVATE, "_UC_DatePicker_WM_ACTIVATE")
    GUISwitch($hParent)
    Return $idDummy
EndFunc ;==>_UC_DatePicker_Create

; ====================== DRAW ======================
Func _UC_DatePicker_Draw($hWnd, ByRef $m)
    Local $hGraphic = _GDIPlus_GraphicsCreateFromHWND($hWnd)
    _GDIPlus_GraphicsSetSmoothingMode($hGraphic, 2)
    _GDIPlus_GraphicsSetTextRenderingHint($hGraphic, 4)

    Local $iW = $m.Width
    Local $iH = $m.Height
    If $iW <= 0 Then $iW = WinGetClientSize($hWnd)[0]
    If $iH <= 0 Then $iH = WinGetClientSize($hWnd)[1]

    Local $iBorder = $m.BorderColor
    If $m.DropdownOpen Then
        $iBorder = $m.AccentColor
    EndIf

    Local $hBrushBG = _GDIPlus_BrushCreateSolid(0xFF000000 + $m.BgColor)
    _GDIPlus_GraphicsFillRect($hGraphic, 0, 0, $iW, $iH, $hBrushBG)

    Local $hPenBorder = _GDIPlus_PenCreate(0xFF000000 + $iBorder, 1)
    _GDIPlus_GraphicsDrawRect($hGraphic, 0, 0, $iW - 1, $iH - 1, $hPenBorder)

    ; Date
    Local $sDate = StringFormat("%02d/%02d/%04d", $m.Day, $m.Month, $m.Year)
    Local $hBrushText = _GDIPlus_BrushCreateSolid(0xFF000000 + $m.TextColor)
    Local $hFormat = _GDIPlus_StringFormatCreate()
    Local $hFamily = _GDIPlus_FontFamilyCreate("Segoe UI")
    Local $hFont = _GDIPlus_FontCreate($hFamily, 10)

    Local $iTextY = Int(($iH - 16) / 2) - 2
    Local $tLayout = _GDIPlus_RectFCreate(10, $iTextY, $iW - 45, 16)
    _GDIPlus_GraphicsDrawStringEx($hGraphic, $sDate, $hFont, $tLayout, $hFormat, $hBrushText)

    ; Calendar Icon
    Local $iIconX = $iW - 24
    Local $iIconY = Int(($iH - 16) / 2) - 2
    Local $hPenIcon = _GDIPlus_PenCreate(0xFF000000 + $m.IconColor, 1)

    _GDIPlus_GraphicsDrawRect($hGraphic, $iIconX, $iIconY + 3, 16, 14, $hPenIcon)
    _GDIPlus_GraphicsDrawLine($hGraphic, $iIconX, $iIconY + 7, $iIconX + 16, $iIconY + 7, $hPenIcon)
    _GDIPlus_GraphicsDrawLine($hGraphic, $iIconX + 4, $iIconY, $iIconX + 4, $iIconY + 5, $hPenIcon)
    _GDIPlus_GraphicsDrawLine($hGraphic, $iIconX + 12, $iIconY, $iIconX + 12, $iIconY + 5, $hPenIcon)

    ; Cleanup
    _GDIPlus_FontDispose($hFont)
    _GDIPlus_FontFamilyDispose($hFamily)
    _GDIPlus_StringFormatDispose($hFormat)
    _GDIPlus_BrushDispose($hBrushBG)
    _GDIPlus_BrushDispose($hBrushText)
    _GDIPlus_PenDispose($hPenBorder)
    _GDIPlus_PenDispose($hPenIcon)
    _GDIPlus_GraphicsDispose($hGraphic)
EndFunc ;==>_UC_DatePicker_Draw

; ====================== EVENTS ======================
Func _UC_DatePicker_WM_LBUTTONDOWN($idDummy, $hWnd, $iX, $iY)
	#forceref $hWnd, $iX, $iY

    Local $m = _UC_Properties($idDummy)

    If $m.DropdownOpen Then
        _UC_DatePicker_HidePopup($idDummy)
    Else
        _UC_DatePicker_ShowPopup($idDummy)
    EndIf

EndFunc


Func _UC_DatePicker_WM_SETFOCUS($idDummy, $hWnd, $iX, $iY)
    #forceref $hWnd, $iX, $iY
    Local $m = _UC_Properties($idDummy)
    If $m.DropdownOpen Then
        _UC_DatePicker_ShowPopup($idDummy)
    EndIf
EndFunc

Func _UC_DatePicker_WM_SHOWWINDOW($idDummy, $wParam, $lParam)
	#forceref $lParam
    Local $m = _UC_Properties($idDummy)
    If $m.UC_Type <> $UC_TYPE_DATEPICKER Then Return

    If $wParam = 1 And $m.PendingInit Then
        If Not $m.GDIReady Then
            GUISetState(@SW_SHOW, $m.UC_hWnd)
        EndIf
        $m.GDIReady = True
        $m.PendingInit = False
        _UC_Properties($idDummy, $m)
        _UC_DatePicker_PostInit($idDummy)
    EndIf
EndFunc

Func _UC_DatePicker_WM_PAINT($idDummy, $hWnd)
    #forceref $idDummy
    Local $m = _UC_Properties($idDummy)
    If $m.UC_Type <> $UC_TYPE_DATEPICKER Then Return
    _UC_DatePicker_Draw($hWnd, $m)
EndFunc

; ====================== CORE ======================
Func _UC_DatePicker_PostInit($id)
    Local $m = _UC_Properties($id)
    If Not $m.GDIReady Then Return
    If IsHWnd($m.UC_hWnd) Then
        _UC_Refresh($m.UC_hWnd)
    EndIf
    $m.FirstPaintDone = True
    _UC_Properties($id, $m)
EndFunc

Func _UC_DatePicker_ShowPopup($idCtrl)
	Local $m = _UC_Properties($idCtrl)



    If Not IsMap($m) Then Return
    If $m.DropdownOpen Then Return

    If $g_hUC_DatePicker_Popup <> 0 Then
        GUIDelete($g_hUC_DatePicker_Popup)
        $g_hUC_DatePicker_Popup = 0
        $g_idUC_DatePicker_PopupOwner = 0
    EndIf

	;size
    Local $iCalW = 240
    Local $iCalH = 210


    Local $aCtrl = WinGetPos($m["UC_hWnd"])
    If @error Then Return

    Local $tPoint = DllStructCreate($tagPOINT)
    DllStructSetData($tPoint, "X", 0)
    DllStructSetData($tPoint, "Y", $aCtrl[3])

    _WinAPI_ClientToScreen($m["UC_hWnd"], $tPoint)

    Local $iX = DllStructGetData($tPoint, "X")
    Local $iY = DllStructGetData($tPoint, "Y")

    ; Create POPUP
    Local $hPopup = GUICreate( _
        "UC_DROPDOWN", _
        $iCalW, _
        $iCalH, _
        $iX, _
        $iY, _
        $WS_POPUP, _
        BitOR($WS_EX_TOOLWINDOW, $WS_EX_TOPMOST), _
        $m.UC_hWnd _
    )


    ; CALENDAR
    Local $idCal = _UC_Calendar_Create($hPopup, 0, 0, $iCalW, $iCalH)
    _UC_Calendar_SetOnDateSelected("__UC_DatePicker_OnDateSelected")



    ; STATE
    $m.PopupGUI = $hPopup
    $m.CalendarID = $idCal
    $m.DropdownOpen = True


	_UC_Calendar_SetDate($m.CalendarID, $m.Year, $m.Month, $m.Day)
	GUISetState(@SW_SHOWNOACTIVATE, $hPopup)
    _UC_Properties($idCtrl, $m)


    ; GLOBAL POPUP STATE
    $g_hUC_DatePicker_Popup = $hPopup
    $g_idUC_DatePicker_PopupOwner = $idCtrl

	;work arround to set focus to dropdown ; $btnFocuxFix =
	 GUICtrlCreateButton("", $iCalH-4, $iCalW-4, 0, 0)
	ControlClick($hPopup, "", "[CLASS:Button; INSTANCE:1]")

EndFunc


Func _UC_DatePicker_HidePopup($idCtrl)
    Local $m = _UC_Properties($idCtrl)
    If $m.PopupGUI Then GUIDelete($m.PopupGUI)
    $m.PopupGUI = 0
    $m.CalendarID = 0
    $m.DropdownOpen = False

    _UC_Properties($idCtrl, $m)

    $g_hUC_DatePicker_Popup = 0
;~     $g_idUC_DatePicker_Active = 0
EndFunc

Func _UC_DatePicker_GetIdealWidth()
    Return 120
EndFunc

; ====================== DATE FUNCTIONS ======================
Func _UC_DatePicker_GetDate($idCtrl)
    Local $m = _UC_Properties($idCtrl)
    Local $aDate[3]
    $aDate[0] = $m.Year
    $aDate[1] = $m.Month
    $aDate[2] = $m.Day
    Return $aDate
EndFunc

Func _UC_DatePicker_GetDateString($idCtrl)
    Local $m = _UC_Properties($idCtrl)
    Return StringFormat("%02d/%02d/%04d", $m.Day, $m.Month, $m.Year)
EndFunc

Func _UC_DatePicker_SetDate($idCtrl, $iYear, $iMonth, $iDay)
    Local $m = _UC_Properties($idCtrl)

    If $iYear < 1601 Then Return SetError(1, 0, False)
    If $iMonth < 1 Or $iMonth > 12 Then Return SetError(2, 0, False)
    If $iDay < 1 Or $iDay > 31 Then Return SetError(3, 0, False)

    $m.Year  = Int($iYear)
    $m.Month = Int($iMonth)
    $m.Day   = Int($iDay)

    _UC_Properties($idCtrl, $m)

    If IsHWnd($m.UC_hWnd) Then
        _UC_Refresh($m.UC_hWnd)
    EndIf

    Return True
EndFunc

Func __UC_DatePicker_OnDateSelected($idCalendar, $iYear, $iMonth, $iDay)

    Local $aAll = _UC_Properties(Default)
    If Not IsArray($aAll) Then Return

    For $i = 3 To $aAll[0]

        Local $m = $aAll[$i]

        If Not IsMap($m) Then ContinueLoop
        If Not MapExists($m, "CalendarID") Then ContinueLoop
        If $m.CalendarID <> $idCalendar Then ContinueLoop

        ; UPDATE DATA
        $m.Year  = $iYear
        $m.Month = $iMonth
        $m.Day   = $iDay


        ; Close Dropdown first (IMPORTANT)
        If $m.PopupGUI <> 0 And IsHWnd($m.PopupGUI) Then
            GUIDelete($m.PopupGUI)
        EndIf

        $m.PopupGUI = 0
        $m.CalendarID = 0
        $m.DropdownOpen = False

        ; salva estado
        _UC_Properties($i, $m)

        ;ANTI FLICKER

        Sleep(30)

        ; SAFE REDRAW
        If MapExists($m, "UC_hWnd") And IsHWnd($m.UC_hWnd) Then
            _WinAPI_RedrawWindow( _
                $m.UC_hWnd, _
                0, _
                0, _
                BitOR($RDW_INVALIDATE, $RDW_ERASE, $RDW_UPDATENOW) _
            )
        EndIf

        ExitLoop
    Next

EndFunc

Func _UC_DatePicker_WM_ACTIVATE($hWnd, $iMsg, $wParam, $lParam)
	 #forceref $iMsg, $lParam

    Local $m = _UC_Properties($g_idUC_DatePicker_PopupOwner)
    If Not IsMap($m) Then Return $GUI_RUNDEFMSG

    If $hWnd <> $m.PopupGUI Then Return $GUI_RUNDEFMSG

    ; WA_INACTIVE = 0
    If $wParam = 0 Then
        _UC_DatePicker_HidePopup($g_idUC_DatePicker_PopupOwner)
    EndIf

    Return $GUI_RUNDEFMSG
EndFunc

#EndRegion ; ~~~~~~~~~~~~~ UC DatePicker API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~