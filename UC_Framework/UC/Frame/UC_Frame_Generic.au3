#include-once ; UC_Frame_Generic.au3

#include "UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC_Framework Generic API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Func _UC_Redraw($hWnd)
	Local $id = Int(_WinAPI_GetProp($hWnd, "UC_ControlID"))
	If Not $id Then Return SetError(1, 0, 0)
	Local $m = _UC_Properties($id, Default, Default, "UC_Frame_Generic.au3")

	If $m.UC_Type = $UC_TYPE_NONE Then Return

	; Creating the function name
	Local $sDrawFunc = "_UC_" & $aUC_Types[$m.UC_Type] & "_Draw"

	__DW("_UC_Redraw :: UC_ControlID=" & $m.UC_ControlID & ", $sDrawFunc=" & $sDrawFunc & @CRLF, 1, "### UC_Frame_Generic.au3")

	Call($sDrawFunc, $hWnd, $m)
	If @error = 0xDEAD And @extended = 0xBEEF Then ConsoleWrite("!Error in _UC_Redraw: Function " & $sDrawFunc & " was not found for Control ID: " & $id & @CRLF)
;~ 	_UC_Properties($id, $m, False) ; update the $m
EndFunc   ;==>_UC_Redraw

; #FUNCTION# ====================================================================================================================
; Name ..........: _UC_Properties
; Description ...: Centralized Property Manager and Reactive Engine for Universal Controls.
; Syntax ........: _UC_Properties($idDummy[, $vName = Default[, $vVal = Default]])
; Parameters ....: $idDummy   - The Control ID (Dummy) assigned to the UC control.
;                  $vName     - [Optional] Property name (String), a complete Map object, or "@Delete".
;                  $vVal      - [Optional] The value to assign.
;                               If $vName is "@Delete", set $vVal to True to skip final redraw.
;                               If $vName is a Map, $vVal=False skips the automatic redraw.
; Return values .: Success:
;                   0.1. GET Full Array:  (Call: _UC_Properties()) -> Returns the entire $aProp Array.
;                   0.1. GET Full Map:    (Call: _UC_Properties(-1)) -> $aProp[1].UC_LastCreatedID -> Returns the UC_LastCreatedID map.
;                   0.1. GET Value:       (Call: _UC_Properties(-1, "UC_Type")) -> Returns the UC_TYPE from UC_LastCreatedID e.g.: $UC_TYPE_TOGGLE
;
;                   1. GET Full Map:  (Call: _UC_Properties($id)) -> Returns the entire Map object.
;                   2. SET Full Map:  (Call: _UC_Properties($id, $mMap)) -> Returns 1, updates memory and Redraws.
;                   3. GET Value:     (Call: _UC_Properties($id, "PropName")) -> Returns the specific value.
;                   4. SET Value:     (Call: _UC_Properties($id, "PropName", $vVal)) -> Returns 1 and Redraws.
;                   5. DELETE:        (Call: _UC_Properties($id, "@Delete")) -> Clears memory slot.
;                  Failure:
;                   - Returns SetError(1, 0, $mTemplate) if a requested property name does not exist.
;                   - Returns SetError(2, 0, 0) if $idDummy property = -1 and control does not exist.
; Author ........: ioa747
; Remarks .......: This function implements a "Reactive Data Binding" logic. Any change to a property
;                  automatically triggers the _UC_Redraw() for the associated hWnd.
;
;                  Internal Architecture & Indexing:
;                  - Index [0]: Stores the total number of allocated slots (Array Size tracking).
;                  - Index [1]: Reserved for General Library Parameters (Global settings for the UC framework).
;                  - Index [2]: Reserved as a Timers Map (Timer -> ControlID)
;                  - Index [3+]: Stores the unique Map for each individual Control ID (Dummy).
;
;                  Usage Scenarios:
;                  - Multi-Property Update: Get the Map, modify multiple keys, then Set it back to trigger one Redraw.
;                  - Control Initialization: The framework automatically copies the Template Map when a new
;                    Control ID is first accessed, ensuring consistency across all controls.
;                  - Memory Management: Map objects are heavy. Always call with "@Delete" when a control is
;                    destroyed (e.g., during GUIDelete) to prevent memory leaks in long-running scripts.
; ===============================================================================================================================
Func _UC_Properties($idDummy = Default, $vName = Default, $vVal = Default, $iFromfile = "??", $iFromLine = @ScriptLineNumber)
	Local Static $aProp[1] = [0], $mMap[]

	If $idDummy = Default Then Return $aProp
	If $idDummy = -1 Then  ; -1 => UC_LastCreatedID
		If Not MapExists($aProp[1], "UC_LastCreatedID") Then Return SetError(2, 0, 0)
		$idDummy = $aProp[1].UC_LastCreatedID
	EndIf

	; Dynamic Array Resize
	If $idDummy > $aProp[0] Then
		Local $iNewSize = $idDummy + 10
		ReDim $aProp[$iNewSize]
		$aProp[0] = UBound($aProp) - 1

		; Initialize Template (if it doesn't already exist)
		If Not IsMap($aProp[2]) Then
			; in Autoit allways controls start from 3
			$aProp[1] = $mMap ; General Properties
			$aProp[2] = $mMap ; Timers  Map
		EndIf

	EndIf

;~ 	__DW("_UC_Properties(" & $vID & ", " &  (IsMap($vName) ? "{" & VarGetType($vName) & "[" & UBound($vName) & "]}" : $vName)  & ", " &  $vVal  & ", " &  $iFrom  & ")" & @CRLF)

	__DW("_UC_Properties(" & $idDummy & ", " & (IsMap($vName) ? "{" & VarGetType($vName) & "[" & UBound($vName) & "]}" : $vName) & ", " & $vVal & ") <-(" & $iFromfile & ":" & $iFromLine & ")-<" & @CRLF, 1, "+++ UC_Frame_Generic.au3")

	; Map Selection (or Template)
	Local $m = (IsMap($aProp[$idDummy]) ? $aProp[$idDummy] : $mMap)

	Select
		Case $vName = Default
			Return $aProp[$idDummy] ; GET MAP

		Case IsMap($vName)
			$aProp[$idDummy] = $vName ; SET MAP
			If $vVal = Default And MapExists($vName, "UC_hWnd") Then
				__DW("_UC_Properties :: (1) >>> _UC_Redraw" & @CRLF, 1, "+++ UC_Frame_Generic.au3")
				_UC_Redraw($vName.UC_hWnd)
			EndIf
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
					$aProp[$idDummy] = ""
					; If $vVal = Default And MapExists($vName, "UC_hWnd") Then _UC_Redraw($m.UC_hWnd)
					Return 1
				EndIf

				$m[$vName] = $vVal
				$aProp[$idDummy] = $m

				; _UC_Redraw($m.UC_hWnd)
				If MapExists($m, "UC_hWnd") Then
					__DW("_UC_Properties :: (2) >>> _UC_Redraw" & @CRLF, 1, "+++ UC_Frame_Generic.au3")
					_UC_Redraw($m.UC_hWnd)
				EndIf
				Return 1
			EndIf
	EndSelect
EndFunc   ;==>_UC_Properties

Func _UC_Get($idCtrl = Default, $sProp = Default)
	If $idCtrl = Default Then
		$idCtrl = _UC_Properties(1, "UC_ActiveControlID", Default, "UC_Frame_Generic.au3")
		If Not $idCtrl Then Return SetError(1, 0, 0)
		If $sProp = Default Then Return $idCtrl ; if no $sProp argum -> Return $idCtrl
	EndIf
	Return _UC_Properties($idCtrl, $sProp, Default, "UC_Frame_Generic.au3")
EndFunc   ;==>_UC_Get

Func _UC_Set($idCtrl = Default, $sProp = Default, $vValue = Default)
	If $idCtrl = Default Then
		$idCtrl = _UC_Properties(1, "UC_ActiveControlID", Default, "UC_Frame_Generic.au3")
		If Not $idCtrl Then Return SetError(1, 0, 0)
		If $sProp = Default Then Return $idCtrl ; if no $sProp argum -> Return $idCtrl
	EndIf
	Return _UC_Properties($idCtrl, $sProp, $vValue, "UC_Frame_Generic.au3")
EndFunc   ;==>_UC_Set

Func _UC_Destroy($hParent = Default, $idDummy = Default)
	__DW("_UC_Destroy($hParent=" & $hParent & ", $idDummy=" & $idDummy & ")" & @CRLF, 1, ">>> UC_Frame_Generic.au3")

	Local $m, $aAll = _UC_Properties(Default)

	; $hParent=Default => Bulk Delete All
	If $hParent = Default Then
		For $i = 3 To $aAll[0]
			$m = $aAll[$i]
			If IsMap($m) Then
				_UC_Timer_Remove($idDummy)
				If MapExists($m, "UC_hWnd") Then
					_WinAPI_RemoveProp($m.UC_hWnd, "UC_ControlID")
					GUIDelete($m.UC_hWnd)
				EndIf
				_UC_Properties($i, "@Delete", True, "UC_Frame_Generic.au3")
			EndIf
		Next
		Return 1
	Else
		; $idDummy=Default => Bulk delete All from $hParent   UC_hParent
		If $idDummy = Default Then
			For $i = 3 To $aAll[0]
				$m = $aAll[$i]
				If IsMap($m) Then
					_UC_Timer_Remove($idDummy)
					If MapExists($m, "UC_hWnd") Then
						If $m.UC_hParent = $hParent Then
							_WinAPI_RemoveProp($m.UC_hWnd, "UC_ControlID")
							GUIDelete($m.UC_hWnd)
							_UC_Properties($i, "@Delete", True, "UC_Frame_Generic.au3")
						EndIf
					EndIf
				EndIf
			Next
			Return 1
		Else
			; Individual deletion
			$m = $aAll[$idDummy]
			If IsMap($m) Then
				_UC_Timer_Remove($idDummy)
				If MapExists($m, "UC_hWnd") Then
					_WinAPI_RemoveProp($m.UC_hWnd, "UC_ControlID")
					GUIDelete($m.UC_hWnd)
				EndIf
				Return _UC_Properties($idDummy, "@Delete", True, "UC_Frame_Generic.au3")
			EndIf
		EndIf
	EndIf
EndFunc   ;==>_UC_Destroy

Func _UC_Refresh($hWnd)
	Return _WinAPI_RedrawWindow($hWnd, 0, 0, BitOR($RDW_INVALIDATE, $RDW_UPDATENOW, $RDW_ALLCHILDREN))
EndFunc   ;==>_UC_Refresh

Func _UC_GUISetBkColor000($iBkColor, $hWnd) ; 🚧
	GUISetBkColor($iBkColor, $hWnd)
	_WinAPI_SetProp($hWnd, "UC_GUIBkColor", $iBkColor)
EndFunc   ;==>_UC_GUISetBkColor000

Func _UC_GUISetBkColor($iBkColor, $hWnd, $iRefresh = 0)
	Local $iMsg = GUISetBkColor($iBkColor, $hWnd)
	If $iMsg Then
		_UC_Properties(1, "UC_GUIBkColor_" & $hWnd, $iBkColor, "UC_Frame_Generic.au3")

		; Initialization (if not already done)
		__UC_Framework_Init($hWnd)

		; check what is set in [Themes] -> Default
		Local $sDefault = _UC_Themes("ThemeConfig", "Default")

		If $sDefault = "auto" Then
			Local $sTarget = _UC_IsLightColor($iBkColor) ? _UC_Themes("ThemeConfig", "DefaultLight") : _UC_Themes("ThemeConfig", "DefaultDark")
			_UC_Themes("Active", _UC_Themes($sTarget))
		Else
			_UC_Themes("Active", _UC_Themes($sDefault))
		EndIf

		; Trigger for Redraw on all controls in $hWnd
		If $iRefresh = 1 Then _UC_Refresh($hWnd)
	EndIf
	Return $iMsg
EndFunc   ;==>_UC_GUISetBkColor

Func _UC_GetContrastColor($iBkColor) ;, $iPrecent = 20) 🚧
	; Extract RGB components
	Local $iR = BitAND(BitShift($iBkColor, 16), 0xFF)
	Local $iG = BitAND(BitShift($iBkColor, 8), 0xFF)
	Local $iB = BitAND($iBkColor, 0xFF)

	; Calculate perceived brightness
	Local $iLuminance = (0.299 * $iR) + (0.587 * $iG) + (0.114 * $iB)

	; Calculate Hover and Pressed colors (Logic: BGR for WinAPI)
;~ 	Local $iBGR = _WinAPI_SwitchColor($iBkColor)

	; If background is bright, return a semi-transparent dark stroke
	; If background is dark, return a semi-transparent light stroke
	If $iLuminance > 128 Then
		Return 0x80000000 ; Semi-transparent Black
;~ 		Return _WinAPI_SwitchColor(_WinAPI_ColorAdjustLuma($iBGR, - $iPrecent)) ; 20%  Darker
	Else
		Return 0x80FFFFFF ; Semi-transparent White
;~ 		Return _WinAPI_SwitchColor(_WinAPI_ColorAdjustLuma($iBGR, $iPrecent))  ; 20% Lighter
	EndIf

EndFunc   ;==>_UC_GetContrastColor

Func _UC_IsLightColor($iBkColor)
	; Determines whether a given RGB color is light or dark based on perceived brightness.

	; Extract RGB components from the standard RGB color value
	Local $iR = BitAND(BitShift($iBkColor, 16), 0xFF)
	Local $iG = BitAND(BitShift($iBkColor, 8), 0xFF)
	Local $iB = BitAND($iBkColor, 0xFF)

	; Calculate perceived brightness (Luminance formula)
	Local $iLuminance = (0.299 * $iR) + (0.587 * $iG) + (0.114 * $iB)

	; Return True if light (Luminance > 128), otherwise False
	If $iLuminance > 130 Then
		Return True
	Else
		Return False
	EndIf
EndFunc   ;==>_UC_IsLightColor

Func _UC_SetCursor($idCtrl, $iCursorID = 0)
	Local $hWnd = _UC_Get($idCtrl, "UC_hWnd")
	Return GUISetCursor($iCursorID, 0, $hWnd)
EndFunc   ;==>_UC_SetCursor

Func _UC_ToolTip($sText, $iX = -1, $iY = -1, $hParent = 0)
	Local Static $hToolTipGUI = 0, $idLabel = 0, $idFrame = 0
	Local $m = _UC_Properties(1, Default, Default, "UC_Frame_Generic.au3") ; Retrieve global properties/settings context

	; Initialization (Run once)
	If $hToolTipGUI = 0 Then
		; Create popup window with ToolWindow style to hide from taskbar
		$hToolTipGUI = GUICreate("UC_ToolTip", 100, 20, -1, -1, $WS_POPUP, BitOR($WS_EX_TOOLWINDOW, $WS_EX_TOPMOST, $WS_EX_TRANSPARENT), $hParent)
		$m.UC_ToolTip_hWnd = $hToolTipGUI

		; Default Style Settings
		Local $iBk = 0xFFF8D4 ; Classic tooltip yellow
		$m.UC_ToolTip_BkColor = $iBk
		$m.UC_ToolTip_TxtColor = ($iBk < 0x888888 ? 0xFFFFFF : 0x000000)
		$m.UC_ToolTip_Transparency = 220
		$m.UC_ToolTip_FontName = "Segoe UI"
		$m.UC_ToolTip_FontSize = 9
		$m.UC_ToolTip_FontWeight = 400
		$m.UC_ToolTip_FontAttribute = 0

		; Create GUI Controls
		$idFrame = GUICtrlCreateLabel("", 0, 0, 100, 20, $SS_BLACKFRAME)
		GUICtrlSetState(-1, $GUI_DISABLE)

		$idLabel = GUICtrlCreateLabel("", 5, 2, 90, 16)
		GUICtrlSetColor(-1, $m.UC_ToolTip_TxtColor)
		GUICtrlSetFont(-1, $m.UC_ToolTip_FontSize, $m.UC_ToolTip_FontWeight, $m.UC_ToolTip_FontAttribute, $m.UC_ToolTip_FontName)

		GUISetBkColor($m.UC_ToolTip_BkColor, $hToolTipGUI)
		WinSetTrans($hToolTipGUI, "", $m.UC_ToolTip_Transparency)

		GUISwitch($hParent) ; 🚧 test
	EndIf

	; Handle Hide State
	If $sText == "" Then
		If BitAND(WinGetState($hToolTipGUI), 2) Then GUISetState(@SW_HIDE, $hToolTipGUI)
		$m.UC_ToolTip_Text = ""
		_UC_Properties(1, $m, False, "UC_Frame_Generic.au3") ; update the map
		Return
	EndIf

	; Optimization: Skip update if text is unchanged (only update position)
	If $m.UC_ToolTip_Text = $sText Then
		If $iX = -1 Then
			Local $aPos = MouseGetPos()
			WinMove($hToolTipGUI, "", $aPos[0] + 15, $aPos[1] + 15)
		EndIf
		Return
	EndIf

	$m.UC_ToolTip_Text = $sText   ; Update stored text
	_UC_Properties(1, $m, False, "UC_Frame_Generic.au3")  ; update the map

	; Dynamic Sizing Logic
	Local $aTextSize = _UC_GetTextSize($sText, $m.UC_ToolTip_FontName, $m.UC_ToolTip_FontSize)

	Local $iWidth = $aTextSize[0] + 10  ; Add horizontal padding
	Local $iHeight = $aTextSize[1] + 4  ; Add vertical padding
	If $iWidth < 40 Then $iWidth = 40   ; Enforce minimum width

	; Positioning
	If $iX = -1 Then
		Local $aMousePos = MouseGetPos()
		$iX = $aMousePos[0] + 15
		$iY = $aMousePos[1] + 15
	EndIf

	If $iX + $iWidth > @DesktopWidth Then $iX = @DesktopWidth - $iWidth
	If $iY + $iHeight > @DesktopHeight Then $iY = @DesktopHeight - $iHeight

	; Apply Changes and Display
	WinMove($hToolTipGUI, "", $iX, $iY, $iWidth, $iHeight)
	GUICtrlSetPos($idFrame, 0, 0, $iWidth, $iHeight)
	GUICtrlSetPos($idLabel, 5, 2, $iWidth - 10, $iHeight - 4)
	GUICtrlSetData($idLabel, $sText)

	; Show without stealing focus
	If Not BitAND(WinGetState($hToolTipGUI), 2) Then GUISetState(@SW_SHOWNOACTIVATE, $hToolTipGUI)
EndFunc   ;==>_UC_ToolTip

Func _UC_GetTextSize($sString, $sFont = "Segoe UI", $fFontSize = 9, $iFontStyle = 0)
	Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND(_WinAPI_GetDesktopWindow())
	Local $hFamily = _GDIPlus_FontFamilyCreate($sFont)
	Local $hFont = _GDIPlus_FontCreate($hFamily, $fFontSize, $iFontStyle)
	Local $hFormat = _GDIPlus_StringFormatCreate()
	Local $tLayout = _GDIPlus_RectFCreate(0, 0, 0, 0)

	; aInfo[0] contains the $tagGDIPRECTF with the calculated dimensions
	Local $aInfo = _GDIPlus_GraphicsMeasureString($hGraphics, $sString, $hFont, $tLayout, $hFormat)

	Local $aSize[2]
	If Not @error Then
		$aSize[0] = Ceiling(DllStructGetData($aInfo[0], "Width"))
		$aSize[1] = Ceiling(DllStructGetData($aInfo[0], "Height"))
	Else
		$aSize[0] = 0
		$aSize[1] = 0
	EndIf

	; Cleanup resources
	_GDIPlus_StringFormatDispose($hFormat)
	_GDIPlus_FontDispose($hFont)
	_GDIPlus_FontFamilyDispose($hFamily)
	_GDIPlus_GraphicsDispose($hGraphics)

	Return $aSize
EndFunc   ;==>_UC_GetTextSize

; Returns the maximum font size that fits within the given width and height ; 🚧
Func _UC_GetFitFontSize($sText, $sFont, $fStartSize, $iMaxWidth, $iMaxHeight, $iFontStyle = 0)
	Local $fFontSize = $fStartSize
	Local $aSize

	While $fFontSize > 4
		$aSize = _UC_GetTextSize($sText, $sFont, $fFontSize, $iFontStyle)

		; Check if width or height exceeds the limits
		If $aSize[0] > $iMaxWidth Or $aSize[1] > $iMaxHeight Then
			$fFontSize -= 0.5 ; Decrease font size and try again
		Else
			ExitLoop ; It fits!
		EndIf
	WEnd
	Return $fFontSize
EndFunc   ;==>_UC_GetFitFontSize

Func _UC_IsMouseOver($hWnd)
	Local $tPoint = _WinAPI_GetMousePos()
	Return (_WinAPI_WindowFromPoint($tPoint) = $hWnd)
EndFunc   ;==>_UC_IsMouseOver

Func _UC_SetState($idCtrl, $iState)
	; Get the Control's Properties
	Local $m = _UC_Properties($idCtrl)
	If Not IsMap($m) Then Return SetError(1, 0, False)

	; Apply the State (e.g. @SW_HIDE or @SW_SHOW) to the Control's internal GUI $m.UC_hWnd
	Local $hCtrlWnd = MapExists($m, "UC_hWnd") ? $m.UC_hWnd : 0
	If $hCtrlWnd Then GUISetState($iState, $hCtrlWnd)

	; If we hide it, we instantly turn off its shadow
	If $iState = @SW_HIDE Then
		Local $hOverlayWnd = MapExists($m, "UC_Shadow_Overlay_hWnd") ? $m.UC_Shadow_Overlay_hWnd : 0
		If WinExists($hOverlayWnd) Then
			GUIDelete($hOverlayWnd)
			$m.UC_Shadow_Overlay_hWnd = 0
			_UC_Properties($idCtrl, $m, False)
		EndIf
	EndIf

	Return True
EndFunc   ;==>_UC_SetState
#EndRegion ; ~~~~~~~~~~~~~ UC_Framework Generic API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
