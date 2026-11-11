import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:share_plus/share_plus.dart';

import '../../../base/cupertino_sheet.dart';
import '../../../main.dart';
import '../../home/system_bean.dart';

class InTimeHistoryLogPage extends ConsumerStatefulWidget {
  final String title;
  final String path;

  const InTimeHistoryLogPage({
    Key? key,
    required this.title,
    required this.path,
  }) : super(key: key);

  @override
  _InTimeHistoryLogPageState createState() => _InTimeHistoryLogPageState();
}

class _InTimeHistoryLogPageState extends ConsumerState<InTimeHistoryLogPage> with LazyLoadState<InTimeHistoryLogPage> {
  String? content;
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();

  Future<void> getLogData() async {
    setState(() => isLoading = true);
    try {
      HttpResponse<String> response = await SingleAccountPageState.ofApi(context).taskLogDetail(
        widget.title,
        widget.path,
      );

      if (response.success) {
        content = response.bean;
      } else {
        final msg = response.message ?? "获取日志失败";
        msg.toast();
      }
    } catch (e) {
      e.toString().toast();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark || theme.isDark();
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      floatingActionButton: content != null && content!.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: "fab_top",
                  backgroundColor: isDark ? const Color(0xFF1E2638) : Colors.white,
                  foregroundColor: primaryColor,
                  elevation: 3,
                  onPressed: _scrollToTop,
                  child: const Icon(CupertinoIcons.up_arrow, size: 16),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "fab_bottom",
                  backgroundColor: isDark ? const Color(0xFF1E2638) : Colors.white,
                  foregroundColor: primaryColor,
                  elevation: 3,
                  onPressed: _scrollToBottom,
                  child: const Icon(CupertinoIcons.down_arrow, size: 16),
                ),
              ],
            )
          : null,
      appBar: QlAppBar(
        canBack: true,
        title: widget.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: "复制全部日志",
            onPressed: () {
              if (content != null && content!.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: content!));
                "已复制全部日志".toast();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 19),
            tooltip: "分享日志",
            onPressed: () {
              if (content != null && content!.isNotEmpty) {
                Share.share(content!);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            tooltip: "更多操作",
            onPressed: () {
              showMoreOperate(
                context,
                [
                  CupertinoSheer(
                    title: "刷新日志",
                    icon: CupertinoIcons.refresh,
                    onTap: getLogData,
                  ),
                  addDivider(),
                  CupertinoSheer(
                    title: "分享日志",
                    icon: Icons.share_outlined,
                    onTap: () async {
                      if (content != null) Share.share(content!);
                    },
                  ),
                  addDivider(),
                  CupertinoSheer(
                    title: "删除该日志",
                    icon: Icons.delete_outline_rounded,
                    isDestructive: true,
                    onTap: () {
                      deleteFold(widget.title, widget.path);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: LoadingWidget())
          : content == null || content!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 56,
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "日志内容为空或已被清理",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(CupertinoIcons.refresh, size: 15),
                        label: const Text("重新获取"),
                        onPressed: getLogData,
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B0F19) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
                      ),
                    ),
                    child: CupertinoScrollbar(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(14),
                        child: SelectableText(
                          content!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                            height: 1.5,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  @override
  void onLazyLoad() {
    getLogData();
  }

  void deleteFold(String title, String path) async {
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

    EasyLoading.show(status: "删除中...");
    var temp = await SingleAccountPageState.ofApi(context).deleteLog(title, path);
    EasyLoading.dismiss();
    if (temp.success) {
      "已删除".toast();
      Navigator.of(context).pop(true);
    } else {
      temp.message.toast();
    }
  }
}
