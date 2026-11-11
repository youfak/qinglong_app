import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../../base/theme.dart';
import 'scripts/script_code_detail_page.dart';

class FileDirectoryPage extends ConsumerStatefulWidget {
  final String path;
  final String? title;

  const FileDirectoryPage({
    Key? key,
    required this.path,
    this.title,
  }) : super(key: key);

  @override
  ConsumerState<FileDirectoryPage> createState() => _FileDirectoryPageState();
}

class _FileDirectoryPageState extends ConsumerState<FileDirectoryPage> {
  List<FileSystemEntity> entities = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    readFiles();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void readFiles() async {
    try {
      final dir = Directory(widget.path);
      if (await dir.exists()) {
        final list = dir.listSync();
        // 目录排前面，文件排后面，按时间倒序
        list.sort((a, b) {
          final isDirA = a is Directory;
          final isDirB = b is Directory;
          if (isDirA && !isDirB) return -1;
          if (!isDirA && isDirB) return 1;
          try {
            return b.statSync().modified.compareTo(a.statSync().modified);
          } catch (_) {
            return 0;
          }
        });
        entities = list;
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDate(DateTime date) {
    return DateFormat("yyyy-MM-dd HH:mm").format(date);
  }

  String _getFriendlyName(String name) {
    if (name == "env") return "环境变量备份目录";
    if (name == "subscribe") return "订阅数据备份目录";
    if (name == "config") return "配置文件备份目录";
    if (name == "download_files") return "下载文件目录";
    return name;
  }

  Color _getItemColor(String name, bool isDir) {
    if (isDir) {
      if (name == "env") return const Color(0xFF10B981);
      if (name == "subscribe") return const Color(0xFF0EA5E9);
      if (name == "config") return const Color(0xFF8B5CF6);
      return const Color(0xFFF59E0B);
    }
    if (name.endsWith(".env")) return const Color(0xFF10B981);
    if (name.endsWith(".subscribe")) return const Color(0xFF0EA5E9);
    if (name.endsWith(".config") || name.endsWith(".sh")) return const Color(0xFF8B5CF6);
    if (name.endsWith(".js") || name.endsWith(".py")) return const Color(0xFFF59E0B);
    return const Color(0xFF64748B);
  }

  IconData _getItemIcon(String name, bool isDir) {
    if (isDir) {
      if (name == "env") return Icons.tune_rounded;
      if (name == "subscribe") return Icons.sync_alt_rounded;
      if (name == "config") return Icons.description_rounded;
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(name)) return Icons.calendar_month_rounded;
      return Icons.folder_rounded;
    }
    if (name.endsWith(".env")) return Icons.tune_rounded;
    if (name.endsWith(".subscribe")) return Icons.sync_alt_rounded;
    if (name.endsWith(".config")) return Icons.description_rounded;
    if (name.endsWith(".sh")) return Icons.terminal_rounded;
    if (name.endsWith(".js") || name.endsWith(".py")) return Icons.code_rounded;
    return Icons.insert_drive_file_outlined;
  }

  String _getTypeLabel(String name, bool isDir) {
    if (isDir) return "目录";
    if (name.endsWith(".env")) return "环境变量备份";
    if (name.endsWith(".subscribe")) return "订阅管理备份";
    if (name.endsWith(".config")) return "配置文件备份";
    if (name.endsWith(".sh")) return "Shell脚本";
    return "备份文件";
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

    final folderName = p.basename(widget.path);
    final displayTitle = widget.title ?? (folderName.isEmpty ? "历史备份" : _getFriendlyName(folderName));

    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? entities
        : entities.where((e) => p.basename(e.path).toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: theme.themeColor.bg2Color(),
      appBar: QlAppBar(
        canBack: true,
        title: displayTitle,
      ),
      body: Column(
        children: [
          // 搜索与统计栏
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
                            controller: _searchController,
                            style: TextStyle(fontSize: 14, color: titleColor),
                            decoration: InputDecoration(
                              hintText: "搜索备份文件...",
                              hintStyle: TextStyle(fontSize: 13, color: descColor.withOpacity(0.6)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () => _searchController.clear(),
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
                    "${filtered.length} 项",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // 列表区域
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off_outlined, size: 56, color: descColor.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          query.isNotEmpty ? "未找到匹配项" : "该目录下暂无备份文件",
                          style: TextStyle(fontSize: 14, color: descColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entity = filtered[index];
                      final isDir = entity is Directory;
                      final baseName = p.basename(entity.path);
                      final friendlyName = _getFriendlyName(baseName);
                      final itemColor = _getItemColor(baseName, isDir);
                      final iconData = _getItemIcon(baseName, isDir);
                      final typeLabel = _getTypeLabel(baseName, isDir);

                      FileStat? stat;
                      try {
                        stat = entity.statSync();
                      } catch (_) {}

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              if (isDir) {
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => FileDirectoryPage(
                                      path: entity.path,
                                      title: friendlyName,
                                    ),
                                  ),
                                );
                              } else {
                                try {
                                  String content = await File(entity.path).readAsString();
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) => ScriptCodeDetailPage(
                                        title: baseName,
                                        content: content,
                                        absPath: entity.path,
                                        canRestore: true,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  e.toString().toast();
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: itemColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(iconData, size: 22, color: itemColor),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                friendlyName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: isDir ? null : 'monospace',
                                                  color: titleColor,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: itemColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                typeLabel,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: itemColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            if (stat != null) ...[
                                              Icon(Icons.access_time_rounded, size: 12, color: descColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(stat.modified),
                                                style: TextStyle(fontSize: 11, color: descColor),
                                              ),
                                              if (!isDir) ...[
                                                const SizedBox(width: 10),
                                                Text("•", style: TextStyle(fontSize: 11, color: descColor)),
                                                const SizedBox(width: 10),
                                                Text(
                                                  _formatFileSize(stat.size),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: descColor,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 16,
                                    color: descColor.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
