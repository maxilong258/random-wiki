# Random Wiki Web

独立的 Next.js 网页阅读器，使用真实的 Wikipedia、Wikivoyage 和 Wikimedia Commons 接口。浏览器直接获取公开内容，当前不使用 Cloudflare Functions，也不需要环境变量或数据库。

## 本地运行

需要 Node.js 22.18 或更新版本，以及 pnpm。

```bash
cd web
pnpm install --frozen-lockfile
./dev.sh
```

访问 `http://127.0.0.1:3100`。如端口被占用，可以执行 `pnpm exec next dev --hostname 127.0.0.1 --port 3101`。

## 功能

- 精简阅读布局：顶部切换内容，桌面左右图文、手机上下排版；无图或图片加载失败时使用纯文字布局，深度、主题和来源说明收纳在设置中。
- 三种内容流：随机百科、历史上的今天、旅行指南；支持按钮、方向键、滚轮和手机上下滑动。
- 五档文章深度：热门、熟知、均衡、小众、冷门，沿用 Flutter 的基础词条及阅读量筛选规则。
- 15 种界面及百科语言，阿拉伯语、希伯来语支持 RTL；部分旅行语种及不可用的历史事件语种回退为英语并提示。
- 摘要详情、相关词条、图片缩放和平移、图片署名、来源网页与系统分享／复制链接。
- 本地收藏及最近 100 条阅读历史，保存在 IndexedDB；主题、语言和深度保存在 localStorage。
- 浅色、深色、跟随系统；手机和桌面自适应布局。
- 文章及批次缓存 1 天、基础词条清单 7 天、历史事件按本地当天缓存；失败时尝试复用仍有效的缓存。

详情为来源导语或事件摘要，完整正文通过原文链接打开。本地存储与 Flutter 应用互不相通；浏览器清理数据会移除收藏和历史。缓存不提供完整离线启动。外部内容是否可达取决于当前网络和来源接口。

## 验证

```bash
pnpm typecheck
pnpm test
pnpm build
```

生产构建会静态导出到 `out/`。普通 Next.js 开发服务即可进行本地预览。

## Cloudflare Pages

线上地址：[randomwiki.maxilong.dev](https://randomwiki.maxilong.dev/)。Pages 项目为 `random-wiki`，生产分支为 `main`，默认域名为 [random-wiki.pages.dev](https://random-wiki.pages.dev/)。

当前采用本地构建、Wrangler 直接上传，未连接 Git 自动部署。在本目录登录 Wrangler 后，运行以下命令即可更新线上版本：

```bash
CF_PAGES_PROJECT=random-wiki ./prod.sh
```

脚本先执行 `pnpm build`，再上传 `out/`，不会提交或推送 Git，也不会部署 Flutter 项目。`randomwiki.maxilong.dev` 已登记为 Pages 自定义域名，对应的代理 CNAME 指向 `random-wiki.pages.dev`，后续更新内容无需修改 DNS。

访问统计统一使用 `maxilong.dev` 域名层自动注入的 Cloudflare Web Analytics。在 Cloudflare 的 Web Analytics 中选择 `maxilong.dev`，再按 Host 筛选 `randomwiki.maxilong.dev`。Pages 项目的独立统计保持关闭，源码中无需添加统计脚本；判断是否接入时应同时检查域名层配置和浏览器实际加载的脚本。当前域名统计沿用排除欧盟访客的设置。

## 项目关系与许可

Flutter 应用位于 `../flutter/`；其中的 `../flutter/web/` 是 Flutter 自带的 Web 平台工程。本目录独立维护。

应用代码使用仓库根目录的 [MIT 许可证](../LICENSE)。维基文字的原文和 CC BY-SA 链接在详情中保留；图片许可及作者以各文件说明页为准，可从图片预览访问。
