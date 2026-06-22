"""Download Twemoji PNGs into frontend/assets/pictures/."""

from __future__ import annotations

import json
import urllib.request
from pathlib import Path

VISUAL_TWEMOJI = {
    "house": "1f3e0",
    "tree": "1f333",
    "bird": "1f426",
    "water": "1f4a7",
    "river": "1f30a",
    "sun": "2600",
    "moon": "1f319",
    "stars": "2b50",
    "flower": "1f338",
    "cat": "1f431",
    "dog": "1f436",
    "book": "1f4d6",
    "school": "1f3eb",
    "food": "1f35b",
    "milk": "1f95b",
    "apple": "1f34e",
    "fruit": "1f34e",
    "mother": "1f469",
    "father": "1f468",
    "girl": "1f467",
    "boy": "1f466",
    "child": "1f476",
    "friend": "1f46b",
    "teacher": "1f469-200d-1f3eb",
    "road": "1f6e3",
    "honey": "1f36f",
    "bee": "1f41d",
    "nut": "1f330",
    "mosquito": "1f99f",
    "leaf": "1f343",
    "rabbit": "1f430",
    "fish": "1f41f",
    "animal": "1f43e",
    "village": "1f3d8",
    "market": "1f3ea",
    "classroom": "1f3eb",
    "morning": "1f305",
    "night": "1f303",
    "celebration": "1f389",
    "farming": "1f33e",
    "colors": "1f308",
    "beautiful": "2728",
    "good": "1f44d",
    "happy": "1f60a",
    "come": "1f449",
    "go": "1f6b6",
    "clothes": "1f455",
    "song": "1f3b5",
    "dance": "1f483",
}

ROOT = Path(__file__).resolve().parent.parent / "frontend" / "assets" / "pictures"
URLS = (
    "https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/512x512/{stem}.png",
    "https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/{stem}.png",
)


def _download_png(stem: str) -> bytes:
    last_err: Exception | None = None
    for template in URLS:
        url = template.format(stem=stem)
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "task02/1.0"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                return resp.read()
        except Exception as exc:  # noqa: BLE001 — try next CDN size
            last_err = exc
    raise RuntimeError(f"Could not download twemoji for {stem}") from last_err


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    ok = 0
    for visual, stem in VISUAL_TWEMOJI.items():
        out = ROOT / f"{visual}.png"
        try:
            out.write_bytes(_download_png(stem))
            ok += 1
            print(f"OK {visual}.png")
        except Exception as exc:  # noqa: BLE001
            if out.exists():
                print(f"SKIP {visual}.png (kept existing) — {exc}")
                ok += 1
            else:
                print(f"FAIL {visual}.png — {exc}")

    manifest = {
        "source": "Twemoji (CC-BY 4.0) https://github.com/twitter/twemoji",
        "visuals": {k: f"assets/pictures/{k}.png" for k in VISUAL_TWEMOJI},
    }
    (ROOT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Saved {ok} pictures.")


if __name__ == "__main__":
    main()
