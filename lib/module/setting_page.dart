import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/multi_account_userinfo_viewmodel.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/home/home_page.dart';
import 'package:qinglong_app/module/home/system_bean.dart';
import 'package:qinglong_app/module/home/version_history_bean.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/sp_utils.dart';

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  @override
  Widget build(BuildContext context) {
    SystemBean? systemBean;

    try {
      systemBean = getIt<SystemBean>(
        instanceName:
            (SingleAccountPageState.of(context)?.index ?? 0).toString(),
      );
    } catch (e) {
      systemBean = SystemBean(version: "2.10.13", fromAutoGet: false);
    }

    final theme = ref.watch(themeProvider);
    final isDark = theme.isDark();
    final primaryColor = theme.primaryColor;
    final cardBg = theme.themeColor.settingBgColor();
    final titleColor = theme.themeColor.titleColor();
    final descColor = theme.themeColor.descColor();
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.05);

    final followSystem = SpUtil.getBool(spThemeFollowSystem, defValue: false);
    final themeStyle = SpUtil.getInt(spThemeStyle, defValue: modeLight);

    return Scaffold(
      backgroundColor: theme.themeColor.bg2Color(),
      appBar: QlAppBar(
        title: "系统设置",
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. 系统/服务器状态卡片
          _buildServerCard(
            context,
            systemBean,
            cardBg,
            borderColor,
            titleColor,
            descColor,
            primaryColor,
          ),
          const SizedBox(height: 20),

          // 2. 外观与主题
          _buildSectionHeader("外观与主题", CupertinoIcons.paintbrush),
          const SizedBox(height: 8),
          _buildCardGroup(
            cardBg: cardBg,
            borderColor: borderColor,
            children: [
              _buildThemeSelector(
                context,
                followSystem,
                themeStyle,
                primaryColor,
                titleColor,
                descColor,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. 运行与代码偏好
          _buildSectionHeader("运行与日志偏好", CupertinoIcons.slider_horizontal_3),
          const SizedBox(height: 8),
          _buildCardGroup(
            cardBg: cardBg,
            borderColor: borderColor,
            children: [
              _buildSwitchTile(
                icon: CupertinoIcons.doc_text,
                iconColor: const Color(0xff3B82F6),
                title: "任务自动弹出日志",
                subtitle: "触发运行任务后立即展开实时日志弹窗",
                value: SpUtil.getBool(spAutoShowLog, defValue: true),
                primaryColor: primaryColor,
                titleColor: titleColor,
                descColor: descColor,
                onChanged: (val) async {
                  await SpUtil.putBool(spAutoShowLog, val);
                  setState(() {});
                },
              ),
              _buildDivider(borderColor),
              _buildSwitchTile(
                icon: Icons.format_list_numbered_rounded,
                iconColor: const Color(0xff8B5CF6),
                title: "代码编辑器显示行号",
                subtitle: "在脚本和配置编辑页面左侧显示代码行号",
                value: SpUtil.getBool(spShowLine, defValue: false),
                primaryColor: primaryColor,
                titleColor: titleColor,
                descColor: descColor,
                onChanged: (val) async {
                  await SpUtil.putBool(spShowLine, val);
                  setState(() {});
                },
              ),
              _buildDivider(borderColor),
              _buildSwitchTile(
                icon: CupertinoIcons.arrow_down_doc,
                iconColor: const Color(0xff10B981),
                title: "实时日志自动滚屏",
                subtitle: "日志刷新时视口平滑跟随滚动到底部",
                value: SpUtil.getBool(spLogAutoJump2Bottom, defValue: false),
                primaryColor: primaryColor,
                titleColor: titleColor,
                descColor: descColor,
                onChanged: (val) async {
                  await SpUtil.putBool(spLogAutoJump2Bottom, val);
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. 安全与高级模式
          if (Platform.isIOS ||
              SpUtil.getInt(spVIP, defValue: typeNormal) != typeNormal) ...[
            _buildSectionHeader("高级功能与安全", CupertinoIcons.shield_lefthalf_fill),
            const SizedBox(height: 8),
            _buildCardGroup(
              cardBg: cardBg,
              borderColor: borderColor,
              children: [
                _buildSwitchTile(
                  icon: CupertinoIcons.viewfinder_circle_fill,
                  iconColor: const Color(0xff06B6D4),
                  title: "生物识别解锁",
                  subtitle: Platform.isIOS ? "使用 Face ID / Touch ID 验证身份" : "使用指纹或面部识别解锁应用",
                  value: SpUtil.getBool(spOpenAuth, defValue: false),
                  primaryColor: primaryColor,
                  titleColor: titleColor,
                  descColor: descColor,
                  onChanged: (val) async {
                    await SpUtil.putBool(spOpenAuth, val);
                    setState(() {});
                  },
                ),
                _buildDivider(borderColor),
                _buildSwitchTile(
                  icon: CupertinoIcons.wand_stars_inverse,
                  iconColor: const Color(0xffEC4899),
                  title: "单实例模式",
                  subtitle: "降低多容器在线内存开销，长按切换",
                  infoOnTap: () {
                    showCupertinoDialog(
                      useRootNavigator: false,
                      context: context,
                      builder: (context1) => CupertinoAlertDialog(
                        title: const Text("单实例模式说明"),
                        content: const Text(
                          "开启后可关闭多容器后台同时在线，显著减少 App 对系统内存与电池的消耗。\n\n如需切换不同青龙面板，可在首页长按底部「我的」快速切换。",
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: Text(
                              "了解",
                              style: TextStyle(color: primaryColor),
                            ),
                            onPressed: () => Navigator.of(context1).pop(),
                          ),
                        ],
                      ),
                    );
                  },
                  value: SpUtil.getBool(spSingleInstance, defValue: false),
                  primaryColor: primaryColor,
                  titleColor: titleColor,
                  descColor: descColor,
                  onChanged: (val) async {
                    await SpUtil.putBool(spSingleInstance, val);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // 5. 危险区域：账号注销与数据清理
          _buildSectionHeader("账号与数据", CupertinoIcons.person_crop_circle_badge_exclam),
          const SizedBox(height: 8),
          _buildCardGroup(
            cardBg: cardBg,
            borderColor: borderColor,
            children: [
              _buildActionTile(
                icon: CupertinoIcons.square_arrow_left,
                iconColor: const Color(0xffF59E0B),
                title: "退出当前登录",
                subtitle: "注销当前青龙实例 Token，保留本地历史配置",
                titleColor: titleColor,
                descColor: descColor,
                onTap: () => _confirmLogout(context, primaryColor),
              ),
              _buildDivider(borderColor),
              _buildActionTile(
                icon: CupertinoIcons.trash,
                iconColor: const Color(0xffEF4444),
                title: "退出并清空当前账号数据",
                subtitle: "清除当前服务器的所有本地缓存、Key 及登录信息",
                titleColor: const Color(0xffEF4444),
                descColor: descColor,
                onTap: () => _confirmClearData(context, primaryColor),
              ),
            ],
          ),

          const SizedBox(height: 36),
          Center(
            child: Text(
              "QingLong Mobile · Material Design 3",
              style: TextStyle(
                fontSize: 12,
                color: descColor.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 头部服务器状态卡片
  Widget _buildServerCard(
    BuildContext context,
    SystemBean? systemBean,
    Color cardBg,
    Color borderColor,
    Color titleColor,
    Color descColor,
    Color primaryColor,
  ) {
    final host = SingleAccountPageState.ofUserInfo(context).host;
    final alias = SingleAccountPageState.ofUserInfo(context).alias;
    final isAuto = systemBean?.fromAutoGet ?? false;

    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.2),
                      primaryColor.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dns_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alias.isNotEmpty ? alias : "当前青龙面板",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      host.isNotEmpty ? host : "未配置主机地址",
                      style: TextStyle(
                        fontSize: 12,
                        color: descColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
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
                      "v${systemBean?.version ?? '2.10.x'}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isAuto) ...[
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _updateVersion(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.pencil_circle,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "自定义服务器版本号 (点击手动校准)",
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
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
        ],
      ),
    );
  }

  // 分组卡片标题
  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = ref.watch(themeProvider);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.themeColor.descColor(),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // 统一圆角卡片容器
  Widget _buildCardGroup({
    required Color cardBg,
    required Color borderColor,
    required List<Widget> children,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  // 主题三态选择器
  Widget _buildThemeSelector(
    BuildContext context,
    bool followSystem,
    int themeStyle,
    Color primaryColor,
    Color titleColor,
    Color descColor,
  ) {
    int selectedIndex;
    if (followSystem) {
      selectedIndex = 0;
    } else if (themeStyle == modeDark) {
      selectedIndex = 2;
    } else {
      selectedIndex = 1;
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.circle_righthalf_fill,
                  size: 18,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "界面显示模式",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      followSystem ? "当前为跟随系统主题变动" : (themeStyle == modeDark ? "固定暗色主题" : "固定浅色主题"),
                      style: TextStyle(fontSize: 12, color: descColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  icon: CupertinoIcons.device_phone_portrait,
                  label: "跟随系统",
                  isSelected: selectedIndex == 0,
                  primaryColor: primaryColor,
                  titleColor: titleColor,
                  onTap: () {
                    SpUtil.putBool(spThemeFollowSystem, true);
                    ref
                        .read(themeProvider.notifier)
                        .changeThemeWithSystemStatus();
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  icon: CupertinoIcons.sun_max_fill,
                  label: "浅色模式",
                  isSelected: selectedIndex == 1,
                  primaryColor: primaryColor,
                  titleColor: titleColor,
                  onTap: () {
                    SpUtil.putBool(spThemeFollowSystem, false);
                    ref.read(themeProvider.notifier).changeTheme(modeLight);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  icon: CupertinoIcons.moon_fill,
                  label: "深色模式",
                  isSelected: selectedIndex == 2,
                  primaryColor: primaryColor,
                  titleColor: titleColor,
                  onTap: () {
                    SpUtil.putBool(spThemeFollowSystem, false);
                    ref.read(themeProvider.notifier).changeTheme(modeDark);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color primaryColor,
    required Color titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? primaryColor : titleColor.withOpacity(0.6),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 开关类配置单元格
  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Color primaryColor,
    required Color titleColor,
    required Color descColor,
    required ValueChanged<bool> onChanged,
    VoidCallback? infoOnTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 19,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ),
                    if (infoOnTap != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: infoOnTap,
                        child: Icon(
                          CupertinoIcons.question_circle,
                          size: 15,
                          color: descColor,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: descColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.85,
            child: CupertinoSwitch(
              activeColor: primaryColor,
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // 动作类单元格
  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color titleColor,
    required Color descColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: descColor,
                    ),
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
    );
  }

  Widget _buildDivider(Color borderColor) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 58,
      endIndent: 14,
      color: borderColor,
    );
  }

  void _confirmLogout(BuildContext context, Color primaryColor) {
    showCupertinoDialog(
      useRootNavigator: false,
      context: context,
      builder: (context1) => CupertinoAlertDialog(
        title: const Text("确认退出当前登录?"),
        content: const Text("退出后需重新验证身份或登录，本地多账号配置仍会保留。"),
        actions: [
          CupertinoDialogAction(
            child: const Text(
              "取消",
              style: TextStyle(color: Color(0xff999999)),
            ),
            onPressed: () => Navigator.of(context1).pop(),
          ),
          CupertinoDialogAction(
            child: Text(
              "确定退出",
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(context1).pop();
              SingleAccountPageState.ofUserInfo(context).updateToken(
                SingleAccountPageState.of(context)?.index ?? 0,
                SingleAccountPageState.ofUserInfo(context).host,
                "",
                false,
                SingleAccountPageState.ofUserInfo(context).alias,
              );
              Navigator.of(context).pushNamedAndRemoveUntil(
                Routes.routeLogin,
                (p) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context, Color primaryColor) {
    showCupertinoDialog(
      useRootNavigator: false,
      context: context,
      builder: (context1) => CupertinoAlertDialog(
        title: const Text("确认清空本地数据?"),
        content: const Text(
          "此操作将清除当前账号在手机上的所有缓存数据和凭证，且无法恢复，确定要继续吗？",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text(
              "取消",
              style: TextStyle(color: Color(0xff999999)),
            ),
            onPressed: () => Navigator.of(context1).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("清空并退出"),
            onPressed: () {
              Navigator.of(context1).pop();
              clearData(context);
              Navigator.of(context).pushNamedAndRemoveUntil(
                Routes.routeLogin,
                (p) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  void clearData(BuildContext context) {
    getIt<MultiAccountUserInfoViewModel>()
        .removeHistoryAccount(SingleAccountPageState.ofUserInfo(context).host);
    SingleAccountPageState.ofUserInfo(context)
        .clearCurrentInfo(SingleAccountPageState.of(context)?.index ?? 0);
  }

  void _updateVersion(BuildContext context) async {
    String? host = SingleAccountPageState.ofUserInfo(context).host;

    TextEditingController controller = TextEditingController(
      text: getIt<SystemBean>(
        instanceName:
            (SingleAccountPageState.of(context)?.index ?? 0).toString(),
      ).version,
    );
    showCupertinoDialog(
      useRootNavigator: false,
      context: context,
      builder: (context1) => CupertinoAlertDialog(
        title: const Text("手动修改服务器版本号"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            TextField(
              textAlign: TextAlign.center,
              controller: controller,
              autofocus: false,
              decoration: InputDecoration(
                hintText: "例如 2.10.13",
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text(
              "取消",
              style: TextStyle(color: Color(0xff999999)),
            ),
            onPressed: () => Navigator.of(context1).pop(),
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
              Navigator.of(context1).pop();
              HomePageState.updateVersionHistory(VersionHistoryBean(
                host: host,
                version: controller.text.trim(),
              ));
              SingleAccountPageState.of(context)
                  ?.registerSystemBean(controller.text.trim(), false);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
