#!/usr/bin/env python3
from collections import Counter
from pathlib import Path
import re
import sys


def main() -> None:
    input_file = Path(sys.argv[1] if len(sys.argv) > 1 else "words.txt")
    text = input_file.read_text(encoding="utf-8").casefold()

    # 取出單字，逗號、句號、驚嘆號等標點不納入統計。
    words = re.findall(r"[^\W_]+(?:'[^\W_]+)?", text)
    if not words:
        return

    counts = Counter(words)
    highest_count = max(counts.values())

    # 最高次數同分時全部輸出，排序後結果會固定。
    for word in sorted(word for word, count in counts.items() if count == highest_count):
        print(f"{highest_count} {word}")


if __name__ == "__main__":
    main()
