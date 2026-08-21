#!/usr/bin/env sh
# Generate a frequency-sweep chirp with amplitude modulation (rattly effect).
#   wiggle.sh [base_freq_hz] [duration_ms] [volume_0-1]
freq=${1:-600}
dur=${2:-200}
vol=${3:-0.3}

tmp=$(mktemp /tmp/omagotchi-wiggle-XXXXXX.wav)
trap 'rm -f "$tmp"' EXIT

python3 - "$freq" "$dur" "$vol" "$tmp" <<'PYEOF'
import sys, math, struct, wave

base = float(sys.argv[1])
dur_ms = int(sys.argv[2])
vol = float(sys.argv[3])
out = sys.argv[4]

sample_rate = 22050
n_samples = int(sample_rate * dur_ms / 1000)

# Generate two cycles of the whir sound back-to-back
with wave.open(out, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(sample_rate)

    frames = bytearray()
    for _ in range(2):
        for i in range(n_samples):
            t = i / sample_rate
            progress = t / (dur_ms / 1000.0)
            # Frequency sweep up and back down
            sweep = 1.0 + 0.7 * math.sin(math.pi * progress)
            freq_now = base * sweep
            # Amplitude modulation for a rattly tremolo
            trem = 0.5 + 0.5 * math.sin(2.0 * math.pi * 30 * t)
            env = math.exp(-2.5 * progress)
            sample = vol * env * trem * math.sin(2.0 * math.pi * freq_now * t)
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
