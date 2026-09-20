# 本地开发

当前版本见 `pubspec.yaml` 的 `version` 字段，格式是 `versionName+versionCode`，例如 `1.0.4+6`。

## 运行

启动安卓模拟器：

```bash
emulator -avd Pixel_7_API_35
```

启动 Flutter：

```bash
flutter run
```

## 签名

发布包需要本地签名文件，**不要提交到 Git**：

- `android/key.properties`
- `android/upload-keystore.jks`

可从示例复制后填入真实密码：

```bash
cp android/key.properties.example android/key.properties
```

## 发版

1. 改 `pubspec.yaml` 的 `version`：商店或 GitHub 每发一包，`versionCode` 必须比上次大。
2. 提交后打 tag，名字与 `versionName` 一致：

```bash
git tag v1.0.4
git push origin v1.0.4
```

3. 按架构打 APK，改成带版本号的文件名后挂到 GitHub Release。`random-wiki-arm64-v8a.apk` 不要带版本号，README 直链才不会变：

```bash
flutter build apk --release --split-per-abi

VERSION=1.0.5
OUT=build/app/outputs/flutter-apk
mkdir -p build/github-release
cp "$OUT/app-arm64-v8a-release.apk" "build/github-release/random-wiki-$VERSION-arm64-v8a.apk"
cp "$OUT/app-armeabi-v7a-release.apk" "build/github-release/random-wiki-$VERSION-armeabi-v7a.apk"
cp "$OUT/app-x86_64-release.apk" "build/github-release/random-wiki-$VERSION-x86_64.apk"
cp "$OUT/app-arm64-v8a-release.apk" "build/github-release/random-wiki-arm64-v8a.apk"

gh release create "v$VERSION" \
  --title "v$VERSION" \
  --notes "Release notes" \
  --latest \
  build/github-release/random-wiki-$VERSION-arm64-v8a.apk \
  build/github-release/random-wiki-$VERSION-armeabi-v7a.apk \
  build/github-release/random-wiki-$VERSION-x86_64.apk \
  build/github-release/random-wiki-arm64-v8a.apk
```
