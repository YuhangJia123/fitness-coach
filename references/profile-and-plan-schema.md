# 个人档案与计划文件结构

所有文件都是项目内可读的 Markdown。建议目录：

```text
fitness-data/
├── profile.md
├── video-tools.md
├── creator-roster.md
├── exports/
│   └── YYYY-MM-DD-weekly-vNN.pdf
├── plans/
│   └── YYYY-MM-DD-<goal>-v01.md
└── revisions/
    └── YYYY-MM-DD-<reason>-v02.md
```

## `video-tools.md` 模板

```markdown
---
updated_at: YYYY-MM-DD
video_resources: ask | enabled | disabled
---

# 视频资源工具状态

## 最近预检
- 核心运行环境: available | unavailable
- Python 3.10+: available | missing | not_required
- Python venv/pip: available | missing | not_required
- 项目目录: writable | read_only
- 工具目录: writable | read_only
- 预检日期:

## 安装
- bilibili-cli:
- dy-cli:
- xiaohongshu/browser tool:
- 安装来源和版本:
- 最近检查:

## 登录状态
- B站: not_required | ready | unavailable
- 抖音: not_required | ready | login_required | unavailable
- 小红书: not_required | ready | login_required | unavailable

## 最近错误
- 日期:
- 平台:
- 错误类型:
- 下一步:

不记录 Cookie、Token、密码、验证码或签名 URL。
```

## `profile.md` 模板

```markdown
---
profile_version: 1
updated_at: YYYY-MM-DD
status: onboarding | active | needs-review
---

# 个人训练档案

## 目标
- 训练焦点: powerlifting | general_fitness | function | other
- 主目标: powerlifting | function | weak-point | hypertrophy | fat-loss
- 次目标:
- 训练状态: novice | intermediate | advanced | unknown
- 目标日期/周期:
- 成功指标:
- 优先部位或动作:
- 指定优先博主: 谭成义、凯胜王、王一涵（可追加、删除或调整顺序）
- 博主排序偏好: 指定博主 > 头部/专业博主 > 收藏/点赞等互动数据

## 计划依据
- 基础 PDF: 《力量训练原理：用七大核心原理科学提升力量》（美）迈克·伊瑟泰尔；《力量举计划设计手册》第 3 版
- 补充依据:
- 补充依据摘要:
- 依据冲突与用户决定:

## 身体与健康边界
- 年龄段:
- 身高:
- 体重:
- 体脂/腰围:
- 运动限制、医生建议、伤病或疼痛:
- 运动前筛查状态:

## 训练条件
- 每周可训练天数:
- 可训练日期:
- 单次时长上限:
- 健身房器械:
- 居家器械和空间:
- 当前计划:
- 训练经验:

## 近期状态
- 睡眠:
- 工作/生活压力:
- 近期疲劳:
- 近 4 周训练摘要:
- 饮食与恢复摘要:

## 训练反馈（追加，不覆盖）
### YYYY-MM-DD
- 来源:
- 实际完成:
- 疲劳/睡眠/酸痛/表现:
- 用户原话或数据:
- 解释与不确定性:

## 周期完成核对（追加，不覆盖）
### YYYY-MM-DD
- 对应计划:
- planned:
- completed:
- skipped:
- moved:
- unknown:
- unresolved:
- 证据:

## 变化记录（追加，不覆盖）
### YYYY-MM-DD
- 字段:
- 旧值:
- 新值:
- 来源:
- 用户是否确认:
```

## 计划模板

```markdown
---
plan_version: v01
created_at: YYYY-MM-DD
goal: powerlifting | function | weak-point | hypertrophy | fat-loss
source_profile: ../profile.md
status: draft | active | superseded
---

# 训练计划

## 假设与数据来源
- 基础 PDF 摘要:
- 已确认的补充依据摘要:

## 大周期
| 阶段 | 周期 | 目的 | 主要指标 | 切换/减量条件 |
|---|---|---|---|---|

## 中周期
| 周次 | 容量/强度方向 | 主项频率 | 变式 | 恢复检查 |
|---|---|---|---|---|

## 小周期
### Day 1 - ...
| 顺序 | 动作 | 组 x 次/时长 | RPE/RIR | 休息 | 替代动作 |
|---|---|---|---|---|---|

## 动作资源参考
| 动作 | 平台 | 资源类型 | 标题/作者 | 原站 URL 或搜索页 | 搜索词 | 结果状态 | 检查日期 |
|---|---|---|---|---|---|---|

## 进阶、减量与调整

## 下次反馈
```

## 事实与推断规则

- 用户原话、导入数据和工具返回结果是事实；训练建议是推断，必须分栏。
- 旧计划只读，修正计划新建版本；在新文件开头链接旧版本。
- 任何未确认的 OCR 数字、估计 1RM 或视频互动数据都写成估计并保留来源。
- 若用户要求只在对话中回答而不写文件，尊重该选择；默认的 skill 行为是保存项目内档案和计划。
