; ========== AUTO CORRECTION LOG and ANALYZER === Version 2-9-2024 =============
; Determines frequency of items in below list, then sorts by f.  
; Date not factored in sort. There's no hotkey, just run the script.  
; It reports the top X hotstrings that were immediately followed by 
; 'Backspace' (<<), and how many times they were used without backspacing (--)).
; Sort one or the other. Intended for use with kunkel321's 'AutoCorrect for v2.'
;===============================================================================
#SingleInstance
#Requires AutoHotkey v2+
^Esc::ExitApp ; Ctrl+Esc to Kill/End process, if you're tired of waiting... 
; Ctrl+C on MessageBox will send report to Clipboard.  
; Note: 1300 items takes about 1 second, but 10k lines takes 44 seconds. 2310 takes ~3.

;===============================================================================
getStartLine() ; Go get line number where hotstrings start, then come back...
SortByBS := 1 ; Set to 0 to sort by OK items. Set to 1 to sort by BackSpaced item count. 
ShowX := 40 ; Show top X results. 
;===============================================================================
AllStrs := FileRead(A_ScriptName) ; ahk file... Know thyself. 
TotalLines := StrSplit(AllStrs, "`n").Length ; Determines number of lines for Prog Bar range.
pg := Gui()
pg.Opt("-MinimizeBox +alwaysOnTop +Owner")
MyProgress := pg.Add("Progress", "w400 h30 cGreen Range0-" . TotalLines, "0")
reportType := "Top " ShowX (SortByBS? " backspaced autocorrects." : " kept autocorrects.")
pg.Title := reportType "  Percent complete: 0 %." ; Starting title (immediately gets updated below.)
pg.Show()

Loop parse AllStrs, "`n`r"
{	MyProgress.Value += 1
	; pg.Title := "Lines of file remaining: " (TotalLines - MyProgress.Value) "..." ; For progress bar.
	pg.Title := reportType "  Percent complete: " Round((MyProgress.Value/TotalLines)*100) "%." ; For progress bar.
	If A_Index < startLine || InStr(A_LoopField, "Cap ") ; Skip these.
		Continue
	okTally := 0, bsTally := 0
	oStr := SubStr(A_LoopField, 15) ; o is "outter loop"
	Loop parse AllStrs, "`n`r" {
		If A_Index < startLine || InStr(A_LoopField, "Cap ") ; Skip these.
			Continue
		iStr := SubStr(A_LoopField, 15) ; i is "inner loop"
		If iStr = oStr { 
			If SubStr(A_LoopField, 12, 2) = "--" ; "--" means the item was logged, and backspace was not pressed.
				okTally++
			If SubStr(A_LoopField, 12, 2) = "<<" ; "<<" means Backspace was pressed right after autocorrection.
				bsTally++
		}
	}
	If SortByBS = 1 
		Report .=  bsTally "<< and " okTally "-- for" ((bsTally>9 or okTally>9)? "oneTab":"twoTabs") oStr "`n"
	else 
		Report .=  okTally "-- and " bsTally "<< for" ((okTally>9 or bsTally>9)? "oneTab":"twoTabs") oStr "`n"
	AllStrs := strReplace(AllStrs, oStr, "Cap fix") ; Replace it with 'cap fix' so we don't keep finding it.
}

Report := Sort(Sort(Report, "/U"), "NR") ; U is 'remove duplicates.' NR is 'numeric' and 'reverse sort.'
For idx, item in strSplit(Report, "`n")
	If idx <= ShowX ; Only use first X lines.
		trunkReport .= item "`n"
	else break
msgTrunkReport := strReplace(strReplace(trunkReport, "oneTab", "`t"), "twoTabs", "`t") ; So right colomn lines up in msgboxes.
txtTrunkReport := strReplace(strReplace(trunkReport, "oneTab", "`t"), "twoTabs", "`t`t") ; So right colomn lines up in text editors.

pg.Destroy() ; Remove progress bar.
msgbox reportType "`n=====================`n" msgTrunkReport, "Autocorrect Report"
ExitApp ; Kill script when msgbox is closed. 
#HotIf WinActive("Autocorrect Report") ; Ctrl+C sends report to clipboard, but only if msgbox is active window. 
^c::A_Clipboard := reportType "`n=====================`n" txtTrunkReport
#HotIf

getStartLine(*) {
	Global startLine := A_LineNumber + 2
}

2024-05-17		 << 		::isnt
2024-05-17		 -- 		:?:hte
2024-05-17		 -- 		::adn
2024-05-17		 -- 		:*:hti
2024-05-17		 << 		:?:;s
2024-05-17		 -- 		::ot
2024-05-17		 << 		::ot
2024-05-17		 << 		:?:teh
2024-05-17		 -- 		:*?:metn
2024-05-17		 -- 		::cleint
2024-05-17		 -- 		:?:hte
2024-05-20		 << 		::ot
2024-05-20		 -- 		::ot
2024-05-20		 -- 		:*?:iht
