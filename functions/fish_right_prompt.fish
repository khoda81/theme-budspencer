###############################################################################
#
# Prompt theme name:
#   budspencer
#
# Description:
#   a sophisticated airline/powerline theme
#
# Original Author:
#   Joseph Tannhuber <sepp.tannhuber@yahoo.de>
#
# Additional edits and bug fixes:
#   Clayton Auld <clayauld@gmail.com>
#
# Sections:
#   -> TTY Detection
#   -> Functions
#     -> Toggle functions
#     -> Command duration segment
#     -> Git segment
#     -> PWD segment
#   -> Prompt
#
###############################################################################

###############################################################################
# => TTY Detection
###############################################################################

# Automatically disables right prompt when in a tty
# Except in Darwin due to OS X terminals identifying themselves as a tty
# Bug fix for WSL terminals as these, too, identify themselves as a tty
if not test (uname) = Darwin
    if not test (uname -r | command grep -i microsoft)
        if tty | command grep tty >/dev/null
            exit
        end
    end
end

###############################################################################
# => Functions
###############################################################################

#####################
# => Toggle functions
#####################
function __budspencer_toggle_symbols -d 'Toggles style of symbols, press # in NORMAL or VISUAL mode'
    if [ $symbols_style = symbols ]
        set symbols_style numbers
    else
        set symbols_style symbols
    end
    set pwd_hist_lock true
    commandline -f repaint
end

function __budspencer_toggle_pwd -d 'Toggles style of pwd segment, press space bar in NORMAL or VISUAL mode'
    for i in (seq (count $budspencer_pwdstyle))
        if [ $budspencer_pwdstyle[$i] = $pwd_style ]
            set pwd_style $budspencer_pwdstyle[(expr $i \% (count $budspencer_pwdstyle) + 1)]
            set pwd_hist_lock true
            commandline -f repaint
            break
        end
    end
end

#############################
# => Command duration segment
#############################

function __budspencer_cmd_duration -d 'Displays the elapsed time of last command'
    set -l seconds ''
    set -l minutes ''
    set -l hours ''
    set -l days ''

    set -l cmd_duration (math -s0 $CMD_DURATION / 1000)
    if [ $cmd_duration -gt 0 ]
        set seconds (math -s0 $cmd_duration % 60)'s'
        if [ $cmd_duration -ge 60 ]
            set minutes (math -s0 $cmd_duration % 3600 / 60)'m'
            if [ $cmd_duration -ge 3600 ]
                set hours (math -s0 $cmd_duration % 86400 / 3600)'h'
                if [ $cmd_duration -ge 86400 ]
                    set days (math -s0 $cmd_duration / 86400)'d'
                end
            end
        end
        set_color $budspencer_colors[2]
        echo -n ''
        switch $pwd_style
            case short long
                if [ $last_status -ne 0 ]
                    echo -n (set_color -b $budspencer_colors[2] $budspencer_colors[7])' '$days$hours$minutes$seconds' '
                else
                    echo -n (set_color -b $budspencer_colors[2] $budspencer_colors[12])' '$days$hours$minutes$seconds' '
                end
        end
        set_color -b $budspencer_colors[2]
    end
end

################
# => Git segment
################
function __budspencer_is_git_ahead_or_behind -d 'Check if there are unpulled or unpushed commits'
    if set -l ahead_or_behind (command git rev-list --count --left-right 'HEAD...@{upstream}' 2> /dev/null)
        echo $ahead_or_behind | sed 's|[[:space:]]|\n|g'
    else
        echo 0\n0
    end
end

function __budspencer_git_status -d 'Check git status'
    set -l git_status (command git status --porcelain 2> /dev/null | cut -c 1-2)
    set -l added (echo -sn $git_status\n | grep -E -c "[ACDMT][ MT]|[ACMT]D")
    set -l deleted (echo -sn $git_status\n | grep -E -c "[ ACMRT]D")
    set -l modified (echo -sn $git_status\n | grep -E -c ".[MT]")
    set -l renamed (echo -sn $git_status\n | grep -E -c "R.")
    set -l unmerged (echo -sn $git_status\n | grep -E -c "AA|DD|U.|.U")
    set -l untracked (echo -sn $git_status\n | grep -E -c "\?\?")
    echo -n $added\n$deleted\n$modified\n$renamed\n$unmerged\n$untracked
end

function __budspencer_is_git_stashed -d 'Check if there are stashed commits'
    command git log --format="%gd" -g $argv refs/stash -- 2>/dev/null | wc -l | tr -d '[:space:]'
end

function __budspencer_svn_status -d 'Check svn status'
    set -l svn_status (command svn status "$argv[1]" 2> /dev/null | grep '^[ACDIMRX?!~ ]' | cut -c 1-2)
    set -l added (echo -sn $svn_status\n | grep -E -c "A.")
    set -l deleted (echo -sn $svn_status\n | grep -E -c "[D!].")
    set -l modified (echo -sn $svn_status\n | grep -E -c "M.|.M")
    set -l renamed (echo -sn $svn_status\n | grep -E -c "R.")
    set -l unmerged (echo -sn $svn_status\n | grep -E -c "[~C].|.C")
    set -l untracked (echo -sn $svn_status\n | grep -E -c '\?.')
    echo -n $added\n$deleted\n$modified\n$renamed\n$unmerged\n$untracked
end

function __budspencer_is_repo_ahead_or_behind
    set -l git_root "$argv[1]"
    set -l svn_root "$argv[2]"

    if test (string length "$git_root") -gt (string length "$svn_root")
        __budspencer_is_git_ahead_or_behind
    else
        echo 0\n0
    end
end

function __budspencer_repo_status
    set -l git_root "$argv[1]"
    set -l svn_root "$argv[2]"

    if test (string length "$svn_root") -gt (string length "$git_root")
        __budspencer_svn_status "$svn_root"
    else if test $git_root
        __budspencer_git_status
    else
        return
    end
end

function __budspencer_is_repo_stashed
    set -l git_root "$argv[1]"
    set -l svn_root "$argv[2]"

    if test (string length "$git_root") -gt (string length "$svn_root")
        __budspencer_is_git_stashed
    else
        echo 0
    end
end

function __budspencer_prompt_repo_symbols -d 'Displays the repo symbols'
    set -l git_root (git rev-parse --show-toplevel 2> /dev/null)
    set -l svn_root (svn info --show-item wc-root 2> /dev/null)

    if test (string length "$svn_root") -eq 0 -a (string length "$git_root") -eq 0
        return
    end
    set -l repo_ahead_behind (__budspencer_is_repo_ahead_or_behind "$git_root" "$svn_root")
    set -l repo_status (__budspencer_repo_status "$git_root" "$svn_root")
    set -l repo_stashed (__budspencer_is_repo_stashed "$git_root" "$svn_root")

    if [ (expr $repo_ahead_behind[1] + $repo_ahead_behind[2] + $repo_status[1] + $repo_status[2] + $repo_status[3] + $repo_status[4] + $repo_status[5] + $repo_status[6] + $repo_stashed) -ne 0 ]
        set_color $budspencer_colors[3]
        echo -n ''
        set_color -b $budspencer_colors[3]
        switch $pwd_style
            case long short
                if [ $symbols_style = symbols ]
                    if [ $repo_ahead_behind[1] -gt 0 ]
                        set_color -o $budspencer_colors[5]
                        echo -n ' '
                    end
                    if [ $repo_ahead_behind[2] -gt 0 ]
                        set_color -o $budspencer_colors[5]
                        echo -n ' '
                    end
                    if [ $repo_status[1] -gt 0 ]
                        set_color -o $budspencer_colors[12]
                        echo -n ' '
                    end
                    if [ $repo_status[2] -gt 0 ]
                        set_color -o $budspencer_colors[7]
                        echo -n ' D'
                    end
                    if [ $repo_status[3] -gt 0 ]
                        set_color -o $budspencer_colors[10]
                        echo -n ' *'
                    end
                    if [ $repo_status[4] -gt 0 ]
                        set_color -o $budspencer_colors[8]
                        echo -n ' '
                    end
                    if [ $repo_status[5] -gt 0 ]
                        set_color -o $budspencer_colors[9]
                        echo -n ' ═'
                    end
                    if [ $repo_status[6] -gt 0 ]
                        set_color -o $budspencer_colors[4]
                        echo -n ' '
                    end
                    if [ $repo_stashed -gt 0 ]
                        set_color -o $budspencer_colors[11]
                        echo -n ' '
                    end
                else
                    if [ $repo_ahead_behind[1] -gt 0 ]
                        set_color $budspencer_colors[5]
                        echo -n ' '$repo_ahead_behind[1]
                    end
                    if [ $repo_ahead_behind[2] -gt 0 ]
                        set_color $budspencer_colors[5]
                        echo -n ' '$repo_ahead_behind[2]
                    end
                    if [ $repo_status[1] -gt 0 ]
                        set_color $budspencer_colors[12]
                        echo -n ' '$repo_status[1]
                    end
                    if [ $repo_status[2] -gt 0 ]
                        set_color $budspencer_colors[7]
                        echo -n ' '$repo_status[2]
                    end
                    if [ $repo_status[3] -gt 0 ]
                        set_color $budspencer_colors[10]
                        echo -n ' '$repo_status[3]
                    end
                    if [ $repo_status[4] -gt 0 ]
                        set_color $budspencer_colors[8]
                        echo -n ' '$repo_status[4]
                    end
                    if [ $repo_status[5] -gt 0 ]
                        set_color $budspencer_colors[9]
                        echo -n ' '$repo_status[5]
                    end
                    if [ $repo_status[6] -gt 0 ]
                        set_color $budspencer_colors[4]
                        echo -n ' '$repo_status[6]
                    end
                    if [ $repo_stashed -gt 0 ]
                        set_color $budspencer_colors[11]
                        echo -n ' '$repo_stashed
                    end
                end
                set_color -b $budspencer_colors[3] normal
                echo -n ' '
        end
    end
end

################
# => PWD segment
################
function __budspencer_prompt_pwd -d 'Displays the present working directory'
    set -l user_host ' '
    if set -q SSH_CLIENT
        if [ $symbols_style = symbols ]
            switch $pwd_style
                case short
                    set user_host " $USER@"(hostname -s)':'
                case long
                    set user_host " $USER@"(hostname -f)':'
            end
        else
            set user_host " $USER@"(hostname -i)':'
        end
    end
    set_color $budspencer_current_bindmode_color
    echo -n ''
    set_color normal
    set_color -b $budspencer_current_bindmode_color $budspencer_colors[1]
    if [ (count $budspencer_prompt_error) != 1 ]
        switch $pwd_style
            case short
                echo -n $user_host(prompt_pwd)' '
            case long
                echo -n $user_host(pwd)' '
        end
    else
        echo -n " $budspencer_prompt_error "
        set -e budspencer_prompt_error[1]
    end
    set_color normal
    set_color $budspencer_current_bindmode_color
    echo -n ''
    set_color normal
end

###############################################################################
# => Clock
###############################################################################

function __budspencer_prompt_clock -d 'Displays the current time'
    set_color $budspencer_colors[6]
    echo -n ''
    set_color -b $budspencer_colors[6] $budspencer_colors[1]
    echo -n ' '(date +%T)' '
end

###############################################################################
# => Prompt
###############################################################################

function fish_right_prompt -d 'Write out the right prompt of the budspencer theme'
    echo -n -s (__budspencer_cmd_duration) (__budspencer_prompt_clock) (__budspencer_prompt_repo_symbols) (__budspencer_prompt_pwd)
    set_color normal
end
