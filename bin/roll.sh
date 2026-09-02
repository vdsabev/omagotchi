#!/usr/bin/env sh
# Generate a low motor whirr - a rumbling drone that fades in and out.
#   roll.sh [freq_hz] [duration_ms] [volume_0-1] [fade_s]
freq=${1:-110}
dur=${2:-1200}
vol=${3:-0.18}
# A short fade lets chunks played back to back run as one continuous drone.
fade=${4:-0.12}

tmp=$(mktemp /tmp/omagotchi-roll-XXXXXX.wav)

python3 - "$freq" "$dur" "$vol" "$tmp" "$fade" <<'PYEOF'
import sys, math, struct, wave

base = float(sys.argv[1])
dur_ms = int(sys.argv[2])
vol = float(sys.argv[3])
out = sys.argv[4]
fade_s = float(sys.argv[5])

sample_rate = 22050
n_samples = int(sample_rate * dur_ms / 1000)
fade = max(1, int(sample_rate * fade_s))

with wave.open(out, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(sample_rate)

    frames = bytearray()
    for i in range(n_samples):
        t = i / sample_rate
        # Fundamental plus its fifth, with a slow tremolo for the motor beat.
        tone = (math.sin(2 * math.pi * base * t)
                + 0.4 * math.sin(2 * math.pi * base * 1.5 * t)
                + 0.2 * math.sin(2 * math.pi * base * 3 * t))
        tremolo = 0.8 + 0.2 * math.sin(2 * math.pi * 11 * t)
        envelope = min(1.0, i / fade, (n_samples - i) / fade)
        sample = int(32767 * vol * envelope * tremolo * tone / 1.6)
        frames += struct.pack("<h", max(-32768, min(32767, sample)))
    w.writeframes(bytes(frames))
PYEOF

# Hands the file over to be played and removed.
exec sh "$(dirname "$0")/play.sh" "$tmp"
