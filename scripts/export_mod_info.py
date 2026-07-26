# 生成于 GLM-5.1
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODS_DIR = ROOT / "mods-unpacked"
ICONS_DIR = ROOT / "static" / "icons"
OUTPUT_FILE = ROOT / "README.md"
ICON_EXTENSIONS = (".png", ".jpg", ".jpeg", ".webp", ".gif")


def load_manifests():
    manifests = []
    for manifest_path in sorted(MODS_DIR.rglob("manifest.json")):
        with open(manifest_path, encoding="utf-8") as f:
            data = json.load(f)
        data["_rel_path"] = manifest_path.parent.name
        manifests.append(data)
    return manifests


def find_icon(name):
    for ext in ICON_EXTENSIONS:
        icon_path = ICONS_DIR / (name + ext)
        if icon_path.is_file():
            return icon_path.relative_to(ROOT).as_posix()
    return None


def build_mod_section(m):
    name = m.get("name", "Unknown")
    version = m.get("version_number", "")
    description = m.get("description", "")
    # 将连续横线分隔行转为 Markdown 水平线，前后加空行
    description = re.sub(r'\n*[-=]{3,}\n*', '\n\n—\n\n', description)
    # Markdown 硬换行：行末两空格
    description = description.replace("\n", "  \n")

    icon_rel = find_icon(name)
    header = f"## {name}"
    if icon_rel:
        header += f" <img src=\"{icon_rel}\" alt=\"{name}\" height=\"32\">"

    section = [header]
    if version:
        section.append(f"**Version:** {version}")
    section.append("")
    section.append(description)
    return "\n".join(section)


def build_readme(manifests):
    sections = [build_mod_section(m) for m in manifests]
    return "# Pathogenic Mods\n\n" + "\n\n---\n\n".join(sections) + "\n"


def main():
    manifests = load_manifests()
    if not manifests:
        print("No mods found.")
        return
    content = build_readme(manifests)
    OUTPUT_FILE.write_text(content, encoding="utf-8")
    print(f"Exported {len(manifests)} mod(s) to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
