# ⛵SailAnchor⚓
This is a log collector for shell scripts, like the ⚓anchor of the ⛵ sail (shell).

## ⛵展示

MobaXterm

<img src="https://image-taragrade.oss-cn-hangzhou.aliyuncs.com/imagehub/image-20220112100743969.png" alt="MobaXterm" style="zoom:50%;" />

Xshell

<img src="https://image-taragrade.oss-cn-hangzhou.aliyuncs.com/imagehub/image-20220112100916382.png" alt="xshell" style="zoom:50%;" />

Windows Terminal

<img src="https://image-taragrade.oss-cn-hangzhou.aliyuncs.com/imagehub/image-20220112101312655.png" alt="image-20220112101312655" style="zoom:50%;" />

## ⛵前言

这个脚本是日志收集器，主要用来收集自己写的一些shell脚本中产生的日志，以便于快于定位和解决问题。

不然就像在茫茫大海中，毫无目标。如果在航行中，通过锚(Anchor)就可以进行定位。

本脚本也参考了一些其他优秀脚本的思路，修改后更加贴合自己的要求。

## ⛵特点

- 可以使用（debug/info/notice/error/warn)标注不同的信息。并且可以配置不同的颜色，以便更快区别信息。
- 可以定位错误的Trace Stack。
- 设置日志输出的等级。（屏蔽和限制等级不进行输出）。
- 可以同时输出到终端与写入文件。
- 日志输出错误，可以进行`report_capsize`后续不再继续输出。

## ⛵使用

在你的脚本文件开头，加入`source ./SailAnchor.sh`

在关键的位置加入（debug/info/notice/error/warn)等函数提示信息。

例如：

```shell
#!/bin/bash

source ./SailAnchor.sh

notice Sailing
your_command
ret=$?
if [ ret = 0 ];then
  info Command downwind, succeeded.

else
  error Command capsize, failed!
fi
```

![shadow-zoom](https://image-taragrade.oss-cn-hangzhou.aliyuncs.com/imagehub/image-20220111161716073.png)

## ⚓配置

### ⚓level

|  LEVEL  | Value |        Functions         |
| :-----: | :---: | :----------------------: |
|  DEBUG  |   0   |         `debug`          |
|  INFO   |   1   |  `info`, `information`   |
| NOTICE  |   2   | `notice`, `notification` |
| WARNING |   3   |    `warn`, `warning`     |
|  ERROR  |   4   |    `error`, `iceberg`    |



### ⚓全局变量

|      Variable Name       |            Description             |                   Default                   |
| :----------------------: | :--------------------------------: | :-----------------------------------------: |
|    SAILOR_DATE_FORMAT    |             日期格式化             |             '%Y/%m/%d %H:%M:%S'             |
|       SAILOR_LEVEL       |  小于SAILOR_LEVEL该值的信息不显示  |                      1                      |
|  SAILOR_STD_ERROR_LEVEL  |     大于SAILOR_LEVEL的不再显示     |                      4                      |
|    SAILOR_DEBUG_COLOR    |           DEBUG信息颜色            |          3 （斜体，不同终端不同）           |
|    SAILOR_INFO_COLOR     |            INFO信息颜色            |               "" （默认颜色）               |
|   SAILOR_NOTICE_COLOR    |           NOTICE信息颜色           |                  36 (cyan)                  |
|   SAILOR_WARNING_COLOR   |          WARNING信息颜色           |                 33 (yellow)                 |
|    SAILOR_ERROR_COLOR    |           ERROR信息颜色            |                  31 (red)                   |
|       SAILOR_COLOR       |         never/auto/always          |                    auto                     |
|      SAILOR_LEVELS       |            5个等级名称             | ("DEBUG" "INFO" "NOTICE" "WARNING" "ERROR") |
|     SAILOR_SHOW_TIME     |            是否显示时间            |                      1                      |
|     SAILOR_SHOW_FILE     |           是否显示问位置           |                      1                      |
|    SAILOR_SHOW_LEVEL     |            是否显示等级            |                      1                      |
|     SAILOR_SHOW_PID      |            是否显示PID             |               0（默认不显示）               |
| SAILOR_ERROR_RETURN_CODE |      `iceberg`/`error`返回码       |                     100                     |
|    SAILOR_ERROR_TRACE    | 是否显示错误信息 `iceberg`/`error` |                      1                      |
|    GLOBAL_FAIL_ANCHOR    |         全局执行结果标志位         |                ./iceberg.anc                |
|        SHELL_NAME        |           shell脚本名称            |                SailAnchor.sh                |
|       ANCHOR_FILE        |              日志名称              |                 achors.log                  |

### ⚓颜色

关于颜色，可以参考标准定义[Standard ECMA-48](http://www.ecma-international.org/publications/standards/Ecma-048.htm) (p61, p62).

Normal are:

| Number |  Color definition  |
| :----: | :----------------: |
|   30   |   black display    |
|   31   |    red display     |
|   32   |   green display    |
|   33   |   yellow display   |
|   34   |    blue display    |
|   35   |  magenta display   |
|   36   |    cyan display    |
|   37   |   white display    |
|   40   |  black background  |
|   41   |   red background   |
|   42   |  green background  |
|   43   | yellow background  |
|   44   |  blue background   |
|   45   | magenta background |
|   46   |  cyan background   |
|   47   |  white background  |

可以同时设置显示（字母颜色）和背景。例如，如果使用红色背景和白色正面颜色进行错误输出，请设置：

```shell
SAILOR_ERROR_COLOR="37;41"
```

## ⚓架构

![strcut](https://image-taragrade.oss-cn-hangzhou.aliyuncs.com/imagehub/strcut.jpg)



|    Function Name    |              Description              |
| :-----------------: | :-----------------------------------: |
|    _sailor_time     |               定位时间                |
|    _sailor_site     |               定位位置                |
|    _sailor_level    |               定位等级                |
|     _get_level      |               获取等级                |
|    _weigh_anchor    |             清除iceberg锚             |
|        horn         |               标识信息                |
|        diary        |         输出到文本，不到终端          |
|     clear_diary     |               清除日志                |
|        call         |          输出到文本以及终端           |
|        blow         |        吹起号角：结合horn使用         |
|       _sailor       |         丢下锚：定位日志问题          |
|        debug        |             输出DEBUG信息             |
|        info         |             输出INFO信息              |
| notice,notification |            输出NOTICE信息             |
|    warn,warning     |            输出WARNING信息            |
|    error,iceberg    | 输出ERROR信息，默认带Trace Back Stack |
|       welcome       |          使用脚本的欢迎信息           |
|        step         |         [report]输出步骤信息          |
|     before_sail     |        [report]脚本执行前信息         |
|     after_sail      |        [report]脚本执行后信息         |
|   report_capsize    |         [report]报告错误信息          |
|   report_arrival    |         [report]报告成功信息          |

## ⚓注意

- 保证SHELL_NAME与实际脚本的名称一致。
- 脚本尽量不要给予`+x`权限,通过`source`方式去加载。
- 尽量使用`debug`,`info`,`notice`,`warn`,`error`等具有信息标签的日志输出函数。日志格式统一。
- 而`step`,`before_sail`,`after_sail`,`report_capsize`,`report_arrival`等报告信息函数可以在关键信息报告或者测试中使用！会破坏一定日志格式。
- 使用`report_capsize`会屏蔽后续错误日志的输出！
- 实际运行中可能存在一些问题，后续有待调整!

