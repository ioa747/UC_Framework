; UC_Frame_Map.au3
#include-once

#include "UC_Frame.au3"

#include <AutoItConstants.au3>

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

Func _MapCW(ByRef $m, $sTitle = "--- Map info ---", $iIndent = 0) ; ConsoleWrite map
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

		If IsMap($vValue) Then
			$sLabel = "= {Map[" & UBound($vValue) & "]}"
			ConsoleWrite($sKey & $sPadding & $sLabel & @CRLF)
			_MapCW($vValue, "", $iIndent + 1) ; Recursion
		ElseIf IsArray($vValue) Then
			$iDimension = UBound($vValue, $UBOUND_DIMENSIONS) ; The dimension of the array e.g. 1/2/3 dimensional.
			$sDim = ""
			For $d = 1 To $iDimension
				$sDim &= "[" & UBound($vValue, $d) & "]"
			Next
			$sLabel = "= {Array" & $sDim & "}"

			ConsoleWrite($sKey & $sPadding & $sLabel & @CRLF)
		Else
			ConsoleWrite($sKey & $sPadding & "= " & $vValue & @CRLF)
		EndIf
	Next
EndFunc   ;==>_MapCW

#EndRegion ; ~~~~~~~~~~~~~ Helper Functions for Map Management ~~~~~~~~~~~~~~~~~~~~~~~~~~~
