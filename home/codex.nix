{ ... }:

{
  home.file = {
    ".codex/AGENTS.md" = {
      source = ../files/codex/AGENTS.md;
      force = true;
    };

    ".codex/templates/plan.md".source = ../files/codex/templates/plan.md;
    ".codex/templates/review.md".source = ../files/codex/templates/review.md;
    ".codex/templates/spec.md".source = ../files/codex/templates/spec.md;
    ".codex/templates/tasks.md".source = ../files/codex/templates/tasks.md;
  };
}
