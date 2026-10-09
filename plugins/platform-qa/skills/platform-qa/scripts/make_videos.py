#!/usr/bin/env python3
"""Build browser-only section videos for a platform-qa report.

Frames come from screenshots (or GIF recordings) of the browser tab itself, so
nothing else on the tester's screen can ever appear in a video.

Two ways to tell it which screenshots belong to which section:

  1. Manifest (preferred) - list each section's screenshot files explicitly:
       python make_videos.py build --out <qa-folder> --manifest manifest.json
     manifest.json:
       {"sections": [
          {"id": "dashboard", "shots": ["C:/.../shot1.jpg", "C:/.../shot2.jpg"]},
          {"id": "agent-support-bot", "gif": "C:/.../support-bot.gif"}
       ]}

  2. Time markers - mark the start of each section while testing, then let the
     script group every screenshot in a folder by file time:
       python make_videos.py mark  --out <qa-folder> dashboard
       python make_videos.py build --out <qa-folder> --shots-dir <screenshot folder>

Output (report.html sits in <qa-folder> and links these):
  <qa-folder>/videos/NN-<id>.mp4          web-ready: faststart, keyframe every 1 s
  <qa-folder>/videos/posters/NN-<id>.jpg  poster for click-to-play

Needs ffmpeg: on PATH, in C:/Tools/ffmpeg, or via `pip install imageio-ffmpeg`.
"""
import argparse
import datetime as dt
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

FRAME_W, FRAME_H = 800, 836          # matches the report's aspect-ratio box
FPS = 12
IMAGE_EXT = (".jpg", ".jpeg", ".png", ".webp")


def find_ffmpeg():
    exe = shutil.which("ffmpeg")
    if exe:
        return exe
    for pattern in ("C:/Tools/ffmpeg/**/ffmpeg.exe", "C:/ffmpeg/**/ffmpeg.exe",
                    os.path.expandvars("%LOCALAPPDATA%/Microsoft/WinGet/Packages/**/ffmpeg.exe"),
                    "/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg"):
        hits = glob.glob(pattern, recursive=True)
        if hits:
            return hits[0]
    try:
        import imageio_ffmpeg  # pip install imageio-ffmpeg (bundles an ffmpeg binary)
        return imageio_ffmpeg.get_ffmpeg_exe()
    except ImportError:
        sys.exit("ffmpeg not found. Install it (winget install Gyan.FFmpeg / brew install ffmpeg / "
                 "apt install ffmpeg) or run: pip install imageio-ffmpeg")


def slug(text):
    return re.sub(r"[^\w\-]+", "-", text).strip("-").lower() or "section"


def run(cmd):
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        raise RuntimeError(res.stderr.strip().splitlines()[-1] if res.stderr.strip() else "ffmpeg failed")


SCALE = (f"scale={FRAME_W}:{FRAME_H}:force_original_aspect_ratio=decrease,"
         f"pad={FRAME_W}:{FRAME_H}:(ow-iw)/2:(oh-ih)/2:color=white,format=yuv420p")
ENCODE = ["-r", str(FPS), "-c:v", "libx264", "-preset", "medium", "-crf", "23",
          "-g", str(FPS), "-keyint_min", str(FPS), "-movflags", "+faststart", "-an"]


def video_from_images(ff, shots, out, seconds):
    """Normalise every screenshot to the same JPEG frame size first: the concat
    demuxer can't mix jpg/png or different sizes."""
    with tempfile.TemporaryDirectory() as tmp:
        frames = []
        for i, shot in enumerate(shots):
            frame = os.path.join(tmp, f"f{i:04d}.jpg")
            try:
                run([ff, "-hide_banner", "-loglevel", "error", "-y", "-i", shot, "-vf", SCALE, "-q:v", "2", frame])
                frames.append(frame)
            except RuntimeError as err:
                print(f"  skipped unreadable frame {os.path.basename(shot)}: {err}")
        if not frames:
            return 0
        listfile = os.path.join(tmp, "list.txt")
        with open(listfile, "w", encoding="utf-8") as fh:
            for frame in frames:
                fh.write(f"file '{frame.replace(os.sep, '/')}'\nduration {seconds}\n")
            fh.write(f"file '{frames[-1].replace(os.sep, '/')}'\n")
        run([ff, "-hide_banner", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0", "-i", listfile,
             "-vf", "format=yuv420p", "-tune", "stillimage", *ENCODE, out])
        return len(frames)


def video_from_gif(ff, gif, out):
    run([ff, "-hide_banner", "-loglevel", "error", "-y", "-i", gif, "-vf", SCALE, *ENCODE, out])
    return 1


def poster(ff, video, out):
    run([ff, "-hide_banner", "-loglevel", "error", "-y", "-ss", "1", "-i", video,
         "-frames:v", "1", "-q:v", "4", out])


def sections_from_markers(qa_dir, shots_dir):
    csv_path = os.path.join(qa_dir, "sections.csv")
    if not os.path.exists(csv_path):
        sys.exit(f"No {csv_path}: run `make_videos.py mark` at the start of each section, or use --manifest.")
    marks = []
    with open(csv_path, encoding="utf-8-sig") as fh:   # -sig: tolerate a BOM (Windows PowerShell adds one)
        for line in fh:
            if line.strip():
                ts, name = line.strip().split(",", 1)
                marks.append((dt.datetime.fromisoformat(ts).timestamp(), name))
    marks.sort()
    shots = sorted((os.path.getmtime(p), p) for p in glob.glob(os.path.join(shots_dir, "*"))
                   if p.lower().endswith(IMAGE_EXT))
    sections = []
    for i, (start, name) in enumerate(marks):
        end = marks[i + 1][0] if i + 1 < len(marks) else float("inf")
        sections.append({"id": name, "shots": [p for t, p in shots if start <= t < end]})
    return sections


def build(args):
    ff = find_ffmpeg()
    qa_dir = os.path.abspath(args.out)
    vid_dir = os.path.join(qa_dir, "videos")
    poster_dir = os.path.join(vid_dir, "posters")
    os.makedirs(poster_dir, exist_ok=True)
    if args.manifest:
        with open(args.manifest, encoding="utf-8-sig") as fh:
            sections = json.load(fh)["sections"]
    elif args.shots_dir:
        sections = sections_from_markers(qa_dir, args.shots_dir)
    else:
        sys.exit("Give --manifest or --shots-dir.")

    results = []
    for n, sec in enumerate(sections, start=1):
        name = f"{n:02d}-{slug(sec['id'])}"
        out = os.path.join(vid_dir, name + ".mp4")
        try:
            if sec.get("gif"):
                used = video_from_gif(ff, sec["gif"], out)
            else:
                shots = [s for s in sec.get("shots", []) if os.path.exists(s)]
                used = video_from_images(ff, shots, out, args.seconds) if shots else 0
            if not used:
                print(f"SKIP {name}: no frames")
                continue
            poster(ff, out, os.path.join(poster_dir, name + ".jpg"))
            print(f"BUILT videos/{name}.mp4 from {used} frame(s)")
            results.append({"section": sec["id"], "video": f"videos/{name}.mp4", "poster": f"videos/posters/{name}.jpg"})
        except RuntimeError as err:
            print(f"FAILED {name}: {err}")
    with open(os.path.join(qa_dir, "videos.json"), "w", encoding="utf-8") as fh:
        json.dump(results, fh, indent=2)
    print(f"{len(results)} video(s); index written to videos.json")


def mark(args):
    qa_dir = os.path.abspath(args.out)
    os.makedirs(qa_dir, exist_ok=True)
    with open(os.path.join(qa_dir, "sections.csv"), "a", encoding="utf-8") as fh:
        fh.write(f"{dt.datetime.now().isoformat(timespec='seconds')},{slug(args.name)}\n")
    print(f"SECTION -> {slug(args.name)}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build", help="build the section videos")
    b.add_argument("--out", required=True, help="QA output folder (report.html goes here)")
    b.add_argument("--manifest", help="JSON listing each section's screenshots or GIF")
    b.add_argument("--shots-dir", help="folder of screenshots, grouped by sections.csv time markers")
    b.add_argument("--seconds", type=float, default=3.0, help="seconds each screenshot is shown")
    b.set_defaults(func=build)
    m = sub.add_parser("mark", help="mark the start of a section now")
    m.add_argument("--out", required=True)
    m.add_argument("name")
    m.set_defaults(func=mark)
    args = p.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
