let
  # Sites allowed to override browser keyboard shortcuts even though the
  # profile blocks that globally ("permissions.default.shortcuts" = 2 in
  # default.nix). Entries are origins including the scheme, as used by the
  # site permission "Override Keyboard Shortcuts".
  shortcutAllowOrigins = [
    "https://docs.google.com"
  ];
in
{
  inherit shortcutAllowOrigins;

  # AutoConfig JavaScript appended to mozilla.cfg through the nixpkgs
  # Firefox wrapper's extraPrefs argument. Firefox evaluates it with
  # chrome privileges on every startup, after the profile is ready, and
  # grants the "shortcuts" permission to each origin the same way the
  # site permission UI would. policies.json cannot express this: its
  # Permissions policy has no Shortcuts key, so per-origin exceptions
  # have to be written to the permission manager directly.
  #
  # The script only adds permissions. Removing an origin from the list
  # above does not revoke it; use the site permission UI once if needed.
  # Every failure is contained so AutoConfig can never abort startup.
  shortcutAllowPrefs = ''
    // Allow the origins from permissions.nix to override keyboard
    // shortcuts even though permissions.default.shortcuts blocks them.
    (function () {
      try {
        var Cc = Components.classes;
        var Ci = Components.interfaces;
        var perms = Cc["@mozilla.org/permissionmanager;1"].getService(
          Ci.nsIPermissionManager
        );
        var ssm = Cc["@mozilla.org/scriptsecuritymanager;1"].getService(
          Ci.nsIScriptSecurityManager
        );
        var origins = ${builtins.toJSON shortcutAllowOrigins};
        origins.forEach(function (origin) {
          try {
            perms.addFromPrincipal(
              ssm.createContentPrincipalFromOrigin(origin),
              "shortcuts",
              perms.ALLOW_ACTION,
              perms.EXPIRE_NEVER
            );
          } catch (e) {
            Components.utils.reportError(
              "firefox: could not allow shortcut override for " + origin + ": " + e
            );
          }
        });
      } catch (e) {
        try {
          Components.utils.reportError("firefox extraPrefs: " + e);
        } catch (e2) {}
      }
    })();
  '';
}
