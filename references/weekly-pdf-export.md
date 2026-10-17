# 本周便携 PDF 导出

总体训练计划先保存为 Markdown。用户确认后，再从该 Markdown 的小周期表格派生一页 A4 横向 PDF，方便手机查看或打印携带。PDF 是计划的只读打印视图，不替代 Markdown，也不创建新的训练事实。

## 触发方式

计划生成或修正完成后询问：

```text
是否生成本周便携版训练文档？
1. 生成一页 PDF 表格
2. 只保留 Markdown 计划
3. 生成 PDF，并同时生成可打印 Markdown 摘要
4. 稍后指定某一周再生成
```

如果用户在未来的聊天中说“生成某一周的计划”“导出下周训练表”或“把第 3 周做成 PDF”，读取项目内当前 active 计划的 Markdown，定位对应小周期，再运行导出脚本。不能凭空重新设计计划，也不能把训练记录的 `planned` 状态改成 `completed`。

## 生成命令

```bash
python3 fitness-coach/scripts/render_weekly_pdf.py \
  --plan fitness-data/plans/YYYY-MM-DD-goal-v01.md \
  --week-start YYYY-MM-DD \
  --output fitness-data/exports/YYYY-MM-DD-weekly-v01.pdf
```

`--week-start` 可以省略；省略时导出 Markdown 中可识别的小周期表格。未来聊天中如果用户只说“第 3 周”，先从计划的中周期/小周期标题确定日期范围；日期不明确时用选择题询问对应周次，不猜日期。

## PDF 内容

PDF 使用 A4 横向布局，优先保持一页和可读字号。页眉包含周范围、目标、计划版本和来源 Markdown；表格包含：

- 日期或 Day、顺序、动作；
- 计划组数×次数/时长、目标 RPE/RIR、休息和替代动作；
- 完成状态：`planned`、`completed`、`skipped`、`moved` 或 `unknown`；
- 空白的实际重量×次数/时长和备注栏，供训练时填写；
- 页脚停止线和记录提醒。

大周期说明、完整视频资源表和长段解释留在 Markdown 中，避免挤压便携表格。动作很多导致一页不可读时，保持可读性并明确输出两页 PDF，同时告诉用户原因。

## 输出位置和来源

默认输出到 `fitness-data/exports/`，文件名包含周起始日和计划版本，例如 `2026-10-19-weekly-v01.pdf`。生成前确认来源计划存在且包含小周期动作表；缺少计划、周次或动作表时，询问用户选择另一个 active 计划、指定周次或只输出 Markdown 摘要。

PDF 生成需要 Python 的 `reportlab`；如果依赖缺少，按 [dependency-preflight.md](dependency-preflight.md) 询问使用临时环境、安装到用户目录或只输出 Markdown。核心训练 skill 和 Markdown 计划不因 PDF 依赖缺少而中断。

PDF 依赖缺失时询问：

```text
当前环境缺少 PDF 生成依赖，怎么继续？
1. 使用临时 Python 环境生成本次 PDF
2. 安装到用户目录，供以后导出使用
3. 不生成 PDF，只输出本周 Markdown 摘要
```
