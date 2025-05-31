# zprompt

各種シェル環境でプロンプトを表示するだけのプログラムです。

## Build

Zig version 0.14.1 でビルドを確認しています。

```bash
# Debug build
zig build

# Release Build
zig build -Doptimize=ReleaseFast
```

出力先 `zig-out/bin/zprompt` (Windows `zig-out\bin\zprompt.exe`)

## Settings

この例では zprompt が PATH に含まれていることを前提とします。 

### zsh

以下のように `.zshrc` に PROMPT を設定してください。

```zsh
setopt PROMPT_SUBST
PROMPT='$(zprompt)'
```

### Nushell

Nushell の設定フォルダの `vendor/autoload/zprompt.nu` に以下のコードを記述してください。

```nu
def create_left_prompt [] {
    zprompt
}

export-env { load-env {
    PROMPT_COMMAND: {||
        # jobs are not supported
        create_left_prompt
    }
    PROMPT_COMMAND_RIGHT: ""

    PROMPT_INDICATOR: ""
    PROMPT_INDICATOR_VI_INSERT: ": "
    PROMPT_INDICATOR_VI_NORMAL: "〉"
    PROMPT_MULTILINE_INDICATOR: "::: "
}}
```

## 環境変数

### ZPROMPT_ICON

プロンプトのアイコンをカスタマイズできます。デフォルトは `🦀` です。(Zig なのに...)

以下は zsh の例です。

```bash
# ドルマークに変更
export ZPROMPT_ICON="$"
# 恐竜の絵文字に変更
export ZPROMPT_ICON="🦖"

# 他の例
export ZPROMPT_ICON=">"
export ZPROMPT_ICON="λ"
export ZPROMPT_ICON="▶"
```

## Notes

Inspired by [Zigbar](https://github.com/dbushell/zigbar) and [Starship](https://starship.rs/).

