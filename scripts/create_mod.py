#!/usr/bin/env python3
# 生成于 GLM-5.1
"""生成 Pathogenic ModLoader 空mod骨架"""

import json
import os
import sys

ME = "YukkuriC"
MANIFEST_TEMPLATE = {
    "dependencies": [],
    "description": "中文：\n----------\nEnglish：\n",
    "extra": {
        "godot": {
            "authors": [ME],
            "compatible_game_version": [],
            "compatible_mod_loader_version": ["7.0.0"],
            "config_schema": {},
            "description_rich": "",
            "image": None,
            "incompatibilities": [],
            "load_before": [],
            "optional_dependencies": [],
            "tags": [],
        }
    },
    "name": "",
    "namespace": ME,
    "version_number": "1.0.0",
    "website_url": "",
}

MOD_MAIN_TEMPLATE = """extends Node

const MOD_DIR := "{mod_dir_name}"
const LOG_NAME := MOD_DIR + ":Main"

func _init() -> void:
\tModLoaderLog.info("Init", LOG_NAME)
"""


OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "mods-unpacked")


def create_mod(name: str) -> None:
    mod_dir_name = f"{ME}-{name}"
    mod_dir = os.path.join(OUTPUT_DIR, mod_dir_name)

    if os.path.exists(mod_dir):
        raise FileExistsError(f"目录已存在: {mod_dir}")

    os.makedirs(mod_dir, exist_ok=True)

    # manifest.json
    manifest = json.loads(json.dumps(MANIFEST_TEMPLATE))  # deep copy
    manifest["name"] = name
    with open(os.path.join(mod_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent="\t", ensure_ascii=False)
        f.write("\n")

    # mod_main.gd
    with open(os.path.join(mod_dir, "mod_main.gd"), "w", encoding="utf-8") as f:
        f.write(MOD_MAIN_TEMPLATE.format(mod_dir_name=mod_dir_name))


def main():
    if len(sys.argv) > 1:
        name = " ".join(sys.argv[1:])
    else:
        name = input("Mod名称: ").strip()

    if not name:
        print("名称不能为空")
        sys.exit(1)

    create_mod(name)
    print(f"已生成: {ME}-{name}")


if __name__ == "__main__":
    main()
