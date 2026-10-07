from pathlib import Path

def define_env(env):
    version_file = Path(env.conf["docs_dir"]) / "inotify_version"
    try:
        env.variables["inotify_version"] = version_file.read_text().strip()
    except FileNotFoundError:
        env.variables["inotify_version"] = "latest"
