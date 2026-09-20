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

3. 打 release APK 并挂到 GitHub Release。文件名保持 `app-release.apk`，和 README 直链一致：

```bash
flutter build apk --release
gh release create v1.0.5 \
  --title "v1.0.5" \
  --notes "Release notes" \
  --latest \
  build/app/outputs/flutter-apk/app-release.apk
```
