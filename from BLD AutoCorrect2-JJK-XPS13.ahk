#SingleInstance
SetWorkingDir(A_ScriptDir)
SetTitleMatchMode("RegEx")
#Requires AutoHotkey v2+

pathDefaultEditor := (FileExist("C:\Users\" . A_UserName . "\AppData\Local\Programs\Microsoft VS Code\Code.exe"))
    ? "C:\Users\" . A_UserName . "\AppData\Local\Programs\Microsoft VS Code\Code.exe"
        : "Notepad.exe"

        
; Structure for script and supporting files
        
urlGitRepo := "https://github.com/kunkel321/AutoCorrect2"

folderGitCopy := A_ScriptDir "\GitHub"
folderLib := A_ScriptDir '\Lib'
folderMedia := A_ScriptDir '\Icons'
folderLogs := A_ScriptDir '\Logs'

filenameThisScript := A_ScriptName
filenameUserHotstrings := "UserHotstrings.ahk"
filenameWordlist := 'GitHubComboList249k.txt'
filenameACLogger := folderLogs . "\AutoCorrectsLog.ahk"
filenameMCLogger := folderLogs . "\MClogger.ahk"
filenameMCLog := folderLogs . "\MCLog.txt"

pathThisScript := A_ScriptFullPath
pathUserHotstrings := folderLib '\' filenameUserHotstrings
pathWordList := folderLib '\' filenameWordlist
pathACLogger := folderLogs '\' filenameACLogger
pathMCLogger := folderLogs '\' filenameMCLogger
pathMCLog := folderLogs '\' filenameMCLog

hhFormName := "HotString Helper 2"

; Hotkey for correction GUI

hh_Hotkey := "#h"

; Variables for default options
myPilcrow := "¶"
myDot := "• "
myTab := "⟹ "

DefaultBoilerPlateOpts := ""
DefaultAutoCorrectOpts := "*"

myPrefix := ";"
mySuffix := ""

addFirstLetters := 5
tooSmallLen := 2

AutoLookupFromValidityCheck := 0
AutoCommentFixesAndMisspells := 1

; Variables for GUI
hhGUIColor := "F5F5DC"
hhFontColor := "003366"

myGreen := 'c1D7C08'
myRed := 'cB90012'
myBigFont := 's13'

HeightSizeIncrease := 300
WidthSizeIncrease := 400

bb := Gui('', 'Validity Report')

; Variables for logging
AutoEnterNewEntry := 1

savedUpText := ''

logIsRunning := 0
intervalCounter := 0
saveIntervalMinutes := 5
saveIntervalMinutes := saveIntervalMinutes * 60 * 1000
IntervalsBeforeStopping := 2

; Variables for correction GUI
ExamPaneOpen := 0
ControlPaneOpen := 0

targetWindow := "" 

lastTrigger := ""
origTriggerTypo := ""
OrigReplacment := ""
IsMultiLine := 0

tArrStep := []
rArrStep := []

; set up tray menu
    TraySetIcon(folderMedia . "\Psicon.ico")

    acMenu := A_TrayMenu
    acMenu.Delete
    acMenu.SetColor("Silver")
    
    acMenu.Add("Edit This Script", handleEditScript)
    acMenu.Add("Run Printer Tool", handlePrinterTool)
    acMenu.Add("System Up Time", handleUptime)
    acMenu.Add("Reload Script", (*) => Reload())
    acMenu.Add("List Lines Debug", (*) => ListLines())
    acMenu.Add("Exit Script", (*) => ExitApp())
    
    acMenu.SetIcon("Edit This Script", folderMedia . "\edit-Blue.ico")
    acMenu.SetIcon("Run Printer Tool", folderMedia . "\printer-Blue.ico")
    acMenu.SetIcon("System Up Time", folderMedia . "\clock-Blue.ico")
    acMenu.SetIcon("Reload Script", folderMedia . "\repeat-Blue.ico")
    acMenu.SetIcon("List Lines Debug", folderMedia . "\ListLines-Blue.ico")
    acMenu.SetIcon("Exit Script", folderMedia . "\exit-Blue.ico")
    
; Set up hotkey helper GUI
    ; Initialize the GUI
        hh := Gui('', hhFormName)

    ; Default optons for the GUI
        hh.Opt("-MinimizeBox +alwaysOnTop")
        hh.BackColor := hhGUIColor
        hhFontColor := (hhFontColor != "") ? "c" . hhFontColor : ""
        hFactor     := 0
        wFactor     := 0

    ; set up GUI
        hh.SetFont('s9')
            hhReplacementLabel                  := hh.AddText('xm', 'Replacement')
            hhBiggerButton                      := hh.AddButton('vSizeTog x+75 yp-5 h8 +notab', 'Make Bigger')
            hhShowSymbolsButton                 := hh.AddButton('vSymTog x+5 h8 +notab', '+ Symbols')

        hh.SetFont('s10')
            hhLeftTrimButton                    := hh.AddButton('vbutLtrim xm h50  w' . (wFactor + 182 / 6), '>>')
            hhRightTrimButton                   := hh.AddButton('vbutRtrim x+1 h50 w' . (wFactor + 182 / 6), '<<')
            hhACLogHandler                      := hh.AddButton('  y+5 h25 xm w' . wFactor + 370, 'Open AutoCorrection Log')
            hhMCLogHandler                      := hh.AddButton('  y+5 h25 xm w' . wFactor + 370, 'Open Manual Correction Log')
            hhCountHoststringsAndFixesButton    := hh.AddButton('y+5 h25 xm w' . wFactor + 370, 'Count HotStrings and Potential Fixes')

        hh.SetFont('bold s10')
            hhWordlistFilenameButton            := hh.AddText('vWordList center xm y+1 h14 w' . wFactor * 2 + 364, filenameWordlist)

        hh.SetFont('s11')
            hhCommentLabel                      := hh.AddText('xm y' . hFactor + 182, 'Comment')

            hhCommentEdit                       := hh.AddEdit('cGreen vComStr xs y' . hFactor + 200 . ' w' . wFactor + 370)
            hhReplacementEdit                   := hh.AddEdit('cDefault vReplaceString +Wrap y+1 xs h' . hFactor + 100 . ' w' . wFactor + 370, '')

            hhMakeFunctionToggle                := hh.AddCheckbox('vFunc, x+70 y' . hFactor + 182, 'Make Function')
            hhMakeFunctionToggle.Value := 1

            hhAppendButton                      := hh.AddButton('xm y' . hFactor + 234, 'Append')
            hhCheckButton                       := hh.AddButton('+notab x+5 y' . hFactor + 234, 'Check')
            hhExamButton                        := hh.AddButton('+notab x+5 y' . hFactor + 234, 'Exam')
            hhSpellButton                       := hh.AddButton('+notab x+5 y' . hFactor + 234, 'Spell')
            hhOpenButton                        := hh.AddButton('+notab x+5 y' . hFactor + 234, 'Open')
            hhCancelButton                      := hh.AddButton('+notab x+5 y' . hFactor + 234, 'Cancel')
            hhUndoButton                        := hh.AddButton('xm y+3 h26 w' . (wFactor + 182 * 2), "Undo (+Reset)")
            hhUndoButton.Enabled := false

            hhBeginRadio                        := hh.AddRadio('vBegRadio y+-18 x' . (wFactor + 182 / 3), '&Beginnings')
            hhMiddleRadio                       := hh.AddRadio('vMidRadio x+5', '&Middles')
            hhEndRadio                          := hh.AddRadio('vEndRadio x+5', '&Endings')

        hh.SetFont("s11 " . hhFontColor)
            hhOptionsLabel                      := hh.AddText('y4 w30', 'Options')
            hhTriggerLabel                      := hh.AddText('x+40 w250', 'Trigger String') ; (hhTriggerLabel := hh.AddText('x+40 w250', 'Trigger String'))

            hhOptionsEdit                       := hh.AddEdit('cDefault yp+20 xm+2 w70 h24') ; (hhOptionsEdit := hh.AddEdit('cDefault yp+20 xm+2 w70 h24'))
            hhTriggerEdit                       := hh.AddEdit('cDefault x+18 w' . wFactor + 280, '')

        hh.SetFont('s12')
            hhMisspellsListLabel                := hh.AddText('vTrigLabel center y+4 h25 xm w' . wFactor + 182, 'Misspells')
            hhCorrectsListLabel                 := hh.AddText('vReplLabel center h25 x+5 w' . wFactor + 182, 'Fixes')

            hhTriggerMatchesEdit                := hh.AddEdit('cDefault vTrigMatches y+1 xm h' . hFactor + 300 . ' w' . wFactor + 182,)
            hhReplacementMatchesEdit            := hh.AddEdit('cDefault vReplMatches x+5 h' . hFactor + 300 . ' w' . wFactor + 182,)
            
            hh.SetFont('s14')
            hhTypoLabel                         := hh.AddText('vTypoLabel -wrap +center cBlue x+1 w' . (wFactor + 182 * 5 / 3), hhFormName)
            hhSecretControlPanelButton          := hh.AddText(' center cBlue ym+270 h25 xm w' . wFactor + 370, 'Secret Control Panel!')
        
    ; Event handlers for GUI
        
        hh.OnEvent("Close", hhButtonCancelHandler)

        hhAppendButton.OnEvent("Click", hhAppendHandler)
        hhCheckButton.OnEvent("Click", hhCheckHandler)
        hhExamButton.OnEvent("Click", hhExamHandler)
        hhSpellButton.OnEvent("Click", hhSpellHandler)
        hhOpenButton.OnEvent("Click", hhButtonOpenHandler)
        hhCancelButton.OnEvent("Click", hhButtonCancelHandler)
        hhBiggerButton.OnEvent("Click", hhSizeToggleHandler)
        hhMakeFunctionToggle.OnEvent('click', hhSaveAsFunctionHandler)
        hhShowSymbolsButton.OnEvent("Click", hhToggleSymbolsHandler)
        hhLeftTrimButton.OnEvent('click', hhTrimLeftHandler)
        hhRightTrimButton.OnEvent('click', hhTrimRightHandler)
        hhExamButton.OnEvent("ContextMenu", hhSubFuncExamControlHandler)
        hhTriggerEdit.OnEvent('Change', hhTriggerChangedHandler) ; (hhTriggerEdit := hh.AddEdit('cDefault x+18 w' . wFactor + 280, '')).OnEvent('Change', hhTriggerChangedHandler)
        hhReplacementEdit.OnEvent('Change', hhActivateFilterHandler)
        hhBeginRadio.OnEvent('click', hhActivateFilterHandler)
        hhMiddleRadio.OnEvent('click', hhActivateMiddleHandler)
        hhEndRadio.OnEvent('click', hhActivateFilterHandler)
        hhUndoButton.OnEvent('Click', hhUndoHandler)
        hhWordlistFilenameButton.OnEvent('DoubleClick', hhWordlistHandler)
        hhACLogHandler.OnEvent("click", (*) => hhRunLoggerHandler("hhACLogHandler"))
        hhMCLogHandler.OnEvent("click", (*) => hhRunLoggerHandler("hhMCLogHandler"))
        hhCountHoststringsAndFixesButton.OnEvent('Click', hhStringsAndFixesHandler)

; Execute functions to ensure necessary files are present

    CheckAndRunAsAdmin()
    CheckAndCloneRepo()

; Execute functions to establish base states for HH GUI

    hhToggleExamButtonHandler(Visibility := False)
    hhToggleButtonsControlHandler(Visibility := False)

; Start Hotkeys

#HotIf WinActive(hhFormName)

    $Enter::
    {
        If (hh['SymTog'].text = "Hide Symb")
            return
        Else if (hhReplacementEdit.Focused)
        {
            Send("{Enter}")
            Return
        }
        Else
            hhAppendHandler()
    }

    +Left::
    {
        hhTriggerEdit.Focus()
        Send("{Home}")
    }

    Esc::
    {
        hh.Hide()
        A_Clipboard := ClipboardOld
    }

    ^z:: hhUndoHandler()

    ^+z:: GoReStart()

    ^Up::
    ^WheelUp::
    {
        hhOptionsEdit.SetFont('s15')
        hhTriggerEdit.SetFont('s15')
        hhReplacementEdit.SetFont('s15')
    }

    ^Down::
    ^WheelDown::
    {
        hhOptionsEdit.SetFont('s11')
        hhTriggerEdit.SetFont('s11')
        hhReplacementEdit.SetFont('s11')
    }

#HotIf

Hotkey(hh_Hotkey, CheckClipboard)

;; Functions for ensuring availability of necessary files and appropriate file structure

CheckAndRunAsAdmin()
{
    If (!A_IsAdmin)
    {
        If (!AllFilesExist())
        {
            RunAsAdmin()
            ExitApp()
        }
    }
}

AllFilesExist()
{
    Global folderGitCopy, folderLib, folderLogs, folderMedia, filenameACLogger, filenameMCLogger, filenameMCLog, pathWordList
    files := [
        folderGitCopy,
        folderLib,
        folderLogs,
        folderMedia,
        filenameACLogger,
        filenameMCLogger,
        filenameMCLog,
        pathWordList
    ]
    for file in files
    {
        If (!FileExist(file))
            return false
    }
    return true
}

RunAsAdmin()
{
    full_command_line := DllCall("GetCommandLine", "str")
    if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
    {
        try
        {
            if A_IsCompiled
                Run('*RunAs "' A_ScriptFullPath '" /restart')
            else
                Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
        }
    }
}

CloneAndUnzipRepo()
{
    If (A_IsAdmin)
    {
        If (!FileExist(folderGitCopy))
        {
            Try
            {
                RunWait('*RunAs "' "git clone '" urlGitRepo "' '" folderGitCopy "'", folderGitCopy, "max")
                UnzipFile(folderGitCopy '\AutoCorrect2.zip', folderGitCopy)
            }
            Catch
            {
                MsgBox("Failed to clone or unzip the repository. Please check your internet connection and try again.")
            }
        }
    }
    else If (MsgBox("Do you want to restart as admin?", "YesNo") = "Yes")
    {
        RunAsAdmin()
    }
}

CheckAndCloneRepo()
{
    If (A_IsAdmin)
    {
        If (FileExist(folderGitCopy) || !AllFilesExist())
        {
            FolderSize := 0
            Loop Files, folderGitCopy "\*.*", "R"
                FolderSize += A_LoopFileSize

            If (FileExist(folderGitCopy) && folderSize < 100000)
            {
                FileDelete(folderGitCopy)
                DirCreate(folderGitCopy)
                CloneAndUnzipRepo()
            }

            CreateFoldersAndCopyFiles()
        }
        Else
        {
            Msgbox("This script must be run as an administrator to ensure all necessary files are present.")
        }
    }
}

CreateFoldersAndCopyFiles()
{
    global folderGitCopy, folderLib, folderLogs, folderMedia, filenameWordlist,
        folders := [
            folderLib,
            folderLogs,
            folderMedia
        ]
    for folder in folders
    {
        If (!FileExist(folder))
            DirCreate(folder)
    }

    CopyFiles(folderGitCopy "\Icons\*.ico", folderMedia)

    filesToCopy := [
        pathACLogger,
        pathMCLogger,
        pathMCLog
    ]
    CopyFiles(filesToCopy, folderLogs)

    filesToCopy := [
        pathWordList
    ]
    CopyFiles(filesToCopy, folderLib)

    If (!FileExist(pathUserHotstrings))
        FileAppend("", pathUserHotstrings)
}

CopyFiles(files, destination)
{
    copyError := 0
    Loop files
    {
        If (!FileExist(destination "\" A_LoopFileName))
        {
            copyError := CopyFilesAndFolders(A_LoopFileFullPath, destination)
            If (copyError != 0)
                MsgBox("Failed to copy " A_LoopFileName " to " destination ".")
        }
    }
}

;; Hotkey helper-related functions

hhRunLoggerHandler(buttonIdentifier)
{
    if (buttonIdentifier = "hhACLogHandler")
        Run("'" pathDefaultEditor "' '" filenameACLogger "'")
    else if (buttonIdentifier = "hhMCLogHandler")
        Run("'" pathDefaultEditor "' '" filenameMCLogger "'")
}

hhToggleButtonsControlHandler(Visibility := False)
{
    ControlCmds := [
        hhSecretControlPanelButton,
        hhACLogHandler,
        hhMCLogHandler,
        hhCountHoststringsAndFixesButton]
    for ctrl in ControlCmds
    {
        ctrl.Visible := Visibility
    }
}

hhToggleExamButtonHandler(Visibility := False)
{
    examCmds := [
        hhLeftTrimButton,
        hhTypoLabel,
        hhRightTrimButton,
        hhBeginRadio,
        hhMiddleRadio,
        hhEndRadio,
        hhUndoButton,
        hhMisspellsListLabel,
        hhCorrectsListLabel,
        hhTriggerMatchesEdit,
        hhReplacementMatchesEdit,
        hhWordlistFilenameButton]
    for ctrl in examCmds
    {
        ctrl.Visible := Visibility
    }
}

CheckClipboard(*)
{
    hhTriggerLabel.SetFont(hhFontColor)

    Global ClipboardOld := ClipboardAll()

    Global triggerBeforeTrimming
    Global triggerBeforeThisTrim

    Global replacementBeforeTrimming
    Global replacementBeforeThisTrim

    Global triggerAfterThisTrim
    Global replacementAfterThisTrim

    hsRegex := "(?Jim)^:(?<Opts>[^:]+)*:(?<Trig>[^:]+)::(?:f\((?<Repl>[^,)]*)[^)]*\)|(?<Repl>[^;\v]+))?(?<fCom>\h*;\h*(?:\bFIXES\h*\d+\h*WORDS?\b)?(?:\h;)?\h*(?<mCom>.*))?$"
    hhReplacementMatchesEdit.CurrMatches := ""
    A_Clipboard := ""

    Send("^c")
    Errorlevel := !ClipWait(0.3)

    hotstringFromClipboard := Trim(A_Clipboard, " `t`n`r")

    If RegExMatch(hotstringFromClipboard, hsRegex, &hotstringFromRegex)
    {
        hhTriggerEdit.text := hotstringFromRegex.Trig
        hhOptionsEdit.Value := hotstringFromRegex.Opts

        sleep(200)

        hhCurrentTrigger        := triggerBeforeThisTrim        := triggerBeforeTrimming        := hhCurrentTrigger.text    := hotstringFromRegex.Trig  := Trim(hotstringFromRegex.Trig, '"')
        hhCurrentReplacement    := replacementBeforeThisTrim    := replacementBeforeTrimming    := hhReplacementEdit.text   := hotstringFromRegex.Repl  := Trim(hotstringFromRegex.Repl, '"')
        hhCommentEdit.text      := hotstringFromRegex.mCom
        
        If InStr(hotstringFromRegex.Opts, "*")
        {
            If InStr(hotstringFromRegex.Opts, "?")
                hhMiddleRadio.Value := 1
            Else
                hhBeginRadio.Value := 1
            
        } 
        Else If InStr(hotstringFromRegex.Opts, "?")
            hhEndRadio.Value := 1
        Else
            hhMiddleRadio.Value := 1
        
        ExamineWords(hhCurrentTrigger, hhCurrentReplacement)
    }
    Else
    {
        NormalStartup(A_Clipboard, A_Clipboard)
    }

    hhUndoButton.Enabled := false
    
    ;; WHY ARE THESE INSTRUCTIONS HERE??
    Loop tArrStep.Length
        tArrStep.pop
    Loop rArrStep.Length
        rArrStep.pop
}

NormalStartup(stringTrigger, stringReplacement) ; ISSUE: second param is unnecessary
{
    Global IsMultiLine := 0
    Global targetWindow := WinActive("A")
    Global origTriggerTypo := ""
    Global DefaultBoilerPlateOpts
    Global DefaultAutoCorrectOpts

    If ((StrLen(stringTrigger) - StrLen(StrReplace(stringTrigger, " ")) > 2) || InStr(stringReplacement, "`n"))
    {
        DefaultOpts := DefaultBoilerPlateOpts
        hhReplacementEdit.value := stringTrigger
        IsMultiLine := 1
        hhMakeFunctionToggle.Value := 0
        If (addFirstLetters > 0)
        {
            initials := ""
            HotStrSug := StrReplace(stringTrigger, "`n", " ")
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
    Else If (stringTrigger = "")
    {
        hhCommentEdit.Text := hhReplacementEdit.Text := hhTriggerEdit.Text := hhOptionsEdit.Text := ""
        hhEndRadio.Value := hhMiddleRadio.Value := hhBeginRadio.Value := 0
        hhActivateFilterHandler()
        hh.Show('Autosize yCenter')
        Return
    }
    else
    {
        If (AutoEnterNewEntry = 1)
            origTriggerTypo := stringTrigger
        DefaultHotStr := Trim(StrLower(stringTrigger))
        hhReplacementEdit.value := Trim(StrLower(stringTrigger))
        DefaultOpts := DefaultAutoCorrectOpts
    }

    hhOptionsEdit.text := DefaultOpts
    hhTriggerEdit.value := DefaultHotStr
    hhReplacementEdit.Opt("-Readonly")
    hhAppendButton.Enabled := true
    If ExamPaneOpen = 1
        hhActivateFilterHandler()
    hh.Show('Autosize yCenter')
}

ExamineWords(stringTrigger, stringReplacement)
{
    Global beginning := ""
    Global typo := ""
    Global fix := ""
    Global ending := ""

    SubTogSize(0, 0)
    hh.Show('Autosize yCenter')

    ostrT := stringTrigger
    ostrR := stringReplacement
    LenT := strLen(stringTrigger)
    LenR := strLen(stringReplacement)

    LoopNum := min(LenT, LenR)
    arrayT := StrSplit(stringTrigger)
    arrayR := StrSplit(stringReplacement)

    If ostrT = ostrR
    {
        deltaString := "[ " ostrT " | " ostrR " ]"
        found := false
    }
    else
    {
        Loop LoopNum
        {
            bsubT := (arrayT[A_Index])
            bsubR := (arrayR[A_Index])
            If (bsubT = bsubR)
                beginning .= bsubT
            else
                break
        }

        Loop LoopNum
        {
            RevIndex := (LenT - A_Index) + 1
            esubT := (arrayT[RevIndex])
            RevIndex := (LenR - A_Index) + 1
            esubR := (arrayR[RevIndex])
            If (esubT = esubR)
                ending := esubT . ending
            else
                break
        }

        If (strLen(beginning) + strLen(ending)) > LoopNum
        {
            delta := (LenT > LenR)
                ? " [ " . subStr(ending, 1, (LenT - LenR)) . " |  ] "
                    : (LenR > LenT)
                        ? " [  |  " . subStr(ending, 1, (LenR - LenT)) . " ] "
                        : ""
        }
        Else
        {
            typo := (strLen(beginning) > strLen(ending)) ? StrReplace(ostrT, beginning, "") : StrReplace(ostrT, ending, "")
            typo := (strLen(beginning) > strLen(ending)) ? StrReplace(typo, ending, "") : StrReplace(typo, beginning, "")
            fix := (strLen(beginning) > strLen(ending)) ? StrReplace(ostrR, beginning, "") : StrReplace(ostrR, ending, "")
            fix := (strLen(beginning) > strLen(ending)) ? StrReplace(fix, ending, "") : StrReplace(fix, beginning, "")
            delta := " [ " . typo . " | " . fix . " ] "
        }
        deltaString := beginning . delta . ending

    }
    hhTypoLabel.text := deltaString

    ViaExamButt := "Yes"
    hhActivateFilterHandler(ViaExamButt)

    If (hhExamButton.text = "Exam")
    {
        hhExamButton.text := "Done"
        If (hFactor != 0)
        {
            hh['SizeTog'].text := "Make Bigger"
            ;soundbeep
            SubTogSize(0, 0)
        }
        hhToggleExamButtonHandler(True)
    }

    hh.Show('Autosize yCenter')
}

hhSizeToggleHandler(*)
{
    Global hFactor := ""
    Global Visibility
    Global ExamPaneOpen
    Global ControlPaneOpen

    If (hh['SizeTog'].text = "Make Bigger")
    {
        hh['SizeTog'].text := "Make Smaller"
        If (hhExamButton.text = "Done")
        {
            hhToggleExamButtonHandler(Visibility := False)
            ExamPaneOpen := 0
            hhToggleButtonsControlHandler(Visibility := False)
            ControlPaneOpen := 0
            hhExamButton.text := "Exam"
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
    hhTriggerEdit.Move(, , wFactor + 280,)
    hhReplacementEdit.Move(, , wFactor + 372, hFactor + 100)
    hhCommentLabel.Move(, hFactor + 182, ,)
    hhCommentEdit.move(, hFactor + 200, wFactor + 367,)
    hhMakeFunctionToggle.Move(, hFactor + 182, ,)
    hhAppendButton.Move(, hFactor + 234, ,)
    hhCheckButton.Move(, hFactor + 234, ,)
    hhExamButton.Move(, hFactor + 234, ,)
    hhSpellButton.Move(, hFactor + 234, ,)
    hhOpenButton.Move(, hFactor + 234, ,)
    hhCancelButton.Move(, hFactor + 234, ,)
}

hhSubFuncExamControlHandler(*)
{
    Global ControlPaneOpen

    hhExamButton.text := (ControlPaneOpen = 1)
        ? "Exam"
            : "Done"

    If (hFactor = HeightSizeIncrease && ControlPaneOpen = 0)
    {
        hhSizeToggleHandler()
        hh['SizeTog'].text := "Make Bigger"
    }

    (ControlPaneOpen = 1) ? hhToggleButtonsControlHandler(False)
        : hhToggleButtonsControlHandler(True)

        ControlPaneOpen := (ControlPaneOpen = 1)
            ? 0
                : 1

        hhToggleExamButtonHandler(False)
        hh.Show('Autosize yCenter')
}

hhExamHandler(*)
{
    Global ExamPaneOpen
    Global ControlPaneOpen

    If ((ExamPaneOpen = 0) and (ControlPaneOpen = 0) and GetKeyState("Shift")) || ((ExamPaneOpen = 1) and (ControlPaneOpen = 0) and GetKeyState("Shift"))
    {
        hhSubFuncExamControlHandler()
    }
    Else If ((ExamPaneOpen = 0) and (ControlPaneOpen = 0))
    {
        hhExamButton.text := "Done"
        If (hFactor = HeightSizeIncrease)
        {
            hhSizeToggleHandler()
            hh['SizeTog'].text := "Make Bigger"
        }

        ExamineWords(hhTriggerEdit.text, hhReplacementEdit.text)
        hhActivateFilterHandler()
        hhToggleButtonsControlHandler(False)
        hhToggleExamButtonHandler(True)
        ExamPaneOpen := 1
    }
    Else
    {
        hhExamButton.text := "Exam"
        hhToggleButtonsControlHandler(False)
        hhToggleExamButtonHandler(False)
        ExamPaneOpen := 0
        ControlPaneOpen := 0
    }
    hh.Show('Autosize yCenter')
}

hhToggleSymbolsHandler(*)
{
    If (hh['SymTog'].text = "+ Symbols")
    {
        hh['SymTog'].text := "- Symbols"
        togReplaceString := hhReplacementEdit.text
        togReplaceString := StrReplace(StrReplace(togReplaceString, "`r`n", "`n"), "`n", myPilcrow . "`n")
        togReplaceString := StrReplace(togReplaceString, A_Space, myDot)
        togReplaceString := StrReplace(togReplaceString, A_Tab, myTab)
        hhReplacementEdit.value := togReplaceString
        hhReplacementEdit.Opt("+Readonly")
        hhAppendButton.Enabled := false
        hh.Show('Autosize yCenter')
    }
    If (hh['SymTog'].text = "- Symbols")
    {
        hh['SymTog'].text := "+ Symbols"
        togReplaceString := hhReplacementEdit.text
        togReplaceString := StrReplace(togReplaceString, myPilcrow . "`r", "`r")
        togReplaceString := StrReplace(togReplaceString, myDot, A_Space)
        togReplaceString := StrReplace(togReplaceString, myTab, A_Tab)
        hhReplacementEdit.value := togReplaceString
        hhReplacementEdit.Opt("-Readonly")
        hhAppendButton.Enabled := true
        hh.Show('Autosize yCenter')
    }
    return
}

hhTriggerChangedHandler(*)
{
    Global triggerBeforeThisTrim
    Global triggerAfterThisTrim

    triggerAfterThisTrim := hhTriggerEdit.text

    If (triggerAfterThisTrim != triggerBeforeThisTrim && ExamPaneOpen = 1)
    {
        If (triggerBeforeThisTrim = SubStr(triggerAfterThisTrim, 2,))
        {
            tArrStep.push(hhTriggerEdit.text)
            rArrStep.push(hhReplacementEdit.text)
            hhReplacementEdit.Value := SubStr(triggerAfterThisTrim, 1, 1) . hhReplacementEdit.text
        }
        If (triggerBeforeThisTrim = SubStr(triggerAfterThisTrim, 1, StrLen(triggerAfterThisTrim) - 1))
        {
            tArrStep.push(hhTriggerEdit.text)
            rArrStep.push(hhReplacementEdit.text)
            hhReplacementEdit.text := hhReplacementEdit.text . SubStr(triggerAfterThisTrim, -1,)
        }
        triggerBeforeThisTrim := triggerAfterThisTrim
    }
    hhUndoButton.Enabled := true
    hhActivateFilterHandler()
}

hhSaveAsFunctionHandler(*)
{
    If (hhMakeFunctionToggle.Value = 1)
    {
        hhOptionsEdit.text := "B0X" StrReplace(StrReplace(hhOptionsEdit.text, "B0", ""), "X", "")
        ;soundbeep 700, 200
    }
    else
    {
        hhOptionsEdit.text := StrReplace(StrReplace(hhOptionsEdit.text, "B0", ""), "X", "")
        ;soundbeep 900, 200
    }
}

hhAppendHandler(*)
{
    Global tMyDefaultOpts := hhOptionsEdit.text
    Global tTriggerString := hhTriggerEdit.text
    Global tReplaceString := hhReplacementEdit.text

    CombinedValidMsg := ValidationFunction(tMyDefaultOpts, tTriggerString, tReplaceString)

    If (!InStr(CombinedValidMsg, "-Okay.", , , 3))
        biggerMsgBox(CombinedValidMsg, 1)
    else
    {
        Appendit(tMyDefaultOpts, tTriggerString, tReplaceString)
        return
    }
}

hhCheckHandler(*)
{
    Global tMyDefaultOpts := hhOptionsEdit.text
    Global tTriggerString := hhTriggerEdit.text
    Global tReplaceString := hhReplacementEdit.text
    CombinedValidMsg := ValidationFunction(tMyDefaultOpts, tTriggerString, tReplaceString)
    biggerMsgBox(CombinedValidMsg, 0)
    Return
}

biggerMsgBox(thisMess, secondButt)
{
    Global mbTitle := ""

    A_Clipboard := thisMess

    if (IsObject(bb))
        bb.Destroy()

    bb := Gui(, 'Validity Report')
    bb.SetFont('s11 ' hhFontColor)
    bb.BackColor := hhGUIColor, hhGUIColor

    (mbTitle := bb.Add('Text', , 'For proposed new item:')).Focus()

    bb.SetFont(myBigFont)
    proposedHS := ':' tMyDefaultOpts ':' tTriggerString '::' tReplaceString
    bb.Add('Text', (strLen(proposedHS) > 90 ? 'w600 ' : '') 'xs yp+22', proposedHS)

    bb.SetFont('s11 ')
    secondButt = 0 ? bb.Add('Text', , "===Validation Check Results===") : ''

    bb.SetFont(myBigFont)
    arrayBBItem := StrSplit(thisMess, "*|*")
    bbItem2 := (InStr(arrayBBItem[2], "`n", , , 10))
        ? subStr(arrayBBItem[2], 1, inStr(arrayBBItem[2], "`n", , , 10)) "`n## Too many conflicts to show in form ##"
            : arrayBBItem[2]

    edtSharedSettings := ' -VScroll ReadOnly -E0x200 Background'

    bb.Add('Edit', (inStr(arrayBBItem[1], '-Okay.') ? myGreen : myRed) edtSharedSettings hhGUIColor, arrayBBItem[1])
    trigEdtBox := bb.Add('Edit', (strLen(bbItem2) > 104 ? ' w600 ' : ' ') (inStr(bbItem2, '-Okay.') ? myGreen : myRed) edtSharedSettings hhGUIColor, bbItem2)

    bb.Add('Edit', (strLen(arrayBBItem[3]) > 104 ? ' w600 ' : ' ') (inStr(arrayBBItem[3], '-Okay.') ? myGreen : myRed) edtSharedSettings hhGUIColor, arrayBBItem[3])
    trigEdtBox.OnEvent('Focus', findInScript)

    bb.SetFont('s11 ' hhFontColor)
    (secondButt = 1) ? bb.Add('Text', , "==============================`nAppend HotString Anyway?") : ''

        bbAppend := bb.Add('Button', , 'Append Anyway')
        bbAppend.OnEvent 'Click', (*) => Appendit(tMyDefaultOpts, tTriggerString, tReplaceString)
        bbAppend.OnEvent 'Click', (*) => bb.Destroy()

        if (secondButt != 1)
            bbAppend.Visible := False

        bbClose := bb.Add('Button', 'x+5 Default', 'Close')
        bbClose.OnEvent 'Click', (*) => bb.Destroy()

        If not inStr(bbItem2, '-Okay.')
            Global bbAuto := bb.Add('Checkbox', 'x+5 Checked' AutoLookupFromValidityCheck, 'Auto Lookup`nin editor')

        bb.Show('yCenter x' (A_ScreenWidth / 2))

        WinSetAlwaysontop(1, "A")

        bb.OnEvent 'Escape', (*) => bb.Destroy()
}

findInScript(*)
{
    Global filenameThisScript
    Global pathDefaultEditor

    A_Clipboard := ""

    If (bbAuto.Value = 0)
        Return
    ;soundbeep
    if (GetKeyState("LButton", "P"))
        KeyWait "LButton", "U"
    SendInput "^c"
    If !ClipWait(1, 0)
        Return

    if WinExist(filenameThisScript)
        WinActivate
    else
    {
        Run('"' pathDefaultEditor "' '" filenameThisScript "'")
        runSuccess := WinWait(filenameThisScript, , 5)
        If (runSuccess = 0)
            Msgbox("Failed to open " filenameThisScript " in your editor.")
        WinActivate(filenameThisScript)
    }
    If RegExMatch(A_Clipboard, "^\d{2,}")
        SendInput "^g" . A_Clipboard
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
    Global validHotDupes := ""
    Global validHotMisspells := ""
    Global ACitemsStartAt

    hhActivateFilterHandler()

    validOpts := ""
    validHot := ""
    validRep := ""
    ThisFile := Fileread(A_ScriptName)

    validOpts := (tMyDefaultOpts = "") ? "Okay." : CheckOptions(tMyDefaultOpts)

    If (tTriggerString = "") || (tTriggerString = myPrefix) || (tTriggerString = mySuffix)
        validHot := "HotString box should not be empty."
    Else If InStr(tTriggerString, ":")
        validHot := "Don't include colons."
    Else
    {
        Loop Parse, ThisFile, "`n", "`r"
        {
            If (A_Index < ACitemsStartAt) or (SubStr(trim(A_LoopField, " `t"), 1, 1) != ":")
                continue
            If RegExMatch(A_LoopField, "i):(?P<Opts>[^:]+)*:(?P<Trig>[^:]+)", &loo)
            {
                validHotDupes .= CheckDupeTriggers(A_Index, A_Loopfield, tTriggerString, tMyDefaultOpts, loo.Trig, loo.Opts)
                validHotDupes .= CheckMiddleConflicts(A_Index, A_Loopfield, tTriggerString, tMyDefaultOpts, loo.Trig, loo.Opts)
                validHotDupes .= CheckPotentialMiddleConflicts(A_Index, A_Loopfield, tTriggerString, tMyDefaultOpts, loo.Trig, loo.Opts)
                validHotDupes .= CheckPotentialBeginningEndConflicts(A_Index, A_Loopfield, tTriggerString, tMyDefaultOpts, loo.Trig, loo.Opts)
                validHotDupes .= CheckWordBeginningConflicts(A_Index, A_Loopfield, tTriggerString, tMyDefaultOpts, loo.Trig, loo.Opts)
                validHotDupes .= CheckWordEndingConflicts(A_Index, A_Loopfield, tTriggerString, tMyDefaultOpts, loo.Trig, loo.Opts)
                continue
            }
            Else
            {
                Continue
            }
        }
    }

    validRep := (tReplaceString = "")
        ? "Replacement string box should not be empty."
            : (SubStr(tReplaceString, 1, 1) = ":")
                ? "Don't include the colons."
                : (tReplaceString = tTriggerString)
                    ? "Replacement string SAME AS Trigger string."
                    : "Okay."

    CombinedValidMsg := "OPTIONS BOX `n-"
        . validOpts
        . "*|*HOTSTRING BOX `n-"
        . validHot
        . "*|*REPLACEMENT BOX `n-"
        . validRep

    Return CombinedValidMsg

}

CheckOptions(tMyDefaultOpts)
{
    NeedleRegEx := "(\*|B0|\?|SI|C|K[0-9]{1,3}|SE|X|SP|O|R|T)"
    WithNeedlesRemoved := RegExReplace(tMyDefaultOpts, NeedleRegEx, "")
    If (WithNeedlesRemoved = "")
        return "Okay."
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
        return "Invalid Hotsring Options found.`n---> " WithNeedlesRemoved "`n" OptTips
    }
}

CheckDupeTriggers(LineNum, Line, newTrigger, newOptions, loopTrigger, loopOptions)
{
    Return ((newTrigger = loopTrigger) && (newOptions = loopOptions))
        ? "`nDuplicate trigger string found at line " LineNum ".`n---> " Line
        : ""
}

CheckMiddleConflicts(LineNum, Line, newTrigger, newOptions, loopTrigger, loopOptions)
{
    Return ((InStr(loopTrigger, newTrigger) and inStr(loopOptions, "*") and inStr(loopOptions, "?"))
        || (InStr(newTrigger, loopTrigger) and inStr(newOptions, "*") and inStr(newOptions, "?")))
        ? "`nWord-Middle conflict found at line " LineNum ", where one of the strings will be nullified by the other.`n---> " Line
        : ""
}

CheckPotentialMiddleConflicts(LineNum, Line, newTrigger, newOptions, loopTrigger, loopOptions)
{
    Return ((loopTrigger = newTrigger) and inStr(loopOptions, "*") and not inStr(loopOptions, "?") and inStr(newOptions, "?") and not inStr(newOptions, "*"))
    || ((loopTrigger = newTrigger) and inStr(loopOptions, "?") and not inStr(loopOptions, "*") and inStr(newOptions, "*") and not inStr(newOptions, "?"))
        ? "`nDuplicate trigger found at line " LineNum ", but maybe okay, because one is word-beginning and other is word-ending.`n---> " Line
        : ""
}

CheckPotentialBeginningEndConflicts(LineNum, Line, newTrigger, newOptions, loopTrigger, loopOptions)
{
    Return ((inStr(loopOptions, "*") and (loopTrigger = subStr(newTrigger, 1, strLen(loopTrigger))))
        || (inStr(newOptions, "*") and (newTrigger = subStr(loopTrigger, 1, strLen(newTrigger)))))
        ? "`nWord Beginning conflict found at line " LineNum ", where one of the strings is a subset of the other.  Whichever appears last will never be expanded.`n---> " Line
        : ""
}

CheckWordBeginningConflicts(LineNum, Line, newTrigger, newOptions, loopTrigger, loopOptions)
{
    Return ((inStr(loopOptions, "?") and loopTrigger = subStr(newTrigger, -strLen(loopTrigger)))
        || (inStr(newOptions, "?") and newTrigger = subStr(loopTrigger, -strLen(newTrigger))))
        ? "`nWord Ending conflict found at line " LineNum ", where one of the strings is a superset of the other.  The longer of the strings should appear before the other, in your code.`n---> " Line
        : ""
}

CheckWordEndingConflicts(LineNum, Line, newTrigger, newOptions, loopTrigger, loopOptions)
{
    Return ((inStr(loopOptions, "?") and loopTrigger = subStr(newTrigger, -strLen(loopTrigger)))
        || (inStr(newOptions, "?") and newTrigger = subStr(loopTrigger, -strLen(newTrigger))))
        ? "`nWord Ending conflict found at line " LineNum ", where one of the strings is a superset of the other.  The longer of the strings should appear before the other, in your code.`n---> " Line
        : ""
}

Appendit(tMyDefaultOpts, tTriggerString, tReplaceString)
{
    Global pathThisScript
    Global rMatches
    Global tMatches
    Global AutoCommentFixesAndMisspells
    Global aComStr
    Global tComStr
    Global AutoEnterNewEntry

    WholeStr := ""
    tComStr := ""
    aComStr := ""

    tMyDefaultOpts := hhOptionsEdit.text
    tTriggerString := hhTriggerEdit.text
    tReplaceString := hhReplacementEdit.text

    If (rMatches > 0) and (AutoCommentFixesAndMisspells = 1)
    {
        Misspells := ""
        Misspells := hhTriggerMatchesEdit.Value
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
    If ((StrLen(tTriggerString) - StrLen(StrReplace(tTriggerString, " ")) > 2) || InStr(tReplaceString, "`n"))
        IsMultiLine := 1
    If (hhMakeFunctionToggle.Value = 1) and (IsMultiLine = 0)
    {
        tMyDefaultOpts := "B0X" . StrReplace(tMyDefaultOpts, "B0X", "")
        fopen := 'f("'
        fclose := '")'
    }

    If (hhCommentEdit.text != "") || (aComStr != "")
        tComStr := " `; " . aComStr . hhCommentEdit.text

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
        ;soundbeep 800, 200
        ;soundbeep 700, 300
    }
    else
    {
        FileAppend("`n" WholeStr, pathThisScript)
        If (AutoEnterNewEntry = 1)
            ChangeActiveEditField(targetWindow)
        If not getKeyState("Ctrl")
            Reload()
    }
}

ChangeActiveEditField(*)
{
    Global origTriggerTypo := trim(origTriggerTypo)

    Send("^c")
    Errorlevel := !ClipWait(0.3)

    hasSpace := (subStr(A_Clipboard, -1) = " ") ? " " : ""
    A_Clipboard := trim(A_Clipboard)

    If (origTriggerTypo = A_Clipboard) and (origTriggerTypo = hhTriggerEdit.text)
    {
        If (bb != 0)
            bb.Hide()
        hh.Hide()
        WinWaitActive(targetWindow)
        Send(hhReplacementEdit.text hasSpace)
    }
}

hhSpellHandler(*)
{
    Global tReplaceString

    tReplaceString := hhReplacementEdit.text
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
                hhReplacementEdit.value := googleSugg
                hhActivateFilterHandler()
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

hhButtonOpenHandler(*)
{
    Global hh
    Global pathDefaultEditor
    Global filenameThisScript
    Global ClipboardOld

    hh.Hide()
    A_Clipboard := ClipboardOld
    Try
        Run("'" pathDefaultEditor "' '" filenameThisScript "'")
    Catch
        Try
            Run("'" pathDefaultEditor "' '" A_ScriptFullPath "'")
        Catch
            msgbox 'cannot run ' filenameThisScript
    WinWaitActive(filenameThisScript)
    Sleep(1000)
    Send("{Ctrl Down}{End}{Ctrl Up}{Home}")
}

hhWordlistHandler(*)
{
    Global filenameWordlist
    Global pathWordList
    Global pathDefaultEditor
    Global filenameThisScript
    Global ClipboardOld

    hh.Hide()
    A_Clipboard := ClipboardOld
    Try
        Run pathDefaultEditor " " filenameThisScript
    Catch
        msgbox 'cannot run ' filenameThisScript
    WinWaitActive(filenameThisScript)
    Sleep(1000)
    SendInput "^f"
    Sleep(100)
    SendInput filenameWordlist
    Sleep(250)
    Run strReplace(pathWordList, "\" . filenameWordlist, "")
}

hhButtonCancelHandler(*)
{
    Global hh
    Global hhTriggerEdit := ""
    Global hhReplacementEdit := ""
    Global ClipboardOld
    Global tArrStep
    Global rArrStep

    hh.Hide()
    hhOptionsEdit.value := ""
    tArrStep := []
    rArrStep := []
    A_Clipboard := ClipboardOld
}

hhTrimLeftHandler(*)
{
    tText := hhTriggerEdit.value
    tArrStep.push(tText)
    tText := subStr(tText, 2)
    hhTriggerEdit.value := tText
    rText := hhReplacementEdit.value
    rArrStep.push(rText)
    rText := subStr(rText, 2)
    hhReplacementEdit.value := rText
    hhUndoButton.Enabled := true
    hhTriggerChangedHandler()
}

hhTrimRightHandler(*)
{
    tText := hhTriggerEdit.value
    tArrStep.push(tText)
    tText := subStr(tText, 1, strLen(tText) - 1)
    hhTriggerEdit.value := tText
    rText := hhReplacementEdit.value
    rArrStep.push(rText)
    rText := subStr(rText, 1, strLen(rText) - 1)
    hhReplacementEdit.value := rText
    hhUndoButton.Enabled := true
    hhTriggerChangedHandler()
}

hhUndoHandler(*)
{
    If GetKeyState("Shift")
        GoReStart()
    else If (tArrStep.Length > 0) and (rArrStep.Length > 0)
    {
        hhTriggerEdit.value := tArrStep.Pop()
        hhReplacementEdit.value := rArrStep.Pop()
        hhActivateFilterHandler()
    }
    else
    {
        hhUndoButton.Enabled := false
    }
}
GoReStart(*)
{
    Global triggerBeforeTrimming
    Global replacementBeforeTrimming
    Global tArrStep
    Global rArrStep

    If !triggerBeforeTrimming and !OrigReplacment
    {
        MsgBox("Can't restart -- Nothing in memory...")
    }
    Else
    {
        hhTriggerEdit.Value := triggerBeforeTrimming
        hhReplacementEdit.Value := replacementBeforeTrimming
        hhUndoButton.Enabled := false
        tArrStep := []
        rArrStep := []
        hhActivateFilterHandler()
    }
}

clickLast := 0
hhActivateMiddleHandler(*)
{
    Global clickCurrent := A_TickCount
    if (clickCurrent - clickLast < 500)
    {
        hhMiddleRadio.Value := 0
        hhOptionsEdit.text := strReplace(strReplace(hhOptionsEdit.text, "?", ""), "*", "")
    }
    Global clickLast := A_TickCount
    hhActivateFilterHandler()
}

hhActivateFilterHandler(ViaExamButt := "No", *)
{
    Global rMatches := 0
    Global tMatches := 0
    Global pathWordList
    Global hhFontColor
    Global hhReplacementEdit

    hhCurrentOptions := hhOptionsEdit.text

    hhCurrentTrigger := Trim(hhTriggerEdit.Value)
    hhCurrentTrigger := (hhCurrentTrigger != "") ? hhCurrentTrigger : " "

    rFind := Trim(hhReplacementEdit.Value, "`n`t ")
    rFind := (rFind != "") ? rFind : " "

    tFilt := ''
    rFilt := ''

    If (ViaExamButt = "Yes")
    {
        hhMiddleRadio.value := (inStr(hhCurrentOptions, "*") and inStr(hhCurrentOptions, "?")) ? 1 : 0
        hhBeginRadio.value := (inStr(hhCurrentOptions, "*") and !InStr(hhCurrentOptions, "?")) ? 1 : 0
        hhEndRadio.value := (!InStr(hhCurrentOptions, "*") and InStr(hhCurrentOptions, "?")) ? 1 : 0
    }

    Loop Read, pathWordList
    {
        If InStr(A_LoopReadLine, hhCurrentTrigger)
        {
            switch
            {
            case (hhMiddleRadio.value = 1):
                tFilt .= A_LoopReadLine '`n'
                tMatches++
            case (hhEndRadio.value = 1 && InStr(SubStr(A_LoopReadLine, -StrLen(hhCurrentTrigger)), hhCurrentTrigger)):
                tFilt .= A_LoopReadLine '`n'
                tMatches++
            case (hhBeginRadio.value = 1 && InStr(SubStr(A_LoopReadLine, 1, StrLen(hhCurrentTrigger)), hhCurrentTrigger)):
                tFilt .= A_LoopReadLine '`n'
                tMatches++
            case (A_LoopReadLine = hhCurrentTrigger):
                tFilt := hhCurrentTrigger
                tMatches++
            }
        }
    }

    if (hhMiddleRadio.value = 1)
    {
        hhCurrentOptions := hhCurrentOptions . "*?"
    }
    else if (hhEndRadio.value = 1)
    {
        hhCurrentOptions := StrReplace(hhCurrentOptions, "*", "")
        hhCurrentOptions := "?" . hhCurrentOptions
    }
    else if (hhBeginRadio.value = 1)
    {
        hhCurrentOptions := StrReplace(hhCurrentOptions, "?", "")
        hhCurrentOptions := (InStr(hhCurrentOptions, "*")) ? hhCurrentOptions : "*" . hhCurrentOptions
    }
    if (inStr(hhCurrentOptions, "**"))
        msgbox("Invalid Options: " hhCurrentOptions "`n`nPlease correct the options and try again.", 4096)

    hhOptionsEdit.text := hhCurrentOptions

    hhTriggerMatchesEdit.Value := tFilt
    hhMisspellsListLabel.Text := "Misspells [" . tMatches . "]"

    hhTriggerLabel.Text := (tMatches > 0) ? "Misspells [" . tMatches . "] words" : "No Misspellings found."
    hhTriggerLabel.SetFont((tMatches > 0) ? "cRed" : hhFontColor)

    Loop Read pathWordList
    {
        If InStr(A_LoopReadLine, rFind)
        {
            switch
            {
            case (hhMiddleRadio.value = 1):
                rFilt .= A_LoopReadLine "`n"
                rMatches++
            case (hhEndRadio.value = 1 && InStr(SubStr(A_LoopReadLine, -StrLen(rFind)), rFind)):
                rFilt .= A_LoopReadLine "`n"
                rMatches++
            case (hhBeginRadio.value = 1 && InStr(SubStr(A_LoopReadLine, 1, StrLen(rFind)), rFind)):
                rFilt .= A_LoopReadLine "`n"
                rMatches++
            case (A_LoopReadLine = rFind):
                rFilt := rFind
                rMatches++
            }
        }
    }

    hhReplacementMatchesEdit.Value := rFilt
    hhCorrectsListLabel.Text := "Fixes [" . rMatches . "]"
}

#HotIf WinActive(filenameThisScript)
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
handleEditScript(*)
{
    Global pathDefaultEditor
    Global filenameThisScript
    
    Try
        Run('"' pathDefaultEditor '" "' filenameThisScript '"')
    Catch
        try
            Run('"' pathDefaultEditor '" "' A_ScriptFullPath '"')
        Catch
            Msgbox 'cannot run ' filenameThisScript
}

+!p::
handlePrinterTool(*)
{
    Global df := ""
    Global printerlist := ""

    defaultPrinter := RegRead("HKCU\Software\Microsoft\Windows NT\CurrentVersion\Windows", "Device")

    pfontColor := hhFontColor

    Loop Reg, "HKCU\Software\Microsoft\Windows NT\CurrentVersion\devices"
        printerlist := printerlist . "" . A_loopRegName . "`n"

    df := Gui()
    df.Title := "Default Printer Changer"
    df.BackColor := hhGUIColor

    df.SetFont("s12 bold c" . pFontColor)
    df.Add("Text", , "Set A Default Printer ...")
    df.OnEvent("Close", ButtonCancel)
    df.OnEvent("Escape", ButtonCancel)

    df.SetFont("s11")
    printerlist := SubStr(printerlist, 1, strlen(printerlist) - 2)
    Loop Parse, printerlist, "`n"
        df.AddRadio((InStr(defaultPrinter, A_LoopField) ? "checked " : "") . "vRadio" . a_index, a_loopfield)

    df.AddButton("default", "Set Printer").OnEvent("Click", ButtonSet)
    df.AddButton("x+10", "Print &Queue").OnEvent("Click", ButtonQue)
    df.AddButton("x+10", "Control Panel").OnEvent("Click", ButtonCtrlPanel)
    df.AddButton("x+10", "Cancel").OnEvent("Click", ButtonCancel)

    df.Show()
}

ButtonSet(*)
{
    Global df
    Global printerList

    Loop Parse, printerlist, "`n"
    {
        thisRadioVal := df["Radio" . a_index].value
        If thisRadioVal != 0
            newDefault := a_loopfield
    }
    RunWait("C:\Windows\System32\RUNDLL32.exe PRINTUI.DLL, PrintUIEntry /y /n '" newDefault "'")
    df.Destroy()
}

ButtonQue(*)
{
    Global df
    Global PrinterList

    viewThis := ""
    Loop Parse, printerlist, "`n"
    {
        thisRadioVal := df["Radio" . a_index].value
        If thisRadioVal != 0
            viewThis := a_loopfield
    }
    RunWait("rundll32 printui.dll, PrintUIEntry /o /n '" viewThis "'")
    df.Destroy()
}

ButtonCtrlPanel(*)
{
    Global df
    Global PrinterList

    Run("control printers")
    df.Destroy()
    printerlist := ""
}

ButtonCancel(*)
{
    Global df
    Global PrinterList

    df.Destroy()
    printerlist := ""
}

!+u::
handleUptime(*)
{
    MsgBox("handleUptime is:`n" . handleUptime(A_TickCount))
    handleUptime(ms)
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

; fix_consecutive_caps()
; fix_consecutive_caps()
; {
;     HotIf (*) => !GetKeyState("CapsLock", "T")
;     loop 26
;     {
;         char1 := Chr(A_Index + 64)
;         loop 26
;         {
;             char2 := Chr(A_Index + 64)
;             Hotstring(":*?CXB0Z:" char1 char2, fix.Bind(char1, char2))
;         }
;     }
;     HotIf
;     fix(char1, char2, *)
;     {
;         ih := InputHook("V I101 L1 T.3")
;         ih.OnEnd := OnEnd
;         ih.Start()
;         OnEnd(ih)
;         {
;             char3 := ih.Input
;             if (char3 ~= "[A-Z]")
;                 Hotstring "Reset"
;             else if (char3 ~= "[a-z]")
;                 || (char3 = A_Space && char1 char2 ~= "OF|TO|IN|IT|IS|AS|AT|WE|HE|BY|ON|BE|NO")
;             {
;                 SendInput("{BS 2}" StrLower(char2) char3)
;                 ;soundbeep(800, 80)
;             }
;         }
;     }
; }

!+F3:: MsgBox(lastTrigger, "Trigger", 0)

f(replace := "")
{

    Global lastTrigger
    Global ignorLen := 0
    Global KeepForLog := ""

    static HSInputBuffer := InputBuffer()

    trigger := A_ThisHotkey
    endchar := A_EndChar

    HSInputBuffer.Start()

    lastTrigger := StrReplace(trigger, "B0X", "") "::" replace

    trigger := SubStr(trigger, inStr(trigger, ":", , , 2) + 1)
    TrigLen := StrLen(trigger) + StrLen(endchar)

    arrayTrig := StrSplit(trigger)
    arrayRepl := StrSplit(replace)
    Loop Min(arrayTrig.Length, arrayRepl.Length)
    {
        If (arrayTrig[A_Index] == arrayRepl[A_Index])
            ignorLen++
        else
            break
    }
    If (endChar = " " && InStr(lastTrigger, "?") )
    {
        If (inStr(lastTrigger,"?"))
            ignorLen += 2
    }
        ignorLen++
    bsCount := TrigLen - ignorLen
    replace := (ignorLen > 0) ? SubStr(replace, ignorLen) : replace
    SendInput("{BS " . bsCount . "} " . replace . " " . endchar)
    HSInputBuffer.Stop()

    ; KeepForLog := LastTrigger "`n"
    ; SetTimer(keepText, -1)
}

#MaxThreadsPerHotkey 5
keepText(*)
{
    Global savedUpText
    Global intervalCounter
    Global logIsRunning
    Global saveIntervalMinutes
    Global KeepForLog

    CtrlZ := Chr(26)
    EndKeys := "{Backspace}," CtrlZ
    lih := InputHook("B V I1 E M T1", EndKeys)

    lih.Start()
    lih.Wait()

    hyphen := (lih.EndReason = "EndKey") ? " << " : " -- "
    savedUpText .= A_YYYY "-" A_MM "-" A_DD "`t`t" hyphen "`t`t" KeepForLog
    intervalCounter := 0
    If logIsRunning = 0
        setTimer Appender, saveIntervalMinutes
}
#MaxThreadsPerHotkey 1

Appender(*)
{
    Global savedUpText
    Global logIsRunning
    Global intervalCounter
    Global filenameACLogger
    Global IntervalsBeforeStopping

    FileAppend(savedUpText, filenameACLogger)
    savedUpText := ''
    logIsRunning := 1
    intervalCounter += 1
    If (intervalCounter >= IntervalsBeforeStopping)
    {
        setTimer Appender, 0
        intervalCounter := logIsRunning := 0
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
        SendLevel(this.SendLevel - 1)
        while this.Buffer.Length
        {
            key := this.Buffer.RemoveAt(1)
            sent.Push(key)
            ;if (InStr(key, "Home") || InStr(key, "Shift") || InStr(Key, "Ctrl"))
             ;   msgbox(key " is key from release of buffer")
            Send(key)
        }
        SendLevel(PrevSendLevel)
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
hhStringsAndFixesHandler(*)
{
    ThisFile := FileRead(A_ScriptFullPath)
    thisOptions := '', regulars := 0, begins := 0, middles := 0, ends := 0, fixes := 0, entries := 0
    Loop Parse ThisFile, '`n'
    {
        If (SubStr(Trim(A_LoopField), 1, 1) = ':')
        {
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
    }
    ends := numberFormat(ends)
    begins := numberFormat(begins)
    middles := numberFormat(middles)
    regulars := numberFormat(regulars)
    entries := numberFormat(entries)
    fixes := numberFormat(fixes)

    MsgBox('   Totals`n==========================='
        '`n    Regular Autocorrects:`t' regulars
        '`n    Word Beginnings:`t`t' begins
        '`n    Word Middles:`t`t' middles
        '`n    Word Ends:`t`t' ends
        '`n==========================='
        '`n   Total Entries:`t`t' entries
        '`n   Potential Fixes:`t`t' fixes
        , 'Report for ' A_ScriptName, 64 + 4096)

}

numberFormat(num)
{
    parts := StrSplit(num, ",")
    if (parts.Length() > 1)
    {
        intPart := parts[1]
        decimalPart := parts[2]
        formattedIntPart := RegExReplace(intPart, "(\d)(?=(\d{3})+$)", "$1,")
        return formattedIntPart "." decimalPart
    }
    else
    {
        return RegExReplace(num, "(\d)(?=(\d{3})+$)", "$1,")
    }
}

UnzipFile(file, folder := "")
{
    if (folder = "")
        folder := A_ScriptDir

    RunWait("powershell -command Expand-Archive -Path " file " -DestinationPath " folder)
}

CopyFilesAndFolders(SourcePattern, DestinationFolder, DoOverwrite := false)
{
    ErrorCount := 0
    try
        FileCopy SourcePattern, DestinationFolder, DoOverwrite
    catch as Err
        ErrorCount := Err.Extra
    Loop Files, SourcePattern, "D"
    {
        try
            DirCopy A_LoopFilePath, DestinationFolder "\" A_LoopFileName, DoOverwrite
        catch
        {
            ErrorCount += 1
            MsgBox "Could not copy " A_LoopFilePath " into " DestinationFolder
        }
    }
    return ErrorCount
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

#INCLUDE "%A_ScriptDir%\Lib\UserHotstringFile.ahk"