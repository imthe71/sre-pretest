#!/usr/bin/env python3

from collections import Counter
from pathlib import Path
import re
import sys

WORD_RE = re.compile(r"[^\W_]+(?:['’][^\W_]+)*", re.UNICODE)


def most_frequent_word(text: str):
    words = [word.casefold() for word in WORD_RE.findall(text)]
    if not words:
        return None

    counts = Counter(words)
    first_seen = {}
    for index, word in enumerate(words):
        if word not in first_seen:
            first_seen[word] = index

    word, count = max(
        counts.items(),
        key=lambda item: (item[1], -first_seen[item[0]]),
    )
    return count, word


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "words.txt"
    text = Path(path).read_text(encoding="utf-8")
    result = most_frequent_word(text)

    if result is None:
        print("0")
    else:
        count, word = result
        print(f"{count} {word}")


if __name__ == "__main__":
    main()
