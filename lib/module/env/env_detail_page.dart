import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/module/env/add_env_page.dart';
import 'package:qinglong_app/module/env/env_bean.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

class EnvDetailPage extends ConsumerStatefulWidget {
  final EnvBean envBean;

  const EnvDetailPage(this.envBean, {Key? key}) : super(key: key);

  @override
  _EnvDetailPageState createState() => _EnvDetailPageState();
}

class _EnvDetailPageState extends ConsumerState<EnvDetailPage> {
  late EnvBean currentEnv;

  @override
  void initState() {
    super.initState();
    currentEnv = widget.envBean;
  }

  void _toggleStatus() async {
    final newStatus = currentEnv.status == 1 ? 0 : 1;
    setState(() {
      currentEnv.status = newStatus;
    });

    await ref
        .read(SingleAccountPageState.ofEnvProvider(context)(getProviderName(context)).notifier)
        .enableEnv(context, [currentEnv.sId!], newStatus == 0 ? 1 : 0);
  }

  void _confirmDelete() {
    final theme = ref.read(themeProvider);
    final isDark = theme.isDark();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            Text(
              "删除环境变量",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.themeColor.titleColor(),
              ),
            ),
          ],
        ),
        content: Text(
          "确定要删除环境变量「${currentEnv.name ?? ''}」吗？此操作无法撤销。",
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: theme.themeColor.descColor(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "取消",
              style: TextStyle(color: theme.themeColor.descColor(), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(SingleAccountPageState.ofEnvProvider(context)(getProviderName(context)).notifier)
                  .delEnv(context, currentEnv.sId!);
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text("确认删除"),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit() async {
    final updated = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => AddEnvPage(envBean: currentEnv),
      ),
    );
    if (updated == true || updated is EnvBean) {
      if (updated is EnvBean) {
        setState(() => currentEnv = updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final isDark = theme.isDark();
    final primaryColor = theme.primaryColor;
    final titleColor = theme.themeColor.titleColor();
    final descColor = theme.themeColor.descColor();
    final cardBg = isDark ? const Color(0xFF1E2638) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final isEnabled = currentEnv.status != 1;
    final valueText = currentEnv.value ?? "";

    String createTimeStr = "-";
    if (currentEnv.created != null) {
      createTimeStr = Utils.formatMessageTime(currentEnv.created ?? 0);
    } else if (currentEnv.createdAt != null) {
      createTimeStr = Utils.formatTime2(currentEnv.createdAt);
    }

    String updateTimeStr = "-";
    if (currentEnv.updatedAt != null) {
      updateTimeStr = Utils.formatTime2(currentEnv.updatedAt);
    } else if (currentEnv.timestamp != null) {
      updateTimeStr = Utils.formatGMTTime(currentEnv.timestamp ?? "");
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: QlAppBar(
        canBack: true,
        title: "环境变量详情",
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: "编辑",
            onPressed: _navigateToEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 21, color: Color(0xFFEF4444)),
            tooltip: "删除",
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 顶部核心信息卡片 (Name, ID, Status)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isEnabled ? primaryColor : const Color(0xFF94A3B8)).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.data_object_rounded,
                          size: 26,
                          color: isEnabled ? primaryColor : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              currentEnv.name ?? "",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (currentEnv.sId != null && currentEnv.sId!.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: currentEnv.sId!));
                                  "已复制变量ID".toast();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF141E30) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "ID: ${currentEnv.sId!}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: descColor,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.copy_rounded, size: 11, color: descColor.withOpacity(0.7)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 14),
                  // 状态开关行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEnabled ? "当前状态：已启用" : "当前状态：已禁用",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                      CupertinoSwitch(
                        activeColor: primaryColor,
                        value: isEnabled,
                        onChanged: (val) => _toggleStatus(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. 变量值窗口卡片
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题与快捷操作栏
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.terminal_rounded, size: 18, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          "变量值 (Value)",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${valueText.length} 字符",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: valueText));
                            "已复制变量值".toast();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 14, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  "复制",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Share.share(valueText);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.share_outlined, size: 14, color: descColor),
                                const SizedBox(width: 4),
                                Text(
                                  "分享",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: descColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  // 代码区域
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 120, maxHeight: 360),
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF020617) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: CupertinoScrollbar(
                      child: SingleChildScrollView(
                        child: SelectableText(
                          valueText.isEmpty ? "(值为空)" : valueText,
                          selectionHeightStyle: BoxHeightStyle.max,
                          selectionWidthStyle: BoxWidthStyle.max,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.5,
                            color: valueText.isEmpty
                                ? descColor.withOpacity(0.5)
                                : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. 元数据卡片 (备注、创建时间、更新时间)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        "变量属性与备注",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildMetaRow(
                    context,
                    label: "备注信息",
                    icon: Icons.notes_rounded,
                    value: (currentEnv.remarks != null && currentEnv.remarks!.isNotEmpty)
                        ? currentEnv.remarks!
                        : "无备注信息",
                    titleColor: titleColor,
                    descColor: descColor,
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 12),
                  _buildMetaRow(
                    context,
                    label: "创建时间",
                    icon: Icons.access_time_rounded,
                    value: createTimeStr,
                    titleColor: titleColor,
                    descColor: descColor,
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 12),
                  _buildMetaRow(
                    context,
                    label: "最近更新",
                    icon: Icons.update_rounded,
                    value: updateTimeStr,
                    titleColor: titleColor,
                    descColor: descColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 4. 底部快捷操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      foregroundColor: primaryColor,
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text("编辑变量", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: _navigateToEdit,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text("删除变量", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: _confirmDelete,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String value,
    required Color titleColor,
    required Color descColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: descColor.withOpacity(0.8)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 13.5, color: descColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
        ),
      ],
    );
  }
}
