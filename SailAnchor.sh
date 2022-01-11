#!/bin/bash
# * FileName: Shell Log Anchor
# * Author: Leyuan Jia
# * Email: Leyuan.Jia@outlook.com
# * Date: 2022, Jua. 11th
# * Copyright: No copyright. You can use this code for anything with no warranty.

# 信息
SHELL_NAME=${SHELL_NAME:-"SailAnchor.sh"}
LOG_FILE=${LOG_FILE:-"anchors.log"}

# 配置
# 日期格式化
SAILOR_DATE_FORMAT=${SAILOR_DATE_FORMAT:-'%Y/%m/%d %H:%M:%S'}
# 0: debug, 1: info, 2: notice, 3: warning, 4: error
# 小于SAILOR_LEVEL的不再显示
SAILOR_LEVEL=${SAILOR_LEVEL:-1}
if [ "${SAILOR_LEVELS}" = "" ]; then
    SAILOR_LEVELS=("DEBUG" "INFO" "NOTICE" "WARNING" "ERROR")
fi
# 大于SAILOR_STD_ERROR_LEVEL的不再显示
SAILOR_STD_ERROR_LEVEL=${SAILOR_STD_ERROR_LEVEL:-4}
# 斜体
SAILOR_DEBUG_COLOR=${SAILOR_INFO_COLOR:-"3"}
# 终端默认颜色
SAILOR_INFO_COLOR=${SAILOR_INFO_COLOR:-""}
# Cyan
SAILOR_NOTICE_COLOR=${SAILOR_INFO_COLOR:-"36"}
# Yellow
SAILOR_WARNING_COLOR=${SAILOR_INFO_COLOR:-"33"}
# Red
SAILOR_ERROR_COLOR=${SAILOR_INFO_COLOR:-"31"}
# never -> Always no color.
# auto  -> Put color only for terminal output.
# always-> Always put color.
SAILOR_COLOR=${SAILOR_COLOR:-auto}
SAILOR_COLORS=("$SAILOR_DEBUG_COLOR" "$SAILOR_INFO_COLOR" "$SAILOR_NOTICE_COLOR" "$SAILOR_WARNING_COLOR" "$SAILOR_ERROR_COLOR")
# 错误返回码
SAILOR_ERROR_RETURN_CODE=${SAILOR_ERROR_RETURN_CODE:-100}

# 开关
# 是否显示时间
SAILOR_SHOW_TIME=${SAILOR_SHOW_TIME:-1}
# 是否显示位置
SAILOR_SHOW_FILE=${SAILOR_SHOW_FILE:-1}
# 是否显示等级
SAILOR_SHOW_LEVEL=${SAILOR_SHOW_LEVEL:-1}
# 是否显示错误TraceBack
SAILOR_ERROR_TRACE=${SAILOR_ERROR_TRACE:-1}

# 全局执行结果标志位，有一步出错后日志不会继续输出
# 父子Shell进程通信使用与该文件同目录下的anc文件标识
export GLOBAL_FAIL_ANCHOR="$(
    cd $(dirname ${BASH_SOURCE[0]})
    pwd
)/iceberg.anc"

# 清理标志位函数：在加载logForShell函数后，务必在主入口脚本所有语句执行前调用
function _weigh_anchor() {
    if [ -f ${GLOBAL_FAIL_ANCHOR} ]; then
        rm -f ${GLOBAL_FAIL_ANCHOR}
    fi
}

#  日志时间 [%Y/%m/%d %H:%M:%S]
function _sailor_time() {
    [ "${SAILOR_SHOW_TIME}" -ne 1 ] && return
    printf "[$(date +"${SAILOR_DATE_FORMAT}")]"
}

# 日志位置 ［shell:line]
function _sailor_site() {
    [ "${SAILOR_SHOW_FILE}" -ne 1 ] && return
    local i=0
    if [ $# -ne 0 ]; then
        i=$1
    fi
    if [ -n "${BASH_VERSION}" ]; then
        # [shell:line]
        printf "[${BASH_SOURCE[$((i + 1))]}:${BASH_LINENO[$i]}]"
    else
        # zsh
        emulate -L ksh
        printf "[${funcfiletrace[$i]}]"
    fi
}

# 日志等级 0: debug, 1: info, 2: notice, 3: warning, 4: error
function _sailor_level() {
    [ "${SAILOR_SHOW_LEVEL}" -ne 1 ] && return
    if [ $# -eq 1 ]; then
        local level=$1
    else
        local level=1
    fi
    [ -z "${ZSH_VERSION}" ] || emulate -L ksh
    printf "[${SAILOR_LEVELS[$level]}]"
}

function _get_level() {
    if [ $# -eq 0 ]; then
        local level=1
    else
        local level=$1
    fi
    # level 不为 长度为1的数字
    if ! expr "$level" : '[0-9]*' >/dev/null; then
        [ -z "$ZSH_VERSION" ] || emulate -L ksh
        local i=0
        while [ $i -lt ${#SAILOR_LEVELS[@]} ]; do
            if [ "$level" = "${SAILOR_LEVELS[$i]}" ]; then
                level=$i
                break
            fi
            ((i++))
        done
    fi
    printf $level
}

function horn() {
    printf "$(_sailor_time)[$$]$*"
}

# diary() 只记录不输出
function diary() {
    echo "$@" 1>>${LOG_FILE}
}

# call() 不包含任何标签输出
function call() {
    echo "$@" | tee -a ${LOG_FILE}
}

# blow() 包含信息输出
function blow() {
    if [ ! -f ${GLOBAL_FAIL_ANCHOR} ]; then
        if [ $# -eq 2 ]; then
            echo -e "\033[$1m$2\033[m"
            diary "$2"
        else
            echo -e "\033[m$1\033[m"
            diary "$1"
        fi
    fi
}

_SAILOR_ANCHOR=0
function _sailor() {
    ((_SAILOR_ANCHOR++))
    local anchor=${_SAILOR_ANCHOR}
    _SAILOR_ANCHOR=0
    if [ $# -eq 0 ]; then
        return
    fi
    local level="$1"
    shift
    if [ "$level" -lt "$(_get_level "${SAILOR_LEVEL}")" ]; then
        return
    fi

    # local msg="$(_sailor_time)[$$]$(_sailor_site "${anchor}")$(_sailor_level "${level}") $*"
    local msg="$(horn "$(_sailor_site "${anchor}")$(_sailor_level "${level}")") $*"

    local _sailor_printf=printf
    local out=1
    if [ "${level}" -ge "${SAILOR_STD_ERROR_LEVEL}" ]; then
        out=2
        _sailor_printf=">&2 printf"
    fi
    # ^[[36m[2022/01/10 07:41:47][./sail.sh:6][NOTICE] Demo^[[m
    if [ "${SAILOR_COLOR}" = "always" ] || { test "${SAILOR_COLOR}" = "auto" && test -t ${out}; }; then
        [ -z "${ZSH_VERSION}" ] || emulate -L ksh
        # eval "${_sailor_printf} \"\\e[${SAILOR_COLORS[$level]}m%s\\e[m\\n\"  \"$msg\""
        # echo -e "\033[${SAILOR_COLORS[$level]}m${msg}\033[m" > 1.txt
        blow ${SAILOR_COLORS[$level]} "${msg}"
    else
        eval "${_sailor_printf} \"%s\\n\" \"$msg\""
    fi
}

function debug() {
    ((_SAILOR_ANCHOR++))
    _sailor 0 "$*"
}
function information() {
    ((_SAILOR_ANCHOR++))
    _sailor 1 "$*"
}
function info() {
    ((_SAILOR_ANCHOR++))
    information "$*"
}
function notification() {
    ((_SAILOR_ANCHOR++))
    _sailor 2 "$*"
}
function notice() {
    ((_SAILOR_ANCHOR++))
    notification "$*"
}
function warning() {
    ((_SAILOR_ANCHOR++))
    _sailor 3 "$*"
}
function warn() {
    ((_SAILOR_ANCHOR++))
    warning "$*"
}

function error() {
    ((_SAILOR_ANCHOR++))
    if [ "$SAILOR_ERROR_TRACE" -eq 1 ]; then
        {
            [ -z "$ZSH_VERSION" ] || emulate -L ksh
            local first=0
            if [ -n "$BASH_VERSION" ]; then
                local current_source=$(echo "${BASH_SOURCE[0]##*/}" | cut -d"." -f1)
                local func="${FUNCNAME[1]}"
                local i=$((${#FUNCNAME[@]} - 2))
            else
                local current_source=$(echo "${funcfiletrace[0]##*/}" | cut -d":" -f1 | cut -d"." -f1)
                local func="${funcstack[1]}"
                local i=$((${#funcstack[@]} - 1))
                local last_source=${funcfiletrace[$i]%:*}
                if [ "$last_source" = zsh ]; then
                    ((i--))
                fi
            fi
            if [ "$current_source" = "${SHELL_NAME}" ] && [ "$func" = iceberg ]; then
                local first=1
            fi
            if [ $i -ge $first ]; then
                call "Traceback (most recent call last):"
            fi
            while [ $i -ge $first ]; do
                if [ -n "$BASH_VERSION" ]; then
                    local file=${BASH_SOURCE[$((i + 1))]}
                    local line=${BASH_LINENO[$i]}
                    local func=""
                    if [ ${BASH_LINENO[$((i + 1))]} -ne 0 ]; then
                        if [ "${FUNCNAME[$((i + 1))]}" = "source" ]; then
                            func=", in ${BASH_SOURCE[$((i + 2))]}"
                        else
                            func=", in ${FUNCNAME[$((i + 1))]}"
                        fi
                    fi
                    local func_call="${FUNCNAME[$i]}"
                    if [ "$func_call" = "source" ]; then
                        func_call="${func_call} ${BASH_SOURCE[$i]}"
                    else
                        func_call="${func_call}()"
                    fi
                else
                    local file=${funcfiletrace[$i]%:*}
                    local line=${funcfiletrace[$i]#*:}
                    local func=""
                    if [ -n "${funcstack[$((i + 1))]}" ]; then
                        if [ "${funcstack[$((i + 1))]}" = "${funcfiletrace[$i]%:*}" ]; then
                            func=", in ${funcfiletrace[$((i + 1))]%:*}"
                        else
                            func=", in ${funcstack[$((i + 1))]}"
                        fi
                    fi
                    local func_call="${funcstack[$i]}"
                    if [ "$func_call" = "${funcfiletrace[$((i - 1))]%:*}" ]; then
                        func_call="source ${funcfiletrace[$((i - 1))]%:*}"
                    else
                        func_call="${func_call}()"
                    fi
                fi
                call "  File \"${file}\", line ${line}${func}"
                if [ $i -gt $first ]; then
                    call "    ${func_call}"
                else
                    call ""
                fi
                ((i--))
            done
        } 1>&2
    fi
    _sailor 4 "$*"
    return "${SAILOR_ERROR_RETURN_CODE}"
}
function iceberg() {
    ((_SAILOR_ANCHOR++))
    error "$*"
}

# welcome() 欢迎使用
function welcome() {
    call "*********************************"
    call "* Welcome to use ShellLogAnchor *"
    call "*********************************"
}

# step() 步骤打印函数：需要传入$1：步骤序号，$2：步骤描述
# 如： Step 1 "Configure yum repos"
function step() {
    local srouce_filename=$(caller)
    echo ""
    blow "$(horn "==  ${srouce_filename##*/}  STEP $1 : $2  ==")"
    echo ""
}

# before_sail() 脚本执行前函数：在关键脚本开始时执行，调用时需要传入执行脚本的所有参数
# 如： before_sail $@
function before_sail() {
    srouce_filename=$(caller)
    echo ""
    blow "$(horn "++  ${srouce_filename##*/}  BEGIN  ++")"
    blow "$(horn "++  ${srouce_filename##*/} $@  ++")"
    echo ""
}

# after_sail() 脚本结束函数：在脚本结束时执行
function after_sail() {
    srouce_filename=$(caller)
    echo ""
    blow "$(horn "##  ${srouce_filename##*/}  FINISH ##")"
}

# report_capsize() 错误报告函数：在某一步结束后判断执行结果，若出错则调用该函数
# 该函数会改变执行结果标志位，阻止出错后日志继续输出
function report_capsize() {
    touch ${GLOBAL_FAIL_ANCHOR}
    call ""
    call "**  line $(caller) REPORTED FAILURE  **"
    call ""
    # 通过循环判断caller返回，如果不为空则持续打印，最多打印5行
    call "    CALLER LIST    "
    call " - line $(caller 0)"
    for loop in 1 2 3 4; do
        if [ "$(caller ${loop})" != "" ]; then
            call " - line $(caller ${loop})"
        else
            call ""
            break
        fi
    done
}

# report_arrival() 成功报告函数：在关键步骤结束后判断执行结S果，成功则调用该函数
# 一般步骤不用调用该函数输出
# 如： report_arrival "Init and check related params"
function report_arrival() {
    call ""
    blow "**  $1 SUCCESS  **"
    call ""
}

$(_weigh_anchor)