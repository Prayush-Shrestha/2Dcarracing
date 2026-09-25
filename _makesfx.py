"""Synthesize the Street Rush SFX set as 16-bit mono WAVs.

Sounds land in assets/sounds/ where game.gd picks them up automatically:
  click.wav, coin.wav, crash.wav, level.wav, engine.wav, gameover.wav
"""
import math
import wave
import struct
import random
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent / "assets" / "sounds"
random.seed(7)


def save(name: str, samples: list[float]) -> None:
    peak = max(1e-6, max(abs(s) for s in samples))
    gain = 0.89 / peak
    frames = struct.pack(
        "<%dh" % len(samples),
        *(int(max(-1.0, min(1.0, s * gain)) * 32767) for s in samples),
    )
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)
    print(f"{name}: {len(samples) / RATE:.2f}s")


def tone(freq: float, dur: float, harm: tuple[float, ...] = (1.0,),
         decay: float = 6.0, delay: float = 0.0,
         total: float | None = None) -> list[float]:
    n = int(RATE * (total if total else dur + delay))
    out = [0.0] * n
    start = int(RATE * delay)
    count = int(RATE * dur)
    for i in range(count):
        t = i / RATE
        env = math.exp(-decay * i / count)
        s = sum(a * math.sin(math.tau * f * freq * t) for f, a in
                [(1.0, harm[0])] + [(m + 2, a) for m, a in enumerate(harm[1:])])
        # NOTE: harmonic partials above use (m+2)*freq multiples
        out[start + i] += s * env / max(1, len(harm))
    return out


def mix(*tracks: list[float]) -> list[float]:
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    return [math.tanh(s) for s in out]


# UI click: short filtered tick
click = tone(1250.0, 0.07, harm=(1.0, 0.35), decay=9.0)
save("click.wav", click)

# Coin: classic B5 -> E6 two-tone chime
coin = mix(
    tone(987.77, 0.10, harm=(1.0, 0.4, 0.15), decay=4.0),
    tone(1318.5, 0.28, harm=(1.0, 0.4, 0.15), decay=5.0, delay=0.09, total=0.37),
)
save("coin.wav", coin)

# Crash: noise burst + low thud
dur = 0.5
n = int(RATE * dur)
noise = []
for i in range(n):
    env = math.exp(-7.0 * i / n)
    noise.append(random.uniform(-1, 1) * env * 0.8)
thud = tone(62.0, dur, harm=(1.0, 0.5), decay=5.0)
save("crash.wav", mix(noise, thud))

# Level up: quick C-E-G-C arpeggio
arp = [523.25, 659.25, 783.99, 1046.5]
level = mix(*[
    tone(f, 0.12, harm=(1.0, 0.3), decay=4.5, delay=k * 0.09, total=0.48)
    for k, f in enumerate(arp)
])
save("level.wav", level)

# Engine: 1s seamless loop, 70Hz saw-ish + harmonics (integer cycles = no click)
n = RATE  # exactly 1 second
eng = []
for i in range(n):
    t = i / RATE
    s = (math.sin(math.tau * 70 * t) * 0.55
         + math.sin(math.tau * 140 * t) * 0.28
         + math.sin(math.tau * 210 * t) * 0.14
         + math.sin(math.tau * 35 * t + 0.6) * 0.22)
    s *= 0.85 + 0.15 * math.sin(math.tau * 9 * t)  # gentle putter, 9 exact cycles
    eng.append(s * 0.7)
save("engine.wav", eng)

# Game over: descending A-F-D-A lament
down = [440.0, 349.23, 293.66, 220.0]
over = mix(*[
    tone(f, 0.22, harm=(1.0, 0.35, 0.12), decay=3.0, delay=k * 0.17, total=0.9)
    for k, f in enumerate(down)
])
save("gameover.wav", over)

print("done ->", OUT)
