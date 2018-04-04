'------------------------------------------------------------------------------
'Purpose  : Wait for the specified amount of seconds (or keypress)
'
'Prereq.  : -
'Note     : -
'
'   Author: Knuth Konrad 02.05.2017
'   Source: -
'  Changed: -
'------------------------------------------------------------------------------
#Compile Exe "STAWait.exe"
#Option Version5
#Dim All

#Link "baCmdLine.sll"

#Break On
#Debug Error Off
#Tools Off

DefLng A-Z

%VERSION_MAJOR = 1
%VERSION_MINOR = 0
%VERSION_REVISION = 3

' Version Resource information
#Include ".\WaitRes.inc"
'------------------------------------------------------------------------------
'*** Constants ***
'------------------------------------------------------------------------------
' Console colors
%Green = 2
%Red = 4
%White = 7
%Yellow = 14
%LITE_GREEN = 10
%LITE_RED = 12
%INTENSE_WHITE = 15

$WAIT_PREFIX = "Waiting for another "
'------------------------------------------------------------------------------
'*** Enumeration/TYPEs ***
'------------------------------------------------------------------------------
Type AppCfgTYPE
   Seconds As Long
   Key As String * 1
   IsKey As Byte
   MinSeconds As Long
End Type
'------------------------------------------------------------------------------
'*** Declares ***
'------------------------------------------------------------------------------
#Include Once "win32api.inc"
#Include "sautilcc.inc"
'------------------------------------------------------------------------------
'*** Variabels ***
'------------------------------------------------------------------------------
' Application config (CLI parameters)
Global gudtCfg As AppCfgTYPE
'==============================================================================

Function PBMain () As Long
'------------------------------------------------------------------------------
'Purpose  : Programm startup method
'
'Prereq.  : -
'Parameter: -
'Returns  : -
'Note     : -
'
'   Author: Knuth Konrad 02.05.2017
'   Source: -
'  Changed: -
'------------------------------------------------------------------------------
   Local oPTNow As IPowerTime
   Let oPTNow = Class "PowerTime"

   ' Application intro
   ConHeadline "Wait", %VERSION_MAJOR, %VERSION_MINOR, %VERSION_REVISION
   ConCopyright "2017", $COMPANY_NAME
   Con.StdOut ""

   ' Debug Info
   Trace New "Wait_" & FormatDate("yyyyMMdd") & "_" & FormatTime("HHmmss") & ".tra"
   Trace On

   ' *** Parse the parameters
   ' Initialization and basic checks
   Local sCmd As String
   sCmd = Command$

   Local o As IBACmdLine
   Local i As Long
   Local vnt As Variant

   Let o = Class "cBACmdLine"

   If IsFalse(o.Init(sCmd)) Then
      Print "Couldn't parse parameters: " & sCmd
      Print "Type Wait /? for help"
      Let o = Nothing
      Exit Function
   End If

   If Len(Trim$(Command$)) < 1 Or InStr(Command$, "/?") > 0 Then
      ShowHelp
      Exit Function
   End If

   ' Parse the passed parameters
   ' Valid CLI parameters are:
   ' /t= or /time=
   ' /m= or /minimum=
   ' /k= or /key=
   i = o.ValuesCount

   If i > 3 Then
      Print "Invalid number of parameters."
      Print ""
      Let o = Nothing
      ShowHelp
      Exit Function
   End If

   ' Parse CLI parameters
   Local sTemp As String
   Local vntResult As Variant

   ' ** Time
   If IsTrue(o.HasParam("t", "time")) Then
      vntResult = o.GetValueByName("t", "time")
      Trace Print "Time Variant$(vntResult)     : " & Variant$(vntResult)
      Trace Print "Time Val(Variant$(vntResult)): " & Format$(Val(Variant$(vntResult)))
      gudtCfg.Seconds = Val(Variant$(vntResult))
      Trace Print "Time gudtCfg.Seconds     : " & Format$(gudtCfg.Seconds)
   End If

   ' ** Minimum time
   If IsTrue(o.HasParam("m", "minimum")) Then
      vntResult = o.GetValueByName("m", "minimum")
      Trace Print "Time Variant$(vntResult)     : " & Variant$(vntResult)
      Trace Print "Time Val(Variant$(vntResult)): " & Format$(Val(Variant$(vntResult)))
      gudtCfg.MinSeconds = Val(Variant$(vntResult))
      Trace Print "Time gudtCfg.MinSeconds     : " & Format$(gudtCfg.MinSeconds)
   End If

   ' ** Key to continue
   If IsTrue(o.HasParam("k", "key")) Then
      gudtCfg.Key = Variant$(o.GetValueByName("k", "key"))
      gudtCfg.IsKey = %True
   Else
      gudtCfg.IsKey = %False
   End If

   ' Echo the CLI parameters
   Call oPTNow.Now()
   Con.StdOut "Cur. date/time: " & oPTNow.DateString & ", " & oPTNow.TimeStringFull
   Con.StdOut "Wait time     : " & Format$(gudtCfg.Seconds) & " second(s)"
   Con.StdOut "Min. wait time: " & Format$(gudtCfg.MinSeconds) & " second(s)"
   Con.StdOut "Wait for key  : ";
   If IsFalse(gudtCfg.IsKey) Then
      Con.StdOut "n/a"
   Else
      Con.StdOut gudtCfg.Key
   End If

   Con.StdOut ""

   ' *** Basic parameter validation
   If IsFalse(ValidateParams()) Then
      ShowHelp
      PBMain = 0
      Exit Function
   End If

   Call SetProcessPriority(%BELOW_NORMAL_PRIORITY_CLASS)

   ' *** Start the timer ***
   Local sKeys As String
   Local oPTStart As IPowerTime

   Local lSign, lSeconds, lMinSeconds, lPrev As Long
   Local lRow, lCol As Long
   Local dwCount As Dword

   If IsTrue(gudtCfg.IsKey) Then
   ' A key(press) is defined, add both lower and uppercase to
   ' be recognized. And also add <Space> and <ESC>

      Let oPTStart = Class "PowerTime"

      Local sPressed, sMsg As String

      sKeys = LCase$(gudtCfg.Key) & UCase$(gudtCfg.Key) & Chr$(32) & Chr$(27)
      lRow = Con.Cell.Row

      Call oPTStart.Now()
      Con.Cursor.Off

      Con.StdOut $WAIT_PREFIX;
      Con.Color %INTENSE_WHITE, -1
      Con.StdOut Format$(gudtCfg.Seconds - lSeconds);
      Con.Color %White, -1
      Con.StdOut " second(s) or press ";
      Con.Color %Yellow, -1
      Con.StdOut gudtCfg.Key;
      Con.Color %White, -1
      Con.StdOut " to continue ...";

      lMinSeconds = gudtCfg.MinSeconds

      Do

         sPressed  = Con.InKey$

         Call oPTNow.Now()
         Call oPTNow.TimeDiff(oPTStart, lSign, ByVal 0&, ByVal 0&, ByVal 0&, lSeconds)

         If lPrev <> lSeconds Then

            Con.Cell = lRow, 1

            Con.StdOut $WAIT_PREFIX;
            Con.Color %INTENSE_WHITE, -1
            Con.StdOut Format$(gudtCfg.Seconds - lSeconds);
            Con.Color %White, -1
            Con.StdOut " second(s) or press ";
            Con.Color %Yellow, -1
            Con.StdOut gudtCfg.Key;
            Con.Color %White, -1
            Con.StdOut " to continue ...";

            lPrev = lSeconds

            ' Adjust/validate min. waiting time.
            If gudtCfg.MinSeconds = 0 Then
            ' No min. time defined, set min to current elapsed time = the exit condition will be true
               lMinSeconds = lPrev
            End If

            Trace Print "lSeconds   : " & Format$(lSeconds)
            Trace Print "lMinSeconds: " & Format$(lMinSeconds)
            Trace Print "lSign      : " & Format$(lSign)
            Trace Print "IsKey      : " & Format$(Tally(sPressed, Any sKeys) > 0)
            Trace Print String$(3, "-")

         End If

         Sleep 100

      Loop Until ((lSign >= 0) And (lSeconds >= gudtCfg.Seconds And lSeconds >= lMinSeconds)) Or (Tally(sPressed, Any sKeys) > 0 And lSeconds >= lMinSeconds)

      Con.StdOut " done.";
      If Len(sPressed) > 0 Then
         sMsg = " Key '"
         Select Case Asc(sPressed)
         Case 27
            ' ESC
            sMsg &= "<ESC>"
         Case 32
            ' Space
            sMsg &= "<SPACE>"
         Case Else
            sMsg &= sPressed
         End Select
         Con.StdOut  sMsg & "' pressed."
      Else
         Con.StdOut ""
      End If
      Con.Cursor.On

   Else
   ' No key defined, just wait the amout of seconds
      Let oPTStart = Class "PowerTime"

      lRow = Con.Cell.Row

      Call oPTStart.Now()
      Con.Cursor.Off

      Con.StdOut $WAIT_PREFIX;
      Con.Color %INTENSE_WHITE, -1
      Con.StdOut Format$(gudtCfg.Seconds - lSeconds);
      Con.Color %White, -1
      Con.StdOut " second(s) ...";

      Do

         Call oPTNow.Now()
         Call oPTNow.TimeDiff(oPTStart, lSign, ByVal 0&, ByVal 0&, ByVal 0&, lSeconds)

         If lPrev <> lSeconds Then

            Con.Cell = lRow, 1

            Con.StdOut $WAIT_PREFIX;
            Con.Color %INTENSE_WHITE, -1
            Con.StdOut Format$(gudtCfg.Seconds - lSeconds);
            Con.Color %White, -1
            Con.StdOut " second(s) ...";

            lPrev = lSeconds

         End If

         Sleep 100

      Loop Until (lSign >= 0) And (lSeconds >= gudtCfg.Seconds)

      Con.StdOut " done."
      Con.Cursor.On
   End If

   Call oPTNow.Now()
   Con.StdOut "Cur. date/time: " & oPTNow.DateString & ", " & oPTNow.TimeStringFull

   Trace Off
   Trace Close

   oPTNow = Nothing
   oPTStart = Nothing

End Function
'==============================================================================

Function ValidateParams() As Long
'------------------------------------------------------------------------------
'Purpose  : basic command line parameter validation
'
'Prereq.  : -
'Parameter: -
'Note     : -
'
'   Author: Knuth Konrad dd.mm.yyyy
'   Source: -
'  Changed: -
'------------------------------------------------------------------------------

   If (gudtCfg.MinSeconds > 0) And (gudtCfg.MinSeconds > gudtCfg.Seconds) Then

      Con.StdOut "Invalid time parameters - minimum wait time can't ge grater than wait time."
      Exit Function

   End If

   ' If we make it here, validation succeeded
   ValidateParams = %True

End Function
'==============================================================================

Sub ShowHelp

   Con.StdOut ""
   Con.StdOut "Wait"
   Con.StdOut "----"
   Con.StdOut "Wait a specified amount of seconds or (optionally) until certain keys are pressed."
   Con.StdOut ""
   Con.StdOut "Usage:   Wait /time=<number of seconds> [/key=<key to skip>] [/minimum=<minimum wait time although key was pressed>]"
   Con.StdOut "e.g.     Wait /t=10 /k=x"
   Con.StdOut "         Waits for 10 seconds or until 'x' is pressed. Upper/lower case doesn't matter."
   Con.StdOut "         In addition to 'x', <SPACE> and <ESC> are also recognized as valid keys."
   Con.StdOut ""
   Con.StdOut "Parameters"
   Con.StdOut "----------"
   Con.StdOut "/t or /time     = Number of seconds to wait"
   Con.StdOut "/k or /key      = Key to skip the pause"
   Con.StdOut "/m or /minimum  = Wait at least <minimum> numer of seconds, although a key is pressed"
   Con.StdOut "                  /k needs to be passed for /m to have any effect."
   Con.StdOut ""
   Con.StdOut "Please note: if no key is specified, the program can still be terminated by CTRL+BREAK."

End Sub
'---------------------------------------------------------------------------




' *** Function
'------------------------------------------------------------------------------
'Purpose  : -
'
'Prereq.  : -
'Parameter: -
'Returns  : -
'Note     : -
'
'   Author: Knuth Konrad dd.mm.yyyy
'   Source: -
'  Changed: -
'------------------------------------------------------------------------------

' *** Sub
'------------------------------------------------------------------------------
'Purpose  : -
'
'Prereq.  : -
'Parameter: -
'Note     : -
'
'   Author: Knuth Konrad dd.mm.yyyy
'   Source: -
'  Changed: -
'------------------------------------------------------------------------------
