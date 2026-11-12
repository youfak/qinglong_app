import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:qinglong_app/base/multi_account_userinfo_viewmodel.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/sp_utils.dart';

import '../../main.dart';

class ChangeAccountPage extends ConsumerStatefulWidget {
  const ChangeAccountPage({Key? key}) : super(key: key);

  @override
  _ChangeAccountPageState createState() => _ChangeAccountPageState();
}

class _ChangeAccountPageState extends ConsumerState<ChangeAccountPage> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.primaryFocus?.unfocus();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (MultiAccountUserInfoViewModel.maxAccount == 1 &&
          SpUtil.getInt(spVIP, defValue: typeNormal) != typeNormal) {
        "请重启App即可启用多账号切换功能".toast();
      }
    });
  }

  Future<String?> _testHostConnection(String host) async {
    String clean = host.trim();
    if (clean.isEmpty) return null;
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        validateStatus: (status) => true,
      ));
      final resp = await dio.get('$clean/api/system');
      if (resp.statusCode == 200) {
        if (resp.data is Map && resp.data['data'] != null) {
          final ver = resp.data['data']['version'] ?? '';
          return '连通成功 (青龙 v$ver)';
        }
        return '连通成功 (HTTP 200)';
      } else if (resp.statusCode != null && resp.statusCode! < 500) {
        return '服务已响应 (HTTP ${resp.statusCode})';
      } else {
        return '服务响应状态: HTTP ${resp.statusCode}';
      }
    } catch (e) {
      return null;
    }
  }

  void _showEditHostDialog(
    BuildContext context,
    UserInfoViewModel userInfo,
    int index,
  ) {
    final theme = ref.read(themeProvider);
    final isDark = theme.isDark();
    final primaryColor = theme.primaryColor;
    final cardBg = theme.themeColor.settingBgColor();
    final titleColor = theme.themeColor.titleColor();
    final descColor = theme.themeColor.descColor();
    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);

    final aliasController = TextEditingController(text: userInfo.alias ?? "");
    final hostController = TextEditingController(text: userInfo.host ?? "");

    bool isTesting = false;
    String? testResult;
    bool? testSuccess;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.dns_rounded, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "修改面板配置",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "修改连接地址与实例别名",
                        style: TextStyle(fontSize: 12, color: descColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "实例别名",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141E30) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: aliasController,
                      style: TextStyle(fontSize: 14, color: titleColor),
                      decoration: InputDecoration(
                        hintText: "例如：家庭NAS青龙、主路由",
                        hintStyle: TextStyle(fontSize: 13, color: descColor.withOpacity(0.6)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "连接地址 (Host / IP:端口)",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141E30) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: hostController,
                      style: TextStyle(fontSize: 13.5, fontFamily: 'monospace', color: titleColor),
                      decoration: InputDecoration(
                        hintText: "http://192.168.1.100:5700",
                        hintStyle: TextStyle(fontSize: 13, color: descColor.withOpacity(0.6)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "需以 http:// 或 https:// 开头，如只输 IP/域名 则默认加 http://",
                    style: TextStyle(fontSize: 11, color: descColor.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 14),

                  // 连通性测试按钮与结果
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          side: BorderSide(color: primaryColor.withOpacity(0.6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          foregroundColor: primaryColor,
                        ),
                        icon: isTesting
                            ? const CupertinoActivityIndicator(radius: 7)
                            : const Icon(Icons.network_check_rounded, size: 16),
                        label: Text(
                          isTesting ? "检测中..." : "测试连通性",
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: isTesting
                            ? null
                            : () async {
                                final text = hostController.text.trim();
                                if (text.isEmpty) {
                                  "请输入连接地址".toast();
                                  return;
                                }
                                setDialogState(() {
                                  isTesting = true;
                                  testResult = null;
                                  testSuccess = null;
                                });
                                final res = await _testHostConnection(text);
                                setDialogState(() {
                                  isTesting = false;
                                  testSuccess = res != null;
                                  testResult = res ?? "连接失败，无法访问该主机与端口";
                                });
                              },
                      ),
                    ],
                  ),
                  if (testResult != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (testSuccess == true
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444))
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (testSuccess == true
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            testSuccess == true
                                ? Icons.check_circle_rounded
                                : Icons.error_outline_rounded,
                            size: 15,
                            color: testSuccess == true
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              testResult!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: testSuccess == true
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(
                  "取消",
                  style: TextStyle(color: descColor, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  String newHost = hostController.text.trim();
                  String newAlias = aliasController.text.trim();
                  if (newHost.isEmpty) {
                    "服务器连接地址不能为空".toast();
                    return;
                  }
                  if (!newHost.startsWith('http://') && !newHost.startsWith('https://')) {
                    newHost = 'http://$newHost';
                  }
                  while (newHost.endsWith('/')) {
                    newHost = newHost.substring(0, newHost.length - 1);
                  }
                  if (newAlias.isEmpty) {
                    newAlias = "青龙实例 #${index + 1}";
                  }

                  userInfo.updateHostAndAlias(index, newHost, newAlias);
                  "连接地址与别名已更新".toast();
                  Navigator.of(dialogCtx).pop();
                  setState(() {});
                },
                child: const Text("保存修改"),
              ),
            ],
          );
        },
      ),
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

    int count = getIt<MultiAccountUserInfoViewModel>().tokenBeans.length + 1;
    if (count > MultiAccountUserInfoViewModel.maxAccount) {
      count = MultiAccountUserInfoViewModel.maxAccount;
    }

    final currentIndex =
        context.findAncestorStateOfType<MultiAccountPageState>()?.index ??
            0;

    return Scaffold(
      backgroundColor: theme.themeColor.bg2Color(),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部导航栏
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill),
                      iconSize: 28,
                      color: descColor.withOpacity(0.5),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "多实例管理",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 头部说明
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "切换青龙面板",
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "轻触卡片立即切换活动实例，支持修改连接地址与别名",
                      style: TextStyle(
                        color: descColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // 账号列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: count,
                  itemBuilder: (context, index) {
                    final tokenList =
                        getIt<MultiAccountUserInfoViewModel>().tokenBeans;
                    if (index >= tokenList.length ||
                        (tokenList.length < count && index == count - 1)) {
                      return _buildAddAccountCard(
                        context,
                        index,
                        primaryColor,
                        cardBg,
                        borderColor,
                        titleColor,
                      );
                    }

                    final userInfo = getIt<UserInfoViewModel>(
                      instanceName: index.toString(),
                    );
                    final isCurrentActive = index == currentIndex;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildAccountCard(
                        userInfo: userInfo,
                        index: index,
                        isActive: isCurrentActive,
                        primaryColor: primaryColor,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        titleColor: titleColor,
                        descColor: descColor,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard({
    required UserInfoViewModel userInfo,
    required int index,
    required bool isActive,
    required Color primaryColor,
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color descColor,
    required bool isDark,
  }) {
    final alias = userInfo.alias?.isNotEmpty == true
        ? userInfo.alias!
        : "青龙实例 #${index + 1}";
    final host = userInfo.host?.isNotEmpty == true
        ? userInfo.host!
        : "未设置服务器地址";
    final isLogined = userInfo.token != null && userInfo.token!.isNotEmpty;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? primaryColor : borderColor,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? primaryColor.withOpacity(0.08)
                : Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context
                .findAncestorStateOfType<MultiAccountPageState>()
                ?.updateIndex(index);
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 状态/服务器图标
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (isActive ? primaryColor : descColor).withOpacity(0.18),
                        (isActive ? primaryColor : descColor).withOpacity(0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.dns_rounded,
                    color: isActive ? primaryColor : descColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // 别名与主机
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              alias,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "活跃",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        host,
                        style: TextStyle(
                          fontSize: 12,
                          color: descColor,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // 登录状态指示
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLogined
                        ? primaryColor.withOpacity(0.1)
                        : const Color(0xffEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isLogined
                              ? primaryColor
                              : const Color(0xffEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isLogined ? "在线" : "未登录",
                        style: TextStyle(
                          color: isLogined
                              ? primaryColor
                              : const Color(0xffEF4444),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // 修改连接地址按钮
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, size: 22),
                  tooltip: "修改连接地址与配置",
                  color: descColor.withOpacity(0.7),
                  padding: const EdgeInsets.only(left: 4),
                  constraints: const BoxConstraints(),
                  onPressed: () => _showEditHostDialog(context, userInfo, index),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (userInfo.host == null || userInfo.host!.isEmpty) {
      return cardContent;
    }

    return Slidable(
      key: ValueKey(userInfo.host),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.44,
        children: [
          SlidableAction(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            backgroundColor: const Color(0xff3B82F6),
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: "修改地址",
            onPressed: (_) => _showEditHostDialog(context, userInfo, index),
          ),
          SlidableAction(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
            backgroundColor: const Color(0xffEF4444),
            foregroundColor: Colors.white,
            icon: CupertinoIcons.delete,
            label: "删除",
            onPressed: (_) {
              if (userInfo.token != null && userInfo.token!.isNotEmpty) {
                "请先退出该账号登录，再执行删除".toast();
                return;
              }

              showCupertinoDialog(
                context: context,
                useRootNavigator: false,
                builder: (childContext) => CupertinoAlertDialog(
                  title: const Text("确认移除账号"),
                  content: Text("确定从列表中移除「$alias」吗？"),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text("取消",
                          style: TextStyle(color: Color(0xff999999))),
                      onPressed: () => Navigator.of(childContext).pop(),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text("移除"),
                      onPressed: () {
                        Navigator.of(childContext).pop();
                        getIt<MultiAccountUserInfoViewModel>()
                            .removeHistoryAccount(userInfo.host);
                        getIt<UserInfoViewModel>(
                                instanceName: index.toString())
                            .clearCurrentInfo(index);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      child: cardContent,
    );
  }

  Widget _buildAddAccountCard(
    BuildContext context,
    int index,
    Color primaryColor,
    Color cardBg,
    Color borderColor,
    titleColor,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        context
            .findAncestorStateOfType<MultiAccountPageState>()
            ?.updateIndex(index);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: cardBg.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.plus,
                size: 18,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "添加新的青龙服务器",
              style: TextStyle(
                color: primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
