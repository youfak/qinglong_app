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

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final List<int> _matches = [];
  int _currentMatchIndex = -1;

  Future<void> getLogData() async {
    setState(() => isLoading = true);
    try {
      HttpResponse<String> response = await SingleAccountPageState.ofApi(context).taskLogDetail(
        widget.title,
        widget.path,
      );

      if (response.success) {
        content = response.bean;
        if (_isSearching && _searchController.text.isNotEmpty) {
          _performSearch(_searchController.text);
        }
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
    _searchController.dispose();
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

  void _performSearch(String query) {
    _matches.clear();
    final trimmed = query.trim();
    if (trimmed.isEmpty || content == null || content!.isEmpty) {
      setState(() {
        _currentMatchIndex = -1;
      });
      return;
    }

    final textLower = content!.toLowerCase();
    final queryLower = trimmed.toLowerCase();
    int startIndex = 0;
    while (true) {
      final index = textLower.indexOf(queryLower, startIndex);
      if (index == -1) break;
      _matches.add(index);
      startIndex = index + queryLower.length;
      if (_matches.length >= 1000) break;
    }

    setState(() {
      _currentMatchIndex = _matches.isNotEmpty ? 0 : -1;
    });
    if (_matches.isNotEmpty) {
      _scrollToCurrentMatch();
    }
  }

  void _nextMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matches.length;
    });
    _scrollToCurrentMatch();
  }

  void _prevMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matches.length) % _matches.length;
    });
    _scrollToCurrentMatch();
  }

  void _scrollToCurrentMatch() {
    if (_currentMatchIndex < 0 ||
        _currentMatchIndex >= _matches.length ||
        content == null) return;
    if (!_scrollController.hasClients) return;

    final charOffset = _matches[_currentMatchIndex];
    final prefix = content!.substring(0, charOffset);
    final lineNum = prefix.split('\n').length - 1;
    final totalLines = content!.split('\n').length;

    if (totalLines > 1) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final target =
          ((lineNum - 2).clamp(0, totalLines) / totalLines) * maxScroll;
      _scrollController.animateTo(
        target.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildSearchBar(BuildContext context, bool isDark, Color primaryColor) {
    final bg = isDark ? const Color(0xFF1E2638) : Colors.white;
    final border = isDark ? const Color(0x33FFFFFF) : const Color(0x1F000000);
    final textCol = isDark ? Colors.white : const Color(0xFF1E293B);
    final subCol = isDark ? Colors.white54 : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(fontSize: 13, color: textCol),
                decoration: InputDecoration(
                  hintText: "在日志中查找...",
                  hintStyle: TextStyle(fontSize: 12.5, color: subCol),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  prefixIcon: Icon(CupertinoIcons.search, size: 15, color: subCol),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _performSearch("");
                          },
                          child: Icon(CupertinoIcons.clear_circled_solid,
                              size: 15, color: subCol),
                        )
                      : null,
                ),
                onChanged: _performSearch,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: _matches.isNotEmpty
                  ? primaryColor.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _searchController.text.isEmpty
                  ? ""
                  : _matches.isEmpty
                      ? "无结果"
                      : "${_currentMatchIndex + 1}/${_matches.length}",
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: _matches.isNotEmpty ? primaryColor : subCol,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(CupertinoIcons.chevron_up, size: 18),
            tooltip: "上一个匹配",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: _matches.isNotEmpty ? _prevMatch : null,
            color: textCol,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.chevron_down, size: 18),
            tooltip: "下一个匹配",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: _matches.isNotEmpty ? _nextMatch : null,
            color: textCol,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.xmark, size: 16),
            tooltip: "关闭搜索",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _matches.clear();
                _currentMatchIndex = -1;
              });
            },
            color: subCol,
          ),
        ],
      ),
    );
  }

  Widget _buildLogContent(bool isDark, Color primaryColor) {
    final baseStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12.5,
      height: 1.5,
      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
    );

    final query = _searchController.text.trim();
    if (!_isSearching || query.isEmpty || _matches.isEmpty) {
      return SelectableText(
        content!,
        style: baseStyle,
      );
    }

    final highlightBg =
        isDark ? const Color(0x66EAB308) : const Color(0x66F59E0B);
    final activeBg = isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);

    List<TextSpan> spans = [];
    int lastIndex = 0;
    final queryLen = query.length;

    for (int i = 0; i < _matches.length; i++) {
      final start = _matches[i];
      if (start > lastIndex) {
        spans.add(TextSpan(text: content!.substring(lastIndex, start)));
      }
      final isCur = i == _currentMatchIndex;
      spans.add(TextSpan(
        text: content!.substring(start, start + queryLen),
        style: TextStyle(
          backgroundColor: isCur ? activeBg : highlightBg,
          color: isCur ? Colors.black : (isDark ? Colors.white : Colors.black),
          fontWeight: isCur ? FontWeight.bold : FontWeight.w600,
        ),
      ));
      lastIndex = start + queryLen;
    }
    if (lastIndex < content!.length) {
      spans.add(TextSpan(text: content!.substring(lastIndex)));
    }

    return SelectableText.rich(
      TextSpan(children: spans, style: baseStyle),
    );
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
            icon: Icon(
              _isSearching
                  ? CupertinoIcons.search_circle_fill
                  : CupertinoIcons.search,
              size: 20,
            ),
            tooltip: _isSearching ? "关闭搜索" : "在日志中搜索",
            color: _isSearching ? primaryColor : null,
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _matches.clear();
                  _currentMatchIndex = -1;
                }
              });
            },
          ),
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
              : Column(
                  children: [
                    if (_isSearching) _buildSearchBar(context, isDark, primaryColor),
                    Expanded(
                      child: SafeArea(
                        top: false,
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
                              child: _buildLogContent(isDark, primaryColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
