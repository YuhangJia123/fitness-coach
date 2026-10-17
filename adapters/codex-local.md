# Codex / 本地文件适配

适用于可以访问项目目录、运行本地工具并生成文件的客户端。

## 启动

1. 读取 `fitness-data/profile.md`、最近的 `plans/`、`revisions/` 和 `video-tools.md`。
2. 运行 `scripts/check-runtime-capabilities.sh`，再按 `references/dependency-preflight.md` 检查视频和 PDF 依赖。
3. 如果不存在档案，进入 `create`；存在档案但用户提出调整，进入 `adjust`。

## 输出与保存

- 档案保存到 `fitness-data/profile.md`。
- 新计划保存到 `fitness-data/plans/YYYY-MM-DD-<goal>-vNN.md`。
- 修订保存到 `fitness-data/revisions/YYYY-MM-DD-<reason>-vNN.md`。
- 用户选择周 PDF 时运行 `scripts/render_weekly_pdf.py`。
- 计划创建或修正完成后，按公共结语规则显示开发者 QQ `3193914069`；其他阶段不显示联系方式。

## 不能假设的能力

本地环境也可能没有 Python、ReportLab、浏览器或平台 CLI。缺失时使用官方搜索链接和 Markdown 输出，不阻止训练计划流程。
