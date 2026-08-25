#!/usr/bin/env sh
# Generate a falling two-note tone and play it - the robot lost its charger.
#   unplug.sh [base_freq_hz] [duration_ms] [volume_0-1]
freq=${1:-440}
dur=${2:-320}
vol=${3:-0.3}

tmp=$(mktemp /tmp/omagotchi-unplug-XXXXXX.wav)

python3 - "$freq" "$dur" "$vol" "$tmp" <<'PYEOF'
import sys, math, struct, wave

base = float(sys.argv[1])
total_dur = int(sys.argv[2])
vol = float(sys.argv[3])
out = sys.argv[4]

sample_rate = 22050

# Two notes a minor third apart, high then low, for a disappointed fall.
notes = [(base, 0.4), (base / 1.19, 0.6)]

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
            attack = min(1.0, progress / 0.08)
            # Pitch sags as the note decays, further on the longer second note.
            bend = 1.0 - 0.06 * progress * share
            env = attack * math.exp(-2.2 * progress)
            # A sub-octave under the fundamental, so the fall lands duller
            # than the charge chirp, which stacks a harmonic above instead.
            sample = vol * env * (math.sin(2.0 * math.pi * note_freq * bend * t)
                                 + 0.3 * math.sin(math.pi * note_freq * bend * t))
            sample = max(-1.0, min(1.0, sample / 1.3))
            frames += struct.pack("<h", int(sample * 32767))
    w.writeframes(bytes(frames))
PYEOF

# Hands the file over to be played and removed.
exec sh "$(dirname "$0")/play.sh" "$tmp"
