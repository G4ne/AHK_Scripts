#NoEnv
#SingleInstance force
SetWorkingDir, A_InitialWorkingDir

;Figure out if the settings file exists, creating it or loading it depending on the result
if !FileExist("settings.txt") {

    settings_file := FileOpen("settings.txt", "w")
    settings_file.WriteLine("# Settings for AutoClicking software, please don't touch unless you know what you're doing.")
    settings_file.Write("0,,0,")
    ; Settings are stored as follows: keystroke time, key to be pressed, hold key or not, activation key

} else {

    settings_file := FileOpen("settings.txt", "r")
    settings_file.ReadLine() ;Skip the first line
    settings := StrSplit(settings_file.ReadLine(), ",")

    settings_wait_time := settings[1]
    settings_pressed_key := settings[2]
    settings_hold_button := settings[3]
    settings_start_key := settings[4]

    settings_file.Close()
}

clicker_on := False ;A variable to keep track of whether the program is running or not
old_start_key := "" ;Variable that holds the previously used start key so the old hotkey can be disabled
num_clicks := 0 ;Holds total num of clicks
time_elapsed = 00:00:00 ;Holds total time spent clicking

if (settings_start_key != "") { ;Sets up a hotkey with the key from the settings if there is a key stored in settings
    start_key := settings_start_key
    gosub set_hotkey ;Sets up a hotkey from the settings
}

Gui, MyGui:New ;Begin building Gui

Gui, MyGui:+LabelMyGui_ ;Creates custom labels to refer to the GUI if it is not the focused window

Gui, MyGui:Margin, 35, 10

Gui, MyGui:Add, Text, x30 y10, Input the amount of miliseconds between keystrokes.

Gui, MyGui:Add, Edit, vwait_time gsubmit_data w185 h20 x53 y30 ;Input box for the time between keystrokes

Gui, MyGui:Add, UpDown, w200 h30, %settings_wait_time% ;UpDown on the input box

Gui, MyGui:Add, Text, x42 y57, Input the key to be pressed.

Gui, MyGui:Add, Edit, vpressed_key gsubmit_data w150 h20 x35 y75, %settings_pressed_key% ;Text box used to capture the key to be pressed

Gui, MyGui:Add, Checkbox, vhold_button gsubmit_data Checked%settings_hold_button% x190 y75, Hold Button ;Checkbox for holding / not holding the key (True = hold, False = don't hold)

Gui, MyGui:Add, GroupBox, w240 h45 x30 y95 ;Box for grouping stats together

Gui, MyGui:Add, Text, w137 x35 y+-35, Number of Clicks: %num_clicks%

Gui, MyGui:Add, Text, w137 x35 y120, Time Elapsed: %time_elapsed%

Gui, MyGui:Add, Text, w80 x180 y103, Activation Key:

Gui, MyGui:Add, Hotkey, vstart_key gset_hotkey w90 h20 x173 y117, %settings_start_key% ;Hotkey box used to create the hotkey from user input

Gui, MyGui:Add, Button, gstart_stop_click w290 h35 x5 y145, Start ;Built-in button used to start and stop pressing the key

Gui, MyGui:Show, w300 h185 ;End building Gui and show it


=:: ;Close Script Hotkey
Gui, MyGui:Destroy
ExitApp

^/::WinActivate, ahk_exe AutoHotKeyU64.exe ;Bring Gui to the front

start_stop_click: ;Turns the program on when the start key is hit and turns it off if hit again
if (clicker_on == true) { ;If the program is already running, turn it off
    SetTimer, _Run, Off 
    SetTimer, _Timekeeping, Off 
    GuiControl, MyGui:, Stop, Start ;Changes the text on the button to start from stop
    Send % "{" pressed_key " up}" ;Releases pressed key
    clicker_on := false
    return
}
else { ;If the program isn't running, start running
    GuiControl, MyGui:, Start, Stop ;Changes the text on the button to stop from start
    clicker_on := true
    if (hold_button) { ;If hold is true, we wait a little longer on the timer so there is a noticable gap between held keystrokes
        long_wait := wait_time * 2
        gosub _Run ;Runs the autoclicker once while the timer is running to prevent an awkward waiting period before the first keystroke
        SetTimer, _Run, %long_wait% ;Loops _Run on a timer with double wait (for above reason)
    }
    else {
        gosub _Run ;Runs for the same reason as highlighted above
        SetTimer, _Run, %wait_time% ;Normal looping of _Run on a timer
    }
    SetTimer, _Timekeeping, 1000 ;starts timer
    return
}

set_hotkey: ;Sets the hotkey to the given key during runtime
Gui, Submit, NoHide
if (old_start_key != "") { ;Checks if old_start_key has been assigned a value (if it has then a hotkey has been created) and deletes the old hotkey
    Hotkey, %old_start_key%, Off
}
Hotkey, %start_key%, start_stop_click, On ;Creates a hotkey to activate the autoclicker
old_start_key := start_key
return

_Run: ;Wrapper label for the _Run function
_Run(wait_time, pressed_key, hold_button)
num_clicks++
GuiControl, MyGui:, Static3, Number of Clicks: %num_clicks%
return

submit_data: ;Updates Gui variables with their appropriate values and saves the values to the settings file
Gui, Submit, NoHide
settings_file := FileOpen("settings.txt", "rw")
settings_file.ReadLine() ; Skips first line
settings_file.Write(wait_time "," pressed_key "," hold_button "," start_key)
settings_file.Close()
return


_Run(waittime, pressed_key, hold) { ;Main function

    if (hold == True) { ;Holds down selected key
        Send % "{" pressed_key " down}"
        Sleep, waittime
        Send % "{" pressed_key " up}"
    }
    else { ;Presses the selected key
        Send % pressed_key
    }
    return
}

_Timekeeping: ;Used to update the time_elapsed variable
sec_passed++ ;This line might look weird because sec_passed is not defined before use, but blank variables are treated as 0, allowing its use before definition
min_passed := sec_passed // 60
hours_passed := min_passed // 60
final_sec := substr("00" . mod(sec_passed, 60), -1) ;Formats the numbers for display
final_min := substr("00" . mod(min_passed, 60), -1)
final_hr := substr("00" . hours_passed, -1)
time_elapsed = %final_hr%:%final_min%:%final_sec%
GuiControl, MyGui:, Static4, Time Elapsed: %time_elapsed%
return

MyGui_Close: ;Runs when the Gui is closed manually
ExitApp 