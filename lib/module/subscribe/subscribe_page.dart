import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:qinglong_app/base/base_state_widget.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/empty_widget.dart';
import 'package:qinglong_app/base/ui/enable_widget.dart';
import 'package:qinglong_app/base/ui/running_widget.dart';
import 'package:qinglong_app/base/ui/search_cell.dart';
import 'package:qinglong_app/module/subscribe/add_subscribe_page.dart';
import 'package:qinglong_app/module/task/intime_log/intime_subscribe_log_page.dart';
import 'package:qinglong_app/utils/utils.dart';

import 'subscribe_viewmodel.dart';

class SubscribePage extends ConsumerStatefulWidget {
  const SubscribePage({Key? key}) : super(key: key);

  @override
  _SubscribePageState createState() => _SubscribePageState();
}

class _SubscribePageState extends ConsumerState<SubscribePage> {
  final TextEditingController searchText = TextEditingController();
  final ScrollController controller = ScrollController();
  bool buttonshow = false;

  void scrollToTop() {
    controller.animateTo(0,
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(floatingButtonVisibility);
    searchText.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.removeListener(floatingButtonVisibility);
    controller.dispose();
    searchText.dispose();
    super.dispose();
  }

  void floatingButtonVisibility() {
    double y = controller.offset;
    if (y > MediaQuery.of(context).size.height / 2) {
      if (buttonshow == true) return;
      setState(() {
        buttonshow = true;
      });
    } else {
      if (buttonshow == false) return;
      setState(() {
        buttonshow = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.themeColor.bg2Color(),
      floatingActionButton: Visibility(
        visible: buttonshow,
        child: FloatingActionButton.small(
          onPressed: scrollToTop,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 3,
          child: const Icon(CupertinoIcons.up_arrow),
        ),
      ),
      appBar: QlAppBar(
        title: "订阅管理",
        actions: [
          IconButton(
            tooltip: "新建订阅",
            icon: Icon(
              CupertinoIcons.plus_circle_fill,
              size: 24,
              color: primaryColor,
            ),
            onPressed: () {
              Navigator.of(context)
                  .push(
                CupertinoPageRoute(
                  builder: (context) => const AddSubscribePage(taskBean: {}),
                ),
              )
                  .then((value) {
                if (value == true) {
                  ref
                      .read(SingleAccountPageState.ofSubscribeProvider(context)(
                          getProviderName(context)))
                      .loadData(context);
                }
              });
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: BaseStateWidget<SubscribeViewModel>(
        builder: (ref, model, child) {
          return body(model, getListByType(model), ref);
        },
        model: SingleAccountPageState.ofSubscribeProvider(context)(
            getProviderName(context)),
        lazyLoad: true,
        onReady: (viewModel) {
          viewModel.loadData(context);
        },
      ),
    );
  }

  Widget body(SubscribeViewModel model, List<Map<String, dynamic>> list,
      WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final primaryColor = theme.primaryColor;
    final query = searchText.text.trim().toLowerCase();

    final filteredList = list.where((item) {
      if (query.isEmpty) return true;
      final name = item["name"]?.toString().toLowerCase() ?? "";
      final url = item["url"]?.toString().toLowerCase() ?? "";
      final alias = item["alias"]?.toString().toLowerCase() ?? "";
      return name.contains(query) ||
          url.contains(query) ||
          alias.contains(query);
    }).toList();

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () async {
        return model.loadData(context, false);
      },
      child: SlidableAutoCloseBehavior(
        child: CustomScrollView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // 搜索栏
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SearchCell(controller: searchText),
              ),
            ),

            // 统计标题栏
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      "订阅任务列表",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.themeColor.descColor(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${filteredList.length} 个订阅",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (filteredList.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyWidget(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SubscribeItemCard(
                          bean: item,
                          ref: ref,
                          onRefresh: () {
                            ref
                                .read(SingleAccountPageState.ofSubscribeProvider(
                                    context)(getProviderName(context)))
                                .loadData(context);
                          },
                        ),
                      );
                    },
                    childCount: filteredList.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> getListByType(SubscribeViewModel model) {
    return model.list;
  }
}

class SubscribeItemCard extends StatelessWidget {
  final Map<String, dynamic> bean;
  final WidgetRef ref;
  final VoidCallback onRefresh;

  const SubscribeItemCard({
    Key? key,
    required this.bean,
    required this.ref,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final isDark = theme.isDark();
    final primaryColor = theme.primaryColor;
    final cardBg = theme.themeColor.settingBgColor();
    final titleColor = theme.themeColor.titleColor();
    final descColor = theme.themeColor.descColor();
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    final isRunning = bean["status"] == 0;
    final isDisabled = (bean["is_disabled"] ?? 0) == 1;
    final name = bean["name"]?.toString() ?? "未命名订阅";
    final schedule = bean["schedule"]?.toString() ?? "";
    final url = bean["url"]?.toString() ?? "";

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRunning ? primaryColor.withOpacity(0.5) : borderColor,
          width: isRunning ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isRunning
                ? primaryColor.withOpacity(0.06)
                : Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Slidable(
          key: ValueKey(bean["id"]),
          startActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.45,
            children: [
              SlidableAction(
                backgroundColor: isRunning
                    ? const Color(0xffEF4444)
                    : primaryColor,
                foregroundColor: Colors.white,
                icon: isRunning
                    ? CupertinoIcons.stop_fill
                    : CupertinoIcons.play_fill,
                label: isRunning ? "停止" : "执行",
                onPressed: (_) {
                  if (isRunning) {
                    _stopCron(context, ref);
                  } else {
                    _startCron(context, ref, true);
                  }
                },
              ),
              SlidableAction(
                backgroundColor: const Color(0xff3B82F6),
                foregroundColor: Colors.white,
                icon: CupertinoIcons.doc_text,
                label: "日志",
                onPressed: (_) => logCron(context, ref),
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.65,
            children: [
              SlidableAction(
                backgroundColor: const Color(0xff8B5CF6),
                foregroundColor: Colors.white,
                icon: CupertinoIcons.pencil,
                label: "编辑",
                onPressed: (_) {
                  Navigator.of(context)
                      .push(
                    CupertinoPageRoute(
                      builder: (context) => AddSubscribePage(taskBean: bean),
                    ),
                  )
                      .then((val) {
                    if (val == true) onRefresh();
                  });
                },
              ),
              SlidableAction(
                backgroundColor: isDisabled
                    ? primaryColor
                    : const Color(0xffF59E0B),
                foregroundColor: Colors.white,
                icon: isDisabled
                    ? Icons.check_circle_outline
                    : Icons.block,
                label: isDisabled ? "启用" : "禁用",
                onPressed: (_) => _enableSubscribe(
                    context, bean["is_disabled"] ?? 0),
              ),
              SlidableAction(
                backgroundColor: const Color(0xffEF4444),
                foregroundColor: Colors.white,
                icon: CupertinoIcons.delete,
                label: "删除",
                onPressed: (_) => _delSubscribe(context, ref),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(
                  Routes.routeSubscribeDetail,
                  arguments: bean,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头部：图标 + 订阅名称 + 运行/状态药丸
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xff3B82F6).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_2_circlepath_circle_fill,
                            color: Color(0xff3B82F6),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isRunning) const RunningWidget(),
                        if (isDisabled)
                          const StatusWidget(
                            title: "已禁用",
                            color: Color(0xffEF4444),
                          )
                        else if (!isRunning)
                          StatusWidget(
                            title: "待机中",
                            color: primaryColor,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 调度 Cron 表达式
                    if (schedule.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.clock,
                            size: 13,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              schedule,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // 仓库 URL 代码微容器
                    if (url.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          url,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: descColor,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 10),

                    // 底部快捷操作胶囊条
                    Divider(height: 1, color: borderColor),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(CupertinoIcons.doc_text, size: 14),
                          label: const Text("日志",
                              style: TextStyle(fontSize: 12)),
                          onPressed: () => logCron(context, ref),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRunning
                                ? const Color(0xffEF4444)
                                : primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(
                            isRunning
                                ? CupertinoIcons.stop_fill
                                : CupertinoIcons.play_arrow_solid,
                            size: 13,
                          ),
                          label: Text(
                            isRunning ? "停止同步" : "立即拉取",
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            if (isRunning) {
                              _stopCron(context, ref);
                            } else {
                              _startCron(context, ref, true);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startCron(BuildContext context, WidgetRef ref, bool showLog) async {
    await ref
        .read(SingleAccountPageState.ofSubscribeProvider(context)(
            getProviderName(context)))
        .runCrons(context, bean["id"]);
    if (showLog) {
      Future.delayed(const Duration(milliseconds: 250), () {
        logCron(context, ref);
      });
    }
  }

  void _stopCron(BuildContext context, WidgetRef ref) {
    ref
        .read(SingleAccountPageState.ofSubscribeProvider(context)(
            getProviderName(context)))
        .stopCrons(context, bean["id"]);
  }

  void logCron(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => InTimeSubscribeLogPage(
          bean["id"],
          false,
          bean["name"] ?? "",
        ),
      ),
    );
  }

  void _enableSubscribe(BuildContext context, int status) {
    ref
        .read(SingleAccountPageState.ofSubscribeProvider(context)(
            getProviderName(context)))
        .enableSubscribe(context, bean["id"], status == 1 ? 0 : 1);
  }

  void _delSubscribe(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      useRootNavigator: false,
      builder: (childContext) => CupertinoAlertDialog(
        title: const Text("确认删除订阅"),
        content: Text("确认删除订阅任务「${bean["name"] ?? ""}」吗？"),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(childContext).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("删除"),
            onPressed: () {
              Navigator.of(childContext).pop();
              ref
                  .read(SingleAccountPageState.ofSubscribeProvider(context)(
                      getProviderName(context)))
                  .delSubscribe(context, bean["id"]);
            },
          ),
        ],
      ),
    );
  }
}
