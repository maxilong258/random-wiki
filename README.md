# Random Wiki

**简体中文** | [English](README.en.md)

Random Wiki 的共同仓库，包含 Flutter 应用和独立网页版两个项目。

## 目录结构

```text
random-wiki/
├── flutter/       # 现有 Flutter 应用：源码、测试、平台工程、素材与开发说明
│   ├── lib/
│   ├── test/
│   ├── android/
│   ├── ios/
│   ├── web/       # Flutter 自带的 Web 平台工程
│   ├── pubspec.yaml
│   └── dev.sh
├── web/           # 独立 Next.js 网页版 Random Wiki
├── README.md
├── README.en.md
└── LICENSE
```

两个项目共用根目录的 Git 仓库和许可证，各自的源码、依赖和构建配置放在各自目录中。

## Flutter 应用

应用介绍、截图和下载见 [Flutter 项目说明](flutter/README.md)，开发和发版见 [Flutter 开发说明](flutter/DEVELOPMENT.md)。

从仓库根目录运行：

```bash
cd flutter
./dev.sh
```

也可以进入 `flutter/` 后执行 `flutter pub get` 和 `flutter run`。

## 独立网页版

[web/](web/README.md) 是独立的 Next.js 网站，与 `flutter/web/` 分开维护。

```bash
cd web
pnpm install --frozen-lockfile
./dev.sh
```

本地地址：`http://127.0.0.1:3100`。网页版支持三种内容流、收藏、历史、15 种语言和主题设置，公开维基内容由浏览器直接请求。

## 开源协议

[MIT](LICENSE)
