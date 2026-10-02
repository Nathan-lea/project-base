# docs/ — 项目文档目录

> 本目录存放**新项目实际开发过程中产生、使用的文档**。

## 放什么

| 文档 | 命名 | 说明 |
|---|---|---|
| 技术栈选型 | `<project>-tech-stack.md` | 技术选型唯一记录；第 7/8 节推导出门禁命令与所需技能 |
| 权威设计文档 | `<project>-design.md` | 需求、非目标、架构、ADR 决策清单、阶段定义 |
| 阶段设计 | `<project>-p<阶段>-design.md` | 该阶段的详设 |
| 实施计划 | `<project>-p<阶段>-plan.md` | Task 划分、验收映射、门禁、纪律 |
| 验收清单 | `<project>-p<阶段>-acceptance.md` | 验收场景表、执行记录、未覆盖项 |
| 进度活文档 | `<project>-task-tracking.md` | **唯一进度源**，每会话收尾更新 |
| 交接文档 | `<project>-p<阶段>-handoff.md` | 复杂项目按需：提交拓扑、裁决全文、遗留队列 |
| 操作手册 | `operation-manual.md` | 启动/配置/使用/对接/部署/运维/排障 |

命名约定详见 `AGENTS.md`「文档规范」；推进顺序见 `GETTING-STARTED.md`。

## 不放什么

- **不放台账**：台账不入库，另置 gitignored 的台账目录。
- **不直接改模板**：所有文档从 `templates/` 复制过来再填写；`templates/` 保持只读空白。
- **不用日期前缀命名**：散落难检索，按类型 + 阶段命名。
