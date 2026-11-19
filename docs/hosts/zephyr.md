# `zephyr`

macOS laptop — nix-darwin on `aarch64-darwin`. Smaller than `freesia`; username is parameterized.

- **Flake entry**: `flake/hosts/zephyr.nix` → `darwinConfigurations.zephyr` (invoked with `user_name = "zephyr"`)
- **nix-darwin config**: `hosts/zephyr/` (`default.nix`, `brew.nix`)
- **Home Manager**: `home/zephyr.nix`, user `zephyr`

## Modules

`flake/hosts/zephyr.nix` imports:

- `hosts/zephyr/` (imports `./brew.nix`, `modules/cachix`, `modules/sops`, `modules/services/atuin`)
- `home-manager.darwinModules.home-manager`
- `sops-nix.darwinModules.sops`
- `nix-homebrew.darwinModules.nix-homebrew`

`user_name` is threaded through `specialArgs` from `flake.nix` and used for the Home Manager user, Homebrew user, and home directory.

## Host-specific settings (`hosts/zephyr/default.nix`)

- `nixpkgs.hostPlatform = "aarch64-darwin"`, `system.primaryUser = "zephyr"`, `allowUnfree = true`
- `system.stateVersion = 6`; `system.configurationRevision` set from the flake revision
- User `zephyr`, home `/Users/zephyr`
- System package `vim`
- No custom `pkgs/` overlays (unlike `freesia`)

## Atuin sync server

`modules/services/atuin/` runs `atuin-server` as a launchd **user agent** (`launchd.user.agents.atuin`, gui domain), enabled in `hosts/zephyr/configuration.nix` with `services.atuin-server.enable = true`:

- Listens on `127.0.0.1:10002` only (`services.atuin-server.port`), SQLite database at `~/.local/share/atuin/server.db`, logs to `~/Library/Logs/atuin.log`
  - A system daemon with `StandardOutPath` under `/var/log` fails instantly with `EX_CONFIG` (launchd cannot open the stdio file), which is why this is a user agent with a user-writable log path
- Exposed to the tailnet as `https://zephyr.tail32a8e5.ts.net` via `tailscale serve --bg --http 443 http://127.0.0.1:10002` (imperative one-liner, persists in tailscaled)
- Clients point at it with `sync_address` in `home/programs/atuin/default.nix`
- `services.atuin-server.openRegistration` starts as `true`; flip to `false` once accounts are registered


## Homebrew (`hosts/zephyr/brew.nix` + `nix-homebrew`)

`nix-homebrew` manages the same immutable taps as `freesia`. Casks: `lm-studio`, `tailscale-app`, `appcleaner`. `onActivation.autoUpdate = false`.

## Secrets (sops-nix)

Age key for this host is registered in `.sops.yaml`. The sops module is imported via `hosts/zephyr/`.

## Home Manager

`home/zephyr.nix` imports CLI tools (`nixvim`, `opencode`, `emacs`, `nushell`, `yazi`, `gh`, `git`, `direnv`, `tmux`, `zsh`), containers (`docker`, `podman`; `colima` is commented out), and `cloudflared` as a host-specific service.

## Rebuild

```bash
nh darwin switch -H zephyr .
```
