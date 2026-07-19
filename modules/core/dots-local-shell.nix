# Low-ceremony path for adding shell vars/aliases/init snippets from
# dots-local, without needing a full extraModules escape-hatch file for
# something as small as one env var.
#
# Deliberately in its own module file (rather than folded into
# core/default.nix's programs.bash block) so Home Manager's normal
# cross-module merging handles combining this with every other module's
# contribution to programs.bash.* (sessionVariables/shellAliases merge as
# attrsets, initExtra concatenates as `lines`) - no manual string
# concatenation needed here.
{ dotsLocal, ... }:
{
  programs.bash.sessionVariables = dotsLocal.shell.sessionVariables;
  programs.bash.shellAliases = dotsLocal.shell.shellAliases;
  programs.bash.initExtra = dotsLocal.shell.initExtra;
}
