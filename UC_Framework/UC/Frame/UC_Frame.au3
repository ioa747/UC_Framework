; https://www.autoitscript.com/forum/topic/213667-uc_framework-universal-controls/
;----------------------------------------------------------------------------------------
; Title...........: UC_Frame.au3
; Description.....: Native AutoIt UDF, UC_Frame_[UDF], Global variable\constant for the UC_Framework
; AutoIt Version..: 3.3.18.0   Author: ioa747           Script Version: 0.0.13.1
; Note............: Testet in Windows 11 Pro 25H2       Date:22/05/2026
; Link............: https://github.com/ioa747/UC_Framework
;----------------------------------------------------------------------------------------
;~ #AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include-once ; UC_Frame.au3

#Region ; ~~~ Native AutoIt UDF ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#include <AutoItConstants.au3>
#include <GUIConstantsEx.au3>
#include <GDIPlus.au3>
#include <WindowsConstants.au3>
#include <WinAPISysWin.au3>
#include <WinAPISys.au3>
#include <WinAPIGdi.au3>
#include <StaticConstants.au3>
#include <String.au3>
#include <WinAPIvkeysConstants.au3>
#include <EditConstants.au3>
#EndRegion ; ~~~ Native AutoIt UDF ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Region ; ~~~ Global  variable\constant ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Global $g_UC_DebugInfo = 0

Global Enum _
        $UC_TYPE_NONE, _
        $UC_TYPE_TOGGLE, _
        $UC_TYPE_SLIDER, _
        $UC_TYPE_BUTTON, _
        $UC_TYPE_LINK, _
        $UC_TYPE_LABEL, _
        $UC_TYPE_IMAGE, _
        $UC_TYPE_PROGRESSBAR, _
        $UC_TYPE_RADIALPROGRESS, _
        $UC_TYPE_HOURMINUTE, _
        $UC_TYPE_RATING, _
        $UC_TYPE_INFOBOX, _
        $UC_TYPE_CHART_BAR, _
        $UC_TYPE_DATEPICKER, _
        $UC_TYPE_CALENDAR, _
		$UC_TYPE_STEPPER, _
        $UC_TYPE_MAX

Global Const $aUC_Types[] = [ _
        "None", _           ; $UC_TYPE_NONE
        "Toggle", _         ; $UC_TYPE_TOGGLE
        "Slider", _         ; $UC_TYPE_SLIDER
        "Button", _         ; $UC_TYPE_BUTTON
        "Link", _           ; $UC_TYPE_LINK
        "Label", _          ; $UC_TYPE_LABEL
        "Image", _          ; $UC_TYPE_IMAGE
        "ProgressBar", _    ; $UC_TYPE_PROGRESSBAR
        "RadialProgress", _ ; $UC_TYPE_RADIALPROGRESS
        "HourMinute", _     ; $UC_TYPE_HOURMINUTE
        "Rating", _         ; $UC_TYPE_RATING
        "InfoBox", _        ; $UC_TYPE_INFOBOX
        "Chart_Bar", _      ; $UC_TYPE_CHART_BAR
        "DatePicker", _     ; $UC_TYPE_DATEPICKER
        "Calendar", _       ; $UC_TYPE_CALENDAR
		"Stepper" _         ; $UC_TYPE_STEPPER
        ]

#EndRegion ; ~~~ Global  variable\constant ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Region ; ~~~ UC_Frame_...  UDF ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#include "UC_Frame_Generic.au3"
#include "UC_Frame_Map.au3"
#include "UC_Frame_Internal.au3"
#include "UC_Frame_GDI.au3"
#include "UC_Frame_WinAPI.au3"
#include "UC_Frame_Timers.au3"
#EndRegion ; ~~~ UC_Frame_...  UDF ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

