#include-once ; UC_Frame_Internal.au3

#include "UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC_Framework Internal Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func __UC_Framework_Init($hParent)
	Static $bInitialized = False
	If $bInitialized Then Return
	__DW("__UC_Framework_Init($hParent=" & $hParent & ")" & @CRLF, 1, ">>> UC_Frame_Internal.au3")
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

	Local $m = _UC_Properties(1, Default, Default, "UC_Frame_Internal.au3") ; get system properties
	Local $aCursorType = StringSplit("Hand|AppStarting|Arrow|Cross|Help|IBeam|Icon|No|" & _
			"Size|SizeAll|SizeNESW|SizeNS|SizeNWSE|SizeWE|UpArrow|Wait|None", "|", 2)
	For $i = 0 To UBound($aCursorType) - 1
		$m["Cursor_" & $aCursorType[$i]] = $i
	Next

	Local $hCallback = DllCallbackRegister("__UC_Timer_Internal_Handler", "none", "hwnd;uint;uint_ptr;dword")
	$m["UC_TimerCallbackPtr"] = DllCallbackGetPtr($hCallback)

;~ 	_MapCW($m, "~~~ (1) system properties ~~~") ; just debuging 🚧

	_UC_Properties(1, $m, False, "UC_Frame_Internal.au3") ; set back system properties

	; Theme Initialized ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Local $sIniPath = @ScriptDir & "\UC_Framework\UC_Theme.ini"

	; check if the file exists. If not, create it.
	If Not FileExists($sIniPath) Then
		_UC_CreateDefaultIni($sIniPath)
	EndIf

	; load sections to maps
	Local $mThemeConfig = _Map_GetfromIni($sIniPath, "ThemeConfig")
	Local $mLight = _Map_GetfromIni($sIniPath, "Light")
	Local $mDark = _Map_GetfromIni($sIniPath, "Dark")

	; save the mapss in the Theme Manager for future use
	_UC_Themes("ThemeConfig", $mThemeConfig)
	_UC_Themes("Light", $mLight)
	_UC_Themes("Dark", $mDark)

	; Select Active Theme
	Local $iCol = __UC_ParentColor($hParent)
;~ 	__DW("UC_Frame_Internal.au3 :: $iCol=" & $iCol & @CRLF) ; just debuging 🚧

	Local $sDefault = MapExists($mThemeConfig, "Default") ? $mThemeConfig.Default : "auto"

	If $sDefault = "auto" Then
		_UC_Themes("Active", (_UC_IsLightColor($iCol) ? $mLight : $mDark))
	Else
		_UC_Themes("Active", ($sDefault = "Dark" ? $mDark : $mLight))
	EndIf

;~ 	Local $mAllTheme = _UC_Themes()        ; just debuging 🚧
;~ 	_MapCW($mAllTheme, "~~~ AllTheme ~~~") ; just debuging 🚧

	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	$bInitialized = True
EndFunc   ;==>__UC_Framework_Init

Func __UC_Main_MsgHandler($hWnd, $iMsg, $wParam, $lParam)
	#forceref $wParam
	Local Static $hLastChild = 0, $hToolTipGUI = _UC_Properties(1, "UC_ToolTip_hWnd", Default, "UC_Frame_Internal.au3")
	Local Static $sFilterFlag = "" ; Central filter to avoid unnecessary redraws/calls

	If $hToolTipGUI = $hWnd Then Return $GUI_RUNDEFMSG

	; First we check if the previous control needs "Reset" from Hover State
	; This must be done regardless of whether $hWnd is a UC control or not.
	If $hLastChild And $hLastChild <> $hWnd Then
		Local $idLast = Int(_WinAPI_GetProp($hLastChild, "UC_ControlID"))
		If $idLast Then
			Local $mLast = _UC_Properties($idLast, Default, Default, "UC_Frame_Internal.au3")

			; Reset if the State is Hover (2)
			If $mLast.State = 2 Then
				_UC_ToolTip("")
				__DW("__UC_Main_MsgHandler :: previous control :: ID:" & Int($idLast) & " > from State: 2 To: 1" & @CRLF, 1, "->> UC_Frame_Internal.au3")
				$mLast.State = 1
				_UC_Properties($idLast, $mLast, Default, "UC_Frame_Internal.au3")
				; 🚧 Once a control is reset, we clean the filter
				; to be ready to accept hover again
				$sFilterFlag = ""
				$hLastChild = 0
			ElseIf $mLast.State <> 3 Then
				; 🚧 If it is not in Dragging (3), reset $hLastChild to zero.
				$hLastChild = 0
			EndIf
		Else
			$hLastChild = 0
		EndIf
	EndIf

	; Now we check the current window
	Local $idDummy = Int(_WinAPI_GetProp($hWnd, "UC_ControlID"))
	If Not $idDummy Then Return $GUI_RUNDEFMSG

	; If we got here, we are in UC Control.
	Local $iCtrlType = _UC_Properties($idDummy, "UC_Type", Default, "UC_Frame_Internal.au3")
	Local $iX = BitAND($lParam, 0xFFFF)
	Local $iY = BitShift($lParam, 16)

	Switch $iMsg
		Case $WM_PAINT
			__DW("__UC_Main_MsgHandler -> Case $WM_PAINT <-" & @CRLF, 1, "<- UC_Frame_Internal.au3")
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
			Local $iState = _UC_Properties($idDummy, "State", Default, "UC_Frame_Internal.au3")

			; 🚧 EXCEPTION: If State is 3 (Pressed/Dragging), we DO NOT filter MOUSEMOVE
			If $iState <> 3 Then
				; Check: If the control is already in this State, Return
				If $sFilterFlag = $idDummy & "-" & $iState Then
					__DW("__UC_Main_MsgHandler :: <<-  Return <<- :: $sFilterFlag=" & $sFilterFlag & @CRLF, 1, "<<- UC_Frame_Internal.au3")
					Return 0
				EndIf
			EndIf

			; If it is not filtered, we proceed to normal execution
			__UC_CallControlFunc($iMsg, $idDummy, $hWnd, $iX, $iY)

			$hLastChild = $hWnd
			_UC_Properties(1, "UC_ActiveControlID", Int($idDummy), "UC_Frame_Internal.au3")
			_UC_Properties(1, "UC_ActiveControlType", Int($iCtrlType), "UC_Frame_Internal.au3")

			; We update the central flag with the NEW state (after CallControlFunc changed the State to Hover)
			$iState = _UC_Properties($idDummy, "State", Default, "UC_Frame_Internal.au3")
			$sFilterFlag = $idDummy & "-" & $iState
			__DW("__UC_Main_MsgHandler :: $sFilterFlag=" & $sFilterFlag & @CRLF, 1, "->>- UC_Frame_Internal.au3")

			Return 0

		Case $WM_SETFOCUS
			__UC_CallControlFunc($iMsg, $idDummy, $hWnd, $iX, $iY)
			$hLastChild = $hWnd
			_UC_Properties(1, "UC_ActiveControlID", Int($idDummy), "UC_Frame_Internal.au3")
			_UC_Properties(1, "UC_ActiveControlType", Int($iCtrlType), "UC_Frame_Internal.au3")
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
	Local $m = _UC_Properties($id, Default, Default, "UC_Frame_Internal.au3")
	Local $sKey = "UC_WM_" & $iMsg

	; We check if Control has declared support for this specific message
	If MapExists($m, $sKey) And $m[$sKey] Then
		Local $sEventName = $m[$sKey] ; e.g. "_WM_LBUTTONDOWN"
		Local $sFuncName = "_UC_" & $aUC_Types[$m.UC_Type] & $sEventName

		__DW("__UC_CallControlFunc ->-> $sFuncName:" & $sFuncName & "  $id: " & $id & @CRLF, 1, "->-> UC_Frame_Internal.au3")

		Local $vRet = Call($sFuncName, $id, $hWnd, $iX, $iY)

		; Error Handling
		If @error = 0xDEAD And @extended = 0xBEEF Then
			; 🚧 ConsoleWrite or __DW ??
			ConsoleWrite("!Error __UC_CallControlFunc: Registered event " & $sEventName & " but function (or parameter) " & $sFuncName & " is missing. " & @CRLF)
			Return SetError(1, 0, False)
		EndIf
		Return $vRet
	EndIf

	Return $GUI_RUNDEFMSG ; Default return if there is no handler
EndFunc   ;==>__UC_CallControlFunc

Func __UC_ParentColor($hWnd)
	Local $hParent = _WinAPI_GetParent($hWnd)
	If Not $hParent Then $hParent = $hWnd ; If it doesn't have a parent, then look at the handle itself
	Local $iCol = _UC_Properties(1, "UC_GUIBkColor_" & $hParent, Default, "UC_Frame_Internal.au3")
	Return (@error ? _WinAPI_GetSysColor($COLOR_BTNFACE) : $iCol) ; $COLOR_BTNFACE as Default
EndFunc   ;==>__UC_ParentColor

Func __UC_Framework_Shutdown()
	__DW("__UC_Framework_Shutdown()" & @CRLF, 1, ">>> UC_Frame_Internal.au3")
	_UC_Destroy()
	_GDIPlus_Shutdown()
EndFunc   ;==>__UC_Framework_Shutdown

Func __DW($sString, $iErrorNoLineNo = 1, $sPreFix = "+>", $iLine = @ScriptLineNumber, $iError = @error, $iExtended = @extended)
	If Not $g_UC_DebugInfo Then Return SetError($iError, $iExtended, 0)
	Local $iReturn
	If $iErrorNoLineNo = 1 Then
		If $iError Then
			$sPreFix = "@@"
			$iReturn = ConsoleWrite($sPreFix & "(" & $iLine & ") :: @error:" & $iError & ", @extended:" & $iExtended & ", " & $sString)
		Else
			$iReturn = ConsoleWrite($sPreFix & "(" & $iLine & ") :: " & $sString)
		EndIf
	Else
		$iReturn = ConsoleWrite($sString)
	EndIf
	; Remarks: The @error and @extended are not set on return leaving them as they were before calling.
	Return SetError($iError, $iExtended, $iReturn)
EndFunc   ;==>__DW
#EndRegion ; ~~~~~~~~~~~~~ UC_Framework Internal Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#Region ; ~~~~~~~~~~~~~ UC_Themes Functions for Theme Management ~~~~~~~~~~~~~~~~~
Func _UC_CreateDefaultIni($sIniPath)
	Local $sTxt = ""
	$sTxt &= "[ThemeConfig]" & @CRLF
	$sTxt &= "Default=auto" & @CRLF
	$sTxt &= "DefaultLight= Light" & @CRLF
	$sTxt &= "DefaultDark=Dark" & @CRLF
	$sTxt &= "[Light]" & @CRLF
	$sTxt &= "Themes_Name=Light" & @CRLF
	$sTxt &= "Themes_IsLightColor=1" & @CRLF
	$sTxt &= "Themes_Workspace=0x758184" & @CRLF
	$sTxt &= "Themes_Accent=0x388692" & @CRLF
	$sTxt &= "Surface_Face=0xF0F0F0" & @CRLF
	$sTxt &= "Surface_Hot=0x0066CC" & @CRLF
	$sTxt &= "Surface_Border=0xABABAB" & @CRLF
	$sTxt &= "Surface_Disabled=0xCCCCCC" & @CRLF
	$sTxt &= "Text_Disabled=0x888888" & @CRLF
	$sTxt &= "Text_fore=0x000000" & @CRLF
	$sTxt &= "Text_Back=0xFFFFFF" & @CRLF
	$sTxt &= "Fonts_Name=Segoe UI" & @CRLF
	$sTxt &= "Fonts_Size=9" & @CRLF
	$sTxt &= "[Dark]" & @CRLF
	$sTxt &= "Themes_Name=Dark" & @CRLF
	$sTxt &= "Themes_IsLightColor=0" & @CRLF
	$sTxt &= "Themes_Workspace=0x758184" & @CRLF
	$sTxt &= "Themes_Accent=0x388692" & @CRLF
	$sTxt &= "Surface_Face=0x2D2D2D" & @CRLF
	$sTxt &= "Surface_Hot=0x3399FF" & @CRLF
	$sTxt &= "Surface_Border=0xABABAB" & @CRLF
	$sTxt &= "Surface_Disabled=0xCCCCCC" & @CRLF
	$sTxt &= "Text_Disabled=0x888888" & @CRLF
	$sTxt &= "Text_fore=0xFFFFFF" & @CRLF
	$sTxt &= "Text_Back=0x1E1E1E" & @CRLF
	$sTxt &= "Fonts_Name=Segoe UI" & @CRLF
	$sTxt &= "Fonts_Size=9"

	FileWrite($sIniPath, $sTxt)
EndFunc   ;==>_UC_CreateDefaultIni

Func _UC_Themes($sTheme = Default, $vName = Default, $vVal = Default)
	Local Static $mTheme = 0, $mEmpty[]

	If $mTheme = 0 Then ; # initialize Themes Map (Map of Maps)
		$mTheme = $mEmpty
		$mTheme.ThemeConfig = $mEmpty ; Themes General Properties Map
		$mTheme.Active = $mEmpty      ; Active Theme Map
	EndIf

	If $sTheme = Default Then Return $mTheme

	; Map Selection (or Template)
	Local $m = (MapExists($mTheme, $sTheme) ? $mTheme[$sTheme] : $mEmpty)

	Select
		Case $vName = Default
			Return $mTheme[$sTheme] ; GET MAP

		Case IsMap($vName)
			$mTheme[$sTheme] = $vName ; SET MAP
			Return 1

		Case Else
			If $vVal = Default Then ; GET Val
				If MapExists($m, $vName) Then
					Return $m[$vName]
				Else
					Return SetError(1, 0, $m)
				EndIf
			Else ; SET Val
				If $vName = "@Delete" Then
					$mTheme[$sTheme] = ""
					Return 1
				EndIf

				$m[$vName] = $vVal
				$mTheme[$sTheme] = $m
				Return 1
			EndIf
	EndSelect
EndFunc   ;==>_UC_Themes

Func _UC_Theme_Switch($sNewThemeName)
	_UC_Themes("Active", _UC_Themes($sNewThemeName))
;~ 	_UC_Resource_Cleanup()
;~  _UC_Redraw_All()
EndFunc   ;==>_UC_Theme_Switch
#EndRegion ; ~~~~~~~~~~~~~ UC_Themes Functions for Theme Management ~~~~~~~~~~~~~~~~~
