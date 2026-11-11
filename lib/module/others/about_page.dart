import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_review/launch_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/qlvisible.dart';
import 'package:qinglong_app/module/home/system_bean.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage>
    with LazyLoadState<AboutPage> {
  String desc = "";
  String versionCode = "";

  @override
  void initState() {
    super.initState();
    getInfo();
  }

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
        : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: theme.themeColor.bg2Color(),
      appBar: QlAppBar(
        canBack: true,
        title: "关于软件",
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 1. 顶部 Hero Logo 与版本信息
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      "assets/images/ql.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "青龙移动客户端",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    desc.isNotEmpty ? "v$desc (Build $versionCode)" : "v2.0.0",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "基于青龙开源项目打造的现代化 ${getPlatformName()} 极客工作台",
                  style: TextStyle(
                    color: descColor,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 2. 版本与服务端状态
          _buildSectionTitle("版本与服务", primaryColor, descColor),
          const SizedBox(height: 8),
          _buildCardGroup(
            cardBg: cardBg,
            borderColor: borderColor,
            children: [
              _buildTile(
                icon: CupertinoIcons.sparkles,
                iconColor: const Color(0xff10B981),
                title: "青龙服务端版本",
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "v${systemBean.version}",
                      style: TextStyle(
                        fontSize: 13,
                        color: descColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: descColor.withOpacity(0.5),
                    ),
                  ],
                ),
                titleColor: titleColor,
                onTap: _checkUpdate,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. 互动与支持
          _buildSectionTitle("互联与支持", primaryColor, descColor),
          const SizedBox(height: 8),
          _buildCardGroup(
            cardBg: cardBg,
            borderColor: borderColor,
            children: [
              QlVisible(
                child: _buildTile(
                  icon: CupertinoIcons.heart_fill,
                  iconColor: const Color(0xffEC4899),
                  title: "在 App Store 给予五星好评",
                  titleColor: titleColor,
                  onTap: () {
                    LaunchReview.launch(
                        writeReview: false, iOSAppId: "1625871665");
                  },
                ),
                childReplace: _buildTile(
                  icon: CupertinoIcons.cloud_download_fill,
                  iconColor: const Color(0xff06B6D4),
                  title: "最新 APK 下载与发布频道",
                  titleColor: titleColor,
                  onTap: () => _launchURL("https://t.me/qinglongapp"),
                ),
              ),
              _buildDivider(borderColor),
              _buildTile(
                icon: CupertinoIcons.paperplane_fill,
                iconColor: const Color(0xff3B82F6),
                title: "官方更新通知频道 (Telegram)",
                titleColor: titleColor,
                onTap: () => _launchURL("https://t.me/qinglongapp"),
              ),
              _buildDivider(borderColor),
              _buildTile(
                icon: CupertinoIcons.share,
                iconColor: const Color(0xff8B5CF6),
                title: "分享客户端给好友",
                titleColor: titleColor,
                onTap: () {
                  if (Platform.isAndroid) {
                    Share.share(
                        "分享一款好用的青龙客户端，快去下载体验吧：https://t.me/qinglongapp");
                  } else {
                    Share.share(
                        "分享一款好用的青龙客户端：https://apps.apple.com/us/app/id1625871665");
                  }
                },
              ),
              _buildDivider(borderColor),
              _buildTile(
                icon: CupertinoIcons.shield_lefthalf_fill,
                iconColor: const Color(0xffF59E0B),
                title: "用户协议与隐私保护",
                titleColor: titleColor,
                onTap: () =>
                    _launchURL("https://newtab.work/PrivacyPolicy.html"),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // 底部声明
          Center(
            child: Column(
              children: [
                Text(
                  "所有凭证与配置均安全保存在本地，不上传任何第三方服务器",
                  style: TextStyle(
                    color: descColor.withOpacity(0.7),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "QingLong Mobile · Designed with Material 3",
                  style: TextStyle(
                    color: descColor.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color primaryColor, Color descColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: descColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

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

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color titleColor,
    Widget? trailing,
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
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                ),
              ),
            ),
            trailing ??
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 15,
                  color: Colors.grey.withOpacity(0.5),
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

  void _launchURL(String urlStr) async {
    try {
      await launchUrl(Uri.tryParse(urlStr.trim())!);
    } catch (e) {
      logger.e(e);
    }
  }

  void getInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      desc = packageInfo.version;
      versionCode = packageInfo.buildNumber;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void onLazyLoad() {}

  void _checkUpdate() async {
    var response = await SingleAccountPageState.ofApi(context).checkUpdate();
    if (response.success) {
      if (response.bean?.hasNewVersion ?? false) {
        showCupertinoDialog(
          context: context,
          useRootNavigator: false,
          builder: (childContext) => CupertinoAlertDialog(
            title: Text("青龙服务端发现新版本 ${response.bean?.lastVersion}"),
            content: Padding(
              padding: const EdgeInsets.only(left: 5, top: 8),
              child: Text(
                "${response.bean?.lastLog}",
                textAlign: TextAlign.left,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text("知道了"),
                onPressed: () => Navigator.of(childContext).pop(),
              ),
            ],
          ),
        );
      } else {
        "当前青龙服务端已经是最新版本".toast();
      }
    }
  }
}

String getPlatformName() {
  if (Platform.isAndroid) return "Android";
  return "iOS";
}
