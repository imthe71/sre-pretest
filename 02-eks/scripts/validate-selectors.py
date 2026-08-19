#!/usr/bin/env python3
"""Check Service selectors against Deployment/StatefulSet pod-template labels.

This intentionally reads the rendered manifests with the small YAML subset used in
this repository, so the check has no third-party Python dependency.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path


def indentation(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def mapping_below(lines: list[str], start: int, parent_indent: int) -> dict[str, str]:
    """Read scalar key/value entries directly below a YAML mapping node."""
    result: dict[str, str] = {}
    child_indent: int | None = None
    for line in lines[start + 1 :]:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        current = indentation(line)
        if current <= parent_indent:
            break
        if child_indent is None:
            child_indent = current
        if current != child_indent:
            continue
        match = re.match(r"\s*([^:#]+):\s*(.*?)\s*$", line)
        if match:
            result[match.group(1).strip()] = match.group(2).strip().strip('"\'')
    return result


def first_index(lines: list[str], pattern: str, start: int = 0) -> int | None:
    regex = re.compile(pattern)
    for index in range(start, len(lines)):
        if regex.match(lines[index]):
            return index
    return None


def top_metadata(lines: list[str]) -> tuple[str, str]:
    metadata = first_index(lines, r"^metadata:\s*$")
    if metadata is None:
        return "", "default"
    values = mapping_below(lines, metadata, 0)
    return values.get("name", ""), values.get("namespace", "default")


def pod_template_labels(lines: list[str]) -> dict[str, str]:
    template = first_index(lines, r"^  template:\s*$")
    if template is None:
        return {}
    metadata = first_index(lines, r"^    metadata:\s*$", template + 1)
    if metadata is None:
        return {}
    labels = first_index(lines, r"^      labels:\s*$", metadata + 1)
    if labels is None:
        return {}
    return mapping_below(lines, labels, 6)


def service_selector(lines: list[str]) -> dict[str, str]:
    selector = first_index(lines, r"^  selector:\s*$")
    if selector is None:
        return {}
    return mapping_below(lines, selector, 2)


def documents(path: Path):
    content = path.read_text(encoding="utf-8-sig")
    for document in re.split(r"^---\s*$", content, flags=re.MULTILINE):
        lines = document.splitlines()
        if any(line.strip() and not line.lstrip().startswith("#") for line in lines):
            yield lines


def value_at_root(lines: list[str], key: str) -> str:
    index = first_index(lines, rf"^{re.escape(key)}:\s*(.+?)\s*$")
    return "" if index is None else lines[index].split(":", 1)[1].strip().strip('"\'')


def main(directory: str) -> int:
    workloads: list[tuple[str, str, str, dict[str, str]]] = []
    services: list[tuple[str, str, dict[str, str]]] = []

    for path in sorted(Path(directory).glob("*.yaml")):
        for lines in documents(path):
            kind = value_at_root(lines, "kind")
            name, namespace = top_metadata(lines)
            if kind in {"Deployment", "StatefulSet", "DaemonSet", "Job"}:
                workloads.append((kind, name, namespace, pod_template_labels(lines)))
            elif kind == "Service":
                services.append((name, namespace, service_selector(lines)))

    failures: list[str] = []
    for name, namespace, selector in services:
        if not selector:
            continue
        targets = [
            f"{kind}/{workload_name}"
            for kind, workload_name, workload_namespace, labels in workloads
            if workload_namespace == namespace
            and all(labels.get(key) == value for key, value in selector.items())
        ]
        if targets:
            print(f"PASS Service/{name} -> {', '.join(targets)}")
        else:
            failures.append(f"Service/{name} selector {selector} has no matching workload pod template")

    if failures:
        print("FAIL " + "\nFAIL ".join(failures), file=sys.stderr)
        return 1
    print("All Service selectors match a workload pod template.")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {Path(sys.argv[0]).name} <rendered-manifest-directory>", file=sys.stderr)
        raise SystemExit(2)
    raise SystemExit(main(sys.argv[1]))
