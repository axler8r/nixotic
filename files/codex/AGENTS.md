# Personal Codex Instructions

## Agentic Augmentation Workflow

Use this lightweight workflow when the user asks to start, plan, implement, or
complete a material piece of work. Keep the loop small; do not force every phase
onto trivial tasks.

The default phase order is:

0. Branch
1. Ideate
2. Plan
3. Design
4. Generate tasks
5. Implement tasks
6. Review
7. Merge

### Artifact Locations

Use repo-local `.scratchpad/codex` files as branch-local durable state:

- `.scratchpad/codex/specs/<slug>.md` for ideation, scope, decisions, and design notes.
- `.scratchpad/codex/plans/<slug>.md` for the implementation plan and acceptance criteria.
- `.scratchpad/codex/tasks/<slug>.md` for the executable task checklist.
- `.scratchpad/codex/tasks/<slug>-review.md` for review findings, checks, and merge notes.

Prefer the templates in `~/.codex/templates/` when creating new artifacts. Derive
`<slug>` from the branch or work title using lowercase words separated by
hyphens.

### Phase Protocol

- **Branch:** Inspect git state first. In this Nixotic repo, follow
  `stable -> wip/* -> stable`: update `stable`, create a short-lived WIP branch,
  and keep merge fast-forward only. In other repos, follow their documented
  branch workflow.
- **Ideate:** Capture goal, intended user, workflow, success criteria, scope,
  assumptions, tradeoffs, and open questions. Separate observations from
  inferences.
- **Plan:** Produce a decision-complete plan before implementation. Include key
  changes, public interfaces or file shapes, acceptance checks, and assumptions.
- **Design:** Add architecture, data flow, integration points, failure modes, or
  verification strategy only when the work needs those decisions.
- **Generate tasks:** Convert the plan into small tasks that can be implemented
  and checked independently. Each task should have an observable done condition.
- **Implement tasks:** Work through tasks one at a time, updating the task file
  as progress changes. Keep edits narrow and inspectable.
- **Review:** Review the diff from product, architecture, code, and assumption
  risk angles. Lead with defects, missing tests, unclear decisions, and residual
  risk.
- **Merge:** Run the repo's validation commands, curate history explicitly, and
  merge according to the repo's workflow. For Nixotic, use the existing WIP
  branch helpers and fast-forward `stable`.

### Stop Conditions

Stop and ask before crossing a durable boundary the user did not request:

- deleting or moving files
- broad refactors
- generated rewrites
- migrations
- publishing, pushing, opening PRs, or merging

## Communication Style

- Be concise, direct, and practical.
- Give short progress updates during longer work.
- In final summaries, mention the files changed and the checks run.
- Prefer concrete next steps over broad process advice.
- Do not overbuild workflows, skills, MCP servers, dashboards, or automations
  unless the repeated need is clear.
