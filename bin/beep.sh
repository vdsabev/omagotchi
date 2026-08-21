#!/usr/bin/env sh
# Generate a boop immediately followed by a honk and play it.
#   beep.sh [freq_hz] [duration_ms] [volume_0-1]
freq=${1:-800}
dur=${2:-180}
vol=${3:-0.3}

tmp=$(mktemp /tmp/omagotchi-boop-honk-XXXXXX.wav)
trap 'rm -f "$tmp"' EXIT

python3 - "$freq" "$dur" "$vol" "$tmp" <<'PYEOF'
import sys, math, struct, wave

base_freq = float(sys.argv[1])
total_dur = int(sys.argv[2])
vol = float(sys.argv[3])
out = sys.argv[4]

sample_rate = 22050

# boop: base_freq sine, 55% of duration
boop_dur = int(total_dur * 0.55)
# honk: 1.5x base_freq buzzy (fundamental + 3rd harmonic), 45% of duration
honk_dur = total_dur - boop_dur
honk_freq = base_freq * 1.5

total_ms = boop_dur + honk_dur
n_samples = int(sample_rate * total_ms / 1000)

with wave.open(out, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(sample_rate)

    frames = bytearray()
    for i in range(n_samples):
        t = i / sample_rate
        if i < int(sample_rate * boop_dur / 1000):
            env = math.exp(-4.0 * t / (boop_dur / 1000.0))
            sample = vol * env * math.sin(2.0 * math.pi * base_freq * t)
        else:
            t2 = t - boop_dur / 1000.0
            env = math.exp(-3.0 * t2 / (honk_dur / 1000.0))
            sample = (math.sin(2.0 * math.pi * honk_freq * t2)
                      + 0.4 * math.sin(2.0 * math.pi * 3 * honk_freq * t2))
            sample = vol * env * sample / 1.4
        sample = max(-1.0, min(1.0, sample))
        frames += struct.pack("<h", int(sample * 32767))
    w.writeframes(bytes(frames))
PYEOF

if command -v pw-play >/dev/null 2>&1; then
  pw-play --volume=1.0 "$tmp"
elif command -v paplay >/dev/null 2>&1; then
  paplay "$tmp"
elif command -v aplay >/dev/null 2>&1; then
  aplay -q "$tmp"
fi
