# <计划名> 实施台账（gitignored）

> 计划：`docs/<project>-implementation-plan-p<phase>.md`（commit <hash>）
> 设计：`docs/<project>-p<phase>-design.md`（commit <hash>）
> 纪律：<分支策略>；单任务单 commit；每任务独立只读 code-reviewer（0C/0I 放行、先提交后评审、问题 amend）；TDD RED→GREEN；门禁见计划头。

## Task 1 <标题>

- 状态：完成（复核放行 0C/0I）｜ 进行中 ｜ 待办
- 提交：<hash> → 评审不放行（0C/xI/yM）→ amend <hash2> → 复核放行
- 评审：会话 <session_id>（第一轮：不放行；第二轮：放行）
- 修正落实：I-1 <说明>；M-1 <说明>
- 延后 Minor（不阻塞）：Mx <说明>
- Ruling：<决定> — <原因> — <错误代价>

## Task 2 <标题>

（同上模板）

---

## 终审

- 全任务 0C/0I 放行记录齐备
- commit 链：<hash>（设计）→ <hash>（计划）→ <T0 hash> → <T1 hash> → ...
- 验收门全绿：格式检查空 / 静态检查 0 / 单测全 PASS / 竞态 ok / 前端 build ✓ / E2E PASS=n FAIL=0 / 链回归 n/n / UI 截图存档 / 工作树干净
- **<阶段> 收官**