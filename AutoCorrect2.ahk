#SingleInstance
SetWorkingDir(A_ScriptDir)
SetTitleMatchMode("RegEx")
#Requires AutoHotkey v2+


NameOfThisFile := "AutoCorrect2.ahk"

mediaFolder := A_ScriptDir '\Icons'
libFolder := A_ScriptDir '\Lib'

MyAhkEditorPath := "C:\Users\" . A_UserName . "\AppData\Local\Programs\Microsoft VS Code\Code.exe"

WordListFile := 'GitHubComboList249k.txt'
WordListPath := A_ScriptDir '\WordListsForHH\' . WordListFile

if (FileExist(A_ScriptDir "\DateTool.ahk"))
#Include "DateTool.ahk"
else if (FileExist(libFolder "\DateTool.ahk"))
#Include libFolder "\DateTool.ahk"
else
	MsgBox("DateTool.ahk not found in the script folder or the lib folder.  DateTool will not be available.")

If (!FileExist(MyAhkEditorPath))
{
	MsgBox("This error means that the variable 'MyAhkEditorPath' has"
		"`nnot been assigned a valid path for an editor."
		"`nTherefore Notepad will be used as a substite.")

	MyAhkEditorPath := "Notepad.exe"
}

If (!FileExist(WordListPath))
{
	MsgBox("This error means that the big list of comparison words at:`n" . WordListPath .
		"`nwas not found.`n`nTherefore the 'Exam' button of the Hotstring Helper tool won't work.")
}


TraySetIcon(mediaFolder . "\Psicon.ico")

acMenu := A_TrayMenu

acMenu.Delete

acMenu.Add("Edit This Script", EditThisScript)
acMenu.Add("Run Printer Tool", PrinterTool)
acMenu.Add("System Up Time", UpTime)
acMenu.Add("Reload Script", (*) => Reload())
acMenu.Add("List Lines Debug", (*) => ListLines())
acMenu.Add("Exit Script", (*) => ExitApp())

acMenu.SetIcon("Edit This Script", mediaFolder . "\edit-Blue.ico")
acMenu.SetIcon("Run Printer Tool", mediaFolder . "\printer-Blue.ico")
acMenu.SetIcon("System Up Time", mediaFolder . "\clock-Blue.ico")
acMenu.SetIcon("Reload Script", mediaFolder . "\repeat-Blue.ico")
acMenu.SetIcon("List Lines Debug", mediaFolder . "\ListLines-Blue.ico")
acMenu.SetIcon("Exit Script", mediaFolder . "\exit-Blue.ico")

acMenu.SetColor("Silver")

SoundBeep(900, 250)
SoundBeep(1100, 200)

GuiColor := "F5F5DC"
FontColor := "003366"


myGreen := 'c1D7C08'
myRed := 'cB90012'
myBigFont := 's13'
AutoLookupFromValidityCheck := 0

hh_Hotkey := "#h"

hhFormName := "HotString Helper 2"

HeightSizeIncrease := 300
WidthSizeIncrease := 400


myPilcrow := "¶"
myDot := "• "
myTab := "⟹ "


DefaultBoilerPlateOpts := ""

myPrefix := ";"

addFirstLetters := 5
tooSmallLen := 2
mySuffix := ""

DefaultAutoCorrectOpts := "*"

AutoCommentFixesAndMisspells := 1
AutoEnterNewEntry := 1

logIsRunning := 0
savedUpText := ''
intervalCounter := 0
saveIntervalMinutes := saveIntervalMinutes * 60 * 1000


SplitPath WordListPath, &WordListName


#HotIf WinActive(hhFormName)

	$Enter::
	{
		If (hh['SymTog'].text = "Hide Symb")
			return
		Else if ReplaceString.Focused
		{
			Send("{Enter}")
			Return
		}
		Else hhButtonAppend()
	}

	+Left::
	{
		TriggerString.Focus()
		Send "{Home}"
	}

	Esc::
	{
		hh.Hide()
		A_Clipboard := ClipboardOld
	}

	^z:: GoUndo()

	^+z:: GoReStart()

	^Up::

	^WheelUp::
	{
		MyDefaultOpts.SetFont('s15')
		TriggerString.SetFont('s15')
		ReplaceString.SetFont('s15')
	}

	^Down::

	^WheelDown::
	{
		MyDefaultOpts.SetFont('s11')
		TriggerString.SetFont('s11')
		ReplaceString.SetFont('s11')
	}

#HotIf

hh := Gui('', hhFormName)

hh.BackColor := GuiColor
FontColor := FontColor != "" ? "c" . FontColor : ""
hFactor := 0, wFactor := 0

hh.Opt("-MinimizeBox +alwaysOnTop")
hh.SetFont("s11 " . FontColor)

hh.AddText('y4 w30', 'Options')
(TrigLbl := hh.AddText('x+40 w250', 'Trigger String'))
(MyDefaultOpts := hh.AddEdit('cDefault yp+20 xm+2 w70 h24'))
(TriggerString := hh.AddEdit('cDefault x+18 w' . wFactor + 280, '')).OnEvent('Change', TriggerChanged)

hh.SetFont('s9')
hh.AddText('xm', 'Replacement')
hh.AddButton('vSizeTog x+75 yp-5 h8 +notab', 'Make Bigger').OnEvent("Click", TogSize)
hh.AddButton('vSymTog x+5 h8 +notab', '+ Symbols').OnEvent("Click", TogSym)
hh.SetFont('s11')
(ReplaceString := hh.AddEdit('cDefault vReplaceString +Wrap y+1 xs h' . hFactor + 100 . ' w' . wFactor + 370, '')).OnEvent('Change', GoFilter)

ComLbl := hh.AddText('xm y' . hFactor + 182, 'Comment')
(ChkFunc := hh.AddCheckbox('vFunc, x+70 y' . hFactor + 182, 'Make Function')).onEvent('click', FormAsFunc)
ChkFunc.Value := 1
ComStr := hh.AddEdit('cGreen vComStr xs y' . hFactor + 200 . ' w' . wFactor + 370)

(ButApp := hh.AddButton('xm y' . hFactor + 234, 'Append')).OnEvent("Click", hhButtonAppend)
(ButCheck := hh.AddButton('+notab x+5 y' . hFactor + 234, 'Check')).OnEvent("Click", hhButtonCheck)
(ButExam := hh.AddButton('+notab x+5 y' . hFactor + 234, 'Exam'))
ButExam.OnEvent("Click", hhButtonExam)
ButExam.OnEvent("ContextMenu", subFuncExamControl)
(ButSpell := hh.AddButton('+notab x+5 y' . hFactor + 234, 'Spell')).OnEvent("Click", hhButtonSpell)
(ButOpen := hh.AddButton('+notab x+5 y' . hFactor + 234, 'Open')).OnEvent("Click", hhButtonOpen)
(ButCancel := hh.AddButton('+notab x+5 y' . hFactor + 234, 'Cancel')).OnEvent("Click", hhButtonCancel)
hh.OnEvent("Close", hhButtonCancel)

hh.SetFont('s10')
(ButLTrim := hh.AddButton('vbutLtrim xm h50  w' . (wFactor + 182 / 6), '>>')).onEvent('click', GoLTrim)

hh.SetFont('s14')
(TxtTypo := hh.AddText('vTypoLabel -wrap +center cBlue x+1 w' . (wFactor + 182 * 5 / 3), hhFormName))

hh.SetFont('s10')
(ButRTrim := hh.AddButton('vbutRtrim x+1 h50 w' . (wFactor + 182 / 6), '<<')).onEvent('click', GoRTrim)

hh.SetFont('s11')
(RadBeg := hh.AddRadio('vBegRadio y+-18 x' . (wFactor + 182 / 3), '&Beginnings')).onEvent('click', GoFilter)
(RadMid := hh.AddRadio('vMidRadio x+5', '&Middles')).onEvent('click', GoMidRadio)
(RadEnd := hh.AddRadio('vEndRadio x+5', '&Endings')).onEvent('click', GoFilter)

(ButUndo := hh.AddButton('xm y+3 h26 w' . (wFactor + 182 * 2), "Undo (+Reset)")).OnEvent('Click', GoUndo)
ButUndo.Enabled := false

hh.SetFont('s12')
(TxtTLable := hh.AddText('vTrigLabel center y+4 h25 xm w' . wFactor + 182, 'Misspells'))
(TxtRLable := hh.AddText('vReplLabel center h25 x+5 w' . wFactor + 182, 'Fixes'))
(EdtTMatches := hh.AddEdit('cDefault vTrigMatches y+1 xm h' . hFactor + 300 . ' w' . wFactor + 182,))
(EdtRMatches := hh.AddEdit('cDefault vReplMatches x+5 h' . hFactor + 300 . ' w' . wFactor + 182,))

hh.SetFont('bold s10')
(TxtWordList := hh.AddText('vWordList center xm y+1 h14 w' . wFactor * 2 + 364, WordListName)).OnEvent('DoubleClick', ChangeWordList)

ShowHideButtonExam(Visibility := False)

(TxtCtrlLbl1 := hh.AddText(' center cBlue ym+270 h25 xm w' . wFactor + 370, 'Secret Control Panel!'))

hh.SetFont('s10')
(butRunAcLog := hh.AddButton('  y+5 h25 xm w' . wFactor + 370, 'Open AutoCorrection Log'))
butRunAcLog.OnEvent("click", (*) => ControlPaneRuns("butRunAcLog"))
(butRunMcLog := hh.AddButton('  y+5 h25 xm w' . wFactor + 370, 'Open Manual Correction Log'))
butRunMcLog.OnEvent("click", (*) => ControlPaneRuns("butRunMcLog"))
(butFixRep := hh.AddButton('y+5 h25 xm w' . wFactor + 370, 'Count HotStrings and Potential Fixes'))
butFixRep.OnEvent('Click', StringAndFixReport)

ShowHideButtonsControl(Visibility := False)

ControlPaneRuns(buttonIdentifier)
{
	if (buttonIdentifier = "butRunAcLog")
		Run MyAhkEditorPath " AutoCorrectsLog.ahk"
	else if (buttonIdentifier = "butRunMcLog")
		Run MyAhkEditorPath " ManualCorrectionLogger.ahk"
}

ShowHideButtonsControl(Visibility := False)
{
	ControlCmds := [TxtCtrlLbl1, butRunAcLog, butRunMcLog, butFixRep]
	for ctrl in ControlCmds
	{
		ctrl.Visible := Visibility
	}
}

ShowHideButtonExam(Visibility := False)
{
	examCmds := [ButLTrim, TxtTypo, ButRTrim, RadBeg, RadMid, RadEnd, ButUndo, TxtTLable, TxtRLable, EdtTMatches, EdtRMatches, TxtWordList]
	for ctrl in examCmds
	{
		ctrl.Visible := Visibility
	}
}

ExamPaneOpen := 0
ControlPaneOpen := 0

OrigTrigger := ""
OrigReplacment := ""
tArrStep := []
rArrStep := []

origTriggerTypo := ""

Hotkey hh_Hotkey, CheckClipboard

CheckClipboard(*)
{
	TrigLbl.SetFont(FontColor)

	Global ClipboardOld := ClipboardAll()
	Global Opts := ""
	Global Trig := ""
	Global Repl := ""
	Global OrigTrigger := ""
	Global OrigReplacement := ""
	Global strT := ""
	Global TrigNeedle_Orig := ""
	Global strR := ""
	Global tMatches := 0

	DefaultHotStr := ""
	EdtRMatches.CurrMatches := ""

	hsRegex := "(?Jim)^:(?<Opts>[^:]+)*:(?<Trig>[^:]+)::(?:f\((?<Repl>[^,)]*)[^)]*\)|(?<Repl>[^;\v]+))?(?<fCom>\h*;\h*(?:\bFIXES\h*\d+\h*WORDS?\b)?(?:\h;)?\h*(?<mCom>.*))?$"

	A_Clipboard := ""
	Send("^c")
	Errorlevel := !ClipWait(0.3)

	thisHotStr := Trim(A_Clipboard, " `t`n`r")

	If RegExMatch(thisHotStr, hsRegex, &hotstr)
	{
		thisHotStr := ""
		TriggerString.text := hotstr.Trig
		MyDefaultOpts.Value := hotstr.Opts

		sleep(200)

		OrigTrigger := hotstr.Trig
		hotstr.Repl := Trim(hotstr.Repl, '"')
		ReplaceString.text := hotstr.Repl
		ComStr.text := hotstr.mCom
		OrigReplacement := hotstr.Repl

		strT := hotstr.Trig
		TrigNeedle_Orig := hotstr.Trig
		strR := hotstr.Repl

		If InStr(hotstr.Opts, "*") && InStr(hotstr.Opts, "?")
			RadMid.Value := 1
		Else If InStr(hotstr.Opts, "*")
			RadBeg.Value := 1
		Else If InStr(hotstr.Opts, "?")
			RadEnd.Value := 1
		Else
			RadMid.Value := 1

		ExamineWords(strT, strR)
	}
	Else
	{
		strT := A_Clipboard
		TrigNeedle_Orig := strT
		strR := A_Clipboard
		NormalStartup(strT, strR)
	}

	ButUndo.Enabled := false
	Loop tArrStep.Length
		tArrStep.pop
	Loop rArrStep.Length
		rArrStep.pop
}

IsMultiLine := 0

NormalStartup(strT, strR)
{
	Global IsMultiLine := 0
	Global targetWindow := WinActive("A")
	Global origTriggerTypo := ""

	If ((StrLen(A_Clipboard) - StrLen(StrReplace(A_Clipboard, " ")) > 2) || InStr(A_Clipboard, "`n"))
	{
		DefaultOpts := DefaultBoilerPlateOpts
		ReplaceString.value := A_Clipboard
		IsMultiLine := 1
		ChkFunc.Value := 0
		If (addFirstLetters > 0)
		{
			initials := ""
			HotStrSug := StrReplace(A_Clipboard, "`n", " ")
			Loop Parse, HotStrSug, A_Space, A_Tab
			{
				If (Strlen(A_LoopField) > tooSmallLen)
					initials .= SubStr(A_LoopField, "1", "1")
				If (StrLen(initials) = addFirstLetters)
					break
			}
			initials := StrLower(initials)
			DefaultHotStr := myPrefix . initials . mySuffix
		}
		else
		{
			DefaultHotStr := myPrefix . mySuffix
		}
	}
	Else If (A_Clipboard = "")
	{
		MyDefaultOpts.Text := ""
		TriggerString.Text := ""
		ReplaceString.Text := ""
		ComStr.Text := ""
		RadBeg.Value := 0
		RadMid.Value := 0
		RadEnd.Value := 0
		GoFilter()
		hh.Show('Autosize yCenter')
		Return
	}
	else
	{
		If (AutoEnterNewEntry = 1)
			origTriggerTypo := A_Clipboard

		DefaultHotStr := Trim(StrLower(A_Clipboard))
		ReplaceString.value := Trim(StrLower(A_Clipboard))
		DefaultOpts := DefaultAutoCorrectOpts
	}

	MyDefaultOpts.text := DefaultOpts
	TriggerString.value := DefaultHotStr
	ReplaceString.Opt("-Readonly")
	ButApp.Enabled := true
	If ExamPaneOpen = 1
		goFilter()
	hh.Show('Autosize yCenter')
}

ExamineWords(strT, strR)
{
	Global beginning := ""
	Global typo := ""
	Global fix := ""
	Global ending := ""

	SubTogSize(0, 0)
	hh.Show('Autosize yCenter')

	ostrT := strT
	ostrR := strR
	LenT := strLen(strT)
	LenR := strLen(strR)

	LoopNum := min(LenT, LenR)
	strT := StrSplit(strT)
	strR := StrSplit(strR)

	If ostrT = ostrR
	{
		deltaString := "[ " ostrT " | " ostrR " ]"
		found := false
	}
	else
	{
		Loop LoopNum
		{
			bsubT := (strT[A_Index])
			bsubR := (strR[A_Index])
			If (bsubT = bsubR)
				beginning .= bsubT
			else
				break
		}

		Loop LoopNum
		{
			RevIndex := (LenT - A_Index) + 1
			esubT := (strT[RevIndex])
			RevIndex := (LenR - A_Index) + 1
			esubR := (strR[RevIndex])
			If (esubT = esubR)
				ending := esubT . ending
			else
				break
		}

		If (strLen(beginning) + strLen(ending)) > LoopNum
		{
			If (LenT > LenR)
			{
				delta := subStr(ending, 1, (LenT - LenR))
				delta := " [ " . delta . " |  ] "
			}
			If (LenR > LenT)
			{
				delta := subStr(ending, 1, (LenR - LenT))
				delta := " [  |  " . delta . " ] "
			}
		}
		Else
		{
			If strLen(beginning) > strLen(ending)
			{
				typo := StrReplace(ostrT, beginning, "")
				typo := StrReplace(typo, ending, "")
				fix := StrReplace(ostrR, beginning, "")
				fix := StrReplace(fix, ending, "")
			}
			Else
			{
				typo := StrReplace(ostrT, ending, "")
				typo := StrReplace(typo, beginning, "")
				fix := StrReplace(ostrR, ending, "")
				fix := StrReplace(fix, beginning, "")
			}
			delta := " [ " . typo . " | " . fix . " ] "
		}
		deltaString := beginning . delta . ending

	}
	TxtTypo.text := deltaString

	ViaExamButt := "Yes"
	GoFilter(ViaExamButt)

	If (ButExam.text = "Exam")
	{
		ButExam.text := "Done"
		If (hFactor != 0)
		{
			hh['SizeTog'].text := "Make Bigger"
			SoundBeep
			SubTogSize(0, 0)
		}
		ShowHideButtonExam(True)
	}

	hh.Show('Autosize yCenter')
}

TogSize(*)
{
	Global hFactor := ""

	If (hh['SizeTog'].text = "Make Bigger")
	{
		hh['SizeTog'].text := "Make Smaller"
		If (ButExam.text = "Done")
		{
			ShowHideButtonExam(Visibility := False)
			ExamPaneOpen := 0
			ShowHideButtonsControl(Visibility := False)
			ControlPaneOpen := 0
			ButExam.text := "Exam"
		}
		hFactor := HeightSizeIncrease
		SubTogSize(hFactor, WidthSizeIncrease)
		hh.Show('Autosize yCenter')
	}
	If (hh['SizeTog'].text = "Make Smaller")
	{
		hh['SizeTog'].text := "Make Bigger"
		hFactor := 0
		SubTogSize(0, 0)
		hh.Show('Autosize yCenter')
	}
	return
}

SubTogSize(hFactor, wFactor)
{
	TriggerString.Move(, , wFactor + 280,)
	ReplaceString.Move(, , wFactor + 372, hFactor + 100)
	ComLbl.Move(, hFactor + 182, ,)
	ComStr.move(, hFactor + 200, wFactor + 367,)
	ChkFunc.Move(, hFactor + 182, ,)
	ButApp.Move(, hFactor + 234, ,)
	ButCheck.Move(, hFactor + 234, ,)
	ButExam.Move(, hFactor + 234, ,)
	ButSpell.Move(, hFactor + 234, ,)
	ButOpen.Move(, hFactor + 234, ,)
	ButCancel.Move(, hFactor + 234, ,)
}

subFuncExamControl(*)
{
	Global ControlPaneOpen
	If ControlPaneOpen = 1
	{
		ButExam.text := "Exam"
		ShowHideButtonsControl(False)
		ControlPaneOpen := 0
	}
	Else
	{
		ButExam.text := "Done"
		If (hFactor = HeightSizeIncrease)
		{
			TogSize()
			hh['SizeTog'].text := "Make Bigger"
		}
		ShowHideButtonsControl(True)
		ControlPaneOpen := 1
	}
	ShowHideButtonExam(False)
	hh.Show('Autosize yCenter')
}

hhButtonExam(*)
{
	Global ExamPaneOpen
	Global ControlPaneOpen
	Global OrigTrigger
	Global OrigReplacement

	If ((ExamPaneOpen = 0) and (ControlPaneOpen = 0) and GetKeyState("Shift")) || ((ExamPaneOpen = 1) and (ControlPaneOpen = 0) and GetKeyState("Shift"))
	{
		subFuncExamControl()
	}
	Else If ((ExamPaneOpen = 0) and (ControlPaneOpen = 0))
	{
		ButExam.text := "Done"
		If (hFactor = HeightSizeIncrease)
		{
			TogSize()
			hh['SizeTog'].text := "Make Bigger"
		}
		OrigTrigger := TriggerString.text
		OrigReplacement := ReplaceString.text
		ExamineWords(OrigTrigger, OrigReplacement)
		goFilter()
		ShowHideButtonsControl(False)
		ShowHideButtonExam(True)
		ExamPaneOpen := 1
	}
	Else
	{
		ButExam.text := "Exam"
		ShowHideButtonsControl(False)
		ShowHideButtonExam(False)
		ExamPaneOpen := 0
		ControlPaneOpen := 0
	}
	hh.Show('Autosize yCenter')
}

TogSym(*)
{
	If (hh['SymTog'].text = "+ Symbols")
	{
		hh['SymTog'].text := "- Symbols"
		togReplaceString := ReplaceString.text
		togReplaceString := StrReplace(StrReplace(togReplaceString, "`r`n", "`n"), "`n", myPilcrow . "`n")
		togReplaceString := StrReplace(togReplaceString, A_Space, myDot)
		togReplaceString := StrReplace(togReplaceString, A_Tab, myTab)
		ReplaceString.value := togReplaceString
		ReplaceString.Opt("+Readonly")
		ButApp.Enabled := false
		hh.Show('Autosize yCenter')
	}
	If (hh['SymTog'].text = "- Symbols")
	{
		hh['SymTog'].text := "+ Symbols"
		togReplaceString := ReplaceString.text
		togReplaceString := StrReplace(togReplaceString, myPilcrow . "`r", "`r")
		togReplaceString := StrReplace(togReplaceString, myDot, A_Space)
		togReplaceString := StrReplace(togReplaceString, myTab, A_Tab)
		ReplaceString.value := togReplaceString
		ReplaceString.Opt("-Readonly")
		ButApp.Enabled := true
		hh.Show('Autosize yCenter')
	}
	return
}

TriggerChanged(*)
{
	Global TrigNeedle_Orig
	TrigNeedle_New := TriggerString.text
	If (TrigNeedle_New != TrigNeedle_Orig && ExamPaneOpen = 1)
	{
		If (TrigNeedle_Orig = SubStr(TrigNeedle_New, 2,))
		{
			tArrStep.push(TriggerString.text)
			rArrStep.push(ReplaceString.text)
			ReplaceString.Value := SubStr(TrigNeedle_New, 1, 1) . ReplaceString.text
		}
		If (TrigNeedle_Orig = SubStr(TrigNeedle_New, 1, StrLen(TrigNeedle_New) - 1))
		{
			tArrStep.push(TriggerString.text)
			rArrStep.push(ReplaceString.text)
			ReplaceString.text := ReplaceString.text . SubStr(TrigNeedle_New, -1,)
		}
		TrigNeedle_Orig := TrigNeedle_New
	}
	ButUndo.Enabled := true
	goFilter()
}

FormAsFunc(*)
{
	If (ChkFunc.Value = 1)
	{
		MyDefaultOpts.text := "B0X" StrReplace(StrReplace(MyDefaultOpts.text, "B0", ""), "X", "")
		SoundBeep 700, 200
	}
	else
	{
		MyDefaultOpts.text := StrReplace(StrReplace(MyDefaultOpts.text, "B0", ""), "X", "")
		SoundBeep 900, 200
	}
}

hhButtonAppend(*)
{
	Global tMyDefaultOpts := MyDefaultOpts.text
	Global tTriggerString := TriggerString.text
	Global tReplaceString := ReplaceString.text

	ValidationFunction(tMyDefaultOpts, tTriggerString, tReplaceString)

	If Not InStr(CombinedValidMsg, "-Okay.", , , 3)
		biggerMsgBox(CombinedValidMsg, 1)
	else
	{
		Appendit(tMyDefaultOpts, tTriggerString, tReplaceString)
		return
	}
}

hhButtonCheck(*)
{
	Global tMyDefaultOpts := MyDefaultOpts.text
	Global tTriggerString := TriggerString.text
	Global tReplaceString := ReplaceString.text
	ValidationFunction(tMyDefaultOpts, tTriggerString, tReplaceString)
	biggerMsgBox(CombinedValidMsg, 0)
	Return
}

bb := 0
biggerMsgBox(thisMess, secondButt)
{
	A_Clipboard := thisMess
	global bb
	if (IsObject(bb))
		bb.Destroy()
	Global bb := Gui(, 'Validity Report')
	bb.SetFont('s11 ' FontColor)
	bb.BackColor := GuiColor, GuiColor
	global mbTitle := ""
	(mbTitle := bb.Add('Text', , 'For proposed new item:')).Focus()
	bb.SetFont(myBigFont)
	proposedHS := ':' tMyDefaultOpts ':' tTriggerString '::' tReplaceString
	bb.Add('Text', (strLen(proposedHS) > 90 ? 'w600 ' : '') 'xs yp+22', proposedHS)
	bb.SetFont('s11 ')
	secondButt = 0 ? bb.Add('Text', , "===Validation Check Results===") : ''
	bb.SetFont(myBigFont)
	bbItem := StrSplit(thisMess, "*|*")
	If InStr(bbItem[2], "`n", , , 10)
		bbItem2 := subStr(bbItem[2], 1, inStr(bbItem[2], "`n", , , 10)) "`n## Too many conflicts to show in form ##"
	Else
		bbItem2 := bbItem[2]
	edtSharedSettings := ' -VScroll ReadOnly -E0x200 Background'
	bb.Add('Edit', (inStr(bbItem[1], '-Okay.') ? myGreen : myRed) edtSharedSettings GuiColor, bbItem[1])
	trigEdtBox := bb.Add('Edit', (strLen(bbItem2) > 104 ? ' w600 ' : ' ') (inStr(bbItem2, '-Okay.') ? myGreen : myRed) edtSharedSettings GuiColor, bbItem2)
	bb.Add('Edit', (strLen(bbItem[3]) > 104 ? ' w600 ' : ' ') (inStr(bbItem[3], '-Okay.') ? myGreen : myRed) edtSharedSettings GuiColor, bbItem[3])
	trigEdtBox.OnEvent('Focus', findInScript)
	bb.SetFont('s11 ' FontColor)
	secondButt = 1 ? bb.Add('Text', , "==============================`nAppend HotString Anyway?") : ''
	bbAppend := bb.Add('Button', , 'Append Anyway')
	bbAppend.OnEvent 'Click', (*) => Appendit(tMyDefaultOpts, tTriggerString, tReplaceString)
	bbAppend.OnEvent 'Click', (*) => bb.Destroy()
	if secondButt != 1
		bbAppend.Visible := False
	bbClose := bb.Add('Button', 'x+5 Default', 'Close')
	bbClose.OnEvent 'Click', (*) => bb.Destroy()
	If not inStr(bbItem2, '-Okay.')
		global bbAuto := bb.Add('Checkbox', 'x+5 Checked' AutoLookupFromValidityCheck, 'Auto Lookup`nin editor')
	bb.Show('yCenter x' (A_ScreenWidth / 2))
	WinSetAlwaysontop(1, "A")
	bb.OnEvent 'Escape', (*) => bb.Destroy()
}

findInScript(*)
{
	If (bbAuto.Value = 0)
		Return
	SoundBeep
	if (GetKeyState("LButton", "P"))
		KeyWait "LButton", "U"
	A_Clipboard := ""
	SendInput "^c"
	If !ClipWait(1, 0)
		Return
	if WinExist(NameOfThisFile)
		WinActivate NameOfThisFile
	else
	{
		Run MyAhkEditorPath " " NameOfThisFile
		While !WinExist(NameOfThisFile)
			Sleep 50
		WinActivate NameOfThisFile
	}
	If RegExMatch(A_Clipboard, "^\d{2,}")
		SendInput "^g" A_Clipboard
	else
	{
		SendInput "^f"
		sleep 200
		SendInput "^v"
	}
	mbTitle.Focus()
}

ValidationFunction(tMyDefaultOpts, tTriggerString, tReplaceString)
{
	GoFilter()
	Global CombinedValidMsg := "", validHotDupes := "", validHotMisspells := "", ACitemsStartAt
	ThisFile := Fileread(A_ScriptName)
	If (tMyDefaultOpts = "")
		validOpts := "Okay."
	else
	{
		NeedleRegEx := "(\*|B0|\?|SI|C|K[0-9]{1,3}|SE|X|SP|O|R|T)"
		WithNeedlesRemoved := RegExReplace(tMyDefaultOpts, NeedleRegEx, "")
		If (WithNeedlesRemoved = "")
			validOpts := "Okay."
		else
		{
			OptTips := inStr(WithNeedlesRemoved, ":") ? "Don't include the colons.`n" : ""
			OptTips .= "
			(
			...Tips from AHK v1 docs...
			* - ending char not needed
			? - trigger inside other words
			B0 - no backspacing
			SI - send input mode
			C - case-sensitive
			K(n) - set key delay
			SE - send event mode
			X - execute command
			SP - send play mode
			O - omit end char
			R - send raw
			T - super raw
			)"
			validOpts .= "Invalid Hotsring Options found.`n---> " WithNeedlesRemoved "`n" OptTips
		}
	}
	validHot := ""
	If (tTriggerString = "") || (tTriggerString = myPrefix) || (tTriggerString = mySuffix)
		validHot := "HotString box should not be empty."
	Else If InStr(tTriggerString, ":")
		validHot := "Don't include colons."
	else
	{
		Loop Parse, ThisFile, "`n", "`r"
		{
			If (A_Index < ACitemsStartAt) or (SubStr(trim(A_LoopField, " `t"), 1, 1) != ":")
				continue
			If RegExMatch(A_LoopField, "i):(?P<Opts>[^:]+)*:(?P<Trig>[^:]+)", &loo)
			{
				If (tTriggerString = loo.Trig) and (tMyDefaultOpts = loo.Opts)
				{
					validHotDupes := "`nDuplicate trigger string found at line " A_Index ".`n---> " A_LoopField
					Continue
				}
				If (InStr(loo.Trig, tTriggerString) and inStr(tMyDefaultOpts, "*") and inStr(tMyDefaultOpts, "?"))
					|| (InStr(tTriggerString, loo.Trig) and inStr(loo.Opts, "*") and inStr(loo.Opts, "?"))
				{
					validHotDupes .= "`nWord-Middle conflict found at line " A_Index ", where one of the strings will be nullified by the other.`n---> " A_LoopField
					Continue
				}
				If ((loo.Trig = tTriggerString) and inStr(loo.Opts, "*") and not inStr(loo.Opts, "?") and inStr(tMyDefaultOpts, "?") and not inStr(tMyDefaultOpts, "*"))
					|| ((loo.Trig = tTriggerString) and inStr(loo.Opts, "?") and not inStr(loo.Opts, "*") and inStr(tMyDefaultOpts, "*") and not inStr(tMyDefaultOpts, "?"))
				{
					validHotDupes .= "`nDuplicate trigger found at line " A_Index ", but maybe okay, because one is word-beginning and other is word-ending.`n---> " A_LoopField
					Continue
				}
				If (inStr(loo.Opts, "*") and loo.Trig = subStr(tTriggerString, 1, strLen(loo.Trig)))
					|| (inStr(tMyDefaultOpts, "*") and tTriggerString = subStr(loo.Trig, 1, strLen(tTriggerString)))
				{
					validHotDupes .= "`nWord Beginning conflict found at line " A_Index ", where one of the strings is a subset of the other.  Whichever appears last will never be expanded.`n---> " A_LoopField
					Continue
				}
				If (inStr(loo.Opts, "?") and loo.Trig = subStr(tTriggerString, -strLen(loo.Trig)))
					|| (inStr(tMyDefaultOpts, "?") and tTriggerString = subStr(loo.Trig, -strLen(tTriggerString)))
				{
					validHotDupes .= "`nWord Ending conflict found at line " A_Index ", where one of the strings is a superset of the other.  The longer of the strings should appear before the other, in your code.`n---> " A_LoopField
					Continue
				}
			}
			Else
				continue
		}
		If validHotDupes != ""
			validHotDupes := SubStr(validHotDupes, 2)
		If (tMatches > 0)
			validHotMisspells := "This trigger string will misspell [" tMatches "] words."
		if validHotDupes and validHotMisspells
			validHot := validHotDupes "`n-" validHotMisspells
		else If !validHotDupes and !validHotMisspells
			validHot := "Okay."
		else
			validHot := validHotDupes validHotMisspells
	}

	If (tReplaceString = "")
		validRep := "Replacement string box should not be empty."
	else if (SubStr(tReplaceString, 1, 1) == ":")
		validRep := "Don't include the colons."
	else if (tReplaceString = tTriggerString)
		validRep := "Replacement string SAME AS Trigger string."
	else
		validRep := "Okay."
	CombinedValidMsg := "OPTIONS BOX `n-" . validOpts . "*|*HOTSTRING BOX `n-" . validHot . "*|*REPLACEMENT BOX `n-" . validRep
	Return CombinedValidMsg
}

Appendit(tMyDefaultOpts, tTriggerString, tReplaceString)
{
	WholeStr := ""
	tMyDefaultOpts := MyDefaultOpts.text
	tTriggerString := TriggerString.text
	tReplaceString := ReplaceString.text
	tComStr := ''
	aComStr := ''

	If (rMatches > 0) and (AutoCommentFixesAndMisspells = 1)
	{
		Misspells := ""
		Misspells := EdtTMatches.Value
		If (tMatches > 3)
			Misspells := ", but misspells " . tMatches . " words !!! "
		Else If (Misspells != "")
		{
			Misspells := SubStr(StrReplace(Misspells, "`n", " (), "), 1, -2) . ". "
			Misspells := ", but misspells " . Misspells
		}
		aComStr := "Fixes " . rMatches . " words " . Misspells
		aComStr := StrReplace(aComStr, "Fixes 1 words ", "Fixes 1 word ")
	}

	fopen := '', fclose := ''
	If (chkFunc.Value = 1) and (IsMultiLine = 0)
	{
		tMyDefaultOpts := "B0X" . StrReplace(tMyDefaultOpts, "B0X", "")
		fopen := 'f("'
		fclose := '")'
	}

	If (ComStr.text != "") || (aComStr != "")
		tComStr := " `; " . aComStr . ComStr.text

	If InStr(tReplaceString, "`n")
	{
		openParenth := subStr(tReplaceString, -1) = "`t" ? "(RTrim0`n" : "(`n"
		WholeStr := ":" . tMyDefaultOpts . ":" . tTriggerString . "::" . tComStr . "`n" . fopen . openParenth . tReplaceString . "`n)" . fclose
	}
	Else
		WholeStr := ":" . tMyDefaultOpts . ":" . tTriggerString . "::" . fopen . tReplaceString . fclose . tComStr

	If GetKeyState("Shift")
	{
		A_Clipboard := WholeStr
		SoundBeep 800, 200
		SoundBeep 700, 300
	}
	else
	{
		FileAppend("`n" WholeStr, A_ScriptFullPath)
		If (AutoEnterNewEntry = 1)
			ChangeActiveEditField()
		If not getKeyState("Ctrl")
			Reload()
	}
}

ChangeActiveEditField(*)
{
	Global origTriggerTypo

	Send("^c")
	Errorlevel := !ClipWait(0.3)

	origTriggerTypo := trim(origTriggerTypo)
	hasSpace := (subStr(A_Clipboard, -1) = " ") ? " " : ""
	A_Clipboard := trim(A_Clipboard)

	If (origTriggerTypo = A_Clipboard) and (origTriggerTypo = TriggerString.text)
	{
		If (bb != 0)
			bb.Hide()
		hh.Hide()
		WinWaitActive(targetWindow)
		Send(ReplaceString.text hasSpace)
	}
}

hhButtonSpell(*)
{
	tReplaceString := ReplaceString.text
	If (tReplaceString = "")
		MsgBox("Replacement Text not found.", , 4096)
	else
	{
		googleSugg := GoogleAutoCorrect(tReplaceString)
		If (googleSugg = "")
			MsgBox("No suggestions found.", , 4096)
		Else
		{
			msgResult := MsgBox(googleSugg "`n`n######################`nChange Replacement Text?", "Google Suggestion", "OC 4096")
			if (msgResult = "OK")
			{
				ReplaceString.value := googleSugg
				goFilter()
			}
			else
				return
		}
	}
}
GoogleAutoCorrect(word)
{
	objReq := ComObject('WinHttp.WinHttpRequest.5.1')
	objReq.Open('GET', 'https://www.google.com/search?q=' word)
	objReq.SetRequestHeader('User-Agent'
		, 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)')
	objReq.Send(), HTML := objReq.ResponseText
	If RegExMatch(HTML, 'value="(.*?)"', &A)
		If RegExMatch(HTML, ';spell=1.*?>(.*?)<\/a>', &B)
			Return B[1] || A[1]
}

hhButtonOpen(*)
{
	hh.Hide()
	A_Clipboard := ClipboardOld
	Try
		Run MyAhkEditorPath " " NameOfThisFile
	Catch
		msgbox 'cannot run ' NameOfThisFile
	WinWaitActive(NameOfThisFile)
	Sleep(1000)
	Send("{Ctrl Down}{End}{Ctrl Up}{Home}")
}

ChangeWordList(*)
{
	Global WordListFile
	Global WordListPath
	Global MyAhkEditorPath
	Global NameOfThisFile
	Global ClipboardOld

	hh.Hide()
	A_Clipboard := ClipboardOld
	Try
		Run MyAhkEditorPath " " NameOfThisFile
	Catch
		msgbox 'cannot run ' NameOfThisFile
	WinWaitActive(NameOfThisFile)
	Sleep(1000)
	SendInput "^f"
	Sleep(100)
	SendInput WordListFile
	Sleep(250)
	Run strReplace(WordListPath, "\" . WordListFile, "")
}

hhButtonCancel(*)
{
	hh.Hide()
	MyDefaultOpts.value := ""
	TriggerString.value := ""
	ReplaceString.value := ""
	tArrStep := []
	rArrStep := []
	A_Clipboard := ClipboardOld
}

GoLTrim(*)
{
	tText := TriggerString.value
	tArrStep.push(tText)
	tText := subStr(tText, 2)
	TriggerString.value := tText
	rText := ReplaceString.value
	rArrStep.push(rText)
	rText := subStr(rText, 2)
	ReplaceString.value := rText
	ButUndo.Enabled := true
	TriggerChanged()
}

GoRTrim(*)
{
	tText := TriggerString.value
	tArrStep.push(tText)
	tText := subStr(tText, 1, strLen(tText) - 1)
	TriggerString.value := tText
	rText := ReplaceString.value
	rArrStep.push(rText)
	rText := subStr(rText, 1, strLen(rText) - 1)
	ReplaceString.value := rText
	ButUndo.Enabled := true
	TriggerChanged()
}

GoUndo(*)
{
	If GetKeyState("Shift")
		GoReStart()
	else If (tArrStep.Length > 0) and (rArrStep.Length > 0)
	{
		TriggerString.value := tArrStep.Pop()
		ReplaceString.value := rArrStep.Pop()
		GoFilter()
	}
	else
	{
		ButUndo.Enabled := false
	}
}
GoReStart(*)
{
	If !OrigTrigger and !OrigReplacment
		MsgBox("Can't restart -- Nothing in memory...")
	Else
	{
		TriggerString.Value := OrigTrigger
		ReplaceString.Value := OrigReplacement
		ButUndo.Enabled := false
		tArrStep := []
		rArrStep := []
		GoFilter()
	}
}

clickLast := 0
GoMidRadio(*)
{
	global clickCurrent := A_TickCount
	if (clickCurrent - clickLast < 500)
	{
		RadMid.Value := 0
		MyDefaultOpts.text := strReplace(strReplace(MyDefaultOpts.text, "?", ""), "*", "")
	}
	global clickLast := A_TickCount
	GoFilter()
}

GoFilter(ViaExamButt := "No", *)
{
	tFind := Trim(TriggerString.Value)
	If !tFind
		tFind := " "
	tFilt := ''
	Global tMatches := 0
	MyOpts := MyDefaultOpts.text

	If (ViaExamButt = "Yes")
	{
		If inStr(MyOpts, "*") and inStr(MyOpts, "?")
			RadMid.value := 1
		Else if inStr(MyOpts, "*")
			RadBeg.value := 1
		Else if inStr(MyOpts, "?")
			RadEnd.value := 1
		Else
		{
			RadMid.value := 0
			RadBeg.value := 0
			RadEnd.value := 0
		}
	}

	Loop Read, WordListPath
	{
		If InStr(A_LoopReadLine, tFind)
		{
			IF (RadMid.value = 1)
			{
				tFilt .= A_LoopReadLine '`n'
				tMatches++
			}
			Else If (RadEnd.value = 1)
			{
				If InStr(SubStr(A_LoopReadLine, -StrLen(tFind)), tFind)
				{
					tFilt .= A_LoopReadLine '`n'
					tMatches++
				}
			}
			else If (RadBeg.value = 1)
			{
				If InStr(SubStr(A_LoopReadLine, 1, StrLen(tFind)), tFind)
				{
					tFilt .= A_LoopReadLine '`n'
					tMatches++
				}
			}
			Else
			{
				If (A_LoopReadLine = tFind)
				{
					tFilt := tFind
					tMatches++
				}
			}
		}
	}

	IF (RadMid.value = 1)
	{
		If not inStr(MyOpts, "*")
			MyOpts := MyOpts . "*"
		If not inStr(MyOpts, "?")
			MyOpts := MyOpts . "?"
	}
	Else If (RadEnd.value = 1)
	{
		If not inStr(MyOpts, "?")
			MyOpts := MyOpts . "?"
		MyOpts := StrReplace(MyOpts, "*")
	}
	else If (RadBeg.value = 1)
	{
		If not inStr(MyOpts, "*")
			MyOpts := MyOpts . "*"
		MyOpts := StrReplace(MyOpts, "?")
	}
	MyDefaultOpts.text := MyOpts

	EdtTMatches.Value := tFilt
	TxtTLable.Text := "Misspells [" . tMatches . "]"

	If (tMatches > 0)
	{
		TrigLbl.Text := "Misspells [" . tMatches . "] words"
		TrigLbl.SetFont("cRed")
	}
	If (tMatches = 0)
	{
		TrigLbl.Text := "No Misspellings found."
		TrigLbl.SetFont(FontColor)
	}

	rFind := Trim(ReplaceString.Value, "`n`t ")
	If !rFind
		rFind := " "
	rFilt := ''
	Global rMatches := 0

	Loop Read WordListPath
	{
		If InStr(A_LoopReadLine, rFind)
		{
			IF (RadMid.value = 1)
			{
				rFilt .= A_LoopReadLine '`n'

				rMatches++
			}
			Else If (RadEnd.value = 1)
			{
				If InStr(SubStr(A_LoopReadLine, -StrLen(rFind)), rFind)
				{
					rFilt .= A_LoopReadLine '`n'
					rMatches++
				}
			}
			else If (RadBeg.value = 1)
			{
				If InStr(SubStr(A_LoopReadLine, 1, StrLen(rFind)), rFind)
				{
					rFilt .= A_LoopReadLine '`n'
					rMatches++
				}
			}
			Else
			{
				If (A_LoopReadLine = rFind)
				{
					rFilt := rFind
					rMatches++
				}
			}
		}
	}
	EdtRMatches.Value := rFilt
	TxtRLable.Text := "Fixes [" . rMatches . "]"
}



#HotIf WinActive(NameOfThisFile,)
	^s::
	{
		Send("^s")
		MsgBox("Reloading...", "", "T0.3")
		Sleep(250)
		Reload()
		MsgBox("I'm reloaded.")
	}
#HotIf


^+e::
EditThisScript(*)
{
	Try
		Run MyAhkEditorPath " " NameOfThisFile
	Catch
		msgbox 'cannot run ' NameOfThisFile
}


+!p::
PrinterTool(*)
{
	pfontColor := fontColor

	Global df := ""

	defaultPrinter := RegRead("HKCU\Software\Microsoft\Windows NT\CurrentVersion\Windows", "Device")

	Global printerlist := ""
	Loop Reg, "HKCU\Software\Microsoft\Windows NT\CurrentVersion\devices"
		printerlist := printerlist . "" . A_loopRegName . "`n"
	printerlist := SubStr(printerlist, 1, strlen(printerlist) - 2)

	df := Gui()
	df.Title := "Default Printer Changer"
	df.OnEvent("Close", ButtonCancel)
	df.OnEvent("Escape", ButtonCancel)
	df.BackColor := guiColor
	df.SetFont("s12 bold c" . pFontColor)
	df.Add("Text", , "Set A Default Printer ...")
	df.SetFont("s11")
	Loop Parse, printerlist, "`n"
		If InStr(defaultPrinter, A_LoopField)
			df.AddRadio("checked vRadio" . a_index, a_loopfield)
		Else
			df.AddRadio("vRadio" . a_index, a_loopfield)
	df.AddButton("default", "Set Printer").OnEvent("Click", ButtonSet)
	df.AddButton("x+10", "Print &Queue").OnEvent("Click", ButtonQue)
	df.AddButton("x+10", "Control Panel").OnEvent("Click", ButtonCtrlPanel)
	df.AddButton("x+10", "Cancel").OnEvent("Click", ButtonCancel)
	df.Show()
}

ButtonSet(*)
{
	Loop Parse, printerlist, "`n"
	{
		thisRadioVal := df["Radio" . a_index].value
		If thisRadioVal != 0
			newDefault := a_loopfield
	}
	RunWait("C:\Windows\System32\RUNDLL32.exe PRINTUI.DLL, PrintUIEntry /y /n `"" newDefault "`"")
	df.Destroy()
}

ButtonQue(*)
{
	viewThis := ""
	Loop Parse, printerlist, "`n"
	{
		thisRadioVal := df["Radio" . a_index].value
		If thisRadioVal != 0
			viewThis := a_loopfield
	}
	RunWait("rundll32 printui.dll, PrintUIEntry /o /n `"" viewThis "`"")
	df.Destroy()
}

ButtonCtrlPanel(*)
{
	Run("control printers")
	df.Destroy()
	printerlist := ""
}

ButtonCancel(*)
{
	df.Destroy()
	printerlist := ""
}

!+u::
UpTime(*)
{
	MsgBox("UpTime is:`n" . Uptime(A_TickCount))
	Uptime(ms)
	{
		VarSetStrCapacity(&b, 256)
		DllCall("GetDurationFormat", "uint", 2048, "uint", 0, "ptr", 0, "int64", ms * 10000, "wstr", " d 'days, 'h' hrs, 'm' mins'", "wstr", b, "int", 256)
		b := StrReplace(b, " 0 days,")
		b := StrReplace(b, " 0 hrs,")
		b := StrReplace(b, " 0 mins,")
		b := StrReplace(b, " 1 days,", "1 day,")
		b := StrReplace(b, " 1 hrs,", " 1 hr,")
		b := StrReplace(b, " 1 mins,", " 1 min,")
		return b
	}
}



fix_consecutive_caps()
fix_consecutive_caps()
{
	HotIf (*) => !GetKeyState("CapsLock", "T")
	loop 26
	{
		char1 := Chr(A_Index + 64)
		loop 26
		{
			char2 := Chr(A_Index + 64)
			Hotstring(":*?CXB0Z:" char1 char2, fix.Bind(char1, char2))
		}
	}
	HotIf
	fix(char1, char2, *)
	{
		ih := InputHook("V I101 L1 T.3")
		ih.OnEnd := OnEnd
		ih.Start()
		OnEnd(ih)
		{
			char3 := ih.Input
			if (char3 ~= "[A-Z]")
				Hotstring "Reset"
			else if (char3 ~= "[a-z]")
				|| (char3 = A_Space && char1 char2 ~= "OF|TO|IN|IT|IS|AS|AT|WE|HE|BY|ON|BE|NO")
			{
				SendInput("{BS 2}" StrLower(char2) char3)
				SoundBeep(800, 80)
			}
		}
	}
}


saveIntervalMinutes := 20
IntervalsBeforeStopping := 2

!+F3:: MsgBox(lastTrigger, "Trigger", 0)

lastTrigger := "none yet"
f(replace := "")
{
	static HSInputBuffer := InputBuffer()
	Global lastTrigger
	Global ignorLen := 0
	Global KeepForLog := ""

	HSInputBuffer.Start()
	trigger := A_ThisHotkey
	endchar := A_EndChar
	lastTrigger := StrReplace(trigger, "B0X", "") "::" replace
	trigger := SubStr(trigger, inStr(trigger, ":", , , 2) + 1)
	TrigLen := StrLen(trigger) + StrLen(endchar)
	trigL := StrSplit(trigger)
	replL := StrSplit(replace)
	Loop Min(trigL.Length, replL.Length)
	{
		If (trigL[A_Index] == replL[A_Index])
			ignorLen++
		; else break 												; this breaks the loop before it completes all iterations.
	}
	replace := SubStr(replace, (ignorLen + 1))
	SendInput("{BS " . (TrigLen - ignorLen) . "}" replace endchar)
	replace := ""
	HSInputBuffer.Stop()
	SoundBeep(900, 60)
	KeepForLog := LastTrigger "`n"
	SetTimer(keepText, -1)
}

#MaxThreadsPerHotkey 5
keepText(*)
{
	EndKeys := "{Backspace}"
	global lih := InputHook("B V I1 E T1", EndKeys)
	lih.Start(), lih.Wait()
	hyphen := (lih.EndKey = "Backspace") ? " << " : " -- "
	global savedUpText .= A_YYYY "-" A_MM "-" A_DD hyphen KeepForLog
	global intervalCounter := 0
	If logIsRunning = 0
		setTimer Appender, saveIntervalMinutes
}
#MaxThreadsPerHotkey 1

Appender(*)
{
	FileAppend(savedUpText, "AutoCorrectsLog.ahk")
	global savedUpText := ''
	global logIsRunning := 1
	global intervalCounter += 1
	If (intervalCounter >= IntervalsBeforeStopping)
	{
		setTimer Appender, 0
		global logIsRunning := 0
		global intervalCounter := 0
	}
}

OnExit Appender


class InputBuffer
{
	Buffer := [], SendLevel := A_SendLevel + 2, ActiveCount := 0, IsReleasing := 0
	static __New() => this.DefineProp("Default", {
		value: InputBuffer()
	})
	static __Get(Name, Params) => this.Default.%Name%
	static __Set(Name, Params, Value) => this.Default.%Name% := Value
	static __Call(Name, Params) => this.Default.%Name%(Params*)

	__New(keybd := true, timeout := 0)
	{
		if !keybd
			throw Error("Keyboard input type must be specified")
		this.Timeout := timeout
		this.Keybd := keybd

		if keybd
		{
			if keybd is String
			{
				if RegExMatch(keybd, "i)I *(\d+)", &lvl)
					this.SendLevel := Integer(lvl[1])
			}
			this.InputHook := InputHook(keybd is String ? keybd : "I" (this.SendLevel) " L0 *")
			this.InputHook.NotifyNonText := true
			this.InputHook.VisibleNonText := false
			this.InputHook.OnKeyDown := this.BufferKey.Bind(this, , , , "Down")
			this.InputHook.OnKeyUp := this.BufferKey.Bind(this, , , , "Up")
			this.InputHook.KeyOpt("{All}", "N S")
		}
		this.HotIfIsActive := this.GetActiveCount.Bind(this)
	}

	BufferKey(ih, VK, SC, UD) => (this.Buffer.Push(Format("{{1} {2}}", GetKeyName(Format("vk{:x}sc{:x}", VK, SC)), UD)))

	Start()
	{
		this.ActiveCount += 1
		SetTimer(this.Stop.Bind(this), -this.Timeout)
		if this.ActiveCount > 1
			return
		this.Buffer := []
		if this.Keybd
			this.InputHook.Start()
	}

	Release()
	{
		if this.IsReleasing
			return []
		sent := [], this.IsReleasing := 1
		PrevSendLevel := A_SendLevel
		SendLevel this.SendLevel - 1
		while this.Buffer.Length
		{
			key := this.Buffer.RemoveAt(1)
			sent.Push(key)
			Send(key)
		}
		SendLevel PrevSendLevel
		this.IsReleasing := 0
		return sent
	}

	Stop(release := true)
	{
		if !this.ActiveCount
			return
		sent := release ? this.Release() : []
		if --this.ActiveCount
			return
		if this.Keybd
			this.InputHook.Stop()
		return sent
	}

	GetActiveCount(HotkeyName) => this.ActiveCount
}

^F3::
StringAndFixReport(*)
{
	ThisFile := FileRead(A_ScriptFullPath)
	thisOptions := '', regulars := 0, begins := 0, middles := 0, ends := 0, fixes := 0, entries := 0
	Loop Parse ThisFile, '`n'
	{
		If SubStr(Trim(A_LoopField), 1, 1) != ':'
			continue
		entries++
		thisOptions := SubStr(Trim(A_LoopField), 1, InStr(A_LoopField, ':', , , 2))
		If InStr(thisOptions, '*') and InStr(thisOptions, '?')
			middles++
		Else If InStr(thisOptions, '*')
			begins++
		Else If InStr(thisOptions, '?')
			ends++
		Else
			regulars++
		If RegExMatch(A_LoopField, 'Fixes\h*\K\d+', &fn)
			fixes += fn[]
	}
	MsgBox('   Totals`n==========================='
		'`n    Regular Autocorrects:`t' numberFormat(regulars)
		'`n    Word Beginnings:`t`t' numberFormat(begins)
		'`n    Word Middles:`t`t' numberFormat(middles)
		'`n    Word Ends:`t`t' numberFormat(ends)
		'`n==========================='
		'`n   Total Entries:`t`t' numberFormat(entries)
		'`n   Potential Fixes:`t`t' numberFormat(fixes)
		, 'Report for ' A_ScriptName, 64 + 4096
	)
	numberFormat(num)
	{
		global
		Loop
		{
			oldnum := num
			num := RegExReplace(num, "(\d)(\d{3}(\,|$))", "$1,$2")
			if (num == oldnum)
				break
		}
		return num
	}
}


:B0:Savitr::
:B0:Vaisyas::
:B0:Wheatley::
:B0:arraign::
:B0:bialy::
:B0:callsign::
:B0:champaign::
:B0:coign::
:B0:condign::
:B0:consign::
:B0:coreign::
:B0:cosign::
:B0:countersign::
:B0:deign::
:B0:deraign::
:B0:eloign::
:B0:ensign::
:B0:feign::
:B0:indign::
:B0:kc::
:B0:malign::
:B0:miliary::
:B0:minyanim::
:B0:pfennig::
:B0:reign::
:B0:sice::
:B0:sign::
:B0:verisign::
:B0?:align::
:B0?:assign::
:B0?:benign::
:B0?:campaign::
:B0?:design::
:B0?:foreign::
:B0?:resign::
:B0?:sovereign::

{
	return
}

#Hotstring Z

ACitemsStartAt := A_LineNumber + 10
:B0X*:eyte:: f("eye")
:B0X*:inteh:: f("in the")
:B0X*:ireleven:: f("irrelevan")
:B0X*:managerial reign:: f("managerial rein")
:B0X*:minsitr:: f("ministr")
:B0X*:ommision:: f("omission")
:B0X*:peculure:: f("peculiar")
:B0X*:pinon:: f("piñon")
:B0X*:presed:: f("presid")
:B0X*:recommed:: f("recommend")
:B0X*:resturaunt:: f("restaurant")
:B0X*:thge:: f("the")
:B0X*:thsi:: f("this")
:B0X*:unkow:: f("unknow")
:B0X:inprocess:: f("in process")
:B0X*?:abotu:: f("about")
:B0X*?:allign:: f("align")
:B0X*?:arign:: f("aring")
:B0X*?:asign:: f("assign")
:B0X*?:awya:: f("away")
:B0X*?:bakc:: f("back")
:B0X*?:blihs:: f("blish")
:B0X*?:charecter:: f("character")
:B0X*?:comnt:: f("cont")
:B0X*?:degred:: f("degrad")
:B0X*?:dessign:: f("design")
:B0X*?:disign:: f("design")
:B0X*?:dquater:: f("dquarter")
:B0X*?:easr:: f("ears")
:B0X*?:ecomon:: f("econom")
:B0X*?:esorce:: f("esource")
:B0X*?:juristiction:: f("jurisdiction")
:B0X*?:konw:: f("know")
:B0X*?:mmorow:: f("morrow")
:B0X*?:ngiht:: f("night")
:B0X*?:orign:: f("origin")
:B0X*?:rnign:: f("rning")
:B0X*?:sensur:: f("censur")
:B0X*?:soverign:: f("sovereign")
:B0X*?:ssurect:: f("surrect")
:B0X*?:tatn:: f("tant")
:B0X*?:thakn:: f("thank")
:B0X*?:thnig:: f("thing")
:B0X*?:threatn:: f("threaten")
:B0X*?:tihkn:: f("think")
:B0X*?:tiojn:: f("tion")
:B0X*?:visiosn:: f("vision")
:B0X?:adresing:: f("addressing")
:B0X?:clas:: f("class")
:B0X?:efull:: f("eful")
:B0X?:ficaly:: f("fically")

:B0X*:Buddist:: f("Buddhist")
:B0X*:Feburary:: f("February")
:B0X*:Hatian:: f("Haitian")
:B0X*:Isaax :: f("Isaac")
:B0X*:Israelies:: f("Israelis")
:B0X*:Janurary:: f("January")
:B0X*:Januray:: f("January")
:B0X*:Karent:: f("Karen")
:B0X*:Montnana:: f("Montana")
:B0X*:Naploeon:: f("Napoleon")
:B0X*:Napolean:: f("Napoleon")
:B0X*:Novermber:: f("November")
:B0X*:Pennyslvania:: f("Pennsylvania")
:B0X*:Queenland:: f("Queensland")
:B0X*:Sacremento:: f("Sacramento")
:B0X*:Straight of:: f("Strait of")
:B0X*:ToolTop:: f("ToolTip")
:B0X*:a FM:: f("an FM")
:B0X*:a MRI:: f("an MRI")
:B0X*:a ab:: f("an ab")
:B0X*:a ac:: f("an ac")
:B0X*:a ad:: f("an ad")
:B0X*:a af:: f("an af")
:B0X*:a ag:: f("an ag")
:B0X*:a al:: f("an al")
:B0X*:a am:: f("an am")
:B0X*:a an:: f("an an")
:B0X*:a ap:: f("an ap")
:B0X*:a as:: f("an as")
:B0X*:a av:: f("an av")
:B0X*:a aw:: f("an aw")
:B0X*:a businessmen:: f("a businessman")
:B0X*:a businesswomen:: f("a businesswoman")
:B0X*:a consortia:: f("a consortium")
:B0X*:a criteria:: f("a criterion")
:B0X*:a ea:: f("an ea")
:B0X*:a ef:: f("an ef")
:B0X*:a ei:: f("an ei")
:B0X*:a el:: f("an el")
:B0X*:a em:: f("an em")
:B0X*:a en:: f("an en")
:B0X*:a ep:: f("an ep")
:B0X*:a eq:: f("an eq")
:B0X*:a es:: f("an es")
:B0X*:a et:: f("an et")
:B0X*:a ex:: f("an ex")
:B0X*:a falling out:: f("a falling-out")
:B0X*:a firemen:: f("a fireman")
:B0X*:a flagella:: f("a flagellum")
:B0X*:a forward by:: f("a foreword by")
:B0X*:a freshmen:: f("a freshman")
:B0X*:a fungi:: f("a fungus")
:B0X*:a gunmen:: f("a gunman")
:B0X*:a heir:: f("an heir")
:B0X*:a herb:: f("an herb")
:B0X*:a honest:: f("an honest")
:B0X*:a honor:: f("an honor")
:B0X*:a hour:: f("an hour")
:B0X*:a ic:: f("an ic")
:B0X*:a id:: f("an id")
:B0X*:a ig:: f("an ig")
:B0X*:a il:: f("an il")
:B0X*:a im:: f("an im")
:B0X*:a in:: f("an in")
:B0X*:a ir:: f("an ir")
:B0X*:a is:: f("an is")
:B0X*:a larvae:: f("a larva")
:B0X*:a lock up:: f("a lockup")
:B0X*:a nuclei:: f("a nucleus")
:B0X*:a numbers of:: f("a number of")
:B0X*:a oa:: f("an oa")
:B0X*:a ob:: f("an ob")
:B0X*:a ocean:: f("an ocean")
:B0X*:a offen:: f("an offen; Fixes 1 word")
:B0X*:a offic:: f("an offic")
:B0X*:a oi:: f("an oi")
:B0X*:a ol:: f("an ol")
:B0X*:a one of the:: f("one of the")
:B0X*:a op:: f("an op")
:B0X*:a or:: f("an or")
:B0X*:a os:: f("an os")
:B0X*:a ot:: f("an ot")
:B0X*:a ou:: f("an ou")
:B0X*:a ov:: f("an ov")
:B0X*:a ow:: f("an ow")
:B0X*:a parentheses:: f("a parenthesis")
:B0X*:a pupae:: f("a pupa")
:B0X*:a radii:: f("a radius")
:B0X*:a regular bases:: f("a regular basis")
:B0X*:a resent:: f("a recent")
:B0X*:a run in:: f("a run-in")
:B0X*:a set back:: f("a set-back")
:B0X*:a set up:: f("a setup")
:B0X*:a several:: f("several")
:B0X*:a simple as:: f("as simple as")
:B0X*:a spermatozoa:: f("a spermatozoon")
:B0X*:a statesmen:: f("a statesman")
:B0X*:a two months:: f("a two-month")
:B0X*:a ud:: f("an ud")
:B0X*:a ug:: f("an ug")
:B0X*:a ul:: f("an ul")
:B0X*:a um:: f("an um")
:B0X*:a up:: f("an up")
:B0X*:a urban:: f("an urban")
:B0X*:a vertebrae:: f("a vertebra")
:B0X*:a women:: f("a woman")
:B0X*:a work out:: f("a workout")
:B0X*:abandonned:: f("abandoned")
:B0X*:abcense:: f("absence")
:B0X*:abera:: f("aberra")
:B0X*:abondon:: f("abandon")
:B0X*:about it's:: f("about its")
:B0X*:about they're:: f("about their")
:B0X*:about who to:: f("about whom to")
:B0X*:about who's:: f("about whose")
:B0X*:abouta:: f("about a")
:B0X*:aboutit:: f("about it")
:B0X*:above it's:: f("above its")
:B0X*:abreviat:: f("abbreviat")
:B0X*:absail:: f("abseil")
:B0X*:abscen:: f("absen")
:B0X*:absense:: f("absence")
:B0X*:abutts:: f("abuts")
:B0X*:accidently:: f("accidentally")
:B0X*:acclimit:: f("acclimat")
:B0X*:accomd:: f("accommod")
:B0X*:accordeon:: f("accordion")
:B0X*:accordian:: f("accordion")
:B0X*:according a:: f("according to a")
:B0X*:accordingto:: f("according to")
:B0X*:achei:: f("achie")
:B0X*:achiv:: f("achiev")
:B0X*:aciden:: f("acciden")
:B0X*:ackward:: f("awkward")
:B0X*:acord:: f("accord")
:B0X*:acquite:: f("acquitte")
:B0X*:across it's:: f("across its")
:B0X*:acuse:: f("accuse")
:B0X*:adbandon:: f("abandon")
:B0X*:adhear:: f("adher")
:B0X*:adheran:: f("adheren")
:B0X*:adresa:: f("addressa")
:B0X*:adress:: f("address")
:B0X*:adves:: f("advers")
:B0X*:afair:: f("affair")
:B0X*:affect upon:: f("effect upon")
:B0X*:afficianado:: f("aficionado")
:B0X*:afficionado:: f("aficionado")
:B0X*:after along time:: f("after a long time")
:B0X*:after awhile:: f("after a while")
:B0X*:after been:: f("after being")
:B0X*:after it's:: f("after its")
:B0X*:after quite awhile:: f("after quite a while")
:B0X*:against it's:: f("against its")
:B0X*:againstt he:: f("against the")
:B0X*:agani:: f("again")
:B0X*:aggregious:: f("egregious")
:B0X*:agian:: f("again")
:B0X*:agina:: f("again")
:B0X*:aginst:: f("against")
:B0X*:agriev:: f("aggriev")
:B0X*:ahjk:: f("ahk")
:B0X*:aiport:: f("airport")
:B0X*:airbourne:: f("airborne")
:B0X*:airplane hanger:: f("airplane hangar")
:B0X*:airporta:: f("airports")
:B0X*:airrcraft:: f("aircraft")
:B0X*:albiet:: f("albeit")
:B0X*:aledg:: f("alleg")
:B0X*:alege:: f("allege")
:B0X*:alegien:: f("allegian")
:B0X*:algebraical:: f("algebraic")
:B0X*:alientat:: f("alienat")
:B0X*:all it's:: f("all its")
:B0X*:all tolled:: f("all told")
:B0X*:alledg:: f("alleg")
:B0X*:allegedy:: f("allegedly")
:B0X*:allegely:: f("allegedly")
:B0X*:allivia:: f("allevia")
:B0X*:allopon:: f("allophon")
:B0X*:allot of:: f("a lot of")
:B0X*:allready:: f("already")
:B0X*:alltime:: f("all-time")
:B0X*:alma matter:: f("alma mater")
:B0X*:almots:: f("almost")
:B0X*:along it's:: f("along its")
:B0X*:along side:: f("alongside")
:B0X*:along time:: f("a long time")
:B0X*:alongside it's:: f("alongside its")
:B0X*:alse:: f("else")
:B0X*:alter boy:: f("altar boy")
:B0X*:alter server:: f("altar server")
:B0X*:alterior:: f("ulterior")
:B0X*:alternit:: f("alternat")
:B0X*:althought:: f("although")
:B0X*:altoug:: f("althoug")
:B0X*:alusi:: f("allusi")
:B0X*:am loathe to:: f("am loath to")
:B0X*:amalgom:: f("amalgam")
:B0X*:amature:: f("amateur")
:B0X*:amid it's:: f("amid its")
:B0X*:amidst it's:: f("amidst its")
:B0X*:amme:: f("ame")
:B0X*:ammuse:: f("amuse")
:B0X*:among it's:: f("among it")
:B0X*:among others things:: f("among other things")
:B0X*:amongst it's:: f("amongst its")
:B0X*:amongst one of the:: f("amongst the")
:B0X*:amongst others things:: f("amongst other things")
:B0X*:amung:: f("among")
:B0X*:amunition:: f("ammunition")
:B0X*:an USB:: f("a USB")
:B0X*:an Unix:: f("a Unix")
:B0X*:an another:: f("another")
:B0X*:an antennae:: f("an antenna")
:B0X*:an film:: f("a film")
:B0X*:an half:: f("a half")
:B0X*:an halt:: f("a halt")
:B0X*:an hand:: f("a hand")
:B0X*:an head:: f("a head")
:B0X*:an heart:: f("a heart")
:B0X*:an helicopter:: f("a helicopter")
:B0X*:an hero:: f("a hero")
:B0X*:an high:: f("a high")
:B0X*:an histor:: f("a histor")
:B0X*:an hospital:: f("a hospital")
:B0X*:an hotel:: f("a hotel")
:B0X*:an humanitarian:: f("a humanitarian")
:B0X*:an large:: f("a large")
:B0X*:an law:: f("a law")
:B0X*:an local:: f("a local")
:B0X*:an new:: f("a new")
:B0X*:an nin:: f("a nin")
:B0X*:an non:: f("a non")
:B0X*:an number:: f("a number")
:B0X*:an pair:: f("a pair")
:B0X*:an player:: f("a player")
:B0X*:an popular:: f("a popular")
:B0X*:an pre-:: f("a pre-")
:B0X*:an sec:: f("a sec")
:B0X*:an ser:: f("a ser")
:B0X*:an seven:: f("a seven")
:B0X*:an six:: f("a six")
:B0X*:an song:: f("a song")
:B0X*:an spec:: f("a spec")
:B0X*:an stat:: f("a stat")
:B0X*:an ten:: f("a ten")
:B0X*:an union:: f("a union")
:B0X*:an unit:: f("a unit")
:B0X*:analag:: f("analog")
:B0X*:anarchim:: f("anarchism")
:B0X*:anarchistm:: f("anarchism")
:B0X*:and so fourth:: f("and so forth")
:B0X*:andd:: f("and")
:B0X*:andone:: f("and one")
:B0X*:androgenous:: f("androgynous")
:B0X*:androgeny:: f("androgyny")
:B0X*:anih:: f("annih")
:B0X*:aniv:: f("anniv")
:B0X*:anonim:: f("anonym")
:B0X*:anoyance:: f("annoyance")
:B0X*:ansal:: f("nasal")
:B0X*:ansest:: f("ancest")
:B0X*:antartic:: f("antarctic")
:B0X*:anthrom:: f("anthropom")
:B0X*:anti-semetic:: f("anti-Semitic")
:B0X*:antiapartheid:: f("anti-apartheid")
:B0X*:anual:: f("annual")
:B0X*:anul:: f("annul")
:B0X*:any another:: f("another")
:B0X*:any resent:: f("any recent")
:B0X*:any where:: f("anywhere")
:B0X*:anyother:: f("any other")
:B0X*:anytying:: f("anything")
:B0X*:apart form:: f("apart from")
:B0X*:aproxim:: f("approxim")
:B0X*:aquaduct:: f("aqueduct")
:B0X*:aquir:: f("acquir")
:B0X*:arbouret:: f("arboret")
:B0X*:archiac:: f("archaic")
:B0X*:archimedian:: f("Archimedean")
:B0X*:archtyp:: f("archetyp")
:B0X*:are aloud to:: f("are allowed to")
:B0X*:are build:: f("are built")
:B0X*:are drew:: f("are drawn")
:B0X*:are it's:: f("are its")
:B0X*:are know:: f("are known")
:B0X*:are lain:: f("are laid")
:B0X*:are lead by:: f("are led by")
:B0X*:are loathe to:: f("are loath to")
:B0X*:are ran by:: f("are run by")
:B0X*:are set-up:: f("are set up")
:B0X*:are setup:: f("are set up")
:B0X*:are shutdown:: f("are shut down")
:B0X*:are shutout:: f("are shut out")
:B0X*:are suppose to:: f("are supposed to")
:B0X*:are use to:: f("are used to")
:B0X*:aready:: f("already")
:B0X*:areod:: f("aerod")
:B0X*:arised:: f("arose")
:B0X*:ariv:: f("arriv")
:B0X*:armistace:: f("armistice")
:B0X*:arn't:: f("aren't")
:B0X*:arogan:: f("arrogan")
:B0X*:arond:: f("around")
:B0X*:aroud:: f("around")
:B0X*:around it's:: f("around its")
:B0X*:arren:: f("arran")
:B0X*:arrou:: f("arou")
:B0X*:artc:: f("artic")
:B0X*:artical:: f("article")
:B0X*:artifical:: f("artificial")
:B0X*:artillar:: f("artiller")
:B0X*:as a resulted:: f("as a result")
:B0X*:as apposed to:: f("as opposed to")
:B0X*:as back up:: f("as backup")
:B0X*:as oppose to:: f("as opposed to")
:B0X*:asetic:: f("ascetic")
:B0X*:asfar:: f("as far")
:B0X*:aside form:: f("aside from")
:B0X*:aside it's:: f("aside its")
:B0X*:asphyxa:: f("asphyxia")
:B0X*:assasin:: f("assassin")
:B0X*:assesment:: f("assessment")
:B0X*:asside:: f("aside")
:B0X*:assisnat:: f("assassinat")
:B0X*:assistent:: f("assistant")
:B0X*:assit:: f("assist")
:B0X*:assualt:: f("assault")
:B0X*:assume the reigns:: f("assume the reins")
:B0X*:assume the roll:: f("assume the role")
:B0X*:asum:: f("assum")
:B0X*:aswell:: f("as well")
:B0X*:at it's:: f("at its")
:B0X*:at of:: f("at or")
:B0X*:at the alter:: f("at the altar")
:B0X*:at the reigns:: f("at the reins")
:B0X*:at then end:: f("at the end")
:B0X*:at-rist:: f("at-risk ")
:B0X*:atheistical:: f("atheistic")
:B0X*:athenean:: f("Athenian")
:B0X*:atleast:: f("at least")
:B0X*:atn:: f("ant")
:B0X*:atorne:: f("attorne")
:B0X*:attened:: f("attended")
:B0X*:attourne:: f("attorne")
:B0X*:attroci:: f("atroci")
:B0X*:auromat:: f("automat")
:B0X*:austrailia:: f("Australia")
:B0X*:authorative:: f("authoritative")
:B0X*:authorites:: f("authorities")
:B0X*:authoritive:: f("authoritative")
:B0X*:autochtonous:: f("autochthonous")
:B0X*:autocton:: f("autochthon")
:B0X*:autorit:: f("authorit")
:B0X*:autsim:: f("autism")
:B0X*:auxilar:: f("auxiliar")
:B0X*:auxillar:: f("auxiliar")
:B0X*:auxilliar:: f("auxiliar")
:B0X*:avalance:: f("avalanche")
:B0X*:avati:: f("aviati")
:B0X*:avengence:: f("a vengeance")
:B0X*:averagee:: f("average")
:B0X*:away form:: f("away from")
:B0X*:aywa:: f("away")
:B0X*:baceause:: f("because")
:B0X*:back and fourth:: f("back and forth")
:B0X*:back drop:: f("backdrop")
:B0X*:back fire:: f("backfire")
:B0X*:back peddle:: f("backpedal")
:B0X*:back round:: f("background")
:B0X*:badly effected:: f("badly affected")
:B0X*:baited breath:: f("bated breath")
:B0X*:baled out:: f("bailed out")
:B0X*:baling out:: f("bailing out")
:B0X*:bananna:: f("banana")
:B0X*:bandonn:: f("abandon")
:B0X*:bandwith:: f("bandwidth")
:B0X*:bankrupc:: f("bankruptc")
:B0X*:banrupt:: f("bankrupt")
:B0X*:barb wire:: f("barbed wire")
:B0X*:bare in mind:: f("bear in mind")
:B0X*:barily:: f("barely")
:B0X*:basic principal:: f("basic principle")
:B0X*:be apart of:: f("be a part of")
:B0X*:be build:: f("be built")
:B0X*:be cause:: f("because")
:B0X*:be drew:: f("be drawn")
:B0X*:be it's:: f("be its")
:B0X*:be know as:: f("be known as")
:B0X*:be lain:: f("be laid")
:B0X*:be lead by:: f("be led by")
:B0X*:be loathe to:: f("be loath to")
:B0X*:be rebuild:: f("be rebuilt")
:B0X*:be set-up:: f("be set up")
:B0X*:be setup:: f("be set up")
:B0X*:be shutdown:: f("be shut down")
:B0X*:be use to:: f("be used to")
:B0X*:be ware:: f("beware")
:B0X*:beachead:: f("beachhead")
:B0X*:beacuse:: f("because")
:B0X*:beastia:: f("bestia")
:B0X*:became it's:: f("became its")
:B0X*:because of it's:: f("because of its")
:B0X*:becausea:: f("because a")
:B0X*:becauseof:: f("because of")
:B0X*:becausethe:: f("because the")
:B0X*:becauseyou:: f("because you")
:B0X*:beccause:: f("because")
:B0X*:becouse:: f("because")
:B0X*:becuse:: f("because")
:B0X*:been accustom to:: f("been accustomed to")
:B0X*:been build:: f("been built")
:B0X*:been it's:: f("been its")
:B0X*:been lain:: f("been laid")
:B0X*:been lead by:: f("been led by")
:B0X*:been loathe to:: f("been loath to")
:B0X*:been mislead:: f("been misled")
:B0X*:been rebuild:: f("been rebuilt")
:B0X*:been set-up:: f("been set up")
:B0X*:been setup:: f("been set up")
:B0X*:been show on:: f("been shown on")
:B0X*:been shutdown:: f("been shut down")
:B0X*:been use to:: f("been used to")
:B0X*:before hand:: f("beforehand")
:B0X*:began it's:: f("began its")
:B0X*:begginer:: f("beginner")
:B0X*:beggining:: f("beginning")
:B0X*:beggins:: f("begins")
:B0X*:begining:: f("beginning")
:B0X*:behind it's:: f("behind its")
:B0X*:being build:: f("being built")
:B0X*:being it's:: f("being its")
:B0X*:being lain:: f("being laid")
:B0X*:being lead by:: f("being led by")
:B0X*:being loathe to:: f("being loath to")
:B0X*:being set-up:: f("being set up")
:B0X*:being setup:: f("being set up")
:B0X*:being show on:: f("being shown on")
:B0X*:being shutdown:: f("being shut down")
:B0X*:being use to:: f("being used to")
:B0X*:beligum:: f("Belgium")
:B0X*:belived:: f("believed")
:B0X*:belives:: f("believes")
:B0X*:bellweather:: f("bellwether")
:B0X*:below it's:: f("below its")
:B0X*:beneath it's:: f("beneath its")
:B0X*:bergamont:: f("bergamot")
:B0X*:beseig:: f("besieg")
:B0X*:beside it's:: f("beside its")
:B0X*:besides it's:: f("besides its")
:B0X*:beteen:: f("between")
:B0X*:better know as:: f("better known as")
:B0X*:better know for:: f("better known for")
:B0X*:better then:: f("better than")
:B0X*:between I and:: f("between me and")
:B0X*:between he and:: f("between him and")
:B0X*:between it's:: f("between its")
:B0X*:between they and:: f("between them and")
:B0X*:betwen:: f("between")
:B0X*:beut:: f("beaut")
:B0X*:beween:: f("between")
:B0X*:bewteen:: f("between")
:B0X*:beyond it's:: f("beyond its")
:B0X*:biginning:: f("beginning")
:B0X*:billingual:: f("bilingual")
:B0X*:bizzare:: f("bizarre")
:B0X*:blaim:: f("blame")
:B0X*:blitzkreig:: f("Blitzkrieg")
:B0X*:bodydbuilder:: f("bodybuilder")
:B0X*:bonifide:: f("bonafide")
:B0X*:bonofide:: f("bonafide")
:B0X*:both it's:: f("both its")
:B0X*:both of it's:: f("both of its")
:B0X*:both of them is:: f("both of them are")
:B0X*:boyan:: f("buoyan")
:B0X*:brake away:: f("break away")
:B0X*:brasillian:: f("Brazilian")
:B0X*:breakthough:: f("breakthrough")
:B0X*:breakthroughts:: f("breakthroughs")
:B0X*:breath fire:: f("breathe fire")
:B0X*:brethen:: f("brethren")
:B0X*:bretheren:: f("brethren")
:B0X*:brew haha:: f("brouhaha")
:B0X*:brillan:: f("brillian")
:B0X*:brimestone:: f("brimstone")
:B0X*:britian:: f("Britain")
:B0X*:brittish:: f("British")
:B0X*:broacasted:: f("broadcast")
:B0X*:broady:: f("broadly")
:B0X*:brocolli:: f("broccoli")
:B0X*:buddah:: f("Buddha")
:B0X*:buoan:: f("buoyan")
:B0X*:bve:: f("be")
:B0X*:by it's:: f("by its")
:B0X*:by who's:: f("by whose")
:B0X*:byt he:: f("by the")
:B0X*:cacus:: f("caucus")
:B0X*:calaber:: f("caliber")
:B0X*:calander:: f("calendar")
:B0X*:calender:: f("calendar")
:B0X*:califronia:: f("California")
:B0X*:caligra:: f("calligra")
:B0X*:callipigian:: f("callipygian")
:B0X*:cambrige:: f("Cambridge")
:B0X*:camoflag:: f("camouflag")
:B0X*:can backup:: f("can back up")
:B0X*:can been:: f("can be")
:B0X*:can blackout:: f("can black out")
:B0X*:can checkout:: f("can check out")
:B0X*:can playback:: f("can play back")
:B0X*:can setup:: f("can set up")
:B0X*:can tryout:: f("can try out")
:B0X*:can workout:: f("can work out")
:B0X*:candidiat:: f("candidat")
:B0X*:cannota:: f("connota")
:B0X*:cansel:: f("cancel")
:B0X*:cansent:: f("consent ")
:B0X*:cantalop:: f("cantaloup")
:B0X*:capetown:: f("Cape Town")
:B0X*:carnege:: f("Carnegie")
:B0X*:carnige:: f("Carnegie")
:B0X*:carniver:: f("carnivor")
:B0X*:carree:: f("caree")
:B0X*:carrib:: f("Carib")
:B0X*:carthogr:: f("cartogr")
:B0X*:casion:: f("caisson")
:B0X*:cassawor:: f("cassowar")
:B0X*:cassowarr:: f("cassowar")
:B0X*:casulat:: f("casualt")
:B0X*:catapillar:: f("caterpillar")
:B0X*:catapiller:: f("caterpillar")
:B0X*:catepillar:: f("caterpillar")
:B0X*:caterpilar:: f("caterpillar")
:B0X*:caterpiller:: f("caterpillar")
:B0X*:catterpilar:: f("caterpillar")
:B0X*:catterpillar:: f("caterpillar")
:B0X*:caucasion:: f("Caucasian")
:B0X*:ceasa:: f("Caesa")
:B0X*:celcius:: f("Celsius")
:B0X*:cementary:: f("cemetery")
:B0X*:cemetar:: f("cemeter")
:B0X*:centruy:: f("century")
:B0X*:centuties:: f("centuries")
:B0X*:centuty:: f("century")
:B0X*:cervial:: f("cervical")
:B0X*:chalk full:: f("chock-full")
:B0X*:champang:: f("champagn")
:B0X*:changed it's:: f("changed its")
:B0X*:charistics:: f("characteristics")
:B0X*:chauffer:: f("chauffeur")
:B0X*:childrens:: f("children's")
:B0X*:chock it up:: f("chalk it up")
:B0X*:chocked full:: f("chock-full")
:B0X*:choclat:: f("chocolat")
:B0X*:chomping at the bit:: f("champing at the bit")
:B0X*:choosen:: f("chosen")
:B0X*:chuch:: f("church")
:B0X*:ciel:: f("ceil")
:B0X*:cilind:: f("cylind")
:B0X*:cincinatti:: f("Cincinnati")
:B0X*:cincinnatti:: f("Cincinnati")
:B0X*:cirtu:: f("citru")
:B0X*:clera:: f("clear")
:B0X*:closed it's:: f("closed its")
:B0X*:closer then:: f("closer than")
:B0X*:co-incided:: f("coincided")
:B0X*:colate:: f("collate")
:B0X*:colea:: f("collea")
:B0X*:collaber:: f("collabor")
:B0X*:collos:: f("coloss")
:B0X*:comande:: f("commande")
:B0X*:comando:: f("commando")
:B0X*:comback:: f("comeback")
:B0X*:comdem:: f("condem")
:B0X*:commadn:: f("command")
:B0X*:commandoes:: f("commandos")
:B0X*:commemerat:: f("commemorat")
:B0X*:commerorat:: f("commemorat")
:B0X*:commonly know as:: f("commonly known as")
:B0X*:commonly know for:: f("commonly known for")
:B0X*:compair:: f("compare")
:B0X*:comparit:: f("comparat")
:B0X*:compona:: f("compone")
:B0X*:compulsar:: f("compulsor")
:B0X*:compulser:: f("compulsor")
:B0X*:concensu:: f("consensu")
:B0X*:conciet:: f("conceit")
:B0X*:condamn:: f("condemn")
:B0X*:condemm:: f("condemn")
:B0X*:conesencu:: f("consensu")
:B0X*:confidental:: f("confidential")
:B0X*:confids:: f("confides")
:B0X*:congradulat:: f("congratulat")
:B0X*:coniv:: f("conniv")
:B0X*:conneticut:: f("Connecticut")
:B0X*:conot:: f("connot")
:B0X*:conquerer:: f("conqueror")
:B0X*:consorci:: f("consorti")
:B0X*:construction sight:: f("construction site")
:B0X*:consulan:: f("consultan")
:B0X*:consulten:: f("consultan")
:B0X*:controvercy:: f("controversy")
:B0X*:controvery:: f("controversy")
:B0X*:copy or report:: f("copy of report")
:B0X*:copy or signed:: f("copy of signed")
:B0X*:corosi:: f("corrosi")
:B0X*:correpond:: f("correspond")
:B0X*:corridoor:: f("corridor")
:B0X*:coucil:: f("council")
:B0X*:coudl:: f("could")
:B0X*:coudn't:: f("couldn't")
:B0X*:could backup:: f("could back up")
:B0X*:could setup:: f("could set up")
:B0X*:could workout:: f("could work out")
:B0X*:councellor:: f("counselor")
:B0X*:counr:: f("countr")
:B0X*:countires:: f("countries")
:B0X*:creeden:: f("creden")
:B0X*:creme:: f("crème")
:B0X*:critere:: f("criteri")
:B0X*:criteria is:: f("criteria are")
:B0X*:criteria was:: f("criteria were")
:B0X*:criterias:: f("criteria")
:B0X*:critiz:: f("criticiz")
:B0X*:crucifiction:: f("crucifixion")
:B0X*:culimi:: f("culmi")
:B0X*:curriculm:: f("curriculum")
:B0X*:cyclind:: f("cylind")
:B0X*:dacquiri:: f("daiquiri")
:B0X*:dael:: f("deal")
:B0X*:dakiri:: f("daiquiri")
:B0X*:dalmation:: f("dalmatian")
:B0X*:dardenelles:: f("Dardanelles")
:B0X*:darker then:: f("darker than")
:B0X*:deafult:: f("default")
:B0X*:decathalon:: f("decathlon")
:B0X*:deciding on how:: f("deciding how")
:B0X*:decomposited:: f("decomposed")
:B0X*:decompositing:: f("decomposing")
:B0X*:decomposits:: f("decomposes")
:B0X*:decress:: f("decrees")
:B0X*:deep-seeded:: f("deep-seated")
:B0X*:definan:: f("defian")
:B0X*:delapidat:: f("dilapidat")
:B0X*:deleri:: f("deliri")
:B0X*:delusionally:: f("delusionary")
:B0X*:demographical:: f("demographic")
:B0X*:derogit:: f("derogat")
:B0X*:descripter:: f("descriptor")
:B0X*:desease:: f("disease")
:B0X*:desica:: f("desicca")
:B0X*:desinte:: f("disinte")
:B0X*:desktiop:: f("desktop")
:B0X*:desorder:: f("disorder")
:B0X*:desorient:: f("disorient")
:B0X*:desparat:: f("desperat")
:B0X*:despite of:: f("despite")
:B0X*:dessicat:: f("desiccat")
:B0X*:deteoriat:: f("deteriorat")
:B0X*:deteriat:: f("deteriorat")
:B0X*:deterioriat:: f("deteriorat")
:B0X*:detrement:: f("detriment")
:B0X*:devaste:: f("devastate")
:B0X*:devestat:: f("devastat")
:B0X*:devistat:: f("devastat")
:B0X*:diablic:: f("diabolic")
:B0X*:diamons:: f("diamonds")
:B0X*:diast:: f("disast")
:B0X*:dicht:: f("dichot")
:B0X*:diconnect:: f("disconnect")
:B0X*:did attempted:: f("did attempt")
:B0X*:didint:: f("didn't")
:B0X*:didn't fair:: f("didn't fare")
:B0X*:didnot:: f("did not")
:B0X*:didnt:: f("didn't")
:B0X*:dieties:: f("deities")
:B0X*:diety:: f("deity")
:B0X*:diffcult:: f("difficult")
:B0X*:different tact:: f("different tack")
:B0X*:different to:: f("different from")
:B0X*:difficulity:: f("difficulty")
:B0X*:diffuse the:: f("defuse the")
:B0X*:dificult:: f("difficult")
:B0X*:diminuit:: f("diminut")
:B0X*:dimunit:: f("diminut")
:B0X*:diphtong:: f("diphthong")
:B0X*:diplomanc:: f("diplomac")
:B0X*:diptheria:: f("diphtheria")
:B0X*:dipthong:: f("diphthong")
:B0X*:direct affect:: f("direct effect")
:B0X*:disasterous:: f("disastrous")
:B0X*:disatisf:: f("dissatisf")
:B0X*:disatrous:: f("disastrous")
:B0X*:discontentment:: f("discontent")
:B0X*:discus a:: f("discuss a")
:B0X*:discus the:: f("discuss the")
:B0X*:discus this:: f("discuss this")
:B0X*:diseminat:: f("disseminat")
:B0X*:dispair:: f("despair")
:B0X*:disparingly:: f("disparagingly")
:B0X*:dispele:: f("dispelle")
:B0X*:dispicab:: f("despicab")
:B0X*:dispite:: f("despite")
:B0X*:disproportiate:: f("disproportionate")
:B0X*:dissag:: f("disag")
:B0X*:dissap:: f("disap")
:B0X*:dissar:: f("disar")
:B0X*:dissob:: f("disob")
:B0X*:divinition:: f("divination")
:B0X*:docrines:: f("doctrines")
:B0X*:doe snot:: f("does not")
:B0X*:doen't:: f("doesn't")
:B0X*:dolling out:: f("doling out")
:B0X*:dominate player:: f("dominant player")
:B0X*:dominate role:: f("dominant role")
:B0X*:don't no:: f("don't know")
:B0X*:dont:: f("don't")
:B0X*:door jam:: f("doorjamb")
:B0X*:dosen't:: f("doesn't")
:B0X*:dosn't:: f("doesn't")
:B0X*:double header:: f("doubleheader")
:B0X*:down it's:: f("down its")
:B0X*:down side:: f("downside")
:B0X*:draughtm:: f("draughtsm")
:B0X*:drunkeness:: f("drunkenness")
:B0X*:due to it's:: f("due to its")
:B0X*:dukeship:: f("dukedom")
:B0X*:dumbell:: f("dumbbell")
:B0X*:during it's:: f("during its")
:B0X*:during they're:: f("during their")
:B0X*:each phenomena:: f("each phenomenon")
:B0X*:ealier:: f("earlier")
:B0X*:earnt:: f("earned")
:B0X*:eiter:: f("either")
:B0X*:eles:: f("eels")
:B0X*:elphant:: f("elephant")
:B0X*:eluded to:: f("alluded to")
:B0X*:emane:: f("ename")
:B0X*:embargos:: f("embargoes")
:B0X*:embezell:: f("embezzl")
:B0X*:emblamatic:: f("emblematic")
:B0X*:emial:: f("email")
:B0X*:eminat:: f("emanat")
:B0X*:emite:: f("emitte")
:B0X*:emne:: f("enme")
:B0X*:emphysyma:: f("emphysema")
:B0X*:empirial:: f("imperial")
:B0X*:emporer:: f("emperor")
:B0X*:enameld:: f("enamelled")
:B0X*:enchanc:: f("enhanc")
:B0X*:encylop:: f("encyclop")
:B0X*:endevors:: f("endeavors")
:B0X*:endolithe:: f("endolith")
:B0X*:ened:: f("need")
:B0X*:enlargment:: f("enlargement")
:B0X*:enlish:: f("English")
:B0X*:enought:: f("enough")
:B0X*:enourmous:: f("enormous")
:B0X*:enscons:: f("ensconc")
:B0X*:enteratin:: f("entertain")
:B0X*:entrepeneur:: f("entrepreneur")
:B0X*:enviorment:: f("environment")
:B0X*:enviorn:: f("environ")
:B0X*:envirom:: f("environm")
:B0X*:envrion:: f("environ")
:B0X*:epidsod:: f("episod")
:B0X*:epsiod:: f("episod")
:B0X*:equitor:: f("equator")
:B0X*:eral:: f("real")
:B0X*:eratic:: f("erratic")
:B0X*:erest:: f("arrest")
:B0X*:errupt:: f("erupt")
:B0X*:escta:: f("ecsta")
:B0X*:esle:: f("else")
:B0X*:europian:: f("European")
:B0X*:eurpean:: f("European")
:B0X*:eurpoean:: f("European")
:B0X*:evental:: f("eventual")
:B0X*:eventhough:: f("even though")
:B0X*:evential:: f("eventual")
:B0X*:everthing:: f("everything")
:B0X*:everytime:: f("every time")
:B0X*:everyting:: f("everything")
:B0X*:excede:: f("exceed")
:B0X*:excelen:: f("excellen")
:B0X*:excellan:: f("excellen")
:B0X*:excells:: f("excels")
:B0X*:exection:: f("execution")
:B0X*:exectued:: f("executed")
:B0X*:exelen:: f("excellen")
:B0X*:exellen:: f("excellen")
:B0X*:exemple:: f("example")
:B0X*:exerbat:: f("exacerbat")
:B0X*:exerciese:: f("exercises")
:B0X*:exerpt:: f("excerpt")
:B0X*:exerternal:: f("external")
:B0X*:exhalt:: f("exalt")
:B0X*:exhibt:: f("exhibit")
:B0X*:exibit:: f("exhibit")
:B0X*:exilera:: f("exhilara")
:B0X*:existince:: f("existence")
:B0X*:exlud:: f("exclud")
:B0X*:exonorat:: f("exonerat")
:B0X*:expatriot:: f("expatriate")
:B0X*:expeditonary:: f("expeditionary")
:B0X*:expeiment:: f("experiment")
:B0X*:explainat:: f("explanat")
:B0X*:explaning:: f("explaining")
:B0X*:exteme:: f("extreme")
:B0X*:extered:: f("exerted")
:B0X*:extermist:: f("extremist")
:B0X*:extract punishment:: f("exact punishment")
:B0X*:extract revenge:: f("exact revenge")
:B0X*:extradiction:: f("extradition")
:B0X*:extravagent:: f("extravagant")
:B0X*:extrememly:: f("extremely")
:B0X*:extremeophile:: f("extremophile")
:B0X*:extremly:: f("extremely")
:B0X*:extrordinar:: f("extraordinar")
:B0X*:eyar:: f("year")
:B0X*:eye brow:: f("eyebrow")
:B0X*:eye lash:: f("eyelash")
:B0X*:eye lid:: f("eyelid")
:B0X*:eye sight:: f("eyesight")
:B0X*:eye sore:: f("eyesore")
:B0X:eyt:: f("yet")
:B0X*:faciliat:: f("facilitat")
:B0X*:facilites:: f("facilities")
:B0X*:facillitat:: f("facilitat")
:B0X*:facinat:: f("fascinat")
:B0X*:faetur:: f("featur")
:B0X*:faired as well:: f("fared as well")
:B0X*:faired badly:: f("fared badly")
:B0X*:faired better:: f("fared better")
:B0X*:faired far:: f("fared far")
:B0X*:faired less:: f("fared less")
:B0X*:faired little:: f("fared little")
:B0X*:faired much:: f("fared much")
:B0X*:faired no better:: f("fared no better")
:B0X*:faired poorly:: f("fared poorly")
:B0X*:faired quite:: f("fared quite")
:B0X*:faired rather:: f("fared rather")
:B0X*:faired slightly:: f("fared slightly")
:B0X*:faired somewhat:: f("fared somewhat")
:B0X*:faired well:: f("fared well")
:B0X*:faired worse:: f("fared worse")
:B0X*:familes:: f("families")
:B0X*:fanatism:: f("fanaticism")
:B0X*:farenheit:: f("Fahrenheit")
:B0X*:farther then:: f("farther than")
:B0X*:faster then:: f("faster than")
:B0X*:febuary:: f("February")
:B0X*:femail:: f("female")
:B0X*:feromone:: f("pheromone")
:B0X*:fianlly:: f("finally")
:B0X*:ficed:: f("fixed")
:B0X*:fiercly:: f("fiercely")
:B0X*:fightings:: f("fighting")
:B0X*:figure head:: f("figurehead")
:B0X*:filled a lawsuit:: f("filed a lawsuit")
:B0X*:finaly:: f("finally")
:B0X*:firey:: f("fiery")
:B0X*:flag ship:: f("flagship")
:B0X*:fleed:: f("freed")
:B0X*:florescent:: f("fluorescent")
:B0X*:flourescent:: f("fluorescent")
:B0X*:follow suite:: f("follow suit")
:B0X*:following it's:: f("following its")
:B0X*:for all intensive purposes:: f("for all intents and purposes")
:B0X*:for along time:: f("for a long time")
:B0X*:for awhile:: f("for a while")
:B0X*:for quite awhile:: f("for quite a while")
:B0X*:for way it's:: f("for what it's")
:B0X*:fore ground:: f("foreground")
:B0X*:forego her:: f("forgo her")
:B0X*:forego his:: f("forgo his")
:B0X*:forego their:: f("forgo their")
:B0X*:foreward:: f("foreword")
:B0X*:forgone conclusion:: f("foregone conclusion")
:B0X*:forhe:: f("forehe")
:B0X*:formalhaut:: f("Fomalhaut")
:B0X*:formelly:: f("formerly")
:B0X*:forsaw:: f("foresaw")
:B0X*:fortell:: f("foretell")
:B0X*:forunner:: f("forerunner")
:B0X*:foundar:: f("foundr")
:B0X*:fouth:: f("fourth")
:B0X*:fransiscan:: f("Franciscan")
:B0X*:friut:: f("fruit")
:B0X*:fromt he:: f("from the")
:B0X*:froniter:: f("frontier")
:B0X*:fued:: f("feud")
:B0X*:fuhrer:: f("Führer")
:B0X*:fulfiled:: f("fulfilled")
:B0X*:full compliment of:: f("full complement of")
:B0X*:funguses:: f("fungi")
:B0X*:furner:: f("funer")
:B0X*:futhe:: f("furthe")
:B0X*:fwe:: f("few")
:B0X*:galatic:: f("galactic")
:B0X*:galations:: f("Galatians")
:B0X*:gameboy:: f("Game Boy")
:B0X*:ganes:: f("games")
:B0X*:ganst:: f("gangst")
:B0X*:gaol:: f("goal")
:B0X*:gauarana:: f("guarana")
:B0X*:gauren:: f("guaran")
:B0X*:gave advise:: f("gave advice")
:B0X*:geneolog:: f("genealog")
:B0X*:genialia:: f("genitalia")
:B0X*:gentlemens:: f("gentlemen's")
:B0X*:gerat:: f("great")
:B0X*:get setup:: f("get set up")
:B0X*:get use to:: f("get used to")
:B0X*:geting:: f("getting")
:B0X*:gets it's:: f("gets its")
:B0X*:getting use to:: f("getting used to")
:B0X*:ghandi:: f("Gandhi")
:B0X*:girat:: f("gyrat")
:B0X*:give advise:: f("give advice")
:B0X*:gives advise:: f("gives advice")
:B0X*:glamourous:: f("glamorous")
:B0X*:gloabl:: f("global")
:B0X*:gnaww:: f("gnaw")
:B0X*:going threw:: f("going through")
:B0X*:got ran:: f("got run")
:B0X*:got setup:: f("got set up")
:B0X*:got shutdown:: f("got shut down")
:B0X*:got shutout:: f("got shut out")
:B0X*:gouvener:: f("governor")
:B0X*:governer:: f("governor")
:B0X*:graet:: f("great")
:B0X*:grafitti:: f("graffiti")
:B0X*:grammer:: f("grammar")
:B0X*:greater then:: f("greater than")
:B0X*:greif:: f("grief")
:B0X*:gridle:: f("griddle")
:B0X*:ground work:: f("groundwork")
:B0X*:guadulupe:: f("Guadalupe")
:B0X*:guage:: f("gauge")
:B0X*:guatamala:: f("Guatemala")
:B0X*:guerrila:: f("guerrilla")
:B0X*:guest stared:: f("guest-starred")
:B0X*:guidlin:: f("guidelin")
:B0X*:guiliani:: f("Giuliani")
:B0X*:guilio:: f("Giulio")
:B0X*:guiness:: f("Guinness")
:B0X*:guiseppe:: f("Giuseppe")
:B0X*:gunanine:: f("guanine")
:B0X*:gusy:: f("guys")
:B0X*:gutteral:: f("guttural")
:B0X*:habaeus:: f("habeas")
:B0X*:habbit:: f("habit")
:B0X*:habeus:: f("habeas")
:B0X*:habsbourg:: f("Habsburg")
:B0X*:had arose:: f("had arisen")
:B0X*:had became:: f("had become")
:B0X*:had began:: f("had begun")
:B0X*:had being:: f("had been")
:B0X*:had brung:: f("had brought")
:B0X*:had came:: f("had come")
:B0X*:had comeback:: f("had come back")
:B0X*:had cut-off:: f("had cut off")
:B0X*:had did:: f("had done")
:B0X*:had drank:: f("had drunk")
:B0X*:had drew:: f("had drawn")
:B0X*:had drove:: f("had driven")
:B0X*:had flew:: f("had flown")
:B0X*:had gave:: f("had given")
:B0X*:had grew:: f("had grown")
:B0X*:had it's:: f("had its")
:B0X*:had knew:: f("had known")
:B0X*:had lead for:: f("had led for")
:B0X*:had lead the:: f("had led the")
:B0X*:had lead to:: f("had led to")
:B0X*:had meet:: f("had met")
:B0X*:had mislead:: f("had misled")
:B0X*:had overcame:: f("had overcome")
:B0X*:had overran:: f("had overrun")
:B0X*:had overtook:: f("had overtaken")
:B0X*:had runaway:: f("had run away")
:B0X*:had sang:: f("had sung")
:B0X*:had send:: f("had sent")
:B0X*:had set-up:: f("had set up")
:B0X*:had setup:: f("had set up")
:B0X*:had shook:: f("had shaken")
:B0X*:had shut-down:: f("had shut down")
:B0X*:had shutdown:: f("had shut down")
:B0X*:had shutout:: f("had shut out")
:B0X*:had sowed:: f("had sown")
:B0X*:had spend:: f("had spent")
:B0X*:had sprang:: f("had sprung")
:B0X*:had threw:: f("had thrown")
:B0X*:had thunk:: f("had thought")
:B0X*:had to much:: f("had too much")
:B0X*:had to used:: f("had to use")
:B0X*:had took:: f("had taken")
:B0X*:had tore:: f("had torn")
:B0X*:had undertook:: f("had undertaken")
:B0X*:had underwent:: f("had undergone")
:B0X*:had went:: f("had gone")
:B0X*:had wore:: f("had worn")
:B0X*:had wrote:: f("had written")
:B0X*:hadbeen:: f("had been")
:B0X*:hadn't went:: f("hadn't gone")
:B0X*:haemorrage:: f("haemorrhage")
:B0X*:haev:: f("have")
:B0X*:halarious:: f("hilarious")
:B0X*:half and hour:: f("half an hour")
:B0X*:hallowean:: f("Halloween")
:B0X*:halp:: f("help")
:B0X*:hand the reigns:: f("hand the reins")
:B0X*:hapen:: f("happen")
:B0X*:harases:: f("harasses")
:B0X*:harasm:: f("harassm")
:B0X*:harassement:: f("harassment")
:B0X*:has brung:: f("has brought")
:B0X*:has came:: f("has come")
:B0X*:has cut-off:: f("has cut off")
:B0X*:has did:: f("has done")
:B0X*:has drank:: f("has drunk")
:B0X*:has drew:: f("has drawn")
:B0X*:has gave:: f("has given")
:B0X*:has having:: f("as having")
:B0X*:has it's:: f("has its")
:B0X*:has lead the:: f("has led the")
:B0X*:has lead to:: f("has led to")
:B0X*:has meet:: f("has met")
:B0X*:has mislead:: f("has misled")
:B0X*:has overcame:: f("has overcome")
:B0X*:has rang:: f("has rung")
:B0X*:has sang:: f("has sung")
:B0X*:has set-up:: f("has set up")
:B0X*:has setup:: f("has set up")
:B0X*:has shook:: f("has shaken")
:B0X*:has sprang:: f("has sprung")
:B0X*:has threw:: f("has thrown")
:B0X*:has throve:: f("has thrived")
:B0X*:has thunk:: f("has thought")
:B0X*:has took:: f("has taken")
:B0X*:has undertook:: f("has undertaken")
:B0X*:has underwent:: f("has undergone")
:B0X*:has went:: f("has gone")
:B0X*:has wrote:: f("has written")
:B0X*:hasbeen:: f("has been")
:B0X*:hasnt:: f("hasn't")
:B0X*:have drank:: f("have drunk")
:B0X*:have it's:: f("have its")
:B0X*:have lead to:: f("have led to")
:B0X*:have mislead:: f("have misled")
:B0X*:have rang:: f("have rung")
:B0X*:have sang:: f("have sung")
:B0X*:have setup:: f("have set up")
:B0X*:have sprang:: f("have sprung")
:B0X*:have took:: f("have taken")
:B0X*:have underwent:: f("have undergone")
:B0X*:have went:: f("have gone")
:B0X*:havebeen:: f("have been")
:B0X*:haviest:: f("heaviest")
:B0X*:having became:: f("having become")
:B0X*:having began:: f("having begun")
:B0X*:having being:: f("having been")
:B0X*:having it's:: f("having its")
:B0X*:having sang:: f("having sung")
:B0X*:having setup:: f("having set up")
:B0X*:having took:: f("having taken")
:B0X*:having underwent:: f("having undergone")
:B0X*:having went:: f("having gone")
:B0X*:hay day:: f("heyday")
:B0X*:hda:: f("had")
:B0X*:he begun:: f("he began")
:B0X*:he let's:: f("he lets")
:B0X*:he seen:: f("he saw")
:B0X*:he use to:: f("he used to")
:B0X*:he's drank:: f("he drank")
:B0X*:head gear:: f("headgear")
:B0X*:head quarters:: f("headquarters")
:B0X*:head stone:: f("headstone")
:B0X*:head wear:: f("headwear")
:B0X*:headquarer:: f("headquarter")
:B0X*:healther:: f("health")
:B0X*:heared:: f("heard")
:B0X*:heathy:: f("healthy")
:B0X*:heidelburg:: f("Heidelberg")
:B0X*:heigher:: f("higher")
:B0X*:held the reigns:: f("held the reins")
:B0X*:helf:: f("held")
:B0X*:hellow:: f("hello")
:B0X*:helment:: f("helmet")
:B0X*:help and make:: f("help to make")
:B0X*:helpfull:: f("helpful")
:B0X*:hemmorhage:: f("hemorrhage")
:B0X*:herf:: f("href")
:B0X*:heroe:: f("hero")
:B0X*:heros:: f("heroes")
:B0X*:hersuit:: f("hirsute")
:B0X*:hesaid:: f("he said")
:B0X*:hesista:: f("hesita")
:B0X*:heterogenous:: f("heterogeneous")
:B0X*:hewas:: f("he was")
:B0X*:hge:: f("he")
:B0X*:higer:: f("higher")
:B0X*:higest:: f("highest")
:B0X*:higher then:: f("higher than")
:B0X*:himselv:: f("himself")
:B0X*:hinderance:: f("hindrance")
:B0X*:hinderence:: f("hindrance")
:B0X*:hindrence:: f("hindrance")
:B0X*:hipopotamus:: f("hippopotamus")
:B0X*:his resent:: f("his recent")
:B0X*:hismelf:: f("himself")
:B0X*:hit the breaks:: f("hit the brakes")
:B0X*:hitsingles:: f("hit singles")
:B0X*:hlep:: f("help")
:B0X*:hold onto:: f("hold on to")
:B0X*:hold the reigns:: f("hold the reins")
:B0X*:holding the reigns:: f("holding the reins")
:B0X*:holds the reigns:: f("holds the reins")
:B0X*:holliday:: f("holiday")
:B0X*:homestate:: f("home state")
:B0X*:hone in on:: f("home in on")
:B0X*:honed in:: f("homed in")
:B0X*:honory:: f("honorary")
:B0X*:honourarium:: f("honorarium")
:B0X*:honourific:: f("honorific")
:B0X*:hosit:: f("hoist")
:B0X*:hostring:: f("hotstring")
:B0X*:hotsring:: f("hotstring")
:B0X*:hotter then:: f("hotter than")
:B0X*:house hold:: f("household")
:B0X*:housr:: f("hours")
:B0X*:hsa:: f("has")
:B0X*:hte:: f("the")
:B0X*:hti:: f("thi")
:B0X*:huminoid:: f("humanoid")
:B0X*:humoural:: f("humoral")
:B0X*:hwi:: f("whi")
:B0X*:hwo:: f("who")
:B0X*:hydropile:: f("hydrophile")
:B0X*:hydropilic:: f("hydrophilic")
:B0X*:hydropobe:: f("hydrophobe")
:B0X*:hydropobic:: f("hydrophobic")
:B0X*:hygein:: f("hygien")
:B0X*:hyjack:: f("hijack")
:B0X*:hypocracy:: f("hypocrisy")
:B0X*:hypocrasy:: f("hypocrisy")
:B0X*:hypocricy:: f("hypocrisy")
:B0X*:hypocrits:: f("hypocrites")
:B0X*:i snot:: f("is not")
:B0X*:i"m:: f("I'm")
:B0X*:i;d:: f("I'd")
:B0X*:iconclas:: f("iconoclas")
:B0X*:idae:: f("idea")
:B0X*:idealogi:: f("ideologi")
:B0X*:idealogy:: f("ideology")
:B0X*:identifer:: f("identifier")
:B0X*:ideosyncratic:: f("idiosyncratic")
:B0X*:idesa:: f("ideas")
:B0X*:idiosyncracy:: f("idiosyncrasy")
:B0X*:ifb y:: f("if by")
:B0X*:ifi t:: f("if it")
:B0X*:ift he:: f("if the")
:B0X*:ignorence:: f("ignorance")
:B0X*:ihaca:: f("Ithaca")
:B0X*:iits the:: f("it's the")
:B0X*:illegim:: f("illegitim")
:B0X*:illess:: f("illness")
:B0X*:illicited:: f("elicited")
:B0X*:illieg:: f("illeg")
:B0X*:ilness:: f("illness")
:B0X*:ilog:: f("illog")
:B0X*:ilu:: f("illu")
:B0X*:imaginery:: f("imaginary")
:B0X*:iman:: f("immin")
:B0X*:imcom:: f("incom")
:B0X*:imigra:: f("immigra")
:B0X*:immida:: f("immedia")
:B0X*:immidia:: f("immedia")
:B0X*:imminent domain:: f("eminent domain")
:B0X*:impecab:: f("impecca")
:B0X*:impedence:: f("impedance")
:B0X*:impressa:: f("impresa")
:B0X*:improvision:: f("improvisation")
:B0X*:in along time:: f("in a long time")
:B0X*:in anyway:: f("in any way")
:B0X*:in awhile:: f("in a while")
:B0X*:in edition to:: f("in addition to")
:B0X*:in lu of:: f("in lieu of")
:B0X*:in masse:: f("en masse")
:B0X*:in parenthesis:: f("in parentheses")
:B0X*:in placed:: f("in place")
:B0X*:in principal:: f("in principle")
:B0X*:in quite awhile:: f("in quite a while")
:B0X*:in regards to:: f("in regard to")
:B0X*:in stead of:: f("instead of")
:B0X*:in tact:: f("intact")
:B0X*:in the long-term:: f("in the long term")
:B0X*:in the short-term:: f("in the short term")
:B0X*:in titled:: f("entitled")
:B0X*:in vein:: f("in vain")
:B0X*:inagura:: f("inaugura")
:B0X*:inate:: f("innate")
:B0X*:inaugure:: f("inaugurate")
:B0X*:inbalance:: f("imbalance")
:B0X*:inbetween:: f("between")
:B0X*:incase of:: f("in case of")
:B0X*:incidently:: f("incidentally")
:B0X*:incread:: f("incred")
:B0X*:incuding:: f("including")
:B0X*:indefineab:: f("undefinab")
:B0X*:indentical:: f("identical")
:B0X*:indesp:: f("indisp")
:B0X*:indictement:: f("indictment")
:B0X*:indigine:: f("indigen")
:B0X*:inevatibl:: f("inevitabl")
:B0X*:inevitib:: f("inevitab")
:B0X*:inevititab:: f("inevitab")
:B0X*:infact:: f("in fact")
:B0X*:infered:: f("inferred")
:B0X*:influented:: f("influenced")
:B0X*:ingreediants:: f("ingredients")
:B0X*:inmigra:: f("immigra")
:B0X*:inocenc:: f("innocenc")
:B0X*:inofficial:: f("unofficial")
:B0X*:inot:: f("into")
:B0X*:inpen:: f("impen")
:B0X*:inperson:: f("in-person")
:B0X*:inspite:: f("in spite")
:B0X*:int he:: f("in the")
:B0X*:interbread:: f("interbred")
:B0X*:intered:: f("interred")
:B0X*:interelat:: f("interrelat")
:B0X*:interm:: f("interim")
:B0X*:interrim:: f("interim")
:B0X*:interrugum:: f("interregnum")
:B0X*:intertain:: f("entertain")
:B0X*:interum:: f("interim")
:B0X*:intervines:: f("intervenes")
:B0X*:intial:: f("initial")
:B0X*:into affect:: f("into effect")
:B0X*:into it's:: f("into its")
:B0X*:introdued:: f("introduced")
:B0X*:intrument:: f("instrument")
:B0X*:intrust:: f("entrust")
:B0X*:inumer:: f("innumer")
:B0X*:inventer:: f("inventor")
:B0X*:invision:: f("envision")
:B0X*:inwhich:: f("in which")
:B0X*:iresis:: f("irresis")
:B0X*:iritab:: f("irritab")
:B0X*:iritat:: f("irritat")
:B0X*:irregardless:: f("regardless")
:B0X*:is front of:: f("in front of")
:B0X*:is it's:: f("is its")
:B0X*:is lead by:: f("is led by")
:B0X*:is loathe to:: f("is loath to")
:B0X*:is ran by:: f("is run by")
:B0X*:is renown for:: f("is renowned for")
:B0X*:is schedule to:: f("is scheduled to")
:B0X*:is set-up:: f("is set up")
:B0X*:is setup:: f("is set up")
:B0X*:is use to:: f("is used to")
:B0X*:is were:: f("is where")
:B0X*:isnt:: f("isn't")
:B0X*:it begun:: f("it began")
:B0X*:it lead to:: f("it led to")
:B0X*:it set-up:: f("it set up")
:B0X*:it setup:: f("it set up")
:B0X*:it snot:: f("it's not")
:B0X*:it spend:: f("it spent")
:B0X*:it use to:: f("it used to")
:B0X*:it was her who:: f("it was she who")
:B0X*:it was him who:: f("it was he who")
:B0X*:it weighted:: f("it weighed")
:B0X*:it weights:: f("it weighs")
:B0X*:it' snot:: f("it's not")
:B0X*:it's end:: f("its end")
:B0X*:it's entire:: f("its entire")
:B0X*:it's goal:: f("its goal")
:B0X*:it's name:: f("its name")
:B0X*:it's own:: f("its own")
:B0X*:it's performance:: f("its performance")
:B0X*:it's successor:: f("its successor")
:B0X*:it's tail:: f("its tail")
:B0X*:it's theme:: f("its theme")
:B0X*:it's timeslot:: f("its timeslot")
:B0X*:it's toll:: f("its toll")
:B0X*:it's website:: f("its website")
:B0X*:itis:: f("it is")
:B0X*:itr:: f("it")
:B0X*:its a:: f("it's a")
:B0X*:its the:: f("it's the")
:B0X*:itwas:: f("it was")
:B0X*:iunior:: f("junior")
:B0X*:jeapard:: f("jeopard")
:B0X*:jewelery:: f("jewelry")
:B0X*:jive with:: f("jibe with")
:B0X*:johanine:: f("Johannine")
:B0X*:jorunal:: f("journal")
:B0X*:jospeh:: f("Joseph")
:B0X*:jouney:: f("journey")
:B0X*:journied:: f("journeyed")
:B0X*:journies:: f("journeys")
:B0X*:juadaism:: f("Judaism")
:B0X*:juadism:: f("Judaism")
:B0X*:key note:: f("keynote")
:B0X*:klenex:: f("kleenex")
:B0X*:knifes:: f("knives")
:B0X*:knive:: f("knife")
:B0X*:lable:: f("label")
:B0X*:labratory:: f("laboratory")
:B0X*:lack there of:: f("lack thereof")
:B0X*:laid ahead:: f("lay ahead")
:B0X*:laid dormant:: f("lay dormant")
:B0X*:laid empty:: f("lay empty")
:B0X*:larger then:: f("larger than")
:B0X*:largley:: f("largely")
:B0X*:largst:: f("largest")
:B0X*:lasoo:: f("lasso")
:B0X*:lastr:: f("last")
:B0X*:lastyear:: f("last year")
:B0X*:laughing stock:: f("laughingstock")
:B0X*:lavae:: f("larvae")
:B0X*:law suite:: f("lawsuit")
:B0X*:lay low:: f("lie low")
:B0X*:layed:: f("laid")
:B0X*:laying around:: f("lying around")
:B0X*:laying awake:: f("lying awake")
:B0X*:laying low:: f("lying low")
:B0X*:lays atop:: f("lies atop")
:B0X*:lays beside:: f("lies beside")
:B0X*:lays in:: f("lies in")
:B0X*:lays low:: f("lies low")
:B0X*:lays near:: f("lies near")
:B0X*:lays on:: f("lies on")
:B0X*:lazer:: f("laser")
:B0X*:lead by:: f("led by")
:B0X*:lead roll:: f("lead role")
:B0X*:leading roll:: f("leading role")
:B0X*:leage:: f("league")
:B0X*:lefr:: f("left")
:B0X*:lefted:: f("left")
:B0X*:leran:: f("learn")
:B0X*:less dominate:: f("less dominant")
:B0X*:less that:: f("less than")
:B0X*:less then:: f("less than")
:B0X*:lesser then:: f("less than")
:B0X*:leutenan:: f("lieutenan")
:B0X*:levle:: f("level")
:B0X*:lias:: f("liais")
:B0X*:libary:: f("library")
:B0X*:libell:: f("libel")
:B0X*:libitarianisn:: f("libertarianism")
:B0X*:lible:: f("libel")
:B0X*:librer:: f("librar")
:B0X*:licence:: f("license")
:B0X*:liesure:: f("leisure")
:B0X*:liev:: f("live")
:B0X*:life time:: f("lifetime")
:B0X*:liftime:: f("lifetime")
:B0X*:lighter then:: f("lighter than")
:B0X*:lightyear:: f("light year")
:B0X*:line of site:: f("line of sight")
:B0X*:line-of-site:: f("line-of-sight")
:B0X*:linnaena:: f("Linnaean")
:B0X*:lions share:: f("lion's share")
:B0X*:liquif:: f("liquef")
:B0X*:litature:: f("literature")
:B0X*:lonelyness:: f("loneliness")
:B0X*:loosing effort:: f("losing effort")
:B0X*:loosing record:: f("losing record")
:B0X*:loosing season:: f("losing season")
:B0X*:loosing streak:: f("losing streak")
:B0X*:loosing team:: f("losing team")
:B0X*:loosing to:: f("losing to")
:B0X*:lower that:: f("lower than")
:B0X*:lower then:: f("lower than")
:B0X*:lsat:: f("last")
:B0X*:lsit:: f("list")
:B0X*:lveo:: f("love")
:B0X*:lvoe:: f("love")
:B0X*:lybia:: f("Libya")
:B0X*:machinary:: f("machinery")
:B0X*:maching:: f("matching")
:B0X*:mackeral:: f("mackerel")
:B0X*:made it's:: f("made its")
:B0X*:magasine:: f("magazine")
:B0X*:maginc:: f("magic")
:B0X*:magizine:: f("magazine")
:B0X*:magnificien:: f("magnificen")
:B0X*:magol:: f("magnol")
:B0X*:maintance:: f("maintenance")
:B0X*:major roll:: f("major role")
:B0X*:make due:: f("make do")
:B0X*:make it's:: f("make its")
:B0X*:malcom:: f("Malcolm")
:B0X*:manisf:: f("manif")
:B0X*:marrtyr:: f("martyr")
:B0X*:massachussets:: f("Massachusetts")
:B0X*:massachussetts:: f("Massachusetts")
:B0X*:massmedia:: f("mass media")
:B0X*:masterbat:: f("masturbat")
:B0X*:mataph:: f("metaph")
:B0X*:materalist:: f("materialist")
:B0X*:mathematican:: f("mathematician")
:B0X*:mathetician:: f("mathematician")
:B0X*:mean while:: f("meanwhile")
:B0X*:mechandi:: f("merchandi")
:B0X*:medievel:: f("medieval")
:B0X*:mediteranean:: f("Mediterranean")
:B0X*:meerkrat:: f("meerkat")
:B0X*:melieux:: f("milieux")
:B0X*:membranaphone:: f("membranophone")
:B0X*:menally:: f("mentally")
:B0X*:mercentil:: f("mercantil")
:B0X*:mesag:: f("messag")
:B0X*:messenging:: f("messaging")
:B0X*:meterolog:: f("meteorolog")
:B0X*:michagan:: f("Michigan")
:B0X*:micheal:: f("Michael")
:B0X*:micos:: f("micros")
:B0X*:miligram:: f("milligram")
:B0X*:milion:: f("million")
:B0X*:milleni:: f("millenni")
:B0X*:millepede:: f("millipede")
:B0X*:miniscule:: f("minuscule")
:B0X*:ministery:: f("ministry")
:B0X*:minor roll:: f("minor role")
:B0X*:minstries:: f("ministries")
:B0X*:minstry:: f("ministry")
:B0X*:minumum:: f("minimum")
:B0X*:mirrorr:: f("mirror")
:B0X*:miscellanious:: f("miscellaneous")
:B0X*:miscellanous:: f("miscellaneous")
:B0X*:mischevious:: f("mischievous")
:B0X*:mischievious:: f("mischievous")
:B0X*:misdameanor:: f("misdemeanor")
:B0X*:misouri:: f("Missouri")
:B0X*:mispell:: f("misspell")
:B0X*:missle:: f("missile")
:B0X*:misteri:: f("mysteri")
:B0X*:mistery:: f("mystery")
:B0X*:mohammedans:: f("muslims")
:B0X*:moil:: f("mohel")
:B0X*:momento:: f("memento")
:B0X*:monestar:: f("monaster")
:B0X*:monicker:: f("moniker")
:B0X*:monkie:: f("monkey")
:B0X*:montain:: f("mountain")
:B0X*:montyp:: f("monotyp")
:B0X*:more dominate:: f("more dominant")
:B0X*:more of less:: f("more or less")
:B0X*:more often then:: f("more often than")
:B0X*:most populace:: f("most populous")
:B0X*:movei:: f("movie")
:B0X*:muhammadan:: f("muslim")
:B0X*:multipled:: f("multiplied")
:B0X*:multiplers:: f("multipliers")
:B0X*:muncipal:: f("municipal")
:B0X*:munnicipal:: f("municipal")
:B0X*:muscician:: f("musician")
:B0X*:mute point:: f("moot point")
:B0X*:myown:: f("my own")
:B0X*:myraid:: f("myriad")
:B0X*:mysogyn:: f("misogyn")
:B0X*:mysterous:: f("mysterious")
:B0X*:naieve:: f("naive")
:B0X*:napoleonian:: f("Napoleonic")
:B0X*:nation wide:: f("nationwide")
:B0X*:nazereth:: f("Nazareth")
:B0X*:near by:: f("nearby")
:B0X*:necessiat:: f("necessitat")
:B0X*:neglib:: f("negligib")
:B0X*:negligab:: f("negligib")
:B0X*:negociab:: f("negotiab")
:B0X*:neverthless:: f("nevertheless")
:B0X*:new comer:: f("newcomer")
:B0X*:newletter:: f("newsletter")
:B0X*:newyorker:: f("New Yorker")
:B0X*:niether:: f("neither")
:B0X*:nightime:: f("nighttime")
:B0X*:nineth:: f("ninth")
:B0X*:ninteenth:: f("nineteenth")
:B0X*:ninties:: f("nineties")
:B0X*:ninty:: f("ninety")
:B0X*:nkwo:: f("know")
:B0X*:no where to:: f("nowhere to")
:B0X*:nontheless:: f("nonetheless")
:B0X*:noone:: f("no one")
:B0X*:norhe:: f("northe")
:B0X*:northen:: f("northern")
:B0X*:northereast:: f("northeast")
:B0X*:note worthy:: f("noteworthy")
:B0X*:noteri:: f("notori")
:B0X*:nothern:: f("northern")
:B0X*:noticable:: f("noticeable")
:B0X*:noticably:: f("noticeably")
:B0X*:notive:: f("notice")
:B0X*:notwhithstanding:: f("notwithstanding")
:B0X*:noveau:: f("nouveau")
:B0X*:nowdays:: f("nowadays")
:B0X*:nowe:: f("now")
:B0X*:nto:: f("not")
:B0X*:nuisanse:: f("nuisance")
:B0X*:numbero:: f("numero")
:B0X*:nusance:: f("nuisance")
:B0X*:nutur:: f("nurtur")
:B0X*:nver:: f("never")
:B0X*:nwe:: f("new")
:B0X*:nwo:: f("now")
:B0X*:obess:: f("obsess")
:B0X*:obssess:: f("obsess")
:B0X*:obstacal:: f("obstacle")
:B0X*:ocasion:: f("occasion")
:B0X*:ocass:: f("occas")
:B0X*:occaison:: f("occasion")
:B0X*:occation:: f("occasion")
:B0X*:octohedr:: f("octahedr")
:B0X*:ocuntr:: f("countr")
:B0X*:of it's kind:: f("of its kind")
:B0X*:of it's own:: f("of its own")
:B0X*:offce:: f("office")
:B0X*:ofits:: f("of its")
:B0X*:oft he:: f("of the")
:B0X*:oftenly:: f("often")
:B0X*:oging:: f("going")
:B0X*:oil barron:: f("oil baron")
:B0X*:omited:: f("omitted")
:B0X*:omiting:: f("omitting")
:B0X*:omlette:: f("omelette")
:B0X*:ommited:: f("omitted")
:B0X*:ommiting:: f("omitting")
:B0X*:ommitted:: f("omitted")
:B0X*:ommitting:: f("omitting")
:B0X*:on accident:: f("by accident")
:B0X*:on going:: f("ongoing")
:B0X*:on it's own:: f("on its own")
:B0X*:on-going:: f("ongoing")
:B0X*:oneof:: f("one of")
:B0X*:ongoing bases:: f("ongoing basis")
:B0X*:onomatopeia:: f("onomatopoeia")
:B0X*:onot:: f("not")
:B0X*:onpar:: f("on par")
:B0X*:ont he:: f("on the")
:B0X*:onyl:: f("only")
:B0X*:openess:: f("openness")
:B0X*:oponen:: f("opponen")
:B0X*:opose:: f("oppose")
:B0X*:oposi:: f("opposi")
:B0X*:oppositit:: f("opposit")
:B0X*:opre:: f("oppre")
:B0X*:optmiz:: f("optimiz")
:B0X*:optomi:: f("optimi")
:B0X*:orded:: f("ordered")
:B0X*:orthag:: f("orthog")
:B0X*:other then:: f("other than")
:B0X*:oublish:: f("publish")
:B0X*:our resent:: f("our recent")
:B0X*:oustanding:: f("outstanding")
:B0X*:out grow:: f("outgrow")
:B0X*:out of sink:: f("out of sync")
:B0X*:out of state:: f("out-of-state")
:B0X*:out side:: f("outside")
:B0X*:outof:: f("out of")
:B0X*:over hear:: f("overhear")
:B0X*:over look:: f("overlook")
:B0X*:over rate:: f("overrate")
:B0X*:over saw:: f("oversaw")
:B0X*:over see:: f("oversee")
:B0X*:overthere:: f("over there")
:B0X*:overwelm:: f("overwhelm")
:B0X*:owudl:: f("would")
:B0X*:owuld:: f("would")
:B0X*:oximoron:: f("oxymoron")
:B0X*:paleolitic:: f("paleolithic")
:B0X*:palist:: f("Palest")
:B0X*:pamflet:: f("pamphlet")
:B0X*:pamplet:: f("pamphlet")
:B0X*:pantomine:: f("pantomime")
:B0X*:paranthe:: f("parenthe")
:B0X*:paraphenalia:: f("paraphernalia")
:B0X*:parrakeet:: f("parakeet")
:B0X*:particulary:: f("particularly")
:B0X*:partof:: f("part of")
:B0X*:pasenger:: f("passenger")
:B0X*:passerbys:: f("passersby")
:B0X*:past away:: f("passed away")
:B0X*:past down:: f("passed down")
:B0X*:pasttime:: f("pastime")
:B0X*:pastural:: f("pastoral")
:B0X*:pavillion:: f("pavilion")
:B0X*:payed:: f("paid")
:B0X*:peacefuland:: f("peaceful and")
:B0X*:peageant:: f("pageant")
:B0X*:peak her interest:: f("pique her interest")
:B0X*:peak his interest:: f("pique his interest")
:B0X*:peaked my interest:: f("piqued my interest")
:B0X*:pedestrain:: f("pedestrian")
:B0X*:pensle:: f("pencil")
:B0X*:peom:: f("poem")
:B0X*:peotry:: f("poetry")
:B0X*:perade:: f("parade")
:B0X*:percentof:: f("percent of")
:B0X*:percentto:: f("percent to")
:B0X*:peretrat:: f("perpetrat")
:B0X*:perheaps:: f("perhaps")
:B0X*:perhpas:: f("perhaps")
:B0X*:peripathetic:: f("peripatetic")
:B0X*:peristen:: f("persisten")
:B0X*:perjer:: f("perjur")
:B0X*:perjorative:: f("pejorative")
:B0X*:perogative:: f("prerogative")
:B0X*:perpindicular:: f("perpendicular")
:B0X*:persan:: f("person")
:B0X*:perseveren:: f("perseveran")
:B0X*:personell:: f("personnel")
:B0X*:personnell:: f("personnel")
:B0X*:persue:: f("pursue")
:B0X*:persui:: f("pursui")
:B0X*:pharoah:: f("Pharaoh")
:B0X*:phenomenonly:: f("phenomenally")
:B0X*:pheonix:: f("phoenix")
:B0X*:philipi:: f("Philippi")
:B0X*:pilgrimm:: f("pilgrim")
:B0X*:pinapple:: f("pineapple")
:B0X*:pinnaple:: f("pineapple")
:B0X*:plagar:: f("plagiar")
:B0X*:planation:: f("plantation")
:B0X*:plantiff:: f("plaintiff")
:B0X*:plateu:: f("plateau")
:B0X*:playright:: f("playwright")
:B0X*:playwrite:: f("playwright")
:B0X*:plebicit:: f("plebiscit")
:B0X*:poety:: f("poetry")
:B0X*:pomegranite:: f("pomegranate")
:B0X*:pomot:: f("promot")
:B0X*:portayed:: f("portrayed")
:B0X*:portugese:: f("Portuguese")
:B0X*:portuguease:: f("Portuguese")
:B0X*:portugues:: f("Portuguese")
:B0X*:posthomous:: f("posthumous")
:B0X*:potatoe:: f("potato")
:B0X*:potatos:: f("potatoes")
:B0X*:potra:: f("portra")
:B0X*:powerfull:: f("powerful")
:B0X*:practioner:: f("practitioner")
:B0X*:prairy:: f("prairie")
:B0X*:prarie:: f("prairie")
:B0X*:pre-Colombian:: f("pre-Columbian")
:B0X*:preample:: f("preamble")
:B0X*:precedessor:: f("predecessor")
:B0X*:precentage:: f("percentage")
:B0X*:precurser:: f("precursor")
:B0X*:preferra:: f("prefera")
:B0X*:premei:: f("premie")
:B0X*:premillenial:: f("premillennial")
:B0X*:preminen:: f("preeminen")
:B0X*:premissio:: f("permissio")
:B0X*:prepart:: f("preparat")
:B0X*:prepat:: f("preparat")
:B0X*:prepera:: f("prepara")
:B0X*:presitg:: f("prestig")
:B0X*:prevers:: f("pervers")
:B0X*:primarly:: f("primarily")
:B0X*:primativ:: f("primitiv")
:B0X*:primordal:: f("primordial")
:B0X*:principaly:: f("principality")
:B0X*:principial:: f("principal")
:B0X*:principlaity:: f("principality")
:B0X*:principle advantage:: f("principal advantage")
:B0X*:principle cause:: f("principal cause")
:B0X*:principle character:: f("principal character")
:B0X*:principle component:: f("principal component")
:B0X*:principle goal:: f("principal goal")
:B0X*:principle group:: f("principal group")
:B0X*:principle method:: f("principal method")
:B0X*:principle owner:: f("principal owner")
:B0X*:principle source:: f("principal source")
:B0X*:principle student:: f("principal student")
:B0X*:principly:: f("principally")
:B0X*:prinici:: f("princi")
:B0X*:privt:: f("privat")
:B0X*:procede:: f("proceed")
:B0X*:procedger:: f("procedure")
:B0X*:proceding:: f("proceeding")
:B0X*:proceedur:: f("procedur")
:B0X*:profesor:: f("professor")
:B0X*:profilic:: f("prolific")
:B0X*:progid:: f("prodig")
:B0X*:prologomena:: f("prolegomena")
:B0X*:promiscous:: f("promiscuous")
:B0X*:pronomial:: f("pronominal")
:B0X*:proof read:: f("proofread")
:B0X*:prophacy:: f("prophecy")
:B0X*:propoga:: f("propaga")
:B0X*:proseletyz:: f("proselytiz")
:B0X*:protocal:: f("protocol")
:B0X*:protruberanc:: f("protuberanc")
:B0X*:proximty:: f("proximity")
:B0X*:pseudonyn:: f("pseudonym")
:B0X*:publically:: f("publicly")
:B0X*:puch:: f("push")
:B0X*:pumkin:: f("pumpkin")
:B0X*:puritannic:: f("puritanic")
:B0X*:purposedly:: f("purposely")
:B0X*:purpot:: f("purport")
:B0X*:puting:: f("putting")
:B0X*:pysci:: f("psychi")
:B0X*:quantat:: f("quantit")
:B0X*:quess:: f("guess")
:B0X*:quinessen:: f("quintessen")
:B0X*:quitted:: f("quit")
:B0X*:quize:: f("quizze")
:B0X*:racaus:: f("raucous")
:B0X*:raed:: f("read")
:B0X*:raing:: f("rating")
:B0X*:rasberr:: f("raspberr")
:B0X*:rather then:: f("rather than")
:B0X*:reasea:: f("resea")
:B0X*:rebounce:: f("rebound")
:B0X*:receivedfrom:: f("received from")
:B0X*:recie:: f("recei")
:B0X*:reciv:: f("receiv")
:B0X*:recomen:: f("recommen")
:B0X*:reconaissance:: f("reconnaissance")
:B0X*:reconize:: f("recognize")
:B0X*:recuit:: f("recruit")
:B0X*:recurran:: f("recurren")
:B0X*:redicu:: f("ridicu")
:B0X*:reek havoc:: f("wreak havoc")
:B0X*:refedend:: f("referend")
:B0X*:refridgera:: f("refrigera")
:B0X*:refusla:: f("refusal")
:B0X*:reher:: f("rehear")
:B0X*:reica:: f("reinca")
:B0X*:reign in:: f("rein in")
:B0X*:reigns of power:: f("reins of power")
:B0X*:reknown:: f("renown")
:B0X*:relected:: f("reelected")
:B0X*:reliz:: f("realiz")
:B0X*:remaing:: f("remaining")
:B0X*:rememberable:: f("memorable")
:B0X*:remenant:: f("remnant")
:B0X*:remenic:: f("reminisc")
:B0X*:reminent:: f("remnant")
:B0X*:remines:: f("reminis")
:B0X*:reminsc:: f("reminisc")
:B0X*:reminsic:: f("reminisc")
:B0X*:rendevous:: f("rendezvous")
:B0X*:rendezous:: f("rendezvous")
:B0X*:renewl:: f("renewal")
:B0X*:repid:: f("rapid")
:B0X*:repon:: f("respon")
:B0X*:reprtoire:: f("repertoire")
:B0X*:repubi:: f("republi")
:B0X*:requr:: f("requir")
:B0X*:resaura:: f("restaura")
:B0X*:resembe:: f("resemble")
:B0X*:resently:: f("recently")
:B0X*:resevoir:: f("reservoir")
:B0X*:resignement:: f("resignation")
:B0X*:resignment:: f("resignation")
:B0X*:resse:: f("rese")
:B0X*:ressurrect:: f("resurrect")
:B0X*:restara:: f("restaura")
:B0X*:restaurati:: f("restorati")
:B0X*:resteraunt:: f("restaurant")
:B0X*:restraunt:: f("restaurant")
:B0X*:resturant:: f("restaurant")
:B0X*:retalitat:: f("retaliat")
:B0X*:retrun:: f("return")
:B0X*:retun:: f("return")
:B0X*:reult:: f("result")
:B0X*:revaluat:: f("reevaluat")
:B0X*:reveral:: f("reversal")
:B0X*:rfere:: f("refere")
:B0X*:rised:: f("rose")
:B0X*:rockerfeller:: f("Rockefeller")
:B0X*:rococco:: f("rococo")
:B0X*:role call:: f("roll call")
:B0X*:roll play:: f("role play")
:B0X*:roomate:: f("roommate")
:B0X*:rucupera:: f("recupera")
:B0X*:rulle:: f("rule")
:B0X*:rumer:: f("rumor")
:B0X*:runner up:: f("runner-up")
:B0X*:russina:: f("Russian")
:B0X*:russion:: f("Russian")
:B0X*:rythem:: f("rhythm")
:B0X*:rythm:: f("rhythm")
:B0X*:sacrelig:: f("sacrileg")
:B0X*:sacrifical:: f("sacrificial")
:B0X*:saddle up to:: f("sidle up to")
:B0X*:safegard:: f("safeguard")
:B0X*:saidhe:: f("said he")
:B0X*:saidt he:: f("said the")
:B0X*:salery:: f("salary")
:B0X*:sandess:: f("sadness")
:B0X*:sandwhich:: f("sandwich")
:B0X*:sargan:: f("sergean")
:B0X*:sargean:: f("sergean")
:B0X*:saterday:: f("Saturday")
:B0X*:saxaphon:: f("saxophon")
:B0X*:say la v:: f("c'est la vie")
:B0X*:scandanavia:: f("Scandinavia")
:B0X*:scaricit:: f("scarcit")
:B0X*:scavang:: f("scaveng")
:B0X*:scrutinit:: f("scrutin")
:B0X*:scuptur:: f("sculptur")
:B0X*:secceed:: f("seced")
:B0X*:secrata:: f("secreta")
:B0X*:see know:: f("see now")
:B0X*:seguoy:: f("segue")
:B0X*:seh:: f("she")
:B0X*:seinor:: f("senior")
:B0X*:senari:: f("scenari")
:B0X*:senc:: f("sens")
:B0X*:sentan:: f("senten")
:B0X*:sepina:: f("subpoena")
:B0X*:sergent:: f("sergeant")
:B0X*:set back:: f("setback")
:B0X*:severley:: f("severely")
:B0X*:severly:: f("severely")
:B0X*:shamen:: f("shaman")
:B0X*:she begun:: f("she began")
:B0X*:she let's:: f("she lets")
:B0X*:she seen:: f("she saw")
:B0X*:shiped:: f("shipped")
:B0X*:short coming:: f("shortcoming")
:B0X*:shorter then:: f("shorter than")
:B0X*:shortly there after:: f("shortly thereafter")
:B0X*:shortwhile:: f("short while")
:B0X*:shoudl:: f("should")
:B0X*:should backup:: f("should back up")
:B0X*:should've went:: f("should have gone")
:B0X*:shreak:: f("shriek")
:B0X*:shrinked:: f("shrunk")
:B0X*:side affect:: f("side effect")
:B0X*:side kick:: f("sidekick")
:B0X*:sideral:: f("sidereal")
:B0X*:siez:: f("seiz")
:B0X*:silicone chip:: f("silicon chip")
:B0X*:simetr:: f("symmetr")
:B0X*:simplier:: f("simpler")
:B0X*:single handily:: f("single-handedly")
:B0X*:singsog:: f("singsong")
:B0X*:site line:: f("sight line")
:B0X*:slight of hand:: f("sleight of hand")
:B0X*:slue of:: f("slew of")
:B0X*:smaller then:: f("smaller than")
:B0X*:smarter then:: f("smarter than")
:B0X*:sneak peak:: f("sneak peek")
:B0X*:sneek:: f("sneak")
:B0X*:so it you:: f("so if you")
:B0X*:socit:: f("societ")
:B0X*:sofware:: f("software")
:B0X*:soilder:: f("soldier")
:B0X*:solatar:: f("solitar")
:B0X*:soley:: f("solely")
:B0X*:soliders:: f("soldiers")
:B0X*:soliliqu:: f("soliloqu")
:B0X*:some what:: f("somewhat")
:B0X*:some where:: f("somewhere")
:B0X*:somene:: f("someone")
:B0X*:someting:: f("something")
:B0X*:somthing:: f("something")
:B0X*:somtime:: f("sometime")
:B0X*:somwhere:: f("somewhere")
:B0X*:soon there after:: f("soon thereafter")
:B0X*:sooner then:: f("sooner than")
:B0X*:sophmore:: f("sophomore")
:B0X*:sorceror:: f("sorcerer")
:B0X*:sorround:: f("surround")
:B0X*:sot hat:: f("so that")
:B0X*:sotyr:: f("story")
:B0X*:sould:: f("should")
:B0X*:sountrack:: f("soundtrack")
:B0X*:sourth:: f("south")
:B0X*:souvenier:: f("souvenir")
:B0X*:soveit:: f("soviet")
:B0X*:sovereignit:: f("sovereignt")
:B0X*:spainish:: f("Spanish")
:B0X*:speach:: f("speech")
:B0X*:speciman:: f("specimen")
:B0X*:spendour:: f("splendour")
:B0X*:spilt among:: f("split among")
:B0X*:spilt between:: f("split between")
:B0X*:spilt into:: f("split into")
:B0X*:spilt up:: f("split up")
:B0X*:spinal chord:: f("spinal cord")
:B0X*:split in to:: f("split into")
:B0X*:sportscar:: f("sports car")
:B0X*:sppech:: f("speech")
:B0X*:spreaded:: f("spread")
:B0X*:sprech:: f("speech")
:B0X*:sq ft:: f("ft²")
:B0X*:sq in:: f("in²")
:B0X*:sq km:: f("km²")
:B0X*:squared feet:: f("square feet")
:B0X*:squared inch:: f("square inch")
:B0X*:squared kilometer:: f("square kilometer")
:B0X*:squared meter:: f("square meter")
:B0X*:squared mile:: f("square mile")
:B0X*:stale mat:: f("stalemat")
:B0X*:standars:: f("standards")
:B0X*:staring role:: f("starring role")
:B0X*:starring roll:: f("starring role")
:B0X*:stay a while:: f("stay awhile")
:B0X*:stilus:: f("stylus")
:B0X*:stomache:: f("stomach")
:B0X*:storise:: f("stories")
:B0X*:stornegst:: f("strongest")
:B0X*:stpo:: f("stop")
:B0X*:strenous:: f("strenuous")
:B0X*:strictist:: f("strictest")
:B0X*:strike out:: f("strikeout")
:B0X*:strikely:: f("strikingly")
:B0X*:strnad:: f("strand")
:B0X*:stronger then:: f("stronger than")
:B0X*:stroy:: f("story")
:B0X*:struggel:: f("struggle")
:B0X*:strugl:: f("struggl")
:B0X*:stubborness:: f("stubbornness")
:B0X*:student's that:: f("students that")
:B0X*:stuggl:: f("struggl")
:B0X*:subjudgation:: f("subjugation")
:B0X*:subpecies:: f("subspecies")
:B0X*:subsidar:: f("subsidiar")
:B0X*:subsiduar:: f("subsidiar")
:B0X*:subsquen:: f("subsequen")
:B0X*:substace:: f("substance")
:B0X*:substatia:: f("substantia")
:B0X*:substitud:: f("substitut")
:B0X*:substract:: f("subtract")
:B0X*:subtance:: f("substance")
:B0X*:suburburban:: f("suburban")
:B0X*:succedd:: f("succeed")
:B0X*:succede:: f("succeede")
:B0X*:succeds:: f("succeeds")
:B0X*:suceed:: f("succeed")
:B0X*:sucide:: f("suicide")
:B0X*:sucidial:: f("suicidal")
:B0X*:sudent:: f("student")
:B0X*:sufferag:: f("suffrag")
:B0X*:sumar:: f("summar")
:B0X*:suop:: f("soup")
:B0X*:superce:: f("superse")
:B0X*:supliment:: f("supplement")
:B0X*:suppliment:: f("supplement")
:B0X*:suppose to:: f("supposed to")
:B0X*:supposingly:: f("supposedly")
:B0X*:surplant:: f("supplant")
:B0X*:surrended:: f("surrendered")
:B0X*:surrepetitious:: f("surreptitious")
:B0X*:surreptious:: f("surreptitious")
:B0X*:surrond:: f("surround")
:B0X*:surroud:: f("surround")
:B0X*:surrunder:: f("surrender")
:B0X*:surveilen:: f("surveillan")
:B0X*:surviver:: f("survivor")
:B0X*:survivied:: f("survived")
:B0X*:swiming:: f("swimming")
:B0X*:synagouge:: f("synagogue")
:B0X*:synph:: f("symph")
:B0X*:syrap:: f("syrup")
:B0X*:tabacco:: f("tobacco")
:B0X*:take affect:: f("take effect")
:B0X*:take over the reigns:: f("take over the reins")
:B0X*:take the reigns:: f("take the reins")
:B0X*:taken the reigns:: f("taken the reins")
:B0X*:taking the reigns:: f("taking the reins")
:B0X*:tatoo:: f("tattoo")
:B0X*:teacg:: f("teach")
:B0X*:teached:: f("taught")
:B0X*:telelev:: f("telev")
:B0X*:televiz:: f("televis")
:B0X*:televsion:: f("television")
:B0X*:tellt he:: f("tell the")
:B0X*:temerature:: f("temperature")
:B0X*:temperment:: f("temperament")
:B0X*:temperture:: f("temperature")
:B0X*:tenacle:: f("tentacle")
:B0X*:termoil:: f("turmoil")
:B0X*:testomon:: f("testimon")
:B0X*:thansk:: f("thanks")
:B0X*:thast:: f("that's")
:B0X*:that him and:: f("that he and")
:B0X*:thats:: f("that's")
:B0X*:thatt he:: f("that the")
:B0X*:the absent of:: f("the absence of")
:B0X*:the affect on:: f("the effect on")
:B0X*:the affects of:: f("the effects of")
:B0X*:the both the:: f("both the")
:B0X*:the break down:: f("the breakdown")
:B0X*:the break up:: f("the breakup")
:B0X*:the build up:: f("the buildup")
:B0X*:the clamp down:: f("the clampdown")
:B0X*:the crack down:: f("the crackdown")
:B0X*:the follow up:: f("the follow-up")
:B0X*:the injures:: f("the injuries")
:B0X*:the lead up:: f("the lead-up")
:B0X*:the phenomena is:: f("the phenomenon is")
:B0X*:the rational behind:: f("the rationale behind")
:B0X*:the rational for:: f("the rationale for")
:B0X*:the resent:: f("the recent")
:B0X*:the set up:: f("the setup")
:B0X*:thecompany:: f("the company")
:B0X*:thefirst:: f("the first")
:B0X*:thegovernment:: f("the government")
:B0X*:theif:: f("thief")
:B0X*:their are:: f("there are")
:B0X*:their had:: f("there had")
:B0X*:their may be:: f("there may be")
:B0X*:their was:: f("there was")
:B0X*:their were:: f("there were")
:B0X*:their would:: f("there would")
:B0X*:them selves:: f("themselves")
:B0X*:themselfs:: f("themselves")
:B0X*:themslves:: f("themselves")
:B0X*:thenew:: f("the new")
:B0X*:therafter:: f("thereafter")
:B0X*:therby:: f("thereby")
:B0X*:there after:: f("thereafter")
:B0X*:there best:: f("their best")
:B0X*:there by:: f("thereby")
:B0X*:there final:: f("their final")
:B0X*:there first:: f("their first")
:B0X*:there last:: f("their last")
:B0X*:there new:: f("their new")
:B0X*:there own:: f("their own")
:B0X*:there where:: f("there were")
:B0X*:there's is:: f("theirs is")
:B0X*:there's three:: f("there are three")
:B0X*:there's two:: f("there are two")
:B0X*:thesame:: f("the same")
:B0X*:these includes:: f("these include")
:B0X*:these type of:: f("these types of")
:B0X*:these where:: f("these were")
:B0X*:thetwo:: f("the two")
:B0X*:they begun:: f("they began")
:B0X*:they we're:: f("they were")
:B0X*:they weight:: f("they weigh")
:B0X*:they where:: f("they were")
:B0X*:they're are:: f("there are")
:B0X*:they're is:: f("there is")
:B0X*:theyll:: f("they'll")
:B0X*:theyre:: f("they're")
:B0X*:theyve:: f("they've")
:B0X*:thier:: f("their")
:B0X*:this data:: f("these data")
:B0X*:this gut:: f("this guy")
:B0X*:this maybe:: f("this may be")
:B0X*:this resent:: f("this recent")
:B0X*:thisyear:: f("this year")
:B0X*:thna:: f("than")
:B0X*:those includes:: f("those include")
:B0X*:those maybe:: f("those may be")
:B0X*:thoughout:: f("throughout")
:B0X*:thousend:: f("thousand")
:B0X*:threatend:: f("threatened")
:B0X*:threshhold:: f("threshold")
:B0X*:thrid:: f("third")
:B0X*:thror:: f("thor")
:B0X*:through it's:: f("through its")
:B0X*:through the ringer:: f("through the wringer")
:B0X*:throughly:: f("thoroughly")
:B0X*:throughout it's:: f("throughout its")
:B0X*:througout:: f("throughout")
:B0X*:throws of passion:: f("throes of passion")
:B0X*:thta:: f("that")
:B0X*:tiem:: f("time")
:B0X*:time out:: f("timeout")
:B0X*:timeschedule:: f("time schedule")
:B0X*:timne:: f("time")
:B0X*:tiome:: f("time")
:B0X*:to back fire:: f("to backfire")
:B0X*:to back-off:: f("to back off")
:B0X*:to back-out:: f("to back out")
:B0X*:to back-up:: f("to back up")
:B0X*:to backoff:: f("to back off")
:B0X*:to backout:: f("to back out")
:B0X*:to backup:: f("to back up")
:B0X*:to bailout:: f("to bail out")
:B0X*:to be setup:: f("to be set up")
:B0X*:to blackout:: f("to black out")
:B0X*:to blastoff:: f("to blast off")
:B0X*:to blowout:: f("to blow out")
:B0X*:to blowup:: f("to blow up")
:B0X*:to breakdown:: f("to break down")
:B0X*:to buildup:: f("to build up")
:B0X*:to built:: f("to build")
:B0X*:to buyout:: f("to buy out")
:B0X*:to comeback:: f("to come back")
:B0X*:to crackdown on:: f("to crack down on")
:B0X*:to cutback:: f("to cut back")
:B0X*:to cutoff:: f("to cut off")
:B0X*:to dropout:: f("to drop out")
:B0X*:to emphasis the:: f("to emphasise the")
:B0X*:to fill-in:: f("to fill in")
:B0X*:to forego:: f("to forgo")
:B0X*:to happened:: f("to happen")
:B0X*:to have lead to:: f("to have led to")
:B0X*:to he and:: f("to him and")
:B0X*:to holdout:: f("to hold out")
:B0X*:to kickoff:: f("to kick off")
:B0X*:to lockout:: f("to lock out")
:B0X*:to lockup:: f("to lock up")
:B0X*:to login:: f("to log in")
:B0X*:to logout:: f("to log out")
:B0X*:to lookup:: f("to look up")
:B0X*:to markup:: f("to mark up")
:B0X*:to opt-in:: f("to opt in")
:B0X*:to opt-out:: f("to opt out")
:B0X*:to phaseout:: f("to phase out")
:B0X*:to pickup:: f("to pick up")
:B0X*:to playback:: f("to play back")
:B0X*:to rebuilt:: f("to be rebuilt")
:B0X*:to rollback:: f("to roll back")
:B0X*:to runaway:: f("to run away")
:B0X*:to seen:: f("to be seen")
:B0X*:to sent:: f("to send")
:B0X*:to setup:: f("to set up")
:B0X*:to shut-down:: f("to shut down")
:B0X*:to shutdown:: f("to shut down")
:B0X*:to spent:: f("to spend")
:B0X*:to spin-off:: f("to spin off")
:B0X*:to spinoff:: f("to spin off")
:B0X*:to takeover:: f("to take over")
:B0X*:to that affect:: f("to that effect")
:B0X*:to they're:: f("to their")
:B0X*:to touchdown:: f("to touch down")
:B0X*:to try-out:: f("to try out")
:B0X*:to tryout:: f("to try out")
:B0X*:to turn-off:: f("to turn off")
:B0X*:to turnaround:: f("to turn around")
:B0X*:to turnoff:: f("to turn off")
:B0X*:to turnout:: f("to turn out")
:B0X*:to turnover:: f("to turn over")
:B0X*:to wakeup:: f("to wake up")
:B0X*:to walkout:: f("to walk out")
:B0X*:to wipeout:: f("to wipe out")
:B0X*:to withdrew:: f("to withdraw")
:B0X*:to workaround:: f("to work around")
:B0X*:to workout:: f("to work out")
:B0X*:tobbaco:: f("tobacco")
:B0X*:today of:: f("today or")
:B0X*:todays:: f("today's")
:B0X*:todya:: f("today")
:B0X*:toldt he:: f("told the")
:B0X*:tolkein:: f("Tolkien")
:B0X*:tomatos:: f("tomatoes")
:B0X*:tommorrow:: f("tomorrow")
:B0X*:too also:: f("also")
:B0X*:too be:: f("to be")
:B0X*:took affect:: f("took effect")
:B0X*:took and interest:: f("took an interest")
:B0X*:took awhile:: f("took a while")
:B0X*:took over the reigns:: f("took over the reins")
:B0X*:took the reigns:: f("took the reins")
:B0X*:toolket:: f("toolkit")
:B0X*:tornadoe:: f("tornado")
:B0X*:torpeados:: f("torpedoes")
:B0X*:torpedos:: f("torpedoes")
:B0X*:tortise:: f("tortoise")
:B0X*:tot he:: f("to the")
:B0X*:tothe:: f("to the")
:B0X*:traffice:: f("trafficke")
:B0X*:trafficing:: f("trafficking")
:B0X*:trancend:: f("transcend")
:B0X*:transcendan:: f("transcenden")
:B0X*:transcripting:: f("transcribing")
:B0X*:transend:: f("transcend")
:B0X*:transfered:: f("transferred")
:B0X*:transferin:: f("transferrin")
:B0X*:translater:: f("translator")
:B0X*:transpora:: f("transporta")
:B0X*:tremelo:: f("tremolo")
:B0X*:triathalon:: f("triathlon")
:B0X*:tried to used:: f("tried to use")
:B0X*:triguer:: f("trigger")
:B0X*:triolog:: f("trilog")
:B0X*:try and:: f("try to")
:B0X*:tthe:: f("the")
:B0X*:turn for the worst:: f("turn for the worse")
:B0X*:tuscon:: f("Tucson")
:B0X*:tust:: f("trust")
:B0X*:tution:: f("tuition")
:B0X*:twelth:: f("twelfth")
:B0X*:twelve month's:: f("twelve months")
:B0X*:twice as much than:: f("twice as much as")
:B0X*:two in a half:: f("two and a half")
:B0X*:tyhe:: f("they")
:B0X*:tyo:: f("to")
:B0X*:tyrany:: f("tyranny")
:B0X*:tyrrani:: f("tyranni")
:B0X*:tyrrany:: f("tyranny")
:B0X*:uber:: f("über")
:B0X*:ubli:: f("publi")
:B0X*:uise:: f("use")
:B0X*:ukran:: f("Ukrain")
:B0X*:ulser:: f("ulcer")
:B0X*:unanym:: f("unanim")
:B0X*:unbeknowst:: f("unbeknownst")
:B0X*:under go:: f("undergo")
:B0X*:under it's:: f("under its")
:B0X*:under rate:: f("underrate")
:B0X*:under take:: f("undertake")
:B0X*:under wear:: f("underwear")
:B0X*:under went:: f("underwent")
:B0X*:underat:: f("underrat")
:B0X*:undert he:: f("under the")
:B0X*:undoubtely:: f("undoubtedly")
:B0X*:undreground:: f("underground")
:B0X*:unecessar:: f("unnecessar")
:B0X*:unequalit:: f("inequalit")
:B0X*:unihabit:: f("uninhabit")
:B0X*:unitedstates:: f("United States")
:B0X*:unitesstates:: f("United States")
:B0X*:univeral:: f("universal")
:B0X*:univerist:: f("universit")
:B0X*:univerit:: f("universit")
:B0X*:universti:: f("universit")
:B0X*:univesit:: f("universit")
:B0X*:unoperational:: f("nonoperational")
:B0X*:unotice:: f("unnotice")
:B0X*:unplease:: f("displease")
:B0X*:unsed:: f("unused")
:B0X*:untill:: f("until")
:B0X*:unuseable:: f("unusable")
:B0X*:up field:: f("upfield")
:B0X*:up it's:: f("up its")
:B0X*:up side:: f("upside")
:B0X*:upon it's:: f("upon its")
:B0X*:upto:: f("up to")
:B0X*:usally:: f("usually")
:B0X*:use to:: f("used to")
:B0X*:vaccum:: f("vacuum")
:B0X*:vacinit:: f("vicinit")
:B0X*:vaguar:: f("vagar")
:B0X*:vaiet:: f("variet")
:B0X*:varit:: f("variet")
:B0X*:vasall:: f("vassal")
:B0X*:vehicule:: f("vehicle")
:B0X*:vengance:: f("vengeance")
:B0X*:vengence:: f("vengeance")
:B0X*:verfication:: f("verification")
:B0X*:vermillion:: f("vermilion")
:B0X*:versitilat:: f("versatilit")
:B0X*:versitlit:: f("versatilit")
:B0X*:vetween:: f("between")
:B0X*:via it's:: f("via its")
:B0X*:viathe:: f("via the")
:B0X*:vigour:: f("vigor")
:B0X*:villian:: f("villain")
:B0X*:villifi:: f("vilifi")
:B0X*:villify:: f("vilify")
:B0X*:villin:: f("villain")
:B0X*:vincinit:: f("vicinit")
:B0X*:virutal:: f("virtual")
:B0X*:visabl:: f("visibl")
:B0X*:vise versa:: f("vice versa")
:B0X*:vistor:: f("visitor")
:B0X*:vitor:: f("victor")
:B0X*:vocal chord:: f("vocal cord")
:B0X*:volcanoe:: f("volcano")
:B0X*:voley:: f("volley")
:B0X*:volkswagon:: f("Volkswagen")
:B0X*:vreity:: f("variety")
:B0X*:vriet:: f("variet")
:B0X*:vulnerablilit:: f("vulnerabilit")
:B0X*:wa snot:: f("was not")
:B0X*:waived off:: f("waved off")
:B0X*:wan tit:: f("want it")
:B0X*:wanna:: f("want to")
:B0X*:warantee:: f("warranty")
:B0X*:wardobe:: f("wardrobe")
:B0X*:warn away:: f("worn away")
:B0X*:warn down:: f("worn down")
:B0X*:warn out:: f("worn out")
:B0X*:was apart of:: f("was a part of")
:B0X*:was began:: f("began")
:B0X*:was build:: f("was built")
:B0X*:was cutoff:: f("was cut off")
:B0X*:was do to:: f("was due to")
:B0X*:was drank:: f("was drunk")
:B0X*:was it's:: f("was its")
:B0X*:was knew:: f("was known")
:B0X*:was lain:: f("was laid")
:B0X*:was laying on:: f("was lying on")
:B0X*:was lead by:: f("was led by")
:B0X*:was lead to:: f("was led to")
:B0X*:was leaded by:: f("was led by")
:B0X*:was loathe to:: f("was loath to")
:B0X*:was loathed to:: f("was loath to")
:B0X*:was meet by:: f("was met by")
:B0X*:was meet with:: f("was met with")
:B0X*:was mislead:: f("was misled")
:B0X*:was rebuild:: f("was rebuilt")
:B0X*:was release by:: f("was released by")
:B0X*:was release on:: f("was released on")
:B0X*:was reran:: f("was rerun")
:B0X*:was sang:: f("was sung")
:B0X*:was schedule to:: f("was scheduled to")
:B0X*:was send:: f("was sent")
:B0X*:was sentence to:: f("was sentenced to")
:B0X*:was set-up:: f("was set up")
:B0X*:was setup:: f("was set up")
:B0X*:was shook:: f("was shaken")
:B0X*:was shoot:: f("was shot")
:B0X*:was show by:: f("was shown by")
:B0X*:was show on:: f("was shown on")
:B0X*:was showed:: f("was shown")
:B0X*:was shut-off:: f("was shut off")
:B0X*:was shutdown:: f("was shut down")
:B0X*:was shutoff:: f("was shut off")
:B0X*:was shutout:: f("was shut out")
:B0X*:was sold-out:: f("was sold out")
:B0X*:was spend:: f("was spent")
:B0X*:was succeed by:: f("was succeeded by")
:B0X*:was suppose to:: f("was supposed to")
:B0X*:was though that:: f("was thought that")
:B0X*:was use to:: f("was used to")
:B0X*:wasnt:: f("wasn't")
:B0X*:way side:: f("wayside")
:B0X*:wayword:: f("wayward")
:B0X*:we;d:: f("we'd")
:B0X*:weaponary:: f("weaponry")
:B0X*:weather or not:: f("whether or not")
:B0X*:well know:: f("well known")
:B0X*:wendsay:: f("Wednesday")
:B0X*:wensday:: f("Wednesday")
:B0X*:went rouge:: f("went rogue")
:B0X*:went threw:: f("went through")
:B0X*:were apart of:: f("were a part of")
:B0X*:were began:: f("were begun")
:B0X*:were cutoff:: f("were cut off")
:B0X*:were drew:: f("were drawn")
:B0X*:were he was:: f("where he was")
:B0X*:were it was:: f("where it was")
:B0X*:were it's:: f("were its")
:B0X*:were knew:: f("were known")
:B0X*:were know:: f("were known")
:B0X*:were lain:: f("were laid")
:B0X*:were lead by:: f("were led by")
:B0X*:were loathe to:: f("were loath to")
:B0X*:were meet by:: f("were met by")
:B0X*:were meet with:: f("were met with")
:B0X*:were overran:: f("were overrun")
:B0X*:were reran:: f("were rerun")
:B0X*:were sang:: f("were sung")
:B0X*:were set-up:: f("were set up")
:B0X*:were setup:: f("were set up")
:B0X*:were she was:: f("where she was")
:B0X*:were showed:: f("were shown")
:B0X*:were shut-out:: f("were shut out")
:B0X*:were shutdown:: f("were shut down")
:B0X*:were shutoff:: f("were shut off")
:B0X*:were shutout:: f("were shut out")
:B0X*:were suppose to:: f("were supposed to")
:B0X*:were took:: f("were taken")
:B0X*:were use to:: f("were used to")
:B0X*:wereabouts:: f("whereabouts")
:B0X*:wern't:: f("weren't")
:B0X*:wet your:: f("whet your")
:B0X*:wether or not:: f("whether or not")
:B0X*:what lead to:: f("what led to")
:B0X*:what lied:: f("what lay")
:B0X*:whent he:: f("when the")
:B0X*:wheras:: f("whereas")
:B0X*:where abouts:: f("whereabouts")
:B0X*:where being:: f("were being")
:B0X*:where by:: f("whereby")
:B0X*:where him:: f("where he")
:B0X*:where made:: f("were made")
:B0X*:where taken:: f("were taken")
:B0X*:where upon:: f("whereupon")
:B0X*:where won:: f("were won")
:B0X*:wherease:: f("whereas")
:B0X*:whereever:: f("wherever")
:B0X*:which had lead:: f("which had led")
:B0X*:which has lead:: f("which has led")
:B0X*:which have lead:: f("which have led")
:B0X*:which where:: f("which were")
:B0X*:whicht he:: f("which the")
:B0X*:while him:: f("while he")
:B0X*:whn:: f("when")
:B0X*:who had lead:: f("who had led")
:B0X*:who has lead:: f("who has led")
:B0X*:who have lead:: f("who have led")
:B0X*:who setup:: f("who set up")
:B0X*:who use to:: f("who used to")
:B0X*:who where:: f("who were")
:B0X*:who's actual:: f("whose actual")
:B0X*:who's brother:: f("whose brother")
:B0X*:who's father:: f("whose father")
:B0X*:who's mother:: f("whose mother")
:B0X*:who's name:: f("whose name")
:B0X*:who's opinion:: f("whose opinion")
:B0X*:who's own:: f("whose own")
:B0X*:who's parents:: f("whose parents")
:B0X*:who's previous:: f("whose previous")
:B0X*:who's team:: f("whose team")
:B0X*:wholey:: f("wholly")
:B0X*:wholy:: f("wholly")
:B0X*:whould:: f("would")
:B0X*:whther:: f("whether")
:B0X*:widesread:: f("widespread")
:B0X*:wihh:: f("withh")
:B0X*:will backup:: f("will back up")
:B0X*:will buyout:: f("will buy out")
:B0X*:will shutdown:: f("will shut down")
:B0X*:will shutoff:: f("will shut off")
:B0X*:willbe:: f("will be")
:B0X*:winther:: f("winter")
:B0X*:with be:: f("will be")
:B0X*:with it's:: f("with its")
:B0X*:with out:: f("without")
:B0X*:with regards to:: f("with regard to")
:B0X*:withdrawl:: f("withdrawal")
:B0X*:witheld:: f("withheld")
:B0X*:withi t:: f("with it")
:B0X*:within it's:: f("within its")
:B0X*:within site of:: f("within sight of")
:B0X*:withold:: f("withhold")
:B0X*:witht he:: f("with the")
:B0X*:wno:: f("sno")
:B0X*:won it's:: f("won its")
:B0X*:wordlwide:: f("worldwide")
:B0X*:working progress:: f("work in progress")
:B0X*:world wide:: f("worldwide")
:B0X*:worse comes to worse:: f("worse comes to worst")
:B0X*:worse then:: f("worse than")
:B0X*:worse-case scenario:: f("worst-case scenario")
:B0X*:worst comes to worst:: f("worse comes to worst")
:B0X*:worst than:: f("worse than")
:B0X*:worsten:: f("worsen")
:B0X*:worth it's:: f("worth its")
:B0X*:worth while:: f("worthwhile")
:B0X*:woudl:: f("would")
:B0X*:would backup:: f("would back up")
:B0X*:would comeback:: f("would come back")
:B0X*:would fair:: f("would fare")
:B0X*:would forego:: f("would forgo")
:B0X*:would setup:: f("would set up")
:B0X*:wouldbe:: f("would be")
:B0X*:wreck havoc:: f("wreak havoc")
:B0X*:wreckless:: f("reckless")
:B0X*:writers block:: f("writer's block")
:B0X*:xoom:: f("zoom")
:B0X*:yatch:: f("yacht")
:B0X*:year old:: f("year-old")
:B0X*:yelow:: f("yellow")
:B0X*:yera:: f("year")
:B0X*:yotube:: f("youtube")
:B0X*:you're own:: f("your own")
:B0X*:you;d:: f("you'd")
:B0X*:youare:: f("you are")
:B0X*:your their:: f("you're their")
:B0X*:your your:: f("you're your")
:B0X*:youseff:: f("yousef")
:B0X*:youself:: f("yourself")
:B0X*:yrea:: f("year")
:B0X*?:arrern:: f("attern")
:B0X*?:boder-line:: f("border-line")
:B0X*?:duec:: f("duce")
:B0X*?:eckk:: f("eck")
:B0X*?:heee:: f("hee")
:B0X*?:leee:: f("lee")
:B0X*?:oloo:: f("ollo")
:B0X*?:reee:: f("ree")
:B0X*?:seee:: f("see")
:B0X*?:uttoo:: f("utto")
:B0X*?:uyt:: f("ut")
:B0X*?:vition:: f("vision")
:B0X*?:waty:: f("way")
:B0X*?:weee:: f("wee")
:B0X*?:ytion:: f("tion")
:B0X*C:aquit:: f("acquit")
:B0X*C:carmel:: f("caramel")
:B0X*C:carrer:: f("career")
:B0X*C:daed:: f("dead")
:B0X*C:ehr:: f("her")
:B0X*C:english:: f("English")
:B0X*C:herat:: f("heart")
:B0X*C:hsi:: f("his")
:B0X*C:ime:: f("imme")
:B0X*C:wich:: f("which")
:B0X*C:yoru:: f("your")
:B0X:*more that:: f("more than")
:B0X:*more then:: f("more than")
:B0X:*moreso:: f("more so")
:B0X:*their has:: f("there has")
:B0X:*their have:: f("there have")
:B0X:;ils:: f("Intensive Learning Services (ILS)")
:B0X:EDB:: f("EBD")
:B0X:Parri:: f("Patti")
:B0X:a dominate:: f("a dominant")
:B0X:a lose:: f("a loss")
:B0X:a manufacture:: f("a manufacturer")
:B0X:a only a:: f("only a")
:B0X:a phenomena:: f("a phenomenon")
:B0X:a protozoa:: f("a protozoon")
:B0X:a renown:: f("a renowned")
:B0X:a strata:: f("a stratum")
:B0X:a taxa:: f("a taxon")
:B0X:adres:: f("address")
:B0X:affect on:: f("effect on")
:B0X:affects of:: f("effects of")
:B0X:agains:: f("against")
:B0X:against who:: f("against whom")
:B0X:agre:: f("agree")
:B0X:aircrafts':: f("aircraft's")
:B0X:aircrafts:: f("aircraft")
:B0X:all for not:: f("all for naught")
:B0X:alot:: f("a lot")
:B0X:also know as:: f("also known as")
:B0X:also know by:: f("also known by")
:B0X:also know for:: f("also known for")
:B0X:alway:: f("always")
:B0X:amin:: f("main")
:B0X:an affect:: f("an effect")
:B0X:andt he:: f("and the")
:B0X:anothe:: f("another")
:B0X:another criteria:: f("another criterion")
:B0X:another words:: f("in other words")
:B0X:apon:: f("upon")
:B0X:are dominate:: f("are dominant")
:B0X:are meet:: f("are met")
:B0X:are renown:: f("are renowned")
:B0X:are the dominate:: f("are the dominant")
:B0X:aslo:: f("also")
:B0X:atmospher:: f("atmosphere")
:B0X:averag:: f("average")
:B0X:be ran:: f("be run")
:B0X:be rode:: f("be ridden")
:B0X:be send:: f("be sent")
:B0X:became know:: f("became known")
:B0X:becames:: f("became")
:B0X:becaus:: f("because")
:B0X:been know:: f("been known")
:B0X:been ran:: f("been run")
:B0X:been rode:: f("been ridden")
:B0X:been send:: f("been sent")
:B0X:beggin:: f("begin")
:B0X:being ran:: f("being run")
:B0X:being rode:: f("being ridden")
:B0X:bicep:: f("biceps")
:B0X:both of who:: f("both of whom")
:B0X:cafe:: f("café")
:B0X:cafes:: f("cafés")
:B0X:can breath:: f("can breathe")
:B0X:can't breath:: f("can't breathe")
:B0X:can't of:: f("can't have")
:B0X:cant:: f("can't")
:B0X:carcas:: f("carcass")
:B0X:certain extend:: f("certain extent")
:B0X:cliant:: f("client")
:B0X:colum:: f("column")
:B0X:could breath:: f("could breathe")
:B0X:couldn't breath:: f("couldn't breathe")
:B0X:daily regiment:: f("daily regimen")
:B0X:depending of:: f("depending on")
:B0X:depends of:: f("depends on")
:B0X:devels:: f("delves")
:B0X:dispell:: f("dispel")
:B0X:dispells:: f("dispels")
:B0X:do to:: f("due to")
:B0X:dolka:: f("folks")
:B0X:doub:: f("doubt")
:B0X:dum:: f("dumb")
:B0X:earlies:: f("earliest")
:B0X:eath:: f("each")
:B0X:ect:: f("etc")
:B0X:elast:: f("least")
:B0X:embarras:: f("embarrass")
:B0X:en mass:: f("en masse")
:B0X:excell:: f("excel")
:B0X:experienc:: f("experience")
:B0X:facia:: f("fascia")
:B0X:fo:: f("of")
:B0X:for he and:: f("for him and")
:B0X:fora:: f("for a")
:B0X:forbad:: f("forbade")
:B0X:fro:: f("for")
:B0X:frome:: f("from")
:B0X:fulfil:: f("fulfill")
:B0X:gae:: f("game")
:B0X:grat:: f("great")
:B0X:had awoke:: f("had awoken")
:B0X:had broke:: f("had broken")
:B0X:had chose:: f("had chosen")
:B0X:had fell:: f("had fallen")
:B0X:had forbad:: f("had forbidden")
:B0X:had forbade:: f("had forbidden")
:B0X:had know:: f("had known")
:B0X:had plead:: f("had pleaded")
:B0X:had ran:: f("had run")
:B0X:had rang:: f("had rung")
:B0X:had rode:: f("had ridden")
:B0X:had spoke:: f("had spoken")
:B0X:had swam:: f("had swum")
:B0X:had throve:: f("had thriven")
:B0X:had woke:: f("had woken")
:B0X:happend:: f("happened")
:B0X:happended:: f("happened")
:B0X:happenned:: f("happened")
:B0X:has arose:: f("has arisen")
:B0X:has awoke:: f("has awoken")
:B0X:has bore:: f("has borne")
:B0X:has broke:: f("has broken")
:B0X:has build:: f("has built")
:B0X:has chose:: f("has chosen")
:B0X:has drove:: f("has driven")
:B0X:has fell:: f("has fallen")
:B0X:has flew:: f("has flown")
:B0X:has forbad:: f("has forbidden")
:B0X:has forbade:: f("has forbidden")
:B0X:has plead:: f("has pleaded")
:B0X:has ran:: f("has run")
:B0X:has spoke:: f("has spoken")
:B0X:has swam:: f("has swum")
:B0X:has trod:: f("has trodden")
:B0X:has woke:: f("has woken")
:B0X:have ran:: f("have run")
:B0X:have swam:: f("have swum")
:B0X:having ran:: f("having run")
:B0X:having swam:: f("having swum")
:B0X:he plead:: f("he pleaded")
:B0X:hier:: f("heir")
:B0X:how ever:: f("however")
:B0X:howver:: f("however")
:B0X:humer:: f("humor")
:B0X:husban:: f("husband")
:B0X:hypocrit:: f("hypocrite")
:B0X:if is:: f("it is")
:B0X:if was:: f("it was")
:B0X:imagin:: f("imagine")
:B0X:internation:: f("international")
:B0X:is also know:: f("is also known")
:B0X:is consider:: f("is considered")
:B0X:is know:: f("is known")
:B0X:it self:: f("itself")
:B0X:japanes:: f("Japanese")
:B0X:larg:: f("large")
:B0X:lot's of:: f("lots of")
:B0X:maltesian:: f("Maltese")
:B0X:mear:: f("mere")
:B0X:might of:: f("might have")
:B0X:more resent:: f("more recent")
:B0X:most resent:: f("most recent")
:B0X:must of:: f("must have")
:B0X:mysef:: f("myself")
:B0X:mysefl:: f("myself")
:B0X:neither criteria:: f("neither criterion")
:B0X:neither phenomena:: f("neither phenomenon")
:B0X:nestin:: f("nesting")
:B0X:noth:: f("north")
:B0X:ocur:: f("occur")
:B0X:one criteria:: f("one criterion")
:B0X:one phenomena:: f("one phenomenon")
:B0X:opposit:: f("opposite")
:B0X:our of:: f("out of")
:B0X:per say:: f("per se")
:B0X:perhasp:: f("perhaps")
:B0X:perphas:: f("perhaps")
:B0X:personel:: f("personnel")
:B0X:poisin:: f("poison")
:B0X:protem:: f("pro tem")
:B0X:recal:: f("recall")
:B0X:rela:: f("real")
:B0X:republi:: f("republic")
:B0X:scientis:: f("scientist")
:B0X:sherif:: f("sheriff")
:B0X:should not of:: f("should not have")
:B0X:should of:: f("should have")
:B0X:show resent:: f("show recent")
:B0X:some how:: f("somehow")
:B0X:some one:: f("someone")
:B0X:sq mi:: f("mi²")
:B0X:t he:: f("the")
:B0X:tast:: f("taste")
:B0X:tath:: f("that")
:B0X:thanks@!:: f("thanks!")
:B0X:thanks@:: f("thanks!")
:B0X:the advise of:: f("the advice of")
:B0X:the dominate:: f("the dominant")
:B0X:the extend of:: f("the extent of")
:B0X:their is:: f("there is")
:B0X:there of:: f("thereof")
:B0X:theri:: f("their")
:B0X:they;l:: f("they'll")
:B0X:they;r:: f("they're")
:B0X:they;v:: f("they've")
:B0X:this lead to:: f("this led to")
:B0X:thr:: f("the")
:B0X:thru:: f("through")
:B0X:to bath:: f("to bathe")
:B0X:to be build:: f("to be built")
:B0X:to breath:: f("to breathe")
:B0X:to chose:: f("to choose")
:B0X:to cut of:: f("to cut off")
:B0X:to loath:: f("to loathe")
:B0X:to some extend:: f("to some extent")
:B0X:to try and:: f("to try to")
:B0X:tou:: f("you")
:B0X:troup:: f("troupe")
:B0X:was cable of:: f("was capable of")
:B0X:was establish:: f("was established")
:B0X:was extend:: f("was extended")
:B0X:was know:: f("was known")
:B0X:was ran:: f("was run")
:B0X:was rode:: f("was ridden")
:B0X:was the dominate:: f("was the dominant")
:B0X:was tore:: f("was torn")
:B0X:was wrote:: f("was written")
:B0X:were build:: f("were built")
:B0X:were ran:: f("were run")
:B0X:were rebuild:: f("were rebuilt")
:B0X:were rode:: f("were ridden")
:B0X:were spend:: f("were spent")
:B0X:were the dominate:: f("were the dominant")
:B0X:were tore:: f("were torn")
:B0X:were wrote:: f("were written")
:B0X:when ever:: f("whenever")
:B0X:where as:: f("whereas")
:B0X:whereas as:: f("whereas")
:B0X:will of:: f("will have")
:B0X:with in:: f("within")
:B0X:with on of:: f("with one of")
:B0X:with who:: f("with whom")
:B0X:witha:: f("with a")
:B0X:withing:: f("within")
:B0X:wonderfull:: f("wonderful")
:B0X:would of:: f("would have")
:B0X:your a:: f("you're a")
:B0X:your an:: f("you're an")
:B0X:your her:: f("you're her")
:B0X:your here:: f("you're here")
:B0X:your his:: f("you're his")
:B0X:your my:: f("you're my")
:B0X:your the:: f("you're the")
:B0X:youv'e:: f("you've")
:B0X:youve:: f("you've")
:B0X*?:0n0:: f("-n-")
:B0X*?:a;;:: f("all")
:B0X*?:aall:: f("all")
:B0X*?:abaptiv:: f("adaptiv")
:B0X*?:abberr:: f("aberr")
:B0X*?:abbout:: f("about")
:B0X*?:abck:: f("back")
:B0X*?:abilt:: f("abilit")
:B0X*?:ablit:: f("abilit")
:B0X*?:abrit:: f("arbit")
:B0X*?:abuda:: f("abunda")
:B0X*?:acadm:: f("academ")
:B0X*?:accadem:: f("academ")
:B0X*?:acccus:: f("accus")
:B0X*?:acceller:: f("acceler")
:B0X*?:accensi:: f("ascensi")
:B0X*?:acceptib:: f("acceptab")
:B0X*?:accessab:: f("accessib")
:B0X*?:accomadat:: f("accommodat")
:B0X*?:accomo:: f("accommo")
:B0X*?:accoring:: f("according")
:B0X*?:accous:: f("acous")
:B0X*?:accqu:: f("acqu")
:B0X*?:accro:: f("acro")
:B0X*?:accuss:: f("accus")
:B0X*?:acede:: f("acade")
:B0X*?:acocu:: f("accou")
:B0X*?:acom:: f("accom")
:B0X*?:acquaintence:: f("acquaintance")
:B0X*?:acquiantence:: f("acquaintance")
:B0X*?:actial:: f("actical")
:B0X*?:acurac:: f("accurac")
:B0X*?:acustom:: f("accustom")
:B0X*?:acys:: f("acies")
:B0X*?:adantag:: f("advantag")
:B0X*?:adaption:: f("adaptation")
:B0X*?:adavan:: f("advan")
:B0X*?:addion:: f("addition")
:B0X*?:additon:: f("addition")
:B0X*?:addm:: f("adm")
:B0X*?:addop:: f("adop")
:B0X*?:addow:: f("adow")
:B0X*?:adequite:: f("adequate")
:B0X*?:adif:: f("atif")
:B0X*?:adiquate:: f("adequate")
:B0X*?:admend:: f("amend")
:B0X*?:admissab:: f("admissib")
:B0X*?:admited:: f("admitted")
:B0X*?:adquate:: f("adequate")
:B0X*?:adquir:: f("acquir")
:B0X*?:advanag:: f("advantag")
:B0X*?:adventr:: f("adventur")
:B0X*?:advertant:: f("advertent")
:B0X*?:adviced:: f("advised")
:B0X*?:aelog:: f("aeolog")
:B0X*?:aeriel:: f("aerial")
:B0X*?:affilat:: f("affiliat")
:B0X*?:affilliat:: f("affiliat")
:B0X*?:affort:: f("afford")
:B0X*?:affraid:: f("afraid")
:B0X*?:aggree:: f("agree")
:B0X*?:agrava:: f("aggrava")
:B0X*?:agreg:: f("aggreg")
:B0X*?:agress:: f("aggress")
:B0X*?:ahev:: f("have")
:B0X*?:ahpp:: f("happ")
:B0X*?:ahve:: f("have")
:B0X*?:aible:: f("able")
:B0X*?:aicraft:: f("aircraft")
:B0X*?:ailabe:: f("ailable")
:B0X*?:ailiab:: f("ailab")
:B0X*?:ailib:: f("ailab")
:B0X*?:ainity:: f("ainty")
:B0X*?:aisian:: f("Asian")
:B0X*?:aiton:: f("ation")
:B0X*?:alchohol:: f("alcohol")
:B0X*?:alchol:: f("alcohol")
:B0X*?:alcohal:: f("alcohol")
:B0X*?:alell:: f("allel")
:B0X*?:aliab:: f("ailab")
:B0X*?:alibit:: f("abilit")
:B0X*?:alitv:: f("lativ")
:B0X*?:allth:: f("alth")
:B0X*?:allto:: f("alto")
:B0X*?:alochol:: f("alcohol")
:B0X*?:alott:: f("allott")
:B0X*?:alowe:: f("allowe")
:B0X*?:alsitic:: f("alistic")
:B0X*?:altion:: f("lation")
:B0X*?:ameria:: f("America")
:B0X*?:amerli:: f("ameli")
:B0X*?:ametal:: f("amental")
:B0X*?:aminter:: f("aminer")
:B0X*?:amke:: f("make")
:B0X*?:amking:: f("making")
:B0X*?:ammou:: f("amou")
:B0X*?:amny:: f("many")
:B0X*?:analitic:: f("analytic")
:B0X*?:anbd:: f("and")
:B0X*?:angabl:: f("angeabl")
:B0X*?:angeing:: f("anging")
:B0X*?:anmd:: f("and")
:B0X*?:annn:: f("ann")
:B0X*?:annoi:: f("anoi")
:B0X*?:annuled:: f("annulled")
:B0X*?:anomo:: f("anoma")
:B0X*?:anounc:: f("announc")
:B0X*?:antaine:: f("antine")
:B0X*?:anwser:: f("answer")
:B0X*?:aost:: f("oast")
:B0X*?:aparen:: f("apparen")
:B0X*?:apear:: f("appear")
:B0X*?:aplic:: f("applic")
:B0X*?:aplie:: f("applie")
:B0X*?:apoint:: f("appoint")
:B0X*?:apparan:: f("apparen")
:B0X*?:appart:: f("apart")
:B0X*?:appeares:: f("appears")
:B0X*?:apperance:: f("appearance")
:B0X*?:appol:: f("apol")
:B0X*?:apprearance:: f("appearance")
:B0X*?:apreh:: f("appreh")
:B0X*?:apropri:: f("appropri")
:B0X*?:aprov:: f("approv")
:B0X*?:aptue:: f("apture")
:B0X*?:aquain:: f("acquain")
:B0X*?:aquiant:: f("acquaint")
:B0X*?:aquisi:: f("acquisi")
:B0X*?:arange:: f("arrange")
:B0X*?:arbitar:: f("arbitrar")
:B0X*?:archao:: f("archeo")
:B0X*?:archetect:: f("architect")
:B0X*?:architectual:: f("architectural")
:B0X*?:areat:: f("arat")
:B0X*?:arhip:: f("arship")
:B0X*?:ariage:: f("arriage")
:B0X*?:ariman:: f("airman")
:B0X*?:arogen:: f("arrogan")
:B0X*?:arrri:: f("arri")
:B0X*?:artdridge:: f("artridge")
:B0X*?:articel:: f("article")
:B0X*?:artrige:: f("artridge")
:B0X*?:asdver:: f("adver")
:B0X*?:asnd:: f("and")
:B0X*?:asociat:: f("associat")
:B0X*?:asorb:: f("absorb")
:B0X*?:asr:: f("ase")
:B0X*?:assempl:: f("assembl")
:B0X*?:assertation:: f("assertion")
:B0X*?:assoca:: f("associa")
:B0X*?:asss:: f("as")
:B0X*?:assym:: f("asym")
:B0X*?:asthet:: f("aesthet")
:B0X*?:asuing:: f("ausing")
:B0X*?:atain:: f("attain")
:B0X*?:ateing:: f("ating")
:B0X*?:atempt:: f("attempt")
:B0X*?:atention:: f("attention")
:B0X*?:athori:: f("authori")
:B0X*?:aticula:: f("articula")
:B0X*?:atoin:: f("ation")
:B0X*?:atribut:: f("attribut")
:B0X*?:attachement:: f("attachment")
:B0X*?:attemt:: f("attempt")
:B0X*?:attenden:: f("attendan")
:B0X*?:attensi:: f("attenti")
:B0X*?:attentioin:: f("attention")
:B0X*?:auclar:: f("acular")
:B0X*?:audiance:: f("audience")
:B0X*?:auther:: f("author")
:B0X*?:authobiograph:: f("autobiograph")
:B0X*?:authror:: f("author")
:B0X*?:automonom:: f("autonom")
:B0X*?:avaialb:: f("availab")
:B0X*?:availb:: f("availab")
:B0X*?:avalab:: f("availab")
:B0X*?:avalib:: f("availab")
:B0X*?:aveing:: f("aving")
:B0X*?:avila:: f("availa")
:B0X*?:awess:: f("awless")
:B0X*?:babilat:: f("babilit")
:B0X*?:ballan:: f("balan")
:B0X*?:baout:: f("about")
:B0X*?:bateabl:: f("batabl")
:B0X*?:bcak:: f("back")
:B0X*?:beahv:: f("behav")
:B0X*?:beatiful:: f("beautiful")
:B0X*?:beaurocra:: f("bureaucra")
:B0X*?:becoe:: f("become")
:B0X*?:becomm:: f("becom")
:B0X*?:bedore:: f("before")
:B0X*?:beei:: f("bei")
:B0X*?:behaio:: f("behavio")
:B0X*?:belan:: f("blan")
:B0X*?:belei:: f("belie")
:B0X*?:belligeran:: f("belligeren")
:B0X*?:benif:: f("benef")
:B0X*?:bilsh:: f("blish")
:B0X*?:biul:: f("buil")
:B0X*?:blence:: f("blance")
:B0X*?:bliah:: f("blish")
:B0X*?:blich:: f("blish")
:B0X*?:blisg:: f("blish")
:B0X*?:bllish:: f("blish")
:B0X*?:boaut:: f("about")
:B0X*?:bombardement:: f("bombardment")
:B0X*?:bombarment:: f("bombardment")
:B0X*?:bondary:: f("boundary")
:B0X*?:borrom:: f("bottom")
:B0X*?:boundr:: f("boundar")
:B0X*?:bouth:: f("bout")
:B0X*?:boxs:: f("boxes")
:B0X*?:bradcast:: f("broadcast")
:B0X*?:breif:: f("brief")
:B0X*?:brenc:: f("branc")
:B0X*?:broadacast:: f("broadcast")
:B0X*?:brod:: f("broad")
:B0X*?:buisn:: f("busin")
:B0X*?:buring:: f("burying")
:B0X*?:burrie:: f("burie")
:B0X*?:busness:: f("business")
:B0X*?:bussiness:: f("business")
:B0X*?:caculater:: f("calculator")
:B0X*?:caffin:: f("caffein")
:B0X*?:caharcter:: f("character")
:B0X*?:cahrac:: f("charac")
:B0X*?:calculater:: f("calculator")
:B0X*?:calculla:: f("calcula")
:B0X*?:calculs:: f("calculus")
:B0X*?:caluclat:: f("calculat")
:B0X*?:caluculat:: f("calculat")
:B0X*?:calulat:: f("calculat")
:B0X*?:camae:: f("came")
:B0X*?:campagin:: f("campaign")
:B0X*?:campain:: f("campaign")
:B0X*?:candad:: f("candid")
:B0X*?:candiat:: f("candidat")
:B0X*?:candidta:: f("candidat")
:B0X*?:cannonic:: f("canonic")
:B0X*?:caperbi:: f("capabi")
:B0X*?:capibl:: f("capabl")
:B0X*?:captia:: f("capita")
:B0X*?:caracht:: f("charact")
:B0X*?:caract:: f("charact")
:B0X*?:carcirat:: f("carcerat")
:B0X*?:carism:: f("charism")
:B0X*?:cartileg:: f("cartilag")
:B0X*?:cartilidg:: f("cartilag")
:B0X*?:casette:: f("cassette")
:B0X*?:casue:: f("cause")
:B0X*?:catagor:: f("categor")
:B0X*?:catergor:: f("categor")
:B0X*?:cathlic:: f("catholic")
:B0X*?:catholoc:: f("catholic")
:B0X*?:catre:: f("cater")
:B0X*?:ccce:: f("cce")
:B0X*?:ccesi:: f("ccessi")
:B0X*?:ceiev:: f("ceiv")
:B0X*?:ceing:: f("cing")
:B0X*?:cencu:: f("censu")
:B0X*?:centente:: f("centen")
:B0X*?:cerimo:: f("ceremo")
:B0X*?:ceromo:: f("ceremo")
:B0X*?:certian:: f("certain")
:B0X*?:cesion:: f("cession")
:B0X*?:cesor:: f("cessor")
:B0X*?:cesser:: f("cessor")
:B0X*?:cev:: f("ceiv")
:B0X*?:chagne:: f("change")
:B0X*?:chaleng:: f("challeng")
:B0X*?:challang:: f("challeng")
:B0X*?:challengabl:: f("challengeabl")
:B0X*?:changab:: f("changeab")
:B0X*?:charasma:: f("charisma")
:B0X*?:charater:: f("character")
:B0X*?:charector:: f("character")
:B0X*?:chargab:: f("chargeab")
:B0X*?:chartiab:: f("charitab")
:B0X*?:cheif:: f("chief")
:B0X*?:chemcial:: f("chemical")
:B0X*?:chemestr:: f("chemistr")
:B0X*?:chict:: f("chit")
:B0X*?:childen:: f("children")
:B0X*?:chracter:: f("character")
:B0X*?:chter:: f("cter")
:B0X*?:cidan:: f("ciden")
:B0X*?:ciencio:: f("cientio")
:B0X*?:ciepen:: f("cipien")
:B0X*?:ciev:: f("ceiv")
:B0X*?:cigic:: f("cific")
:B0X*?:cilation:: f("ciliation")
:B0X*?:cilliar:: f("cillar")
:B0X*?:circut:: f("circuit")
:B0X*?:ciricu:: f("circu")
:B0X*?:cirp:: f("crip")
:B0X*?:cison:: f("cision")
:B0X*?:citment:: f("citement")
:B0X*?:civilli:: f("civili")
:B0X*?:clae:: f("clea")
:B0X*?:clasic:: f("classic")
:B0X*?:clincial:: f("clinical")
:B0X*?:clomation:: f("clamation")
:B0X*?:cment:: f("cement")
:B0X*?:cmo:: f("com")
:B0X*?:cna:: f("can")
:B0X*?:coform:: f("conform")
:B0X*?:cogis:: f("cognis")
:B0X*?:cogiz:: f("cogniz")
:B0X*?:cogntivie:: f("cognitive")
:B0X*?:colaborat:: f("collaborat")
:B0X*?:colecti:: f("collecti")
:B0X*?:colelct:: f("collect")
:B0X*?:collon:: f("colon")
:B0X*?:comanie:: f("companie")
:B0X*?:comany:: f("company")
:B0X*?:comapan:: f("compan")
:B0X*?:comapn:: f("compan")
:B0X*?:comban:: f("combin")
:B0X*?:combatent:: f("combatant")
:B0X*?:combinatin:: f("combination")
:B0X*?:combon:: f("combin")
:B0X*?:combusi:: f("combusti")
:B0X*?:comemorat:: f("commemorat")
:B0X*?:comiss:: f("commiss")
:B0X*?:comitt:: f("committ")
:B0X*?:commed:: f("comed")
:B0X*?:commerical:: f("commercial")
:B0X*?:commericial:: f("commercial")
:B0X*?:commini:: f("communi")
:B0X*?:commite:: f("committe")
:B0X*?:commongly:: f("commonly")
:B0X*?:commuica:: f("communica")
:B0X*?:commuinica:: f("communica")
:B0X*?:communcia:: f("communica")
:B0X*?:communia:: f("communica")
:B0X*?:compatiab:: f("compatib")
:B0X*?:compeit:: f("competit")
:B0X*?:compenc:: f("compens")
:B0X*?:competan:: f("competen")
:B0X*?:competati:: f("competiti")
:B0X*?:competens:: f("competenc")
:B0X*?:comphr:: f("compr")
:B0X*?:compleate:: f("complete")
:B0X*?:compleatness:: f("completeness")
:B0X*?:comprab:: f("comparab")
:B0X*?:comprimis:: f("compromis")
:B0X*?:comun:: f("commun")
:B0X*?:concider:: f("consider")
:B0X*?:concious:: f("conscious")
:B0X*?:condidt:: f("condit")
:B0X*?:conect:: f("connect")
:B0X*?:conferanc:: f("conferenc")
:B0X*?:configurea:: f("configura")
:B0X*?:confort:: f("comfort")
:B0X*?:conqur:: f("conquer")
:B0X*?:conscen:: f("consen")
:B0X*?:consectu:: f("consecu")
:B0X*?:consentr:: f("concentr")
:B0X*?:consept:: f("concept")
:B0X*?:conservit:: f("conservat")
:B0X*?:consici:: f("consci")
:B0X*?:consico:: f("conscio")
:B0X*?:considerd:: f("considered")
:B0X*?:considerit:: f("considerat")
:B0X*?:consio:: f("conscio")
:B0X*?:constain:: f("constrain")
:B0X*?:constin:: f("contin")
:B0X*?:consumate:: f("consummate")
:B0X*?:consumbe:: f("consume")
:B0X*?:contian:: f("contain")
:B0X*?:contien:: f("conscien")
:B0X*?:contigen:: f("contingen")
:B0X*?:contined:: f("continued")
:B0X*?:continential:: f("continental")
:B0X*?:continetal:: f("continental")
:B0X*?:contino:: f("continuo")
:B0X*?:contitut:: f("constitut")
:B0X*?:contravers:: f("controvers")
:B0X*?:contributer:: f("contributor")
:B0X*?:controle:: f("controlle")
:B0X*?:controveri:: f("controversi")
:B0X*?:controversal:: f("controversial")
:B0X*?:controvertial:: f("controversial")
:B0X*?:contru:: f("constru")
:B0X*?:convenant:: f("covenant")
:B0X*?:convential:: f("conventional")
:B0X*?:convice:: f("convince")
:B0X*?:coopor:: f("cooper")
:B0X*?:coorper:: f("cooper")
:B0X*?:copm:: f("comp")
:B0X*?:copty:: f("copy")
:B0X*?:coput:: f("comput")
:B0X*?:copywrite:: f("copyright")
:B0X*?:coropor:: f("corpor")
:B0X*?:corpar:: f("corpor")
:B0X*?:corpera:: f("corpora")
:B0X*?:corporta:: f("corporat")
:B0X*?:corprat:: f("corporat")
:B0X*?:corpro:: f("corpor")
:B0X*?:corrispond:: f("correspond")
:B0X*?:costit:: f("constit")
:B0X*?:cotten:: f("cotton")
:B0X*?:countain:: f("contain")
:B0X*?:couraing:: f("couraging")
:B0X*?:couro:: f("coro")
:B0X*?:courur:: f("cour")
:B0X*?:cpom:: f("com")
:B0X*?:cpoy:: f("copy")
:B0X*?:creaet:: f("creat")
:B0X*?:credia:: f("credita")
:B0X*?:credida:: f("credita")
:B0X*?:criib:: f("crib")
:B0X*?:crti:: f("criti")
:B0X*?:crusie:: f("cruise")
:B0X*?:crutia:: f("crucia")
:B0X*?:crystalisa:: f("crystallisa")
:B0X*?:ctaegor:: f("categor")
:B0X*?:ctail:: f("cktail")
:B0X*?:ctent:: f("ctant")
:B0X*?:ctinos:: f("ctions")
:B0X*?:ctoin:: f("ction")
:B0X*?:cualr:: f("cular")
:B0X*?:cuas:: f("caus")
:B0X*?:cultral:: f("cultural")
:B0X*?:cultue:: f("culture")
:B0X*?:culure:: f("culture")
:B0X*?:curcuit:: f("circuit")
:B0X*?:cusotm:: f("custom")
:B0X*?:cutsom:: f("custom")
:B0X*?:cuture:: f("culture")
:B0X*?:cxan:: f("can")
:B0X*?:damenor:: f("demeanor")
:B0X*?:damenour:: f("demeanour")
:B0X*?:dammag:: f("damag")
:B0X*?:damy:: f("demy")
:B0X*?:daugher:: f("daughter")
:B0X*?:dcument:: f("document")
:B0X*?:ddti:: f("dditi")
:B0X*?:deatil:: f("detail")
:B0X*?:decend:: f("descend")
:B0X*?:decideab:: f("decidab")
:B0X*?:decrib:: f("describ")
:B0X*?:dectect:: f("detect")
:B0X*?:defendent:: f("defendant")
:B0X*?:deffens:: f("defens")
:B0X*?:deffin:: f("defin")
:B0X*?:defintion:: f("definition")
:B0X*?:degrat:: f("degrad")
:B0X*?:deinc:: f("dienc")
:B0X*?:delag:: f("deleg")
:B0X*?:delevop:: f("develop")
:B0X*?:demeno:: f("demeano")
:B0X*?:demmin:: f("demin")
:B0X*?:demorcr:: f("democr")
:B0X*?:denegrat:: f("denigrat")
:B0X*?:denpen:: f("depen")
:B0X*?:dentational:: f("dental")
:B0X*?:depedant:: f("dependent")
:B0X*?:depeden:: f("dependen")
:B0X*?:dependan:: f("dependen")
:B0X*?:deptart:: f("depart")
:B0X*?:deram:: f("dream")
:B0X*?:deriviate:: f("derive")
:B0X*?:derivit:: f("derivat")
:B0X*?:descib:: f("describ")
:B0X*?:descision:: f("decision")
:B0X*?:descus:: f("discus")
:B0X*?:desided:: f("decided")
:B0X*?:desinat:: f("destinat")
:B0X*?:desireab:: f("desirab")
:B0X*?:desision:: f("decision")
:B0X*?:desitn:: f("destin")
:B0X*?:despatch:: f("dispatch")
:B0X*?:despensib:: f("dispensab")
:B0X*?:despict:: f("depict")
:B0X*?:despira:: f("despera")
:B0X*?:destory:: f("destroy")
:B0X*?:detecab:: f("detectab")
:B0X*?:develeopr:: f("developer")
:B0X*?:devellop:: f("develop")
:B0X*?:developor:: f("developer")
:B0X*?:developpe:: f("develope")
:B0X*?:develp:: f("develop")
:B0X*?:devid:: f("divid")
:B0X*?:devolop:: f("develop")
:B0X*?:dgeing:: f("dging")
:B0X*?:dgement:: f("dgment")
:B0X*?:diapl:: f("displ")
:B0X*?:diarhe:: f("diarrhoe")
:B0X*?:dicatb:: f("dictab")
:B0X*?:diciplin:: f("disciplin")
:B0X*?:dicover:: f("discover")
:B0X*?:dicus:: f("discus")
:B0X*?:difef:: f("diffe")
:B0X*?:diferre:: f("differe")
:B0X*?:differan:: f("differen")
:B0X*?:diffren:: f("differen")
:B0X*?:dimenion:: f("dimension")
:B0X*?:dimention:: f("dimension")
:B0X*?:dimesnion:: f("dimension")
:B0X*?:diosese:: f("diocese")
:B0X*?:dipend:: f("depend")
:B0X*?:diriv:: f("deriv")
:B0X*?:discrib:: f("describ")
:B0X*?:disipl:: f("discipl")
:B0X*?:disolved:: f("dissolved")
:B0X*?:dispaly:: f("display")
:B0X*?:dispenc:: f("dispens")
:B0X*?:dispensib:: f("dispensab")
:B0X*?:disrict:: f("district")
:B0X*?:distruct:: f("destruct")
:B0X*?:ditonal:: f("ditional")
:B0X*?:ditribut:: f("distribut")
:B0X*?:divice:: f("device")
:B0X*?:divsi:: f("divisi")
:B0X*?:dmant:: f("dment")
:B0X*?:dminst:: f("dminist")
:B0X*?:doccu:: f("docu")
:B0X*?:doctin:: f("doctrin")
:B0X*?:docuement:: f("document")
:B0X*?:doind:: f("doing")
:B0X*?:dolan:: f("dolen")
:B0X*?:doller:: f("dollar")
:B0X*?:dominent:: f("dominant")
:B0X*?:dowloads:: f("download")
:B0X*?:dpend:: f("depend")
:B0X*?:dramtic:: f("dramatic")
:B0X*?:driect:: f("direct")
:B0X*?:drnik:: f("drink")
:B0X*?:dulgue:: f("dulge")
:B0X*?:dupicat:: f("duplicat")
:B0X*?:durig:: f("during")
:B0X*?:durring:: f("during")
:B0X*?:duting:: f("during")
:B0X*?:eacll:: f("ecall")
:B0X*?:eanr:: f("earn")
:B0X*?:eaolog:: f("eolog")
:B0X*?:eareance:: f("earance")
:B0X*?:earence:: f("earance")
:B0X*?:easen:: f("easan")
:B0X*?:ecco:: f("eco")
:B0X*?:eccu:: f("ecu")
:B0X*?:eceed:: f("ecede")
:B0X*?:eceonom:: f("econom")
:B0X*?:ecepi:: f("ecipi")
:B0X*?:ecuat:: f("equat")
:B0X*?:ecyl:: f("ecycl")
:B0X*?:edabl:: f("edibl")
:B0X*?:eearl:: f("earl")
:B0X*?:eeen:: f("een")
:B0X*?:eeep:: f("eep")
:B0X*?:eferan:: f("eferen")
:B0X*?:efered:: f("eferred")
:B0X*?:efering:: f("eferring")
:B0X*?:efern:: f("eferen")
:B0X*?:effecien:: f("efficien")
:B0X*?:egth:: f("ength")
:B0X*?:ehter:: f("ether")
:B0X*?:eild:: f("ield")
:B0X*?:elavan:: f("elevan")
:B0X*?:elction:: f("election")
:B0X*?:electic:: f("electric")
:B0X*?:electrial:: f("electrical")
:B0X*?:elemin:: f("elimin")
:B0X*?:eletric:: f("electric")
:B0X*?:elien:: f("elian")
:B0X*?:eligab:: f("eligib")
:B0X*?:eligo:: f("eligio")
:B0X*?:eliment:: f("element")
:B0X*?:ellected:: f("elected")
:B0X*?:elyhood:: f("elihood")
:B0X*?:embarass:: f("embarrass")
:B0X*?:emce:: f("ence")
:B0X*?:emiting:: f("emitting")
:B0X*?:emmediate:: f("immediate")
:B0X*?:emmigr:: f("emigr")
:B0X*?:emmis:: f("emis")
:B0X*?:emmit:: f("emitt")
:B0X*?:emnt:: f("ment")
:B0X*?:emostr:: f("emonstr")
:B0X*?:empahs:: f("emphas")
:B0X*?:emperic:: f("empiric")
:B0X*?:emphais:: f("emphasis")
:B0X*?:emphsis:: f("emphasis")
:B0X*?:emprison:: f("imprison")
:B0X*?:enchang:: f("enchant")
:B0X*?:encial:: f("ential")
:B0X*?:endand:: f("endant")
:B0X*?:endig:: f("ending")
:B0X*?:enduc:: f("induc")
:B0X*?:enece:: f("ence")
:B0X*?:enence:: f("enance")
:B0X*?:enflam:: f("inflam")
:B0X*?:engagment:: f("engagement")
:B0X*?:engeneer:: f("engineer")
:B0X*?:engieneer:: f("engineer")
:B0X*?:engten:: f("engthen")
:B0X*?:entagl:: f("entangl")
:B0X*?:entaly:: f("entally")
:B0X*?:entatr:: f("entar")
:B0X*?:entce:: f("ence")
:B0X*?:entgh:: f("ength")
:B0X*?:enthusiatic:: f("enthusiastic")
:B0X*?:entiatiation:: f("entiation")
:B0X*?:entily:: f("ently")
:B0X*?:envolu:: f("evolu")
:B0X*?:enxt:: f("next")
:B0X*?:eperat:: f("eparat")
:B0X*?:equalibr:: f("equilibr")
:B0X*?:equelibr:: f("equilibr")
:B0X*?:equialent:: f("equivalent")
:B0X*?:equilibium:: f("equilibrium")
:B0X*?:equilibrum:: f("equilibrium")
:B0X*?:equivilant:: f("equivalent")
:B0X*?:equivilent:: f("equivalent")
:B0X*?:erchen:: f("erchan")
:B0X*?:ereance:: f("earance")
:B0X*?:eremt:: f("erent")
:B0X*?:ernece:: f("erence")
:B0X*?:ernt:: f("erent")
:B0X*?:erruped:: f("errupted")
:B0X*?:esab:: f("essab")
:B0X*?:esential:: f("essential")
:B0X*?:esisten:: f("esistan")
:B0X*?:esitmat:: f("estimat")
:B0X*?:esnt:: f("esent")
:B0X*?:essense:: f("essence")
:B0X*?:essentail:: f("essential")
:B0X*?:essentual:: f("essential")
:B0X*?:estabish:: f("establish")
:B0X*?:esxual:: f("sexual")
:B0X*?:etanc:: f("etenc")
:B0X*?:etead:: f("eated")
:B0X*?:ethime:: f("etime")
:B0X*?:exagerat:: f("exaggerat")
:B0X*?:exagerrat:: f("exaggerat")
:B0X*?:exampt:: f("exempt")
:B0X*?:exapan:: f("expan")
:B0X*?:excact:: f("exact")
:B0X*?:excang:: f("exchang")
:B0X*?:excecut:: f("execut")
:B0X*?:excedd:: f("exceed")
:B0X*?:excercis:: f("exercis")
:B0X*?:exchanch:: f("exchang")
:B0X*?:excist:: f("exist")
:B0X*?:execis:: f("exercis")
:B0X*?:exeed:: f("exceed")
:B0X*?:exept:: f("except")
:B0X*?:exersize:: f("exercise")
:B0X*?:exict:: f("excit")
:B0X*?:exinct:: f("extinct")
:B0X*?:exisit:: f("exist")
:B0X*?:existan:: f("existen")
:B0X*?:exlile:: f("exile")
:B0X*?:exmapl:: f("exampl")
:B0X*?:expalin:: f("explain")
:B0X*?:expeced:: f("expected")
:B0X*?:expecial:: f("especial")
:B0X*?:experianc:: f("experienc")
:B0X*?:expidi:: f("expedi")
:B0X*?:expierenc:: f("experienc")
:B0X*?:expirien:: f("experien")
:B0X*?:explanit:: f("explanat")
:B0X*?:explict:: f("explicit")
:B0X*?:exploitit:: f("exploitat")
:B0X*?:explotat:: f("exploitat")
:B0X*?:exprienc:: f("experienc")
:B0X*?:exressed:: f("expressed")
:B0X*?:exsis:: f("exis")
:B0X*?:extention:: f("extension")
:B0X*?:extint:: f("extinct")
:B0X*?:facist:: f("fascist")
:B0X*?:fagia:: f("phagia")
:B0X*?:falab:: f("fallib")
:B0X*?:fallab:: f("fallib")
:B0X*?:familar:: f("familiar")
:B0X*?:familli:: f("famili")
:B0X*?:fammi:: f("fami")
:B0X*?:fascit:: f("facet")
:B0X*?:fasia:: f("phasia")
:B0X*?:fatc:: f("fact")
:B0X*?:fature:: f("facture")
:B0X*?:faught:: f("fought")
:B0X*?:feasable:: f("feasible")
:B0X*?:fedre:: f("feder")
:B0X*?:femmi:: f("femi")
:B0X*?:fencive:: f("fensive")
:B0X*?:ferec:: f("ferenc")
:B0X*?:feriang:: f("ferring")
:B0X*?:ferren:: f("feren")
:B0X*?:fertily:: f("fertility")
:B0X*?:fesion:: f("fession")
:B0X*?:fesser:: f("fessor")
:B0X*?:festion:: f("festation")
:B0X*?:ffese:: f("fesse")
:B0X*?:fficen:: f("fficien")
:B0X*?:fianit:: f("finit")
:B0X*?:fictious:: f("fictitious")
:B0X*?:fidn:: f("find")
:B0X*?:fiet:: f("feit")
:B0X*?:filiament:: f("filament")
:B0X*?:filitrat:: f("filtrat")
:B0X*?:fimil:: f("famil")
:B0X*?:finac:: f("financ")
:B0X*?:finat:: f("finit")
:B0X*?:finet:: f("finit")
:B0X*?:finining:: f("fining")
:B0X*?:firc:: f("furc")
:B0X*?:firend:: f("friend")
:B0X*?:firmm:: f("firm")
:B0X*?:fisi:: f("fissi")
:B0X*?:flama:: f("flamma")
:B0X*?:flourid:: f("fluorid")
:B0X*?:flourin:: f("fluorin")
:B0X*?:fluan:: f("fluen")
:B0X*?:fluorish:: f("flourish")
:B0X*?:focuss:: f("focus")
:B0X*?:foer:: f("fore")
:B0X*?:follwo:: f("follow")
:B0X*?:folow:: f("follow")
:B0X*?:fomat:: f("format")
:B0X*?:fomed:: f("formed")
:B0X*?:fomr:: f("form")
:B0X*?:foneti:: f("phoneti")
:B0X*?:fontrier:: f("frontier")
:B0X*?:fooot:: f("foot")
:B0X*?:forbiden:: f("forbidden")
:B0X*?:foretun:: f("fortun")
:B0X*?:forgetab:: f("forgettab")
:B0X*?:forgiveabl:: f("forgivabl")
:B0X*?:formidible:: f("formidable")
:B0X*?:formost:: f("foremost")
:B0X*?:forsee:: f("foresee")
:B0X*?:forwrd:: f("forward")
:B0X*?:foucs:: f("focus")
:B0X*?:foudn:: f("found")
:B0X*?:fourti:: f("forti")
:B0X*?:fourtun:: f("fortun")
:B0X*?:foward:: f("forward")
:B0X*?:freind:: f("friend")
:B0X*?:frence:: f("ference")
:B0X*?:fromed:: f("formed")
:B0X*?:fromi:: f("formi")
:B0X*?:fucnt:: f("funct")
:B0X*?:fufill:: f("fulfill")
:B0X*?:fugure:: f("figure")
:B0X*?:fulen:: f("fluen")
:B0X*?:fullfill:: f("fulfill")
:B0X*?:furut:: f("furt")
:B0X*?:gallax:: f("galax")
:B0X*?:galvin:: f("galvan")
:B0X*?:ganaly:: f("ginally")
:B0X*?:ganera:: f("genera")
:B0X*?:garant:: f("guarant")
:B0X*?:garav:: f("grav")
:B0X*?:garnison:: f("garrison")
:B0X*?:gaurant:: f("guarant")
:B0X*?:gaurd:: f("guard")
:B0X*?:gemer:: f("gener")
:B0X*?:generatt:: f("generat")
:B0X*?:gestab:: f("gestib")
:B0X*?:giid:: f("good")
:B0X*?:glight:: f("flight")
:B0X*?:glph:: f("glyph")
:B0X*?:glua:: f("gula")
:B0X*?:gnficia:: f("gnifica")
:B0X*?:gnizen:: f("gnizan")
:B0X*?:godess:: f("goddess")
:B0X*?:gorund:: f("ground")
:B0X*?:gourp:: f("group")
:B0X*?:govement:: f("government")
:B0X*?:govenment:: f("government")
:B0X*?:govenrment:: f("government")
:B0X*?:govera:: f("governa")
:B0X*?:goverment:: f("government")
:B0X*?:govor:: f("govern")
:B0X*?:gradded:: f("graded")
:B0X*?:graffitti:: f("graffiti")
:B0X*?:grama:: f("gramma")
:B0X*?:grammma:: f("gramma")
:B0X*?:greatful:: f("grateful")
:B0X*?:gresion:: f("gression")
:B0X*?:gropu:: f("group")
:B0X*?:gruop:: f("group")
:B0X*?:grwo:: f("grow")
:B0X*?:gsit:: f("gist")
:B0X*?:gubl:: f("guabl")
:B0X*?:guement:: f("gument")
:B0X*?:guidence:: f("guidance")
:B0X*?:gurantee:: f("guarantee")
:B0X*?:habitans:: f("habitants")
:B0X*?:habition:: f("hibition")
:B0X*?:haneg:: f("hange")
:B0X*?:harased:: f("harassed")
:B0X*?:havour:: f("havior")
:B0X*?:hcange:: f("change")
:B0X*?:hcih:: f("hich")
:B0X*?:heirarch:: f("hierarch")
:B0X*?:heiroglyph:: f("hieroglyph")
:B0X*?:heiv:: f("hiev")
:B0X*?:herant:: f("herent")
:B0X*?:heridit:: f("heredit")
:B0X*?:hertia:: f("herita")
:B0X*?:hertzs:: f("hertz")
:B0X*?:hicial:: f("hical")
:B0X*?:hierach:: f("hierarch")
:B0X*?:hierarcic:: f("hierarchic")
:B0X*?:higway:: f("highway")
:B0X*?:hnag:: f("hang")
:B0X*?:holf:: f("hold")
:B0X*?:hospiti:: f("hospita")
:B0X*?:houno:: f("hono")
:B0X*?:hstor:: f("histor")
:B0X*?:humerous:: f("humorous")
:B0X*?:humur:: f("humour")
:B0X*?:hvae:: f("have")
:B0X*?:hvai:: f("havi")
:B0X*?:hvea:: f("have")
:B0X*?:hwere:: f("where")
:B0X*?:hydog:: f("hydrog")
:B0X*?:hymm:: f("hym")
:B0X*?:ibile:: f("ible")
:B0X*?:ibilt:: f("ibilit")
:B0X*?:iblit:: f("ibilit")
:B0X*?:icibl:: f("iceabl")
:B0X*?:iciton:: f("iction")
:B0X*?:idenital:: f("idential")
:B0X*?:iegh:: f("eigh")
:B0X*?:iegn:: f("eign")
:B0X*?:ievn:: f("iven")
:B0X*?:igeou:: f("igiou")
:B0X*?:igini:: f("igni")
:B0X*?:ignf:: f("ignif")
:B0X*?:igous:: f("igious")
:B0X*?:igth:: f("ight")
:B0X*?:ihs:: f("his")
:B0X*?:iht:: f("ith")
:B0X*?:ijng:: f("ing")
:B0X*?:ilair:: f("iliar")
:B0X*?:illution:: f("illusion")
:B0X*?:imagen:: f("imagin")
:B0X*?:immita:: f("imita")
:B0X*?:impliment:: f("implement")
:B0X*?:imploy:: f("employ")
:B0X*?:importen:: f("importan")
:B0X*?:imprion:: f("imprison")
:B0X*?:incede:: f("incide")
:B0X*?:incidential:: f("incidental")
:B0X*?:incra:: f("incre")
:B0X*?:inctro:: f("intro")
:B0X*?:indeca:: f("indica")
:B0X*?:indite:: f("indict")
:B0X*?:indutr:: f("industr")
:B0X*?:indvidua:: f("individua")
:B0X*?:inece:: f("ience")
:B0X*?:ineing:: f("ining")
:B0X*?:infectuo:: f("infectio")
:B0X*?:infrant:: f("infant")
:B0X*?:infrige:: f("infringe")
:B0X*?:ingenius:: f("ingenious")
:B0X*?:inheritage:: f("inheritance")
:B0X*?:inheritence:: f("inheritance")
:B0X*?:inially:: f("inally")
:B0X*?:ininis:: f("inis")
:B0X*?:inital:: f("initial")
:B0X*?:inng:: f("ing")
:B0X*?:innocula:: f("inocula")
:B0X*?:inpeach:: f("impeach")
:B0X*?:inpolit:: f("impolit")
:B0X*?:inprison:: f("imprison")
:B0X*?:inprov:: f("improv")
:B0X*?:institue:: f("institute")
:B0X*?:instu:: f("instru")
:B0X*?:intelect:: f("intellect")
:B0X*?:intelig:: f("intellig")
:B0X*?:intenational:: f("international")
:B0X*?:intented:: f("intended")
:B0X*?:intepret:: f("interpret")
:B0X*?:interational:: f("international")
:B0X*?:interferance:: f("interference")
:B0X*?:intergrat:: f("integrat")
:B0X*?:interpet:: f("interpret")
:B0X*?:interupt:: f("interrupt")
:B0X*?:inteven:: f("interven")
:B0X*?:intrduc:: f("introduc")
:B0X*?:intrest:: f("interest")
:B0X*?:intruduc:: f("introduc")
:B0X*?:intut:: f("intuit")
:B0X*?:inudstr:: f("industr")
:B0X*?:investingat:: f("investigat")
:B0X*?:iopn:: f("ion")
:B0X*?:iouness:: f("iousness")
:B0X*?:iousit:: f("iosit")
:B0X*?:irts:: f("irst")
:B0X*?:isherr:: f("isher")
:B0X*?:ishor:: f("isher")
:B0X*?:ishre:: f("isher")
:B0X*?:isile:: f("issile")
:B0X*?:issence:: f("issance")
:B0X*?:iticing:: f("iticising")
:B0X*?:itina:: f("itiona")
:B0X*?:ititia:: f("initia")
:B0X*?:itition:: f("ition")
:B0X*?:itnere:: f("intere")
:B0X*?:itnroduc:: f("introduc")
:B0X*?:itoin:: f("ition")
:B0X*?:itttle:: f("ittle")
:B0X*?:iveing:: f("iving")
:B0X*?:iverous:: f("ivorous")
:B0X*?:ivle:: f("ivel")
:B0X*?:iwll:: f("will")
:B0X*?:iwth:: f("with")
:B0X*?:jecutr:: f("jectur")
:B0X*?:jist:: f("gist")
:B0X*?:jstu:: f("just")
:B0X*?:jsut:: f("just")
:B0X*?:juct:: f("junct")
:B0X*?:judgment:: f("judgement")
:B0X*?:judical:: f("judicial")
:B0X*?:judisua:: f("judicia")
:B0X*?:juduci:: f("judici")
:B0X*?:jugment:: f("judgment")
:B0X*?:kindergarden:: f("kindergarten")
:B0X*?:knowldeg:: f("knowledg")
:B0X*?:knowldg:: f("knowledg")
:B0X*?:knowleg:: f("knowledg")
:B0X*?:knwo:: f("know")
:B0X*?:kwno:: f("know")
:B0X*?:labat:: f("laborat")
:B0X*?:laeg:: f("leag")
:B0X*?:laguage:: f("language")
:B0X*?:laimation:: f("lamation")
:B0X*?:laion:: f("lation")
:B0X*?:lalbe:: f("lable")
:B0X*?:laraty:: f("larity")
:B0X*?:lastes:: f("lates")
:B0X*?:lateab:: f("latab")
:B0X*?:latrea:: f("latera")
:B0X*?:lattitude:: f("latitude")
:B0X*?:launhe:: f("launche")
:B0X*?:lcud:: f("clud")
:B0X*?:leagur:: f("leaguer")
:B0X*?:leathal:: f("lethal")
:B0X*?:lece:: f("lesce")
:B0X*?:lecton:: f("lection")
:B0X*?:legitamat:: f("legitimat")
:B0X*?:legitm:: f("legitim")
:B0X*?:legue:: f("league")
:B0X*?:leiv:: f("liev")
:B0X*?:libgui:: f("lingui")
:B0X*?:liek:: f("like")
:B0X*?:liement:: f("lement")
:B0X*?:lieuenan:: f("lieutenan")
:B0X*?:lieutenen:: f("lieutenan")
:B0X*?:likl:: f("likel")
:B0X*?:lility:: f("ility")
:B0X*?:liscen:: f("licen")
:B0X*?:lisehr:: f("lisher")
:B0X*?:lisen:: f("licen")
:B0X*?:lisheed:: f("lished")
:B0X*?:lishh:: f("lish")
:B0X*?:lissh:: f("lish")
:B0X*?:listn:: f("listen")
:B0X*?:litav:: f("lativ")
:B0X*?:litert:: f("literat")
:B0X*?:littel:: f("little")
:B0X*?:litteral:: f("literal")
:B0X*?:littoe:: f("little")
:B0X*?:liuke:: f("like")
:B0X*?:llarious:: f("larious")
:B0X*?:llegen:: f("llegian")
:B0X*?:llegien:: f("llegian")
:B0X*?:lmits:: f("limits")
:B0X*?:loev:: f("love")
:B0X*?:lonle:: f("lonel")
:B0X*?:lpp:: f("lp")
:B0X*?:lsih:: f("lish")
:B0X*?:lsot:: f("lso")
:B0X*?:lutly:: f("lutely")
:B0X*?:lyed:: f("lied")
:B0X*?:machne:: f("machine")
:B0X*?:maintina:: f("maintain")
:B0X*?:maintion:: f("mention")
:B0X*?:majorot:: f("majorit")
:B0X*?:makeing:: f("making")
:B0X*?:making it's:: f("making its")
:B0X*?:makse:: f("makes")
:B0X*?:mallise:: f("malize")
:B0X*?:mallize:: f("malize")
:B0X*?:mamal:: f("mammal")
:B0X*?:mamant:: f("mament")
:B0X*?:managab:: f("manageab")
:B0X*?:managment:: f("management")
:B0X*?:mandito:: f("mandato")
:B0X*?:maneouv:: f("manoeuv")
:B0X*?:manoeuver:: f("maneuver")
:B0X*?:manouver:: f("maneuver")
:B0X*?:mantain:: f("maintain")
:B0X*?:manuever:: f("maneuver")
:B0X*?:manuver:: f("maneuver")
:B0X*?:marjorit:: f("majorit")
:B0X*?:markes:: f("marks")
:B0X*?:markett:: f("market")
:B0X*?:marrage:: f("marriage")
:B0X*?:mathamati:: f("mathemati")
:B0X*?:mathmati:: f("mathemati")
:B0X*?:mberan:: f("mbran")
:B0X*?:mbintat:: f("mbinat")
:B0X*?:mchan:: f("mechan")
:B0X*?:meber:: f("member")
:B0X*?:medac:: f("medic")
:B0X*?:medeival:: f("medieval")
:B0X*?:medevial:: f("medieval")
:B0X*?:meent:: f("ment")
:B0X*?:meing:: f("ming")
:B0X*?:melad:: f("malad")
:B0X*?:memmor:: f("memor")
:B0X*?:memt:: f("ment")
:B0X*?:menat:: f("menta")
:B0X*?:metalic:: f("metallic")
:B0X*?:metn:: f("ment")
:B0X*?:mialr:: f("milar")
:B0X*?:mibil:: f("mobil")
:B0X*?:mileau:: f("milieu")
:B0X*?:milen:: f("millen")
:B0X*?:mileu:: f("milieu")
:B0X*?:milirat:: f("militar")
:B0X*?:millit:: f("milit")
:B0X*?:millon:: f("million")
:B0X*?:milta:: f("milita")
:B0X*?:minatur:: f("miniatur")
:B0X*?:minining:: f("mining")
:B0X*?:miscelane:: f("miscellane")
:B0X*?:mision:: f("mission")
:B0X*?:missabi:: f("missibi")
:B0X*?:misson:: f("mission")
:B0X*?:mition:: f("mission")
:B0X*?:mittm:: f("mitm")
:B0X*?:mitty:: f("mittee")
:B0X*?:mkae:: f("make")
:B0X*?:mkaing:: f("making")
:B0X*?:mkea:: f("make")
:B0X*?:mnet:: f("ment")
:B0X*?:modle:: f("model")
:B0X*?:moent:: f("moment")
:B0X*?:moleclue:: f("molecule")
:B0X*?:morgag:: f("mortgag")
:B0X*?:mornal:: f("normal")
:B0X*?:morot:: f("motor")
:B0X*?:morow:: f("morrow")
:B0X*?:mortag:: f("mortgag")
:B0X*?:mostur:: f("moistur")
:B0X*?:moung:: f("mong")
:B0X*?:mounth:: f("month")
:B0X*?:mpossa:: f("mpossi")
:B0X*?:mrak:: f("mark")
:B0X*?:mroe:: f("more")
:B0X*?:msot:: f("most")
:B0X*?:mtion:: f("mation")
:B0X*?:mucuous:: f("mucous")
:B0X*?:muder:: f("murder")
:B0X*?:mulatat:: f("mulat")
:B0X*?:munber:: f("number")
:B0X*?:munites:: f("munities")
:B0X*?:muscel:: f("muscle")
:B0X*?:muscial:: f("musical")
:B0X*?:mutiliat:: f("mutilat")
:B0X*?:myu:: f("my")
:B0X*?:naisance:: f("naissance")
:B0X*?:natly:: f("nately")
:B0X*?:naton:: f("nation")
:B0X*?:naturely:: f("naturally")
:B0X*?:naturual:: f("natural")
:B0X*?:nclr:: f("ncr")
:B0X*?:ndunt:: f("ndant")
:B0X*?:necass:: f("necess")
:B0X*?:neccesar:: f("necessar")
:B0X*?:neccessar:: f("necessar")
:B0X*?:necesar:: f("necessar")
:B0X*?:nefica:: f("neficia")
:B0X*?:negociat:: f("negotiat")
:B0X*?:negota:: f("negotia")
:B0X*?:neice:: f("niece")
:B0X*?:neigbor:: f("neighbor")
:B0X*?:neigbour:: f("neighbor")
:B0X*?:neize:: f("nize")
:B0X*?:neolitic:: f("neolithic")
:B0X*?:nerial:: f("neral")
:B0X*?:neribl:: f("nerabl")
:B0X*?:nervious:: f("nervous")
:B0X*?:nessasar:: f("necessar")
:B0X*?:nessec:: f("necess")
:B0X*?:nght:: f("ngth")
:B0X*?:ngng:: f("nging")
:B0X*?:nht:: f("nth")
:B0X*?:niant:: f("nant")
:B0X*?:niare:: f("naire")
:B0X*?:nickle:: f("nickel")
:B0X*?:nifiga:: f("nifica")
:B0X*?:nihgt:: f("night")
:B0X*?:nilog:: f("nolog")
:B0X*?:nisator:: f("niser")
:B0X*?:nisb:: f("nsib")
:B0X*?:nistion:: f("nisation")
:B0X*?:nitian:: f("nician")
:B0X*?:niton:: f("nition")
:B0X*?:nizator:: f("nizer")
:B0X*?:niztion:: f("nization")
:B0X*?:nkow:: f("know")
:B0X*?:nlcu:: f("nclu")
:B0X*?:nlees:: f("nless")
:B0X*?:nmae:: f("name")
:B0X*?:nnst:: f("nst")
:B0X*?:nnung:: f("nning")
:B0X*?:nominclat:: f("nomenclat")
:B0X*?:nonom:: f("nonym")
:B0X*?:nouce:: f("nounce")
:B0X*?:nounch:: f("nounc")
:B0X*?:nouncia:: f("nuncia")
:B0X*?:nsern:: f("ncern")
:B0X*?:nsistan:: f("nsisten")
:B0X*?:nsitu:: f("nstitu")
:B0X*?:nsnet:: f("nsent")
:B0X*?:nstade:: f("nstead")
:B0X*?:nstatan:: f("nstan")
:B0X*?:nsted:: f("nstead")
:B0X*?:nstiv:: f("nsitiv")
:B0X*?:ntaines:: f("ntains")
:B0X*?:ntamp:: f("ntemp")
:B0X*?:ntfic:: f("ntific")
:B0X*?:ntifc:: f("ntific")
:B0X*?:ntrui:: f("nturi")
:B0X*?:nucular:: f("nuclear")
:B0X*?:nuculear:: f("nuclear")
:B0X*?:nuei:: f("nui")
:B0X*?:nuptual:: f("nuptial")
:B0X*?:nvien:: f("nven")
:B0X*?:obedian:: f("obedien")
:B0X*?:obelm:: f("oblem")
:B0X*?:occassi:: f("occasi")
:B0X*?:occasti:: f("occasi")
:B0X*?:occour:: f("occur")
:B0X*?:occuran:: f("occurren")
:B0X*?:occurran:: f("occurren")
:B0X*?:ocup:: f("occup")
:B0X*?:ocurran:: f("occurren")
:B0X*?:odouriferous:: f("odoriferous")
:B0X*?:odourous:: f("odorous")
:B0X*?:oducab:: f("oducib")
:B0X*?:oeny:: f("oney")
:B0X*?:oeopl:: f("eopl")
:B0X*?:oeprat:: f("operat")
:B0X*?:offesi:: f("ofessi")
:B0X*?:offical:: f("official")
:B0X*?:offred:: f("offered")
:B0X*?:ogeous:: f("ogous")
:B0X*?:ogess:: f("ogress")
:B0X*?:ohter:: f("other")
:B0X*?:ointiment:: f("ointment")
:B0X*?:olgist:: f("ologist")
:B0X*?:olision:: f("olition")
:B0X*?:ollum:: f("olum")
:B0X*?:olpe:: f("ople")
:B0X*?:olther:: f("other")
:B0X*?:omenom:: f("omenon")
:B0X*?:ommm:: f("omm")
:B0X*?:omnio:: f("omino")
:B0X*?:omptabl:: f("ompatibl")
:B0X*?:omre:: f("more")
:B0X*?:omse:: f("onse")
:B0X*?:ongraph:: f("onograph")
:B0X*?:onnal:: f("onal")
:B0X*?:ononent:: f("onent")
:B0X*?:ononym:: f("onym")
:B0X*?:onsenc:: f("onsens")
:B0X*?:ontruc:: f("onstruc")
:B0X*?:ontstr:: f("onstr")
:B0X*?:onvertab:: f("onvertib")
:B0X*?:onyic:: f("onic")
:B0X*?:onymn:: f("onym")
:B0X*?:oook:: f("ook")
:B0X*?:oparate:: f("operate")
:B0X*?:oportun:: f("opportun")
:B0X*?:opperat:: f("operat")
:B0X*?:oppertun:: f("opportun")
:B0X*?:oppini:: f("opini")
:B0X*?:opprotun:: f("opportun")
:B0X*?:opth:: f("ophth")
:B0X*?:ordianti:: f("ordinati")
:B0X*?:orginis:: f("organiz")
:B0X*?:orginiz:: f("organiz")
:B0X*?:orht:: f("orth")
:B0X*?:oridal:: f("ordial")
:B0X*?:oridina:: f("ordina")
:B0X*?:origion:: f("origin")
:B0X*?:ormenc:: f("ormanc")
:B0X*?:osible:: f("osable")
:B0X*?:oteab:: f("otab")
:B0X*?:ouevre:: f("oeuvre")
:B0X*?:ougnble:: f("ouble")
:B0X*?:ouhg:: f("ough")
:B0X*?:oulb:: f("oubl")
:B0X*?:ouldnt:: f("ouldn't")
:B0X*?:ountian:: f("ountain")
:B0X*?:ourious:: f("orious")
:B0X*?:owinf:: f("owing")
:B0X*?:owrk:: f("work")
:B0X*?:oxident:: f("oxidant")
:B0X*?:oxigen:: f("oxygen")
:B0X*?:paiti:: f("pati")
:B0X*?:palce:: f("place")
:B0X*?:paliament:: f("parliament")
:B0X*?:papaer:: f("paper")
:B0X*?:paralel:: f("parallel")
:B0X*?:parellel:: f("parallel")
:B0X*?:parision:: f("parison")
:B0X*?:parisit:: f("parasit")
:B0X*?:paritucla:: f("particula")
:B0X*?:parliment:: f("parliament")
:B0X*?:parment:: f("partment")
:B0X*?:parralel:: f("parallel")
:B0X*?:parrall:: f("parall")
:B0X*?:parren:: f("paren")
:B0X*?:pased:: f("passed")
:B0X*?:patab:: f("patib")
:B0X*?:pattent:: f("patent")
:B0X*?:pbli:: f("publi")
:B0X*?:pbuli:: f("publi")
:B0X*?:pcial:: f("pical")
:B0X*?:pcitur:: f("pictur")
:B0X*?:peall:: f("peal")
:B0X*?:peapl:: f("peopl")
:B0X*?:pefor:: f("perfor")
:B0X*?:peice:: f("piece")
:B0X*?:peiti:: f("petiti")
:B0X*?:pendece:: f("pendence")
:B0X*?:pendendet:: f("pendent")
:B0X*?:penerat:: f("penetrat")
:B0X*?:penisula:: f("peninsula")
:B0X*?:penninsula:: f("peninsula")
:B0X*?:pennisula:: f("peninsula")
:B0X*?:pensanti:: f("pensati")
:B0X*?:pensinula:: f("peninsula")
:B0X*?:penten:: f("pentan")
:B0X*?:pention:: f("pension")
:B0X*?:peopel:: f("people")
:B0X*?:percepted:: f("perceived")
:B0X*?:perfom:: f("perform")
:B0X*?:performes:: f("performs")
:B0X*?:permenan:: f("permanen")
:B0X*?:perminen:: f("permanen")
:B0X*?:permissab:: f("permissib")
:B0X*?:peronal:: f("personal")
:B0X*?:perosn:: f("person")
:B0X*?:persistan:: f("persisten")
:B0X*?:persud:: f("persuad")
:B0X*?:pertrat:: f("petrat")
:B0X*?:pertuba:: f("perturba")
:B0X*?:peteti:: f("petiti")
:B0X*?:petion:: f("petition")
:B0X*?:petive:: f("petitive")
:B0X*?:phenomenonal:: f("phenomenal")
:B0X*?:phenomon:: f("phenomen")
:B0X*?:phenonmen:: f("phenomen")
:B0X*?:philisoph:: f("philosoph")
:B0X*?:phillipi:: f("Philippi")
:B0X*?:phillo:: f("philo")
:B0X*?:philosph:: f("philosoph")
:B0X*?:phoricial:: f("phorical")
:B0X*?:phyllis:: f("philis")
:B0X*?:phylosoph:: f("philosoph")
:B0X*?:piant:: f("pient")
:B0X*?:piblish:: f("publish")
:B0X*?:pinon:: f("pion")
:B0X*?:piten:: f("peten")
:B0X*?:plament:: f("plement")
:B0X*?:plausab:: f("plausib")
:B0X*?:pld:: f("ple")
:B0X*?:plesan:: f("pleasan")
:B0X*?:pleseant:: f("pleasant")
:B0X*?:pletetion:: f("pletion")
:B0X*?:pmant:: f("pment")
:B0X*?:poenis:: f("penis")
:B0X*?:poepl:: f("peopl")
:B0X*?:poleg:: f("polog")
:B0X*?:polina:: f("pollina")
:B0X*?:politican:: f("politician")
:B0X*?:polti:: f("politi")
:B0X*?:polut:: f("pollut")
:B0X*?:pomd:: f("pond")
:B0X*?:ponan:: f("ponen")
:B0X*?:ponsab:: f("ponsib")
:B0X*?:poportion:: f("proportion")
:B0X*?:popoul:: f("popul")
:B0X*?:porblem:: f("problem")
:B0X*?:portad:: f("ported")
:B0X*?:porv:: f("prov")
:B0X*?:posat:: f("posit")
:B0X*?:posess:: f("possess")
:B0X*?:posion:: f("poison")
:B0X*?:possab:: f("possib")
:B0X*?:postion:: f("position")
:B0X*?:postit:: f("posit")
:B0X*?:postiv:: f("positiv")
:B0X*?:potunit:: f("portunit")
:B0X*?:poulat:: f("populat")
:B0X*?:poverful:: f("powerful")
:B0X*?:poweful:: f("powerful")
:B0X*?:ppment:: f("pment")
:B0X*?:pposs:: f("ppos")
:B0X*?:ppub:: f("pub")
:B0X*?:prait:: f("priat")
:B0X*?:pratic:: f("practic")
:B0X*?:precendent:: f("precedent")
:B0X*?:precic:: f("precis")
:B0X*?:precid:: f("preced")
:B0X*?:prega:: f("pregna")
:B0X*?:pregne:: f("pregna")
:B0X*?:preiod:: f("period")
:B0X*?:prelifer:: f("prolifer")
:B0X*?:prepair:: f("prepare")
:B0X*?:prerio:: f("perio")
:B0X*?:presan:: f("presen")
:B0X*?:presp:: f("persp")
:B0X*?:pretect:: f("protect")
:B0X*?:pricip:: f("princip")
:B0X*?:priestood:: f("priesthood")
:B0X*?:prisonn:: f("prison")
:B0X*?:privale:: f("privile")
:B0X*?:privele:: f("privile")
:B0X*?:privelig:: f("privileg")
:B0X*?:privelle:: f("privile")
:B0X*?:privilag:: f("privileg")
:B0X*?:priviledg:: f("privileg")
:B0X*?:probabli:: f("probabili")
:B0X*?:probal:: f("probabl")
:B0X*?:procce:: f("proce")
:B0X*?:proclame:: f("proclaime")
:B0X*?:proffession:: f("profession")
:B0X*?:progrom:: f("program")
:B0X*?:prohabit:: f("prohibit")
:B0X*?:prominan:: f("prominen")
:B0X*?:prominate:: f("prominent")
:B0X*?:promona:: f("promine")
:B0X*?:proov:: f("prov")
:B0X*?:propiet:: f("propriet")
:B0X*?:propmt:: f("prompt")
:B0X*?:propotion:: f("proportion")
:B0X*?:propper:: f("proper")
:B0X*?:propro:: f("pro")
:B0X*?:prorp:: f("propr")
:B0X*?:protie:: f("protei")
:B0X*?:protray:: f("portray")
:B0X*?:prounc:: f("pronounc")
:B0X*?:provd:: f("provid")
:B0X*?:provicial:: f("provincial")
:B0X*?:provinicial:: f("provincial")
:B0X*?:proxia:: f("proxima")
:B0X*?:psect:: f("spect")
:B0X*?:psoiti:: f("positi")
:B0X*?:psuedo:: f("pseudo")
:B0X*?:psyco:: f("psycho")
:B0X*?:psyh:: f("psych")
:B0X*?:ptenc:: f("ptanc")
:B0X*?:ptete:: f("pete")
:B0X*?:ptition:: f("petition")
:B0X*?:ptogress:: f("progress")
:B0X*?:ptoin:: f("ption")
:B0X*?:pturd:: f("ptured")
:B0X*?:pubish:: f("publish")
:B0X*?:publian:: f("publican")
:B0X*?:publise:: f("publishe")
:B0X*?:publush:: f("publish")
:B0X*?:pulare:: f("pular")
:B0X*?:puler:: f("pular")
:B0X*?:pulishe:: f("publishe")
:B0X*?:puplish:: f("publish")
:B0X*?:pursuad:: f("persuad")
:B0X*?:purtun:: f("portun")
:B0X*?:pususad:: f("persuad")
:B0X*?:putar:: f("puter")
:B0X*?:putib:: f("putab")
:B0X*?:pwoer:: f("power")
:B0X*?:pysch:: f("psych")
:B0X*?:qtuie:: f("quite")
:B0X*?:quesece:: f("quence")
:B0X*?:quesion:: f("question")
:B0X*?:questiom:: f("question")
:B0X*?:queston:: f("question")
:B0X*?:quetion:: f("question")
:B0X*?:quirment:: f("quirement")
:B0X*?:qush:: f("quish")
:B0X*?:quti:: f("quit")
:B0X*?:rabinn:: f("rabbin")
:B0X*?:radiactiv:: f("radioactiv")
:B0X*?:raell:: f("reall")
:B0X*?:rafic:: f("rific")
:B0X*?:ranie:: f("rannie")
:B0X*?:ratly:: f("rately")
:B0X*?:raverci:: f("roversi")
:B0X*?:rcaft:: f("rcraft")
:B0X*?:reaccurr:: f("recurr")
:B0X*?:reaci:: f("reachi")
:B0X*?:rebll:: f("rebell")
:B0X*?:recide:: f("reside")
:B0X*?:recomment:: f("recommend")
:B0X*?:recqu:: f("requ")
:B0X*?:recration:: f("recreation")
:B0X*?:recrod:: f("record")
:B0X*?:recter:: f("rector")
:B0X*?:recuring:: f("recurring")
:B0X*?:reedem:: f("redeem")
:B0X*?:reenfo:: f("reinfo")
:B0X*?:referal:: f("referral")
:B0X*?:reffer:: f("refer")
:B0X*?:refrer:: f("refer")
:B0X*?:reigin:: f("reign")
:B0X*?:reing:: f("ring")
:B0X*?:reiv:: f("riev")
:B0X*?:relese:: f("release")
:B0X*?:releven:: f("relevan")
:B0X*?:remmi:: f("remi")
:B0X*?:renial:: f("rennial")
:B0X*?:renno:: f("reno")
:B0X*?:rentee:: f("rantee")
:B0X*?:rentor:: f("renter")
:B0X*?:reomm:: f("recomm")
:B0X*?:repatiti:: f("repetiti")
:B0X*?:repb:: f("repub")
:B0X*?:repetant:: f("repentant")
:B0X*?:repetent:: f("repentant")
:B0X*?:replacab:: f("replaceab")
:B0X*?:reposd:: f("respond")
:B0X*?:resense:: f("resence")
:B0X*?:resistab:: f("resistib")
:B0X*?:resiv:: f("ressiv")
:B0X*?:responc:: f("respons")
:B0X*?:respondan:: f("responden")
:B0X*?:restict:: f("restrict")
:B0X*?:revelan:: f("relevan")
:B0X*?:reversab:: f("reversib")
:B0X*?:rhitm:: f("rithm")
:B0X*?:rhythem:: f("rhythm")
:B0X*?:rhytm:: f("rhythm")
:B0X*?:ributred:: f("ributed")
:B0X*?:ridgid:: f("rigid")
:B0X*?:rieciat:: f("reciat")
:B0X*?:rifing:: f("rifying")
:B0X*?:rigeur:: f("rigor")
:B0X*?:rigourous:: f("rigorous")
:B0X*?:rilia:: f("rillia")
:B0X*?:rimetal:: f("rimental")
:B0X*?:rininging:: f("ringing")
:B0X*?:riodal:: f("roidal")
:B0X*?:ritent:: f("rient")
:B0X*?:ritm:: f("rithm")
:B0X*?:rixon:: f("rison")
:B0X*?:rmaly:: f("rmally")
:B0X*?:rmaton:: f("rmation")
:B0X*?:rocord:: f("record")
:B0X*?:ropiat:: f("ropriat")
:B0X*?:rowm:: f("rown")
:B0X*?:roximite:: f("roximate")
:B0X*?:rraige:: f("rriage")
:B0X*?:rshan:: f("rtion")
:B0X*?:rshon:: f("rtion")
:B0X*?:rshun:: f("rtion")
:B0X*?:rtaure:: f("rature")
:B0X*?:rtiing:: f("riting")
:B0X*?:rtnat:: f("rtant")
:B0X*?:ruming:: f("rumming")
:B0X*?:ruptab:: f("ruptib")
:B0X*?:rwit:: f("writ")
:B0X*?:ryed:: f("ried")
:B0X*?:rythym:: f("rhythm")
:B0X*?:saccari:: f("sacchari")
:B0X*?:safte:: f("safet")
:B0X*?:saidit:: f("said it")
:B0X*?:saidth:: f("said th")
:B0X*?:sampel:: f("sample")
:B0X*?:santion:: f("sanction")
:B0X*?:sassan:: f("sassin")
:B0X*?:satelite:: f("satellite")
:B0X*?:satric:: f("satiric")
:B0X*?:sattelite:: f("satellite")
:B0X*?:scaleable:: f("scalable")
:B0X*?:scedul:: f("schedul")
:B0X*?:schedual:: f("schedule")
:B0X*?:scholarstic:: f("scholastic")
:B0X*?:scince:: f("science")
:B0X*?:scipt:: f("script")
:B0X*?:scje:: f("sche")
:B0X*?:scripton:: f("scription")
:B0X*?:sctruct:: f("struct")
:B0X*?:sdide:: f("side")
:B0X*?:sdier:: f("sider")
:B0X*?:seach:: f("search")
:B0X*?:secretery:: f("secretary")
:B0X*?:sedere:: f("sidere")
:B0X*?:seeked:: f("sought")
:B0X*?:segement:: f("segment")
:B0X*?:seige:: f("siege")
:B0X*?:semm:: f("sem")
:B0X*?:senqu:: f("sequ")
:B0X*?:sensativ:: f("sensitiv")
:B0X*?:sentive:: f("sentative")
:B0X*?:seper:: f("separ")
:B0X*?:sepulchure:: f("sepulcher")
:B0X*?:sepulcre:: f("sepulcher")
:B0X*?:sequentually:: f("sequently")
:B0X*?:serach:: f("search")
:B0X*?:sercu:: f("circu")
:B0X*?:sesi:: f("sessi")
:B0X*?:sevic:: f("servic")
:B0X*?:sgin:: f("sign")
:B0X*?:shco:: f("scho")
:B0X*?:siad:: f("said")
:B0X*?:sicion:: f("cision")
:B0X*?:sicne:: f("since")
:B0X*?:sidenta:: f("sidentia")
:B0X*?:signifa:: f("significa")
:B0X*?:significe:: f("significa")
:B0X*?:signit:: f("signat")
:B0X*?:simala:: f("simila")
:B0X*?:similia:: f("simila")
:B0X*?:simmi:: f("simi")
:B0X*?:simpt:: f("sympt")
:B0X*?:sincerley:: f("sincerely")
:B0X*?:sincerly:: f("sincerely")
:B0X*?:sinse:: f("since")
:B0X*?:sistend:: f("sistent")
:B0X*?:sistion:: f("sition")
:B0X*?:sitll:: f("still")
:B0X*?:siton:: f("sition")
:B0X*?:skelaton:: f("skeleton")
:B0X*?:slowy:: f("slowly")
:B0X*?:smae:: f("same")
:B0X*?:smealt:: f("smelt")
:B0X*?:smoe:: f("some")
:B0X*?:snese:: f("sense")
:B0X*?:socal:: f("social")
:B0X*?:socre:: f("score")
:B0X*?:soem:: f("some")
:B0X*?:sohw:: f("show")
:B0X*?:soica:: f("socia")
:B0X*?:sollut:: f("solut")
:B0X*?:soluab:: f("solub")
:B0X*?:sonent:: f("sonant")
:B0X*?:sophicat:: f("sophisticat")
:B0X*?:sorbsi:: f("sorpti")
:B0X*?:sorbti:: f("sorpti")
:B0X*?:sosica:: f("socia")
:B0X*?:sotry:: f("story")
:B0X*?:soudn:: f("sound")
:B0X*?:sourse:: f("source")
:B0X*?:specal:: f("special")
:B0X*?:specfic:: f("specific")
:B0X*?:specialliz:: f("specializ")
:B0X*?:specifiy:: f("specify")
:B0X*?:spectaular:: f("spectacular")
:B0X*?:spectum:: f("spectrum")
:B0X*?:speling:: f("spelling")
:B0X*?:spesial:: f("special")
:B0X*?:spiria:: f("spira")
:B0X*?:spoac:: f("spac")
:B0X*?:sponib:: f("sponsib")
:B0X*?:sponser:: f("sponsor")
:B0X*?:spred:: f("spread")
:B0X*?:spririt:: f("spirit")
:B0X*?:spritual:: f("spiritual")
:B0X*?:spyc:: f("psyc")
:B0X*?:sqaur:: f("squar")
:B0X*?:ssanger:: f("ssenger")
:B0X*?:ssese:: f("ssesse")
:B0X*?:ssition:: f("sition")
:B0X*?:stablise:: f("stabilise")
:B0X*?:staleld:: f("stalled")
:B0X*?:stancial:: f("stantial")
:B0X*?:stange:: f("strange")
:B0X*?:starna:: f("sterna")
:B0X*?:starteg:: f("strateg")
:B0X*?:stateman:: f("statesman")
:B0X*?:statment:: f("statement")
:B0X*?:sterotype:: f("stereotype")
:B0X*?:stingent:: f("stringent")
:B0X*?:stiring:: f("stirring")
:B0X*?:stirrs:: f("stirs")
:B0X*?:stituan:: f("stituen")
:B0X*?:stnad:: f("stand")
:B0X*?:stoin:: f("stion")
:B0X*?:stong:: f("strong")
:B0X*?:stradeg:: f("strateg")
:B0X*?:stratagic:: f("strategic")
:B0X*?:streem:: f("stream")
:B0X*?:strengh:: f("strength")
:B0X*?:structual:: f("structural")
:B0X*?:sttr:: f("str")
:B0X*?:stuct:: f("struct")
:B0X*?:studdy:: f("study")
:B0X*?:studing:: f("studying")
:B0X*?:sturctur:: f("structur")
:B0X*?:stutionaliz:: f("stitutionaliz")
:B0X*?:substancia:: f("substantia")
:B0X*?:succesful:: f("successful")
:B0X*?:succsess:: f("success")
:B0X*?:sucess:: f("success")
:B0X*?:sueing:: f("suing")
:B0X*?:suffc:: f("suffic")
:B0X*?:sufferr:: f("suffer")
:B0X*?:suffician:: f("sufficien")
:B0X*?:superintendan:: f("superintenden")
:B0X*?:suph:: f("soph")
:B0X*?:supos:: f("suppos")
:B0X*?:suppoed:: f("supposed")
:B0X*?:suppy:: f("supply")
:B0X*?:suprass:: f("surpass")
:B0X*?:supress:: f("suppress")
:B0X*?:supris:: f("surpris")
:B0X*?:supriz:: f("surpris")
:B0X*?:surect:: f("surrect")
:B0X*?:surence:: f("surance")
:B0X*?:surfce:: f("surface")
:B0X*?:surle:: f("surel")
:B0X*?:suro:: f("surro")
:B0X*?:surpress:: f("suppress")
:B0X*?:surpriz:: f("surpris")
:B0X*?:susept:: f("suscept")
:B0X*?:svae:: f("save")
:B0X*?:swepth:: f("swept")
:B0X*?:symetr:: f("symmetr")
:B0X*?:symettr:: f("symmetr")
:B0X*?:symmetral:: f("symmetric")
:B0X*?:syncro:: f("synchro")
:B0X*?:sypmtom:: f("symptom")
:B0X*?:sysmatic:: f("systematic")
:B0X*?:sytem:: f("system")
:B0X*?:sytl:: f("styl")
:B0X*?:tagan:: f("tagon")
:B0X*?:tahn:: f("than")
:B0X*?:taht:: f("that")
:B0X*?:tailled:: f("tailed")
:B0X*?:taimina:: f("tamina")
:B0X*?:tainence:: f("tenance")
:B0X*?:taion:: f("tation")
:B0X*?:tait:: f("trait")
:B0X*?:tamt:: f("tant")
:B0X*?:tanous:: f("taneous")
:B0X*?:taral:: f("tural")
:B0X*?:tarey:: f("tary")
:B0X*?:tatch:: f("tach")
:B0X*?:taxan:: f("taxon")
:B0X*?:techic:: f("technic")
:B0X*?:techini:: f("techni")
:B0X*?:techt:: f("tect")
:B0X*?:tecn:: f("techn")
:B0X*?:telpho:: f("telepho")
:B0X*?:tempalt:: f("templat")
:B0X*?:tempara:: f("tempera")
:B0X*?:temperar:: f("temporar")
:B0X*?:tempoa:: f("tempora")
:B0X*?:temporaneus:: f("temporaneous")
:B0X*?:tendac:: f("tendenc")
:B0X*?:tendor:: f("tender")
:B0X*?:tepmor:: f("tempor")
:B0X*?:teriod:: f("teroid")
:B0X*?:terranian:: f("terranean")
:B0X*?:terrestial:: f("terrestrial")
:B0X*?:terrior:: f("territor")
:B0X*?:territorist:: f("terrorist")
:B0X*?:terroist:: f("terrorist")
:B0X*?:tghe:: f("the")
:B0X*?:tghi:: f("thi")
:B0X*?:thaph:: f("taph")
:B0X*?:theather:: f("theater")
:B0X*?:theese:: f("these")
:B0X*?:thgat:: f("that")
:B0X*?:thiun:: f("thin")
:B0X*?:thsoe:: f("those")
:B0X*?:thyat:: f("that")
:B0X*?:tiait:: f("tiat")
:B0X*?:tibut:: f("tribut")
:B0X*?:ticial:: f("tical")
:B0X*?:ticio:: f("titio")
:B0X*?:ticlular:: f("ticular")
:B0X*?:tiction:: f("tinction")
:B0X*?:tiget:: f("tiger")
:B0X*?:tiion:: f("tion")
:B0X*?:tingish:: f("tinguish")
:B0X*?:tioge:: f("toge")
:B0X*?:tionnab:: f("tionab")
:B0X*?:tionne:: f("tione")
:B0X*?:tionni:: f("tioni")
:B0X*?:tisment:: f("tisement")
:B0X*?:titid:: f("titud")
:B0X*?:titity:: f("tity")
:B0X*?:titui:: f("tituti")
:B0X*?:tiviat:: f("tivat")
:B0X*?:tje:: f("the")
:B0X*?:tjhe:: f("the")
:B0X*?:tkae:: f("take")
:B0X*?:tkaing:: f("taking")
:B0X*?:tlak:: f("talk")
:B0X*?:tlied:: f("tled")
:B0X*?:tlme:: f("tleme")
:B0X*?:tlye:: f("tyle")
:B0X*?:tned:: f("nted")
:B0X*?:tofy:: f("tify")
:B0X*?:togani:: f("tagoni")
:B0X*?:toghether:: f("together")
:B0X*?:toleren:: f("toleran")
:B0X*?:tority:: f("torily")
:B0X*?:touble:: f("trouble")
:B0X*?:tounge:: f("tongue")
:B0X*?:tourch:: f("torch")
:B0X*?:toword:: f("toward")
:B0X*?:towrad:: f("toward")
:B0X*?:tradion:: f("tradition")
:B0X*?:tradtion:: f("tradition")
:B0X*?:tranf:: f("transf")
:B0X*?:transmissab:: f("transmissib")
:B0X*?:tribusion:: f("tribution")
:B0X*?:triger:: f("trigger")
:B0X*?:tritian:: f("trician")
:B0X*?:tritut:: f("tribut")
:B0X*?:troling:: f("trolling")
:B0X*?:troverci:: f("troversi")
:B0X*?:trubution:: f("tribution")
:B0X*?:tstion:: f("tation")
:B0X*?:ttele:: f("ttle")
:B0X*?:tuara:: f("taura")
:B0X*?:tudonal:: f("tudinal")
:B0X*?:tuer:: f("teur")
:B0X*?:twpo:: f("two")
:B0X*?:tyfull:: f("tiful")
:B0X*?:tyha:: f("tha")
:B0X*?:udner:: f("under")
:B0X*?:udnet:: f("udent")
:B0X*?:ugth:: f("ught")
:B0X*?:uitious:: f("uitous")
:B0X*?:ulaton:: f("ulation")
:B0X*?:umetal:: f("umental")
:B0X*?:understoon:: f("understood")
:B0X*?:untion:: f("unction")
:B0X*?:unviers:: f("univers")
:B0X*?:uoul:: f("oul")
:B0X*?:uraunt:: f("urant")
:B0X*?:uredd:: f("ured")
:B0X*?:urgan:: f("urgen")
:B0X*?:urveyer:: f("urveyor")
:B0X*?:useage:: f("usage")
:B0X*?:useing:: f("using")
:B0X*?:usuab:: f("usab")
:B0X*?:ususal:: f("usual")
:B0X*?:utrab:: f("urab")
:B0X*?:vacative:: f("vocative")
:B0X*?:valant:: f("valent")
:B0X*?:valubl:: f("valuabl")
:B0X*?:valueabl:: f("valuabl")
:B0X*?:varation:: f("variation")
:B0X*?:varien:: f("varian")
:B0X*?:varing:: f("varying")
:B0X*?:varous:: f("various")
:B0X*?:vegat:: f("veget")
:B0X*?:vegit:: f("veget")
:B0X*?:vegt:: f("veget")
:B0X*?:veinen:: f("venien")
:B0X*?:veiw:: f("view")
:B0X*?:velant:: f("valent")
:B0X*?:velent:: f("valent")
:B0X*?:venem:: f("venom")
:B0X*?:vereal:: f("veral")
:B0X*?:verison:: f("version")
:B0X*?:vertibrat:: f("vertebrat")
:B0X*?:vertion:: f("version")
:B0X*?:vetat:: f("vitat")
:B0X*?:veyr:: f("very")
:B0X*?:vigeur:: f("vigor")
:B0X*?:vigilen:: f("vigilan")
:B0X*?:vison:: f("vision")
:B0X*?:visting:: f("visiting")
:B0X*?:vivous:: f("vious")
:B0X*?:vlalent:: f("valent")
:B0X*?:vment:: f("vement")
:B0X*?:voiu:: f("viou")
:B0X*?:volont:: f("volunt")
:B0X*?:volount:: f("volunt")
:B0X*?:volumn:: f("volum")
:B0X*?:vrey:: f("very")
:B0X*?:vyer:: f("very")
:B0X*?:vyre:: f("very")
:B0X*?:waer:: f("wear")
:B0X*?:waht:: f("what")
:B0X*?:warrent:: f("warrant")
:B0X*?:wehn:: f("when")
:B0X*?:werre:: f("were")
:B0X*?:whant:: f("want")
:B0X*?:wherre:: f("where")
:B0X*?:whta:: f("what")
:B0X*?:wief:: f("wife")
:B0X*?:wieldl:: f("wield")
:B0X*?:wierd:: f("weird")
:B0X*?:wiew:: f("view")
:B0X*?:willk:: f("will")
:B0X*?:windoes:: f("windows")
:B0X*?:wirt:: f("writ")
:B0X*?:witten:: f("written")
:B0X*?:wiull:: f("will")
:B0X*?:wnat:: f("want")
:B0X*?:woh:: f("who")
:B0X*?:wokr:: f("work")
:B0X*?:worls:: f("world")
:B0X*?:wriet:: f("write")
:B0X*?:wrighter:: f("writer")
:B0X*?:writen:: f("written")
:B0X*?:writting:: f("writing")
:B0X*?:wrod:: f("word")
:B0X*?:wrok:: f("work")
:B0X*?:wtih:: f("with")
:B0X*?:wupp:: f("supp")
:B0X*?:yaer:: f("year")
:B0X*?:yearm:: f("year")
:B0X*?:yoiu:: f("you")
:B0X*?:ythim:: f("ythm")
:B0X*?:ytou:: f("you")
:B0X*?:yuo:: f("you")
:B0X*?:zyne:: f("zine")
:B0X*?C:Amercia:: f("America")
:B0X*?C:balen:: f("balan")
:B0X*?C:beng:: f("being")
:B0X*?C:bouy:: f("buoy")
:B0X*?C:comt:: f("cont")
:B0X*?C:doimg:: f("doing")
:B0X*?C:elicid:: f("elicit")
:B0X*?C:elpa:: f("epla")
:B0X*?C:hiesm:: f("theism")
:B0X*?C:manan:: f("manen")
:B0X*?C:mnt:: f("ment")
:B0X*?C:moust:: f("mous")
:B0X*?C:oppen:: f("open")
:B0X*?C:origen:: f("origin")
:B0X*?C:pulic:: f("public")
:B0X*?C:sigin:: f("sign")
:B0X*?C:tehr:: f("ther")
:B0X*?C:tempra:: f("tempora")
:B0X?:'nt:: f("n't")
:B0X?:;ll:: f("'ll")
:B0X?:;re:: f("'re")
:B0X?:;s:: f("'s")
:B0X?:;ve:: f("'ve")
:B0X?:Spet:: f("Sept")
:B0X?:abely:: f("ably")
:B0X?:abley:: f("ably")
:B0X?:acn:: f("can")
:B0X?:addres:: f("address")
:B0X?:aelly:: f("eally")
:B0X?:aindre:: f("ained")
:B0X?:alekd:: f("alked")
:B0X?:allly:: f("ally")
:B0X?:alowing:: f("allowing")
:B0X?:alyl:: f("ally")
:B0X?:amde:: f("made")
:B0X?:ancestory:: f("ancestry")
:B0X?:ancles:: f("acles")
:B0X?:andd:: f("and")
:B0X?:anim:: f("anism")
:B0X?:aotrs:: f("ators")
:B0X?:appearred:: f("appeared")
:B0X?:artice:: f("article")
:B0X?:arund:: f("around")
:B0X?:aticly:: f("atically")
:B0X?:ativs:: f("atives")
:B0X?:atley:: f("ately")
:B0X?:atn:: f("ant")
:B0X?:attemp:: f("attempt")
:B0X?:aunchs:: f("aunches")
:B0X?:autor:: f("author")
:B0X?:ayd:: f("ady")
:B0X?:ayt:: f("ay")
:B0X?:aywa:: f("away")
:B0X?:bilites:: f("bilities")
:B0X?:bilties:: f("bilities")
:B0X?:bilty:: f("bility")
:B0X?:blities:: f("bilities")
:B0X?:blity:: f("bility")
:B0X?:blly:: f("bly")
:B0X?:boared:: f("board")
:B0X?:borke:: f("broke")
:B0X?:bthe:: f("b the")
:B0X?:busines:: f("business")
:B0X?:busineses:: f("businesses")
:B0X?:bve:: f("be")
:B0X?:caht:: f("chat")
:B0X?:certaintly:: f("certainly")
:B0X?:cisly:: f("cisely")
:B0X?:claimes:: f("claims")
:B0X?:claming:: f("claiming")
:B0X?:clud:: f("clude")
:B0X?:comit:: f("commit")
:B0X?:comming:: f("coming")
:B0X?:commiting:: f("committing")
:B0X?:committe:: f("committee")
:B0X?:comon:: f("common")
:B0X?:compability:: f("compatibility")
:B0X?:competely:: f("completely")
:B0X?:controll:: f("control")
:B0X?:controlls:: f("controls")
:B0X?:criticists:: f("critics")
:B0X?:cthe:: f("c the")
:B0X?:cticly:: f("ctically")
:B0X?:ctino:: f("ction")
:B0X?:ctoty:: f("ctory")
:B0X?:cually:: f("cularly")
:B0X?:culem:: f("culum")
:B0X?:currenly:: f("currently")
:B0X?:daty:: f("day")
:B0X?:decidely:: f("decidedly")
:B0X?:develope:: f("develop")
:B0X?:developes:: f("develops")
:B0X?:dfull:: f("dful")
:B0X?:difere:: f("differe")
:B0X?:disctinct:: f("distinct")
:B0X?:dng:: f("ding")
:B0X?:doens:: f("does")
:B0X?:doese:: f("does")
:B0X?:dreasm:: f("dreams")
:B0X?:dtae:: f("date")
:B0X?:dthe:: f("d the")
:B0X?:eamil:: f("email")
:B0X?:ecclectic:: f("eclectic")
:B0X?:eclisp:: f("eclips")
:B0X?:ed form the :: f("ed from the")
:B0X?:edely:: f("edly")
:B0X?:efel:: f("feel")
:B0X?:efort:: f("effort")
:B0X?:efulls:: f("efuls")
:B0X?:elyl:: f("ely")
:B0X?:encs:: f("ences")
:B0X?:equiped:: f("equipped")
:B0X?:essery:: f("essary")
:B0X?:essess:: f("esses")
:B0X?:establising:: f("establishing")
:B0X?:examinated:: f("examined")
:B0X?:expell:: f("expel")
:B0X?:ferrs:: f("fers")
:B0X?:fiel:: f("file")
:B0X?:finit:: f("finite")
:B0X?:finitly:: f("finitely")
:B0X?:fng:: f("fing")
:B0X?:frmo:: f("from")
:B0X?:frp,:: f("from")
:B0X?:fthe:: f("f the")
:B0X?:fuly:: f("fully")
:B0X?:gardes:: f("gards")
:B0X?:getted:: f("geted")
:B0X?:gettin:: f("getting")
:B0X?:gfulls:: f("gfuls")
:B0X?:ginaly:: f("ginally")
:B0X?:giory:: f("gory")
:B0X?:glases:: f("glasses")
:B0X?:gratefull:: f("grateful")
:B0X?:gred:: f("greed")
:B0X?:gthe:: f("g the")
:B0X?:hace:: f("hare")
:B0X?:herad:: f("heard")
:B0X?:herefor:: f("herefore")
:B0X?:hfull:: f("hful")
:B0X?:hge:: f("he")
:B0X?:higns:: f("hings")
:B0X?:higsn:: f("hings")
:B0X?:hsa:: f("has")
:B0X?:hsi:: f("his")
:B0X?:hte:: f("the")
:B0X?:hthe:: f("h the")
:B0X?:http:\\:: f("http://")
:B0X?:httpL:: f("http:")
:B0X?:iaing:: f("iating")
:B0X?:ialy:: f("ially")
:B0X?:iatly:: f("iately")
:B0X?:iblilty:: f("ibility")
:B0X?:icaly:: f("ically")
:B0X?:icm:: f("ism")
:B0X?:icms:: f("isms")
:B0X?:idty:: f("dity")
:B0X?:ienty:: f("iently")
:B0X?:ign:: f("ing")
:B0X?:ilarily:: f("ilarly")
:B0X?:ilny:: f("inly")
:B0X?:inm:: f("in")
:B0X?:iosn:: f("ions")
:B0X?:isio:: f("ision")
:B0X?:itino:: f("ition")
:B0X?:itiy:: f("ity")
:B0X?:itoy:: f("itory")
:B0X?:itr:: f("it")
:B0X?:ityes:: f("ities")
:B0X?:ivites:: f("ivities")
:B0X?:kc:: f("ck")
:B0X?:kfulls:: f("kfuls")
:B0X?:kn:: f("nk")
:B0X?:kng:: f("king")
:B0X?:kthe:: f("k the")
:B0X?:l;y:: f("ly")
:B0X?:laly:: f("ally")
:B0X?:letness:: f("leteness")
:B0X?:lfull:: f("lful")
:B0X?:lieing:: f("lying")
:B0X?:lighly:: f("lightly")
:B0X?:ligy:: f("lify")
:B0X?:likey:: f("likely")
:B0X?:llete:: f("lette")
:B0X?:lsit:: f("list")
:B0X?:lthe:: f("l the")
:B0X?:lwats:: f("lways")
:B0X?:lyu:: f("ly")
:B0X?:maked:: f("marked")
:B0X?:maticas:: f("matics")
:B0X?:miantly:: f("minately")
:B0X?:mibly:: f("mably")
:B0X?:miliary:: f("military")
:B0X?:morphysis:: f("morphosis")
:B0X?:motted:: f("moted")
:B0X?:mpley:: f("mply")
:B0X?:mpyl:: f("mply")
:B0X?:mthe:: f("m the")
:B0X?:n;t:: f("n't")
:B0X?:narys:: f("naries")
:B0X?:ndacies:: f("ndances")
:B0X?:nfull:: f("nful")
:B0X?:nfulls:: f("nfuls")
:B0X?:ngment:: f("ngement")
:B0X?:nicly:: f("nically")
:B0X?:nig:: f("ing")
:B0X?:nision:: f("nisation")
:B0X?:nnally:: f("nally")
:B0X?:nnology:: f("nology")
:B0X?:ns't:: f("sn't")
:B0X?:nsly:: f("nsely")
:B0X?:nsof:: f("ns of")
:B0X?:nsur:: f("nsure")
:B0X?:ntay:: f("ntary")
:B0X?:nyed:: f("nied")
:B0X?:oachs:: f("oaches")
:B0X?:occure:: f("occur")
:B0X?:occured:: f("occurred")
:B0X?:occurr:: f("occur")
:B0X?:olgy:: f("ology")
:B0X?:omst:: f("most")
:B0X?:onaly:: f("onally")
:B0X?:onw:: f("one")
:B0X?:otaly:: f("otally")
:B0X?:otherw:: f("others")
:B0X?:otino:: f("otion")
:B0X?:otu:: f("out")
:B0X?:ougly:: f("oughly")
:B0X?:ouldent:: f("ouldn't")
:B0X?:ourary:: f("orary")
:B0X?:paide:: f("paid")
:B0X?:pich:: f("pitch")
:B0X?:pleatly:: f("pletely")
:B0X?:pletly:: f("pletely")
:B0X?:polical:: f("political")
:B0X?:proces:: f("process")
:B0X?:proprietory:: f("proprietary")
:B0X?:pthe:: f("p the")
:B0X?:publis:: f("publics")
:B0X?:puertorrican:: f("Puerto Rican")
:B0X?:quater:: f("quarter")
:B0X?:quaters:: f("quarters")
:B0X?:querd:: f("quered")
:B0X?:raly:: f("rally")
:B0X?:rarry:: f("rary")
:B0X?:realy:: f("really")
:B0X?:reched:: f("reached")
:B0X?:reciding:: f("residing")
:B0X?:reday:: f("ready")
:B0X?:resed:: f("ressed")
:B0X?:resing:: f("ressing")
:B0X?:returnd:: f("returned")
:B0X?:riey:: f("riety")
:B0X?:rithy:: f("rity")
:B0X?:ritiers:: f("rities")
:B0X?:rthe:: f("r the")
:B0X?:ruley:: f("ruly")
:B0X?:ryied:: f("ried")
:B0X?:saccharid:: f("saccharide")
:B0X?:safty:: f("safety")
:B0X?:sasy:: f("says")
:B0X?:saught:: f("sought")
:B0X?:schol:: f("school")
:B0X?:scoll:: f("scroll")
:B0X?:seses:: f("sesses")
:B0X?:sfull:: f("sful")
:B0X?:sfulyl:: f("sfully")
:B0X?:shiping:: f("shipping")
:B0X?:shorly:: f("shortly")
:B0X?:siary:: f("sary")
:B0X?:sice:: f("sive")
:B0X?:sicly:: f("sically")
:B0X?:smoothe:: f("smooth")
:B0X?:sorce:: f("source")
:B0X?:specif:: f("specify")
:B0X?:ssully:: f("ssfully")
:B0X?:stanly:: f("stantly")
:B0X?:sthe:: f("s the")
:B0X?:stino:: f("stion")
:B0X?:storicians:: f("storians")
:B0X?:stpo:: f("stop")
:B0X?:strat:: f("start")
:B0X?:struced:: f("structed")
:B0X?:stuls:: f("sults")
:B0X?:syas:: f("says")
:B0X?:t eh:: f("the")
:B0X?:targetting:: f("targeting")
:B0X?:teh:: f("the")
:B0X?:tempory:: f("temporary")
:B0X?:tfull:: f("tful")
:B0X?:theh:: f("the")
:B0X?:thh:: f("th")
:B0X?:thn:: f("then")
:B0X?:thne:: f("then")
:B0X?:throught:: f("through")
:B0X?:tht:: f("th")
:B0X?:thw:: f("the")
:B0X?:thyness:: f("thiness")
:B0X?:tiem:: f("time")
:B0X?:timne:: f("time")
:B0X?:tioj:: f("tion")
:B0X?:tionar:: f("tionary")
:B0X?:tng:: f("ting")
:B0X?:tooes:: f("toos")
:B0X?:topry:: f("tory")
:B0X?:toreis:: f("tories")
:B0X?:toyr:: f("tory")
:B0X?:traing:: f("traying")
:B0X?:tricly:: f("trically")
:B0X?:tricty:: f("tricity")
:B0X?:truely:: f("truly")
:B0X?:tthe:: f("the")
:B0X?:tust:: f("trust")
:B0X?:twon:: f("town")
:B0X?:tyo:: f("to")
:B0X?:ualy:: f("ually")
:B0X?:uarly:: f("ularly")
:B0X?:ularily:: f("ularly")
:B0X?:ultimely:: f("ultimately")
:B0X?:urchs:: f("urches")
:B0X?:urnk:: f("runk")
:B0X?:utino:: f("ution")
:B0X?:veill:: f("veil")
:B0X?:verd:: f("vered")
:B0X?:videntally:: f("vidently")
:B0X?:vly:: f("vely")
:B0X?:wass:: f("was")
:B0X?:wasy:: f("ways")
:B0X?:weas:: f("was")
:B0X?:weath:: f("wealth")
:B0X?:wifes:: f("wives")
:B0X?:wille:: f("will")
:B0X?:willingless:: f("willingness")
:B0X?:wordly:: f("worldly")
:B0X?:wroet:: f("wrote")
:B0X?:wthe:: f("w the")
:B0X?:wya:: f("way")
:B0X?:wyas:: f("ways")
:B0X?:xthe:: f("x the")
:B0X?:yng:: f("ying")
:B0X?:ywat:: f("yway")
:B0X?C:btu:: f("but")
:B0X?C:hc:: f("ch")
:B0X?C:itn:: f("ith")
:B0XC*:i'd:: f("I'd")
:B0XC:ASS:: f("ADD")
:B0XC:Im:: f("I'm")
:B0XC:may of:: f("may have")
:B0XC:nad:: f("and")

:*:angstrom::Ångström
:*:anime::animé
:*:apertif::apértif
:*:applique::appliqué
:*:boite::boîte
:*:canape::canapé
:*:celebre::célèbre
:*:chaine::chaîné
:*:chateau::château
:*:cinema verite::cinéma vérité
:*:cliche::cliché
:*:communique::communiqué
:*:confrere::confrère
:*:consomme::consommé
:*:cortege::cortège
:*:coulee::coulée
:*:coup d'etat::coup d'état
:*:coup de grace::coup de grâce
:*:coup de tat::coup d'état
:*:creche::crèche
:*:creme caramel::crème caramel
:*:crepe::crêpe
:*:crouton::croûton
:*:dais::daïs
:*:debacle::débâcle
:*:debutante::débutant
:*:decor::décor
:*:derriere::derrière
:*:discotheque::discothèque
:*:divorcee::divorcée
:*:doppelganger::doppelgänger
:*:eclair::éclair
:*:emigre::émigré
:*:entree::entrée
:*:epee::épée
:*:facade::façade
:*:fete::fête
:*:fiance::fiancé
:*:flambe::flambé
:*:frappe::frappé
:*:fraulein::fräulein
:*:garcon::garçon
:*:gateau::gâteau
:*:habitue::habitué
:*:jalapeno::jalapeño
:*:matinee::matinée
:*:melee::mêlée
:*:moireing::moiré
:*:naif::naïf
:*:negligee::negligée
:*:noel::Noël
:*:ombre::ombré
:*:pina colada::Piña Colada
:*:pinata::piñata
:*:pinon::piñon
:*:protege::protégé
:*:puree::purée
:*:saute::sauté
:*:seance::séance
:*:senor::señor
:*:smorgasbord::smörgåsbord
:*:soiree::soirée
:*:souffle::soufflé
:*:soupcon::soupçon
:*:tete-a-tete::tête-à-tête
:*:ubermensch::Übermensch
::Bjorn::Bjørn
::Fohn wind::Föhn wind
::Quebecois::Québécois
::a bas::à bas
::a la::à la
::aesop::Æsop
::ancien regime::Ancien Régime
::ao dai::ào dái
::apres::après
::arete::arête
::attache::attaché
::auto-da-fe::auto-da-fé
::belle epoque::belle époque
::bete noire::bête noire
::betise::bêtise
::blase::blasé
::boutonniere::boutonnière
::champs-elysees::Champs-Élysées
::charge d'affaires::chargé d'affaires
::cinemas verite::cinémas vérit
::cloisonne::cloisonné
::creme brulee::crème brûlée
::creme de cacao::crème de cacao
::creme de menthe::crème de menthe
::creusa::Creüsa
::crudites::crudités
::curacao::curaçao
::declasse::déclassé
::decolletage::décolletage
::decollete::décolleté
::decoupage::découpage
::degage::dégagé
::deja vu::déjà vu
::demode::démodé
::denoument::dénoument
::derailleur::dérailleur
::deshabille::déshabillé
::detente::détente
::diamante::diamanté
::eclat::éclat
::el nino::El Niño
::elan::élan
::entrecote::entrecôte
::entrepot::entrepôt
::etouffee::étouffée
::faience::faïence
::filmjolk::filmjölk
::fin de siecle::fin de siècle
::fleche::flèche
::folie a deux::folie à deux
::folies a deux::folies à deux
::fouette::fouetté
::gardai::gardaí
::gemutlichkeit::gemütlichkeit
::gewurztraminer::Gewürztraminer
::glace::glacé
::glogg::glögg
::gotterdammerung::Götterdämmerung
::grafenberg spot::Gräfenberg spot
::ingenue::ingénue
::jager::jäger
::jardiniere::jardinière
::kaldolmar::kåldolmar
::krouzek::kroužek
::kummel::kümmel
::la nina::La Niña
::landler::ländler
::langue d'oil::langue d'oïl
::litterateur::littérateur
::lycee::lycée
::macedoine::macédoine
::macrame::macramé
::maitre d'hotel::maître d'hôtel
::malaguena::malagueña
::manana::mañana
::manege::manège
::manque::manqué
::materiel::matériel
::melange::mélange
::menage a trois::ménage à trois
::menages a trois::ménages à trois
::mesalliance::mésalliance
::metier::métier
::minaudiere::minaudière
::mobius::Möbius
::moire::moiré
::motley crue::Mötley Crüe
::motorhead::Motörhead
::naive::naïve
::naiver::naïver
::naives::naïves
::naivete::naïveté
::nee::née
::neufchatel::Neufchâtel
::nez perce::Nez Percé
::número uno::número uno
::objet trouve::objet trouvé
::objets trouve::objets trouvé
::omerta::omertà
::opera bouffe::opéra bouffe
::opera comique::opéra comique
::operas bouffe::opéras bouffe
::operas comique::opéras comique
::outre::outré
::papier-mache::papier-mâché
::passe::passé
::piece de resistance::pièce de résistance
::pied-a-terre::pied-à-terre
::pique::piqué
::piqued::piquéd
::pirana::piraña
::più::più
::plie::plié
::plisse::plissé
::polsa::pölsa
::precis::précis
::pret-a-porter::prêt-à-porter
::raison d'etre::raison d'être
::recherche::recherché
::retrousse::retroussé
::risque::risqué
::riviere::rivière
::roman a clef::roman à clef
::roue::roué
::sinn fein::Sinn Féin
::smorgastarta::smörgåstårta
::soigne::soigné
::sprachgefühl::sprachgefuhl
::surstromming::surströmming
::touche::touché
::tourtiere::tourtière
::ventre a terre::ventre à terre
::vicuna::vicuña
::vin rose::vin rosé
::vins rose::vins rosé
::vis a vis::vis à vis
::vis-a-vis::vis-à-vis
::voila::voilà


:C:april::April
:C:august::August
:C:december::December
:C:february::February
:C:friday::Friday
:C:january::January
:C:july::July
:C:june::June
:C:monday::Monday
:C:november::November
:C:october::October
:C:saturday::Saturday
:C:september::September
:C:sunday::Sunday
:C:thursday::Thursday
:C:tuesday::Tuesday
:C:wednesday::Wednesday

::;fruits::
(
Apple
Banana
Carrot
Date
Eggplant
Fig
Grape
Honeydew
Iceberg lettuce
Jalapeno
Kiwi
Lemon
Mango
Nectarine
Orange
Papaya
Quince
Radish
Strawberry
Tomato
Ugli fruit
Vanilla bean
Watermelon
Xigua (Chinese watermelon)
Yellow pepper
Zucchini
)

::;animals::
(
Aardvark
Butterfly
Cheetah
Dolphin
Elephant
Frog
Giraffe
Hippo
Iguana
Jaguar
Kangaroo
Lion
Monkey
Narwhal
Owl
Penguin
Quail
Rabbit
Snake
Tiger
Umbrellabird
Vulture
Wolf
X-ray fish
Yak
Zebra
)

::;colors::
(
Amber
Blue
Crimson
Denim
Emerald
Fuchsia
Gold
Harlequin
Indigo
Jade
Khaki
Lavender
Magenta
Navy
Olive
Pink
Quartz
Red
Scarlet
Turquoise
Ultramarine
Violet
White
Xanadu
Yellow
Zaffre
)


:B0X*?:schg:: f("sch")
:B0X*:rre:: f("re")
:B0X*:evesdrop:: f("eavesdrop")
:B0X*?:pareed:: f("pared")
:B0X:thi:: f("the")
:B0X*?:renuw:: f("renew")
:B0X:thet:: f("that")
:B0X*?:tyhi:: f("thi")
:B0X*?:oloda:: f("olida")
:B0X*?:sctipt:: f("script")
:B0X*:uploda:: f("upload")
:B0X:thise:: f("these")
:B0X:butause:: f("because")
:B0X*?:sciipt:: f("script")
:B0X*:hotring:: f("hotstring")
:B0X:thet:: f("that")
:B0X*?:conllict:: f("conflict")
:B0X:eash:: f("each")
:B0X:tha:: f("the")
:B0XC:i:: f("I")
:B0X*?:visial:: f("visual")
:B0X*:assignement:: f("assignment")
:B0X?*:delimma:: f("dilemma")
:B0XC:copt:: f("copy")
:B0X*:delima:: f("dilemma")
:B0X:I thing:: f("I think")