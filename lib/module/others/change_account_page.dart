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
                      "轻触卡片立即切换活动实例，左滑可移除离线账号",
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
                const SizedBox(width: 10),

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
        extentRatio: 0.25,
        children: [
          SlidableAction(
            borderRadius: BorderRadius.circular(16),
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
    Color titleColor,
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
