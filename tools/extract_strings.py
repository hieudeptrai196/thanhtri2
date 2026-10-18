#!/usr/bin/env python3
"""Collects player-facing strings and keeps the translation files in step.

Sources: tr("...") in game scripts, string literals on lines marked "# i18n", and display_name /
description / skill_name / skill_description fields of .tres data. Vietnamese is the source language (msgid).
Writes locale/messages.pot and merges every locale/*.po: known translations are kept, new
strings are added empty, strings no longer used are dropped. Prints what is still untranslated.

Usage: python3 tools/extract_strings.py   (from the project root)
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKIP_DIRS = {"tests", "tools", ".godot", "addons"}
STRING = r'"((?:[^"\\]|\\.)*)"'
TR_CALL = re.compile(r'\btr\(\s*' + STRING + r'\s*\)')
LITERAL = re.compile(STRING)
TRES_FIELD = re.compile(r'^(?:display_name|description|skill_name|skill_description) = ' + STRING + r'\s*$', re.M)


def game_files(pattern):
    for path in sorted(ROOT.rglob(pattern)):
        if not SKIP_DIRS.intersection(path.relative_to(ROOT).parts):
            yield path


def collect():
    found = {}  # msgid -> first location
    for path in game_files("*.gd"):
        rel = path.relative_to(ROOT).as_posix()
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if line.lstrip().startswith("#"):
                continue
            strings = TR_CALL.findall(line)
            if "# i18n" in line:
                strings += LITERAL.findall(line.split("# i18n")[0])
            for text in strings:
                found.setdefault(text, f"{rel}:{number}")
    for path in game_files("*.tres"):
        rel = path.relative_to(ROOT).as_posix()
        for text in TRES_FIELD.findall(path.read_text(encoding="utf-8")):
            found.setdefault(text, rel)
    return found


def read_po(path):
    entries, msgid, msgstr, field = {}, None, None, None
    for line in path.read_text(encoding="utf-8").splitlines() + [""]:
        if line.startswith("msgid "):
            if msgid is not None:
                entries[msgid] = msgstr
            msgid, msgstr, field = line[7:-1], "", "id"
        elif line.startswith("msgstr "):
            msgstr, field = line[8:-1], "str"
        elif line.startswith('"') and field:
            if field == "id":
                msgid += line[1:-1]
            else:
                msgstr += line[1:-1]
        elif not line.strip() and msgid is not None:
            entries[msgid] = msgstr
            msgid, field = None, None
    entries.pop("", None)
    return entries


def header(language):
    lang = f'"Language: {language}\\n"\n' if language else ""
    return ('msgid ""\nmsgstr ""\n"Project-Id-Version: THANH TRI\\n"\n'
            '"MIME-Version: 1.0\\n"\n"Content-Type: text/plain; charset=UTF-8\\n"\n"Content-Transfer-Encoding: 8bit\\n"\n'
            + lang + "\n")


def write(path, found, translations, language):
    body = [header(language)]
    for msgid, where in found.items():
        body.append(f"#: {where}\nmsgid \"{msgid}\"\nmsgstr \"{translations.get(msgid, '')}\"\n\n")
    path.write_text("".join(body), encoding="utf-8")


def main():
    found = collect()
    locale = ROOT / "locale"
    locale.mkdir(exist_ok=True)
    write(locale / "messages.pot", found, {}, None)
    print(f"{len(found)} strings -> locale/messages.pot")
    for po in sorted(locale.glob("*.po")):
        old = read_po(po)
        write(po, found, old, po.stem)
        missing = [m for m in found if not old.get(m)]
        print(f"{po.name}: {len(found) - len(missing)}/{len(found)} translated")
        for msgid in missing:
            print(f"  missing: {msgid}")


if __name__ == "__main__":
    main()
