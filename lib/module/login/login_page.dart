import 'package:dio/dio.dart';
import 'package:dio_log/dio_log.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animator/flutter_animator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/multi_account_userinfo_viewmodel.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/in_app_purchase_page.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/login_helper.dart';
import 'package:qinglong_app/utils/sp_utils.dart';
import 'package:qinglong_app/utils/utils.dart';

import '../others/change_account_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  final bool fromAddNewAccount;

  const LoginPage({
    Key? key,
    this.fromAddNewAccount = false,
  }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool rememberPassword = true;
  bool _obscurePassword = true;
  bool isLoading = false;
  bool isTestingHost = false;
  String? testHostResult;
  bool? testHostSuccess;

  final GlobalKey<AnimatorWidgetState> loginKey = GlobalKey<AnimatorWidgetState>();
  LoginHelper? helper;

  @override
  void initState() {
    super.initState();
    if (!widget.fromAddNewAccount) {
      final userInfo = SingleAccountPageState.ofUserInfo(context);
      _hostController.text = userInfo.host ?? "";
      if (userInfo.userName != null && userInfo.userName!.isNotEmpty) {
        _userNameController.text = userInfo.userName!;
        rememberPassword = true;
      }
      if (userInfo.passWord != null && userInfo.passWord!.isNotEmpty) {
        _passwordController.text = userInfo.passWord!;
      }
      if (userInfo.alias != null && userInfo.alias!.isNotEmpty) {
        _aliasController.text = userInfo.alias!;
      }
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _aliasController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool canClickLoginBtn() {
    if (isLoading) return false;
    if (_hostController.text.trim().isEmpty) return false;
    return _userNameController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
  }

  Future<void> _testHostConnectivity() async {
    final raw = _hostController.text.trim();
    if (raw.isEmpty) {
      "请先输入服务器地址".toast();
      return;
    }

    String clean = raw;
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
      _hostController.text = clean;
    }
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
      _hostController.text = clean;
    }

    setState(() {
      isTestingHost = true;
      testHostResult = null;
      testHostSuccess = null;
    });

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: 4000,
        receiveTimeout: 4000,
        validateStatus: (status) => true,
      ));
      final resp = await dio.get('$clean/api/system');
      if (resp.statusCode == 200) {
        String ver = '';
        if (resp.data is Map && resp.data['data'] != null) {
          ver = resp.data['data']['version'] ?? '';
        }
        setState(() {
          testHostSuccess = true;
          testHostResult = ver.isNotEmpty ? "连通正常 (v$ver)" : "连通正常 (200)";
        });
      } else if (resp.statusCode != null && resp.statusCode! < 500) {
        setState(() {
          testHostSuccess = true;
          testHostResult = "服务已响应 (${resp.statusCode})";
        });
      } else {
        setState(() {
          testHostSuccess = false;
          testHostResult = "响应异常 (${resp.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        testHostSuccess = false;
        testHostResult = "无法连接至该服务器";
      });
    } finally {
      if (mounted) setState(() => isTestingHost = false);
    }
  }

  Future<void> login() async {
    String host = _hostController.text.trim();
    if (!host.startsWith("http://") && !host.startsWith("https://")) {
      host = "http://$host";
      _hostController.text = host;
    }
    while (host.endsWith("/")) {
      host = host.substring(0, host.length - 1);
      _hostController.text = host;
    }

    SingleAccountPageState.of(context)?.registerHttp(host);
    SingleAccountPageState.ofHttp(context)?.pushedLoginPage = false;
    Utils.hideKeyBoard(context);

    setState(() => isLoading = true);

    helper = LoginHelper(
      host,
      _userNameController.text.trim(),
      _passwordController.text.trim(),
      rememberPassword,
      _aliasController.text.trim(),
    );

    var response = await helper!.login(context);
    dealLoginResponse(response);
  }

  void dealLoginResponse(int response) {
    if (response == LoginHelper.success) {
      Navigator.of(context).pushReplacementNamed(Routes.routeHomePage);
    } else if (response == LoginHelper.failed) {
      loginFailed();
    } else {
      twoFact();
    }
  }

  void loginFailed() {
    isLoading = false;
    loginKey.currentState?.forward();
    setState(() {});
  }

  void twoFact() {
    String twoFactCode = "";
    showCupertinoDialog(
      useRootNavigator: false,
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("两步验证 (2FA)"),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "该青龙实例已开启两步验证，请输入验证器中的 6 位动态验证码：",
                style: TextStyle(fontSize: 13, color: Color(0xff666666)),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: CupertinoTextField(
                  placeholder: "6 位数字验证码",
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                  onChanged: (value) => twoFactCode = value.trim(),
                  autofocus: true,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: Text("确认登录", style: TextStyle(color: ref.watch(themeProvider).primaryColor)),
            onPressed: () async {
              Navigator.of(context).pop(true);
              if (helper != null) {
                var response = await helper!.loginTwice(context, twoFactCode);
                dealLoginResponse(response);
              } else {
                "状态异常，请重新点击登录".toast();
              }
            },
          ),
        ],
      ),
    ).then((value) {
      if (value == null) {
        isLoading = false;
        setState(() {});
      }
    });
  }

  void _showHistoryAccountsSheet(BuildContext context, bool isDark, Color primaryColor) {
    final historyAccounts = getIt<MultiAccountUserInfoViewModel>().historyAccounts;
    if (historyAccounts.isEmpty) return;

    final cardBg = isDark ? const Color(0xFF1E2638) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final descColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final list = getIt<MultiAccountUserInfoViewModel>().historyAccounts;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: descColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.history_rounded, size: 18, color: primaryColor),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "历史登录账号",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "共 ${list.length} 个",
                          style: TextStyle(fontSize: 12, color: descColor),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text("暂无历史账号", style: TextStyle(color: descColor, fontSize: 14)),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shrinkWrap: true,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final bean = list[index];
                        final alias = (bean.alias?.isNotEmpty == true)
                            ? bean.alias!
                            : (bean.userName?.isNotEmpty == true ? bean.userName! : "青龙实例 #${index + 1}");
                        final host = bean.host ?? "未知地址";

                        return Material(
                          color: isDark ? const Color(0xFF131B2A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.of(modalCtx).pop();
                              setState(() {
                                _hostController.text = bean.host ?? "";
                                _userNameController.text = bean.userName ?? "";
                                _passwordController.text = bean.password ?? "";
                                _aliasController.text = bean.alias ?? "";
                                rememberPassword = true;
                                testHostResult = null;
                                testHostSuccess = null;
                              });
                              "已快速填入该账号".toast();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.dns_rounded, size: 20, color: primaryColor),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alias,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: titleColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
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
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.trash, size: 18),
                                    color: const Color(0xffEF4444).withOpacity(0.8),
                                    tooltip: "删除记录",
                                    onPressed: () {
                                      getIt<MultiAccountUserInfoViewModel>().removeHistoryAccount(bean.host);
                                      setModalState(() {});
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark || theme.isDark();
    final primaryColor = theme.primaryColor;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E2638) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final descColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final fieldBg = isDark ? const Color(0xFF131B2A) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

    final canPop = Navigator.of(context).canPop() ||
        widget.fromAddNewAccount ||
        SpUtil.getBool(spSingleInstance, defValue: false);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 顶部导航栏
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (canPop)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          color: titleColor,
                          tooltip: "返回",
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      else
                        const SizedBox(width: 40),
                      Text(
                        "青龙面板登录",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_horiz_rounded, size: 24),
                        color: primaryColor,
                        tooltip: "切换青龙实例",
                        onPressed: () {
                          if (SpUtil.getInt(spVIP, defValue: typeNormal) == typeNormal) {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) => const InAppPurchasePage(fromDirectly: true),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).push(
                            CupertinoPageRoute(builder: (context) => const ChangeAccountPage()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 品牌 Logo 与欢迎标语
                  GestureDetector(
                    onDoubleTap: () {
                      if (debugBtnIsShow()) {
                        dismissDebugBtn();
                      } else {
                        showDebugBtn(context, btnColor: primaryColor);
                      }
                    },
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          "assets/images/ql.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    "欢迎使用青龙面板",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "连接您的青龙自动化服务器，随时随地掌握定时任务",
                    style: TextStyle(
                      fontSize: 13,
                      color: descColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 表单输入主卡片
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 服务器地址标题 & 连通性测试
                        Row(
                          children: [
                            Text(
                              "服务器地址",
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                            const Text(
                              " *",
                              style: TextStyle(fontSize: 14, color: Color(0xffEF4444)),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: isTestingHost ? null : _testHostConnectivity,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (testHostSuccess == true)
                                      ? const Color(0xff10B981).withOpacity(0.12)
                                      : (testHostSuccess == false)
                                          ? const Color(0xffEF4444).withOpacity(0.12)
                                          : primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isTestingHost)
                                      const SizedBox(
                                        width: 11,
                                        height: 11,
                                        child: CircularProgressIndicator(strokeWidth: 1.5),
                                      )
                                    else
                                      Icon(
                                        (testHostSuccess == true)
                                            ? Icons.check_circle_rounded
                                            : (testHostSuccess == false)
                                                ? Icons.error_rounded
                                                : Icons.speed_rounded,
                                        size: 13,
                                        color: (testHostSuccess == true)
                                            ? const Color(0xff10B981)
                                            : (testHostSuccess == false)
                                                ? const Color(0xffEF4444)
                                                : primaryColor,
                                      ),
                                    const SizedBox(width: 4),
                                    Text(
                                      testHostResult ?? (isTestingHost ? "测试中..." : "测试连通"),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: (testHostSuccess == true)
                                            ? const Color(0xff10B981)
                                            : (testHostSuccess == false)
                                                ? const Color(0xffEF4444)
                                                : primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 服务器地址输入框
                        Container(
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: _hostController,
                            keyboardType: TextInputType.url,
                            style: TextStyle(fontSize: 14, color: titleColor, fontFamily: 'monospace'),
                            onChanged: (_) {
                              if (testHostResult != null) {
                                setState(() {
                                  testHostResult = null;
                                  testHostSuccess = null;
                                });
                              } else {
                                setState(() {});
                              }
                            },
                            decoration: InputDecoration(
                              hintText: "http://IP或域名:5700",
                              hintStyle: TextStyle(fontSize: 13, color: descColor.withOpacity(0.6)),
                              prefixIcon: Icon(Icons.dns_rounded, size: 19, color: primaryColor),
                              suffixIcon: _hostController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(CupertinoIcons.clear_circled_solid, size: 16),
                                      color: descColor.withOpacity(0.7),
                                      onPressed: () {
                                        _hostController.clear();
                                        setState(() {
                                          testHostResult = null;
                                          testHostSuccess = null;
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 账号输入
                        Text(
                          "青龙账号",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: _userNameController,
                            style: TextStyle(fontSize: 14, color: titleColor),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: "请输入用户名或登录账号",
                              hintStyle: TextStyle(fontSize: 13, color: descColor.withOpacity(0.6)),
                              prefixIcon: Icon(CupertinoIcons.person_fill, size: 19, color: primaryColor),
                              suffixIcon: _userNameController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(CupertinoIcons.clear_circled_solid, size: 16),
                                      color: descColor.withOpacity(0.7),
                                      onPressed: () {
                                        _userNameController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 密码输入
                        Text(
                          "登录密码",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(fontSize: 14, color: titleColor),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: "请输入青龙面板密码",
                              hintStyle: TextStyle(fontSize: 13, color: descColor.withOpacity(0.6)),
                              prefixIcon: Icon(CupertinoIcons.lock_fill, size: 19, color: primaryColor),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                                      size: 19,
                                      color: descColor.withOpacity(0.7),
                                    ),
                                    tooltip: _obscurePassword ? "显示密码" : "隐藏密码",
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  if (_passwordController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(CupertinoIcons.clear_circled_solid, size: 16),
                                      color: descColor.withOpacity(0.7),
                                      onPressed: () {
                                        _passwordController.clear();
                                        setState(() {});
                                      },
                                    ),
                                ],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 别名输入 (选填)
                        Text(
                          "实例别名 (选填)",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: _aliasController,
                            inputFormatters: [LengthLimitingTextInputFormatter(20)],
                            style: TextStyle(fontSize: 14, color: titleColor),
                            decoration: InputDecoration(
                              hintText: "例如：家庭NAS、云服务器（仅展示使用）",
                              hintStyle: TextStyle(fontSize: 13, color: descColor.withOpacity(0.6)),
                              prefixIcon: Icon(CupertinoIcons.tag_fill, size: 18, color: primaryColor),
                              suffixIcon: _aliasController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(CupertinoIcons.clear_circled_solid, size: 16),
                                      color: descColor.withOpacity(0.7),
                                      onPressed: () {
                                        _aliasController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 记住密码选项
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: rememberPassword,
                                activeColor: primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                onChanged: (val) {
                                  setState(() => rememberPassword = val ?? false);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() => rememberPassword = !rememberPassword);
                              },
                              child: Text(
                                "记住密码与登录配置",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: titleColor.withOpacity(0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 登录主按钮
                  Shake(
                    preferences: const AnimationPreferences(autoPlay: AnimationPlayStates.None),
                    key: loginKey,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: canClickLoginBtn()
                              ? [primaryColor, primaryColor.withOpacity(0.85)]
                              : [primaryColor.withOpacity(0.4), primaryColor.withOpacity(0.3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: canClickLoginBtn()
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: canClickLoginBtn() ? login : null,
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        "立即登录",
                                        style: TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_rounded, size: 19, color: Colors.white),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 历史账号入口
                  if (getIt<MultiAccountUserInfoViewModel>().historyAccounts.isNotEmpty)
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: descColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        icon: Icon(Icons.history_rounded, size: 17, color: primaryColor),
                        label: Text(
                          "历史已存账号 (${getIt<MultiAccountUserInfoViewModel>().historyAccounts.length})",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: descColor,
                          ),
                        ),
                        onPressed: () => _showHistoryAccountsSheet(context, isDark, primaryColor),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
