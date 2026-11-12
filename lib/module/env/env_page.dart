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
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/search_cell.dart';
import 'package:qinglong_app/module/env/add_env_page.dart';
import 'package:qinglong_app/module/env/env_bean.dart';
import 'package:qinglong_app/module/env/env_viewmodel.dart';
import 'package:qinglong_app/module/task/task_page.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/utils.dart';

import '../../base/ui/enable_widget.dart';

class EnvPage extends ConsumerStatefulWidget {
  const EnvPage({Key? key}) : super(key: key);

  @override
  EnvPageState createState() => EnvPageState();
}

class EnvPageState extends ConsumerState<EnvPage> with TickerProviderStateMixin {
  String currentState = EnvViewModel.allStr;
  TextEditingController searchText = TextEditingController();
  TabController? _tabController;
  final ScrollController _scrollController = ScrollController();

  bool editMode = false;
  Set<String> checkedIds = <String>{};
  bool buttonshow = false;
  GlobalKey<RefreshIndicatorState> refreshKey = GlobalKey();

  Future<void> scrollToTop() async {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.linear);
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

  List<EnvBean> getListByType(int index) {
    var model = ref.read(SingleAccountPageState.ofEnvProvider(context)(getProviderName(context)).notifier);
    if (index == 0) {
      return model.list;
    } else if (index == 1) {
      return model.enabledList;
    } else if (index == 2) {
      return model.disabledList;
    }
    return model.list;
  }

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);

    super.initState();
    searchText.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    removeOverlay();
    super.dispose();
  }

  double searchCellHeight = 55;

  SliverAppBar _buildAppBar(WidgetRef ref, EnvViewModel model) {
    return SliverAppBar(
      pinned: false,
      floating: false,
      elevation: 0,
      automaticallyImplyLeading: false,
      snap: false,
      primary: false,
      toolbarHeight: searchCellHeight,
      flexibleSpace: searchCell(context, ref, model),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (_) {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        appBar: QlAppBar(
          title: (editMode && checkedIds.isNotEmpty) ? "当前选中 ${checkedIds.length} 个变量" : "环境变量",
          canClick2Vip: !editMode,
          backWidget: Builder(builder: (context) {
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
                // searchText.text = "";
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
          }),
          actions: [
            CupertinoButton(
              color: Colors.transparent,
              padding: EdgeInsets.zero,
              onPressed: () {
                if (editMode) {
                  if (checkedIds.length ==
                      getListByType(_tabController?.index ?? 0).where((value) {
                        if (searchText.text.isEmpty ||
                            (value.name?.contains(searchText.text.toLowerCase()) ?? false) ||
                            (value.value?.contains(searchText.text.toLowerCase()) ?? false) ||
                            (value.remarks?.contains(searchText.text.toLowerCase()) ?? false)) {
                          return true;
                        } else {
                          return false;
                        }
                      }).length) {
                    //全不选

                    checkedIds.clear();
                    setState(() {});
                  } else {
                    //全选
                    checkedIds.clear();
                    checkedIds.addAll(getListByType(_tabController?.index ?? 0)
                        .where((value) {
                          if (searchText.text.isEmpty ||
                              (value.name?.contains(searchText.text.toLowerCase()) ?? false) ||
                              (value.value?.contains(searchText.text.toLowerCase()) ?? false) ||
                              (value.remarks?.contains(searchText.text.toLowerCase()) ?? false)) {
                            return true;
                          } else {
                            return false;
                          }
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
                    builder: (context) => const AddEnvPage(),
                  ),
                )
                    .then((value) {
                  ref.read(SingleAccountPageState.ofEnvProvider(context)(getProviderName(context)).notifier).loadData(context, false);
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                child: Center(
                  child: editMode
                      ? Text(
                          checkedIds.length ==
                                  getListByType(_tabController?.index ?? 0).where((value) {
                                    if (searchText.text.isEmpty ||
                                        (value.name?.contains(searchText.text.toLowerCase()) ?? false) ||
                                        (value.value?.contains(searchText.text.toLowerCase()) ?? false) ||
                                        (value.remarks?.contains(searchText.text.toLowerCase()) ?? false)) {
                                      return true;
                                    } else {
                                      return false;
                                    }
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
        body: BaseStateWidget<EnvViewModel>(
          builder: (ref, model, child) {
            return NestedScrollView(
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
                notificationPredicate: (_) {
                  return true;
                },
                color: Theme.of(context).primaryColor,
                onRefresh: () async {
                  return model.loadData(context, false);
                },
                child: SlidableAutoCloseBehavior(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      EnvRecordListView(
                        list: model.list,
                        searchText: searchText.text,
                        editMode: editMode,
                        checked: checkedIds,
                        changed: (id) {
                          if (checkedIds.contains(id)) {
                            checkedIds.remove(id);
                          } else {
                            checkedIds.add(id);
                          }
                          setState(() {});
                        },
                      ),
                      EnvListView(
                        list: model.enabledList,
                        searchText: searchText.text,
                        editMode: editMode,
                        checked: checkedIds,
                        changed: (id) {
                          if (checkedIds.contains(id)) {
                            checkedIds.remove(id);
                          } else {
                            checkedIds.add(id);
                          }
                          setState(() {});
                        },
                      ),
                      EnvListView(
                        list: model.disabledList,
                        searchText: searchText.text,
                        editMode: editMode,
                        checked: checkedIds,
                        changed: (id) {
                          if (checkedIds.contains(id)) {
                            checkedIds.remove(id);
                          } else {
                            checkedIds.add(id);
                          }
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          model: SingleAccountPageState.ofEnvProvider(context)(getProviderName(context)),
          onReady: (viewModel) {
            viewModel.loadData(context);
          },
        ),
      ),
    );
  }

  Widget searchCell(BuildContext context, WidgetRef ref, EnvViewModel model) {
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

  OverlayEntry? _editModeOverlay;

  void showOverlay(BuildContext context) {
    removeOverlay();
    _editModeOverlay = OverlayEntry(
      builder: (BuildContext context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: ref.watch(themeProvider).currentTheme.bottomNavigationBarTheme.backgroundColor?.withOpacity(1),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: kBottomNavigationBarHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
        );
      },
    );

    Overlay.of(context)?.insert(_editModeOverlay!);
  }

  void _executeCode(BuildContext context, String s) {
    if (checkedIds.isEmpty) {
      "至少选择1个变量".toast();
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
              WidgetsBinding.instance.addPostFrameCallback(
                (timeStamp) {
                  if (s == "启用") {
                    enableEnv();
                  } else if (s == "禁用") {
                    disableEnv();
                  } else if (s == "删除") {
                    deleteEnvs();
                  }
                },
              );
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  void enableEnv() {
    ref.read(SingleAccountPageState.ofEnvProvider(context)(getProviderName(context)).notifier).enableEnv(
          context,
          checkedIds.toList(),
          1,
        );
  }

  void disableEnv() {
    ref.read(SingleAccountPageState.ofEnvProvider(context)(getProviderName(context)).notifier).enableEnv(
          context,
          checkedIds.toList(),
          0,
        );
  }

  void deleteEnvs() {
    ref.read(SingleAccountPageState.ofEnvProvider(context)(getProviderName(context)).notifier).delEnvs(context, checkedIds.toList());
  }

  void removeOverlay() {
    if (_editModeOverlay != null && _editModeOverlay!.mounted) {
      _editModeOverlay?.remove();
      _editModeOverlay = null;
    }
  }
}

class EnvItemCell extends StatelessWidget {
  final EnvBean bean;
  final int index;
  final WidgetRef ref;
  final bool editMode;
  final bool editMode2;
  final bool checked;
  final ValueChanged<String> checkedCallback;

  const EnvItemCell(
    this.bean,
    this.index,
    this.ref, {
    Key? key,
    this.editMode = false,
    this.editMode2 = false,
    required this.checkedCallback,
    required this.checked,
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
        : Colors.black.withOpacity(0.05);

    final timeStr = bean.updatedAt == null
        ? Utils.formatGMTTime(bean.timestamp ?? "")
        : Utils.formatTime2(bean.updatedAt);

    return Slidable(
      enabled: !editMode,
      key: ValueKey(bean.sId),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            backgroundColor: const Color(0xff5D5E70),
            onPressed: (_) {
              Navigator.of(context)
                  .push(
                CupertinoPageRoute(
                  builder: (context) => AddEnvPage(
                    envBean: bean,
                  ),
                ),
              )
                  .then((value) {
                ref
                    .read(SingleAccountPageState.ofEnvProvider(context)(
                        getProviderName(context)).notifier)
                    .loadData(context, false);
              });
            },
            foregroundColor: Colors.white,
            icon: CupertinoIcons.pencil_outline,
          ),
          SlidableAction(
            backgroundColor: const Color(0xffA356D6),
            onPressed: (_) {
              enableEnv(context);
            },
            foregroundColor: Colors.white,
            icon: bean.status == 1
                ? Icons.check_circle_outline_sharp
                : Icons.dnd_forwardslash,
          ),
          SlidableAction(
            backgroundColor: const Color(0xffEA4D3E),
            onPressed: (_) {
              delEnv(context, ref);
            },
            foregroundColor: Colors.white,
            icon: CupertinoIcons.delete,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (editMode) {
                checkedCallback(bean.sId ?? "");
              } else {
                Navigator.of(context)
                    .pushNamed(Routes.routeEnvDetail, arguments: bean);
              }
            },
            child: Row(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: SizedBox(
                    width: editMode ? 44 : 0,
                    height: 44,
                    child: Visibility(
                      visible: editMode,
                      child: Center(
                        child: Icon(
                          checked
                              ? CupertinoIcons.checkmark_alt_circle_fill
                              : CupertinoIcons.circle,
                          size: 24,
                          color: checked ? primaryColor : descColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 第一行：序号 + 变量名与备注 + 右上角启用/禁用状态
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${getIndexByIndex(context, index)}",
                                style: TextStyle(
                                  color: descColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  text: bean.name ?? "",
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    if (bean.remarks != null &&
                                        bean.remarks!.isNotEmpty)
                                      TextSpan(
                                        text: " (${bean.remarks})",
                                        style: TextStyle(
                                          color: descColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            bean.status == 1
                                ? const StatusWidget(
                                    title: "已禁用",
                                    color: Color(0xffEF4444),
                                  )
                                : StatusWidget(
                                    title: "已启用",
                                    color: primaryColor,
                                  ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 第二行：变量值
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bean.value ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: titleColor.withOpacity(0.85),
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 第三行（右下角）：时间信息彻底靠右展示，绝不与状态重叠
                        if (!editMode2 && timeStr.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                CupertinoIcons.clock,
                                size: 12,
                                color: descColor.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color: descColor.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                if (editMode2)
                  const IgnorePointer(
                    ignoring: true,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(
                        CupertinoIcons.line_horizontal_3,
                        color: Color(0xff999999),
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void enableEnv(BuildContext context) {
    ref
        .read(SingleAccountPageState.ofEnvProvider(context)(
            getProviderName(context)))
        .enableEnv(context, [bean.sId!], bean.status!);
  }

  void delEnv(BuildContext context1, WidgetRef ref) {
    showCupertinoDialog(
      useRootNavigator: false,
      context: context1,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("确认删除"),
        content: Text("确认删除环境变量 ${bean.name ?? ""} 吗"),
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
                  .read(SingleAccountPageState.ofEnvProvider(context1)(
                      getProviderName(context1)))
                  .delEnv(context1, bean.sId!);
            },
          ),
        ],
      ),
    );
  }

  int getIndexByIndex(BuildContext context, int index) {
    return index + 1;
  }
}

class EnvListView extends ConsumerStatefulWidget {
  final List<EnvBean> list;
  final String searchText;
  final bool editMode;
  final Set<String> checked;
  final ValueChanged<String> changed;

  const EnvListView({
    Key? key,
    required this.list,
    required this.searchText,
    required this.editMode,
    required this.checked,
    required this.changed,
  }) : super(key: key);

  @override
  ConsumerState<EnvListView> createState() => _EnvListViewState();
}

class _EnvListViewState extends ConsumerState<EnvListView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final query = widget.searchText.trim().toLowerCase();
    final filteredList = widget.list.where((value) {
      if (query.isEmpty) return true;
      return (value.name?.toLowerCase().contains(query) ?? false) ||
          (value.value?.toLowerCase().contains(query) ?? false) ||
          (value.remarks?.toLowerCase().contains(query) ?? false);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.only(
        bottom: kBottomNavigationBarHeight + 50,
        top: kToolbarHeight,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int i) {
        EnvBean value = filteredList[i];
        return EnvItemCell(
          value,
          i,
          ref,
          key: ValueKey(value.sId),
          editMode: widget.editMode,
          editMode2: false,
          checkedCallback: (id) {
            widget.changed(id);
          },
          checked: widget.checked.contains(value.sId),
        );
      },
      itemCount: filteredList.length,
    );
  }
}

class EnvRecordListView extends ConsumerStatefulWidget {
  final List<EnvBean> list;
  final String searchText;
  final bool editMode;
  final Set<String> checked;
  final ValueChanged<String> changed;

  const EnvRecordListView({
    Key? key,
    required this.list,
    required this.searchText,
    required this.editMode,
    required this.checked,
    required this.changed,
  }) : super(key: key);

  @override
  ConsumerState<EnvRecordListView> createState() => _EnvRecordListViewState();
}

class _EnvRecordListViewState extends ConsumerState<EnvRecordListView> with AutomaticKeepAliveClientMixin {
  final List<EnvItemCell> list = [];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    list.clear();
    for (int i = 0; i < widget.list.length; i++) {
      EnvBean value = widget.list[i];
      if (widget.searchText.isEmpty ||
          (value.name?.contains(widget.searchText) ?? false) ||
          (value.value?.contains(widget.searchText) ?? false) ||
          (value.remarks?.contains(widget.searchText) ?? false)) {
        list.add(
          EnvItemCell(
            value,
            i,
            ref,
            key: ValueKey(value.sId),
            editMode: widget.editMode,
            editMode2: widget.editMode,
            checkedCallback: (id) {
              widget.changed(id);
            },
            checked: widget.checked.contains(value.sId),
          ),
        );
      }
    }
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        bottom: kBottomNavigationBarHeight + 50,
        top: kToolbarHeight,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      onReorder: (int oldIndex, int newIndex) {
        if (widget.searchText.isNotEmpty) {
          "请先清空搜索关键词".toast();
          return;
        }

        setState(
          () {
            //交换数据
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final EnvBean item = widget.list.removeAt(oldIndex);
            widget.list.insert(newIndex, item);

            ref.read(SingleAccountPageState.ofEnvProvider(context)(getProviderName(context)).notifier).update(context, item.sId ?? "", newIndex, oldIndex);
          },
        );
      },
      children: list,
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
                  EnvViewModel.allStr,
                  style: TextStyle(
                    fontSize: 14,
                    color: ref.watch(themeProvider).themeColor.title2Color(),
                  ),
                ),
                1: Text(
                  EnvViewModel.enabledStr,
                  style: TextStyle(
                    fontSize: 14,
                    color: ref.watch(themeProvider).themeColor.title2Color(),
                  ),
                ),
                2: Text(
                  EnvViewModel.disabledStr,
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
