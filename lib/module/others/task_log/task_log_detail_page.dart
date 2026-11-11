import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:share_plus/share_plus.dart';

class TaskLogDetailPage extends ConsumerStatefulWidget {
  final String title;
  final String path;

  const TaskLogDetailPage({
    Key? key,
    required this.title,
    required this.path,
  }) : super(key: key);

  @override
  _TaskLogDetailPageState createState() => _TaskLogDetailPageState();
}

class _TaskLogDetailPageState extends ConsumerState<TaskLogDetailPage>
    with LazyLoadState<TaskLogDetailPage> {
  String? content;
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();

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

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      HttpResponse<String> response = await SingleAccountPageState.ofApi(context).taskLogDetail(
        widget.title,
        widget.path,
      );

      if (response.success) {
        content = response.bean;
      } else {
        final msg = response.message ?? "获取日志详情失败";
        msg.toast();
      }
    } catch (e) {
      e.toString().toast();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void onLazyLoad() {
    loadData();
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
                  heroTag: "detail_fab_top",
                  backgroundColor: isDark ? const Color(0xFF1E2638) : Colors.white,
                  foregroundColor: primaryColor,
                  elevation: 3,
                  onPressed: _scrollToTop,
                  child: const Icon(CupertinoIcons.up_arrow, size: 16),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "detail_fab_bottom",
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
                        "日志内容为空",
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
                        onPressed: loadData,
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
}
