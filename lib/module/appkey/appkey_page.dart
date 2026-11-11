import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:qinglong_app/base/base_state_widget.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/search_cell.dart';
import 'package:qinglong_app/module/appkey/appkey_detail_page.dart';
import 'package:qinglong_app/module/appkey/appkey_viewmodel.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/utils.dart';

import 'add_appkey_page.dart';

class AppKeyPage extends ConsumerStatefulWidget {
  const AppKeyPage({Key? key}) : super(key: key);

  @override
  _AppKeyPageState createState() => _AppKeyPageState();
}

class _AppKeyPageState extends ConsumerState<AppKeyPage> {
  final TextEditingController searchText = TextEditingController();
  final ScrollController controller = ScrollController();
  bool buttonshow = false;

  void scrollToTop() {
    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
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
        title: "应用设置",
        actions: [
          IconButton(
            tooltip: "新增应用",
            icon: Icon(
              CupertinoIcons.plus_circle_fill,
              size: 24,
              color: primaryColor,
            ),
            onPressed: () {
              Navigator.of(context)
                  .push(
                CupertinoPageRoute(
                  builder: (context) => const AddAppKeyPage(bean: {}),
                ),
              )
                  .then((value) {
                if (value != null && value == true) {
                  ref
                      .read(
                        SingleAccountPageState.ofAppKeyProvider(context)(
                          getProviderName(context),
                        ),
                      )
                      .loadData(context);
                }
              });
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: BaseStateWidget<AppKeyViewModel>(
        builder: (ref, model, child) {
          return body(model, getListByType(model), ref);
        },
        model: SingleAccountPageState.ofAppKeyProvider(context)(
          getProviderName(context),
        ),
        lazyLoad: true,
        onReady: (viewModel) {
          viewModel.loadData(context);
        },
      ),
    );
  }

  Widget body(
    AppKeyViewModel model,
    List<Map<String, dynamic>> list,
    WidgetRef ref,
  ) {
    final theme = ref.watch(themeProvider);
    final isDark = theme.isDark();
    final primaryColor = theme.primaryColor;

    final filteredList = list.where((item) {
      if (searchText.text.isEmpty) return true;
      final name = item["name"]?.toString().toLowerCase() ?? "";
      final clientId = item["client_id"]?.toString().toLowerCase() ?? "";
      final q = searchText.text.toLowerCase();
      return name.contains(q) || clientId.contains(q);
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

            // 头部提示横幅
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle_fill,
                        color: primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "青龙 OpenAPI 应用密钥，向左滑动卡片可快捷编辑、重置 Secret 或删除应用。",
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryColor.withOpacity(0.9),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 列表内容
            if (filteredList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.square_grid_2x2,
                        size: 54,
                        color: theme.themeColor.descColor().withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        searchText.text.isEmpty ? "暂无 OpenAPI 应用" : "未搜索到匹配应用",
                        style: TextStyle(
                          color: theme.themeColor.descColor(),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
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
                        child: AppKeyItemCard(
                          bean: item,
                          ref: ref,
                          onRefreshNeeded: () => model.loadData(context),
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

  List<Map<String, dynamic>> getListByType(AppKeyViewModel model) {
    return model.list;
  }
}

class AppKeyItemCard extends StatelessWidget {
  final Map<String, dynamic> bean;
  final WidgetRef ref;
  final VoidCallback onRefreshNeeded;

  const AppKeyItemCard({
    Key? key,
    required this.bean,
    required this.ref,
    required this.onRefreshNeeded,
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

    final scopes = AppKeyViewModel.getScopeNames(
      bean["scopes"] as List<dynamic>?,
    );
    final clientId = bean["client_id"]?.toString() ?? "";

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Slidable(
          key: ValueKey(getAppKeyId(bean)),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.65,
            children: [
              SlidableAction(
                backgroundColor: const Color(0xff3B82F6),
                foregroundColor: Colors.white,
                icon: CupertinoIcons.pencil,
                label: '编辑',
                onPressed: (_) {
                  Navigator.of(context)
                      .push(
                    CupertinoPageRoute(
                      builder: (context) => AddAppKeyPage(bean: bean),
                    ),
                  )
                      .then((val) {
                    if (val == true) onRefreshNeeded();
                  });
                },
              ),
              SlidableAction(
                backgroundColor: const Color(0xff8B5CF6),
                foregroundColor: Colors.white,
                icon: CupertinoIcons.arrow_2_circlepath,
                label: '重置',
                onPressed: (_) {
                  WidgetsBinding.instance.endOfFrame.then((value) {
                    _reset(context);
                  });
                },
              ),
              SlidableAction(
                backgroundColor: const Color(0xffEF4444),
                foregroundColor: Colors.white,
                icon: CupertinoIcons.delete,
                label: '删除',
                onPressed: (_) {
                  WidgetsBinding.instance.endOfFrame.then((value) {
                    _del(context, ref);
                  });
                },
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => AppKeyDetailDetailPage(bean),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头部：图标 + 应用名 + 权限数徽标
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.2),
                                primaryColor.withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            CupertinoIcons.lock_shield_fill,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bean["name"] ?? "未命名应用",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                              if (clientId.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  "ID: $clientId",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: descColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${scopes.length} 项权限",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: descColor.withOpacity(0.4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 权限 Chip 标签
                    if (scopes.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: scopes.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.06),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  e,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: titleColor.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Text(
                        "无分配权限",
                        style: TextStyle(fontSize: 12, color: descColor),
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

  void _del(BuildContext context1, WidgetRef ref) {
    showCupertinoDialog(
      context: context1,
      useRootNavigator: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("确认删除应用"),
        content: Text("确定要删除应用「${bean["name"] ?? ""}」吗？删除后该应用将无法再访问任何 API 接口。"),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("删除"),
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(
                    SingleAccountPageState.ofAppKeyProvider(context1)(
                      getProviderName(context1),
                    ),
                  )
                  .delAppKey(context1, getAppKeyId(bean));
            },
          ),
        ],
      ),
    );
  }

  void _reset(BuildContext context) {
    showCupertinoDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => CupertinoAlertDialog(
        title: Text("确认重置「${bean["name"]}」的 Secret?"),
        content: const Text("重置 Secret 会立即导致使用原密钥的所有第三方脚本与 Token 失效，需要重新配置。"),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: Text(
              "确定重置",
              style: TextStyle(
                color: ref.watch(themeProvider).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(
                    SingleAccountPageState.ofAppKeyProvider(context)(
                      getProviderName(context),
                    ),
                  )
                  .resetAppKey(context, getAppKeyId(bean));
            },
          ),
        ],
      ),
    );
  }
}

String getAppKeyId(Map<String, dynamic> bean) {
  if (bean.containsKey("_id")) {
    return bean["_id"] ?? "";
  }
  return bean["id"]?.toString() ?? "";
}
