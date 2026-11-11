import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/config/config_detail_page.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/icloud_utils.dart';
import 'package:qinglong_app/utils/sp_utils.dart';

import '../../base/sp_const.dart';
import '../code_editor/codemirror/io.dart';
import '../code_editor/editor.dart';

class ConfigEditPage extends ConsumerStatefulWidget {
  final String content;
  final String title;

  const ConfigEditPage(this.title, this.content, {Key? key}) : super(key: key);

  @override
  _ConfigEditPageState createState() => _ConfigEditPageState();
}

class _ConfigEditPageState extends ConsumerState<ConfigEditPage> {
  CodeMirrorOptions options = CodeMirrorOptions();
  EditorController? controller;
  late String result;
  late String preResult;
  List<String> operateList = [];

  bool _isSearching = false;
  final TextEditingController _searchQueryController = TextEditingController();
  int _searchMatchCount = 0;
  int _searchCurrentIndex = -1;

  FocusNode focusNode = FocusNode();
  GlobalKey<CodeMirrorViewState> codeKey = GlobalKey();

  @override
  void dispose() {
    _searchQueryController.dispose();
    EasyLoading.dismiss();
    MultiAccountPageState.clearAction();
    super.dispose();
  }

  @override
  void initState() {
    result = widget.content;
    preResult = widget.content;
    super.initState();
    generateOperateList();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      focusNode.requestFocus();
      checkClipBoard();
    });
  }

  Future<void> notifyICloud(
      BuildContext context, String? title, String? content) async {
    await getIt<ICloudUtils>(
            instanceName:
                SingleAccountPageState.of(context)?.index.toString() ?? "0")
        .asyncConfig(title, content);
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
        content: const Text("配置内容已修改，退出将丢失本次变更，确定退出吗？"),
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
                if (operateList.isNotEmpty)
                  ListTile(
                    leading: Icon(CupertinoIcons.slider_horizontal_3,
                        color: primaryColor),
                    title: Text("快速修改 Export 环境变量 (${operateList.length})",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: titleColor)),
                    subtitle: Text("直观查看并修改文件中声明的环境变量",
                        style: TextStyle(fontSize: 12, color: descColor)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showExportPicker();
                    },
                  ),
                ListTile(
                  leading: Icon(CupertinoIcons.doc_on_clipboard,
                      color: primaryColor),
                  title: Text("复制全部配置内容",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: titleColor)),
                  subtitle: Text("将当前完整配置代码复制至剪切板",
                      style: TextStyle(fontSize: 12, color: descColor)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Clipboard.setData(ClipboardData(text: result));
                    "已复制全部配置到剪切板".toast();
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
                  subtitle: Text("放弃所有未提交的配置变更",
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

  void _showExportPicker() {
    final theme = ref.read(themeProvider);
    final cardBg = theme.themeColor.settingBgColor();
    final titleColor = theme.themeColor.titleColor();
    final descColor = theme.themeColor.descColor();
    final primaryColor = theme.primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Text("选择要修改的变量",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: titleColor)),
                    const Spacer(),
                    Text("${operateList.length} 项",
                        style: TextStyle(fontSize: 12, color: descColor)),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
              Expanded(
                child: ListView.separated(
                  itemCount: operateList.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, indent: 20, color: Colors.grey.withOpacity(0.08)),
                  itemBuilder: (context, index) {
                    final keyName = operateList[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(CupertinoIcons.tag_fill,
                          size: 16, color: primaryColor),
                      title: Text(keyName,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: titleColor)),
                      trailing: Icon(CupertinoIcons.pencil,
                          size: 16, color: descColor),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        updateValueBykey(keyName);
                      },
                    );
                  },
                ),
              ),
            ],
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
          title: '编辑${widget.title}',
          actions: [
            // 搜索按钮
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
            // 保存按钮
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
                            .saveFile(widget.title, result);
                    if (Platform.isIOS) {
                      await notifyICloud(context, widget.title, result);
                    }
                    EasyLoading.dismiss();
                    if (response.success) {
                      preResult = result;
                      generateOperateList();
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
                            hintText: "在配置中查找...",
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

  void generateOperateList() {
    operateList.clear();
    List<String> array = result.split("\n");
    for (String a in array) {
      String t = a.replaceAll(" ", "");
      if (t.trim().startsWith("export")) {
        try {
          int i = t.indexOf("export") + 6;
          int j = t.indexOf("=");
          if (j > i) {
            operateList.add(t.substring(i, j));
          }
        } catch (_) {}
      }
    }
  }

  void updateValueBykey(String key) async {
    String defaultValue = "";
    try {
      var clipBoard = await Clipboard.getData(Clipboard.kTextPlain);

      if (clipBoard != null && clipBoard.text != null) {
        String tempText = clipBoard.text!;

        if (tempText.trim().contains("export")) {
          int i = tempText.trim().indexOf("\"");
          int j = tempText.trim().lastIndexOf("\"");

          if (i == -1 || j == -1) {
            i = tempText.trim().indexOf("'");
            j = tempText.trim().lastIndexOf("'");
          }

          if (i >= 0 && j > i) {
            defaultValue = tempText.trim().substring(i + 1, j);
          }
        } else {
          defaultValue = tempText;
        }
      }
    } catch (_) {}

    TextEditingController textController = TextEditingController(
        text: defaultValue.replaceAll("\"", "").replaceAll("'", ""));

    showCupertinoDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text("修改环境变量 $key"),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: textController,
            placeholder: "请输入新的值",
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: Text(
              "确定更新",
              style: TextStyle(
                color: ref.watch(themeProvider).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              updateValueByKey(key, textController.text);
            },
          ),
        ],
      ),
    );
  }

  void updateValueByKey(String key, String value) {
    List<String> array = result.split("\n");
    int line = 0;
    for (String a in array) {
      String t = a.replaceAll(" ", "");
      if (t.trim().startsWith("export$key=")) {
        array[line] = "export $key=\"$value\"";
        break;
      }
      line++;
    }
    result = array.join("\n");
    controller?.setValue(result);
    "已在代码中更新 $key".toast();
  }

  void checkClipBoard() async {
    try {
      var clipBoard = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipBoard != null && clipBoard.text != null) {
        String text = clipBoard.text!;
        if (text.trim().startsWith("export")) {
          String key = text.split("=").first.replaceAll("export", "").trim();
          if (operateList.contains(key)) {
            showCupertinoDialog(
              useRootNavigator: false,
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text("检测到剪切板变量"),
                content: Text("检测到环境变量 $key，是否直接替换文件中的值？"),
                actions: [
                  CupertinoDialogAction(
                    child: const Text("取消",
                        style: TextStyle(color: Color(0xff999999))),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoDialogAction(
                    child: Text(
                      "替换",
                      style: TextStyle(
                        color: ref.watch(themeProvider).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      updateValueBykey(key);
                    },
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (_) {}
  }
}
