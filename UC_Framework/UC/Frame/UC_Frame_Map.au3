#include-once ; UC_Frame_Map.au3

#include "UC_Frame.au3"

#Region ; ~~~~~~~~~~~~~ UC_Framework Functions for Map Management ~~~~~~~~~~~~~~~~~~~~~
Func _Map2D(Const ByRef $mMap)
	Local $aMapKeys = MapKeys($mMap)
	Local $aMap2D[UBound($aMapKeys)][2]
	For $i = 0 To UBound($aMapKeys) - 1
		$aMap2D[$i][0] = $aMapKeys[$i]
		$aMap2D[$i][1] = $mMap[$aMapKeys[$i]]
	Next
	Return $aMap2D
EndFunc   ;==>_Map2D

Func _ClearMap(ByRef $mMap)
	Local $m[]
	$mMap = $m
EndFunc   ;==>_ClearMap

Func _MapCW(ByRef $m, $sTitle = "~~~ Map info ~~~", $sLastLn = Default, $iIndent = 0) ; ConsoleWrite map
	If $iIndent = 0 Then ConsoleWrite($sTitle & @CRLF)
	Local $aObject = _Map2D($m)
	Local $iMaxKeyLen = 0
	Local $sKey
	For $i = 0 To UBound($aObject) - 1
		$sKey = $aObject[$i][0]
		If StringLen($sKey) > $iMaxKeyLen Then
			$iMaxKeyLen = StringLen($sKey)
		EndIf
	Next

	For $i = 0 To UBound($aObject) - 1
		$sKey = $aObject[$i][0]
		Local $vValue = $aObject[$i][1]
		Local $sPadding = _StringRepeat(" ", $iMaxKeyLen - StringLen($sKey) + 1)
		Local $sDim, $sLabel = ""
		Local $iDimension
		Local $sPrefix = _StringRepeat(" ", $iIndent * 4)

		If IsMap($vValue) Then
			$sLabel = "= {Map[" & UBound($vValue) & "]}"
			ConsoleWrite($sPrefix & $sKey & $sPadding & $sLabel & @CRLF)
			_MapCW($vValue, "", "", $iIndent + 1) ; Recursion
		ElseIf IsArray($vValue) Then
			$iDimension = UBound($vValue, $UBOUND_DIMENSIONS) ; The dimension of the array e.g. 1/2/3 dimensional.
			$sDim = ""
			For $d = 1 To $iDimension
				$sDim &= "[" & UBound($vValue, $d) & "]"
			Next
			$sLabel = "= {Array" & $sDim & "}"

			ConsoleWrite($sPrefix & $sKey & $sPadding & $sLabel & @CRLF)
		Else
			ConsoleWrite($sPrefix & $sKey & $sPadding & "= " & $vValue & @CRLF)
		EndIf
	Next

	If $sLastLn = Default Then $sLastLn = _StringRepeat("~", StringLen($sTitle))

	If $iIndent = 0 Then ConsoleWrite($sLastLn & @CRLF)

EndFunc   ;==>_MapCW

Func _Map_GetfromIni($sFilePath, $sSection = "")
	If Not FileExists($sFilePath) Then Return SetError(1, 0, -1) ; !Error Ini File NOT Exist

	; If the user requested a specific section, we read that directly.
	If $sSection <> "" Then
		Local $aKey = IniReadSection($sFilePath, $sSection)
		If @error Then Return SetError(2, 0, -1) ; !Error section NOT Exist

		Local $mKey[]
		For $i = 1 To $aKey[0][0]
			$mKey[$aKey[$i][0]] = __UC_ParseValue($aKey[$i][1])
		Next
		Return $mKey
	EndIf

	; If it did NOT request a section, we read everything Recursion
	Local $aSectionName = IniReadSectionNames($sFilePath)
	Local $mNewMap[]
	For $R = 1 To $aSectionName[0]
		$mNewMap[$aSectionName[$R]] = _Map_GetfromIni($sFilePath, $aSectionName[$R])
	Next
	Return $mNewMap
EndFunc   ;==>_Map_GetfromIni

Func _Map_SaveToIni(ByRef $mMap, $sFilePath, $sSection = "")
	Local $aSectionName, $mKey, $aKey, $Data

	If $sSection <> "" Then
		Local $mTemp[]
		$mTemp[$sSection] = $mMap
		$mMap = $mTemp
	EndIf

	$aSectionName = MapKeys($mMap)
	$mKey = $mMap[$aSectionName[0]]
	$aKey = MapKeys($mKey)
	For $R = 0 To UBound($aSectionName) - 1
		$mKey = $mMap[$aSectionName[$R]]
		$aKey = MapKeys($mKey)
		Local $iRowsCnt = UBound($aKey)
		Local $aSection[$iRowsCnt + 1][2]
		$aSection[0][0] = $iRowsCnt
		For $i = 0 To $iRowsCnt - 1
			$Data = $mKey[$aKey[$i]]
			;ConsoleWrite($i & ") " & $aKey[$i] & ":" & $Data & @CRLF)
			$aSection[$i + 1][0] = $aKey[$i]
			$aSection[$i + 1][1] = $Data
		Next
		; Write the array to the section labelled $aSectionName[$R].
		IniWriteSection($sFilePath, $aSectionName[$R], $aSection)
	Next
;~ 	_ArrayDisplay($aSection, "$aSection")
EndFunc   ;==>_Map_SaveToIni

Func __UC_ParseValue($sVal)
	; check if it is numeric (Hex, Int, Float)
	If StringLeft($sVal, 2) = "0x" Or StringIsInt($sVal) Or StringIsFloat($sVal) Then
		Return Number($sVal)
	EndIf

	; check if it is Booleans
	If $sVal = "True" Then Return True
	If $sVal = "False" Then Return False

	; String
	Return $sVal
EndFunc   ;==>__UC_ParseValue
#EndRegion ; ~~~~~~~~~~~~~ UC_Framework Functions for Map Management ~~~~~~~~~~~~~~~~~~~~~
