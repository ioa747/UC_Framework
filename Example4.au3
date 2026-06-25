; https://www.autoitscript.com/forum/topic/213667-uc_framework-universal-controls/
;----------------------------------------------------------------------------------------
; Title...........: Example4.au3
; Description.....: Example of using the UC_Framework.au3
; AutoIt Version..: 3.3.18.0   Author: ioa747           Script Version: 0.0.13.3
; Note............: Testet in Windows 11 Pro 25H2       Date:22/05/2026
; Link............: https://github.com/ioa747/UC_Framework
;----------------------------------------------------------------------------------------
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include "UC_Framework\UC_Framework.au3"

;~ $g_UC_DebugInfo = 1

_Main()

Func _Main()
    Local $hMainGui = GUICreate("Universal Controls GUI", 580, 480, -1, -1, BitOR($WS_CLIPCHILDREN, $GUI_SS_DEFAULT_GUI))
    _UC_GUISetBkColor(0xF0F0F0, $hMainGui)

    Local $idLblTheme = GUICtrlCreateLabel("GUI Theme", 20, 10, 150, 17)

    ; === Toggles ===
    Local $idToggleTheme = _UC_Toggle_Create($hMainGui, 20, 30, 50, 25, 0, 0xF0F0F0, 0x758184, 0xD1D1D1)
    Local $idToggle1 = _UC_Toggle_Create($hMainGui, 20, 80, 50, 25, 0)
    Local $idToggle2 = _UC_Toggle_Create($hMainGui, 20, 130, 50, 25, 1, 0xFF6A00, 0x33AA00)


    GUISetState(@SW_SHOW)

    Local $iMsg

    While 1
        $iMsg = GUIGetMsg()
        Switch $iMsg
            Case $GUI_EVENT_CLOSE
                ExitLoop

            Case $idToggleTheme
                ConsoleWrite("$idToggleTheme:" & GUICtrlRead($idToggleTheme) & @CRLF)
                Local $iTxtColor, $iBkColor

                If GUICtrlRead($idToggleTheme) Then
					$iBkColor = 0x393F41
                    $iTxtColor = 0xFFFFFF
                Else
					$iBkColor = 0xF0F0F0
                    $iTxtColor = 0x000000
                EndIf

				_UC_GUISetBkColor($iBkColor , $hMainGui)

				ConsoleWrite("Themes_Name=" & _UC_Themes("Active", "Themes_Name") & @CRLF)

                GUICtrlSetColor($idLblTheme, $iTxtColor)
				ConsoleWrite("$iTxtColor=0x" & Hex($iTxtColor, 6) & @CRLF)

                _UC_Refresh($hMainGui)

;~ 				_UC_Theme_Switch(GUICtrlRead($idToggleTheme) ? "Light" : "Dark")

            Case $idToggle1
                ConsoleWrite("$idToggle1:" & GUICtrlRead($idToggle1) & @CRLF)
				_MapCW(_UC_Get(1), "~~~ System Variable ~~~")

				Local $mAllTheme = _UC_Themes()        ; just debuging 🚧
				_MapCW($mAllTheme, "~~~ AllTheme ~~~") ; just debuging 🚧

            Case $idToggle2
                ConsoleWrite("$idToggle2:" & GUICtrlRead($idToggle2) & @CRLF)

				Local $mActive_UC = _UC_Get(Default, "UC_ControlID") ; just debuging 🚧
				_MapCW(_UC_Get($mActive_UC), "~~~ $mActive_UC ~~~")  ; just debuging 🚧


        EndSwitch

    WEnd

    _UC_Destroy($hMainGui)

EndFunc   ;==>_Main


