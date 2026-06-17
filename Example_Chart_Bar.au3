#include "UC_Framework\UC_Framework.au3"

_Main()

Func _Main()

    Local $hGUI = GUICreate("Sales Dashboard", 1000, 600)

    _UC_GUISetBkColor(0xF7F8FA, $hGUI)

    Local $aLabels[] = [ _
        "Jan", _
        "Feb", _
        "Mar", _
        "Apr", _
        "May", _
        "Jun", _
        "Jul", _
        "Aug" _
    ]

    Local $aData[8][3] = [ _
        [120, 80, 50], _
        [150, 60, 70], _
        [180, 90, 40], _
        [130, 100, 60], _
        [220, 110, 80], _
        [190, 140, 75], _
        [240, 120, 90], _
        [260, 150, 100] _
    ]

    Local $idChart = _UC_Chart_Bar_Create($hGUI, 20, 20, 950, 450, $aData, $aLabels, "Year Sales", "Revenue", "Month", 0x2563EB, 0x000000)

	Local $idStack = _UC_Button_Create($hGUI, "Stacked", 20, 500, 120, 35, 5, 0x3C975A, 0xFFFFFF)
	Local $idGroup = _UC_Button_Create($hGUI, "Grouped", 160, 500, 120, 35, 5, 0xA84646, 0xFFFFFF)

    GUISetState()

    While 1

        Switch GUIGetMsg()

            Case $GUI_EVENT_CLOSE
                Exit

            Case $idStack
                _UC_Chart_Bar_SetMode($idChart, 1)

            Case $idGroup
                _UC_Chart_Bar_SetMode($idChart, 0)

        EndSwitch

    WEnd

EndFunc