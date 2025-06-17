# zprompt

各種シェル環境でプロンプトを表示するだけのプログラムです。

![example](https://i.gyazo.com/b6b9e262025d475520133e1dbd42c942.png)

スクリーンショットの設定 (zsh)

```zsh
# zprompt settings
export ZPROMPT_ICON="🌏"
export ZPROMPT_DIR_COLOR="bright_blue"
export ZPROMPT_GIT_COLOR="green"
setopt PROMPT_SUBST
PROMPT='$(zprompt)'
```

注意: カラーを設定する機能は zsh でのみ対応です。

## 方針

- 設定は環境変数で行う
- Zig, Rust などのプロジェクトごとにアイコンを付ける機能はいれない

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

### カラー設定

zprompt では以下の環境変数を使ってプロンプトの各要素の色をカスタマイズできます：

- `ZPROMPT_DIR_COLOR`: ディレクトリパスの色
- `ZPROMPT_GIT_COLOR`: Git ブランチ/タグの色（括弧含む）
- `ZPROMPT_ICON_COLOR`: プロンプトアイコンの色

#### 色の指定方法

1. **色名を使う方法**
   ```bash
   export ZPROMPT_DIR_COLOR="blue"
   export ZPROMPT_GIT_COLOR="green"
   export ZPROMPT_ICON_COLOR="red"
   ```

   利用可能な色名：
   - 基本色: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`
   - 明るい色: `bright_black`, `bright_red`, `bright_green`, `bright_yellow`, `bright_blue`, `bright_magenta`, `bright_cyan`, `bright_white`
   - 修飾子: `bold`, `dim`, `reset`

2. **ANSIエスケープコードを直接指定する方法**
   ```bash
   # Bash/Zsh の場合
   export ZPROMPT_DIR_COLOR=$'\033[1;34m'   # 太字の青
   export ZPROMPT_GIT_COLOR=$'\033[0;32m'   # 通常の緑
   export ZPROMPT_ICON_COLOR=$'\033[1;31m'  # 太字の赤
   ```

#### 設定例

```bash
# シンプルなカラー設定
export ZPROMPT_DIR_COLOR="bright_blue"
export ZPROMPT_GIT_COLOR="bright_green"
export ZPROMPT_ICON_COLOR="yellow"

# カスタムカラースキーム
export ZPROMPT_DIR_COLOR="cyan"
export ZPROMPT_GIT_COLOR="magenta"
export ZPROMPT_ICON_COLOR="bright_red"

# モノクロ設定
export ZPROMPT_DIR_COLOR="white"
export ZPROMPT_GIT_COLOR="bright_black"
export ZPROMPT_ICON_COLOR="white"
```

## Notes

Inspired by [Zigbar](https://github.com/dbushell/zigbar) and [Starship](https://starship.rs/).

