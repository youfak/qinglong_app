import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/base/ui/tree/models/script_data.dart';
import 'package:qinglong_app/module/others/scripts/folder_add_page.dart';
import 'package:qinglong_app/module/others/scripts/script_upload_page.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../../../base/cupertino_sheet.dart';
import '../../../base/ui/tree/tree_view.dart';
import '../../../base/ui/tree/tree_view_controller.dart';
import '../../../main.dart';
import '../../home/system_bean.dart';

class ScriptPage extends ConsumerStatefulWidget {
  const ScriptPage({Key? key}) : super(key: key);

  @override
  _ScriptPageState createState() => _ScriptPageState();
}

class _ScriptPageState extends ConsumerState<ScriptPage> with LazyLoadState<ScriptPage> {
  List<ScriptData> list = [];
  String? path;

  final ScrollController controller = ScrollController();
  final TextEditingController searchText = TextEditingController();

  bool buttonshow = false;
  late TreeViewController _treeViewController;

  void scrollToTop() {
    controller.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }

  @override
  void initState() {
    super.initState();
    _treeViewController = TreeViewController(children: []);
    controller.addListener(floatingButtonVisibility);
    searchText.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    searchText.dispose();
    super.dispose();
  }

  void floatingButtonVisibility() {
    double y = controller.offset;
    if (y > 500) {
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

  List<ScriptData> _filterScripts(List<ScriptData> nodes, String query) {
    List<ScriptData> result = [];
    final lower = query.toLowerCase();
    void traverse(List<ScriptData> currentNodes) {
      for (var node in currentNodes) {
        if (!node.isParent) {
          if (node.title.toLowerCase().contains(lower) || node.parent.toLowerCase().contains(lower)) {
            result.add(node);
          }
        }
        if (node.children.isNotEmpty) {
          traverse(node.children);
        }
      }
    }

    traverse(nodes);
    return result;
  }

  IconData _getFileIcon(String title) {
    final ext = title.contains('.') ? title.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'js':
      case 'jsx':
      case 'ts':
      case 'tsx':
        return Icons.javascript_rounded;
      case 'py':
        return Icons.terminal_rounded;
      case 'sh':
      case 'bash':
        return Icons.terminal_rounded;
      case 'json':
        return Icons.data_object_rounded;
      case 'log':
      case 'txt':
        return Icons.article_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileColor(String title) {
    final ext = title.contains('.') ? title.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'js':
      case 'jsx':
      case 'ts':
      case 'tsx':
        return const Color(0xFFEAB308);
      case 'py':
        return const Color(0xFF3B82F6);
      case 'sh':
      case 'bash':
        return const Color(0xFF10B981);
      case 'json':
        return const Color(0xFFF97316);
      case 'log':
      case 'txt':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || ref.watch(themeProvider).isDark();
    final primaryColor = ref.watch(themeProvider).primaryColor;
    final query = searchText.text.trim();
    final searchResults = query.isNotEmpty ? _filterScripts(list, query) : <ScriptData>[];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (_) {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
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
          backCall: () {
            Navigator.of(context).pop();
          },
          title: "脚本管理",
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.add, size: 22),
              tooltip: "新建",
              onPressed: () {
                showMoreOperate(
                  context,
                  [
                    CupertinoSheer(
                      title: "新增文件",
                      icon: Icons.note_add_outlined,
                      onTap: () {
                        addScript();
                      },
                    ),
                    addDivider(),
                    CupertinoSheer(
                      title: "新增文件夹",
                      icon: Icons.create_new_folder_outlined,
                      onTap: () {
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
                        addFloder();
                      },
                    )
                  ],
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Modern Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchText,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: "搜索脚本名称或路径...",
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (searchText.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => searchText.clear(),
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Body Content
            Expanded(
              child: list.isEmpty
                  ? const Center(
                      child: LoadingWidget(),
                    )
                  : query.isNotEmpty
                      ? _buildSearchResults(searchResults, isDark)
                      : RefreshIndicator(
                          color: primaryColor,
                          onRefresh: () async {
                            await loadData();
                            return Future.value();
                          },
                          child: TreeView(
                            controller: _treeViewController,
                            onExpansionChanged: (key, state) {
                              ScriptData? node = _treeViewController.getNode(key);
                              if (node != null) {
                                List<ScriptData> updated = _treeViewController.updateNode(key, node.copyWith(expanded: !node.expanded));
                                setState(() {
                                  _treeViewController = _treeViewController.copyWith(children: updated);
                                });
                              }
                            },
                            onDeleteSelfClick: (ScriptData data) {
                              _showDeleteConfirmDialog(data);
                            },
                            onNodeTap: (key) {
                              ScriptData? selectedNode = _treeViewController.getNode(key);
                              Navigator.of(context).pushNamed(
                                Routes.routeScriptDetail,
                                arguments: {
                                  "title": selectedNode?.title,
                                  "path": selectedNode?.parent,
                                },
                              ).then(
                                (value) {
                                  if (value != null && value == true) {
                                    loadData();
                                  }
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<ScriptData> results, bool isDark) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              "未找到匹配的脚本",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        final fileColor = _getFileColor(item.title);
        final fileIcon = _getFileIcon(item.title);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2638) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).pushNamed(
                  Routes.routeScriptDetail,
                  arguments: {
                    "title": item.title,
                    "path": item.parent,
                  },
                ).then((value) {
                  if (value != null && value == true) {
                    loadData();
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: fileColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(fileIcon, size: 20, color: fileColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (item.parent.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 13,
                                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.parent,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(ScriptData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark || ref.watch(themeProvider).isDark();
    showDialog(
      context: context,
      builder: (context1) => AlertDialog(
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
            const Text(
              "确认删除",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          "确定要删除 \"${data.title}\" 吗？此操作无法撤销。",
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context1).pop(),
            child: Text(
              "取消",
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(context1).pop();
              deleteFold(data);
            },
            child: const Text("删除", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> loadData() async {
    HttpResponse<List<ScriptData>> response = await SingleAccountPageState.ofApi(context).scripts();

    if (response.success) {
      if (response.bean == null || response.bean!.isEmpty) {
        "暂无数据".toast();
      }
      list.clear();
      response.bean?.removeWhere((element) => element.title == "node_modules");
      list.addAll(response.bean ?? []);
      _treeViewController = TreeViewController(children: list);
      if (mounted) setState(() {});
    } else {
      response.message?.toast();
    }
  }

  @override
  void onLazyLoad() {
    loadData();
  }

  void addScript() {
    Navigator.of(context)
        .push(
      CupertinoPageRoute(
        builder: (context) => const ScriptUploadPage(),
      ),
    )
        .then((value) {
      if (value != null && value == true) {
        loadData();
      }
    });
  }

  void addFloder() {
    Navigator.of(context)
        .push(
      CupertinoPageRoute(
        builder: (context) => const FloderAddPage(),
      ),
    )
        .then((value) {
      if (value != null && value == true) {
        loadData();
      }
    });
  }

  void deleteFold(ScriptData item) async {
    SystemBean? systemBean;

    try {
      systemBean = getIt<SystemBean>(instanceName: (SingleAccountPageState.of(context)?.index ?? 0).toString());
    } catch (e) {
      systemBean = SystemBean(version: "2.10.13", fromAutoGet: false);
    }
    if ((item.children.isNotEmpty) && !systemBean.isUpperVersion2_14_5()) {
      "该功能仅支持v2.14.5及以上版本".toast();
      return;
    }

    EasyLoading.show(status: "删除中...");
    var temp = (item.type == "directory")
        ? await SingleAccountPageState.ofApi(context).delScriptFold(
            item.title,
            item.parent,
          )
        : (systemBean.isUpperVersion2_14_5()
            ? await SingleAccountPageState.ofApi(context).delScriptNewVersion(
                item.title,
                item.parent,
              )
            : await SingleAccountPageState.ofApi(context).delScript(
                item.title,
                item.parent,
              ));
    EasyLoading.dismiss();
    if (temp.success) {
      "已删除".toast();
      await loadData();
    } else {
      temp.message.toast();
    }
  }
}
