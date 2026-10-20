#!/usr/bin/env bash
# 本地开发启动脚本。
# 用法：
#   ./dev.sh                 已连接的 Android 设备；没有就启动第一个模拟器
#   ./dev.sh emulator-5554   指定 flutter devices 里的设备 id
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

if ! command -v flutter >/dev/null 2>&1; then
  for candidate in \
    "$HOME/development/flutter/bin" \
    "$HOME/flutter/bin" \
    "$HOME/sdk/flutter/bin"
  do
    if [[ -x "$candidate/flutter" ]]; then
      export PATH="$candidate:$PATH"
      break
    fi
  done
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "找不到 flutter。请先安装并加入 PATH：https://docs.flutter.dev/get-started/install/macos"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "找不到 python3，无法解析 flutter devices 的输出。"
  exit 1
fi

find_android_device() {
  flutter devices --device-timeout 3 --machine | python3 -c '
import json, sys
text = sys.stdin.read()
start, end = text.find("["), text.rfind("]")
if start == -1 or end == -1:
    sys.exit(0)
for device in json.loads(text[start:end + 1]):
    platform = device.get("targetPlatform") or ""
    if platform.startswith("android") and device.get("isSupported", True):
        print(device.get("id", ""))
        break
'
}

echo "安装依赖..."
flutter pub get

DEVICE="${1:-}"

if [[ -z "$DEVICE" ]]; then
  DEVICE="$(find_android_device || true)"
fi

if [[ -z "$DEVICE" ]]; then
  EMULATOR_ID="$(flutter emulators | awk '/•/ && $1 != "Id" { print $1; exit }')"
  if [[ -z "$EMULATOR_ID" ]]; then
    echo "没有已连接的 Android 设备，也没有可用的模拟器。"
    echo "请插上手机并打开 USB 调试，或用 Android Studio 创建一个模拟器后再运行 ./dev.sh"
    exit 1
  fi

  echo "没有已连接的 Android 设备，正在启动模拟器 ${EMULATOR_ID} ..."
  flutter emulators --launch "$EMULATOR_ID"

  echo "等待模拟器就绪..."
  for _ in $(seq 1 40); do
    DEVICE="$(find_android_device || true)"
    if [[ -n "$DEVICE" ]]; then
      break
    fi
    sleep 3
  done
fi

if [[ -z "$DEVICE" ]]; then
  echo "模拟器启动超时。可以先在 Android Studio 里打开模拟器，再重新运行 ./dev.sh"
  exit 1
fi

echo "在 ${DEVICE} 上启动 Random Wiki。热重载按 r，热重启按 R，退出按 q。"
exec flutter run -d "$DEVICE"
