import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/module/scan_page.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/sp_utils.dart';
import 'package:share_plus/share_plus.dart';

import '../../../base/http/api.dart';

class InTimeLogPage extends ConsumerStatefulWidget {
  final String cronId;
  final bool needTimer;
  final String title;
  final String? command;

  const InTimeLogPage(
    this.cronId,
    this.needTimer,
    this.title, {
    Key? key,
    this.command,
  }) : super(key: key);

  @override
  _InTimeLogPageState createState() => _InTimeLogPageState();
}

class _InTimeLogPageState extends ConsumerState<InTimeLogPage> with LazyLoadState<InTimeLogPage> {
  Timer? _timer;

  String? content;

  bool isRequest = false;
  bool canRequest = true;
  bool alwaysAuthScroll = false;

  final ScrollController _scrollController = ScrollController();
  bool hasToastedFailed = false;

  Future<void> getLogData() async {
    if (!canRequest) return;
    if (isRequest) return;
    if (!mounted) return;
    isRequest = true;
    HttpResponse<String> response = await SingleAccountPageState.ofApi(context).inTimeLog(widget.cronId);

    if (!mounted) return;
    isRequest = false;
    if (response.success) {
      if (!mounted) return;
      content = response.bean;
      if (content == null || content!.isEmpty) return;

      String? found = ScanPageState.foundReg(widget.command ?? "", content ?? "");
      if (found != null &&
          found.isNotEmpty &&
          widget.command != null &&
          (widget.command!.endsWith(".js") || widget.command!.endsWith(".ts") || widget.command!.endsWith(".py")) &&
          SpUtil.getInt(spVIP, defValue: typeNormal) != typeNormal) {
        Api api = Api(SingleAccountPageState.of(context)?.index ?? 0);
        var result = await ScanPageState.autoInstallFounded(api, found, widget.command!);
        if (result == true) {
          "已安装依赖 $found".toast();
        }
      }
      if (alwaysAuthScroll) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (!mounted) return;
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.linear,
            );
          }
        });
      }
      if (!mounted) return;
      setState(() {});
    } else {
      if (!hasToastedFailed) {
        hasToastedFailed = true;
        response.message.toast();
      }
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final isDark = theme.isDark();
    final primaryColor = theme.primaryColor;
    final titleColor = theme.themeColor.titleColor();
    final descColor = theme.themeColor.descColor();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 自动滚屏开关
          FloatingActionButton.small(
            heroTag: "fab_autoscroll",
            backgroundColor: alwaysAuthScroll ? primaryColor : (isDark ? const Color(0xFF1E2638) : Colors.white),
            foregroundColor: alwaysAuthScroll ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
            elevation: 3,
            tooltip: alwaysAuthScroll ? "暂停自动滚屏" : "开启自动滚屏",
            onPressed: () {
              setState(() {
                alwaysAuthScroll = !alwaysAuthScroll;
              });
              if (alwaysAuthScroll) {
                (alwaysAuthScroll ? "已开启自动滚屏" : "已暂停自动滚屏").toast();
                _scrollToBottom();
              }
            },
            child: Icon(
              alwaysAuthScroll ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              size: 20,
              color: alwaysAuthScroll ? Colors.white : primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          // 回到顶部
          FloatingActionButton.small(
            heroTag: "fab_top",
            backgroundColor: isDark ? const Color(0xFF1E2638) : Colors.white,
            foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
            elevation: 3,
            tooltip: "回到顶部",
            onPressed: _scrollToTop,
            child: const Icon(Icons.arrow_upward_rounded, size: 18),
          ),
          const SizedBox(height: 8),
          // 滚到底部
          FloatingActionButton.small(
            heroTag: "fab_bottom",
            backgroundColor: isDark ? const Color(0xFF1E2638) : Colors.white,
            foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
            elevation: 3,
            tooltip: "滚到底部",
            onPressed: _scrollToBottom,
            child: const Icon(Icons.arrow_downward_rounded, size: 18),
          ),
        ],
      ),
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
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: "刷新",
            onPressed: () {
              getLogData();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 实时状态栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2638) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.needTimer ? const Color(0xFF10B981) : descColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.needTimer ? "实时流监听中 (每2秒刷新)" : "静态日志视图",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.needTimer ? const Color(0xFF10B981) : descColor,
                    ),
                  ),
                  const Spacer(),
                  if (alwaysAuthScroll)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "自动滚动中",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor),
                      ),
                    ),
                ],
              ),
            ),
            // 日志主窗口
            Expanded(
              child: content == null
                  ? const Center(child: LoadingWidget())
                  : content!.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notes_rounded, size: 48, color: descColor.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text("暂无日志内容", style: TextStyle(fontSize: 14, color: descColor)),
                            ],
                          ),
                        )
                      : CupertinoScrollbar(
                          controller: _scrollController,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF020617) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: SelectableText(
                                content!,
                                selectionHeightStyle: BoxHeightStyle.max,
                                selectionWidthStyle: BoxWidthStyle.max,
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
          ],
        ),
      ),
    );
  }

  @override
  void onLazyLoad() {
    alwaysAuthScroll = SpUtil.getBool(spLogAutoJump2Bottom, defValue: false);
    if (widget.needTimer) {
      _timer = Timer.periodic(
        const Duration(seconds: 2),
        (timer) {
          getLogData();
        },
      );
      getLogData();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        getLogData();
      });
    }
  }
}
