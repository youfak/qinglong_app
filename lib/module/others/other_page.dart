import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/module/in_app_purchase_page.dart';
import 'package:qinglong_app/module/others/change_account_page.dart';
import 'package:qinglong_app/module/others/sort_account_page.dart';
import 'package:qinglong_app/module/others/text_size_page.dart';
import 'package:qinglong_app/module/others/update_password_page.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/icloud_utils.dart';
import 'package:qinglong_app/utils/sp_utils.dart';
import 'package:path/path.dart' as ints;

import '../../main.dart';
import '../appkey/appkey_page.dart';
import '../home/system_bean.dart';
import '../poet_page.dart';
import '../push_setting_page.dart';
import '../scan_page.dart';
import '../task/task_page.dart';
import '../update_max_account_page.dart';

class OtherPage extends ConsumerStatefulWidget {
  const OtherPage({Key? key}) : super(key: key);

  @override
  OtherPageState createState() => OtherPageState();
}

class OtherPageState extends ConsumerState<OtherPage>
    with LazyLoadState<OtherPage> {
  var toggleValue = false;
  String? userIcon;
  String userName = "青龙客户端";
  var desc = "欢迎使用青龙客户端".obs;
  Map<String, dynamic> poetData = {};

  @override
  void initState() {
    super.initState();
    delLogsByExperiedDate();
  }

  final ScrollController _scrollController = ScrollController();
  GlobalKey<RefreshIndicatorState> refreshKey = GlobalKey();

  Future<void> move2Top() async {
    if (_scrollController.offset !=
        _scrollController.position.minScrollExtent) {
      await scrollToTop();
    } else {
      if (refreshKey.currentState?.mounted ?? false) {
        await refreshKey.currentState?.show();
      }
    }
  }

  Future<void> scrollToTop() async {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = ref.watch(themeProvider).themeMode == modeDark;
    Color primaryColor = ref.watch(themeProvider).primaryColor;
    Color titleColor = ref.watch(themeProvider).themeColor.titleColor();
    Color descColor = ref.watch(themeProvider).themeColor.descColor();
    Color cardBg = ref.watch(themeProvider).themeColor.settingBgColor();
    Color pageBg = ref.watch(themeProvider).themeColor.bg2Color();

    return Scaffold(
      backgroundColor: pageBg,
      body: RefreshIndicator(
        key: refreshKey,
        color: primaryColor,
        onRefresh: () async {
          await loadPoet();
        },
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(
              bottom: kBottomNavigationBarHeight + 50,
            ),
            child: Column(
              children: [
                // 1. Modern Profile Hero Section
                _buildProfileHero(context, isDark, primaryColor, titleColor, descColor, cardBg),

                const SizedBox(height: 12),

                // 2. Primary Feature Hub (Subscriptions, Scripts, Dependencies)
                _buildFeatureHub(context, isDark, primaryColor, titleColor, cardBg),

                const SizedBox(height: 14),

                // 3. Multi-Account & Cloud Sync
                _buildSectionCard(
                  title: "多账号与云端",
                  icon: CupertinoIcons.person_2,
                  isDark: isDark,
                  cardBg: cardBg,
                  primaryColor: primaryColor,
                  children: [
                    _buildSettingTile(
                      title: "多账号管理",
                      subtitle: "配置多实例账号支持",
                      icon: CupertinoIcons.person_badge_plus,
                      iconColor: const Color(0xff10B981),
                      onTap: () {
                        if (SpUtil.getBool(spSingleInstance, defValue: false)) {
                          '请先进入 系统设置 关闭单实例模式'.toast();
                          return;
                        }
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const UpdateMaxAccountPage(),
                          ),
                        );
                      },
                    ),
                    if (!SpUtil.getBool(spSingleInstance, defValue: false))
                      _buildSettingTile(
                        title: "账号排序",
                        subtitle: "调整面板账号展示顺序",
                        icon: CupertinoIcons.arrow_up_arrow_down,
                        iconColor: const Color(0xff3B82F6),
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => const SortAccountPage(),
                            ),
                          );
                        },
                      ),
                    _buildSettingTile(
                      title: "配置与文件备份",
                      subtitle: "本地/iCloud 备份青龙数据",
                      icon: CupertinoIcons.cloud_upload,
                      iconColor: const Color(0xff8B5CF6),
                      hideDivider: true,
                      onTap: () {
                        Navigator.of(context).pushNamed(Routes.routeICloud);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 4. Developer Tools & Logs
                _buildSectionCard(
                  title: "日志与开发工具",
                  icon: CupertinoIcons.wrench,
                  isDark: isDark,
                  cardBg: cardBg,
                  primaryColor: primaryColor,
                  children: [
                    _buildSettingTile(
                      title: "任务日志",
                      subtitle: "查看青龙定时任务运行历史",
                      icon: CupertinoIcons.list_bullet_below_rectangle,
                      iconColor: const Color(0xff06B6D4),
                      onTap: () {
                        Navigator.of(context).pushNamed(Routes.routeTaskLog);
                      },
                    ),
                    _buildSettingTile(
                      title: "登录日志",
                      subtitle: "查看面板用户登录记录",
                      icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                      iconColor: const Color(0xff6366F1),
                      onTap: () {
                        if (SingleAccountPageState.ofUserInfo(context).useSecretLogined) {
                          "使用 Client ID 方式登录无法获取登录日志".toast();
                        } else {
                          Navigator.of(context).pushNamed(Routes.routeLoginLog);
                        }
                      },
                    ),
                    _buildSettingTile(
                      title: "扫描依赖",
                      subtitle: "一键分析脚本所需语言依赖包",
                      icon: CupertinoIcons.doc_text_search,
                      iconColor: const Color(0xffEC4899),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const ScanPage(),
                          ),
                        );
                      },
                    ),
                    _buildSettingTile(
                      title: "日志清理频率",
                      subtitle: "自动清理过期任务运行日志",
                      icon: CupertinoIcons.trash,
                      iconColor: const Color(0xffF97316),
                      hideDivider: true,
                      onTap: () {
                        _delLog(context);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 5. System Preferences
                _buildSectionCard(
                  title: "系统偏好与关于",
                  icon: CupertinoIcons.gear,
                  isDark: isDark,
                  cardBg: cardBg,
                  primaryColor: primaryColor,
                  children: [
                    _buildSettingTile(
                      title: "应用设置",
                      subtitle: "青龙 OpenAPI Key 及网络配置",
                      icon: CupertinoIcons.slider_horizontal_3,
                      iconColor: const Color(0xff14B8A6),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const AppKeyPage(),
                          ),
                        );
                      },
                    ),
                    _buildSettingTile(
                      title: "通知推送",
                      subtitle: "任务运行完成/异常通知渠道",
                      icon: CupertinoIcons.bell,
                      iconColor: const Color(0xffF59E0B),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const PushSettingPage(),
                          ),
                        );
                      },
                    ),
                    _buildSettingTile(
                      title: "修改密码",
                      subtitle: "修改当前青龙登录用户密码",
                      icon: CupertinoIcons.lock_shield,
                      iconColor: const Color(0xff64748B),
                      onTap: () {
                        if (SingleAccountPageState.ofUserInfo(context).useSecretLogined) {
                          "使用 Client ID 方式登录无法修改密码".toast();
                        } else {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => const UpdatePasswordPage(),
                            ),
                          );
                        }
                      },
                    ),
                    _buildSettingTile(
                      title: "字体大小",
                      subtitle: "自定义界面文字排版尺寸",
                      icon: CupertinoIcons.textformat_size,
                      iconColor: const Color(0xff3B82F6),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const TextSizePage(),
                          ),
                        );
                      },
                    ),
                    _buildSettingTile(
                      title: "系统设置",
                      subtitle: "深色模式、单实例模式及高级开关",
                      icon: CupertinoIcons.shield_lefthalf_fill,
                      iconColor: const Color(0xff10B981),
                      onTap: () {
                        Navigator.of(context).pushNamed(Routes.routeSetting);
                      },
                    ),
                    _buildSettingTile(
                      title: "关于软件",
                      subtitle: "版本信息与开源致谢",
                      icon: CupertinoIcons.info_circle,
                      iconColor: const Color(0xff8B5CF6),
                      hideDivider: true,
                      onTap: () {
                        Navigator.of(context).pushNamed(Routes.routeAbout);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHero(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color titleColor,
    Color descColor,
    Color cardBg,
  ) {
    String currentAlias = SingleAccountPageState.ofUserInfo(context).alias ?? "";
    String displayName = currentAlias.isNotEmpty ? currentAlias : userName;
    String host = SingleAccountPageState.ofUserInfo(context).host ?? "";

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 16,
        16,
        18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(isDark ? 0.22 : 0.12),
            isDark ? const Color(0xff18181B) : Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: (userIcon != null && userIcon!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: userIcon!,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Image.asset(
                            getImageByVIPLogo(),
                            width: 58,
                            height: 58,
                          ),
                          errorWidget: (_, __, ___) => Image.asset(
                            getImageByVIPLogo(),
                            width: 58,
                            height: 58,
                          ),
                        )
                      : Image.asset(
                          getImageByVIPLogo(),
                          width: 58,
                          height: 58,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (host.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff27272A) : const Color(0xffE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          host.replaceFirst(RegExp(r'^https?://'), ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: descColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Switch Account Button
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                borderRadius: BorderRadius.circular(12),
                color: isDark ? const Color(0xff27272A) : const Color(0xffF1F5F9),
                onPressed: () {
                  if (SpUtil.getBool(spSingleInstance, defValue: false)) {
                    "当前处于单实例模式".toast();
                    return;
                  }
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          const ChangeAccountPage(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
                child: Icon(
                  CupertinoIcons.arrow_2_squarepath,
                  size: 20,
                  color: primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Poetic Quote Banner
          Obx(
            () => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (poetData.isEmpty) return;
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => PoetPage(data: poetData),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff22222A) : const Color(0xffF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xff2E2E38) : const Color(0xffE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.quote_bubble,
                      size: 14,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        desc.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: descColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 12,
                      color: descColor.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHub(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color titleColor,
    Color cardBg,
  ) {
    bool isUpper2_13 = false;
    try {
      isUpper2_13 = getIt<SystemBean>(
        instanceName: (SingleAccountPageState.of(context)?.index ?? 0).toString(),
      ).isUpperVersion2_13_0();
    } catch (e) {
      isUpper2_13 = true;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: _buildHubCard(
              title: isUpper2_13 ? "订阅管理" : "拉库管理",
              icon: CupertinoIcons.arrow_2_circlepath_circle_fill,
              iconColor: const Color(0xff10B981),
              cardBg: cardBg,
              isDark: isDark,
              titleColor: titleColor,
              onTap: () {
                if (isUpper2_13) {
                  Navigator.of(context).pushNamed(Routes.routeSubscribeList);
                } else {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const TaskPage(onlyShowPullRepo: true),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildHubCard(
              title: "脚本管理",
              icon: CupertinoIcons.doc_text_fill,
              iconColor: const Color(0xff3B82F6),
              cardBg: cardBg,
              isDark: isDark,
              titleColor: titleColor,
              onTap: () {
                Navigator.of(context).pushNamed(Routes.routeScript);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildHubCard(
              title: "依赖管理",
              icon: CupertinoIcons.cube_box_fill,
              iconColor: const Color(0xff8B5CF6),
              cardBg: cardBg,
              isDark: isDark,
              titleColor: titleColor,
              onTap: () {
                Navigator.of(context).pushNamed(Routes.routeDependency);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color cardBg,
    required bool isDark,
    required Color titleColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xff27272A) : const Color(0xffE2E8F0),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required Color cardBg,
    required Color primaryColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xff27272A) : const Color(0xffE2E8F0),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Icon(icon, size: 15, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool hideDivider = false,
  }) {
    bool isDark = ref.watch(themeProvider).themeMode == modeDark;
    Color titleColor = ref.watch(themeProvider).themeColor.titleColor();
    Color descColor = ref.watch(themeProvider).themeColor.descColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
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
                            fontWeight: FontWeight.w500,
                            color: titleColor,
                          ),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: descColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 15,
                    color: descColor.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!hideDivider)
          Divider(
            height: 1,
            indent: 52,
            endIndent: 16,
            thickness: 0.5,
            color: isDark ? const Color(0xff27272A) : const Color(0xffF1F5F9),
          ),
      ],
    );
  }

  void _delLog(BuildContext context) async {
    EasyLoading.show(status: "获取配置中...");
    String day = "7";

    try {
      var response = await SingleAccountPageState.ofApi(context)
          .logDel()
          .timeout(const Duration(seconds: 5));
      if (response.success && response.bean != null) {
        if (response.bean?.frequency != null) {
          day = response.bean!.frequency!.toString();
        } else if (response.bean?.info?.frequency != null) {
          day = response.bean!.info!.frequency.toString();
        }
      }
    } catch (_) {} finally {
      EasyLoading.dismiss();
    }

    final theme = ref.read(themeProvider);
    final isDark = theme.isDark();
    final primaryColor = theme.primaryColor;
    final cardBg = theme.themeColor.settingBgColor();
    final titleColor = theme.themeColor.titleColor();
    final descColor = theme.themeColor.descColor();

    TextEditingController controller = TextEditingController(text: day);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xff14B8A6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.trash_circle_fill,
                          color: Color(0xff14B8A6),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "自动清理日志设置",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "按设定的周期自动清除历史执行日志",
                              style: TextStyle(fontSize: 12, color: descColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "常用清理周期",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: descColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      {"label": "3 天", "val": "3"},
                      {"label": "7 天 (推荐)", "val": "7"},
                      {"label": "15 天", "val": "15"},
                      {"label": "30 天", "val": "30"},
                      {"label": "不清理 (留空)", "val": ""},
                    ].map((item) {
                      final isSelected = controller.text == item["val"];
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setModalState(() {
                            controller.text = item["val"]!;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withOpacity(0.15)
                                : (isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.black.withOpacity(0.03)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.grey.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            item["label"]!,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? primaryColor : titleColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "自定义清理频率 (天)",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: descColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                    decoration: InputDecoration(
                      hintText: "留空或填 0 表示不自动清理",
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: descColor.withOpacity(0.5),
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: const Icon(
                        CupertinoIcons.calendar,
                        size: 18,
                      ),
                      suffixText: "天",
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 24),
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
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text("取消"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            final val = int.tryParse(controller.text.trim()) ?? 0;
                            commitLogDel(val);
                          },
                          child: const Text(
                            "保存设置",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void commitLogDel(int time) async {
    EasyLoading.show(status: "保存中...");
    var response = await SingleAccountPageState.ofApi(context).logDelTime(time);
    EasyLoading.dismiss();
    if (response.success) {
      "清理频率更新成功".toast();
    } else {
      response.message.toast();
    }
  }

  Widget buildOtherFun(
    String title,
    String icon,
    GestureTapCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 2,
      ),
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 3,
          ),
          child: Column(
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                    ref.watch(themeProvider).primaryColor, BlendMode.srcIn),
                child: Image.asset(
                  icon,
                  width: 24,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: ref.watch(themeProvider).themeColor.titleColor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOtherFun2(
    String title,
    IconData icon,
    GestureTapCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 2,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 3,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: ref.watch(themeProvider).primaryColor,
                size: 24,
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: ref.watch(themeProvider).themeColor.titleColor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getImageByVIP() {
    return "assets/images/normal.png";
  }

  String getImageByVIPLogo() {
    return "assets/images/ql.png";
  }

  @override
  void onLazyLoad() async {
    var response = await SingleAccountPageState.ofApi(context).user();

    if (response.success) {
      userIcon = response.bean?.avatar;
      userName = response.bean?.username ?? "青龙客户端";
      if (userIcon != null && userIcon!.isNotEmpty) {
        userIcon =
            "${SingleAccountPageState.ofUserInfo(context).host}/api/static/$userIcon";
      }
      setState(() {});
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadPoet();
    });
  }

  void delLogsByExperiedDate() async {
    try {
      int before = SpUtil.getInt(spLocalBackUpFileExperiedTime,
          defValue: getDefaultLogExperiedTime());
      String now = DateFormat('yyyy-MM-dd').format(DateTime.now()); //获取多少天前的日期

      print("...$before天之前的文件全部删除");

      Directory directory = Directory(
          "${await FileUtil(SingleAccountPageState.of(context)?.index ?? 0).localPath}/");

      List<FileSystemEntity> list = directory.listSync();

      for (FileSystemEntity file in list) {
        String date = ints.basename(file.path);
        var a = DateTime.tryParse(date);
        var b = DateTime.tryParse(now);

        if (a != null && b != null) {
          if (b.difference(a).inDays > before) {
            if (await file.exists()) {
              await file.delete(recursive: true);
              print("删除成功${file.path}");
            }
          } else {
            print("不用删除${file.path}");
          }
        } else {
          print("时间格式出错${file.path}");
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> loadPoet() async {
    try {
      Dio dio = Dio(BaseOptions(
        receiveTimeout: 10000,
        connectTimeout: 10000,
      ));

      if (!SpUtil.haveKey(spPoetToken)) {
        var tokenResponse = await dio.get("https://v2.jinrishici.com/token");

        if (tokenResponse.statusCode == 200) {
          String? token = tokenResponse.data["data"];
          if (token != null && token.isNotEmpty) {
            SpUtil.putString(spPoetToken, token);
          }
        }
      }

      var response = await dio.get("https://v2.jinrishici.com/one.json",
          options: Options(
            headers: {
              "X-User-Token": SpUtil.getString(spPoetToken, defValue: ""),
            },
          ));
      if (response.statusCode == 200) {
        poetData.clear();
        poetData.addAll(response.data as Map<String, dynamic>);
        desc.value = poetData["data"]?["content"]?.toString() ?? "欢迎使用青龙客户端";
      }
    } catch (e) {}
  }
}

int getDefaultLogExperiedTime() {
  int count = 5;
  if (SpUtil.getInt(spVIP, defValue: typeNormal) == typeVIP) {
    count = 5;
  } else {
    count = 30;
  }
  return count;
}
