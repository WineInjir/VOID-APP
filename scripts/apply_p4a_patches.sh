#!/usr/bin/env bash
# Local patches for the python-for-android checkout that buildozer manages
# under .buildozer/android/platform/python-for-android. That checkout is a
# plain git clone which buildozer can silently reset to upstream HEAD
# (re-clone, checkout, etc.), wiping these edits. Run this manually after
# such a reset (e.g. build.sh fails with the pip ImportError or the app
# crashes after the loading screen with a materialyoucolor
# ModuleNotFoundError) and before building again.
set -e
cd "$(dirname "$0")/.."

P4A_DIR=".buildozer/android/platform/python-for-android"
BUILD_PY="$P4A_DIR/pythonforandroid/build.py"
MYC_RECIPE="$P4A_DIR/pythonforandroid/recipes/materialyoucolor/__init__.py"

apply_patches() {
    # 1. Skip p4a's "pip install -U pip" self-upgrade in the temporary
    #    build venv. Running concurrently with other build steps, this was
    #    observed to corrupt pip's own install via a race in its
    #    self-replacement (ImportError: cannot import name
    #    'BuildDependencyInstallError'). The venv's bundled pip is fine
    #    without upgrading.
    if [ -f "$BUILD_PY" ]; then
        python3 - "$BUILD_PY" <<'PYEOF'
import sys

path = sys.argv[1]
old = (
    "        # Prepare base environment and upgrade pip:\n"
    "        base_env = dict(copy.copy(os.environ))\n"
    "        base_env[\"PYTHONPATH\"] = ctx.get_site_packages_dir(arch)\n"
    "        info('Upgrade pip to latest version')\n"
    "        shprint(sh.bash, '-c', (\n"
    "            \"source venv/bin/activate && pip install -U pip\"\n"
    "        ), _env=copy.copy(base_env))\n"
)
new = (
    "        # Prepare base environment (skip self-upgrading pip: doing so while\n"
    "        # other build steps run concurrently has been observed to corrupt\n"
    "        # pip's own install via a race in its self-replacement).\n"
    "        base_env = dict(copy.copy(os.environ))\n"
    "        base_env[\"PYTHONPATH\"] = ctx.get_site_packages_dir(arch)\n"
)

text = open(path).read()
if new in text:
    print("  [patch] build.py: already applied, skipping")
elif old in text:
    open(path, "w").write(text.replace(old, new))
    print("  [patch] build.py: pip self-upgrade step removed")
else:
    print("  [patch] build.py: expected block not found (upstream changed?), skipping")
PYEOF
    else
        echo "  [patch] build.py: not found yet (python-for-android not cloned), skipping"
    fi

    # 2. Bump the materialyoucolor recipe from 2.0.10 to 3.0.3. buildozer.spec
    #    pulls KivyMD from the master branch, which imports
    #    materialyoucolor.dynamiccolor.color_spec — a module that doesn't
    #    exist until materialyoucolor 3.x. Without this the app crashes
    #    right after the loading screen with ModuleNotFoundError.
    if [ -f "$MYC_RECIPE" ]; then
        if grep -q 'version = "3.0.3"' "$MYC_RECIPE"; then
            echo "  [patch] materialyoucolor recipe: already at 3.0.3, skipping"
        else
            sed -i 's/version = "2\.0\.10"/version = "3.0.3"/' "$MYC_RECIPE"
            echo "  [patch] materialyoucolor recipe: bumped to 3.0.3"
        fi
    else
        echo "  [patch] materialyoucolor recipe: not found yet, skipping"
    fi
}

apply_patches
