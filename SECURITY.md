# 安全与隐私

## 隐私模式文件

本项目的隐私扫描依赖仓库根目录的 `.privacy-patterns`，它**不入库**（已被 `.gitignore` 忽略），因为它会包含使用单位的真实内网域名与邮箱域名。

从示例复制后按实际情况增删：

```bash
cp templates/privacy-patterns.example .privacy-patterns
chmod 600 .privacy-patterns
```

## 提交钩子（fail-closed）

`.githooks/pre-commit` 在每次提交前扫描暂存区。设计上是 **fail-closed**：

- `.privacy-patterns` 缺失 → **阻断提交**，并提示如何创建；
- `.privacy-patterns` 存在但无有效模式 → **阻断提交**，空模式等于没有防护；
- 命中隐私模式 → **阻断提交**，报出文件与匹配行。

安装：

```bash
mkdir -p .githooks
cp templates/pre-commit.sh .githooks/pre-commit && chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
```

钩子自身不含任何敏感字符串，模式全部外置到不入库的文件。

## 历史体检

钩子只看暂存区，看不到「曾经提交过、后来又删掉」的内容。密钥一旦入库就永远留在 git 历史里，删文件无效。

```bash
bash templates/history-scan.sh
```

扫描三类：密钥文件类是否曾入库、全量历史内容是否命中隐私模式、提交信息是否含凭据。退出码 `0` 通过 / `1` 发现泄漏 / `2` 用法错误。

建议在首次提交前、每次推送前、以及定期巡检各跑一次。

## 发现泄漏后的处置顺序

**顺序不可颠倒。**

```
1. 轮换全部相关凭据         ← 最优先，凭据失效才算处置
2. 清理 git 历史            ← git filter-repo --path <路径> --invert-paths
3. 通知协作者重新克隆        ← 改写历史会变 hash，旧克隆副本仍在本地
4. 若已推送，强制推送并复扫   ← bash templates/history-scan.sh
```

跳过第 1 步直接清历史，等于用「文件看不到了」冒充「问题解决了」—— 凭据本身仍然有效。

仓库一旦推送到公开平台即视为公开：会自动索引，第三方扫描器数小时内即可发现密钥，删除与 fork 都不会让它消失。

## 绕过钩子

需要 `--no-verify` 时，先确认没有真实泄漏（示例模式应改为占位符化），并在提交信息中注明原因。绕过行为要留痕。

## 报告安全问题

**不要用公开 issue 报告安全问题。** 请通过私下渠道联系维护者。