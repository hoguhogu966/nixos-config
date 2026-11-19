# `zephyr`

macOS laptop — nix-darwin on `aarch64-darwin`. Smaller than `freesia`; username is parameterized.

- **Flake entry**: `flake/hosts/zephyr.nix` → `darwinConfigurations.zephyr` (invoked with `user_name = "zephyr"`)
- **nix-darwin config**: `hosts/zephyr/` (`default.nix`, `brew.nix`)
- **Home Manager**: `home/zephyr.nix`, user `zephyr`

## Modules

`flake/hosts/zephyr.nix` imports:

- `hosts/zephyr/` (imports `./brew.nix`, `modules/cachix`, `modules/sops`)
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

`hosts/zephyr/configuration.nix` runs `atuin-server` as a launchd daemon (`launchd.daemons.atuin`, label `org.nixos.atuin`):

- Listens on `127.0.0.1:8888` only, SQLite database at `~/.local/share/atuin/server.db`, logs to `/var/log/atuin.log`
- Exposed to the tailnet as `https://zephyr.tail32a8e5.ts.net` via `tailscale serve --bg http://127.0.0.1:8888` (imperative one-liner, persists in tailscaled)
- Clients point at it with `sync_address` in `home/programs/atuin/default.nix`
- `ATUIN_OPEN_REGISTRATION` starts as `"true"`; flip to `"false"` once accounts are registered


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
