#!/usr/bin/env sh
# Generate a short thud - the robot hits the ground again.
#   land.sh [freq_hz] [duration_ms] [volume_0-1]
freq=${1:-90}
dur=${2:-220}
vol=${3:-0.32}

tmp=$(mktemp /tmp/omagotchi-land-XXXXXX.wav)

python3 - "$freq" "$dur" "$vol" "$tmp" <<'PYEOF'
import sys, math, struct, wave, random

base = float(sys.argv[1])
dur_ms = int(sys.argv[2])
vol = float(sys.argv[3])
out = sys.argv[4]

sample_rate = 22050
n_samples = int(sample_rate * dur_ms / 1000)
random.seed(7)

with wave.open(out, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(sample_rate)

    frames = bytearray()
    phase = 0.0
    for i in range(n_samples):
        progress = i / n_samples
        # A dropping pitch plus a burst of noise makes the impact read as metal.
        freq_now = base * (1.0 - 0.5 * progress)
        phase += 2.0 * math.pi * freq_now / sample_rate
        env = math.exp(-9.0 * progress)
        rattle = random.uniform(-1.0, 1.0) * math.exp(-40.0 * progress)
        sample = vol * (env * math.sin(phase) + 0.35 * rattle)
        frames += struct.pack("<h", int(max(-1.0, min(1.0, sample)) * 32767))
    w.writeframes(bytes(frames))
PYEOF

# Hands the file over to be played and removed.
exec sh "$(dirname "$0")/play.sh" "$tmp"
