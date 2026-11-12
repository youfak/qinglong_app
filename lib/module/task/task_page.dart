import 'dart:async';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:qinglong_app/base/base_state_widget.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/base/ui/search_cell.dart';
import 'package:qinglong_app/module/task/add_task_page.dart';
import 'package:qinglong_app/module/task/intime_log/intime_log_page.dart';
import 'package:qinglong_app/module/task/task_bean.dart';
import 'package:qinglong_app/module/task/task_viewmodel.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/sp_utils.dart';
import 'package:qinglong_app/utils/utils.dart';

import '../../base/ui/enable_widget.dart';
import '../../base/ui/notify.dart';
import '../../base/ui/running_widget.dart';
import '../../main.dart';

class TaskPage extends ConsumerStatefulWidget {
  final bool loading;
  final bool onlyShowPullRepo;

  const TaskPage({
    Key? key,
    this.loading = false,
    this.onlyShowPullRepo = false,
  }) : super(key: key);

  @override
  TaskPageState createState() => TaskPageState();
}

class TaskPageState extends ConsumerState<TaskPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  TextEditingController searchText = TextEditingController();

  TabController? _tabController;
  final ScrollController _scrollController = ScrollController();

  bool editMode = false;
  Set<String> checkedIds = <String>{};

  GlobalKey<RefreshIndicatorState> refreshKey = GlobalKey();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      ref
          .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
          .loadData(context);
      if (MultiAccountPageState.actionRunAll == MultiAccountPageState.useAction()) {
        ref
            .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
            .runAllTasked = false;
        ref
            .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
            .runAllTasks(context);
      }
    } else if (state == AppLifecycleState.inactive) {}
  }

  Future<void> scrollToTop() async {
    await _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }

  Future<void> move2Top() async {
    if (_scrollController.offset != _scrollController.position.minScrollExtent) {
      await scrollToTop();
    } else {
      if (refreshKey.currentState?.mounted ?? false) {
        await refreshKey.currentState?.show();
      }
    }
  }

  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this);
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    searchText.addListener(() {
      setState(() {});
    });
  }

  double searchCellHeight = 55;

  SliverAppBar _buildAppBar(WidgetRef ref, TaskViewModel model) {
    return SliverAppBar(
      pinned: false,
      floating: false,
      elevation: 0,
      automaticallyImplyLeading: false,
      snap: false,
      primary: false,
      toolbarHeight: searchCellHeight,
      flexibleSpace: searchCell(ref, model),
    );
  }

  List<TaskBean> getListByType(int index) {
    var model =
        ref.read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier);
    if (index == 0) {
      return model.list;
    } else if (index == 1) {
      return model.running;
    } else if (index == 2) {
      return model.neverRunning;
    } else if (index == 3) {
      return model.disabled;
    }
    return model.list;
  }

  List<String> lastRunningTaskIds = [];
  List<String> runningTaskIds = [];

  @override
  Widget build(BuildContext context) {
    if (widget.onlyShowPullRepo) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (_) {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Scaffold(
          appBar: QlAppBar(
            title: "拉库管理",
            canClick2Vip: !editMode,
            actions: [
              CupertinoButton(
                color: Colors.transparent,
                padding: EdgeInsets.zero,
                onPressed: () {

                  Navigator.of(context)
                      .push(
                    CupertinoPageRoute(
                      builder: (context) => const AddTaskPage(
                        hideUploadFile: false,
                      ),
                    ),
                  )
                      .then(
                        (value) {
                      ref
                          .read(
                          SingleAccountPageState.ofTaskProvider(context)(getProviderName(context))
                              .notifier)
                          .loadData(context, false);
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                  ),
                  child: Center(
                    child: editMode
                        ? Text(
                      checkedIds.length ==
                          getListByType(_tabController?.index ?? 0).where((item) {
                            if (searchText.text.isEmpty ||
                                (item.name
                                    ?.toLowerCase()
                                    .contains(searchText.text.toLowerCase()) ??
                                    false) ||
                                (item.command
                                    ?.toLowerCase()
                                    .contains(searchText.text.toLowerCase()) ??
                                    false) ||
                                (item.schedule?.contains(searchText.text.toLowerCase()) ??
                                    false)) {
                              return true;
                            }
                            return false;
                          }).length
                          ? "全不选"
                          : "全选",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).appBarTheme.iconTheme?.color,
                      ),
                    )
                        : Icon(
                      CupertinoIcons.add,
                      size: 24,
                      color: Theme.of(context).appBarTheme.iconTheme?.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: BaseStateWidget<TaskViewModel>(
            builder: (ref, model, child) {
              return IconTheme(
                data: const IconThemeData(
                  size: 25,
                ),
                child: NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      _buildAppBar(ref, model),
                    ];
                  },
                  body: RefreshIndicator(
                    key: refreshKey,
                    color: Theme.of(context).primaryColor,
                    notificationPredicate: (_) => true,
                    onRefresh: () async {
                      return await model.loadData(context, false);
                    },
                    child: SlidableAutoCloseBehavior(
                      child: body(
                        model,
                        model.notScripts,
                        ref,
                        true,
                      ),
                    ),
                  ),
                ),
              );
            },
            model: SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)),
            onReady: (viewModel) {
              viewModel.loadData(context);
            },
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (_) {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        appBar: QlAppBar(
          title: (editMode && checkedIds.isNotEmpty) ? "当前选中 ${checkedIds.length} 个任务" : "定时任务",
          canClick2Vip: !editMode,
          backWidget: Builder(
            builder: (context) {
              return CupertinoButton(
                color: Colors.transparent,
                padding: EdgeInsets.zero,
                onPressed: () {
                  checkedIds.clear();
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    if (editMode) {
                      showOverlay(context);
                    } else {
                      removeOverlay();
                    }
                  });
                  editMode = !editMode;
                  // if (editMode) {
                  //   searchText.text = "";
                  // }
                  setState(() {});
                },
                child: Center(
                  child: Text(
                    editMode == true ? "完成" : "编辑",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).appBarTheme.iconTheme?.color,
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            CupertinoButton(
              color: Colors.transparent,
              padding: EdgeInsets.zero,
              onPressed: () {
                if (editMode) {
                  if (checkedIds.length ==
                      getListByType(_tabController?.index ?? 0).where((item) {
                        if (searchText.text.isEmpty ||
                            (item.name?.toLowerCase().contains(searchText.text.toLowerCase()) ??
                                false) ||
                            (item.command?.toLowerCase().contains(searchText.text.toLowerCase()) ??
                                false) ||
                            (item.schedule?.contains(searchText.text.toLowerCase()) ?? false)) {
                          return true;
                        }
                        return false;
                      }).length) {
                    //全不选
                    checkedIds.clear();
                    setState(() {});
                  } else {
                    //全选
                    checkedIds.clear();
                    checkedIds.addAll(getListByType(_tabController?.index ?? 0)
                        .where((item) {
                          if (searchText.text.isEmpty ||
                              (item.name?.toLowerCase().contains(searchText.text.toLowerCase()) ??
                                  false) ||
                              (item.command
                                      ?.toLowerCase()
                                      .contains(searchText.text.toLowerCase()) ??
                                  false) ||
                              (item.schedule?.contains(searchText.text.toLowerCase()) ?? false)) {
                            return true;
                          }
                          return false;
                        })
                        .map((e) => e.sId ?? "")
                        .toList());
                    setState(() {});
                  }
                  return;
                }

                Navigator.of(context)
                    .push(
                  CupertinoPageRoute(
                    builder: (context) => const AddTaskPage(
                      hideUploadFile: false,
                    ),
                  ),
                )
                    .then(
                  (value) {
                    ref
                        .read(
                            SingleAccountPageState.ofTaskProvider(context)(getProviderName(context))
                                .notifier)
                        .loadData(context, false);
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                child: Center(
                  child: editMode
                      ? Text(
                          checkedIds.length ==
                                  getListByType(_tabController?.index ?? 0).where((item) {
                                    if (searchText.text.isEmpty ||
                                        (item.name
                                                ?.toLowerCase()
                                                .contains(searchText.text.toLowerCase()) ??
                                            false) ||
                                        (item.command
                                                ?.toLowerCase()
                                                .contains(searchText.text.toLowerCase()) ??
                                            false) ||
                                        (item.schedule?.contains(searchText.text.toLowerCase()) ??
                                            false)) {
                                      return true;
                                    }
                                    return false;
                                  }).length
                              ? "全不选"
                              : "全选",
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).appBarTheme.iconTheme?.color,
                          ),
                        )
                      : Icon(
                          CupertinoIcons.add,
                          size: 24,
                          color: Theme.of(context).appBarTheme.iconTheme?.color,
                        ),
                ),
              ),
            ),
          ],
        ),
        body: widget.loading
            ? const Center(child: LoadingWidget())
            : BaseStateWidget<TaskViewModel>(
                builder: (ref, model, child) {
                  return IconTheme(
                    data: const IconThemeData(
                      size: 25,
                    ),
                    child: NestedScrollView(
                      controller: _scrollController,
                      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                        return [
                          _buildAppBar(ref, model),
                          SliverOverlapAbsorber(
                            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                            sliver: SliverPersistentHeader(
                              pinned: true,
                              floating: false,
                              delegate: SliverTabBarDelegate(
                                _tabController!,
                                ref,
                                editMode,
                              ),
                            ),
                          ),
                        ];
                      },
                      body: RefreshIndicator(
                        key: refreshKey,
                        edgeOffset: 15,
                        color: Theme.of(context).primaryColor,
                        notificationPredicate: (_) => true,
                        onRefresh: () async {
                          return await model.loadData(context, false);
                        },
                        child: SlidableAutoCloseBehavior(
                          child: TabBarView(
                            controller: _tabController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              body(
                                model,
                                model.list,
                                ref,
                                true,
                              ),
                              body(
                                model,
                                model.running,
                                ref,
                                false,
                              ),
                              body(
                                model,
                                model.neverRunning,
                                ref,
                                false,
                              ),
                              body(
                                model,
                                model.disabled,
                                ref,
                                false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                model: SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)),
                onReady: (viewModel) {
                  viewModel.loadData(context);
                },
              ),
      ),
    );
  }

  Widget body(TaskViewModel model, List<TaskBean> list, WidgetRef ref, bool needController) {
    return LayoutBuilder(builder: (context, c) {
      return SizedBox(
        height: c.maxHeight,
        child: ListBodyWidget(
          model: model,
          list: list,
          searchText: searchText.text,
          editMode: editMode,
          checked: checkedIds,
          onlyShowPullRepo: widget.onlyShowPullRepo,
          changed: (id) {
            if (checkedIds.contains(id)) {
              checkedIds.remove(id);
            } else {
              checkedIds.add(id);
            }
            setState(() {});
          },
        ),
      );
    });
  }

  Widget searchCell(WidgetRef context, TaskViewModel model) {
    return Container(
      color: ref.watch(themeProvider).themeColor.searchBgColor(),
      padding: const EdgeInsets.only(
        left: 15,
        right: 15,
        top: 10,
        bottom: 10,
      ),
      height: searchCellHeight.toDouble(),
      child: SearchCell(
        controller: searchText,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    removeOverlay();
    super.dispose();
  }

  OverlayEntry? _editModeOverlay;

  void showOverlay(BuildContext context) {
    removeOverlay();
    _editModeOverlay = OverlayEntry(
      builder: (BuildContext context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: ref
                .watch(themeProvider)
                .currentTheme
                .bottomNavigationBarTheme
                .backgroundColor
                ?.withOpacity(1),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: kBottomNavigationBarHeight,
                child: SingleChildScrollView(
                  primary: true,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 15,
                      ),
                      EditModeButton(
                        "运行",
                        icon: CupertinoIcons.memories,
                        onTap: () {
                          _executeCode(context, "运行");
                        },
                      ),
                      EditModeButton(
                        "停止",
                        icon: CupertinoIcons.stop_circle,
                        onTap: () {
                          _executeCode(context, "停止");
                        },
                      ),
                      EditModeButton(
                        "启用",
                        icon: Icons.check_circle_outline_sharp,
                        onTap: () {
                          _executeCode(context, "启用");
                        },
                      ),
                      EditModeButton(
                        "禁用",
                        icon: Icons.dnd_forwardslash,
                        onTap: () {
                          _executeCode(context, "禁用");
                        },
                      ),
                      EditModeButton(
                        "置顶",
                        icon: CupertinoIcons.pin,
                        onTap: () {
                          _executeCode(context, "置顶");
                        },
                      ),
                      EditModeButton(
                        "取消置顶",
                        icon: CupertinoIcons.pin_slash,
                        onTap: () {
                          _executeCode(context, "取消置顶");
                        },
                      ),
                      EditModeButton(
                        "删除",
                        icon: CupertinoIcons.delete,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _executeCode(context, "删除");
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context)?.insert(_editModeOverlay!);
  }

  void removeOverlay() {
    if (_editModeOverlay != null && _editModeOverlay!.mounted) {
      _editModeOverlay?.remove();
      _editModeOverlay = null;
    }
  }

  void _executeCode(BuildContext context, String s) {
    if (checkedIds.isEmpty) {
      "至少选择1个任务".toast();
      return;
    }

    showCupertinoDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => CupertinoAlertDialog(
        title: Text("确认$s"),
        content: Text("确认$s吗"),
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
            onPressed: () {
              Navigator.of(context).pop();
              editMode = false;
              removeOverlay();
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                if (s == "运行") {
                  runTasks();
                } else if (s == "停止") {
                  stopTasks();
                } else if (s == "置顶") {
                  pinTasks();
                } else if (s == "取消置顶") {
                  unPinTasks();
                } else if (s == "启用") {
                  enableTask();
                } else if (s == "禁用") {
                  disableTasks();
                } else if (s == "删除") {
                  deleteTasks();
                }
              });
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  void runTasks() {
    ref
        .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
        .runCrons(context, checkedIds.toList());
  }

  void deleteTasks() {
    ref
        .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
        .delCron(context, checkedIds.toList());
  }

  void disableTasks() {
    ref
        .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
        .enableTask(
          context,
          checkedIds.toList(),
          0,
        );
  }

  void enableTask() {
    ref
        .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
        .enableTask(
          context,
          checkedIds.toList(),
          1,
        );
  }

  void unPinTasks() {
    ref
        .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
        .pinTask(
          context,
          checkedIds.toList(),
          1,
        );
  }

  void pinTasks() {
    ref
        .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
        .pinTask(
          context,
          checkedIds.toList(),
          0,
        );
  }

  void stopTasks() {
    ref
        .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
        .stopCrons(context, checkedIds.toList());
  }

  Notify? notify;

  void show(BuildContext context, String title, String name, String cronId, String command) {
    notify = Notify();
    notify!.show(
      context,
      view(context, "\"$title\"已结束", name, cronId, command, "点击查看具体日志"),
      topOffset: MediaQuery.of(context).viewPadding.top + 10,
      keepDuration: 3000,
    );
  }

  Widget view(BuildContext context, String title, String name, String cronId, String command,
      String? desc) {
    return GestureDetector(
      onTap: () {
        if (notify != null && notify!.isShown()) {
          notify?.dismiss(true);
        }

        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => InTimeLogPage(
              cronId,
              false,
              name,
              command: command,
            ),
          ),
        );
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Container(
          padding: const EdgeInsets.only(
            left: 15,
            top: 5,
            bottom: 5,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: ref.watch(themeProvider).themeColor.blackAndWhite(),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                spreadRadius: 0,
                color: Color(0x4d000000),
                blurRadius: 15,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 7,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.asset(
                    "assets/images/ql.png",
                    height: 45,
                  ),
                ),
              ),
              const SizedBox(
                width: 15,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ref.watch(themeProvider).themeColor.titleColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Visibility(
                      visible: desc != null && desc.isNotEmpty,
                      child: Text(
                        desc ?? "",
                        style: TextStyle(
                          color: ref.watch(themeProvider).themeColor.descColor(),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListBodyWidget extends ConsumerStatefulWidget {
  final TaskViewModel model;
  final List<TaskBean> list;
  final String searchText;
  final bool editMode;
  final Set<String> checked;
  final ValueChanged<String> changed;
  final bool onlyShowPullRepo;

  const ListBodyWidget({
    Key? key,
    required this.model,
    required this.list,
    required this.searchText,
    required this.editMode,
    required this.checked,
    required this.changed,
    required this.onlyShowPullRepo,
  }) : super(key: key);

  @override
  ConsumerState<ListBodyWidget> createState() => _ListBodyState();
}

class _ListBodyState extends ConsumerState<ListBodyWidget> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final query = widget.searchText.trim().toLowerCase();
    final filteredList = widget.list.where((item) {
      if (query.isEmpty) return true;
      return (item.name?.toLowerCase().contains(query) ?? false) ||
          (item.command?.toLowerCase().contains(query) ?? false) ||
          (item.schedule?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(
            top: widget.onlyShowPullRepo ? 80 : kToolbarHeight + 60,
            bottom: 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.search,
                size: 44,
                color: Theme.of(context).disabledColor.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                query.isEmpty ? "暂无任务" : "未搜索到匹配任务",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(
        bottom: kBottomNavigationBarHeight + 50,
        top: widget.onlyShowPullRepo ? 0 : kToolbarHeight,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemBuilder: (context, index) {
        final item = filteredList[index];
        return TaskItemCell(
          item,
          ref,
          key: ValueKey(item.sId ?? "${item.name}_$index"),
          editMode: widget.editMode,
          checkedCallback: (id) {
            widget.changed(id);
          },
          checked: widget.checked.contains(item.sId),
        );
      },
      itemCount: filteredList.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 2);
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class TaskItemCell extends StatelessWidget {
  final TaskBean bean;
  final WidgetRef ref;
  final bool editMode;
  final bool checked;
  final ValueChanged<String> checkedCallback;

  const TaskItemCell(
    this.bean,
    this.ref, {
    Key? key,
    this.editMode = false,
    required this.checkedCallback,
    required this.checked,
  }) : super(key: key);

  void openScript(BuildContext context) {
    var info = ScriptPathInfo.parse(bean.command);
    if (info.title.isNotEmpty) {
      Navigator.of(context).pushNamed(Routes.routeScriptDetail, arguments: {
        "title": info.title,
        "path": info.path,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = ref.watch(themeProvider).themeMode == modeDark;
    final bool isPinned = (bean.isPinned ?? 0) == 1;
    final Color primary = ref.watch(themeProvider).primaryColor;
    final Color titleColor = ref.watch(themeProvider).themeColor.titleColor();
    final Color descColor = ref.watch(themeProvider).themeColor.descColor();
    final bool hasScript = bean.command != null && bean.command!.startsWith("task ");

    Color cardBg;
    if (isDark) {
      cardBg = isPinned ? const Color(0xff22211d) : const Color(0xff18181f);
    } else {
      cardBg = isPinned ? const Color(0xfffffdf5) : Colors.white;
    }

    Color cardBorder;
    if (isDark) {
      cardBorder = isPinned ? const Color(0xfff59e0b).withOpacity(0.4) : const Color(0xff272733);
    } else {
      cardBorder = isPinned ? const Color(0xfff59e0b).withOpacity(0.35) : const Color(0xffe2e8f0);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardBorder,
          width: isPinned ? 1.2 : 0.8,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.025),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Slidable(
          enabled: !editMode,
          key: ValueKey(bean.sId),
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            extentRatio: 0.75,
            children: [
              SlidableAction(
                backgroundColor: const Color(0xff5D5E70),
                onPressed: (_) {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => AddTaskPage(
                        taskBean: bean,
                        hideUploadFile: true,
                      ),
                    ),
                  );
                },
                foregroundColor: Colors.white,
                icon: CupertinoIcons.pencil_outline,
              ),
              SlidableAction(
                backgroundColor: const Color(0xffF19A39),
                onPressed: (_) {
                  WidgetsBinding.instance.endOfFrame.then((timeStamp) {
                    pinTask(context);
                  });
                },
                foregroundColor: Colors.white,
                icon: (bean.isPinned ?? 0) == 0 ? CupertinoIcons.pin : CupertinoIcons.pin_slash,
              ),
              SlidableAction(
                backgroundColor: const Color(0xffA356D6),
                onPressed: (_) {
                  WidgetsBinding.instance.endOfFrame.then((timeStamp) {
                    enableTask(context);
                  });
                },
                foregroundColor: Colors.white,
                icon: bean.isDisabled! == 0 ? Icons.dnd_forwardslash : Icons.check_circle_outline_sharp,
              ),
              SlidableAction(
                backgroundColor: const Color(0xffEA4D3E),
                onPressed: (_) {
                  WidgetsBinding.instance.endOfFrame.then((timeStamp) {
                    delTask(context, ref);
                  });
                },
                foregroundColor: Colors.white,
                icon: CupertinoIcons.delete,
              ),
            ],
          ),
          startActionPane: ActionPane(
            motion: const StretchMotion(),
            extentRatio: hasScript ? 0.6 : 0.4,
            children: [
              SlidableAction(
                backgroundColor: const Color(0xff10B981),
                onPressed: (_) {
                  if (bean.status! == 1) {
                    startCron(
                      context,
                      ref,
                      SpUtil.getBool(spAutoShowLog, defValue: true),
                    );
                  } else {
                    stopCron(
                      context,
                      ref,
                    );
                  }
                },
                foregroundColor: Colors.white,
                icon: bean.status! == 1 ? CupertinoIcons.play_circle : CupertinoIcons.stop_circle,
              ),
              SlidableAction(
                backgroundColor: const Color(0xff6366F1),
                onPressed: (_) {
                  logCron(context, ref);
                },
                foregroundColor: Colors.white,
                icon: CupertinoIcons.text_justifyleft,
              ),
              if (hasScript)
                SlidableAction(
                  backgroundColor: const Color(0xff0EA5E9),
                  onPressed: (_) {
                    openScript(context);
                  },
                  foregroundColor: Colors.white,
                  icon: CupertinoIcons.doc_text,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (editMode) {
                  checkedCallback(bean.sId ?? "");
                } else {
                  Navigator.of(context).pushNamed(Routes.routeTaskDetail, arguments: bean);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      child: SizedBox(
                        width: editMode ? 36 : 0,
                        child: Visibility(
                          visible: editMode,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Icon(
                              checked ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.circle,
                              size: 22,
                              color: checked ? primary : descColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isPinned)
                                const Padding(
                                  padding: EdgeInsets.only(right: 5),
                                  child: Icon(
                                    CupertinoIcons.pin_fill,
                                    size: 13,
                                    color: Color(0xfff59e0b),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  bean.name ?? "",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (bean.status == 0) ...[
                                const RunningWidget(),
                                const SizedBox(width: 6),
                              ],
                              if (bean.isDisabled == 1) ...[
                                const StatusWidget(
                                  title: "已禁用",
                                  color: Color(0xffef4444),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                (bean.lastExecutionTime == null || bean.lastExecutionTime == 0)
                                    ? "-"
                                    : Utils.formatMessageTime(bean.lastExecutionTime!),
                                maxLines: 1,
                                style: TextStyle(
                                  color: descColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xff23232c) : const Color(0xfff1f5f9),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.clock,
                                      size: 11,
                                      color: primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      bean.schedule ?? "",
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xffcbd5e1) : const Color(0xff475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xff121217) : const Color(0xfff8fafc),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? const Color(0xff22222a) : const Color(0xffe2e8f0),
                                width: 0.6,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.terminal,
                                  size: 13,
                                  color: descColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    bean.command ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11.5,
                                      color: isDark ? const Color(0xff94a3b8) : const Color(0xff334155),
                                    ),
                                  ),
                                ),
                                if (hasScript) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => openScript(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CupertinoIcons.doc_text,
                                            size: 11,
                                            color: primary,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            "脚本",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
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

  startCron(BuildContext context, WidgetRef ref, bool showLog) async {
    await ref
        .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
        .runCrons(context, [bean.sId!]);
    if (showLog) {
      logCron(context, ref);
    }
  }

  stopCron(BuildContext context, WidgetRef ref) {
    ref
        .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
        .stopCrons(context, [bean.sId!]);
  }

  logCron(BuildContext context, WidgetRef ref) {
    Navigator.of(context)
        .push(
      CupertinoPageRoute(
        builder: (context) => InTimeLogPage(
          bean.sId!,
          true,
          bean.name ?? "",
          command: bean.command,
        ),
      ),
    )
        .then(
      (value) {
        Future.delayed(
          const Duration(milliseconds: 500),
          () {
            ref
                .read(
                  SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier,
                )
                .loadData(
                  context,
                  false,
                );
          },
        );
      },
    );
  }

  void enableTask(BuildContext context) {
    ref
        .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
        .enableTask(context, [bean.sId!], bean.isDisabled!);
  }

  void pinTask(BuildContext context) {
    ref
        .read(SingleAccountPageState.ofTaskProvider(context)(getProviderName(context)).notifier)
        .pinTask(context, [bean.sId!], bean.isPinned ?? 0);
  }

  void delTask(BuildContext context1, WidgetRef ref) {
    showCupertinoDialog(
      context: context1,
      useRootNavigator: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("确认删除"),
        content: Text("确认删除定时任务 ${bean.name ?? ""} 吗"),
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
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(SingleAccountPageState.ofTaskProvider(context1)(getProviderName(context1)))
                  .delCron(context1, [bean.sId!]);
            },
          ),
        ],
      ),
    );
  }
}

class SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final WidgetRef ref;
  final bool editMode;

  const SliverTabBarDelegate(
    this.tabController,
    this.ref,
    this.editMode,
  );

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: 55,
      child: IgnorePointer(
        ignoring: editMode,
        child: ColoredBox(
          color: ref.watch(themeProvider).currentTheme.scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 15,
              right: 15,
              bottom: 10,
              top: 10,
            ),
            child: CustomSlidingSegmentedControl<int>(
              initialValue: 0,
              height: 35,
              isStretch: true,
              children: {
                0: Text(
                  TaskViewModel.allStr,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    color: ref.watch(themeProvider).themeColor.title2Color(),
                  ),
                ),
                1: Text(
                  TaskViewModel.runningStr,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    color: ref.watch(themeProvider).themeColor.title2Color(),
                  ),
                ),
                2: Text(
                  TaskViewModel.neverStr,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    color: ref.watch(themeProvider).themeColor.title2Color(),
                  ),
                ),
                3: Text(
                  TaskViewModel.disableStr,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    color: ref.watch(themeProvider).themeColor.title2Color(),
                  ),
                ),
              },
              decoration: BoxDecoration(
                color: ref.watch(themeProvider).themeColor.segmentedUnCheckBg(),
                borderRadius: BorderRadius.circular(8),
              ),
              thumbDecoration: BoxDecoration(
                color: ref.watch(themeProvider).themeColor.blackAndWhite(),
                borderRadius: BorderRadius.circular(6),
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInToLinear,
              onValueChanged: (v) {
                tabController.index = v;
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(SliverTabBarDelegate oldDelegate) {
    return true;
  }

  @override
  double get maxExtent => 55;

  @override
  double get minExtent => 55;
}

class EditModeButton extends ConsumerWidget {
  final String title;
  final GestureTapCallback onTap;
  final IconData icon;

  const EditModeButton(
    this.title, {
    Key? key,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final BottomNavigationBarThemeData bottomTheme = BottomNavigationBarTheme.of(context);

    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.only(
        right: 15,
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: bottomTheme.unselectedLabelStyle?.color ?? Colors.grey,
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: bottomTheme.unselectedLabelStyle?.color ?? Colors.grey,
              ),
            ),
          ],
        ),
        onPressed: onTap,
      ),
    );
  }
}
