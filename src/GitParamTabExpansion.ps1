# Variable is used in GitTabExpansion.ps1
$shortGitParams = @{
    add = 'n v f i p e u A N'
    bisect = ''
    blame = 'b L l t S p M C h c f n s e w'
    branch = 'd D l f m M r a v vv q t u'
    checkout = 'q f b B t l m p'
    cherry = 'v'
    'cherry-pick' = 'e x r m n s S X'
    clean = 'd f i n q e x X'
    clone = 'l s q v n o b u c'
    commit = 'a p C c z F m t s n e i o u v q S'
    config = 'f l z e'
    diff = 'p u s U z B M C D l S G O R a b w W'
    difftool = 'd y t x g'
    fetch = 'a f k p n t u q v'
    grep = 'a i I w v h H E G P F n l L O z c p C A B W f e q'
    help = 'a g i m w'
    init = 'q'
    log = 'L n i E F g c c m r t'
    merge = 'e n s X q v S m'
    mergetool = 't y'
    mv = 'f k n v'
    notes = 'f m F C c n s q v'
    prune = 'n v'
    pull = 'q v e n s X r a f k u'
    push = 'n f u q v'
    rebase = 'm s X S q v n C f i p x'
    remote = 'v'
    reset = 'q p'
    restore = 's p W S q m'
    revert = 'e m n S s X'
    rm = 'f n r q'
    shortlog = 'n s e w'
    stash = 'p k u a q'
    status = 's b u z'
    submodule = 'q b f n N'
    switch = 'c C d f m q t'
    tag = 'a s u f d v n l m F'
    whatchanged = 'p'
}

# Variable is used in GitTabExpansion.ps1
$longGitParams = @{
    add = 'dry-run verbose force interactive patch edit update all no-ignore-removal no-all ignore-removal intent-to-add refresh ignore-errors ignore-missing renormalize'
    bisect = 'no-checkout term-old term-new'
    blame = 'root show-stats reverse porcelain line-porcelain incremental encoding= contents date score-debug show-name show-number show-email abbrev'
    branch = 'color no-color list abbrev= no-abbrev column no-column merged no-merged contains set-upstream track no-track set-upstream-to= unset-upstream edit-description delete create-reflog force move all verbose quiet'
    checkout = 'quiet force ours theirs track no-track detach orphan ignore-skip-worktree-bits merge conflict= patch'
    'cherry-pick' = 'edit mainline no-commit signoff gpg-sign ff allow-empty allow-empty-message keep-redundant-commits strategy= strategy-option= continue quit abort'
    clean = 'force interactive dry-run quiet exclude='
    clone = 'local no-hardlinks shared reference quiet verbose progress no-checkout bare mirror origin branch upload-pack template= config depth single-branch no-single-branch recursive recurse-submodules separate-git-dir='
    commit = 'all patch reuse-message reedit-message fixup squash reset-author short branch porcelain long null file author date message template signoff no-verify allow-empty allow-empty-message cleanup= edit no-edit amend no-post-rewrite include only untracked-files verbose quiet dry-run status no-status gpg-sign no-gpg-sign'
    config = 'replace-all add get get-all get-regexp get-urlmatch global system local file blob remove-section rename-section unset unset-all list bool int bool-or-int path null get-colorbool get-color edit includes no-includes'
    describe = 'dirty all tags contains abbrev candidates= exact-match debug long match always first-parent'
    diff = 'cached patch no-patch unified= raw patch-with-raw minimal patience histogram diff-algorithm= stat numstat shortstat dirstat summary patch-with-stat name-only name-status submodule color no-color word-diff word-diff-regex color-words no-renames check full-index binary apprev break-rewrites find-renames find-copies find-copies-harder irreversible-delete diff-filter= pickaxe-all pickaxe-regex relative text ignore-space-at-eol ignore-space-change ignore-all-space ignore-blank-lines inter-hunk-context= function-context exit-code quiet ext-diff no-ext-diff textconv no-textconv ignore-submodules src-prefix dst-prefix no-prefix staged'
    difftool = 'dir-diff no-prompt prompt tool= tool-help no-symlinks symlinks extcmd= gui'
    fetch = 'all append depth= unshallow update-shallow dry-run force keep multiple prune no-tags tags recurse-submodules= no-recurse-submodules submodule-prefix= recurse-submodules-default= update-head-ok upload-pack quiet verbose progress'
    gc = 'aggressive auto prune= no-prune quiet force'
    grep = 'cached no-index untracked no-exclude-standard exclude-standard text textconv no-textconv ignore-case max-depth word-regexp invert-match full-name extended-regexp basic-regexp perl-regexp fixed-strings line-number files-with-matches open-file-in-pager null count color no-color break heading show-function context after-context before-context function-context and or not all-match quiet'
    help = 'all guides info man web'
    init = 'quiet bare template= separate-git-dir= shared='
    log = 'follow no-decorate decorate source use-mailmap full-diff log-size max-count skip since after until before author committer grep-reflog grep all-match regexp-ignore-case basic-regexp extended-regexp fixed-strings perl-regexp remove-empty merges no-merges min-parents max-parents no-min-parents no-max-parents first-parent not all branches tags remote glob= exclude= ignore-missing bisect stdin cherry-mark cherry-pick left-only right-only cherry walk-reflogs merge boundary simplify-by-decoration full-history dense sparse simplify-merges ancestry-path date-order author-date-order topo-order reverse objects objects-edge unpacked no-walk= do-walk pretty format= abbrev-commit no-abbrev-commit oneline encoding= notes no-notes standard-notes no-standard-notes show-signature relative-date date= parents children left-right graph show-linear-break patch stat'
    merge = 'commit no-commit edit no-edit ff no-ff ff-only log no-log stat no-stat squash no-squash strategy strategy-option verify-signatures no-verify-signatures summary no-summary quiet verbose progress no-progress gpg-sign rerere-autoupdate no-rerere-autoupdate abort allow-unrelated-histories'
    mergetool = 'tool= tool-help no-prompt prompt'
    mv = 'force dry-run verbose'
    notes = 'force message file reuse-message reedit-message ref ignore-missing stdin dry-run strategy= commit abort quiet verbose'
    prune = 'dry-run verbose expire'
    pull = 'quiet verbose recurse-submodules= no-recurse-submodules= commit no-commit edit no-edit ff no-ff ff-only log no-log stat no-stat squash no-squash strategy= strategy-option= verify-signatures no-verify-signatures summary no-summary rebase= no-rebase all append depth= unshallow update-shallow force keep no-tags update-head-ok upload-pack progress'
    push = 'all prune mirror dry-run porcelain delete tags follow-tags receive-pack= exec= force-with-lease no-force-with-lease force repo= set-upstream thin no-thin quiet verbose progress recurse-submodules= verify no-verify'
    rebase = 'onto continue abort keep-empty skip edit-todo merge strategy= strategy-option= gpg-sign quiet verbose stat no-stat no-verify verify force-rebase fork-point no-fork-point ignore-whitespace whitespace= committer-date-is-author-date ignore-date interactive preserve-merges exec root autosquash no-autosquash autostash no-autostash no-ff'
    reflog = 'stale-fix expire= expire-unreachable= all updateref rewrite verbose'
    remote = 'verbose'
    reset = 'patch quiet soft mixed hard merge keep'
    restore = 'source= patch worktree staged quiet progress no-progress ours theirs merge conflict= ignore-unmerged ignore-skip-worktree-bits overlay no-overlay'
    revert = 'edit mainline no-edit no-commit gpg-sign signoff strategy= strategy-option continue quit abort'
    rm = 'force dry-run cached ignore-unmatch quiet'
    shortlog = 'numbered summary email format='
    show = 'pretty= format= abbrev-commit no-abbrev-commit oneline encoding= notes no-notes show-notes no-standard-notes standard-notes show-signature'
    stash = 'patch no-keep-index keep-index include-untracked all quiet index'
    status = 'short branch porcelain long untracked-files ignore-submodules ignored column no-column'
    submodule = 'quiet branch force cached files summary-limit remote no-fetch checkout merge rebase init name reference recursive depth'
    switch = 'create force-create detach guess no-guess force discard-changes merge conflict= quiet no-progress track no-track orphan ignore-other-worktrees recurse-submodules no-recurse-submodules'
    tag = 'annotate sign local-user force delete verify list sort column no-column contains points-at message file cleanup'
    whatchanged = 'since'
}

$shortVstsGlobal = 'h o'
$shortVstsParams = @{
    abandon = "i $shortVstsGlobal"
    create = "d i p r s t $shortVstsGlobal"
    complete = "i $shortVstsGlobal"
    list = "i p r s t $shortVstsGlobal"
    reactivate = "i $shortVstsGlobal"
    'set-vote' = "i $shortVstsGlobal"
    show = "i $shortVstsGlobal"
    update = "d i $shortVstsGlobal"
}

$longVstsGlobal = 'debug help output query verbose'
$longVstsParams = @{
    abandon = "id detect instance $longVstsGlobal"
    create = "auto-complete delete-source-branch work-items bypass-policy bypass-policy-reason description detect instance merge-commit-message open project repository reviewers source-branch squash target-branch title $longVstsGlobal"
    complete = "id detect instance $longVstsGlobal"
    list = " $longVstsGlobal"
    reactivate = " $longVstsGlobal"
    'set-vote' = " $longVstsGlobal"
    show = " $longVstsGlobal"
    update = " $longVstsGlobal"
}

# Variable is used in GitTabExpansion.ps1
$gitParamValues = @{
    blame = @{
        encoding = 'utf-8 none'
    }
    branch = @{
        color = 'always never auto'
        abbrev = '7 8 9 10'
    }
    checkout = @{
        conflict = 'merge diff3'
    }
    'cherry-pick' = @{
        strategy = 'resolve recursive octopus ours subtree'
    }
    commit = @{
        'cleanup' = 'strip whitespace verbatim scissors default'
    }
    diff = @{
        unified = '0 1 2 3 4 5'
        'diff-algorithm' = 'default patience minimal histogram myers'
        color = 'always never auto'
        'word-diff' = 'color plain porcelain none'
        abbrev = '7 8 9 10'
        'diff-filter' = 'A C D M R T U X B *'
        'inter-hunk-context' = '0 1 2 3 4 5'
        'ignore-submodules' = 'none untracked dirty all'
    }
    difftool = @{
        tool = 'vimdiff vimdiff2 araxis bc3 codecompare deltawalker diffmerge diffuse ecmerge emerge gvimdiff gvimdiff2 kdiff3 kompare meld opendiff p4merge tkdiff xxdiff'
    }
    fetch = @{
        'recurse-submodules' = 'yes on-demand no'
        'recurse-submodules-default' = 'yes on-demand'
    }
    init = @{
        shared = 'false true umask group all world everybody o'
    }
    log = @{
        decorate = 'short full no'
        'no-walk' = 'sorted unsorted'
        pretty = {
            param($format)
            gitConfigKeys 'pretty' $format 'oneline short medium full fuller email raw'
        }
        format = {
            param($format)
            gitConfigKeys 'pretty' $format 'oneline short medium full fuller email raw'
        }
        encoding = 'UTF-8'
        date = 'relative local default iso rfc short raw'
    }
    merge = @{
        strategy = 'resolve recursive octopus ours subtree'
        log = '1 2 3 4 5 6 7 8 9'
    }
    mergetool = @{
        tool = 'vimdiff vimdiff2 araxis bc3 codecompare deltawalker diffmerge diffuse ecmerge emerge gvimdiff gvimdiff2 kdiff3 kompare meld opendiff p4merge tkdiff xxdiff'
    }
    notes = @{
        strategy = 'manual ours theirs union cat_sort_uniq'
    }
    pull = @{
        strategy = 'resolve recursive octopus ours subtree'
        'recurse-submodules' = 'yes on-demand no'
        'no-recurse-submodules' = 'yes on-demand no'
        rebase = 'false true preserve'
    }
    push = @{
        'recurse-submodules' = 'check on-demand'
    }
    rebase = @{
        strategy = 'resolve recursive octopus ours subtree'
    }
    restore = @{
        conflict = 'merge diff3'
        source = {
            param($ref)
            gitBranches $ref $true
            gitTags $ref
        }
    }
    revert = @{
        strategy = 'resolve recursive octopus ours subtree'
    }
    show = @{
        pretty = {
            param($format)
            gitConfigKeys 'pretty' $format 'oneline short medium full fuller email raw'
        }
        format = {
            param($format)
            gitConfigKeys 'pretty' $format 'oneline short medium full fuller email raw'
        }
        encoding = 'utf-8'
    }
    status = @{
        'untracked-files' = 'no normal all'
        'ignore-submodules' = 'none untracked dirty all'
    }
    switch = @{
        conflict = 'merge diff3'
    }
}
