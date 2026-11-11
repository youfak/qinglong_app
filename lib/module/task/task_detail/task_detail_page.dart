import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:qinglong_app/base/cupertino_sheet.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/module/task/add_task_page.dart';
import 'package:qinglong_app/module/task/intime_log/intime_log_page.dart';
import 'package:qinglong_app/module/task/task_bean.dart';
import 'package:qinglong_app/utils/utils.dart';
import 'package:timezone/standalone.dart';

import '../../../base/cron_parse.dart';

class TaskDetailPage extends ConsumerStatefulWidget {
  final TaskBean taskBean;
  final bool hideAppbar;

  const TaskDetailPage(this.taskBean, {Key? key, this.hideAppbar = false}) : super(key: key);

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> with LazyLoadState<TaskDetailPage> {
  bool isPin = false;
  bool isLoading = true;

  var nextRunTime = "".obs;

  void getNextRunTime(String time) {
    if (time.isEmpty) return;
    try {
      String cronTime;
      List<dynamic> timeList = time.split(" ");
      Duration duration;
      if (timeList.length > 5) {
        var first = timeList.first;
        var second = parseConstraint(first)?.first ?? 0;
        duration = Duration(seconds: second);

        cronTime = timeList.sublist(1, timeList.length).join(" ");
      } else {
        cronTime = time;
        duration = const Duration(seconds: 0);
      }

      var cronIterator = Cron().parse(cronTime, "Asia/Shanghai");
      TZDateTime nextDate = cronIterator.next();
      var result = nextDate.add(duration);
      var resultStr = Utils.formatMessageTime(result.millisecondsSinceEpoch);
      nextRunTime.value = resultStr;
    } catch (e) {
      nextRunTime.value = "- -";
    }
  }

  @override
  void initState() {
    isPin = widget.taskBean.isPinned == 1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (isLoading) {
      body = const Center(
        child: LoadingWidget(),
      );
    } else {
      bool isDark = ref.watch(themeProvider).themeMode == modeDark;
      Color primaryColor = ref.watch(themeProvider).primaryColor;
      Color titleColor = ref.watch(themeProvider).themeColor.titleColor();
      Color descColor = ref.watch(themeProvider).themeColor.descColor();
      Color cardBg = ref.watch(themeProvider).themeColor.settingBgColor();

      body = Material(
        color: Colors.transparent,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            primary: true,
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                // 1. Hero Card: Status, Name & Command
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPin
                          ? const Color(0xffEAB308).withOpacity(0.6)
                          : (isDark ? const Color(0xff27272A) : const Color(0xffE2E8F0)),
                      width: isPin ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          widget.taskBean.status == 0
                              ? const RunningWidget()
                              : const SizedBox.shrink(),
                          if (widget.taskBean.status == 0)
                            const SizedBox(width: 8),
                          StatusWidget(
                            title: widget.taskBean.isDisabled == 1 ? "已禁用" : "已启用",
                            color: widget.taskBean.isDisabled == 1
                                ? const Color(0xffEF4444)
                                : primaryColor,
                          ),
                          if (isPin) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xffEAB308).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.push_pin, size: 12, color: Color(0xffEAB308)),
                                  SizedBox(width: 3),
                                  Text(
                                    "已置顶",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xffEAB308),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xff18181B) : const Color(0xffF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "#${widget.taskBean.sId ?? ''}",
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: descColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.taskBean.name ?? "",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff121217) : const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xff22222A) : const Color(0xffE2E8F0),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.terminal, size: 14, color: descColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableText(
                                widget.taskBean.command ?? "",
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: isDark ? const Color(0xff94A3B8) : const Color(0xff334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Schedule & Execution Group
                _buildGroupCard(
                  context,
                  ref,
                  groupTitle: "调度与运行",
                  groupIcon: CupertinoIcons.clock,
                  children: [
                    TaskDetailCell(
                      title: "定时规则",
                      desc: widget.taskBean.schedule ?? "-",
                    ),
                    Obx(() {
                      return TaskDetailCell(
                        title: "下次运行",
                        desc: nextRunTime.value,
                      );
                    }),
                    TaskDetailCell(
                      title: "最后运行时间",
                      desc: Utils.formatMessageTime(widget.taskBean.lastExecutionTime ?? 0),
                    ),
                    TaskDetailCell(
                      title: "最后运行时长",
                      desc: widget.taskBean.lastRunningTime == null
                          ? "-"
                          : "${widget.taskBean.lastRunningTime} 秒",
                    ),
                    TaskDetailCell(
                      title: "创建时间",
                      desc: widget.taskBean.created == null
                          ? Utils.formatTime2(widget.taskBean.createdAt)
                          : Utils.formatMessageTime(widget.taskBean.created ?? 0),
                    ),
                    TaskDetailCell(
                      title: "更新时间",
                      hideDivide: true,
                      desc: widget.taskBean.updatedAt == null
                          ? Utils.formatGMTTime(widget.taskBean.timestamp ?? "")
                          : Utils.formatTime2(widget.taskBean.updatedAt),
                    ),
                  ],
                ),

                // 3. Resources & Logs Group
                _buildGroupCard(
                  context,
                  ref,
                  groupTitle: "资源与日志",
                  groupIcon: CupertinoIcons.doc_text,
                  children: [
                    TaskDetailCell(
                      title: "最新日志",
                      desc: widget.taskBean.logPath ?? "点击查看实时运行日志",
                      suffixIcon: Icon(
                        CupertinoIcons.chevron_right,
                        size: 15,
                        color: descColor,
                      ),
                      taped: () {
                        showLog();
                      },
                    ),
                    if (widget.taskBean.command != null &&
                        widget.taskBean.command!.isNotEmpty &&
                        widget.taskBean.command!.startsWith("task ")) ...[
                      TaskDetailCell(
                        title: "关联脚本",
                        suffixIcon: Icon(
                          CupertinoIcons.chevron_right,
                          size: 15,
                          color: descColor,
                        ),
                        desc: widget.taskBean.command?.replaceFirst(RegExp(r'^task\s+'), '').trim() ?? "-",
                        taped: () {
                          var info = ScriptPathInfo.parse(widget.taskBean.command);
                          if (info.title.isNotEmpty) {
                            Navigator.of(context).pushNamed(Routes.routeScriptDetail, arguments: {
                              "title": info.title,
                              "path": info.path,
                            });
                          }
                        },
                      ),
                      TaskDetailCell(
                        title: "历史日志",
                        hideDivide: true,
                        suffixIcon: Icon(
                          CupertinoIcons.chevron_right,
                          size: 15,
                          color: descColor,
                        ),
                        desc: "查看该脚本的全部历史记录",
                        taped: () {
                          Navigator.of(context).pushNamed(
                            Routes.routeTaskLog,
                            arguments: {
                              "search": widget.taskBean.command
                                      ?.replaceAll("task ", "")
                                      .replaceAll("/", "_")
                                      .split(".")[0] ??
                                  ""
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),

                // 4. Quick Settings Card (Pin & State)
                _buildGroupCard(
                  context,
                  ref,
                  groupTitle: "任务偏好",
                  groupIcon: CupertinoIcons.slider_horizontal_3,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "置顶任务",
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "置顶后在任务列表中优先展示",
                                style: TextStyle(
                                  color: descColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          CupertinoSwitch(
                            activeColor: primaryColor,
                            value: isPin,
                            onChanged: (v) {
                              pinTask(v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 5. Bottom Action Controls
                if (!widget.hideAppbar) ...[
                  const SizedBox(height: 14),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        // Run / Stop button
                        Expanded(
                          flex: 3,
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: widget.taskBean.status == 1
                                ? primaryColor
                                : const Color(0xffF59E0B),
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () async {
                              if (widget.taskBean.status == 1) {
                                await startCron(context, ref);
                              } else {
                                await stopCron(context, ref);
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.taskBean.status == 1
                                      ? CupertinoIcons.play_arrow_solid
                                      : CupertinoIcons.stop_fill,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.taskBean.status == 1 ? "运行任务" : "停止运行",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Edit button
                        Expanded(
                          flex: 2,
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: isDark ? const Color(0xff27272A) : const Color(0xffE2E8F0),
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) => AddTaskPage(
                                    taskBean: widget.taskBean,
                                    hideUploadFile: true,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              "编辑",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Delete button
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          color: const Color(0xffEF4444).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () {
                            delTask(context, ref);
                          },
                          child: const Icon(
                            CupertinoIcons.trash,
                            size: 18,
                            color: Color(0xffEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: QlAppBar(
        canBack: true,
        backCall: () {
          Navigator.of(context).pop();
        },
        title: widget.taskBean.name ?? "",
        actions: [
          CupertinoButton(
            color: Colors.transparent,
            padding: EdgeInsets.zero,
            onPressed: () {
              showMoreOperate(
                context,
                [
                  CupertinoSheer(
                    title: widget.taskBean.status! == 1 ? "运行" : "停止运行",
                    onTap: () async {
                      if (widget.taskBean.status! == 1) {
                        await startCron(context, ref);
                      } else {
                        await stopCron(context, ref);
                      }
                    },
                  ),
                  addDivider(),
                  CupertinoSheer(
                    title: "编辑",
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => AddTaskPage(
                            taskBean: widget.taskBean,
                            hideUploadFile: true,
                          ),
                        ),
                      );
                    },
                  ),
                  addDivider(),
                  CupertinoSheer(
                    title: widget.taskBean.isDisabled! == 0 ? "禁用" : "启用",
                    onTap: () {
                      enableTask();
                    },
                  ),
                ],
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: Center(
                child: Icon(
                  Icons.more_horiz,
                  size: 26,
                  color: Theme.of(context).appBarTheme.iconTheme?.color,
                ),
              ),
            ),
          )
        ],
      ),
      body: body,
    );
  }

  startCron(BuildContext context, WidgetRef ref) async {
    await ref.read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier).runCrons(context, [widget.taskBean.sId!]);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      showLog();
    });
  }

  stopCron(BuildContext context, WidgetRef ref) async {
    await ref.read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier).stopCrons(context, [widget.taskBean.sId!]);
    setState(() {});
  }

  void enableTask() async {
    await ref
        .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)))
        .enableTask(context, [widget.taskBean.sId!], widget.taskBean.isDisabled!);
    setState(() {});
  }

  void pinTask(bool v) async {
    await ref.read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier).pinTask(
          context,
          [widget.taskBean.sId!],
          //这里取反
          v ? 0 : 1,
        );
    isPin = !isPin;
    setState(() {});
  }

  void delTask(BuildContext context1, WidgetRef ref) {
    showCupertinoDialog(
      useRootNavigator: false,
      context: context1,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("确认删除"),
        content: Text("确认删除定时任务 ${widget.taskBean.name ?? ""} 吗"),
        actions: [
          CupertinoDialogAction(
            child: const Text(
              "取消",
              style: TextStyle(
                color: Color(0xff999999),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            child: Text(
              "确定",
              style: TextStyle(
                color: ref.watch(themeProvider).primaryColor,
              ),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(SingleAccountPageState.ofTaskProvider(context1)(getProviderName(context1))).delCron(context1, [widget.taskBean.sId!]);
              Navigator.of(context1).pop();
            },
          ),
        ],
      ),
    );
  }

  void showLog() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => InTimeLogPage(
          widget.taskBean.sId!,
          true,
          widget.taskBean.name ?? "",
          command: widget.taskBean.command,
        ),
      ),
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    WidgetRef ref, {
    required String groupTitle,
    required IconData groupIcon,
    required List<Widget> children,
  }) {
    bool isDark = ref.watch(themeProvider).themeMode == modeDark;
    Color primaryColor = ref.watch(themeProvider).primaryColor;
    Color cardBg = ref.watch(themeProvider).themeColor.settingBgColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xff27272A) : const Color(0xffE2E8F0),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 4),
            child: Row(
              children: [
                Icon(groupIcon, size: 15, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  groupTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  @override
  void onLazyLoad() {
    isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      getNextRunTime(widget.taskBean.schedule ?? "");
    });
    setState(() {});
  }
}

class TaskDetailCell extends ConsumerWidget {
  final String title;
  final String? desc;
  final Widget? icon;
  final Widget? suffixIcon;
  final bool hideDivide;
  final Function? taped;

  const TaskDetailCell({
    Key? key,
    required this.title,
    this.desc,
    this.icon,
    this.suffixIcon,
    this.hideDivide = false,
    this.taped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isDark = ref.watch(themeProvider).themeMode == modeDark;
    Color titleColor = ref.watch(themeProvider).themeColor.titleColor();
    Color descColor = ref.watch(themeProvider).themeColor.descColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: taped != null
                ? () {
                    taped!();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: descColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  desc != null
                      ? Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: SelectableText(
                              desc!,
                              selectionHeightStyle: BoxHeightStyle.max,
                              selectionWidthStyle: BoxWidthStyle.max,
                              onTap: () {
                                if (taped != null) {
                                  taped!();
                                }
                              },
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      : Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: icon ?? const SizedBox.shrink(),
                          ),
                        ),
                  if (suffixIcon != null) ...[
                    const SizedBox(
                      width: 8,
                    ),
                    suffixIcon!,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (!hideDivide)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            thickness: 0.5,
            color: isDark ? const Color(0xff27272A) : const Color(0xffF1F5F9),
          ),
      ],
    );
  }
}
