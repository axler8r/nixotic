{ config, pkgs, ... }:

{
  programs.bat = {
    enable = true;

    themes = {
      NixoticSolarizedLight = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>name</key>
          <string>NixoticSolarizedLight</string>
          <key>settings</key>
          <array>
            <dict>
              <key>settings</key>
              <dict>
                <key>background</key>
                <string>#fdf6e3</string>
                <key>foreground</key>
                <string>#839496</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Comment</string>
              <key>scope</key>
              <string>comment, comment.block.documentation</string>
              <key>settings</key>
              <dict>
                <key>foreground</key><string>#839496</string>
                <key>fontStyle</key><string>italic</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Keyword</string>
              <key>scope</key>
              <string>keyword, storage.type, storage.modifier, keyword.control, keyword.operator.word</string>
              <key>settings</key>
              <dict>
                <key>foreground</key><string>#859900</string>
                <key>fontStyle</key><string>bold</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Variable and Constant</string>
              <key>scope</key>
              <string>variable, variable.other.readwrite, variable.language, constant, support.constant</string>
              <key>settings</key>
              <dict><key>foreground</key><string>#268bd2</string></dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Strings</string>
              <key>scope</key>
              <string>string</string>
              <key>settings</key>
              <dict><key>foreground</key><string>#2aa198</string></dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Numbers and Booleans</string>
              <key>scope</key>
              <string>constant.numeric, constant.language.boolean</string>
              <key>settings</key>
              <dict><key>foreground</key><string>#2aa198</string></dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Types</string>
              <key>scope</key>
              <string>entity.name.type, support.type, support.class, entity.name.class, meta.class, entity.name.struct</string>
              <key>settings</key>
              <dict><key>foreground</key><string>#b58900</string></dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Functions</string>
              <key>scope</key>
              <string>entity.name.function, meta.function-call, support.function, variable.function</string>
              <key>settings</key>
              <dict>
                <key>foreground</key><string>#cb4b16</string>
                <key>fontStyle</key><string>italic</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Regex and Escapes</string>
              <key>scope</key>
              <string>string.regexp, constant.character.escape</string>
              <key>settings</key>
              <dict><key>foreground</key><string>#6c71c4</string></dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Imports and Macros</string>
              <key>scope</key>
              <string>keyword.control.import, keyword.control.from, keyword.control.include, entity.name.namespace, support.namespace, meta.preprocessor, entity.name.annotation, storage.type.annotation</string>
              <key>settings</key>
              <dict><key>foreground</key><string>#d33682</string></dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Punctuation and Operators</string>
              <key>scope</key>
              <string>punctuation, keyword.operator</string>
              <key>settings</key>
              <dict><key>foreground</key><string>#839496</string></dict>
            </dict>
          </array>
        </dict>
        </plist>
      '';
    };

    config = {
      theme = "NixoticSolarizedLight";
      map-syntax = [
        ".ignore:Git Ignore"
        "*.code-workspace:JSON"
        ".XCompose:Bourne Again Shell (bash)"
        ".livebook:Markdown"
        ".taskrc:Bourne Again Shell (bash)"
        ".tigrc:Bourne Again Shell (bash)"
        ".tmux.conf:Bourne Again Shell (bash)"
        ".xonshrc:Python"
        ".zsh*:Bourne Again Shell (bash)"
      ];
    };
  };
}
