; UC_DateCalendar.au3
#include-once
#include <Date.au3>
#include <WinAPILocale.au3>
#include <GDIPlus.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#include "Frame\UC_Frame.au3"

Global Const $UC_CAL_GRID_Y = 75
Global Const $UC_CAL_CELL_H = 34
Global Const $LOCALE_RETURN_GENITIVE_NAMES = 0x10000000

Global $g_fCalendar_OnDateSelected = ""


Func _UC_Calendar_Create($hParent, $iX, $iY, $iW = 280, $iH = 240)

	GUISwitch($hParent)

	Local $idDummy = GUICtrlCreateDummy()

	Local $hChild = GUICreate( _
			"UC_Control_" & $idDummy, _
			$iW, _
			$iH, _
			$iX, _
			$iY, _
			BitOR($WS_CHILD, $WS_VISIBLE, $WS_CLIPSIBLINGS, $WS_TABSTOP), _
			$WS_EX_TRANSPARENT, _
			$hParent)

	__UC_Framework_Init($hParent)

	Local $m[]


	$m.UC_Type = $UC_TYPE_CALENDAR
	$m.UC_ControlID = $idDummy
	$m.UC_hWnd = $hChild
	$m.UC_hParent = $hParent
	$m.WeekDays = _UC_Calendar_GetWeekDayNames()


	$m.Width = $iW
	$m.Height = $iH

	; EVENT
	$m["UC_WM_" & $WM_LBUTTONDOWN] = "_WM_LBUTTONDOWN"
	$m["UC_WM_" & $WM_LBUTTONUP] = "_WM_LBUTTONUP"
	$m["UC_WM_" & $WM_MOUSEMOVE] = "_WM_MOUSEMOVE"
	$m["UC_WM_" & $WM_SETFOCUS] = "_WM_SETFOCUS"

	$m.Year  = @YEAR
	$m.Month = @MON
	$m.Day   = @MDAY


	$m.SelectedYear = @YEAR
	$m.SelectedMonth = @MON
	$m.SelectedDay = @MDAY


	$m.State = 1
	$m.Hover = False
	$m.HoverDay = 0


	$m.BgColor = 0xFFFFFF
	$m.TextColor = 0x202020
	$m.HeaderTextColor = 0xFFFFFF
	$m.BorderColor = 0xC8C8C8
	$m.GridColor = 0xE5E5E5
	$m.HeaderColor = 0x0078D4
	$m.AccentColor = 0x0078D4
	$m.TodayColor = 0xFF6A00
	$m.HoverColor = 0xE8F2FF

	$m.FirstDayOfWeek = 0


	; CALLBACKS
	$m.OnDateChange = ""

	; CACHE LAYOUT
	$m.HeaderHeight = 36
	$m.FooterHeight = 32
	$m.WeekHeaderHeight = 26

	$m.NavButtonWidth = 30

	$m.CellWidth = 0
	$m.CellHeight = 0
	$m.FooterHeight = 32

	; REGISTER
	_WinAPI_SetProp($hChild, "UC_ControlID", $idDummy)

	_UC_Properties($idDummy, $m)
	_UC_Properties(1, "UC_LastCreatedID", $idDummy)
	_WinAPI_RedrawWindow($hChild, 0, 0, BitOR($RDW_INVALIDATE, $RDW_UPDATENOW, $RDW_ERASE))
	GUISwitch($hParent)

	_UC_Calendar_SetOnDateSelected("__UC_DatePicker_OnDateSelected")
	Return $idDummy

EndFunc   ;==>_UC_Calendar_Create

Func _UC_Calendar_IsLeapYear($iYear)

	If Mod($iYear, 400) = 0 Then Return True
	If Mod($iYear, 100) = 0 Then Return False
	If Mod($iYear, 4) = 0 Then Return True

	Return False

EndFunc

Func _UC_Calendar_GetDaysInMonth($iYear, $iMonth)

	Switch $iMonth

		Case 1, 3, 5, 7, 8, 10, 12
			Return 31

		Case 4, 6, 9, 11
			Return 30

		Case 2
			If _UC_Calendar_IsLeapYear($iYear) Then
				Return 29
			Else
				Return 28
			EndIf

	EndSwitch

	Return 30

EndFunc

Func _UC_Calendar_SetDate($idCtrl, $iYear, $iMonth, $iDay)

    Local $m = _UC_Properties($idCtrl)

    $m.Year  = $iYear
    $m.Month = $iMonth
    $m.Day   = $iDay

    $m.SelectedYear  = $iYear
    $m.SelectedMonth = $iMonth
    $m.SelectedDay   = $iDay

    _UC_Properties($idCtrl, $m)

    _UC_Calendar_RequestRedraw($m.UC_hWnd)

    Return True

EndFunc

Func _UC_Calendar_GetDate($idCtrl)

    Local $m = _UC_Properties($idCtrl)

    Local $aDate[3]

    $aDate[0] = $m.SelectedYear
    $aDate[1] = $m.SelectedMonth
    $aDate[2] = $m.SelectedDay

    Return $aDate

EndFunc

Func _UC_Calendar_GetDateString($idCtrl)

    Local $m = _UC_Properties($idCtrl)

    Return StringFormat("%02d/%02d/%04d", $m.SelectedDay, $m.SelectedMonth, $m.SelectedYear)

EndFunc

Func _UC_Calendar_NextMonth($idCtrl)

    Local $m = _UC_Properties($idCtrl)

    $m.Month += 1

    If $m.Month > 12 Then
        $m.Month = 1
        $m.Year += 1
    EndIf

    _UC_Properties($idCtrl, $m)
    _UC_Calendar_RequestRedraw($m.UC_hWnd)

EndFunc

Func _UC_Calendar_PrevMonth($idCtrl)

    Local $m = _UC_Properties($idCtrl)

    $m.Month -= 1

    If $m.Month < 1 Then
        $m.Month = 12
        $m.Year -= 1
    EndIf

    _UC_Properties($idCtrl, $m)
    _UC_Calendar_RequestRedraw($m.UC_hWnd)

EndFunc

Func _UC_Calendar_WM_LBUTTONUP($idCtrl, $hWnd, $iX, $iY)
	#forceref $hWnd

    Local $m = _UC_Properties($idCtrl)

    ; HEAD BUTTONS
    If $iY <= 40 Then

        ; << PREVIOUS YEAR
        If $iX >= 0 And $iX <= 28 Then
            _UC_Calendar_PrevYear($idCtrl)
            Return
        EndIf

        ; < PREVIOUS MONTH
        If $iX >= 30 And $iX <= 55 Then
            _UC_Calendar_PrevMonth($idCtrl)
            Return
        EndIf

        ; > NEXT MONTH
        If $iX >= ($m.Width - 55) And _
           $iX <= ($m.Width - 30) Then

            _UC_Calendar_NextMonth($idCtrl)
            Return
        EndIf

        ; >> NEXT YEAR
        If $iX >= ($m.Width - 28) Then
            _UC_Calendar_NextYear($idCtrl)
            Return
        EndIf

    EndIf

    ; TODAY BUTTON
    Local $iBtnW = 70
    Local $iBtnH = 22

    Local $iBtnX = Int(($m.Width - $iBtnW) / 2)
    Local $iBtnY = $m.Height - 28

    If $iX >= $iBtnX And _
       $iX <= ($iBtnX + $iBtnW) And _
       $iY >= $iBtnY And _
       $iY <= ($iBtnY + $iBtnH) Then

        $m.Year = @YEAR
        $m.Month = @MON
        $m.Day = @MDAY

        $m.SelectedYear = @YEAR
        $m.SelectedMonth = @MON
        $m.SelectedDay = @MDAY

        _UC_Properties($idCtrl, $m)

        _UC_Calendar_TriggerChange($idCtrl, $m)


		; NOTIFY DatePicker
		If $g_fCalendar_OnDateSelected <> "" Then

			Call( _
				$g_fCalendar_OnDateSelected, _
				$idCtrl, _
				$m.SelectedYear, _
				$m.SelectedMonth, _
				$m.SelectedDay)

			If @error Then
				MsgBox(16, "ERRO", _
					"Falha ao chamar:" & @CRLF & _
					$g_fCalendar_OnDateSelected & @CRLF & _
					"@error=" & @error)
			EndIf

		EndIf

        _UC_Calendar_RequestRedraw($m.UC_hWnd)

        Return
    EndIf


    ;DAY SELECTION
    Local $iDay = _UC_Calendar_GetDayFromPoint($m, $iX, $iY)

    If $iDay < 1 Then Return


    If $m.SelectedDay = $iDay And _
       $m.SelectedMonth = $m.Month And _
       $m.SelectedYear = $m.Year Then Return

    $m.SelectedDay = $iDay
    $m.SelectedMonth = $m.Month
    $m.SelectedYear = $m.Year


    $m.Day = $iDay

	_UC_Properties($idCtrl, $m)
	_UC_Calendar_TriggerChange($idCtrl, $m)

	If $g_fCalendar_OnDateSelected <> "" Then

		Call( _
			$g_fCalendar_OnDateSelected, _
			$idCtrl, _
			$m.SelectedYear, _
			$m.SelectedMonth, _
			$m.SelectedDay)

	EndIf

	_UC_Calendar_RequestRedraw($m.UC_hWnd)
EndFunc

Func _UC_Calendar_GetStartOffset($m)
	Local $iFirstWeekday = _DateToDayOfWeek($m.Year, $m.Month, 1) - 1
	Return Mod(($iFirstWeekday - $m.FirstDayOfWeek + 7), 7)
EndFunc

Func _UC_Calendar_GetWeekIndex($iYear, $iMonth, $iDay, $iFirstDayOfWeek)

	; _DateToDayOfWeek: 0=Sunday ... 6=Saturday
	Local $iWD = _DateToDayOfWeek($iYear, $iMonth, $iDay) - 1
	Return Mod(($iWD - $iFirstDayOfWeek + 7), 7)

EndFunc

Func _UC_Calendar_GetFirstWeekday($iYear, $iMonth)
    Return _DateToDayOfWeek($iYear, $iMonth, 1)
EndFunc

Func _UC_Calendar_NormalizeWeekday($iWeekday, $iFirstDayOfWeek)

    Return Mod(($iWeekday - $iFirstDayOfWeek + 7), 7)

EndFunc

Func _UC_Calendar_GetDayFromPoint(ByRef $m, $iX, $iY)
    Return _UC_Calendar_HitTest($m, $iX, $iY)
EndFunc

Func _UC_Calendar_SelectFromPoint($idCtrl, $iX, $iY)

    Local $m = _UC_Properties($idCtrl)

    Local $iDay = _UC_Calendar_GetDayFromPoint($m, $iX, $iY)
    If $iDay = -1 Then Return False

    If $m.SelectedDay = $iDay And _
       $m.SelectedMonth = $m.Month And _
       $m.SelectedYear = $m.Year Then Return True

    $m.SelectedDay = $iDay
	$m.SelectedMonth = $m.Month
	$m.SelectedYear = $m.Year

	$m.Day   = $iDay
	$m.Month = $m.SelectedMonth
	$m.Year  = $m.SelectedYear

    _UC_Properties($idCtrl, $m)

    _UC_Calendar_TriggerChange($idCtrl, $m)
    _UC_Calendar_RequestRedraw($m.UC_hWnd)

    Return True

EndFunc

Func _UC_Calendar_TriggerChange($idCtrl, $m)

    If $m.OnDateChange = "" Then Return

    Call($m.OnDateChange, _
        $idCtrl, _
        $m.SelectedYear, _
        $m.SelectedMonth, _
        $m.SelectedDay)

EndFunc

Func _UC_Calendar_UpdateHover($idCtrl, $iX, $iY)

    Local $m = _UC_Properties($idCtrl)

    Local $iDay = _UC_Calendar_HitTest($m, $iX, $iY)

    If $iDay = $m.HoverDay Then Return

    $m.HoverDay = $iDay

    _UC_Properties($idCtrl, $m)

    _UC_Calendar_RequestRedraw($m.UC_hWnd)

EndFunc

Func _UC_Calendar_GetCellRect($m, $iRow, $iCol)

    Local $mtr = _UC_Calendar_GetMetrics($m)

    Local $iCellW = $mtr[0]
    Local $iCellH = $mtr[1]
    Local $iStartY = $mtr[2]

    Local $x = $iCol * $iCellW
    Local $y = $iStartY + ($iRow * $iCellH)

    Local $r[4]
    $r[0] = $x
    $r[1] = $y
    $r[2] = $iCellW
    $r[3] = $iCellH

    Return $r

EndFunc

Func _UC_Calendar_RequestRedraw($hWnd)
    _WinAPI_RedrawWindow($hWnd)
EndFunc

Func _UC_Calendar_StartDrag(ByRef $m, $iDay)

    $m.Dragging = True
    $m.DragStartDay = $iDay
    $m.DragEndDay = $iDay

EndFunc

Func _UC_Calendar_UpdateDrag(ByRef $m, $iDay)

    If Not $m.Dragging Then Return
    $m.DragEndDay = $iDay

EndFunc

Func _UC_Calendar_EndDrag(ByRef $m)
    $m.Dragging = False
EndFunc

Func _UC_Calendar_GetLayout()

    Local $aLayout[3]

    $aLayout[0] = $UC_CAL_GRID_Y
    $aLayout[1] = $UC_CAL_CELL_H
    $aLayout[2] = 7

    Return $aLayout

EndFunc

Func _UC_Calendar_HandleMouseMove($idCtrl, $iX, $iY)

    Local $m = _UC_Properties($idCtrl)

    _UC_Calendar_UpdateHover($idCtrl, $iX, $iY)

    If $m.Dragging Then
        Local $iDay = _UC_Calendar_GetDayFromPoint($m, $iX, $iY)
        _UC_Calendar_UpdateDrag($m, $iDay)
    EndIf

EndFunc

Func _UC_Calendar_HandleClick($idCtrl, $iX, $iY)

    Local $m = _UC_Properties($idCtrl)

    Local $iDay = _UC_Calendar_GetDayFromPoint($m, $iX, $iY)

    If $iDay = -1 Then Return False

    _UC_Calendar_SelectFromPoint($idCtrl, $iX, $iY)

    _UC_Calendar_StartDrag($m, $iDay)

    Return True

EndFunc

Func _UC_Calendar_HandleRelease($idCtrl, $iX, $iY)
	#forceref $iX, $iY

    Local $m = _UC_Properties($idCtrl)

    If $m.Dragging Then
        _UC_Calendar_EndDrag($m)
    EndIf

EndFunc

Func _UC_Calendar_GetMetrics(ByRef $m)

    Local $t[4]

    Local $iHeaderH = 28
    Local $iWeekH   = 20
    Local $iFooterH = 26

    ;Cell size
    $t[0] = Int($m.Width / 7)

    ; height for 6 weeks
    Local $iGridHeight = _
        $m.Height - _
        $iHeaderH - _
        $iWeekH - _
        $iFooterH

    $t[1] = Int($iGridHeight / 6)

    $t[2] = $iHeaderH + $iWeekH

    $t[3] = _UC_Calendar_GetStartOffset($m)

    Return $t

EndFunc

Func _UC_Calendar_HitTest(ByRef $m, $iX, $iY)

    Local $mtr = _UC_Calendar_GetMetrics($m)

    Local $iCellW  = $mtr[0]
    Local $iCellH  = $mtr[1]
    Local $iStartY = $mtr[2]
    Local $iOffset = $mtr[3]

    ; out grid
    If $iY < $iStartY Then Return -1

    ; bellow grid
    If $iY >= ($iStartY + ($iCellH * 6)) Then Return -1

    ;  horizontal out
    If $iX < 0 Or $iX >= ($iCellW * 7) Then Return -1

    Local $iCol = Int($iX / $iCellW)
    Local $iRow = Int(($iY - $iStartY) / $iCellH)

    If $iCol < 0 Or $iCol > 6 Then Return -1
    If $iRow < 0 Or $iRow > 5 Then Return -1

    Local $iIndex = ($iRow * 7) + $iCol
    Local $iDay = $iIndex - $iOffset + 1

    Local $iDaysInMonth = _UC_Calendar_GetDaysInMonth($m.Year, $m.Month)

    If $iDay < 1 Then Return -1
    If $iDay > $iDaysInMonth Then Return -1

    Return $iDay

EndFunc

Func _UC_Calendar_HitTestMonth($iX, $iY, $iW, $iH)

    Local $iCols = 3
    Local $iRows = 4

    Local $iCellW = $iW / $iCols
    Local $iCellH = ($iH - 50) / $iRows

    Local $col = Int($iX / $iCellW)
    Local $row = Int(($iY - 50) / $iCellH)

    If $col < 0 Or $col > 2 Then Return -1
    If $row < 0 Or $row > 3 Then Return -1

    Local $i = ($row * 3) + $col + 1

    If $i < 1 Or $i > 12 Then Return -1

    Return $i

EndFunc

Func _UC_Calendar_Draw($hWnd, ByRef $m)

    Local $hGfx = _GDIPlus_GraphicsCreateFromHWND($hWnd)

    Local $iW = $m.Width
    Local $iH = $m.Height

    ; LAYOUT
    Local $iHeaderH = 30
    Local $iWeekH = 20
    Local $iFooterH = 26

    Local $iStartY = $iHeaderH + $iWeekH

    Local $iCellW = Int($iW / 7)
    Local $iCellH = Int(($iH - $iStartY - $iFooterH) / 6)

    ; BACKGROUND
    Local $hBG = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
    _GDIPlus_GraphicsFillRect($hGfx, 0, 0, $iW, $iH, $hBG)
    _GDIPlus_BrushDispose($hBG)

    ; FONT
    Local $hFamily = _GDIPlus_FontFamilyCreate("Segoe UI")

    Local $hFontTitle = _GDIPlus_FontCreate($hFamily, 10)
    Local $hFontDays = _GDIPlus_FontCreate($hFamily, 8)
    Local $hFontBtn = _GDIPlus_FontCreate($hFamily, 9)

    Local $hBrushText = _GDIPlus_BrushCreateSolid(0xFF202020)
    Local $hBrushWhite = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)

    Local $hPenGrid = _GDIPlus_PenCreate(0xFFE6E6E6, 1)

    Local $hFormat = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hFormat, 1)

    ; HEADER
    Local $sTitle = _UC_Calendar_GetMonthName($m.Month) & " " & $m.Year

    _GDIPlus_GraphicsDrawStringEx($hGfx, $sTitle, $hFontTitle, _GDIPlus_RectFCreate(0, 8, $iW, 24), $hFormat, $hBrushText)

    ; << PREVIOUS YEAR
    _UC_Calendar_DrawArrow($hGfx, 2, 10, 14, 0)
	_UC_Calendar_DrawArrow($hGfx, 12, 10, 14, 0)

    ; < PREVIOUS MONTH
    _UC_Calendar_DrawArrow($hGfx, 36, 10, 14, 0)

    ; > NEXT MONTH
    _UC_Calendar_DrawArrow($hGfx, $iW - 50, 10, 14, 1)

    ; >> NEXT YEAR
    _UC_Calendar_DrawArrow($hGfx, $iW - 30, 10, 14, 1)
	_UC_Calendar_DrawArrow($hGfx, $iW - 20, 10, 14, 1)

    ; WEEEKDAYS
    Local $hWeekBG = _GDIPlus_BrushCreateSolid(0xFF254768)
    _GDIPlus_GraphicsFillRect($hGfx, 0, $iHeaderH, $iW, $iWeekH, $hWeekBG)
    _GDIPlus_BrushDispose($hWeekBG)


    For $i = 0 To 6

		Local $iIndex = Mod($i + $m.FirstDayOfWeek, 7)

		Local $sDay = $m.WeekDays[$iIndex]

		_GDIPlus_GraphicsDrawStringEx( _
			$hGfx, _
			$sDay, _
			$hFontDays, _
			_GDIPlus_RectFCreate( _
				$i * $iCellW, _
				$iHeaderH + 2, _
				$iCellW, _
				20), _
			$hFormat, _
			$hBrushWhite)

	Next

    ; DAYS OF MONTH
    Local $iDaysInMonth = _UC_Calendar_GetDaysInMonth($m.Year, $m.Month)
    Local $iOffset = _UC_Calendar_GetStartOffset($m)

    For $iIndex = 0 To 41

        Local $iRow = Int($iIndex / 7)
        Local $iCol = Mod($iIndex, 7)

        Local $x = $iCol * $iCellW
        Local $y = $iStartY + ($iRow * $iCellH)

        _GDIPlus_GraphicsDrawRect($hGfx, $x, $y, $iCellW, $iCellH, $hPenGrid)

        Local $iDay = $iIndex - $iOffset + 1

        If $iDay < 1 Or $iDay > $iDaysInMonth Then ContinueLoop

        ; HOVER
        If $m.HoverDay = $iDay Then

            Local $hHover = _GDIPlus_BrushCreateSolid(0xFFF0F7FF)

            _GDIPlus_GraphicsFillRect($hGfx, $x, $y, $iCellW, $iCellH, $hHover)

            _GDIPlus_BrushDispose($hHover)

        EndIf

        ; TODAY OR RESET
        If $m.Year = @YEAR And $m.Month = @MON And $iDay = @MDAY Then

            Local $hToday = _GDIPlus_BrushCreateSolid(0xFFACE5EE)
            _GDIPlus_GraphicsFillRect($hGfx, $x, $y, $iCellW, $iCellH, $hToday)
            _GDIPlus_BrushDispose($hToday)

        EndIf

        ; SELECTED
        If $m.SelectedYear = $m.Year And $m.SelectedMonth = $m.Month And $m.SelectedDay = $iDay Then

            Local $hSel = _GDIPlus_BrushCreateSolid(0xFF6B9ACA)
            _GDIPlus_GraphicsFillRect($hGfx, $x, $y, $iCellW, $iCellH, $hSel)
            _GDIPlus_BrushDispose($hSel)

        EndIf

        _GDIPlus_GraphicsDrawStringEx($hGfx, String($iDay), $hFontDays, _GDIPlus_RectFCreate($x, $y + 4, $iCellW, $iCellH - 4), $hFormat, $hBrushText)

    Next

    ; BUTTON TODAY
    Local $iBtnW = 70
    Local $iBtnH = 22
    Local $iBtnX = Int(($iW - $iBtnW) / 2)
    Local $iBtnY = $iH - 28
    Local $hBtn = _GDIPlus_BrushCreateSolid(0xFF254768)

    _GDIPlus_GraphicsFillRect($hGfx, $iBtnX, $iBtnY, $iBtnW, $iBtnH, $hBtn)
    _GDIPlus_BrushDispose($hBtn)


	;RELOAD ICON
	Local $iIconSize = 14

	Local $iIconX = $iBtnX + (($iBtnW - $iIconSize) / 2)
	Local $iIconY = $iBtnY + (($iBtnH - $iIconSize) / 2)

	_UC_Calendar_DrawReloadIcon($hGfx, $iIconX, $iIconY, $iIconSize)


	; BORDER
	Local $hPenBorder = _GDIPlus_PenCreate(0xFFD0D0D0, 1)

	_GDIPlus_GraphicsDrawRect( _
		$hGfx, _
		0, _
		0, _
		$m.Width - 1, _
		$m.Height - 1, _
		$hPenBorder)

	_GDIPlus_PenDispose($hPenBorder)

	; CLEANUP
	_GDIPlus_PenDispose($hPenGrid)
	_GDIPlus_BrushDispose($hBrushText)
	_GDIPlus_BrushDispose($hBrushWhite)
	_GDIPlus_FontDispose($hFontTitle)
	_GDIPlus_FontDispose($hFontDays)
	_GDIPlus_FontDispose($hFontBtn)
	_GDIPlus_FontFamilyDispose($hFamily)
	_GDIPlus_StringFormatDispose($hFormat)
	_GDIPlus_GraphicsDispose($hGfx)

EndFunc

Func _UC_Calendar_DrawMonthPicker($hGfx, ByRef $m, $iW, $iH, $hFont, $hBrushText, $hFormat)

    Local Static $aMonths = ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]
    Local $iCols = 3
    Local $iRows = 4
    Local $iCellW = $iW / $iCols
    Local $iCellH = ($iH - 50) / $iRows
    Local $iStartY = 50

    ; BACKGROUND
    Local $hBG = _GDIPlus_BrushCreateSolid(0xFFF9F9F9)
    _GDIPlus_GraphicsFillRect($hGfx, 0, 40, $iW, $iH - 40, $hBG)
    _GDIPlus_BrushDispose($hBG)

    ; TITLE
    _GDIPlus_GraphicsDrawStringEx( _
        $hGfx, _
        String($m.Year), _
        _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), 14), _
        _GDIPlus_RectFCreate(0, 8, $iW, 30), _
        $hFormat, _
        $hBrushText)

    For $i = 0 To 11

        Local $row = Int($i / 3)
        Local $col = Mod($i, 3)

        Local $x = $col * $iCellW
        Local $y = $iStartY + ($row * $iCellH)

        If ($i + 1) = $m.Month Then
            Local $hSel = _GDIPlus_BrushCreateSolid(0x220A74DA)
            _GDIPlus_GraphicsFillRect($hGfx, $x + 5, $y + 5, $iCellW - 10, $iCellH - 10, $hSel)
            _GDIPlus_BrushDispose($hSel)
        EndIf

        Local $tRect = _GDIPlus_RectFCreate($x, $y + 10, $iCellW, 20)

        _GDIPlus_GraphicsDrawStringEx($hGfx, $aMonths[$i], $hFont, $tRect, $hFormat, $hBrushText)
    Next

EndFunc

Func _UC_Calendar_PrevYear($idCtrl)

    Local $m = _UC_Properties($idCtrl)

    $m.Year -= 1

    Local $iMaxDay = _
        _UC_Calendar_GetDaysInMonth($m.Year, $m.Month)

    If $m.Day > $iMaxDay Then
        $m.Day = $iMaxDay
    EndIf

    If $m.SelectedYear = ($m.Year + 1) Then
        $m.SelectedYear = $m.Year

        If $m.SelectedDay > $iMaxDay Then
            $m.SelectedDay = $iMaxDay
        EndIf
    EndIf

    _UC_Properties($idCtrl, $m)

    _UC_Calendar_RequestRedraw($m.UC_hWnd)

EndFunc

Func _UC_Calendar_NextYear($idCtrl)

    Local $m = _UC_Properties($idCtrl)

    $m.Year += 1

    Local $iMaxDay = _
        _UC_Calendar_GetDaysInMonth($m.Year, $m.Month)

    If $m.Day > $iMaxDay Then
        $m.Day = $iMaxDay
    EndIf

    If $m.SelectedYear = ($m.Year - 1) Then
        $m.SelectedYear = $m.Year

        If $m.SelectedDay > $iMaxDay Then
            $m.SelectedDay = $iMaxDay
        EndIf
    EndIf

    _UC_Properties($idCtrl, $m)
    _UC_Calendar_RequestRedraw($m.UC_hWnd)

EndFunc

Func _UC_Calendar_SelectToday($idCtrl)

    Local $m = _UC_Properties($idCtrl)

    $m.Year  = @YEAR
    $m.Month = @MON
    $m.Day   = @MDAY

    $m.SelectedYear  = @YEAR
    $m.SelectedMonth = @MON
    $m.SelectedDay   = @MDAY

    _UC_Properties($idCtrl, $m)

    _UC_Calendar_TriggerChange($idCtrl, $m)
    _UC_Calendar_RequestRedraw($m.UC_hWnd)

EndFunc

Func _UC_Calendar_GetLocaleInfo($iLCType)

    Local $aCall = DllCall("kernel32.dll", "int", "GetLocaleInfoW", "dword", 0x0400, "dword", $iLCType, "wstr", "", "int", 260)

    If @error Then Return ""

    Return $aCall[3]

EndFunc

Func _UC_Calendar_GetMonthName($iMonth)

    Local $aLCType[12] = [ _
        $LOCALE_SMONTHNAME1, _
        $LOCALE_SMONTHNAME2, _
        $LOCALE_SMONTHNAME3, _
        $LOCALE_SMONTHNAME4, _
        $LOCALE_SMONTHNAME5, _
        $LOCALE_SMONTHNAME6, _
        $LOCALE_SMONTHNAME7, _
        $LOCALE_SMONTHNAME8, _
        $LOCALE_SMONTHNAME9, _
        $LOCALE_SMONTHNAME10, _
        $LOCALE_SMONTHNAME11, _
        $LOCALE_SMONTHNAME12]

    Return _UC_Calendar_Capitalize(_UC_Calendar_GetLocaleInfo(BitOR($aLCType[$iMonth - 1], $LOCALE_RETURN_GENITIVE_NAMES)))
EndFunc

Func _UC_Calendar_GetWeekDayNames()

    Local $aDays[7]

    $aDays[0] = _UC_Calendar_GetShortDayName(0)
    $aDays[1] = _UC_Calendar_GetShortDayName(1)
    $aDays[2] = _UC_Calendar_GetShortDayName(2)
    $aDays[3] = _UC_Calendar_GetShortDayName(3)
    $aDays[4] = _UC_Calendar_GetShortDayName(4)
    $aDays[5] = _UC_Calendar_GetShortDayName(5)
    $aDays[6] = _UC_Calendar_GetShortDayName(6)

    Return $aDays

EndFunc

Func _UC_Calendar_GetShortDayName($iDay)

    Local $sName = _WinAPI_GetLocaleInfo( _
        $LOCALE_USER_DEFAULT, _
        $LOCALE_SABBREVDAYNAME1 + Mod($iDay + 6, 7))

    If StringLen($sName) > 4 Then _
        $sName = StringLeft($sName, 3)

    Return _UC_Calendar_Capitalize($sName)

EndFunc

Func _UC_Calendar_Capitalize($sText)

    If $sText = "" Then Return ""

    Return StringUpper(StringLeft($sText, 1)) & StringMid($sText, 2)

EndFunc

Func _UC_Calendar_DrawArrow($hGfx, $iX, $iY, $iSize, $iDirection, $iColor = 0xFF404040)

    Local $hPen = _GDIPlus_PenCreate($iColor, 1.8)

    _GDIPlus_GraphicsSetSmoothingMode($hGfx, 2)

    Local $cx = $iX + ($iSize / 2)
    Local $cy = $iY + ($iSize / 2)

    Switch $iDirection

        ; <
        Case 0

            _GDIPlus_GraphicsDrawLine( _
                $hGfx, _
                $cx + ($iSize * 0.25), _
                $cy - ($iSize * 0.35), _
                $cx - ($iSize * 0.25), _
                $cy, _
                $hPen)

            _GDIPlus_GraphicsDrawLine( _
                $hGfx, _
                $cx - ($iSize * 0.25), _
                $cy, _
                $cx + ($iSize * 0.25), _
                $cy + ($iSize * 0.35), _
                $hPen)

        ; >
        Case 1

            _GDIPlus_GraphicsDrawLine( _
                $hGfx, _
                $cx - ($iSize * 0.25), _
                $cy - ($iSize * 0.35), _
                $cx + ($iSize * 0.25), _
                $cy, _
                $hPen)

            _GDIPlus_GraphicsDrawLine( _
                $hGfx, _
                $cx + ($iSize * 0.25), _
                $cy, _
                $cx - ($iSize * 0.25), _
                $cy + ($iSize * 0.35), _
                $hPen)

    EndSwitch

    _GDIPlus_PenDispose($hPen)

EndFunc

Func _UC_Calendar_DrawReloadIcon($hGfx, $iX, $iY, $iSize, $iColor = 0xFFFFFFFF)

    Local $hPen = _GDIPlus_PenCreate($iColor, 2)


    _GDIPlus_PenSetStartCap($hPen, 2)
    _GDIPlus_PenSetEndCap($hPen, 2)

    Local $r = $iSize

    _GDIPlus_GraphicsDrawArc( _
        $hGfx, _
        $iX, _
        $iY, _
        $r, _
        $r, _
        25, _
        300, _
        $hPen)


    Local $x1 = $iX + ($r * 0.72)
    Local $y1 = $iY + ($r * 0.30)

    Local $x2 = $iX + ($r * 0.95)
    Local $y2 = $iY + ($r * 0.30)

    Local $x3 = $iX + ($r * 0.95)
    Local $y3 = $iY + ($r * 0.05)


    _GDIPlus_GraphicsDrawLine( _
        $hGfx, _
        $x1, _
        $y1, _
        $x2, _
        $y2, _
        $hPen)

    _GDIPlus_GraphicsDrawLine( _
        $hGfx, _
        $x2, _
        $y1, _
        $x3, _
        $y3, _
        $hPen)

    _GDIPlus_PenDispose($hPen)

EndFunc



Func _UC_Calendar_SetOnDateSelected($sFunc)

    $g_fCalendar_OnDateSelected = $sFunc

EndFunc
