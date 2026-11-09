# Generate simple sound effects as 16-bit PCM WAV files
$ErrorActionPreference = "Stop"
$outDir = "C:\Dev\Projects\Incremental Shooter\assets\sounds"
$sr = 22050

function Write-Wav($name, [double[]]$samples) {
    $path = Join-Path $outDir $name
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    $numSamples = $samples.Length
    $byteRate = $sr * 2
    $blockAlign = 2
    $dataSize = $numSamples * 2
    # RIFF header
    $bw.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
    $bw.Write([int]($dataSize + 36))
    $bw.Write([System.Text.Encoding]::ASCII.GetBytes("WAVE"))
    $bw.Write([System.Text.Encoding]::ASCII.GetBytes("fmt "))
    $bw.Write([int]16)
    $bw.Write([Int16]1)        # PCM
    $bw.Write([Int16]1)        # mono
    $bw.Write([int]$sr)
    $bw.Write([int]$byteRate)
    $bw.Write([Int16]$blockAlign)
    $bw.Write([Int16]16)
    $bw.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
    $bw.Write([int]$dataSize)
    foreach ($s in $samples) {
        $v = [int]($s * 32767.0)
        if ($v -gt 32767) { $v = 32767 }
        if ($v -lt -32768) { $v = -32768 }
        $bw.Write([Int16]$v)
    }
    $bw.Flush()
    [System.IO.File]::WriteAllBytes($path, $ms.ToArray())
    $bw.Dispose(); $ms.Dispose()
    Write-Host "wrote $name ($numSamples samples)"
}

function Noise([int]$n, [double]$amp=1.0) {
    $r = New-Object System.Random
    $a = New-Object double[] $n
    for ($i=0;$i -lt $n;$i++){ $a[$i] = ($r.NextDouble()*2-1)*$amp }
    return $a
}

function Sine([int]$n, [double]$freq, [double]$amp=1.0, [double]$decay=0.0) {
    $a = New-Object double[] $n
    for ($i=0;$i -lt $n;$i++){
        $t = $i / [double]$sr
        $env = 1.0
        if ($decay -gt 0) { $env = [Math]::Exp(-$decay*$t) }
        $a[$i] = [Math]::Sin(2*[Math]::PI*$freq*$t) * $amp * $env
    }
    return $a
}

function Mix($a, $b, [double]$wa=1.0, [double]$wb=1.0) {
    $n = [Math]::Max($a.Length,$b.Length)
    $r = New-Object double[] $n
    for ($i=0;$i -lt $n;$i++){
        $va = 0.0; $vb = 0.0
        if ($i -lt $a.Length){ $va = $a[$i] }
        if ($i -lt $b.Length){ $vb = $b[$i] }
        $r[$i] = $va*$wa + $vb*$wb
    }
    return $r
}

function Scale($a, [double]$f) {
    $r = New-Object double[] $a.Length
    for ($i=0;$i -lt $a.Length;$i++){ $r[$i] = $a[$i]*$f }
    return $r
}

function Envelope($a, [double]$attack=0.005, [double]$decay=0.0) {
    $r = New-Object double[] $a.Length
    for ($i=0;$i -lt $a.Length;$i++){
        $t = $i/[double]$sr
        $env = 1.0
        if ($t -lt $attack){ $env = $t/$attack }
        if ($decay -gt 0){ $env *= [Math]::Exp(-$decay*$t) }
        $r[$i] = $a[$i]*$env
    }
    return $r
}

# shoot: noise burst + low thump
$shotNoise = Envelope (Scale (Noise 2000) 0.9) 0.001 8.0
$shotThump = Envelope (Sine 2000 90 0.6 6.0) 0.001 6.0
$shoot = Mix $shotNoise $shotThump 0.7 0.5
Write-Wav "shoot.wav" $shoot

# hit: thud
$hit = Envelope (Sine 3000 120 0.8 5.0) 0.002 4.0
Write-Wav "hit.wav" $hit

# enemy death: descending sweep
$death = New-Object double[] 6000
for ($i=0;$i -lt 6000;$i++){
    $t = $i/[double]$sr
    $f = 400 - 300*$t/0.27
    if ($f -lt 80){ $f = 80 }
    $death[$i] = [Math]::Sin(2*[Math]::PI*$f*$t) * 0.7 * [Math]::Exp(-3*$t)
}
Write-Wav "enemy_death.wav" $death

# reload: click + slide
$click = Envelope (Noise 300 1.0) 0.001 20.0
$slide = Envelope (Sine 4000 600 0.3 2.0) 0.001 1.5
# concatenate
$reload = New-Object double[] 6000
for ($i=0;$i -lt 300;$i++){ if ($i -lt $click.Length){ $reload[$i] = $click[$i]*0.8 } }
for ($i=0;$i -lt 4000;$i++){ $reload[1500+$i] = $slide[$i]*0.5 }
Write-Wav "reload.wav" $reload

# pickup money: high ping
$ping = Envelope (Sine 2500 880 0.6 3.0) 0.001 3.0
$ping2 = Envelope (Sine 2500 1320 0.4 3.0) 0.001 3.0
$pickup = Mix $ping $ping2 1.0 0.6
Write-Wav "pickup.wav" $pickup

# wave start: rising tone
$wave = New-Object double[] 8000
for ($i=0;$i -lt 8000;$i++){
    $t = $i/[double]$sr
    $f = 300 + 600*$t/0.36
    $wave[$i] = [Math]::Sin(2*[Math]::PI*$f*$t) * 0.5 * (1-[Math]::Exp(-20*$t)) * [Math]::Exp(-1.5*$t)
}
Write-Wav "wave_start.wav" $wave

# player hurt: harsh
$hurtNoise = Envelope (Noise 2500 1.0) 0.001 4.0
$hurtTone = Envelope (Sine 2500 180 0.5 3.0) 0.001 3.0
$hurt = Mix $hurtNoise $hurtTone 0.6 0.4
Write-Wav "player_hurt.wav" $hurt

# empty click
$empty = Envelope (Noise 200 0.8) 0.001 30.0
Write-Wav "empty.wav" $empty

# ui click
$uiclick = Envelope (Sine 800 1200 0.4 10.0) 0.001 10.0
Write-Wav "ui_click.wav" $uiclick