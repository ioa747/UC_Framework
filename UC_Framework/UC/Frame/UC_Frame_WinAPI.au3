; UC_Frame_WinAPI.au3
#include-once


#Region ; ~~~~~~~~~~~~~ UC_Framework Functions for Window Properties (WinAPI) ~~~~~~~~~
Func _WinAPI_SetProp($hWnd, $sName, $iVal)
	Local $aRet = DllCall("user32.dll", "bool", "SetPropW", "hwnd", $hWnd, "wstr", $sName, "handle", $iVal)
	Return $aRet[0]
EndFunc   ;==>_WinAPI_SetProp

Func _WinAPI_GetProp($hWnd, $sName)
	Local $aRet = DllCall("user32.dll", "handle", "GetPropW", "hwnd", $hWnd, "wstr", $sName)
	Return $aRet[0]
EndFunc   ;==>_WinAPI_GetProp

Func _WinAPI_RemoveProp($hWnd, $sName)
	Local $aRet = DllCall("user32.dll", "ptr", "RemovePropW", "hwnd", $hWnd, "wstr", $sName)
	Return $aRet[0]
EndFunc   ;==>_WinAPI_RemoveProp
#EndRegion ; ~~~~~~~~~~~~~ Helper Functions for Window Properties (WinAPI) ~~~~~~~~~~~~~~~
