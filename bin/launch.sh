#!/usr/bin/env sh
# Generate a rising whoosh - the robot is slung into the air.
#   launch.sh [start_freq_hz] [duration_ms] [volume_0-1]
freq=${1:-320}
dur=${2:-420}
vol=${3:-0.26}

tmp=$(mktemp /tmp/omagotchi-launch-XXXXXX.wav)

python3 - "$freq" "$dur" "$vol" "$tmp" <<'PYEOF'
import sys, math, struct, wave

base = float(sys.argv[1])
dur_ms = int(sys.argv[2])
vol = float(sys.argv[3])
out = sys.argv[4]

sample_rate = 22050
n_samples = int(sample_rate * dur_ms / 1000)

with wave.open(out, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(sample_rate)

    frames = bytearray()
    phase = 0.0
    for i in range(n_samples):
        progress = i / n_samples
        # The pitch climbs four times over, so the launch reads as an ascent.
        freq_now = base * (1.0 + 3.0 * progress * progress)
        phase += 2.0 * math.pi * freq_now / sample_rate
        # Noise-free body plus an octave, faded in and out around the peak.
        env = math.sin(math.pi * progress) ** 0.7
        sample = vol * env * (math.sin(phase) + 0.3 * math.sin(2 * phase))
        frames += struct.pack("<h", int(max(-1.0, min(1.0, sample / 1.3)) * 32767))
    w.writeframes(bytes(frames))
PYEOF

# Hands the file over to be played and removed.
exec sh "$(dirname "$0")/play.sh" "$tmp"
