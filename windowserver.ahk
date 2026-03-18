#Requires AutoHotkey v2.0
#SingleInstance Force

global TempPS    := A_Temp "\ups_query.ps1"
global TempOut   := A_Temp "\ups_results.txt"
global IconPath  := A_ScriptDir "\planet.ico"


global UNIVERSE_URL := "https://raw.githubusercontent.com/jmxploits/universe-download-STARMAP/refs/heads/main/universe.json"

global JsonPath := A_ScriptDir "\universe.json"
if !FileExist(JsonPath) {
    JsonPath := A_Temp "\universe.json"
    if !FileExist(JsonPath) {
        _dlg := Gui("+AlwaysOnTop -Caption +ToolWindow", "")
        _dlg.BackColor := "1A0020"
        _dlg.SetFont("s9 cFFBB77", "Segoe UI")
        _dlg.Add("Text", "x16 y14 w260", "Downloading universe.json...")
        _dlg.Show("w292 h44")
        try {
            Download(UNIVERSE_URL, JsonPath)
        } catch _e {
            _dlg.Destroy()
            MsgBox("Download failed:`n" . _e.Message . "`n`nCheck UNIVERSE_URL in the script or place universe.json next to it.", "Download Error", 16)
            ExitApp()
        }
        _dlg.Destroy()
    }
}

global ResList   := ["Iron","Copper","Coal","Uranium","Diamond","Jade","Titanium","Beryllium","Aluminum","Gold","Lead"]

global StarNames := ["Red","Orange","Yellow","Blue","Neutron","BlackHole","AsteroidField"]
global SubNames  := ["Barren","Desert","EarthLike","Exotic","Forest","Gas","Ocean","RobotDepot","RobotFactory","Terra","Tundra"]

global StarState := Map()
global SubState  := Map()
global StarBtns  := Map()
global SubBtns   := Map()

for _n in StarNames
    StarState[_n] := 0
for _n in SubNames
    SubState[_n] := 0

global C_BG    := "1A0020"
global C_INPUT := "35003A"
global C_DARK  := "0E000F"
global C_FG    := "FFBB77"
global C_DIM   := "B06070"
global C_SEP   := "880038"

if FileExist(IconPath)
    TraySetIcon(IconPath)

global G := Gui("+Resize +MinSize780x600", "Universe Planet Search")
G.BackColor := C_BG
G.SetFont("s8 c" . C_FG, "Segoe UI")
G.OnEvent("Close", GuiClose)
G.OnEvent("Size",  GuiResize)

WIN_W  := 780
INNER  := WIN_W - 24

G.SetFont("s7 Bold c" . C_DIM, "Segoe UI")
G.Add("Text", "x12 y10 w200", "PLANET NAME")
G.Add("Text", "x222 y10 w200", "RANDOM MATERIAL")
G.SetFont("s8 c" . C_FG, "Segoe UI")
global EditName := G.Add("Edit", "x12 y23 w200 h22 Background" . C_INPUT)
global EditMat  := G.Add("Edit", "x222 y23 w460 h22 Background" . C_INPUT)
G.Add("Button", "x692 y23 w76 h22", "Clear All").OnEvent("Click", DoClearAll)
G.Add("Text", "x12 y52 w" . INNER . " h1 Background" . C_SEP)
G.SetFont("s7 Bold c" . C_DIM, "Segoe UI")
G.Add("Text", "x12 y57", "PLANET TYPE")
G.SetFont("s8 c" . C_FG, "Segoe UI")

bw := 120
bh := 22
col := 0
by  := 70
for _name in SubNames {
    _btn := G.Add("Button", "x" . (12 + col * 124) . " y" . by . " w" . bw . " h" . bh, _name)
    _btn.OnEvent("Click", MakeSubToggle(_name))
    SubBtns[_name] := _btn
    col++
    if (col >= 6) {
        col := 0
        by  += bh + 4
    }
}
subEndY := by + bh + 8
G.Add("Text", "x12 y" . subEndY . " w" . INNER . " h1 Background" . C_SEP)
subEndY += 5

G.SetFont("s7 Bold c" . C_DIM, "Segoe UI")
G.Add("Text", "x12 y" . subEndY, "STAR TYPE")
G.SetFont("s8 c" . C_FG, "Segoe UI")

starRowY := subEndY + 13
col    := 0
starBy := starRowY
for _name in StarNames {
    _lbl  := (_name = "AsteroidField") ? "AsteroidFld" : _name
    _btn2 := G.Add("Button", "x" . (12 + col * 124) . " y" . starBy . " w" . bw . " h" . bh, _lbl)
    _btn2.OnEvent("Click", MakeStarToggle(_name))
    StarBtns[_name] := _btn2
    col++
    if (col >= 6) {
        col   := 0
        starBy += bh + 4
    }
}
starEndY := starBy + bh + 8
G.Add("Text", "x12 y" . starEndY . " w" . INNER . " h1 Background" . C_SEP)
starEndY += 5

G.SetFont("s7 Bold c" . C_DIM, "Segoe UI")
G.Add("Text", "x12 y" . starEndY, "TEMPERATURE")
G.Add("Text", "x440 y" . starEndY, "ATMOSPHERE")
G.SetFont("s8 c" . C_FG, "Segoe UI")

tempY := starEndY + 13
global TxtMin := G.Add("Text",   "x12 y"  .  tempY        . " w200", "Min:  -400")
global SldMin := G.Add("Slider", "x12 y"  . (tempY + 14)  . " w200 h20 Range-400-150 AltSubmit", -400)
global TxtMax := G.Add("Text",   "x222 y" .  tempY        . " w200", "Max:   150")
global SldMax := G.Add("Slider", "x222 y" . (tempY + 14)  . " w200 h20 Range-400-150 AltSubmit", 150)
SldMin.OnEvent("Change", DoTempChange)
SldMax.OnEvent("Change", DoTempChange)

global DDAtmo := G.Add("DropDownList", "x440 y" . tempY . " w180 Background" . C_INPUT, ["Any", "Must Have", "Must Not"])
DDAtmo.Value := 1

tempEndY := tempY + 14 + 20 + 8
G.Add("Text", "x12 y" . tempEndY . " w" . INNER . " h1 Background" . C_SEP)
tempEndY += 5

G.SetFont("s7 Bold c" . C_DIM, "Segoe UI")
G.Add("Text", "x12 y" . tempEndY, "RESOURCES  ( Any / Must Have >= min - max / Must Not )")
G.SetFont("s8 c" . C_FG, "Segoe UI")

global ResDD := Map()
global ResSMin := Map() 
global RowData := Map() 
global GInfo := 0    
global ResSMax := Map() 
global ResTMin := Map() 
global ResTMax := Map() 

RES_COLS  := 2
RES_COL_W := 378

col   := 0
row   := 0
resY0 := tempEndY + 14
for _res in ResList {
    xL    := 12  + col * RES_COL_W
    xDD   := xL  + 87
    xGL1  := xDD + 113   ; ">= " label
    xSMin := xGL1 + 22   ; min slider
    xGL2  := xSMin + 72  ; " - " label
    xSMax := xGL2 + 14   ; max slider
    yR    := resY0 + row * 30
    ySld  := yR + 3

    G.Add("Text", "x" . xL . " y" . (yR+4) . " w85", _res)

    _dd := G.Add("DropDownList", "x" . xDD . " y" . yR . " w110 h22 Background" . C_INPUT,
                 ["Any", "Must Have", "Must Not"])
    _dd.Value := 1
    ResDD[_res] := _dd

    G.SetFont("s7 c" . C_DIM, "Segoe UI")
    _tMin := G.Add("Text", "x" . xGL1 . " y" . (yR+4) . " w22", ">=1")
    G.SetFont("s8 c" . C_FG, "Segoe UI")

    ; Min slider (abundance 1-7)
    _sMin := G.Add("Slider", "x" . xSMin . " y" . ySld . " w68 h18 Range1-7 AltSubmit TickInterval1 NoTicks", 1)
    ResSMin[_res] := _sMin
    ResTMin[_res] := _tMin
    _sMin.OnEvent("Change", MakeResSlider(_res, "min"))

    G.SetFont("s7 c" . C_DIM, "Segoe UI")
    _tMax := G.Add("Text", "x" . xGL2 . " y" . (yR+4) . " w18", "-7")
    G.SetFont("s8 c" . C_FG, "Segoe UI")

    ; Max slider (abundance 1-7), default 7
    _sMax := G.Add("Slider", "x" . xSMax . " y" . ySld . " w68 h18 Range1-7 AltSubmit TickInterval1 NoTicks", 7)
    ResSMax[_res] := _sMax
    ResTMax[_res] := _tMax
    _sMax.OnEvent("Change", MakeResSlider(_res, "max"))

    col++
    if (col >= RES_COLS) {
        col := 0
        row++
    }
}

resEndY := resY0 + row * 30 + 30 + 6
G.Add("Text", "x12 y" . resEndY . " w" . INNER . " h1 Background" . C_SEP)
resEndY += 5

G.Add("Button", "x12 y" . resEndY . " w140 h26 Default", "[ Search ]").OnEvent("Click", DoSearch)
G.SetFont("s7 c" . C_DIM, "Segoe UI")
global TxtStatus := G.Add("Text", "x160 y" . (resEndY + 5) . " w596", "Ready")
G.SetFont("s8 c" . C_FG, "Segoe UI")

lvY := resEndY + 32
global LV := G.Add("ListView",
    "x12 y" . lvY . " w" . INNER . " h220 Grid -Multi Background" . C_DARK . " c" . C_FG,
    ["Planet Name", "SubType", "Star", "Coordinates"])
LV.OnEvent("DoubleClick", LVDblClick)
LV.OnEvent("Click",       LVClick)

botY := lvY + 220 + 6
G.Add("Text",   "x12 y" . botY . " w" . INNER . " h1 Background" . C_SEP)
G.Add("Button", "x12 y" . (botY + 4) . " w200 h24", "[ Copy Coordinates ]").OnEvent("Click", DoCopyCoords)
G.SetFont("s7 c" . C_DIM, "Segoe UI")
global TxtCopy := G.Add("Text", "x220 y" . (botY + 8) . " w536", "")

global gLvY := lvY

G.Show("w" . WIN_W . " h" . (botY + 34))

if FileExist(IconPath) {
    hIco := DllCall("LoadImage", "Ptr", 0, "Str", IconPath, "UInt", 1, "Int", 32, "Int", 32, "UInt", 0x10, "Ptr")
    SendMessage(0x80, 0, hIco, G.Hwnd)
    SendMessage(0x80, 1, hIco, G.Hwnd)
}

Persistent

GInfo := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox +ToolWindow", "Planet Info")
GInfo.BackColor := C_BG
GInfo.SetFont("s8 c" . C_FG, "Segoe UI")
GInfo.OnEvent("Close", (*) => GInfo.Hide())

INFO_W := 240

global InfoPlaceholder := GInfo.Add("Text", "x12 y12 w216 r1 Center c" . C_DIM, "Choose a planet 1st!")

global InfoTitle   := GInfo.Add("Text", "x12 y12 w216 r1 +Wrap cFFBB77 +Border +Hidden", "")
GInfo.Add("Text", "x12 y44 w216 h1 Background" . C_SEP)

GInfo.SetFont("s7 Bold c" . C_DIM, "Segoe UI")
GInfo.Add("Text", "x12 y52 w60",  "TYPE")
GInfo.Add("Text", "x80 y52 w60",  "STAR")
GInfo.Add("Text", "x148 y52 w80", "ATMOSPHERE")
GInfo.SetFont("s8 c" . C_FG, "Segoe UI")
global InfoSubType := GInfo.Add("Text", "x12  y64 w64",  "")
global InfoStar    := GInfo.Add("Text", "x80  y64 w64",  "")
global InfoAtmo    := GInfo.Add("Text", "x148 y64 w80",  "")

GInfo.Add("Text", "x12 y84 w216 h1 Background" . C_SEP)

GInfo.SetFont("s7 Bold c" . C_DIM, "Segoe UI")
GInfo.Add("Text", "x12 y90 w80",  "TEMPERATURE")
GInfo.Add("Text", "x100 y90 w116", "MATERIAL")
GInfo.SetFont("s8 c" . C_FG, "Segoe UI")
global InfoTemp    := GInfo.Add("Text", "x12  y102 w80",  "")
global InfoMat     := GInfo.Add("Text", "x100 y102 w116", "")

GInfo.Add("Text", "x12 y120 w216 h1 Background" . C_SEP)

GInfo.SetFont("s7 Bold c" . C_DIM, "Segoe UI")
GInfo.Add("Text", "x12 y126", "RESOURCES")
GInfo.SetFont("s8 c" . C_FG, "Segoe UI")

; 11 resources in 2 columns
global InfoResLabels := []
global InfoResVals   := []
_resNames2 := ["Iron","Copper","Coal","Uranium","Diamond","Jade","Titanium","Beryllium","Aluminum","Gold","Lead"]
_rc := 0
for _rn in _resNames2 {
    _rx := (_rc & 1) ? 124 : 12
    _ry := 140 + (_rc >> 1) * 20
    GInfo.SetFont("s7 c" . C_DIM, "Segoe UI")
    GInfo.Add("Text", "x" . _rx . " y" . _ry . " w70", _rn)
    GInfo.SetFont("s8 c" . C_FG, "Segoe UI")
    _rv := GInfo.Add("Text", "x" . (_rx + 72) . " y" . _ry . " w40", "-")
    InfoResVals.Push(_rv)
    InfoResLabels.Push(_rn)
    _rc++
}

GInfo.Add("Text", "x12 y" . (140 + ((_rc+1)//2)*20 + 4) . " w216 h1 Background" . C_SEP)

; Coords at bottom
global InfoCoords := GInfo.Add("Text", "x12 y" . (140 + ((_rc+1)//2)*20 + 10) . " w216 r2 +Wrap c" . C_DIM, "")

INFO_H := 140 + ((_rc+1)//2)*20 + 32

; Position info panel to the right of main window
_mainX := 0
_mainY := 0
WinGetPos(&_mainX, &_mainY, , , G.Hwnd)
GInfo.Show("w" . INFO_W . " h" . INFO_H . " x" . (_mainX + WIN_W + 4) . " y" . _mainY)
if FileExist(IconPath) {
    _hIco2 := DllCall("LoadImage", "Ptr", 0, "Str", IconPath, "UInt", 1, "Int", 32, "Int", 32, "UInt", 0x10, "Ptr")
    SendMessage(0x80, 0, _hIco2, GInfo.Hwnd)
    SendMessage(0x80, 1, _hIco2, GInfo.Hwnd)
}

MakeSubToggle(_n) {
    local _captured := _n
    return (ctrl, *) => DoToggleSub(_captured)
}
MakeStarToggle(_n) {
    local _captured := _n
    return (ctrl, *) => DoToggleStar(_captured)
}

MakeResSlider(_res, _which) {
    local _r := _res
    local _w := _which
    return (_c, *) => ResSliderChange(_r, _w)
}

ResSliderChange(_res, _which) {
    local _mn := ResSMin[_res].Value
    local _mx := ResSMax[_res].Value
    ; Enforce min <= max
    if (_which = "min" and _mn > _mx) {
        ResSMin[_res].Value := _mx
        _mn := _mx
    }
    if (_which = "max" and _mx < _mn) {
        ResSMax[_res].Value := _mn
        _mx := _mn
    }
    ResTMin[_res].Text := ">=" . _mn
    ResTMax[_res].Text := "-"  . _mx
}

DoToggleSub(_name) {
    SubState[_name] := Mod(SubState[_name] + 1, 3)
    local _s := SubState[_name]
    if (_s = 0)
        SubBtns[_name].Text := _name
    else if (_s = 1)
        SubBtns[_name].Text := "+ " . _name
    else
        SubBtns[_name].Text := "- " . _name
}

DoToggleStar(_name) {
    StarState[_name] := Mod(StarState[_name] + 1, 3)
    local _s   := StarState[_name]
    local _lbl := (_name = "AsteroidField") ? "AsteroidFld" : _name
    if (_s = 0)
        StarBtns[_name].Text := _lbl
    else if (_s = 1)
        StarBtns[_name].Text := "+ " . _lbl
    else
        StarBtns[_name].Text := "- " . _lbl
}

GuiClose(*) {
    ExitApp()
}

GuiResize(GuiObj, MinMax, W, H) {
    if (MinMax = -1)
        return
    local _newW := W - 24
    local _newH := H - gLvY - 38
    if (_newH < 80)
        _newH := 80
    LV.Move(, , _newW, _newH)
}

DoTempChange(*) {
    local _mn := SldMin.Value
    local _mx := SldMax.Value
    if (_mn > _mx) {
        SldMin.Value := _mx
        _mn := _mx
    }
    TxtMin.Text := "Min:  " . _mn
    TxtMax.Text := "Max:   " . _mx
}

DoClearAll(*) {
    EditName.Value := ""
    EditMat.Value  := ""
    for _n in StarNames {
        StarState[_n] := 0
        local _lbl := (_n = "AsteroidField") ? "AsteroidFld" : _n
        StarBtns[_n].Text := _lbl
    }
    for _n in SubNames {
        SubState[_n] := 0
        SubBtns[_n].Text := _n
    }
    SldMin.Value  := -400
    SldMax.Value  :=  150
    TxtMin.Text   := "Min:  -400"
    TxtMax.Text   := "Max:   150"
    DDAtmo.Value  := 1
    for _res, _dd in ResDD {
        _dd.Value := 1
        ResSMin[_res].Value := 1
        ResSMax[_res].Value := 7
        ResTMin[_res].Text  := ">=1"
        ResTMax[_res].Text  := "-7"
    }
    LV.Delete()
    TxtStatus.Text := "Filters cleared"
    TxtCopy.Text   := ""
    ShowInfoPlaceholder()
}

DoSearch(*) {
    TxtStatus.Text := "Searching..."
    TxtCopy.Text   := ""

    ; Collect subtype and star states
    local mustSubsList  := []
    local noSubsList    := []
    local mustStarsList := []
    local noStarsList   := []

    for _n in SubNames {
        if (SubState[_n] = 1)
            mustSubsList.Push("'" . _n . "'")
        else if (SubState[_n] = 2)
            noSubsList.Push("'" . _n . "'")
    }
    for _n in StarNames {
        if (StarState[_n] = 1)
            mustStarsList.Push("'" . _n . "'")
        else if (StarState[_n] = 2)
            noStarsList.Push("'" . _n . "'")
    }

    local mustSubsPS  := JoinArray(mustSubsList,  ",")
    local noSubsPS    := JoinArray(noSubsList,    ",")
    local mustStarsPS := JoinArray(mustStarsList, ",")
    local noStarsPS   := JoinArray(noStarsList,   ",")

    ; Atmosphere
    local atmoMode := 0
    if (DDAtmo.Text = "Must Have")
        atmoMode := 1
    else if (DDAtmo.Text = "Must Not")
        atmoMode := 2

    local nf   := StrReplace(EditName.Value, "'", "''")
    local mf   := StrReplace(EditMat.Value,  "'", "''")
    local tMin := SldMin.Value
    local tMax := SldMax.Value

    local ResLines := ""
    for _res, _dd in ResDD {
        local _v    := _dd.Value   ; 1=Any  2=Must Have  3=Must Not
        local _rMin := ResSMin[_res].Value   ; slider value: integer 1-7
        local _rMax := ResSMax[_res].Value   ; slider value: integer 1-7
        if (_rMin > _rMax) {
            local _tmp := _rMin
            _rMin := _rMax
            _rMax := _tmp
        }

        if (_v = 2) {   ; Must Have
            ResLines .= "    if ($match) {`n"
            ResLines .= "        $rv = 0`n"
            ResLines .= "        if ($pl.PSObject.Properties['Resources'] -and $pl.Resources.PSObject.Properties['" . _res . "']) { $rv = [int]$pl.Resources." . _res . " }`n"
            ResLines .= "        if ($rv -lt " . _rMin . " -or $rv -gt " . _rMax . ") { $match = $false }`n"
            ResLines .= "    }`n"
        } else if (_v = 3) {   ; Must Not
            ResLines .= "    if ($match -and $pl.PSObject.Properties['Resources'] -and $pl.Resources.PSObject.Properties['" . _res . "'] -and [int]$pl.Resources." . _res . " -gt 0) { $match = $false }`n"
        }
    }

    local PS := ""
    PS .= "$data = Get-Content '" . JsonPath . "' -Raw -Encoding UTF8 | ConvertFrom-Json`n"
    PS .= "$out  = [System.Collections.Generic.List[string]]::new()`n"


    PS .= "$starMap = @{}`n"
    PS .= "$data.PSObject.Properties | ForEach-Object {`n"
    PS .= "    $t = $_.Value.Type`n"
    PS .= "    if ($t -eq 'Star' -or $t -eq 'BlackHole' -or $t -eq 'AsteroidField') {`n"
    PS .= "        $p  = $_.Name -split ', '`n"
    PS .= "        $sk = $p[0] + ', ' + $p[1]`n"
    PS .= "        $id = if ($t -eq 'Star') { $_.Value.SubType } else { $t }`n"
    PS .= "        $starMap[$sk] = $id`n"
    PS .= "    }`n"
    PS .= "}`n"

    PS .= "$mustSubs  = @(" . mustSubsPS  . ")`n"
    PS .= "$noSubs    = @(" . noSubsPS    . ")`n"
    PS .= "$mustStars = @(" . mustStarsPS . ")`n"
    PS .= "$noStars   = @(" . noStarsPS   . ")`n"

    PS .= "$data.PSObject.Properties | ForEach-Object {`n"
    PS .= "    $coords = $_.Name`n"
    PS .= "    $pl     = $_.Value`n"
    PS .= "    if ($pl.Type -ne 'Planet') { return }`n"
    PS .= "    if (-not $pl.PSObject.Properties['Name']) { return }`n"
    PS .= "    $match = $true`n"
    PS .= "    $p     = $coords -split ', '`n"
    PS .= "    $sk    = $p[0] + ', ' + $p[1]`n"
    PS .= "    $starT = if ($starMap.ContainsKey($sk)) { $starMap[$sk] } else { 'Unknown' }`n"

    PS .= "    if ($match -and $mustStars.Count -gt 0 -and $starT -notin $mustStars) { $match = $false }`n"
    PS .= "    if ($match -and $noStars.Count   -gt 0 -and $starT -in    $noStars)   { $match = $false }`n"
    PS .= "    if ($match -and $mustSubs.Count  -gt 0 -and $pl.SubType -notin $mustSubs) { $match = $false }`n"
    PS .= "    if ($match -and $noSubs.Count    -gt 0 -and $pl.SubType -in    $noSubs)   { $match = $false }`n"

    if (nf != "")
        PS .= "    if ($match -and $pl.Name -notlike '*" . nf . "*') { $match = $false }`n"

    if (mf != "") {
        PS .= "    if ($match) {`n"
        PS .= "        if (-not $pl.PSObject.Properties['RandomMaterial']) { $match = $false }`n"
        PS .= "        elseif ($pl.RandomMaterial -notlike '*" . mf . "*') { $match = $false }`n"
        PS .= "    }`n"
    }

    PS .= "    if ($match -and ($pl.Temperature -lt " . tMin . " -or $pl.Temperature -gt " . tMax . ")) { $match = $false }`n"

    if (atmoMode = 1)
        PS .= "    if ($match -and $pl.Atmosphere -ne $true) { $match = $false }`n"
    else if (atmoMode = 2)
        PS .= "    if ($match -and $pl.Atmosphere -eq $true) { $match = $false }`n"

    if (ResLines != "")
        PS .= ResLines

    PS .= "    if ($match) {`n"
    PS .= "        $subT  = if ($pl.PSObject.Properties['SubType']) { $pl.SubType } else { '' }`n"
    PS .= "        $atmo  = if ($pl.Atmosphere) { 'Yes' } else { 'No' }`n"
    PS .= "        $temp  = [string]$pl.Temperature`n"
    PS .= "        $mat   = if ($pl.PSObject.Properties['RandomMaterial']) { $pl.RandomMaterial } else { '' }`n"
    PS .= "        $resStr = ''`n"
    PS .= "        if ($pl.PSObject.Properties['Resources']) {`n"
    PS .= "            $parts = @()`n"
    PS .= "            $pl.Resources.PSObject.Properties | ForEach-Object { $parts += ($_.Name + ':' + $_.Value) }`n"
    PS .= "            $resStr = $parts -join ','`n"
    PS .= "        }`n"
    PS .= "        $out.Add($pl.Name + '|' + $subT + '|' + $starT + '|' + $coords + '|' + $atmo + '|' + $temp + '|' + $mat + '|' + $resStr)`n"
    PS .= "    }`n"
    PS .= "}`n"
    PS .= "[System.IO.File]::WriteAllLines('" . TempOut . "', $out, [System.Text.UTF8Encoding]::new($false))`n"

    try FileDelete(TempPS)
    FileAppend(PS, TempPS, "UTF-8")
    RunWait('powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' . TempPS . '"', , "Hide")

    LV.Delete()
    RowData.Clear()
    local count := 0
    loop read TempOut {
        local _line := Trim(A_LoopReadLine)
        if (_line = "")
            continue
        ; Format: Name|SubType|Star|Coords|Atmo|Temp|Material|Resources
        local _p1 := InStr(_line, "|", , 1)
        local _p2 := InStr(_line, "|", , _p1 + 1)
        local _p3 := InStr(_line, "|", , _p2 + 1)
        local _p4 := InStr(_line, "|", , _p3 + 1)
        local _p5 := InStr(_line, "|", , _p4 + 1)
        local _p6 := InStr(_line, "|", , _p5 + 1)
        local _p7 := InStr(_line, "|", , _p6 + 1)
        if (!_p1 || !_p2 || !_p3)
            continue
        local _pName   := SubStr(_line, 1,      _p1-1)
        local _pSub    := SubStr(_line, _p1+1,  _p2-_p1-1)
        local _pStar   := SubStr(_line, _p2+1,  _p3-_p2-1)
        local _pCoords := SubStr(_line, _p3+1,  _p4-_p3-1)
        local _pAtmo   := SubStr(_line, _p4+1,  _p5-_p4-1)
        local _pTemp   := SubStr(_line, _p5+1,  _p6-_p5-1)
        local _pMat    := SubStr(_line, _p6+1,  _p7-_p6-1)
        local _pRes    := SubStr(_line, _p7+1)
        count++
        LV.Add("", _pName, _pSub, _pStar, _pCoords)
        ; Build structured data map and store by row index
        local _rd := Map()
        _rd["name"]    := _pName
        _rd["subtype"] := _pSub
        _rd["star"]    := _pStar
        _rd["coords"]  := _pCoords
        _rd["atmo"]    := _pAtmo
        _rd["temp"]    := _pTemp
        _rd["mat"]     := _pMat
        local _resMap := Map()
        if (_pRes != "") {
            loop parse _pRes, "," {
                local _kv := StrSplit(A_LoopField, ":")
                if (_kv.Length >= 2)
                    _resMap[_kv[1]] := _kv[2]
            }
        }
        _rd["resmap"]  := _resMap
        RowData[count] := _rd
    }

    LV.ModifyCol(1, "AutoHdr")
    LV.ModifyCol(2, "AutoHdr")
    LV.ModifyCol(3, "AutoHdr")
    LV.ModifyCol(4, "AutoHdr")

    if (count = 0)
        TxtStatus.Text := "No matches - try relaxing filters"
    else if (count = 1)
        TxtStatus.Text := "1 planet found"
    else
        TxtStatus.Text := count . " planets found"
}

DoCopyCoords(*) {
    local _r := LV.GetNext(0, "Focused")
    if (!_r) {
        TxtCopy.Text := "(!) Select a row first"
        return
    }
    local _c := LV.GetText(_r, 4)
    A_Clipboard := _c
    TxtCopy.Text := "Copied: " . _c
}

LVClick(ctrl, _r) {
    if (_r < 1) {
        ShowInfoPlaceholder()
        return
    }
    if RowData.Has(_r)
        ShowInfoPanel(RowData[_r])
}

LVDblClick(ctrl, _r) {
    if (_r < 1)
        return
    if RowData.Has(_r)
        ShowInfoPanel(RowData[_r])
    local _c := LV.GetText(_r, 4)
    A_Clipboard := _c
    TxtCopy.Text := "Copied: " . _c
}

ShowInfoPlaceholder() {
    InfoPlaceholder.Visible := true
    InfoTitle.Visible   := false
    InfoSubType.Text    := ""
    InfoStar.Text       := ""
    InfoAtmo.Text       := ""
    InfoTemp.Text       := ""
    InfoMat.Text        := ""
    InfoCoords.Text     := ""
    for _v in InfoResVals
        _v.Text := "-"
}

ShowInfoPanel(_d) {
    InfoPlaceholder.Visible := false
    InfoTitle.Visible       := true
    InfoTitle.Text          := _d["name"]
    InfoSubType.Text        := _d["subtype"]
    InfoStar.Text           := _d["star"]
    InfoAtmo.Text           := _d["atmo"]
    InfoTemp.Text           := _d["temp"] . "°"
    InfoMat.Text            := _d["mat"] != "" ? _d["mat"] : "—"
    InfoCoords.Text         := _d["coords"]
    ; Populate resource values in fixed order
    local _resNames2 := ["Iron","Copper","Coal","Uranium","Diamond","Jade","Titanium","Beryllium","Aluminum","Gold","Lead"]
    local _resMap := _d["resmap"]
    local _i := 1
    for _rn in _resNames2 {
        local _val := _resMap.Has(_rn) ? _resMap[_rn] : "-"
        InfoResVals[_i].Text := _val
        _i++
    }
}

JoinArray(_arr, _sep) {
    local _out := ""
    local _i   := 0
    for _v in _arr {
        _i++
        if (_i = 1)
            _out := _v
        else
            _out .= _sep . _v
    }
    return _out
}
