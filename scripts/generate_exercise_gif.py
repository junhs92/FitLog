"""Generate the dumbbell bench press demo GIF.

Mirrors the geometry in
lib/features/exercises/widgets/dumbbell_bench_press_painter.dart so the
committed animation stays in sync with the in-app rendering.

Usage:
    python3 scripts/generate_exercise_gif.py
"""

from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw

REPO_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_PATH = REPO_ROOT / "assets" / "animations" / "dumbbell_bench_press.gif"

CANVAS_W, CANVAS_H = 480, 320
FRAMES = 40
FRAME_DURATION_MS = 50

BG = (248, 249, 250)
BODY = (76, 110, 245)
HEAD = (55, 58, 64)
BENCH = (144, 146, 150)
DUMBBELL = (26, 27, 30)
FLOOR = (222, 226, 230)


def _lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def _p(cx: float, cy: float, u: float, x: float, y: float) -> tuple[float, float]:
    return cx + x * u, cy + y * u


def _thick_line(
    draw: ImageDraw.ImageDraw,
    a: tuple[float, float],
    b: tuple[float, float],
    width: float,
    color: tuple[int, int, int],
) -> None:
    draw.line([a, b], fill=color, width=max(1, int(round(width))))
    r = max(1, int(round(width / 2)))
    for point in (a, b):
        x, y = point
        draw.ellipse((x - r, y - r, x + r, y + r), fill=color)


def _draw_dumbbell(
    draw: ImageDraw.ImageDraw, hand: tuple[float, float], u: float
) -> None:
    bx, by = hand
    bar_w = 1.4 * u
    bar_h = 0.18 * u
    draw.rounded_rectangle(
        (bx - bar_w / 2, by - bar_h / 2, bx + bar_w / 2, by + bar_h / 2),
        radius=max(1, int(round(0.05 * u))),
        fill=DUMBBELL,
    )
    plate_w = 0.32 * u
    plate_h = 0.8 * u
    for offset in (-0.55 * u, 0.55 * u):
        draw.rounded_rectangle(
            (
                bx + offset - plate_w / 2,
                by - plate_h / 2,
                bx + offset + plate_w / 2,
                by + plate_h / 2,
            ),
            radius=max(1, int(round(0.08 * u))),
            fill=DUMBBELL,
        )


def render_frame(progress: float) -> Image.Image:
    img = Image.new("RGB", (CANVAS_W, CANVAS_H), BG)
    draw = ImageDraw.Draw(img)

    u = min(CANVAS_W, CANVAS_H) / 10.0
    cx, cy = CANVAS_W / 2, CANVAS_H / 2

    def p(x: float, y: float) -> tuple[float, float]:
        return _p(cx, cy, u, x, y)

    draw.line([p(-5, 2.7), p(5, 2.7)], fill=FLOOR, width=max(1, int(round(0.1 * u))))

    bench_tl = p(-4, 0.3)
    bench_br = p(4, 1.0)
    draw.rounded_rectangle(
        (bench_tl[0], bench_tl[1], bench_br[0], bench_br[1]),
        radius=max(1, int(round(0.2 * u))),
        fill=BENCH,
    )

    for lx in (-3.2, 2.8):
        a = p(lx, 1.0)
        b = p(lx + 0.4, 2.7)
        draw.rectangle((a[0], a[1], b[0], b[1]), fill=BENCH)

    phase = (1 - math.cos(2 * math.pi * progress)) / 2

    head_center = p(-3.2, -0.2)
    head_r = 0.5 * u
    draw.ellipse(
        (
            head_center[0] - head_r,
            head_center[1] - head_r,
            head_center[0] + head_r,
            head_center[1] + head_r,
        ),
        fill=HEAD,
    )

    neck = p(-2.6, -0.05)
    hip = p(1.5, 0.1)
    _thick_line(draw, neck, hip, 0.55 * u, BODY)

    knee = p(2.7, -0.3)
    foot = p(3.2, 1.0)
    _thick_line(draw, hip, knee, 0.42 * u, BODY)
    _thick_line(draw, knee, foot, 0.42 * u, BODY)

    shoulder = p(-2.3, -0.05)
    l1 = 1.3 * u
    l2 = 1.3 * u

    wrist_height = _lerp(0.3 * u, (l1 + l2) * 0.98, phase)
    wrist = (shoulder[0], shoulder[1] - wrist_height)

    d = wrist_height
    cos_shoulder = max(-1.0, min(1.0, (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)))
    shoulder_angle = math.acos(cos_shoulder)
    elbow = (
        shoulder[0] + math.sin(shoulder_angle) * l1,
        shoulder[1] - math.cos(shoulder_angle) * l1,
    )

    back_dy = 0.18 * u
    shoulder_b = (shoulder[0], shoulder[1] + back_dy)
    elbow_b = (elbow[0], elbow[1] + back_dy)
    wrist_b = (wrist[0], wrist[1] + back_dy)

    _thick_line(draw, shoulder_b, elbow_b, 0.34 * u, BODY)
    _thick_line(draw, elbow_b, wrist_b, 0.34 * u, BODY)
    _draw_dumbbell(draw, wrist_b, u)

    _thick_line(draw, shoulder, elbow, 0.34 * u, BODY)
    _thick_line(draw, elbow, wrist, 0.34 * u, BODY)
    _draw_dumbbell(draw, wrist, u)

    return img


def main() -> None:
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    frames = [render_frame(i / FRAMES) for i in range(FRAMES)]
    palette_frames = [f.quantize(colors=64, method=Image.Quantize.MEDIANCUT) for f in frames]
    palette_frames[0].save(
        OUTPUT_PATH,
        save_all=True,
        append_images=palette_frames[1:],
        duration=FRAME_DURATION_MS,
        loop=0,
        optimize=True,
        disposal=2,
    )
    size_kb = os.path.getsize(OUTPUT_PATH) / 1024
    print(f"Wrote {OUTPUT_PATH.relative_to(REPO_ROOT)} ({size_kb:.1f} KB, {FRAMES} frames)")


if __name__ == "__main__":
    main()
