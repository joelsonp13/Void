# -*- coding: utf-8 -*-
"""Migra TweenService:Create(a, TweenInfo.new(...), {props}):Play() -> rfTween(a, {props}, \"Motion\")."""

import re


def infer_motion(tweeninfo_inner: str) -> str:
    if "Elastic" in tweeninfo_inner:
        return "Elastic"
    if "Back" in tweeninfo_inner:
        return "Bouncy"
    if "Exponential" in tweeninfo_inner:
        return "Emphasis"
    if "Quint" in tweeninfo_inner:
        return "Smooth"
    if "Quad" in tweeninfo_inner or "Sine" in tweeninfo_inner:
        return "Fast"
    return "Smooth"


def skip_ws(s: str, i: int) -> int:
    while i < len(s) and s[i] in " \t\n\r":
        i += 1
    return i


def parse_delimited(s: str, start: int, open_ch: str, close_ch: str) -> tuple[str | None, int]:
    if start >= len(s) or s[start] != open_ch:
        return None, start
    depth = 0
    i = start
    in_str: str | None = None
    escape = False
    while i < len(s):
        c = s[i]
        if escape:
            escape = False
            i += 1
            continue
        if in_str:
            if c == "\\":
                escape = True
            elif c == in_str:
                in_str = None
            i += 1
            continue
        if c in ('"', "'"):
            in_str = c
            i += 1
            continue
        if c == open_ch:
            depth += 1
        elif c == close_ch:
            depth -= 1
            if depth == 0:
                return s[start : i + 1], i + 1
        i += 1
    return None, start


def parse_arg(s: str, start: int) -> tuple[str, int] | None:
    i = skip_ws(s, start)
    arg_start = i
    paren = brace = sq = 0
    in_str: str | None = None
    escape = False
    while i < len(s):
        c = s[i]
        if escape:
            escape = False
            i += 1
            continue
        if in_str:
            if c == "\\":
                escape = True
            elif c == in_str:
                in_str = None
            i += 1
            continue
        if c in ('"', "'"):
            in_str = c
            i += 1
            continue
        if c == "(":
            paren += 1
        elif c == ")":
            paren -= 1
        elif c == "{":
            brace += 1
        elif c == "}":
            brace -= 1
        elif c == "[":
            sq += 1
        elif c == "]":
            sq -= 1
        elif c == "," and paren == 0 and brace == 0 and sq == 0:
            return s[arg_start:i].strip(), i + 1
        i += 1
    return None


def try_replace_at(s: str, idx: int) -> tuple[str, int] | None:
    needle = "TweenService:Create("
    if not s.startswith(needle, idx):
        return None
    pos = idx + len(needle)
    r1 = parse_arg(s, pos)
    if not r1:
        return None
    arg1, pos = r1
    pos = skip_ws(s, pos)
    if not s.startswith("TweenInfo.new", pos):
        return None
    pos2 = pos + len("TweenInfo.new")
    pos2 = skip_ws(s, pos2)
    if pos2 >= len(s) or s[pos2] != "(":
        return None
    ti_full, after_ti = parse_delimited(s, pos2, "(", ")")
    if ti_full is None:
        return None
    pos = skip_ws(s, after_ti)
    if pos >= len(s) or s[pos] != ",":
        return None
    pos += 1
    pos = skip_ws(s, pos)
    if pos >= len(s) or s[pos] != "{":
        return None
    props_full, after_props = parse_delimited(s, pos, "{", "}")
    if props_full is None:
        return None
    pos = skip_ws(s, after_props)
    m = re.match(r"\)\s*:Play\(\)", s[pos:])
    if not m:
        return None
    end = pos + m.end()

    inner = ti_full[1:-1]
    motion = infer_motion(inner)
    replacement = f'rfTween({arg1}, {props_full}, "{motion}")'
    return s[:idx] + replacement + s[end:], idx + len(replacement)


def main():
    path = "source.lua"
    with open(path, "r", encoding="utf-8") as f:
        s = f.read()

    subs = 0
    i = 0
    needle = "TweenService:Create("
    while True:
        idx = s.find(needle, i)
        if idx == -1:
            break
        window = s[idx : idx + 260]
        # Apenas o fallback interno de rfTween (Quint + Direction.Out explícitos)
        if "TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)" in window:
            i = idx + len(needle)
            continue
        res = try_replace_at(s, idx)
        if not res:
            i = idx + len(needle)
            continue
        s, new_i = res
        subs += 1
        i = idx

    remaining = s.count("TweenService:Create(")
    with open(path, "w", encoding="utf-8") as f:
        f.write(s)
    print(f"Migrated {subs} -> rfTween")
    print(f"Remaining TweenService:Create: {remaining}")


if __name__ == "__main__":
    main()
