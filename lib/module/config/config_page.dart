import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/base_state_widget.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/empty_widget.dart';
import 'package:qinglong_app/base/ui/search_cell.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/config/add_config_page.dart';
import 'package:qinglong_app/module/config/config_bean.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/utils.dart';

import '../home/home_page.dart';
import 'config_viewmodel.dart';

class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({Key? key}) : super(key: key);

  @override
  ConfigPageState createState() => ConfigPageState();
}

class ConfigPageState extends ConsumerState<ConfigPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String? configContent;
  bool gotoConfigDetailed = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadConfigData(context);
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (MultiAccountPageState.actionEditConfig ==
          MultiAccountPageState.useAction()) {
        gotoConfigDetailed = false;
        loadConfigData(context);
      }
    }
  }

  Future<void> loadConfigData(BuildContext context) async {
    HttpResponse<String> result =
        await SingleAccountPageState.ofApi(context).content("config.sh");
    if (result.success && result.bean != null) {
      configContent = result.bean;

      if (MultiAccountPageState.actionEditConfig ==
              MultiAccountPageState.useAction() &&
          !gotoConfigDetailed) {
        gotoConfigDetailed = true;
        Navigator.of(context).pushNamed(
          Routes.routeConfigEdit,
          arguments: {
            "title": "config.sh",
            "content": configContent,
          },
        ).then((value) {
          loadConfigData(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.themeColor.bg2Color(),
      appBar: QlAppBar(
        canBack: false,
        title: "配置文件",
        actions: [
          IconButton(
            tooltip: "新建配置文件",
            icon: Icon(
              CupertinoIcons.plus_circle_fill,
              size: 24,
              color: primaryColor,
            ),
            onPressed: () {
              Navigator.of(context)
                  .push(
                CupertinoPageRoute(
                  builder: (context) => const AddConfigPage(),
                ),
              )
                  .then((value) {
                if (value == true) {
                  ref
                      .read(SingleAccountPageState.ofConfigProvider(context)(
                              getProviderName(context))
                          .notifier)
                      .loadData(context, false);
                }
              });
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: BaseStateWidget<ConfigViewModel>(
        builder: (ref, model, child) {
          final query = _searchController.text.trim().toLowerCase();
          final filteredList = model.list.where((item) {
            if (query.isEmpty) return true;
            return item.title?.toLowerCase().contains(query) ?? false;
          }).toList();

          return RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              await loadConfigData(context);
              return model.loadData(context, false);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                // 搜索框
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: SearchCell(controller: _searchController),
                  ),
                ),

                // 统计与提示横幅
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          "配置文件清单",
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
                            "${filteredList.length} 个配置",
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
                          final value = filteredList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ConfigFileCard(
                              bean: value,
                              isMainConfig:
                                  value.title?.toLowerCase() == "config.sh",
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  Routes.routeConfigDetail,
                                  arguments: {"bean": value},
                                ).then((_) => loadConfigData(context));
                              },
                              onEdit: () async {
                                final title = value.title ?? "";
                                if (title.isEmpty) return;

                                String? targetContent;
                                if (title.toLowerCase() == "config.sh" && configContent != null) {
                                  targetContent = configContent;
                                } else {
                                  EasyLoading.show(status: "获取配置中...");
                                  try {
                                    final res = await SingleAccountPageState.ofApi(context).content(title);
                                    EasyLoading.dismiss();
                                    if (res.success && res.bean != null) {
                                      targetContent = res.bean;
                                    } else {
                                      (res.message ?? "获取文件内容失败").toast();
                                      return;
                                    }
                                  } catch (e) {
                                    EasyLoading.dismiss();
                                    "获取文件内容失败".toast();
                                    return;
                                  }
                                }

                                Navigator.of(context).pushNamed(
                                  Routes.routeConfigEdit,
                                  arguments: {
                                    "title": title,
                                    "content": targetContent,
                                  },
                                ).then((_) {
                                  Future.delayed(
                                      const Duration(milliseconds: 500), () {
                                    loadConfigData(context);
                                  });
                                });
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
          );
        },
        model: SingleAccountPageState.ofConfigProvider(context)(
            getProviderName(context)),
        onReady: (viewModel) {
          viewModel.loadData(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class ConfigFileCard extends ConsumerWidget {
  final ConfigBean bean;
  final bool isMainConfig;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const ConfigFileCard({
    Key? key,
    required this.bean,
    required this.isMainConfig,
    required this.onTap,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final isDark = theme.isDark();
    final primaryColor = theme.primaryColor;
    final cardBg = theme.themeColor.settingBgColor();
    final titleColor = theme.themeColor.titleColor();
    final descColor = theme.themeColor.descColor();
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    final title = bean.title ?? "未命名配置";
    final ext = title.contains(".") ? title.split(".").last : "sh";

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMainConfig ? primaryColor.withOpacity(0.4) : borderColor,
          width: isMainConfig ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isMainConfig
                ? primaryColor.withOpacity(0.04)
                : Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // 文件格式图标
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isMainConfig
                        ? primaryColor.withOpacity(0.12)
                        : (isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      isMainConfig
                          ? CupertinoIcons.doc_text_fill
                          : CupertinoIcons.doc_text,
                      color: isMainConfig ? primaryColor : titleColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 文件名与类型徽章
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMainConfig) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "主配置",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isMainConfig
                            ? "青龙面板核心环境变量与全局设定文件"
                            : "扩展配置文件 · .$ext",
                        style: TextStyle(
                          fontSize: 12,
                          color: descColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 快捷编辑按钮
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMainConfig
                        ? primaryColor
                        : (isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05)),
                    foregroundColor: isMainConfig ? Colors.white : titleColor,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    CupertinoIcons.pencil,
                    size: 13,
                    color: isMainConfig ? Colors.white : primaryColor,
                  ),
                  label: const Text(
                    "编辑",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: onEdit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
