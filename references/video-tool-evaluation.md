# 平台检索工具调研与验收

观察日期：2026-10-17。目标是让使用者能按动作关键词搜索三大平台，并得到视频/笔记标题、作者、原站链接或搜索关键词；登录可以由使用者在本地完成。测试只使用临时目录和公开入口，不读取或保存用户的 Cookie、Token、密码或验证码。

## 当前选择

| 平台 | 推荐入口 | 登录 | 验收状态 | 适合 skill 的输出 |
|---|---|---:|---|---|
| B 站 | `public-clis/bilibili-cli` | 搜索通常不需要 | 已实测搜索、热门、排行榜 | BV、标题、作者、播放量、原站 URL |
| B 站转录能力 | `XZXZZX-Ai/bilibili-mcp` | 视视频能力而定 | 仅记录为工具背景，不纳入本 skill 默认流程 | 不使用转录；仅保留标题和链接 |
| 抖音 | `Youhai020616/douyin`（`dy`） | 搜索需要扫码登录 | 已实测安装、帮助和无登录失败返回 | 登录后返回视频 ID、标题、作者和原站 URL |
| 抖音 MCP | `juziguai/douyin-mcp-server` | 搜索需要登录；公开分享链接可读取 | 源码可编译；当前环境依赖未完整安装 | MCP/CLI 结果或登录失败原因 |
| 抖音无 Cookie 后备 | [EpicSaber/douyin-analytics-scraper](https://github.com/EpicSaber/douyin-analytics-scraper) | Apify OAuth/可能付费代理 | 只核验仓库说明，未调用外部账户 | 小样本元数据，需自行规范化原站 URL |
| 小红书 | `xpzouying/xiaohongshu-mcp`（macOS Apple Silicon） | 需要扫码登录 | 官方发行版入口已核验；未代替使用者扫码 | 原站链接、标题、作者、视频筛选结果 |
| 小红书只读 | `sinmentis/xiaohongshu-mcp-readonly` | 需要扫码登录 | Go 源码检查通过；当前环境无 Go，未运行服务 | 只读搜索结果 |
| 小红书无 Cookie 后备 | [habit.zhou/xiaohongshu-pro-scraper](https://apify.com/habit.zhou/xiaohongshu-pro-scraper) | Apify OAuth/费用 | 只核验公开 Actor 说明，未调用外部账户 | 视频笔记、互动数据和原站链接 |
| 三平台统一 | `JNHFlow21/social-media-toolkit` | 默认不依赖登录 | 临时 venv 安装成功，`socialkit --help` 和 `doctor` 成功 | 统一元数据；失败时回退平台专用工具 |
| 三平台浏览器后备 | `ywleeo/browser-mcp` | 使用真实 Chrome 登录态 | 当前环境 Python 3.11，仓库要求 Python 3.12；未启动 | 登录后的搜索结果和原站链接 |

## 配置方式

训练档案和计划生成不需要 Python。若不希望安装 Python 或第三方工具，直接使用 B 站、抖音和小红书官方搜索页即可；这些链接和关键词路径是 skill 的通用兼容模式。

运行视频工具前先执行依赖预检：

```bash
fitness-coach/scripts/check-video-tools.sh
```

缺少依赖时，先让用户选择官方搜索页、用户目录安装、临时环境或跳过视频资源。只有用户选择安装后，才运行下面的工具命令。

这些命令只安装或启动本地工具；第一次登录由使用者在本地浏览器完成：

```bash
# B 站：公开搜索可直接使用
uv tool install bilibili-cli
bili search "杠铃深蹲 动作" --type video --max 3 --yaml

# 抖音：关键词搜索前先在专用浏览器扫码登录
pip install dy-cli
playwright install chromium
dy init
dy search "杠铃深蹲" --sort 最多点赞 --type video --json-output

# 小红书：macOS Apple Silicon 下载对应发行版后
./xiaohongshu-login-darwin-arm64
./xiaohongshu-mcp-darwin-arm64
# 然后由 MCP 客户端调用搜索工具

# 三平台真实 Chrome 后备
pip install ai-browser-mcp
uv run browser-mcp
```

不要把这些命令中的登录过程改成在聊天里粘贴 Cookie 或 Token。

## 默认使用方式

计划生成后，skill 会为计划中的每个动作自动执行三次搜索：B 站、抖音、小红书。使用者只需提供动作和目标，例如“给我找杠铃深蹲的教学资源”；不需要重复指定平台。结果表会固定包含三个平台行：成功时给原站链接，登录失败时给官方搜索页和关键词。

使用者明确同意安装后，skill 运行项目内的幂等安装脚本：

```bash
fitness-coach/scripts/install-video-tools.sh --all
```

需要隔离本次运行时使用：

```bash
fitness-coach/scripts/install-video-tools.sh --all --temporary
```

该模式仍可能需要 Python 3.10+；如果系统没有 Python，回退到不安装的官方搜索页模式，或先询问是否允许安装 Python。

安装前可用 `--dry-run` 查看命令。脚本只安装搜索工具、依赖和浏览器，不执行登录，不读取 Cookie，不写入 Token；安装状态由 skill 记录到 `fitness-data/video-tools.md`。

## 实际验收

### B 站：成功

临时安装的 `bilibili-cli` 0.6.2 执行：

```bash
PYTHONPATH=/private/tmp/bili-cli-test python -m bili_cli.cli search '杠铃深蹲 动作' --type video --max 3 --yaml
```

成功返回真实候选，例如：

- `BV1FU9LB5EGf`，标题“三分半学会标准杠铃深蹲，解剖级细节教学！(新手必看)”，作者“小崔的健身笔记”，播放量约 35368。
- `BV1UD4y1y7kV`，标题“杠铃深蹲，这样你还学不会可说不过去啦。”，作者“狮子王鑫的健身课堂”，播放量约 161242。

skill 应把 BV 转成 `https://www.bilibili.com/video/<BV>`，并把播放量标为检索时快照。`status` 正确返回 `not_authenticated`；详情接口和直接公开 API 在当前出口曾遇到 HTTP 412，因此不能把详情失败误判成“没有视频”。

### 抖音：登录后可用，未登录失败可识别

`dy` CLI 安装和帮助命令成功。无登录 Cookie 执行关键词搜索返回结构化登录失败，提示先登录；因此流程应提示用户扫码后重试。`juziguai/douyin-mcp-server` 也明确区分 `douyin_search_login_required` 与网络/签名错误。

没有登录时，网页索引可以找到部分 `https://www.douyin.com/video/<id>` 原站页面，但只能标记 `web_indexed`，不声称这是完整平台排序或已查看视频内容。

### 小红书：只读 MCP，登录后可用

`xpzouying/xiaohongshu-mcp` 提供 macOS Apple Silicon 发行版和独立登录工具；登录后可进行内容搜索。`sinmentis/xiaohongshu-mcp-readonly` 仍作为 Linux/只读后备。当前环境没有 Go 和扫码登录条件，因此没有盲目启动真实搜索。

### 统一工具：可启动但不能替代平台专用回退

`social-media-toolkit` 临时安装成功，`socialkit --help` 和 `socialkit doctor` 成功。对 B 站视频详情的 `inspect` 在当前出口返回 HTTP 412；对抖音公开 URL 的 `inspect` 无法解析视频 JSON。它适合作为统一接口的第一尝试，失败后必须回退到平台专用工具或搜索链接。

## 运行策略

1. 先检查工具是否安装和登录状态，不把“工具存在”当作“搜索成功”。
2. 运行平台关键词搜索，先匹配用户指定博主或头部/专业博主，再使用收藏、点赞、播放、评论等互动数据排序。
3. 只保留原站页面 URL；不输出临时 CDN、下载地址、Cookie、Token 或签名参数。
4. 登录失败时提示用户本地扫码/登录；用户拒绝登录时降级为 `search_link_only` 或 `web_indexed`。
5. HTTP 412、验证码、风控、超时、解析失败都保留错误类型，并继续尝试下一个允许的工具。
6. 每个平台最多返回 1-3 个动作候选；没有具体候选时只给官方搜索页和关键词。

## 范围限制

本 skill 不读取视频画面、字幕、评论或媒体文件，不执行 ASR、下载、点赞、收藏、发布或动作技术评审。`XZXZZX-Ai/bilibili-mcp` 的字幕能力、统一工具的文本/ASR能力和任何媒体下载能力不属于默认调用链；它们只作为调研记录保留。

## 参考工具

- [public-clis/bilibili-cli](https://github.com/public-clis/bilibili-cli)
- [XZXZZX-Ai/bilibili-mcp](https://github.com/XZXZZX-Ai/bilibili-mcp)
- [Youhai020616/douyin](https://github.com/Youhai020616/douyin)
- [juziguai/douyin-mcp-server](https://github.com/juziguai/douyin-mcp-server)
- [xpzouying/xiaohongshu-mcp](https://github.com/xpzouying/xiaohongshu-mcp)
- [sinmentis/xiaohongshu-mcp-readonly](https://github.com/sinmentis/xiaohongshu-mcp-readonly)
- [JNHFlow21/social-media-toolkit](https://github.com/JNHFlow21/social-media-toolkit)
- [ywleeo/browser-mcp](https://github.com/ywleeo/browser-mcp)
