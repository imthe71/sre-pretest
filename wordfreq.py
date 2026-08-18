#!/usr/bin/env python3
"""Print the most frequent word in a UTF-8 text file."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path
import re

# Keep Unicode words and apostrophes inside a word, while ignoring punctuation.
WORD_RE = re.compile(r"[^\W_]+(?:['’][^\W_]+)*", re.UNICODE)


def most_frequent_word(text: str) -> tuple[int, str] | None:
    """Return (count, word), choosing the earliest word when counts tie."""
    words = [word.casefold() for word in WORD_RE.findall(text)]
    if not words:
        return None

    counts = Counter(words)
    first_seen: dict[str, int] = {}
    for index, word in enumerate(words):
        first_seen.setdefault(word, index)

    word, count = max(
        counts.items(),
        key=lambda item: (item[1], -first_seen[item[0]]),
    )
    return count, word


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Find the most frequent word in a UTF-8 text file."
    )
    parser.add_argument("path", nargs="?", default="words.txt")
    args = parser.parse_args()

    text = Path(args.path).read_text(encoding="utf-8")
    result = most_frequent_word(text)
    print("0" if result is None else f"{result[0]} {result[1]}")


if __name__ == "__main__":
    main()
