from ruamel.yaml import YAML
from pathlib import Path
import shutil

BASE_PATH = ''
ADDITION_PATH = ''

def locate_path():
    global BASE_PATH, ADDITION_PATH

    BASE_PATH = Path(__file__).parent / "full"
    if not BASE_PATH.exists():
        print("错误: 找不到同目录下的 full 文件夹")
        return False 
    
    ADDITION_PATH = Path(__file__).parent / "addition"
    if not ADDITION_PATH.exists():
        print("错误: 找不到同目录下的 addition 文件夹")
        return False 
    
    return True 


def patch_default_yaml():
    global BASE_PATH

    yaml = YAML()
    yaml.preserve_quotes = True

    default_yaml = BASE_PATH / "default.yaml"
    with open(default_yaml, "r", encoding="utf-8") as f:
        content = f.read().replace("\t", "    ")
    
    config = yaml.load(content)

    config["ascii_composer"]["switch_key"]["Shift_R"] = "commit_code"

    with open(default_yaml, "w", encoding="utf-8") as f:
        yaml.dump(config, f)

    print("已修改 default.yaml")

def patch_schema_yaml():
    base_path = Path(__file__).parent / "full"

    yaml = YAML()
    yaml.preserve_quotes = True

    schema_yaml = base_path / "rime_ice.schema.yaml"
    with open(schema_yaml, "r", encoding="utf-8") as f:
        content = f.read().replace("\t", "    ")

    config = yaml.load(content)

    config["switches"].insert(0, {"name": "confirm_mode", "states": ["␣", "⏎"]})

    config["engine"]["processors"].insert(0, "lua_processor@*custom_space_enter")

    config["engine"]["filters"].insert(0, "lua_filter@*confirm_mode_filter")

    if "space" in config["editor"]["bindings"]:
        del config["editor"]["bindings"]["space"]
    if "Return" in config["editor"]["bindings"]:
        del config["editor"]["bindings"]["Return"]

    with open(schema_yaml, "w", encoding="utf-8") as f:
        yaml.dump(config, f)

    print("已修改 rime_ice.schema.yaml")


def sync_lua():
    global BASE_PATH, ADDITION_PATH

    src = ADDITION_PATH / "lua"
    dst = BASE_PATH / "lua"

    if not src.exists():
        print("错误: 找不到 addition/lua 文件夹")
        return

    for file in src.iterdir():
        if file.is_file():
            shutil.copy2(file, dst / file.name)
            print(f"已同步: {file.name}")

if __name__ == "__main__":
    if locate_path():
        patch_default_yaml()
        patch_schema_yaml()
        sync_lua()
    input('按回车键以关闭...')
