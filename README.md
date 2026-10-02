# project-base — 开箱即用的工程基座

> **文档驱动 → 测试先行 → 门禁固化 → 独立评审 → 活文档交接 → 链零回归**
>
> 一个与技术栈无关的工程方法论基座 + 模板库。适用于**中大型、多阶段、跨会话、需要多人或多代理协作**的工程交付。

## 这是什么

把一次"复杂、长期、跨会话"的工程交付，拆成一条**可验证、可交接、可追溯**的纪律化流水线。

它解决的不是"怎么写代码"，而是**协作中真正会失控的三件事**：

| 失控的事 | 基座怎么管住 |
|---|---|
| 做到一半忘了当初为什么这么定 | 设计 → 计划 → 台账 → 裁决逐层留痕，跨会话接棒不靠记忆 |
| 改了代码但文档、注释、测试没跟上 | 门禁全绿才允许提交；每个任务独立评审，0 Critical / 0 Important 才放行 |
| 谁都按自己习惯来 | 16 条硬规则 + 断言质量四问 + 失败模式清单，写在 `AGENTS.md` 里 |

**技术栈无关**：门禁命令、目录约定、门禁矩阵都留了占位符，Go / TypeScript / Python / Shell 或别的都能裁剪接入。运维类平台、内部系统、应用类工具、通用应用都可以拿它当起点。

**开箱即用**：clone 之后它就是你的项目根目录，`docs/` 与 `templates/` 直接在位。照 `GETTING-STARTED.md` 的 10 步走完，设计、计划、门禁、评审、验收、交接的全套骨架都在位了。

## 快速上手

```bash
git clone <本仓库地址> my-project && cd my-project
# 然后照着 GETTING-STARTED.md 走；它是新项目的入口与顺序
```

**一个必须先建的文件**：项目根目录下的 `.privacy-patterns`（隐私扫描模式，不入库）。

```bash
cp templates/privacy-patterns.example .privacy-patterns
```

提交钩子是 **fail-closed** 的 —— 这个文件缺失或为空会**直接阻断提交**，这是刻意的设计（防止"检查通过了"变成"检查被跳过了"）。

## 核心信条

> **文档驱动 → 测试先行 → 门禁固化 → 独立评审 → 活文档交接 → 链零回归**

基座的价值在于三件事的固化：

- 把**过程纪律**固化为机器可检查的门禁与可复制的模板；
- 把**状态与裁决**固化为活文档与台账；
- 把**一次性经验**固化为可复用的标准与陷阱清单。

## 目录结构

```
project-base/
├── README.md            本文件 —— 基座定位、目录说明、怎么用
├── GETTING-STARTED.md   新项目使用路径 —— 从零到跑起来按什么顺序走
├── AGENTS.md            仓库级硬规则速查 —— 动手时看这个
├── WORKFLOW.md          完整工程纪律与工作流手册 —— 照着做时看这个
├── CONTRIBUTING.md      参与贡献的纪律与必查项
├── SECURITY.md          隐私与安全机制、泄漏处置顺序
├── LICENSE              MIT
├── templates/           模板库 —— 源文件，不填写、不修改，按需复制到项目里
├── docs/                项目文档集中存放目录 —— 模板复制过来、填写完成的实际文档
└── .githooks/           提交前隐私检查钩子 —— clone 后已装好，模式文件建好即可生效
```

> `CONTRIBUTING.md`、`SECURITY.md`、`LICENSE` 是给**基座使用者**看的，起项目时可以移到 `docs/` 或删除。`templates/` 与 `.githooks/` 要跟着项目长期保留。

**本基座目录即新项目仓库**：以 git 仓库形式提供，clone 之后它就是你的项目根目录，`docs/` 与 `templates/` 直接在位，基座文档随后在立项时换成项目自己的内容。起项目的完整顺序见 [`GETTING-STARTED.md`](GETTING-STARTED.md)。

**templates/ 与 docs/ 的关系**：`templates/` 是**只读的模板源**，里面的文件是带占位符的骨架，始终保持空白状态；新项目开始后，在对应阶段把需要的模板**复制到项目的 `docs/` 目录**（文档类模板）或复制到其功能位置（脚本与配置文件），按项目实际情况替换占位符、填写内容。**不要在 `templates/` 里直接填写项目内容。**

## 文档索引与阅读顺序

| 文件 | 读者 | 内容 | 什么时候看 |
|---|---|---|---|
| [`README.md`](README.md) | 人，找入口 | 定位、目录、使用路径 | 第一次接触本基座 |
| [`GETTING-STARTED.md`](GETTING-STARTED.md) | 新项目发起人 | 从零到项目跑起来的 10 步顺序与每步卡点 | **起一个新项目时照着走** |
| [`AGENTS.md`](AGENTS.md) | 代理 / 新加入的成员 | 不可协商的硬规则、每任务标准循环、文档与提交规范、安全红线 | 每次动手干活前扫一眼 |
| [`WORKFLOW.md`](WORKFLOW.md) | 需要照着做的人 | 阶段 0–6 全流程、门禁矩阵、需求澄清 7 问法、计划拆解、TDD 循环、评审与台账、分层验收与链零回归、陷阱清单、文档规范 | 按阶段推进时逐节对照 |

推荐路径：**先读 README 建立定位 → 起项目时照 GETTING-STARTED.md 走 → 干活前扫 AGENTS.md 记住硬规则 → 推进到具体阶段时翻 WORKFLOW.md 对应章节。**

> `GETTING-STARTED.md` 讲**顺序**（先做哪一步、卡点在哪），`WORKFLOW.md` 讲**每个阶段内部怎么做细**。两者配合使用，不重复。

## 快速使用路径

完整顺序见 [`GETTING-STARTED.md`](GETTING-STARTED.md)。下表是**模板取用对照**：模板**不整体复制**，而是在推进到对应阶段时按需取用那一份。各阶段怎么做细见 `WORKFLOW.md`「阶段 0」到「阶段 6」。

| 阶段 | 需要做什么 | 从 templates/ 取哪份 | 放到哪 |
|---|---|---|---|
| **立项前**（步骤 3） | 确定技术栈与周边环境，**推导出门禁命令与所需技能** | `tech-stack-template.md` | `docs/<project>-tech-stack.md` |
| 阶段 0 环境基座 | 装提交前隐私检查钩子、配置扫描模式、**确定项目所需技能并就绪**、确认门禁命令、**建立进度活文档** | `pre-commit.sh`、`privacy-patterns.example`、`history-scan.sh`、`skills-check.sh`、`skills-required.txt`、`tracking-template.md` | 钩子进 `.githooks/`；隐私模式、扫描脚本、技能脚本与清单进项目根目录（清单按实际栈增删）；活文档进 `docs/<project>-task-tracking.md` |
| 阶段 1 需求澄清与设计 | 产出权威设计文档（含非目标、ADR 决策清单、阶段定义） | `design-template.md` | `docs/<project>-design.md` |
| 阶段 2 写实施计划 | 按阶段拆解 Task，标注验收映射与门禁 | `implementation-plan-template.md` | `docs/<project>-p<阶段>-plan.md` |
| 阶段 3 任务执行 | 执行期逐任务回填台账（不入库） | `ledger-template.md` | 台账目录，gitignored |
| 阶段 4 评审与修正 | 无需新模板：评审结论、修正落实、延后项回填进台账 | —— | —— |
| 阶段 5 验收 | 写验收清单与执行记录；建立该阶段 E2E 脚本 | `acceptance-template.md`、`e2e-template.sh` | 验收文档进 `docs/<project>-p<阶段>-acceptance.md`；E2E 脚本进脚本目录 |
| 阶段 6 交接收尾 | 收尾输出物（验收文档、操作手册、README、AGENTS.md）；**持续更新进度活文档** | —— | `docs/` |

**贯穿全程**：进度活文档在阶段 0 建立一次，此后每次会话收尾都更新它 —— 它是唯一进度源。文档命名遵循 `AGENTS.md`「文档规范」一节；中文输出、文件产出报告、代码注释、项目边界四项硬规则见 `AGENTS.md`（§八 表达与产出规范、§九 安全隐私红线）。

## templates/ 模板清单

模板是**带占位符的骨架**，复制后按项目实际情况替换占位符并填写内容。文档类模板复制到项目的 `docs/`，脚本与配置文件复制到其功能位置。

| 模板 | 类型 | 用途 | 复制到 |
|---|---|---|---|
| `tech-stack-template.md` | 文档 | 技术栈与周边环境选型骨架，含备选与切换触发条件、推导出的门禁命令与所需技能 | `docs/<project>-tech-stack.md` |
| `design-template.md` | 文档 | 设计文档骨架，含 ADR 风格决策表、非目标、演进触发条件 | `docs/<project>-design.md` |
| `implementation-plan-template.md` | 文档 | 实施计划骨架，含 Task N 约定、TDD 步骤、验收映射 | `docs/<project>-p<阶段>-plan.md` |
| `acceptance-template.md` | 文档 | 阶段验收清单 + 执行记录 | `docs/<project>-p<阶段>-acceptance.md` |
| `tracking-template.md` | 文档 | 进度活文档，唯一进度源，供跨会话接棒 | `docs/<project>-task-tracking.md` |
| `ledger-template.md` | 文档 | 单计划实施台账，逐任务回填状态/提交/评审/裁决 | 台账目录，**不入库** |
| `e2e-template.sh` | 脚本 | 自含环境 E2E 脚本骨架，含断言、RESULT 汇总、trap 清理 | 脚本目录，按阶段命名并独占命名空间 |
| `pre-commit.sh` | 脚本 | 提交前隐私信息扫描钩子（模式外置，钩子自身零隐私字符串） | `.githooks/pre-commit`，并 `git config core.hooksPath .githooks` |
| `privacy-patterns.example` | 配置 | 隐私扫描模式示例，按实际环境增删 | 项目根目录 `.privacy-patterns`，**不入库** |
| `history-scan.sh` | 脚本 | 仓库历史隐私体检：密钥文件曾入库 / 全量历史内容 / 提交信息，三类扫描 | 项目根目录；首次提交前、推送前、定期巡检各跑一次 |
| `privacy.test.sh` | 脚本 | 隐私防护行为测试，验证钩子与扫描脚本均 fail-closed | 脚本目录，随模板库保留 |
| `skills-required.txt` | 配置 | 项目所需代理技能清单（流程型 + 实现型分层） | 项目根目录 `skills-required.txt`，按项目实际技术栈增删 |
| `skills-check.sh` | 脚本 | 技能就绪检测与补齐 | 项目根目录 `skills-check.sh`（与清单同目录，默认就读旁边那份） |

**占位符约定**：模板中以尖括号包夹的为占位符（如 `<项目名>`、`<阶段>`、`<project>`、`<hash>`、`<repo-root>`），复制后按项目实际替换。阶段占位符一律用中文的 `<阶段>`；英文大写那种写法会顺着脚本名一起漂移，已废弃。

**维护约定**：`templates/` 保持只读、空白、不含任何项目内容。项目里用完的模板留在项目的 `docs/` 中，本目录的原文件不动。

## 适用前提

- 使用 git 管理版本；
- 具备可运行的测试与构建工具链（门禁命令按项目语言替换）；
- 接受"文档先行、过程留痕"的协作方式。

## 起一个项目前要准备什么

- 本基座可 clone 的地址；
- 对新项目的一句话需求描述（什么项目、大概完成什么功能）；
- 大致的技术栈意向（语言、存储、部署形态），可由 `GETTING-STARTED.md` 步骤 3 逐项敲定。

其中「一句话需求描述」与「技术栈意向」可以直接在会话里跟代理说明，不必先写成文档 —— 步骤 2、3 会把它们落进 `docs/<project>-tech-stack.md` 与设计文档。

## 基座边界

本基座**只提供方法、规范与模板，不包含任何具体项目的实现**。所有技术栈相关的选型、门禁命令、目录结构都需在具体项目中按实际情况裁剪后落地。

## 贡献

欢迎提 issue 和 PR。改动前请先读 [`AGENTS.md`](AGENTS.md) —— 本项目自己就按这套纪律干活，包括：

- 中文撰写文档与注释，标识符与标准格式除外；
- 单任务单 commit，commit message 用 Conventional Commits（`feat:`/`fix:`/`test:`/`docs:`/`chore:`` + scope）；
- 改动脚本必须先写失败测试（见 `templates/privacy.test.sh` 的写法），再最小实现；
- 改动文档同步更新交叉引用与编号，别留断链。

改 `templates/` 里的脚本时，记得同时更新 `templates/privacy.test.sh` 的断言 —— 测试没跟着改，等于没测。

完整纪律见 [`CONTRIBUTING.md`](CONTRIBUTING.md)。

## 许可

[MIT](LICENSE) © 2026 Nathan-Lea。允许自由使用、修改、分发与商用，保留版权声明即可。详见 LICENSE 文件。

## 安全问题

**不要用公开 issue 报告安全问题。** 涉及隐私模式、凭据处理或钩子绕过的问题，请通过私下渠道联系维护者。

机制细节见 [`SECURITY.md`](SECURITY.md)。
