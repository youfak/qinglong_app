import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/icloud_utils.dart';

import '../../code_editor/editor.dart';

class ScriptCodeDetailPage extends ConsumerStatefulWidget {
  final String title;
  final String content;
  final bool canRestore;
  final String? absPath;

  const ScriptCodeDetailPage({
    Key? key,
    required this.title,
    required this.content,
    this.absPath,
    this.canRestore = false,
  }) : super(key: key);

  @override
  ScriptCodeDetailPageState createState() => ScriptCodeDetailPageState();
}

class ScriptCodeDetailPageState extends ConsumerState<ScriptCodeDetailPage>
    with LazyLoadState<ScriptCodeDetailPage> {
  late CodeMirrorOptions options;
  EditorController? controller;

  int _selectedViewTab = 0; // 0: 可视化卡片视图, 1: 代码/JSON视图
  String? content;

  String getLanguageType(String title) {
    if (title.endsWith(".js") || title.endsWith(".ts")) return 'javascript';
    if (title.endsWith(".sh")) return 'shell';
    if (title.endsWith(".py")) return 'python';
    if (title.endsWith(".json") || title.endsWith(".env") || title.endsWith(".subscribe")) return 'json';
    if (title.endsWith(".yaml")) return 'yaml';
    return "shell";
  }

  bool isJsonFile() {
    return (widget.absPath?.endsWith(".${FileUtil.env}") ?? false) ||
        (widget.absPath?.endsWith(".${FileUtil.subscribe}") ?? false) ||
        widget.title.endsWith(".json");
  }

  String getPrettyJSONString() {
    try {
      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      return encoder.convert(jsonDecode(content ?? "[]"));
    } catch (_) {
      return content ?? "";
    }
  }

  List<dynamic> _parseJsonList() {
    try {
      final decoded = jsonDecode(content ?? "[]");
      if (decoded is List) return decoded;
      if (decoded is Map) return [decoded];
    } catch (_) {}
    return [];
  }

  String _getBackupTypeLabel() {
    if (widget.title.endsWith(".${FileUtil.env}")) return "环境变量备份";
    if (widget.title.endsWith(".${FileUtil.subscribe}")) return "订阅管理备份";
    if (widget.title.endsWith(".${FileUtil.config}")) return "系统配置备份";
    if (widget.title.endsWith(".sh")) return "Shell 脚本";
    return "历史备份文件";
  }

  Color _getBackupColor() {
    if (widget.title.endsWith(".${FileUtil.env}")) return const Color(0xFF10B981);
    if (widget.title.endsWith(".${FileUtil.subscribe}")) return const Color(0xFF0EA5E9);
    if (widget.title.endsWith(".${FileUtil.config}")) return const Color(0xFF8B5CF6);
    return const Color(0xFFF59E0B);
  }

  IconData _getBackupIcon() {
    if (widget.title.endsWith(".${FileUtil.env}")) return Icons.tune_rounded;
    if (widget.title.endsWith(".${FileUtil.subscribe}")) return Icons.sync_alt_rounded;
    if (widget.title.endsWith(".${FileUtil.config}")) return Icons.description_rounded;
    return Icons.insert_drive_file_outlined;
  }

  @override
  void initState() {
    super.initState();
    options = CodeMirrorOptions(
      readOnly: true,
      mode: getLanguageType(widget.title),
    );
  }

  @override
  void onLazyLoad() {
    content = widget.content;
    setState(() {});
  }

  void _showRestoreConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || ref.read(themeProvider).isDark();
    final theme = ref.read(themeProvider);
    final primaryColor = theme.primaryColor;
    final cardBg = isDark ? const Color(0xFF1E2638) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final descColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    final typeLabel = _getBackupTypeLabel();
    final jsonList = isJsonFile() ? _parseJsonList() : [];
    final countText = jsonList.isNotEmpty ? "包含 ${jsonList.length} 条数据" : "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          bottom: true,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: descColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getBackupColor().withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getBackupIcon(), color: _getBackupColor(), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "确认还原 $typeLabel",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                color: descColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "还原操作将会使用此备份文件覆盖当前青龙服务器上的相应数据，此操作不可撤销。$countText",
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: Text(
                            "取消",
                            style: TextStyle(color: descColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.restore_rounded, size: 18),
                          label: const Text(
                            "确认立即还原",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            Navigator.of(sheetContext).pop();
                            _executeRestore();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _executeRestore() async {
    final accountIndex = (SingleAccountPageState.of(context)?.index ?? 0).toString();
    EasyLoading.show(status: "正在还原备份...");
    try {
      if (widget.title.endsWith(".${FileUtil.env}")) {
        getIt<ICloudUtils>(instanceName: accountIndex).restoreEnv(widget.absPath!);
      } else if (widget.title.endsWith(".${FileUtil.config}")) {
        getIt<ICloudUtils>(instanceName: accountIndex).restoreConfig(widget.absPath!);
      } else if (widget.title.endsWith(".${FileUtil.subscribe}")) {
        getIt<ICloudUtils>(instanceName: accountIndex).restoreSubscribe(widget.absPath!);
      } else {
        "不支持直接还原该类型文件".toast();
      }
    } catch (e) {
      e.toString().toast();
    } finally {
      EasyLoading.dismiss();
    }
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

    return Scaffold(
      backgroundColor: theme.themeColor.bg2Color(),
      appBar: QlAppBar(
        canBack: true,
        title: widget.title,
        actions: [
          if (widget.canRestore)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    minimumSize: Size.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text(
                    "还原",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showRestoreConfirmation(context),
                ),
              ),
            ),
        ],
      ),
      body: content == null
          ? const Center(child: LoadingWidget())
          : Column(
              children: [
                // 顶部信息条
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: isDark ? const Color(0xFF131B2E) : Colors.white,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getBackupColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getBackupIcon(), size: 14, color: _getBackupColor()),
                            const SizedBox(width: 4),
                            Text(
                              _getBackupTypeLabel(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getBackupColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (isJsonFile()) ...[
                        Text(
                          "共 ${_parseJsonList().length} 条数据",
                          style: TextStyle(fontSize: 12, color: descColor),
                        ),
                      ],
                      const Spacer(),
                      // 视图切换按钮 (仅针对 JSON 文件)
                      if (isJsonFile())
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              _buildViewTabItem(0, "卡片视图", isDark, primaryColor, descColor),
                              _buildViewTabItem(1, "JSON代码", isDark, primaryColor, descColor),
                            ],
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: "复制内容",
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: content ?? ""));
                            "已复制到剪贴板".toast();
                          },
                        ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),

                // 内容渲染
                Expanded(
                  child: isJsonFile()
                      ? (_selectedViewTab == 0
                          ? _buildJsonVisualList(_parseJsonList(), isDark, cardBg, titleColor, descColor, borderColor, primaryColor)
                          : _buildCodeView())
                      : _buildCodeView(),
                ),
              ],
            ),
    );
  }

  Widget _buildViewTabItem(int index, String label, bool isDark, Color primaryColor, Color descColor) {
    final isSelected = _selectedViewTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedViewTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : descColor,
          ),
        ),
      ),
    );
  }

  Widget _buildJsonVisualList(
    List<dynamic> items,
    bool isDark,
    Color cardBg,
    Color titleColor,
    Color descColor,
    Color borderColor,
    Color primaryColor,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Text("暂无数据或数据格式不匹配", style: TextStyle(color: descColor)),
      );
    }

    final isEnv = widget.title.endsWith(".${FileUtil.env}");

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is! Map) return const SizedBox.shrink();

        if (isEnv) {
          final name = item["name"]?.toString() ?? "";
          final value = item["value"]?.toString() ?? "";
          final remarks = item["remarks"]?.toString() ?? "";
          final isDisabled = item["status"] == 1 || item["status"] == "1";

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: titleColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDisabled ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDisabled ? "已禁用" : "已启用",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isDisabled ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontFamily: 'monospace',
                            color: titleColor.withOpacity(0.85),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: value));
                          "已复制变量值".toast();
                        },
                        child: Icon(Icons.copy_rounded, size: 14, color: descColor),
                      ),
                    ],
                  ),
                ),
                if (remarks.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    remarks,
                    style: TextStyle(fontSize: 11.5, color: descColor),
                  ),
                ],
              ],
            ),
          );
        } else {
          // 订阅管理项目
          final name = item["name"]?.toString() ?? "";
          final url = item["url"]?.toString() ?? "";
          final schedule = item["schedule"]?.toString() ?? "";

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      url,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: descColor,
                      ),
                    ),
                  ),
                ],
                if (schedule.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        schedule,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildCodeView() {
    return Editor(
      options: options,
      onCreate: (val) {
        controller = val;
        controller?.setOptions(options);
        controller?.setValue(isJsonFile() ? getPrettyJSONString() : (content ?? ""));
      },
      onValue: (val) {},
    );
  }
}
