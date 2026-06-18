#include-once ; UC_Frame_Timers.au3

#include "UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC_Framework Timers API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func _UC_Timer_Set($idCtrl, $iElapse = 250, $sUserFunc = "", $iTimerID = 0)
	Local $UC = _UC_Properties($idCtrl)
	Local $hParent = $UC.UC_hParent

	; If $iTimerID is 0 (new timer), generate a unique ID above 10000 to avoid conflicts
	If $iTimerID = 0 Then
		Static $iUC_TimerCounter = 10000
		$iUC_TimerCounter += 1
		$iTimerID = $iUC_TimerCounter
	EndIf

	Local $pCallback = _UC_Properties(1, "UC_TimerCallbackPtr")

	; Call our API wrapper with the explicit custom ID
	Local $id = _UC_Timer_SetTimer($hParent, $iElapse, $pCallback, $iTimerID)

	If Not $id Then Return SetError(1, 0, 0)

	; Timer Data
	Local $mt[], $mMap[]

	$mt.id = $id
	$mt.elapse = $iElapse
	$mt.UserFunc = $sUserFunc
	$mt.hwnd = $hParent
	$mt.ControlID = $idCtrl
	$mt.Fired = 0
	$mt.RetVal = ""
	$mt.LastError = 0

	Local $mTimers = (MapExists($UC, "Timers") ? $UC.Timers : $mMap)
	$mTimers[String($mt.id)] = $mt
	$UC.Timers = $mTimers

	_UC_Properties(2, String($mt.id), $idCtrl)
	_UC_Properties($idCtrl, $UC, False)
	Return $id
EndFunc   ;==>_UC_Timer_Set

Func __UC_Timer_Internal_Handler($hWnd, $iMsg, $iIDTimer, $iTime) ; central Timer callback
	#forceref $hWnd, $iMsg, $iTime
	Local $m = _UC_TimerMap($iIDTimer)
	If @error Then Return SetError(1, 0, "") ; It's not our timer.
	$m.RetVal = ""
	$m.LastError = 0

	If $m.UserFunc <> "" Then
		$m.Fired += 1
		$m.RetVal = Call($m.UserFunc, $m)
		If @error = 0xDEAD And @extended = 0xBEEF Then $m.LastError = 2 ; *** function does not exist or invalid number of parameters.
		If MapExists(_UC_Properties(2), String($iIDTimer)) Then _UC_TimerMap($iIDTimer, $m)
		Return 0
	EndIf

EndFunc   ;==>__UC_Timer_Internal_Handler

Func _UC_Timer_Kill($iTimerID)
	Local $m = _UC_TimerMap($iTimerID)
	If Not @error Then
		Local $Result = _UC_Timer_KillTimer($m.hwnd, $m.id)
		_UC_TimerMap($iTimerID, "@Delete")
		Local $mTimerIndex = _UC_Properties(2)
		Local $sKey = String($m.id)
		If IsMap($mTimerIndex) And MapExists($mTimerIndex, $sKey) Then MapRemove($mTimerIndex, $sKey)
		_UC_Properties(2, $mTimerIndex)
		Return $Result
	EndIf
	Return False
EndFunc   ;==>_UC_Timer_Kill

Func _UC_Timer_Remove($idCtrl)
	Local $mUC = _UC_Properties($idCtrl)
	If MapExists($mUC, "Timers") Then
		Local $aTimers = _Map2D($mUC.Timers)
		For $i = 0 To UBound($aTimers) - 1
			_UC_Timer_Kill($aTimers[$i][0])
		Next
	EndIf
EndFunc   ;==>_UC_Timer_Remove

Func _UC_TimerMap($iIDTimer, $mTimer = 0)
	Local $sKey, $idCtrl, $mTimers
	$sKey = String($iIDTimer)
	$idCtrl = _UC_Properties(2, $sKey)
	If Not @error Then
		Local $mUC = _UC_Properties($idCtrl)
		If IsMap($mUC) Then
			$mTimers = $mUC.Timers
			If $mTimer = 0 Then ; Get map
				If IsMap($mTimers) And MapExists($mTimers, $sKey) Then Return $mTimers[$sKey]
			Else ; .............. Set map
				If IsMap($mTimers) And IsMap($mTimer) Then
					$mTimers[$sKey] = $mTimer
				EndIf

				If IsMap($mTimers) And MapExists($mTimers, $sKey) And $mTimer = "@Delete" Then ; Delete map
					MapRemove($mTimers, $sKey)
				EndIf

				$mUC.Timers = $mTimers
				Return _UC_Properties($idCtrl, $mUC, False)

			EndIf
		EndIf
	EndIf
	Return SetError(1, 0, 0)
EndFunc   ;==>_UC_TimerMap

; Internal API call to SetTimer using our specific pointer
Func _UC_Timer_SetTimer($hWnd, $iElapse, $pTimerFunc, $iTimerID = 0)
	Local $aCall = DllCall("user32.dll", "uint_ptr", "SetTimer", _
			"hwnd", $hWnd, _
			"uint_ptr", $iTimerID, _
			"uint", $iElapse, _
			"ptr", $pTimerFunc)

	If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
	Return $aCall[0] ; Returns the valid Timer ID
EndFunc   ;==>_UC_Timer_SetTimer

Func _UC_Timer_KillTimer($hWnd, $iTimerID)
	Local $aCall = DllCall("user32.dll", "bool", "KillTimer", "hwnd", $hWnd, "uint_ptr", $iTimerID)
	If @error Then Return False
	Return $aCall[0]
EndFunc   ;==>_UC_Timer_KillTimer
#EndRegion ; ~~~~~~~~~~~~~ UC Timers API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
