#!/usr/bin/env sh
# Generate a rising two-note chirp and play it - the robot found food.
#   charge.sh [base_freq_hz] [duration_ms] [volume_0-1]
freq=${1:-520}
dur=${2:-260}
vol=${3:-0.3}

tmp=$(mktemp /tmp/omagotchi-charge-XXXXXX.wav)

python3 - "$freq" "$dur" "$vol" "$tmp" <<'PYEOF'
import sys, math, struct, wave

base = float(sys.argv[1])
total_dur = int(sys.argv[2])
vol = float(sys.argv[3])
out = sys.argv[4]

sample_rate = 22050

# Two notes a perfect fifth apart, low then high.
notes = [(base, 0.45), (base * 1.5, 0.55)]

with wave.open(out, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(sample_rate)

    frames = bytearray()
    for note_freq, share in notes:
        note_ms = total_dur * share
        for i in range(int(sample_rate * note_ms / 1000)):
            t = i / sample_rate
            progress = t / (note_ms / 1000.0)
            # Soft attack keeps the note from clicking at the start.
            attack = min(1.0, progress / 0.08)
            env = attack * math.exp(-3.0 * progress)
            sample = vol * env * (math.sin(2.0 * math.pi * note_freq * t)
                                  + 0.25 * math.sin(4.0 * math.pi * note_freq * t))
            sample = max(-1.0, min(1.0, sample / 1.25))
            frames += struct.pack("<h", int(sample * 32767))
    w.writeframes(bytes(frames))
PYEOF

# Hands the file over to be played and removed.
exec sh "$(dirname "$0")/play.sh" "$tmp"
