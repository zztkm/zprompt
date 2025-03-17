# zprompt

各種シェル環境でプロンプトを表示するだけのプログラムです。

現在開発中で、現在は Windows 上でのみ動作確認をしています。

## Build

```bash
zig build
```

出力先 `zig-out/bin/zprompt` (Windows `zig-out\bin\zprompt.exe`)

このプログラムを PATH の通ったディレクトリに配置して、シェルのプロンプト設定用プログラムとして呼び出すように設定すると利用可能です。

## Settings

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

## Notes

Inspired by [Zigbar](https://github.com/dbushell/zigbar) and [Starship](https://starship.rs/).
