import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:intl/intl.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/icloud_utils.dart';

class IcloudFilePage extends ConsumerStatefulWidget {
  const IcloudFilePage({Key? key}) : super(key: key);

  @override
  _IcloudFilePageState createState() => _IcloudFilePageState();
}

class _IcloudFilePageState extends ConsumerState<IcloudFilePage> {
  List<ICloudFile> list = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getFiles();
  }

  void getFiles() async {
    setState(() => isLoading = true);
    try {
      final iCloudStorage = await ICloudStorage.getInstance(ICloudUtils.containerID);
      final fileList = await iCloudStorage.gatherFiles(onUpdate: (stream) {});
      list.clear();
      list.addAll(fileList);
    } catch (e) {
      e.toString().toast();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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

  Color _getFileColor(String path) {
    if (path.contains("env")) return const Color(0xFF10B981);
    if (path.contains("subscribe")) return const Color(0xFF0EA5E9);
    if (path.contains("config")) return const Color(0xFF8B5CF6);
    return const Color(0xFFF59E0B);
  }

  IconData _getFileIcon(String path) {
    if (path.contains("env")) return Icons.tune_rounded;
    if (path.contains("subscribe")) return Icons.sync_alt_rounded;
    if (path.contains("config")) return Icons.description_rounded;
    return Icons.cloud_queue_rounded;
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
        title: "iCloud 云端备份",
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, size: 20),
            tooltip: "刷新",
            onPressed: getFiles,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 64,
                        color: descColor.withOpacity(0.35),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "未找到 iCloud 备份文件",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "请确认系统已登录 Apple ID 并允许 iCloud 访问",
                        style: TextStyle(fontSize: 13, color: descColor),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final fileColor = _getFileColor(item.relativePath);
                    final fileIcon = _getFileIcon(item.relativePath);

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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: fileColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(fileIcon, size: 22, color: fileColor),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.relativePath,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      if (item.contentChangeDate != null) ...[
                                        Icon(Icons.access_time_rounded, size: 12, color: descColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(item.contentChangeDate!),
                                          style: TextStyle(fontSize: 11, color: descColor),
                                        ),
                                        const SizedBox(width: 10),
                                        Text("•", style: TextStyle(fontSize: 11, color: descColor)),
                                        const SizedBox(width: 10),
                                      ],
                                      Text(
                                        _formatFileSize(item.sizeInBytes ?? 0),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: descColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              tooltip: "复制路径",
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: item.relativePath));
                                "已复制文件路径".toast();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
