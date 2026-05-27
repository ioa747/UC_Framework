; https://www.autoitscript.com/forum/topic/213667-uc_framework-universal-controls/
;----------------------------------------------------------------------------------------
; Title...........: Example1.au3
; Description.....: Example of using the UC_Framework.au3
; AutoIt Version..: 3.3.18.0   Author: ioa747           Script Version: 0.0.10.0
; Note............: Testet in Windows 11 Pro 25H2       Date:22/05/2026
;----------------------------------------------------------------------------------------
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include "UC_Framework\UC_Framework.au3"

_Main()

Func _Main()
    Local $hMainGui = GUICreate("Universal Controls GUI", 580, 480, -1, -1, BitOR($WS_CLIPCHILDREN, $GUI_SS_DEFAULT_GUI))
    _UC_GUISetBkColor(0xF0F0F0, $hMainGui)

    Local $idLblTheme = GUICtrlCreateLabel("GUI Theme", 20, 10, 150, 17)

    ; === Toggles ===
    Local $idToggleTheme = _UC_Toggle_Create($hMainGui, 20, 30, 50, 25, 0, 0xF0F0F0, 0x758184, 0xD1D1D1)
    Local $idToggle1 = _UC_Toggle_Create($hMainGui, 20, 80, 50, 25, 0, 0x0094FF)
    Local $idToggle2 = _UC_Toggle_Create($hMainGui, 20, 130, 50, 25, 1, 0xFF6A00, 0x33AA00)

    ; === Sliders ===
    Local $idHLabel = GUICtrlCreateLabel("Horizontal Slider (50):", 20, 180)
    Local $idHSlider = _UC_Slider_Create($hMainGui, 20, 200, 180, 20, 0, 100, 50, 0, 0x4CD964, 0xCCCCCC, 0xFFFFFF, 4)

    Local $idVLabel = _UC_Label_Create($hMainGui, "Vertical Slider (20):", 340, 25, 20, 150, 3, 0x000000)
    Local $idVSlider = _UC_Slider_Create($hMainGui, 360, 25, 20, 150, 0, 20, 20, 1, 0x0078D7)

    ; === Buttons ===
    Local $btnClassic = _UC_Button_Create($hMainGui, "CLASSIC RECT", 220, 20, 100, 35, 0, 0x3A71B1, 0xFFFFFF)
    _UC_Set(-1, "State", 0)

    Local $btnModern = _UC_Button_Create($hMainGui, "ROUNDED CORNERS", 220, 70, 100, 35, 5, 0x3C975A, 0xFFFFFF)
    Local $btnPill = _UC_Button_Create($hMainGui, "PILL BUTTON", 220, 120, 100, 35, 30, 0xA84646, 0xFFFFFF)
    Local $btnRound1 = _UC_Button_Create($hMainGui, ChrW(59448), 220, 170, 35, 35, 34, 0xA14300, 0xFFFFFF)
    _UC_Set(-1, "Font", "Segoe Fluent Icons")
    _UC_Set(-1, "FontSize", 12)
    _UC_Set(-1, "Tooltip", "FolderOpen")
    _UC_Set(-1, "ShowTooltip", 1)

    Local $btnRound2 = _UC_Button_Create($hMainGui, "R2", 260, 170, 35, 35, 34, 0x7800AC, 0xFFFFFF)
    Local $btnRound3 = _UC_Button_Create($hMainGui, ChrW(59213), 300, 170, 35, 35, 34, 0xFF6A00, 0xFFFFFF)
    _UC_Set(-1, "Font", "Segoe Fluent Icons")
    _UC_Set(-1, "FontSize", 12)

    ; === Progressbar ===
    Local $idProgress = _UC_ProgressBar_Create($hMainGui, 20, 240, 350, 24, 0, 100, 50)
    _UC_Set(-1, "ShowPercent", True)

    ; === Radial Progressbar ===
    Local $idRadial = _UC_RadialProgress_Create($hMainGui, 400, 40, 100)
    _UC_Set(-1, "RingThickness", 12)
    _UC_Set(-1, "FontSize", 16)
    _UC_Set(-1, "Value", 50)

    ; === Links ===
    Local $Link = "https://github.com/ioa747/NetWebView2Lib"
    Local $idLink = _UC_Link_Create($hMainGui, "webview2autoit", $Link, 100, 30, 80, 20, 12)
    _UC_Set(-1, "ShowTooltip", 1)

    ; === Image ===
    Local $iWidth, $sImage = @ScriptDir & "\UC_Framework\UC\Assets\1272.png"
    Local $idImage1 = _UC_Image_Create($hMainGui, $sImage, 10, 300, 0.6)
    $iWidth = _UC_Get(-1, "Width")
    Local $idImage2 = _UC_Image_Create($hMainGui, $sImage, 10 + $iWidth, 300, 0.4)
    $iWidth += _UC_Get(-1, "Width")
    Local $idImage3 = _UC_Image_Create($hMainGui, $sImage, 10 + $iWidth, 300, 0.2)
    _UC_Set(-1, "SetFocus", 1)

    ; === HourMinute ===
    Local $idHourMinute = _UC_HourMinute_Create($hMainGui, 410, 170, 14, 35) ; 14:35 inicial

	; === Rating ===
	Local $idRating = _UC_Rating_Create($hMainGui, 400, 240, 24, 5, 3, 0)

	; === InfoBox ===
	;Local $idBox1 = _UC_InfoBox_Create($hMainGui, 20, 20, 340, 100, "EARNINGS (ANNUAL)", "$215,000", "$")

	;Local $idBox2 = _UC_InfoBox_Create($hMainGui, 380, 20, 200, 80, "TOTAL", "98,400", "£", "Segoe UI", 32, 0xE74C3C, 0xE74C3C, 0x1F1F1F, 0xE74C3C, 0xFFFFFF,6)

	Local $idBox3 = _UC_InfoBox_Create($hMainGui, 400, 270, 140, 55, "PAYED", "45k", "£", "Segoe UI" , 16, 0xE74C3C, 0xE74C3C, 0x1F1F1F, 0xE74C3C, 0xFFFFFF,6,0,0,0)

	Local $idBox4 = _UC_InfoBox_Create($hMainGui, 400, 330, 140, 55, "MONEY", "200k", "$", "Segoe UI", 34, 0x0F52BA, 0x0F52BA, 0x90D5FF, 0x0F52BA, 0x000000, 6,1,1,1)

    ; =================================================================

    ; === Timer ===
    _UC_Timer_Set($idImage3, 100, "_CallBackTimerFunction")
    _UC_Timer_Set($btnRound2, 500, "_CallBackTimerFlash")

    Local $id_UP = GUICtrlCreateDummy()
    Local $id_DOWN = GUICtrlCreateDummy()
    Local $id_UP_XL = GUICtrlCreateDummy()
    Local $id_DOWN_XL = GUICtrlCreateDummy()

    Local $aAccelKeys[4][2] = [["{UP}", $id_UP], ["{DOWN}", $id_DOWN], ["+{UP}", $id_UP_XL], ["+{DOWN}", $id_DOWN_XL]]
    GUISetAccelerators($aAccelKeys)
    GUISetState(@SW_SHOW)

    _MapCW(_UC_Get(1), "--- System Variable ---")
	ConsoleWrite("---------------------" & @CRLF)


    Local $iMsg, $iSliderXLStep, $iVal, $iTimeValue
    While 1
        $iMsg = GUIGetMsg()
        Switch $iMsg
            Case $GUI_EVENT_CLOSE
                ExitLoop

            Case $id_UP
                _UC_Slider_UpdateFromValue(Default, 1)

            Case $id_DOWN
                _UC_Slider_UpdateFromValue(Default, -1)

            Case $id_UP_XL
                $iSliderXLStep = _UC_Get(Default, "SliderXLStep")
                _UC_Slider_UpdateFromValue(Default, $iSliderXLStep)

            Case $id_DOWN_XL
                $iSliderXLStep = _UC_Get(Default, "SliderXLStep")
                _UC_Slider_UpdateFromValue(Default, -$iSliderXLStep)

            Case $idToggleTheme
                ConsoleWrite("$idToggleTheme:" & GUICtrlRead($idToggleTheme) & @CRLF)
                Local $iTxtColor, $iBkColor

                If GUICtrlRead($idToggleTheme) Then
					$iBkColor = 0x262A2B
                    $iTxtColor = 0xFFFFFF
                Else
					$iBkColor = 0xF0F0F0
                    $iTxtColor = 0x000000
                EndIf

				_UC_GUISetBkColor($iBkColor, $hMainGui)

                GUICtrlSetColor($idLblTheme, $iTxtColor)
                GUICtrlSetColor($idHLabel, $iTxtColor)
                _UC_Set($idVLabel, "Color", $iTxtColor)

				_UC_Set($idHourMinute, "BoxColor", $iBkColor)
				_UC_Set($idHourMinute, "TextColor", $iTxtColor)

                _UC_Refresh($hMainGui)

            Case $idToggle1
                ConsoleWrite("$idToggle1:" & GUICtrlRead($idToggle1) & @CRLF)
                GUISetState((GUICtrlRead($idToggle1) ? @SW_HIDE : @SW_SHOW), _UC_Get($idToggle2, "UC_hWnd"))

            Case $idToggle2
                ConsoleWrite("$idToggle2:" & GUICtrlRead($idToggle2) & @CRLF)
                _UC_Set($idHSlider, "ThumbType", GUICtrlRead($idToggle2))

            Case $idHSlider
                $iVal = GUICtrlRead($idHSlider)
                GUICtrlSetData($idHLabel, "Horizontal Slider (" & $iVal & "):")
                _UC_Set($idProgress, "Value", $iVal)
                _UC_Set($idRadial, "Value", $iVal)

            Case $idVSlider
                $iVal = GUICtrlRead($idVSlider)
                _UC_Set($idVLabel, "Text", "Vertical Slider (" & $iVal & "):")
                _UC_Set($btnPill, "CornerRadius", $iVal)

            Case $idHourMinute
                $iTimeValue = GUICtrlRead($idHourMinute)
				ConsoleWrite("$iTimeValue=" & $iTimeValue & @CRLF)

            Case $idLink
                ShellExecute(_UC_Get($idLink, "Value"))

            Case $btnClassic, $btnModern, $btnPill
                ConsoleWrite("'" & _UC_Get(Default, "Text") & "' Button Clicked!" & @CRLF)

            Case $btnRound1
                ConsoleWrite("'" & _UC_Get($btnRound1, "Tooltip") & "' Button Clicked!" & @CRLF)

            Case $btnRound2
                ConsoleWrite("'" & GUICtrlRead($btnRound2) & "' Button Clicked!" & @CRLF)
                _UC_Timer_Set($idImage3, 100, "_CallBackTimerFunction")

            Case $btnRound3
                ConsoleWrite("'" & GUICtrlRead($btnRound3) & "' Button Clicked!" & @CRLF)
				_MapCW(_UC_Get($btnRound3), "--- $btnRound3 ---")
				ConsoleWrite("---------------------" & @CRLF)

            Case $idImage1, $idImage2, $idImage3
                ConsoleWrite("'" & _UC_Get(Default, "Filename") & "'  Scale:" & _UC_Get(Default, "Scale") & @CRLF)

			Case $idRating
				ConsoleWrite("$idRating=" & GUICtrlRead($idRating) & @CRLF)
			Case $idBox3, $idBox4 ;$idBox1, $idBox2
                ConsoleWrite("$idBox=" & _UC_Get(Default, "Title") & ": " & _UC_Get(Default, "Value") & @CRLF)
        EndSwitch

    WEnd

    _UC_Destroy($hMainGui)

EndFunc   ;==>_Main

Func _CallBackTimerFunction(ByRef $mt)
    If Not MapExists($mt, "Custom") Then $mt.Custom = 3
    $mt.Custom -= 0.2
    Local $UC = _UC_Properties($mt.ControlID)
    WinMove($UC.UC_hWnd, "", Default, Default, $UC.Width * $mt.Custom, $UC.Height * $mt.Custom)
    If $mt.Custom < 0.9 Then _UC_Timer_Kill($mt.id)
EndFunc   ;==>_CallBackTimerFunction

Func _CallBackTimerFlash(ByRef $mt)
    Local $iFlash = Mod($mt.Fired, 2)
    Local $UC = _UC_Properties($mt.ControlID)
    $UC.BtnColor = ($iFlash ? 0xB200FF : 0x7800AC)
    _UC_Properties($mt.ControlID, $UC)
EndFunc   ;==>_CallBackTimerFlash
