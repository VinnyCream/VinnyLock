#!/usr/bin/env bash
# Build APK release và kiểm tra chữ ký trước khi phát hành.
# Cần: Flutter đúng phiên bản trong pubspec, android/key.properties, apksigner trong Android SDK build-tools.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f android/key.properties ]; then
  echo "Thiếu android/key.properties (xem android/key.properties.example)." >&2
  exit 1
fi

flutter pub get
flutter analyze
flutter test
flutter build apk --release

APK="build/app/outputs/flutter-apk/app-release.apk"
APKSIGNER="$(command -v apksigner || true)"
if [ -z "$APKSIGNER" ] && [ -n "${ANDROID_HOME:-}" ]; then
  APKSIGNER="$(ls "$ANDROID_HOME"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -n 1 || true)"
fi
if [ -z "$APKSIGNER" ]; then
  echo "Không tìm thấy apksigner, bỏ qua bước kiểm tra chữ ký." >&2
  exit 1
fi

"$APKSIGNER" verify --print-certs "$APK" | tee /tmp/vinnylock-cert.txt
if grep -qi "Android Debug" /tmp/vinnylock-cert.txt; then
  echo "LỖI: APK đang ký bằng khóa debug." >&2
  exit 1
fi

sha256sum "$APK"
echo "Xong. Ghi lại dấu vân tay SHA-256 của chứng chỉ ở trên vào README để người dùng đối chiếu."
