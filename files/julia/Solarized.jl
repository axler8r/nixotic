using OhMyREPL
using Crayons

import OhMyREPL: Passes.SyntaxHighlighter

solarized = SyntaxHighlighter.ColorScheme()

SyntaxHighlighter.argdef!(solarized, Crayon(foreground=5,  bold=true))
SyntaxHighlighter.call!(solarized, Crayon(foreground=3,  bold=true))
SyntaxHighlighter.comment!(solarized, Crayon(foreground=14, bold=false))
SyntaxHighlighter.error!(solarized, Crayon(foreground=1,  bold=false))
SyntaxHighlighter.function_def!(solarized, Crayon(foreground=2,  bold=false))
SyntaxHighlighter.keyword!(solarized, Crayon(foreground=2,  bold=true))
SyntaxHighlighter.macro!(solarized, Crayon(foreground=6,  bold=false))
SyntaxHighlighter.number!(solarized, Crayon(foreground=6,  bold=false))
SyntaxHighlighter.op!(solarized, Crayon(foreground=5,  bold=false))
SyntaxHighlighter.string!(solarized, Crayon(foreground=6,  bold=false))
SyntaxHighlighter.symbol!(solarized, Crayon(foreground=6,  bold=true))
SyntaxHighlighter.text!(solarized, Crayon(foreground=12, bold=true))

SyntaxHighlighter.add!("Solarized", solarized)

colorscheme!("Solarized")

OhMyREPL.input_prompt!("\ue624 \uf053 ", :cyan)
OhMyREPL.output_prompt!("\ue624 \uf054 ", :cyan)

Base.active_repl.interface.modes[2].prompt = "\ue795 \uf053 "; #shell prompt
Base.active_repl.interface.modes[3].prompt = "\uf128 \uf053 "; #help prompt
#julia_version = ENV["JULIA_VERSION"];
# Base.active_repl.interface.modes[6].prompt = "\uf487 \uf053 "; #pkg prompt
