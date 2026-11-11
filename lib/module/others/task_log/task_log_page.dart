import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/module/others/task_log/task_log_bean.dart';
import 'package:qinglong_app/module/task/intime_log/intime_history_log_page.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../../../main.dart';
import '../../home/system_bean.dart';

class TaskLogPage extends ConsumerStatefulWidget {
  final String? searchText;

  const TaskLogPage({
    Key? key,
    this.searchText,
  }) : super(key: key);

  @override
  _TaskLogPageState createState() => _TaskLogPageState();
}

class _TaskLogPageState extends ConsumerState<TaskLogPage> with LazyLoadState<TaskLogPage> {
  List<TaskLogBean> list = [];
  bool isLoading = true;

  final TextEditingController searchText = TextEditingController();
  final ScrollController controller = ScrollController();
  bool buttonshow = false;

  void scrollToTop() {
    controller.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(floatingButtonVisibility);
    searchText.addListener(() {
      setState(() {});
    });
    if (widget.searchText != null && widget.searchText!.isNotEmpty) {
      searchText.text = widget.searchText!;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    searchText.dispose();
    super.dispose();
  }

  void floatingButtonVisibility() {
    double y = controller.offset;
    if (y > 400) {
      if (buttonshow) return;
      setState(() => buttonshow = true);
    } else {
      if (!buttonshow) return;
      setState(() => buttonshow = false);
    }
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      HttpResponse<List<TaskLogBean>> response = await SingleAccountPageState.ofApi(context).taskLog();
      list.clear();
      if (response.success && response.bean != null) {
        list.addAll(response.bean ?? []);
      } else {
        final msg = response.message ?? "";
        if (msg.isNotEmpty && !msg.contains("下线")) {
          msg.toast();
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void onLazyLoad() {
    loadData();
  }

  void deleteFold(TaskLogBean item) async {
    SystemBean? systemBean;
    try {
      systemBean = getIt<SystemBean>(instanceName: (SingleAccountPageState.of(context)?.index ?? 0).toString());
    } catch (e) {
      systemBean = SystemBean(version: "2.10.13", fromAutoGet: false);
    }
    if (!systemBean.isUpperVersion2_14_5()) {
      "该功能仅支持v2.14.5及以上版本".toast();
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark || ref.read(themeProvider).isDark();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2638) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
            ),
            const SizedBox(width: 12),
            const Text("确认删除日志", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("确定删除日志「${item.name ?? ""}」吗？此操作不可撤销。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("取消"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              EasyLoading.show(status: "删除中...");
              var temp = item.isDir == true
                  ? await SingleAccountPageState.ofApi(context).deleteLogFold(item.name ?? "", "")
                  : await SingleAccountPageState.ofApi(context).deleteLog(item.name ?? "", "");
              EasyLoading.dismiss();
              if (temp.success) {
                "已删除".toast();
                await loadData();
              } else {
                temp.message.toast();
              }
            },
            child: const Text("删除", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark || theme.isDark();
    final primaryColor = theme.primaryColor;
    final cardBg = theme.themeColor.settingBgColor();
    final titleColor = theme.themeColor.titleColor();
    final descColor = theme.themeColor.descColor();
    final borderColor = isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000);

    final query = searchText.text.trim().toLowerCase();
    final filteredList = query.isEmpty
        ? list
        : list.where((item) {
            final nameMatch = item.name?.toLowerCase().contains(query) ?? false;
            final filesMatch = item.files?.any((f) => f.toLowerCase().contains(query)) ?? false;
            final childrenMatch = item.children?.any((c) => (c.title?.toLowerCase().contains(query) ?? false)) ?? false;
            return nameMatch || filesMatch || childrenMatch;
          }).toList();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (_) => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        backgroundColor: theme.themeColor.bg2Color(),
        floatingActionButton: Visibility(
          visible: buttonshow,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: primaryColor,
            onPressed: scrollToTop,
            elevation: 3,
            child: const Icon(CupertinoIcons.up_arrow, color: Colors.white, size: 20),
          ),
        ),
        appBar: QlAppBar(
          canBack: true,
          title: "任务日志",
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.refresh, size: 20),
              tooltip: "刷新",
              onPressed: loadData,
            ),
          ],
        ),
        body: Column(
          children: [
            // 顶部搜索与计数
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? const Color(0xFF131B2E) : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 18, color: descColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: searchText,
                              style: TextStyle(fontSize: 14, color: titleColor),
                              decoration: InputDecoration(
                                hintText: "搜索任务日志名称...",
                                hintStyle: TextStyle(fontSize: 13, color: descColor.withOpacity(0.6)),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (searchText.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => searchText.clear(),
                              child: Icon(Icons.cancel_rounded, size: 16, color: descColor),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${filteredList.length} 个任务",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),

            // 主列表
            Expanded(
              child: isLoading
                  ? const Center(child: LoadingWidget())
                  : filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.article_outlined, size: 60, color: descColor.withOpacity(0.35)),
                              const SizedBox(height: 16),
                              Text(
                                query.isNotEmpty ? "未找到匹配日志" : "暂无任务日志",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "如提示接口下线，青龙已自动尝试降级通道",
                                style: TextStyle(fontSize: 13, color: descColor),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                icon: const Icon(CupertinoIcons.refresh, size: 16),
                                label: const Text("重新拉取"),
                                onPressed: loadData,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: primaryColor,
                          onRefresh: loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            controller: controller,
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              return _buildLogItemCard(item, isDark, cardBg, titleColor, descColor, borderColor, primaryColor);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItemCard(
    TaskLogBean item,
    bool isDark,
    Color cardBg,
    Color titleColor,
    Color descColor,
    Color borderColor,
    Color primaryColor,
  ) {
    final isDir = item.isDir == true;
    final logFiles = item.files ?? [];
    final children = item.children ?? [];
    final totalCount = logFiles.isNotEmpty ? logFiles.length : children.length;

    if (isDir) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Slidable(
          key: ValueKey(item.name ?? ""),
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            extentRatio: 0.2,
            children: [
              SlidableAction(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                icon: CupertinoIcons.delete,
                label: "删除",
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                onPressed: (_) => deleteFold(item),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.terminal_rounded, size: 22, color: Color(0xFF10B981)),
              ),
              title: Text(
                item.name ?? "",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: titleColor,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "$totalCount 个历史日志",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              children: [
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 8),
                if (logFiles.isNotEmpty)
                  ...logFiles.map((fileName) => _buildChildLogTile(item.name ?? "", fileName, isDark, titleColor, descColor, borderColor))
                else if (children.isNotEmpty)
                  ...children.map((child) => _buildChildLogTile(item.name ?? "", child.title ?? "", isDark, titleColor, descColor, borderColor))
                else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text("文件夹为空", style: TextStyle(fontSize: 13, color: descColor)),
                  ),
              ],
            ),
          ),
        ),
      );
    } else {
      // 独立日志文件
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Slidable(
          key: ValueKey(item.name ?? ""),
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            extentRatio: 0.2,
            children: [
              SlidableAction(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                icon: CupertinoIcons.delete,
                label: "删除",
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                onPressed: (_) => deleteFold(item),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => InTimeHistoryLogPage(
                      path: "",
                      title: item.name ?? "",
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.description_outlined, size: 22, color: Color(0xFF0EA5E9)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.name ?? "",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: titleColor,
                        ),
                      ),
                    ),
                    Icon(CupertinoIcons.chevron_right, size: 16, color: descColor.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildChildLogTile(
    String dirName,
    String logFileName,
    bool isDark,
    Color titleColor,
    Color descColor,
    Color borderColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => InTimeHistoryLogPage(
                  path: dirName,
                  title: logFileName,
                ),
              ),
            ).then((val) {
              if (val == true) loadData();
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: descColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    logFileName,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                      color: titleColor,
                    ),
                  ),
                ),
                Icon(CupertinoIcons.chevron_right, size: 14, color: descColor.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
