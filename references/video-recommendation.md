# 三平台动作视频资源搜索

视频层只负责发现训练资源。它返回视频或笔记的标题、作者/账号、原站链接、互动排序信号和可复制搜索关键词，不读取视频内容，不下载媒体，不做字幕、ASR、评论或动作技术审查。

## 工具路由

登录可以使用。skill 只提示使用者在本地完成扫码或浏览器登录，不在聊天中索取 Cookie、Token、密码或验证码。

实际调用工具前先阅读 [dependency-preflight.md](dependency-preflight.md)，运行 `scripts/check-video-tools.sh` 检查环境。核心计划和官方搜索页不需要 Python；缺少可选工具时按预检选择题决定安装用户目录、临时环境或直接使用官方搜索页。

三平台检索是默认选项。使用者不需要每次重复指定平台；只有明确说“不需要视频资源”时才跳过。某个平台未登录时，先提示完成本地登录，再给出该平台搜索页和关键词作为可用的临时结果。

头部博主优先规则见 [creator-roster.md](creator-roster.md)。用户可以随时追加、停用或重排名单。

## 确认与自动安装

每次进入 `create` 或 `adjust`，先询问：

```text
是否需要为计划中的每个动作搜索 B 站、抖音和小红书的标题、链接或关键词？
B 站公开搜索通常不需要登录；抖音和小红书首次搜索需要本地扫码登录。
选择“需要并同意安装工具”后，我会自动安装或更新检索工具。
```

使用者同意后，按平台执行安装：

1. B 站：安装 `bilibili-cli`，搜索不要求登录。
2. 抖音：创建独立 Python 环境，安装 `dy-cli` 和 Playwright，并下载 Chromium；首次搜索时打开专用浏览器供使用者扫码。
3. 小红书：macOS Apple Silicon 优先安装 [xpzouying/xiaohongshu-mcp](https://github.com/xpzouying/xiaohongshu-mcp) 的对应发行版并运行登录工具；Linux 可使用只读的 [sinmentis/xiaohongshu-mcp-readonly](https://github.com/sinmentis/xiaohongshu-mcp-readonly)；也可使用 [browser-mcp](https://github.com/ywleeo/browser-mcp) 复用真实 Chrome 登录态。

安装只写入工具目录和 `fitness-data/video-tools.md` 的版本/状态，不写入认证材料。安装完成不等于登录完成：抖音和小红书必须由使用者扫码。

| 平台/需求 | 默认工具 | 备用工具 | 登录和限制 |
|---|---|---|---|
| B 站关键词搜索 | [public-clis/bilibili-cli](https://github.com/public-clis/bilibili-cli) | [XZXZZX-Ai/bilibili-mcp](https://github.com/XZXZZX-Ai/bilibili-mcp)、[Zijian-Ni/bilibili-mcp-server](https://github.com/Zijian-Ni/bilibili-mcp-server) | `search/hot/rank` 通常无需登录；详情请求可能遇到 412 |
| 抖音关键词搜索 | [Youhai020616/douyin](https://github.com/Youhai020616/douyin)（`dy` CLI） | [juziguai/douyin-mcp-server](https://github.com/juziguai/douyin-mcp-server)、[ywleeo/browser-mcp](https://github.com/ywleeo/browser-mcp) | 关键词搜索通常需要扫码登录；登录失败时保留结构化错误 |
| 抖音无登录后备 | [EpicSaber/douyin-analytics-scraper](https://github.com/EpicSaber/douyin-analytics-scraper) | 网页搜索 `site:douyin.com/video` | Apify OAuth、代理或费用；只作为小样本元数据后备 |
| 小红书关键词搜索 | [xpzouying/xiaohongshu-mcp](https://github.com/xpzouying/xiaohongshu-mcp)（macOS Apple Silicon） | [sinmentis/xiaohongshu-mcp-readonly](https://github.com/sinmentis/xiaohongshu-mcp-readonly)、[ywleeo/browser-mcp](https://github.com/ywleeo/browser-mcp) | 需要本地浏览器扫码登录；优先使用原站链接 |
| 小红书无 Cookie 后备 | [habit.zhou/xiaohongshu-pro-scraper](https://apify.com/habit.zhou/xiaohongshu-pro-scraper) | 官方搜索页/网页索引 | Apify OAuth/费用；只保留原站链接 |
| 三平台统一入口 | [JNHFlow21/social-media-toolkit](https://github.com/JNHFlow21/social-media-toolkit) | 平台专用工具 | 可先试公开元数据；失败后回退，不阻塞平台专用搜索 |

安装入口和实际验收见 [video-tool-evaluation.md](video-tool-evaluation.md)。

## 搜索词生成

为计划中的每一个动作生成 2-4 组查询词，保留用户的目标、器械和水平：

1. 中文动作名：`杠铃深蹲`
2. 中文动作名 + 目的：`杠铃深蹲 标准动作`、`杠铃深蹲 常见错误`
3. 中文动作名 + 器械/水平：`杠铃深蹲 力量举 新手`
4. 英文或别名：`barbell back squat technique`、`高杠深蹲`

如果计划有替代动作，也为替代动作生成搜索词，例如 `高脚杯深蹲 居家 标准动作`。

## 搜索流程

1. 先按平台工具路由运行关键词搜索，并优先筛选视频或视频笔记类型。
2. 先过滤标题与动作、器械和训练目的明显不相关的结果。
3. 按博主优先级排序：用户明确指定的博主（例如谭成义、凯胜王、王一涵） -> 可核验的头部/专业博主 -> 其他相关博主。
4. 同一博主层级内，再按工具实际返回的收藏、点赞、播放、评论、作者粉丝和发布时间排序；默认优先收藏，其次点赞，再参考播放、评论和发布时间。
5. 去掉重复、无法确认原站页面或只返回临时媒体地址的结果。
6. 每个计划动作、每个平台返回 1-3 个候选；没有可靠候选时只给该平台搜索页和关键词。
7. 记录检索日期、工具状态和错误类型，方便下一次重试。

指定博主优先只表示资源排序偏好，不等于动作技术正确。平台没有返回博主身份、认证信息或互动数据时，标为未知，不凭记忆补全。输出中仍要提醒使用者自行判断是否适合自己的训练水平和限制。

## 结果状态

- `search_result`：工具成功返回了标题和原站页面链接。
- `metadata_only`：只有标题、作者或互动元数据，仍然可以作为资源入口，但不声称已查看内容。
- `search_link_only`：没有具体候选，只能给官方搜索页或平台内搜索词。
- `web_indexed`：来自搜索引擎索引的原站结果，不代表完整平台排序。
- `unavailable`：工具未安装、登录失败、被风控、超时或返回不可解析结果；必须说明原因。

## 输出字段

```text
动作:
平台:
资源类型: video | article | note | unknown
标题:
作者/账号:
原站 URL:
搜索词:
互动数据: 只填工具实际返回的字段
博主匹配: 指定博主 | 头部/专业博主 | 普通相关博主 | 未知
结果状态:
匹配理由:
局限:
检查日期:
```

## 登录与降级

- B 站搜索通常不需要登录：安装 `bilibili-cli` 后直接执行 `bili search "动作关键词" --type video --max 3 --yaml`。
- 抖音首次使用：安装 `dy-cli`，执行 `playwright install chromium` 和 `dy init`，在打开的专用浏览器中扫码；登录完成后执行 `dy search "动作关键词" --sort 最多点赞 --type video --json-output`。
- 小红书首次使用：macOS Apple Silicon 运行 `xiaohongshu-login-darwin-arm64` 后启动 `xiaohongshu-mcp-darwin-arm64`；Linux 使用只读服务的本地登录页；登录后调用搜索工具筛选视频笔记。
- 工具要求登录时，告诉使用者打开工具提供的本地登录页或浏览器，完成扫码后重试同一关键词。
- 登录失败、HTTP 412、验证码、风控、超时或解析失败时，按备用工具继续尝试；不要把失败当成“没有相关视频”。
- 使用者不希望登录时，返回官方搜索页或网页索引链接，并标记 `search_link_only` 或 `web_indexed`。
- 工具完全不可用时，输出平台、动作中文名、英文名、器械和目标的组合搜索词；不凭记忆生成 BV 号、抖音短链、小红书 token 或作者数据。

官方搜索页格式：

- B 站：`https://search.bilibili.com/all?keyword=<URL编码后的关键词>`
- 抖音：`https://www.douyin.com/search/<URL编码后的关键词>`
- 小红书：`https://www.xiaohongshu.com/search_result?keyword=<URL编码后的关键词>`

## 链接和合规

- 只输出公开原站页面 URL 或官方搜索页；过滤下载地址、临时 CDN URL、签名参数和内部接口地址。
- 不在档案中保存 Cookie、Token、密码或验证码。
- 不调用发布、评论、点赞、收藏、下载等写操作或媒体操作。
- 用户要求批量下载、转载、商用或绕过登录/风控时，停止视频资源层并要求其确认合法授权。
