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

3. 打 release APK 并挂到 GitHub Release（资源名保持 `random-wiki.apk`，README 的下载链接才不会变）：

```bash
flutter build apk --release
gh release create v1.0.4 \
  --title "v1.0.4" \
  --notes "Release notes" \
  --latest \
  build/app/outputs/flutter-apk/app-release.apk#random-wiki.apk
```
