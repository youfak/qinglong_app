import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/api.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/others/file_directory_page.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/icloud_utils.dart';
import 'package:qinglong_app/utils/sp_utils.dart';

import '../../base/theme.dart';

class IcloudPage extends ConsumerStatefulWidget {
  const IcloudPage({Key? key}) : super(key: key);

  @override
  ConsumerState<IcloudPage> createState() => _IcloudPageState();
}

class _IcloudPageState extends ConsumerState<IcloudPage>
    with LazyLoadState<IcloudPage> {
  String? fileNum = "-";
  String fileSizes = "-";

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

    return Scaffold(
      backgroundColor: theme.themeColor.bg2Color(),
      appBar: QlAppBar(
        title: "配置与文件备份",
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. 顶部备份概览 Hero 卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CupertinoIcons.cloud_upload_fill,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "自动配置备份",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "变动时自动在本地生成快照",
                            style: TextStyle(fontSize: 12, color: descColor),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.85,
                      child: CupertinoSwitch(
                        activeColor: primaryColor,
                        value: SpUtil.getBool(spICloud, defValue: true),
                        onChanged: (v) {
                          SpUtil.putBool(spICloud, v);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "已备份 $fileNum 个文件 · 占用 $fileSizes",
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: lookUpFiles,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              "浏览文件",
                              style: TextStyle(
                                fontSize: 13,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              CupertinoIcons.chevron_right,
                              size: 14,
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. 环境变量备份
          _buildSectionTitle("环境变量数据", CupertinoIcons.layers_alt, primaryColor, descColor),
          const SizedBox(height: 8),
          _buildModuleCard(
            title: "同步环境变量",
            lastSyncTime: SpUtil.getString(spEnvBackTime, defValue: "从未同步"),
            primaryColor: primaryColor,
            cardBg: cardBg,
            borderColor: borderColor,
            titleColor: titleColor,
            descColor: descColor,
            onSync: () async {
              try {
                var result = await Api(
                        SingleAccountPageState.of(context)!.index)
                    .envs("");
                await getIt<ICloudUtils>(
                        instanceName: SingleAccountPageState.of(context)!
                            .index
                            .toString())
                    .asyncEnv(result.bean ?? [], focusUpdate: true);
                SpUtil.putString(spEnvBackTime, ICloudUtils.now());
                "环境变量备份同步成功".toast();
                setState(() {});
              } catch (_) {}
            },
            onRestore: lookUpFiles,
            onDelete: _handleDeleteBackup,
          ),
          const SizedBox(height: 18),

          // 3. 配置文件备份
          _buildSectionTitle("系统配置文件", CupertinoIcons.doc_plaintext, primaryColor, descColor),
          const SizedBox(height: 8),
          _buildModuleCard(
            title: "同步 config.sh 核心配置",
            lastSyncTime: SpUtil.getString(spConfigBackTime, defValue: "从未同步"),
            primaryColor: primaryColor,
            cardBg: cardBg,
            borderColor: borderColor,
            titleColor: titleColor,
            descColor: descColor,
            onSync: () async {
              HttpResponse<String> result =
                  await SingleAccountPageState.ofApi(context)
                      .content("config.sh");
              if (result.success && result.bean != null) {
                await ICloudUtils(SingleAccountPageState.of(context)!.index)
                    .asyncConfig("config.sh", result.bean ?? "",
                        focusUpdate: true);
                SpUtil.putString(spConfigBackTime, ICloudUtils.now());
                "配置文件备份同步成功".toast();
                setState(() {});
              } else {
                result.message?.toast();
              }
            },
            onRestore: lookUpFiles,
            onDelete: _handleDeleteBackup,
          ),
          const SizedBox(height: 18),

          // 4. 订阅管理备份
          _buildSectionTitle("订阅管理数据", CupertinoIcons.arrow_2_circlepath_circle, primaryColor, descColor),
          const SizedBox(height: 8),
          _buildModuleCard(
            title: "同步订阅配置",
            lastSyncTime: SpUtil.getString(spSubscribeBackTime, defValue: "从未同步"),
            primaryColor: primaryColor,
            cardBg: cardBg,
            borderColor: borderColor,
            titleColor: titleColor,
            descColor: descColor,
            onSync: () async {
              try {
                var result = await Api(
                        SingleAccountPageState.of(context)!.index)
                    .subscribes();
                await getIt<ICloudUtils>(
                        instanceName: SingleAccountPageState.of(context)!
                            .index
                            .toString())
                    .asyncSubscribe(result.bean ?? "", focusUpdate: true);
                SpUtil.putString(spSubscribeBackTime, ICloudUtils.now());
                "订阅管理备份同步成功".toast();
                setState(() {});
              } catch (_) {}
            },
            onRestore: lookUpFiles,
            onDelete: _handleDeleteBackup,
          ),
          const SizedBox(height: 18),

          // 5. 存储策略
          _buildSectionTitle("存储与保留策略", CupertinoIcons.timer, primaryColor, descColor),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _delDuration,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xffF59E0B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.clock,
                          color: Color(0xffF59E0B),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "历史备份保留天数",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "每 ${SpUtil.getInt(spLocalBackUpFileExperiedTime, defValue: getDefaultLogExperiedTime())} 天自动清理超出范围的备份",
                              style: TextStyle(fontSize: 12, color: descColor),
                            ),
                          ],
                        ),
                      ),
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
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      String title, IconData icon, Color primaryColor, Color descColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: descColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String lastSyncTime,
    required Color primaryColor,
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color descColor,
    required VoidCallback onSync,
    required VoidCallback onRestore,
    required VoidCallback onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "上次同步: $lastSyncTime",
                        style: TextStyle(fontSize: 12, color: descColor),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.arrow_2_circlepath, size: 14),
                  label: const Text("即刻同步", style: TextStyle(fontSize: 12)),
                  onPressed: onSync,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16)),
                  onTap: onRestore,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.arrow_counterclockwise,
                              size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            "还原历史备份",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 26, color: borderColor),
              Expanded(
                child: InkWell(
                  borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(16)),
                  onTap: onDelete,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.delete,
                              size: 14, color: descColor),
                          const SizedBox(width: 6),
                          Text(
                            "删除该项备份",
                            style: TextStyle(
                              fontSize: 13,
                              color: descColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleDeleteBackup() {
    if (Platform.isAndroid) {
      "可在下方调整保留天数，或在文件浏览器中删除对应文件".toast2();
      return;
    }
    "请前往「文件」App 中长按手动删除历史备份".toast();
  }

  void _delDuration() {
    TextEditingController controller = TextEditingController(
      text: SpUtil.getInt(spLocalBackUpFileExperiedTime,
              defValue: getDefaultLogExperiedTime())
          .toString(),
    );
    showCupertinoDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("设置备份文件保留天数"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            TextField(
              textAlign: TextAlign.center,
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "保留天数 (1-100)",
                suffixText: "天",
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child:
                const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: Text(
              "确定保存",
              style: TextStyle(
                color: ref.watch(themeProvider).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              int? days = int.tryParse(controller.text);
              if (days == null || days < 1 || days > 100) {
                "有效天数范围为 1 至 100 天".toast();
                return;
              }
              SpUtil.putInt(spLocalBackUpFileExperiedTime, days);
              Navigator.of(context).pop();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  @override
  void onLazyLoad() async {
    try {
      Map<String, int> result = await compute(
          dirStatSync,
          await FileUtil(SingleAccountPageState.of(context)?.index ?? 0)
              .sourcePath);
      fileNum = result["fileNum"].toString();
      fileSizes = getFileSizeString(result["size"] ?? 0, 2);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  static String getFileSizeString(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)}${suffixes[i]}';
  }

  void lookUpFiles() async {
    String path =
        await FileUtil(SingleAccountPageState.of(context)?.index ?? 0)
            .sourcePath;
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => FileDirectoryPage(path: path),
      ),
    );
  }
}

Map<String, int> dirStatSync(String dirPath) {
  int fileNum = 0;
  int totalSize = 0;
  var dir = Directory(dirPath);
  try {
    if (dir.existsSync()) {
      dir.listSync(recursive: true, followLinks: false).forEach((entity) {
        if (entity is File) {
          fileNum++;
          totalSize += entity.lengthSync();
        }
      });
    }
  } catch (_) {}
  return {'fileNum': fileNum, 'size': totalSize};
}
