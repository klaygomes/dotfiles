#!/usr/bin/env python3
"""Place narration line clips on a timeline with pauses. See references/video.md."""
import argparse
import json
import os
import sys


def parse_gaps(raw, count):
    values = [float(v) for v in raw.split(",")]
    return [values[min(i, len(values) - 1)] for i in range(count)]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--index", required=True, help="lines.json from agent-voice script")
    ap.add_argument("--gap", default="0.6", help="pause after each scene in seconds, by meaning; one value or a comma list per boundary")
    ap.add_argument("--lead-in", type=float, default=0.6)
    ap.add_argument("--tail", type=float, default=0.7, help="seconds after the last word; keep the end hold between 0.6 and 1.4")
    ap.add_argument("--fps", type=int, default=30)
    ap.add_argument("--out", default="schedule.json")
    ap.add_argument("--vtt", help="also write WebVTT captions, one cue per line")
    a = ap.parse_args()

    lines = json.load(open(a.index))
    gaps = parse_gaps(a.gap, len(lines))

    t, placed = a.lead_in, []
    for i, line in enumerate(lines):
        placed.append({
            "line": line["i"],
            "text": line["text"],
            "clip": line["clip"],
            "at": round(t - line.get("lead", 0), 3),
            "start": round(t, 3),
            "end": round(t + line["dur"], 3),
            "start_frame": round(t * a.fps),
            "words": [{"word": w["word"], "frame": round((w["start"] + t) * a.fps)} for w in line["words"]],
        })
        t += line["dur"] + (gaps[i] if i < len(lines) - 1 else 0)

    total = round(t + a.tail, 2)
    word_count = sum(len(l["text"].split()) for l in lines)
    wpm = round(word_count / total * 60)
    json.dump({"fps": a.fps, "duration": total, "wpm": wpm, "lines": placed}, open(a.out, "w"), indent=1)

    if a.vtt:
        stamp = lambda s: "%02d:%02d:%06.3f" % (s // 3600, s % 3600 // 60, s % 60)
        cues = ["%d\n%s --> %s\n%s\n" % (p["line"], stamp(p["start"]), stamp(p["end"]), p["text"].strip()) for p in placed]
        open(a.vtt, "w").write("WEBVTT\n\n" + "\n".join(cues))

    for p in placed:
        print("line %02d  %6.2f-%6.2f s  frame %5d  %s" % (p["line"], p["start"], p["end"], p["start_frame"], p["text"][:60]))
    print("duration %.2f s  %d words  %d wpm%s" % (total, word_count, wpm, "  (outside 125-145)" if not 125 <= wpm <= 145 else ""))
    print("mix: --duration %s " % total + " ".join("--vo %s@%s" % (p["clip"], p["at"]) for p in placed))
    print("wrote %s (per-word frames in lines[].words)" % os.path.abspath(a.out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
