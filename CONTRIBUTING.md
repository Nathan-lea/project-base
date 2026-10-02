# 开源贡献指南

感谢参与。本项目自己按 `AGENTS.md` 的纪律干活，改动也应遵循同一套标准。

## 环境准备

```bash
git clone <本仓库地址> && cd project-base

# 隐私模式文件（不入库，但提交钩子需要它）
cp templates/privacy-patterns.example .privacy-patterns

# 装钩子
mkdir -p .githooks
cp templates/pre-commit.sh .githooks/pre-commit && chmod +x .githooks/pre-commit
git config core.hooksPath .githooks

# 跑一遍现有测试，确认起点是绿的
bash templates/privacy.test.sh
```

`privacy.test.sh` 必须全绿再动手。

## 改动纪律

| 项 | 要求 |
|---|---|
| 分支 | 一个改动一个分支，从 `main` 切出 |
| commit | 单任务单 commit，Conventional Commits：`feat:`/`fix:`/`test:`/`docs:`/`chore:` + scope |
| TDD | 改脚本先写失败测试，确认失败原因正确，再最小实现 |
| 文档 | 中文撰写；标识符、HTTP 状态码、JSON 字段、第三方专有名词保留原文 |
| 注释 | 解释"为什么这么写"，不复述代码本身 |
| 提交报告 | 说清新增了哪些文件、哪些文件改了什么、为什么改 |

## 必查项

改完自检这几条，PR 描述里说明结果：

```bash
bash templates/privacy.test.sh        # 行为测试须 PASS=13 FAIL=0
bash templates/history-scan.sh        # 历史体检须 LEAK=0
bash templates/skills-check.sh --check  # 技能清单须 MISSING=0
for f in templates/*.sh; do bash -n "$f"; done   # 所有脚本语法
```

改文档还要确认：相对链接无断链、章节编号连续、`§` 交叉引用都指向存在的章节。

## 代码评审

每个改动由独立评审者过一遍，**0 Critical / 0 Important** 才放行。评审至少覆盖：

- 安全（凭据不回显、注入防护、fail-closed 是否真的 fail-closed）
- 边界与异常处理
- 命名与注释一致性（注释是否与实现相符）
- 测试是否真的会因为被测代码被删而变红

## 提交隐私信息

**不要提交**任何真实凭据、证书、密钥、内网地址、员工邮箱。文档里一律用占位符：

```
<repo-root>  <tmp>  <internal-host>  <credential-path>  <email>
```

`templates/privacy.test.sh` 已有 fail-closed 的行为测试，改动钩子时不要为了让测试通过而削弱它。

## 联系

安全问题不要开公开 issue，详见 README 的「安全问题」一节。