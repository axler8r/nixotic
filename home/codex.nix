{ ... }:

{
  home.file = {
    ".codex/AGENTS.md" = {
      source = ../files/codex/AGENTS.md;
      force = true;
    };

    ".codex/templates".source = ../files/codex/templates;
  };
}
