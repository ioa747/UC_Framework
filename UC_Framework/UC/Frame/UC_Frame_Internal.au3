; UC_Frame_Internal.au3
#include-once

#include "UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC_Framework Internal Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func __UC_Framework_Init($hParent)
	Static $bInitialized = False
	If $bInitialized Then Return
	_GDIPlus_Startup()
	GUIRegisterMsg($WM_ERASEBKGND, "__UC_Main_MsgHandler")
	GUIRegisterMsg($WM_PAINT, "__UC_Main_MsgHandler")
	GUIRegisterMsg($WM_LBUTTONDOWN, "__UC_Main_MsgHandler")
	GUIRegisterMsg($WM_LBUTTONDBLCLK, "__UC_Main_MsgHandler")
	GUIRegisterMsg($WM_MOUSEMOVE, "__UC_Main_MsgHandler")
	GUIRegisterMsg($WM_LBUTTONUP, "__UC_Main_MsgHandler")
	GUIRegisterMsg($WM_RBUTTONDOWN, "__UC_Main_MsgHandler")
	GUIRegisterMsg($WM_RBUTTONUP, "__UC_Main_MsgHandler")
	GUIRegisterMsg($WM_SETFOCUS, "__UC_Main_MsgHandler")
	GUIRegisterMsg($WM_KEYDOWN, "__UC_Main_MsgHandler")

	OnAutoItExitRegister("__UC_Framework_Shutdown")

	_UC_ToolTip("", -1, -1, $hParent)

	Local $aCursorType = StringSplit("Hand|AppStarting|Arrow|Cross|Help|IBeam|Icon|No|" & _
			"Size|SizeAll|SizeNESW|SizeNS|SizeNWSE|SizeWE|UpArrow|Wait|None", "|", 2)
	For $i = 0 To UBound($aCursorType) - 1
		_UC_Properties(1, "Cursor_" & $aCursorType[$i], $i)
	Next

	Local $hCallback = DllCallbackRegister("__UC_Timer_Internal_Handler", "none", "hwnd;uint;uint_ptr;dword")
	_UC_Properties(1, "UC_TimerCallbackPtr", DllCallbackGetPtr($hCallback))

	$bInitialized = True
EndFunc   ;==>__UC_Framework_Init

Func __UC_Main_MsgHandler($hWnd, $iMsg, $wParam, $lParam)
	#forceref $wParam
	Local Static $hLastChild = 0, $hToolTipGUI = _UC_Properties(1, "UC_ToolTip_hWnd")

	If $hToolTipGUI = $hWnd Then Return $GUI_RUNDEFMSG

	; First we check if the previous control needs "Reset"
	; This must be done regardless of whether $hWnd is a UC control or not.
	If $hLastChild And $hLastChild <> $hWnd Then
		Local $idLast = _WinAPI_GetProp($hLastChild, "UC_ControlID")
		If $idLast Then
			Local $mLast = _UC_Properties($idLast)

			; Only if it is not already Normal or Disabled
			If $mLast.State <> 1 Then
				_UC_ToolTip("")
				If $mLast.State <> 0 Then
					$mLast.State = 1
					_UC_Properties($idLast, $mLast)
				EndIf
			EndIf
		EndIf
		$hLastChild = 0
	EndIf

	; Now we check the current window
	Local $idDummy = _WinAPI_GetProp($hWnd, "UC_ControlID")
	If Not $idDummy Then Return $GUI_RUNDEFMSG

	; If we got here, we are in UC Control.
	Local $iCtrlType = _UC_Properties($idDummy, "UC_Type")
	Local $iX = BitAND($lParam, 0xFFFF)
	Local $iY = BitShift($lParam, 16)

	Switch $iMsg
		Case $WM_PAINT
			_UC_Redraw($hWnd)
			Local $tPAINTSTRUCT = DllStructCreate($tagPAINTSTRUCT)
			_WinAPI_BeginPaint($hWnd, $tPAINTSTRUCT)
			_WinAPI_EndPaint($hWnd, $tPAINTSTRUCT)
			Return 0
		Case $WM_ERASEBKGND
			Return 1

		Case $WM_LBUTTONDOWN, $WM_LBUTTONDBLCLK, $WM_LBUTTONUP, $WM_RBUTTONDOWN, $WM_RBUTTONUP
			__UC_CallControlFunc($iMsg, $idDummy, $hWnd, $iX, $iY)
			Return 0

		Case $WM_MOUSEMOVE
			__UC_CallControlFunc($iMsg, $idDummy, $hWnd, $iX, $iY)
			$hLastChild = $hWnd
			_UC_Properties(1, "UC_ActiveControlID", Int($idDummy))
			_UC_Properties(1, "UC_ActiveControlType", Int($iCtrlType))
			Return 0

		Case $WM_SETFOCUS
			__UC_CallControlFunc($iMsg, $idDummy, $hWnd, $iX, $iY)
			$hLastChild = $hWnd
			_UC_Properties(1, "UC_ActiveControlID", Int($idDummy))
			_UC_Properties(1, "UC_ActiveControlType", Int($iCtrlType))
			Return 0

		Case $WM_KEYDOWN
			; $wParam contains the key code (Virtual Key Code)
			Local $aXY[2] = [$iX, $iY]
			__UC_CallControlFunc($iMsg, $idDummy, $hWnd, $wParam, $aXY)
			Return 0

	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc   ;==>__UC_Main_MsgHandler

Func __UC_CallControlFunc($iMsg, $id, $hWnd, $iX, $iY)
    Local $m = _UC_Properties($id)
    Local $sKey = "UC_WM_" & $iMsg

    ; We check if Control has declared support for this specific message
    If MapExists($m, $sKey) And $m[$sKey] Then
        Local $sEventName = $m[$sKey] ; e.g. "_WM_LBUTTONDOWN"
        Local $sFuncName = "_UC_" & $aUC_Types[$m.UC_Type] & $sEventName

        Local $vRet = Call($sFuncName, $id, $hWnd, $iX, $iY)

        ; Error Handling
        If @error = 0xDEAD And @extended = 0xBEEF Then
            If $g_UC_DebugInfo Then __DW("!Error: Registered event " & $sEventName & " but function " & $sFuncName & " missing.")
            Return SetError(1, 0, False)
        EndIf
        Return $vRet
    EndIf

    Return $GUI_RUNDEFMSG ; Default return if there is no handler
EndFunc

Func __UC_ParentColor($hWnd)
	Local $hParent = _WinAPI_GetParent($hWnd)
	Local $iCol = _WinAPI_GetProp($hParent, "UC_GUIBkColor")
	Return ($iCol ? $iCol : _WinAPI_GetSysColor($COLOR_BTNFACE)) ; $COLOR_BTNFACE as Default
EndFunc   ;==>__UC_ParentColor

Func __UC_Framework_Shutdown()
	_UC_Destroy()
	_GDIPlus_Shutdown()
EndFunc   ;==>__UC_Framework_Shutdown

Func __DW($sString, $iErrorNoLineNo = 1, $iLine = @ScriptLineNumber, $iError = @error, $iExtended = @extended)
	If Not $g_UC_DebugInfo Then Return SetError($iError, $iExtended, 0)
	Local $iReturn
	If $iErrorNoLineNo = 1 Then
		If $iError Then
			$iReturn = ConsoleWrite("@@(" & $iLine & ") :: @error:" & $iError & ", @extended:" & $iExtended & ", " & $sString)
		Else
			$iReturn = ConsoleWrite("+>(" & $iLine & ") :: " & $sString)
		EndIf
	Else
		$iReturn = ConsoleWrite($sString)
	EndIf
	; Remarks: The @error and @extended are not set on return leaving them as they were before calling.
	Return SetError($iError, $iExtended, $iReturn)
EndFunc   ;==>__DW
#EndRegion ; ~~~~~~~~~~~~~ UC_Framework Internal Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

