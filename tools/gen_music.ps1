$ErrorActionPreference = "Stop"
$outDir = "C:\Dev\Projects\Incremental Shooter\assets\music"
$sr = 22050
$duration = 24.0
$totalSamples = [int]($sr * $duration)

# Note frequencies
function Freq($note) {
    # note like "A4"
    $names = @("C","C#","D","D#","E","F","F#","G","G#","A","A#","B")
    $oct = [int]$note.Substring($note.Length-1)
    $name = $note.Substring(0, $note.Length-1)
    $idx = $names.IndexOf($name)
    $midi = ($oct+1)*12 + $idx
    return 440.0 * [Math]::Pow(2.0, ($midi-69)/12.0)
}

# Chord progression: Am F C G (each 2 beats? let's do 4 beats per chord, 4 chords = 16 beats per cycle)
# 2 cycles in 24s -> 12s per cycle -> 1.5s per beat? 16 beats in 12s = 0.75s/beat -> 80 BPM. OK.
$beat = 0.75
$chords = @(
    @("A3","C4","E4"),   # Am
    @("F3","A3","C4"),   # F
    @("C3","E3","G3"),   # C
    @("G3","B3","D4")    # G
)

# Melody notes per beat (16 beats per cycle) - arpeggio-ish
$melody = @(
    "A4","C5","E5","A5",
    "F4","A4","C5","F5",
    "C5","E5","G5","C6",
    "G4","B4","D5","G5"
)

# Bass roots per chord (4 beats)
$bassNotes = @("A2","F2","C2","G2")

# Build list of tones: each tone = (freq, start, dur, amp)
$tones = New-Object System.Collections.ArrayList

# Pad/chords: each chord lasts 4 beats, all 3 notes
for ($cycle=0; $cycle -lt 2; $cycle++) {
    for ($ci=0; $ci -lt 4; $ci++) {
        $t0 = ($cycle*16 + $ci*4) * $beat
        foreach ($n in $chords[$ci]) {
            [void]$tones.Add(@{f=(Freq $n); s=$t0; d=(4*$beat); a=0.06})
        }
    }
}

# Bass: root per beat? root for 4 beats per chord
for ($cycle=0; $cycle -lt 2; $cycle++) {
    for ($ci=0; $ci -lt 4; $ci++) {
        $t0 = ($cycle*16 + $ci*4) * $beat
        $bn = $bassNotes[$ci]
        for ($b=0; $b -lt 4; $b++) {
            $tt = $t0 + $b*$beat
            [void]$tones.Add(@{f=(Freq $bn); s=$tt; d=($beat*0.9); a=0.18})
        }
    }
}

# Melody: one note per beat
for ($cycle=0; $cycle -lt 2; $cycle++) {
    for ($i=0; $i -lt 16; $i++) {
        $t0 = ($cycle*16 + $i) * $beat
        $mn = $melody[$i]
        [void]$tones.Add(@{f=(Freq $mn); s=$t0; d=($beat*0.85); a=0.12})
    }
}

# High shimmer (octave up melody, lower amp) delayed
for ($cycle=0; $cycle -lt 2; $cycle++) {
    for ($i=0; $i -lt 16; $i++) {
        $t0 = ($cycle*16 + $i) * $beat + 0.05
        $mn = $melody[$i]
        # octave up
        $f = (Freq $mn) * 2.0
        [void]$tones.Add(@{f=$f; s=$t0; d=($beat*0.5); a=0.04})
    }
}

# Render
$samples = New-Object double[] $totalSamples
# precompute tone arrays for speed
$tf = New-Object double[] $tones.Count
$ts = New-Object double[] $tones.Count
$td = New-Object double[] $tones.Count
$ta = New-Object double[] $tones.Count
for ($i=0; $i -lt $tones.Count; $i++) {
    $tf[$i] = $tones[$i].f
    $ts[$i] = $tones[$i].s
    $td[$i] = $tones[$i].d
    $ta[$i] = $tones[$i].a
}

for ($i=0; $i -lt $totalSamples; $i++) {
    $t = $i / [double]$sr
    $v = 0.0
    for ($k=0; $k -lt $tones.Count; $k++) {
        $dt = $t - $ts[$k]
        if ($dt -ge 0 -and $dt -lt $td[$k]) {
            # envelope: attack 0.02, decay
            $env = 1.0
            if ($dt -lt 0.02) { $env = $dt/0.02 }
            $env *= [Math]::Exp(-1.5*$dt)
            $v += [Math]::Sin(2*[Math]::PI*$tf[$k]*$t) * $ta[$k] * $env
        }
    }
    # gentle master fade at very end? keep loopable: no fade
    # soft clip
    if ($v -gt 0.9) { $v = 0.9 }
    if ($v -lt -0.9) { $v = -0.9 }
    $samples[$i] = $v * 0.9
}

# Write WAV
$ms = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($ms)
$dataSize = $totalSamples * 2
$bw.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
$bw.Write([int]($dataSize + 36))
$bw.Write([System.Text.Encoding]::ASCII.GetBytes("WAVE"))
$bw.Write([System.Text.Encoding]::ASCII.GetBytes("fmt "))
$bw.Write([int]16)
$bw.Write([Int16]1)
$bw.Write([Int16]1)
$bw.Write([int]$sr)
$bw.Write([int]($sr*2))
$bw.Write([Int16]2)
$bw.Write([Int16]16)
$bw.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
$bw.Write([int]$dataSize)
for ($i=0; $i -lt $totalSamples; $i++) {
    $v = [int]($samples[$i] * 32767.0)
    if ($v -gt 32767) { $v = 32767 }
    if ($v -lt -32768) { $v = -32768 }
    $bw.Write([Int16]$v)
}
$bw.Flush()
[System.IO.File]::WriteAllBytes((Join-Path $outDir "lobby.wav"), $ms.ToArray())
$bw.Dispose(); $ms.Dispose()
Write-Host "wrote lobby.wav ($totalSamples samples, $duration s)"