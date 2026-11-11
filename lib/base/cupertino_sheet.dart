import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/theme.dart';

class CupertinoSheer extends ConsumerWidget {
  final String title;
  final GestureTapCallback onTap;
  final IconData? icon;
  final Color? color;
  final bool isDestructive;

  const CupertinoSheer({
    Key? key,
    required this.title,
    required this.onTap,
    this.icon,
    this.color,
    this.isDestructive = false,
  }) : super(key: key);

  static IconData _resolveIcon(String title, IconData? customIcon) {
    if (customIcon != null) return customIcon;
    final t = title.trim();
    if (t.contains("新增文件") || t.contains("新建文件")) return Icons.note_add_outlined;
    if (t.contains("文件夹")) return Icons.create_new_folder_outlined;
    if (t.contains("编辑") || t.contains("修改")) return Icons.edit_outlined;
    if (t.contains("停止")) return Icons.stop_circle_outlined;
    if (t.contains("运行") || t.contains("执行")) return Icons.play_arrow_rounded;
    if (t.contains("日志")) return Icons.terminal_rounded;
    if (t.contains("分享")) return Icons.share_outlined;
    if (t.contains("下载") || t.contains("导出")) return Icons.download_rounded;
    if (t.contains("禁用")) return Icons.pause_circle_outline_rounded;
    if (t.contains("启用")) return Icons.check_circle_outline_rounded;
    if (t.contains("删除")) return Icons.delete_outline_rounded;
    if (t.contains("清空")) return Icons.cleaning_services_outlined;
    if (t.contains("复制")) return Icons.copy_rounded;
    if (t.contains("置顶")) return Icons.vertical_align_top_rounded;
    return Icons.more_horiz_rounded;
  }

  static Color _resolveColor(String title, Color? customColor, bool isDestructive, Color defaultColor) {
    if (customColor != null) return customColor;
    if (isDestructive) return const Color(0xFFEF4444);
    final t = title.trim();
    if (t.contains("删除") || t.contains("停止")) return const Color(0xFFEF4444);
    if (t.contains("运行") || t.contains("启用")) return const Color(0xFF10B981);
    if (t.contains("禁用")) return const Color(0xFFF59E0B);
    return defaultColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark || ref.watch(themeProvider).isDark();
    final defaultTitleColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final itemColor = _resolveColor(title, color, isDestructive, defaultTitleColor);
    final iconData = _resolveIcon(title, icon);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconData,
                  size: 20,
                  color: itemColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: itemColor,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget addDivider() {
  return Consumer(
    builder: (context, ref, _) {
      final isDark = Theme.of(context).brightness == Brightness.dark || ref.watch(themeProvider).isDark();
      return Divider(
        height: 1,
        thickness: 0.8,
        indent: 16,
        endIndent: 16,
        color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
      );
    },
  );
}

void showMoreOperate(BuildContext context, List<Widget> list) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context1) {
      return Consumer(
        builder: (context, ref, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark || ref.watch(themeProvider).isDark();
          final surfaceColor = isDark ? const Color(0xFF1E2638) : Colors.white;
          final borderColor = isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000);
          final cancelBg = isDark ? const Color(0xFF26324A) : const Color(0xFFF1F5F9);
          final cancelText = isDark ? Colors.white70 : const Color(0xFF475569);

          return SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: list,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: cancelBg,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(context1).pop(),
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        child: Text(
                          "取消",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cancelText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
