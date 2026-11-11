import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/utils.dart';

import 'add_appkey_page.dart';
import 'appkey_page.dart';
import 'appkey_viewmodel.dart';

class AppKeyDetailDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> bean;

  const AppKeyDetailDetailPage(
    this.bean, {
    Key? key,
  }) : super(key: key);

  @override
  _AppKeyDetailDetailPageState createState() => _AppKeyDetailDetailPageState();
}

class _AppKeyDetailDetailPageState
    extends ConsumerState<AppKeyDetailDetailPage> {
  bool _showSecret = false;

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

    final clientId = widget.bean >> "client_id";
    final clientSecret = widget.bean >> "client_secret";
    final scopes = AppKeyViewModel.getScopeNames(
      widget.bean["scopes"] as List<dynamic>?,
    );
    final appName = widget.bean["name"] ?? "应用详情";

    return Scaffold(
      backgroundColor: theme.themeColor.bg2Color(),
      appBar: QlAppBar(
        title: appName,
        actions: [
          IconButton(
            tooltip: "编辑",
            icon: Icon(
              CupertinoIcons.pencil_circle_fill,
              size: 24,
              color: primaryColor,
            ),
            onPressed: () {
              Navigator.of(context)
                  .push(
                CupertinoPageRoute(
                  builder: (context) => AddAppKeyPage(bean: widget.bean),
                ),
              )
                  .then((value) {
                if (value == true) {
                  Navigator.of(context).pop(true);
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Hero 头部卡片
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
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.2),
                        primaryColor.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    CupertinoIcons.lock_shield_fill,
                    color: primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "青龙面板 OpenAPI 授权凭据",
                        style: TextStyle(
                          fontSize: 12,
                          color: descColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Client ID 卡片
          _buildKeyCard(
            title: "Client ID",
            value: clientId,
            isSensitive: false,
            primaryColor: primaryColor,
            cardBg: cardBg,
            borderColor: borderColor,
            titleColor: titleColor,
            descColor: descColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // 3. Client Secret 卡片
          _buildKeyCard(
            title: "Client Secret",
            value: clientSecret,
            isSensitive: true,
            isSecretVisible: _showSecret,
            onToggleVisibility: () {
              setState(() {
                _showSecret = !_showSecret;
              });
            },
            primaryColor: primaryColor,
            cardBg: cardBg,
            borderColor: borderColor,
            titleColor: titleColor,
            descColor: descColor,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // 4. 权限作用域卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_shield_fill,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "应用授权范围 (Scopes)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (scopes.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: scopes.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              e,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    "暂未分配任何权限",
                    style: TextStyle(fontSize: 13, color: descColor),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 5. 危险操作卡片
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: const Color(0xff8B5CF6).withOpacity(0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    CupertinoIcons.arrow_2_circlepath,
                    size: 16,
                    color: Color(0xff8B5CF6),
                  ),
                  label: const Text(
                    "重置 Secret",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff8B5CF6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _resetSecret(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    CupertinoIcons.delete,
                    size: 16,
                  ),
                  label: const Text(
                    "删除应用",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _del(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKeyCard({
    required String title,
    required String value,
    required bool isSensitive,
    bool isSecretVisible = false,
    VoidCallback? onToggleVisibility,
    required Color primaryColor,
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color descColor,
    required bool isDark,
  }) {
    String displayValue = value;
    if (isSensitive && !isSecretVisible) {
      displayValue = "••••••••••••••••••••••••";
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: descColor,
                ),
              ),
              const Spacer(),
              if (isSensitive)
                GestureDetector(
                  onTap: onToggleVisibility,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      isSecretVisible
                          ? CupertinoIcons.eye_slash_fill
                          : CupertinoIcons.eye_fill,
                      size: 16,
                      color: descColor,
                    ),
                  ),
                ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  "已复制到剪切板".toast();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.doc_on_doc,
                        size: 14,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "复制",
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              displayValue,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetSecret(BuildContext context) {
    showCupertinoDialog(
      context: context,
      useRootNavigator: false,
      builder: (context1) => CupertinoAlertDialog(
        title: Text("确认重置「${widget.bean["name"]}」的 Secret?"),
        content: const Text("重置 Secret 会立即导致使用原密钥的所有第三方脚本与 Token 失效，需要重新配置。"),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(context1).pop(),
          ),
          CupertinoDialogAction(
            child: Text(
              "确定重置",
              style: TextStyle(
                color: ref.watch(themeProvider).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.of(context1).pop();
              EasyLoading.show(status: "重置中...");
              ref
                  .read(
                    SingleAccountPageState.ofAppKeyProvider(context)(
                      getProviderName(context),
                    ),
                  )
                  .resetAppKey(context, getAppKeyId(widget.bean))
                  .then((_) {
                EasyLoading.dismiss();
                Navigator.of(context).pop(true);
              }).catchError((_) {
                EasyLoading.dismiss();
              });
            },
          ),
        ],
      ),
    );
  }

  void _del(BuildContext context1, WidgetRef ref) {
    showCupertinoDialog(
      context: context1,
      useRootNavigator: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("确认删除应用"),
        content: Text("确定要删除应用「${widget.bean["name"] ?? ""}」吗？删除后该应用将无法再访问任何 API 接口。"),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("删除"),
            onPressed: () {
              Navigator.of(context).pop();
              EasyLoading.show(status: "删除中");
              ref
                  .read(
                    SingleAccountPageState.ofAppKeyProvider(context1)(
                      getProviderName(context1),
                    ),
                  )
                  .delAppKey(context1, getAppKeyId(widget.bean))
                  .then((value) {
                EasyLoading.dismiss();
                Navigator.of(context1).pop(true);
              }).catchError((_, __) {
                EasyLoading.dismiss();
              });
            },
          ),
        ],
      ),
    );
  }
}

extension DynamicEmptyHandle on Map<String, dynamic> {
  String operator >>(Object? key) {
    if (containsKey(key)) {
      dynamic value = this[key];
      if (value != null) {
        if (value is String) {
          if (value.isNotEmpty) return value;
        } else {
          return value.toString();
        }
      }
    }
    return "- -";
  }

  String operator >>>(Object? key) {
    if (containsKey(key)) {
      dynamic value = this[key];
      if (value != null) {
        if (value is String) {
          if (value.isNotEmpty) return value;
        } else {
          return value.toString();
        }
      }
    }
    return "";
  }
}
