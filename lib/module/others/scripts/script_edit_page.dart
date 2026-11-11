import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../../code_editor/codemirror/io.dart';
import '../../code_editor/editor.dart';
import '../../config/config_detail_page.dart';

class ScriptEditPage extends ConsumerStatefulWidget {
  final String content;
  final String title;
  final String path;

  const ScriptEditPage(
    this.title,
    String? path,
    String? content, {
    Key? key,
  })  : path = path ?? "",
        content = content ?? "",
        super(key: key);

  @override
  _ScriptEditPageState createState() => _ScriptEditPageState();
}

class _ScriptEditPageState extends ConsumerState<ScriptEditPage> {
  late String result;
  late String preResult;
  late CodeMirrorOptions options;
  EditorController? controller;

  bool _isSearching = false;
  final TextEditingController _searchQueryController = TextEditingController();
  int _searchMatchCount = 0;
  int _searchCurrentIndex = -1;

  String getLanguageType(String title) {
    if (title.endsWith(".js") || title.endsWith(".ts")) return 'javascript';
    if (title.endsWith(".sh")) return 'shell';
    if (title.endsWith(".py")) return 'python';
    if (title.endsWith(".json")) return 'shell';
    if (title.endsWith(".yaml")) return 'yaml';
    return "shell";
  }

  @override
  void dispose() {
    _searchQueryController.dispose();
    EasyLoading.dismiss();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    options = CodeMirrorOptions().copyWith(
      readOnly: false,
      mode: getLanguageType(widget.title),
    );

    result = widget.content;
    preResult = widget.content;
  }

  Future<void> hideKeyboardFocus() async {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<bool> _confirmExit() async {
    if (result == preResult) return true;

    final shouldPop = await showCupertinoDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (childContext) => CupertinoAlertDialog(
        title: const Text("未保存提示"),
        content: const Text("脚本内容已修改，退出将丢失本次编辑，确定退出吗？"),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(childContext).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("放弃修改"),
            onPressed: () => Navigator.of(childContext).pop(true),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _showMoreMenu() {
    final theme = ref.read(themeProvider);
    final cardBg = theme.themeColor.settingBgColor();
    final titleColor = theme.themeColor.titleColor();
    final descColor = theme.themeColor.descColor();
    final primaryColor = theme.primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(CupertinoIcons.doc_on_clipboard,
                      color: primaryColor),
                  title: Text("复制全部脚本内容",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: titleColor)),
                  subtitle: Text("将当前完整代码复制至剪切板",
                      style: TextStyle(fontSize: 12, color: descColor)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Clipboard.setData(ClipboardData(text: result));
                    "已复制全部代码到剪切板".toast();
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.arrow_counterclockwise,
                      color: Color(0xffF59E0B)),
                  title: Text("还原为上次保存内容",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: titleColor)),
                  subtitle: Text("放弃所有未提交的代码变更",
                      style: TextStyle(fontSize: 12, color: descColor)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      result = preResult;
                      controller?.setValue(preResult);
                    });
                    "已还原为初始内容".toast();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        backgroundColor: theme.themeColor.codeBgColor(),
        appBar: QlAppBar(
          canBack: true,
          backCall: () async {
            if (await _confirmExit()) {
              Navigator.of(context).pop();
            }
          },
          title: widget.title,
          actions: [
            // 搜索切换按钮
            IconButton(
              tooltip: "搜索查找",
              icon: Icon(
                _isSearching
                    ? CupertinoIcons.search_circle_fill
                    : CupertinoIcons.search,
                color: _isSearching ? primaryColor : null,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchQueryController.clear();
                    controller?.clearSearch?.call();
                    _searchMatchCount = 0;
                    _searchCurrentIndex = -1;
                  }
                });
              },
            ),
            // 更多操作按钮
            IconButton(
              tooltip: "更多操作",
              icon: const Icon(CupertinoIcons.ellipsis_circle, size: 22),
              onPressed: _showMoreMenu,
            ),
            // 提交按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  try {
                    await hideKeyboardFocus();
                    EasyLoading.show(status: "保存中...");
                    HttpResponse<NullResponse> response =
                        await SingleAccountPageState.ofApi(context)
                            .updateScript(widget.title, widget.path, result);
                    EasyLoading.dismiss();
                    if (response.success) {
                      preResult = result;
                      "保存成功".toast();
                      Navigator.of(context).pop(result);
                    } else {
                      (response.message ?? "保存失败").toast();
                    }
                  } catch (e) {
                    EasyLoading.dismiss();
                  }
                },
                child: const Text(
                  "保存",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // 原生 M3 搜索控制栏
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isSearching
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(bottom: BorderSide(color: borderColor)),
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
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchQueryController,
                          autofocus: true,
                          style: TextStyle(fontSize: 13.5, color: titleColor),
                          decoration: InputDecoration(
                            hintText: "在代码中查找...",
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: descColor.withOpacity(0.6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            prefixIcon: Icon(CupertinoIcons.search,
                                size: 16, color: descColor),
                            suffixIcon: _searchQueryController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchQueryController.clear();
                                      controller?.clearSearch?.call();
                                      setState(() {
                                        _searchMatchCount = 0;
                                        _searchCurrentIndex = -1;
                                      });
                                    },
                                    child: Icon(CupertinoIcons.clear_circled,
                                        size: 16, color: descColor),
                                  )
                                : null,
                          ),
                          onChanged: (text) {
                            controller?.doSearch?.call(text);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 匹配计数指示
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _searchMatchCount > 0
                            ? primaryColor.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _searchMatchCount > 0
                            ? "${_searchCurrentIndex + 1}/$_searchMatchCount"
                            : (_searchQueryController.text.isEmpty
                                ? ""
                                : "无匹配"),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _searchMatchCount > 0 ? primaryColor : descColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.chevron_up),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      color: _searchMatchCount > 0
                          ? titleColor
                          : descColor.withOpacity(0.3),
                      onPressed: _searchMatchCount > 0
                          ? () => controller?.searchPrev?.call()
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.chevron_down),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      color: _searchMatchCount > 0
                          ? titleColor
                          : descColor.withOpacity(0.3),
                      onPressed: _searchMatchCount > 0
                          ? () => controller?.searchNext?.call()
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark),
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      color: descColor,
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchQueryController.clear();
                          controller?.clearSearch?.call();
                          _searchMatchCount = 0;
                          _searchCurrentIndex = -1;
                        });
                      },
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),

            // 代码编辑视图
            Expanded(
              child: SafeArea(
                top: false,
                child: Editor(
                  codeMirrorKey: codeKey,
                  options: options,
                  onSearchResult: (count, index) {
                    setState(() {
                      _searchMatchCount = count;
                      _searchCurrentIndex = index;
                    });
                  },
                  onCreate: (val) {
                    controller = val;
                    controller?.setOptions(options);
                    controller?.setValue(result);
                  },
                  onValue: (val) {
                    result = val;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  GlobalKey<CodeMirrorViewState> codeKey = GlobalKey();
}
