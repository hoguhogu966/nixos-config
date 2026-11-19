# Tool services

`~/src/tool` 以下の常駐サービスを Nix で管理する。ジャンルごとにディレクトリを分けている:

| ジャンル | サービス |
|---|---|
| `web/` | gitea, linkding, penpot, pydio, vikunja |
| `media/` | jellyfin (madia_server) |
| `files/` | samba |
| `research/` | altero (zotero連携), rustxng (メタ検索) |
| `dev/` | color-dis-bot (flake input として取り込み) |

有効/無効は `modules/services/default.nix` で**サービス単位** (ディレクトリ単位では
ない) で指定する。外したいサービスはその import 行を削除して rebuild する。

## 仕組み

- 各サービスは `lib/compose.nix` 経由で
  - compose 定義を **Nix attrset で書き**、`pkgs.writers.writeYAML` で YAML 生成
  - launchd ユーザーエージェントを登録し、ログイン時 (colima 起動待ち後) に
    `docker compose up -d --remove-orphans` を実行、以後 30 分間隔で再適用
- Docker エンジンは colima (`unix://$HOME/.colima/default/docker.sock`)。
  変える場合は `lib/compose.nix` の `DOCKER_HOST` を修正する。
- プロジェクト名は既存の compose と同じ (`gitea` / `madia_server` / `penpot` /
  `samba` / `vikunja` / `altero` / `rustxng` / `linkding` / `pydio`) ので、
  既存コンテナ・ボリュームはそのまま引き継がれる。

## シークレット

平文シークレットはこのリポジトリに置かない (AGENTS.md 規約)。YAML 内では
`${VAR}` を使い、値はリポジトリ外の `~/src/tool/<service>/.env` から
`--env-file` で渡す:

| サービス | .env | 必要な変数 |
|---|---|---|
| jellyfin | `~/src/tool/madia_server/.env` | PUID, PGID, TZ (既存) |
| linkding | `~/src/tool/linkding/.env` | LINKDING_SECRET 等 (既存) |
| altero | `~/src/tool/zotero/altero/.env` | POSTGRES_PASSWORD 等 (既存) |
| vikunja | `~/src/tool/vikunja/.env` | VIKUNJA_DB_PASSWORD, VIKUNJA_SERVICE_SECRET |
| pydio | `~/src/tool/pydio/.env` | MYSQL_ROOT_PASSWORD, MYSQL_PASSWORD |
| penpot | `~/src/tool/penpot/.env` | PENPOT_VERSION, PENPOT_SECRET_KEY |
| color-dis-bot | `~/src/tool/color_dis_bot/.env` | DISCORD_TOKEN (既存) |

## ログ

`~/Library/Logs/compose-<name>.log` (標準出力) と
`compose-<name>.err.log` (標準エラー)、bot は `color-dis-bot{,.err}.log`。

## 移行時の注意

- `rustxng` は以前 `docker run` で単独起動していたため、compose 化する前に
  一度 `docker rm -f rustxng` が必要。
- 手動起動していた color-dis-bot (node プロセス) は switch 後に一度止める
  (launchd が `KeepAlive` で自分のインスタンスを維持する)。
- `~/src/tool` に残る旧 compose ファイルは参照されなくなる。移行確認後に
  削除するか、バックアップとして残す。
