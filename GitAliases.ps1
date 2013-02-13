# Additional aliases for easier git workflow
# Inspired by git plugin for zsh: https://github.com/robbyrussell/oh-my-zsh/blob/master/plugins/git/git.plugin.zsh
# Modified to be more intuitive and work with default powershell aliases.

$gitAliases = @{
    "g" = "git";
    "gst" = "git status";
    "gsts" = "git status -s";
    "gpl" = "git pull";
    "gplr" = "git pull --rebase";
    "gpu" = "git push";
    "gpuoat" = "git push origin --all; if ($?) { git push origin --tags }";
    "gd" = "git diff";
    "gcv" = "git commit -v";
    "gcva" = "git commit -v -a";
    "gco" = "git checkout";
    "gcom" = "git checkout master";
    "gr" = "git remote";
    "grv" = "git remote -v";
    "grmv" = "git remote rename";
    "grrm" = "git remote remove";
    "grset" = "git remote set-url";
    "grup" = "git remote update";
    "gb" = "git branch";
    "gba" = "git branch -a";
    "gcount" = "git shortlog -sn";
    "gcl" = "git config --list";
    "gcp" = "git cherry-pick";
    "glg" = "git log --stat --max-count=5";
    "glgg" = "git log --graph --max-count=5";
    "glgga" = "git log --graph --decorate --all";
    "ga" = "git add";
    "gmg" = "git merge";
    "grh" = "git reset HEAD";
    "grhh" = "git reset HEAD --hard";
    "gwc" = "git whatchanged -p --abbrev-commit --pretty=medium";
    "gf" = "git ls-files | grep";
}

$gitAliases.GetEnumerator() | % { Set-Item -Path $("function:global:" + $_.Name) -Value $_.Value }
