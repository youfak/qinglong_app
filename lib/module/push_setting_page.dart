import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/sp_utils.dart';

class PushSettingPage extends ConsumerStatefulWidget {
  const PushSettingPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PushSettingPage> createState() => _PushSettingPageState();
}

class _PushSettingPageState extends ConsumerState<PushSettingPage> {
  final List<PushBean> list = [];
  PushBean? current;
  bool loading = true;
  final Map<String, bool> _obscureMap = {};

  @override
  void initState() {
    super.initState();
    initData();
    onLazyLoad();
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

    final isClosed = current == null || current!.key == "已关闭";
    final meta = getChannelMeta(current?.key ?? "已关闭");

    return Scaffold(
      backgroundColor: theme.themeColor.bg2Color(),
      appBar: QlAppBar(
        title: "通知设置",
        actions: [
          TextButton(
            onPressed: commit,
            child: Text(
              "保存",
              style: TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(child: LoadingWidget())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. 当前渠道 Hero 状态卡片
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
                              color: meta.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              meta.icon,
                              color: meta.color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      getNameByKey(current?.key ?? "已关闭"),
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: titleColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isClosed
                                            ? Colors.grey.withOpacity(0.15)
                                            : primaryColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        isClosed ? "未启用" : "生效中",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isClosed
                                              ? descColor
                                              : primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  meta.subtitle,
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
                      const SizedBox(height: 14),
                      Divider(height: 1, color: borderColor),
                      const SizedBox(height: 12),
                      // 快捷切换渠道按钮
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _showChannelPicker(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.arrow_2_squarepath,
                                size: 16,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "切换推送通道 (共 ${list.length} 个可用通道)",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 14,
                                color: descColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. 字段配置区域
                if (isClosed)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.bell_slash,
                            size: 48,
                            color: descColor.withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "当前推送通道已关闭",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "定时任务运行结果及通知将不会推送到任何第三方服务。\n点击上方“切换推送通道”可选择开启。",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: descColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.slider_horizontal_3,
                        size: 15,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${getNameByKey(current!.key)} 参数配置",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: descColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: current!.children.map((child) {
                        final isPassword = child.key.toLowerCase().contains("key") ||
                            child.key.toLowerCase().contains("token") ||
                            child.key.toLowerCase().contains("secret") ||
                            child.key.toLowerCase().contains("pass");
                        final isObscure = _obscureMap[child.key] ?? isPassword;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    child.key,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: titleColor,
                                    ),
                                  ),
                                  if (child.required) ...[
                                    const SizedBox(width: 4),
                                    const Text(
                                      "*",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                child.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: descColor,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: child.controller,
                                obscureText: isObscure,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: titleColor,
                                  fontFamily: isPassword ? 'monospace' : null,
                                ),
                                decoration: InputDecoration(
                                  hintText: "请输入 ${child.key}",
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: descColor.withOpacity(0.6),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  suffixIcon: isPassword
                                      ? IconButton(
                                          icon: Icon(
                                            isObscure
                                                ? CupertinoIcons.eye_slash
                                                : CupertinoIcons.eye,
                                            size: 18,
                                            color: descColor,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureMap[child.key] =
                                                  !isObscure;
                                            });
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // 3. 底部保存大按钮
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: commit,
                  child: const Text(
                    "保存通知配置",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  // 现代 M3 渠道选择底部工作表
  void _showChannelPicker(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final cardBg = theme.themeColor.settingBgColor();
    final titleColor = theme.themeColor.titleColor();
    final descColor = theme.themeColor.descColor();
    final primaryColor = theme.primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        "选择推送通道",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill),
                        color: descColor.withOpacity(0.4),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 52,
                      color: Colors.grey.withOpacity(0.08),
                    ),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final isSelected = current?.key == item.key;
                      final meta = getChannelMeta(item.key);

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            current = item;
                          });
                          Navigator.of(ctx).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: meta.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  meta.icon,
                                  color: meta.color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      getNameByKey(item.key),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? primaryColor
                                            : titleColor,
                                      ),
                                    ),
                                    Text(
                                      meta.subtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: descColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  CupertinoIcons.checkmark_circle_fill,
                                  color: primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void initData() {
    var pushSetting = {
      "gotify": [
        {
          "label": 'gotifyUrl',
          "tip": 'gotify的url地址,例如 https://push.example.de:8080',
          "required": true,
        },
        {"label": 'gotifyToken', "tip": 'gotify的消息应用token码', "required": true},
        {"label": 'gotifyPriority', "tip": '推送消息的优先级'},
      ],
      "goCqHttpBot": [
        {
          "label": 'goCqHttpBotUrl',
          "tip":
              '推送到个人QQ: http://127.0.0.1/send_private_msg，群：http://127.0.0.1/send_group_msg',
          "required": true,
        },
        {"label": 'goCqHttpBotToken', "tip": '访问密钥', "required": true},
        {
          "label": 'goCqHttpBotQq',
          "tip":
              '如果GOBOT_URL设置 /send_private_msg 则需要填入 user_id=个人QQ 相反如果是 /send_group_msg 则需要填入 group_id=QQ群',
          "required": true,
        },
      ],
      "serverChan": [
        {"label": 'serverChanKey', "tip": 'Server酱SENDKEY', "required": true},
      ],
      "pushDeer": [
        {
          "label": 'pushDeerKey',
          "tip": 'PushDeer的Key，https://github.com/easychen/pushdeer',
          "required": true,
        },
      ],
      "bark": [
        {
          "label": 'barkPush',
          "tip": 'Bark的信息IP/设备码，例如：https://api.day.app/XXXXXXXX',
          "required": true,
        },
        {
          "label": 'barkIcon',
          "tip": 'BARK推送图标,自定义推送图标 (需iOS15或以上才能显示)',
        },
        {"label": 'barkSound', "tip": 'BARK推送铃声,铃声列表去APP查看复制填写'},
        {"label": 'barkGroup', "tip": 'BARK推送消息的分组, 默认为qinglong'},
      ],
      "telegramBot": [
        {
          "label": 'telegramBotToken',
          "tip":
              'telegram机器人的token，例如：1077xxx4424:AAFjv0FcqxxxxxxgEMGfi22B4yh15R5uw',
          "required": true,
        },
        {
          "label": 'telegramBotUserId',
          "tip": 'telegram用户的id，例如：129xxx206',
          "required": true,
        },
        {"label": 'telegramBotProxyHost', "tip": '代理IP'},
        {"label": 'telegramBotProxyPort', "tip": '代理端口'},
        {
          "label": 'telegramBotProxyAuth',
          "tip": 'telegram代理配置认证参数, 用户名与密码用英文冒号连接 user:password',
        },
        {
          "label": 'telegramBotApiHost',
          "tip": 'telegram api自建的反向代理地址，默认tg官方api',
        },
      ],
      "dingtalkBot": [
        {
          "label": 'dingtalkBotToken',
          "tip":
              '钉钉机器人webhook token，例如：5a544165465465645d0f31dca676e7bd07415asdasd',
          "required": true,
        },
        {
          "label": 'dingtalkBotSecret',
          "tip": '密钥，机器人安全设置页面，加签一栏下面显示的SEC开头的字符串',
        },
      ],
      "weWorkBot": [
        {
          "label": 'weWorkBotKey',
          "tip":
              '企业微信机器人的 webhook(详见文档 https://work.weixin.qq.com/api/doc/90000/90136/91770)，例如：693a91f6-7xxx-4bc4-97a0-0ec2sifa5aaa',
          "required": true,
        },
      ],
      "weWorkApp": [
        {
          "label": 'weWorkAppKey',
          "tip":
              'corpid,corpsecret,touser(注:多个成员ID使用|隔开),agentid,消息类型(选填,不填默认文本消息类型) 注意用,号隔开(英文输入法的逗号)，例如：wwcfrs,B-76WERQ,qinglong,1000001,2COat',
          "required": true,
        },
      ],
      "iGot": [
        {
          "label": 'iGotPushKey',
          "tip": 'iGot的信息推送key，例如：https://push.hellyw.com/XXXXXXXX',
          "required": true,
        },
      ],
      "pushPlus": [
        {
          "label": 'pushPlusToken',
          "tip":
              '微信扫码登录后一对一推送或一对多推送下面的token(您的Token)，不提供PUSH_PLUS_USER则默认为一对一推送',
          "required": true,
        },
        {
          "label": 'pushPlusUser',
          "tip":
              '一对多推送的“群组编码”（一对多推送下面->您的群组(如无则新建)->群组编码，如果您是创建群组人。也需点击“查看二维码”扫描绑定，否则不能接受群组消息推送）',
        },
      ],
      "chat": [
        {
          "label": 'chatUrl',
          "tip": 'chat的url地址',
          "required": true,
        },
        {
          "label": 'chatToken',
          "tip": 'chat的token码',
          "required": true,
        },
      ],
      "email": [
        {
          "label": 'emailService',
          "tip":
              '邮箱服务名称，比如126、163、Gmail、QQ等，支持列表https://nodemailer.com/smtp/well-known/',
          "required": true,
        },
        {"label": 'emailUser', "tip": '邮箱地址', "required": true},
        {"label": 'emailPass', "tip": '邮箱SMTP授权码', "required": true},
      ],
      "已关闭": [],
    };

    for (var entry in pushSetting.entries) {
      list.add(PushBean(
        entry.key,
        entry.key,
        entry.value
            .map((e) => PushChildBean(
                  e["label"].toString(),
                  e["tip"].toString(),
                  (e["required"] ?? false) as bool,
                ))
            .toList(),
      ));
    }
  }

  String get _cacheKey {
    final host = SingleAccountPageState.ofUserInfo(context).host ?? "default";
    return "push_notification_cache_$host";
  }

  void onLazyLoad() async {
    Map<String, dynamic>? activeConfig;

    try {
      var response =
          await SingleAccountPageState.ofApi(context).getNotifcation();
      if (response.success && response.bean != null) {
        String result = response.bean!;
        dynamic decoded = jsonDecode(result);
        if (decoded is Map<String, dynamic>) {
          activeConfig = decoded;
          // 多层包装穿透
          if (activeConfig["data"] is Map<String, dynamic>) {
            activeConfig = activeConfig["data"] as Map<String, dynamic>;
          } else if (activeConfig["notification"] is Map<String, dynamic>) {
            activeConfig = activeConfig["notification"] as Map<String, dynamic>;
          } else if (activeConfig["info"] is Map<String, dynamic>) {
            activeConfig = activeConfig["info"] as Map<String, dynamic>;
          }
        }
      }
    } catch (_) {}

    // 本地缓存兜底：若服务端未返回有效配置或解析为空，读取本地缓存
    if (activeConfig == null ||
        activeConfig.isEmpty ||
        activeConfig["type"] == null) {
      String localCache = SpUtil.getString(_cacheKey, defValue: "");
      if (localCache.isNotEmpty) {
        try {
          dynamic localDecoded = jsonDecode(localCache);
          if (localDecoded is Map<String, dynamic> &&
              localDecoded["type"] != null) {
            activeConfig = localDecoded;
          }
        } catch (_) {}
      }
    }

    if (activeConfig != null && activeConfig.isNotEmpty) {
      String type = activeConfig["type"]?.toString() ?? "";
      if (type.isNotEmpty && type != "已关闭") {
        int index = list.indexWhere(
          (element) => element.key.toLowerCase() == type.toLowerCase(),
        );

        if (index >= 0) {
          final matchedChannel = list[index];
          for (var element in matchedChannel.children) {
            // 尝试精确匹配或大小写不敏感匹配
            var val = activeConfig[element.key] ??
                activeConfig[element.key.toLowerCase()];
            element.controller.text = val?.toString() ?? "";
          }
          current = matchedChannel;
          // 保存至本地缓存
          SpUtil.putString(_cacheKey, jsonEncode(activeConfig));
          if (mounted) {
            setState(() {
              loading = false;
            });
          }
          return;
        }
      }
    }

    // 默认回退为已关闭
    current = list.isNotEmpty ? list.last : null;
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void commit() async {
    if (current == null || current!.key == "已关闭") {
      EasyLoading.show(status: "正在保存...");
      var response =
          await SingleAccountPageState.ofApi(context).updateNotifcation({});
      EasyLoading.dismiss();
      if (response.success) {
        SpUtil.remove(_cacheKey);
        "通知已关闭".toast();
        Navigator.of(context).pop();
      } else {
        response.message.toast();
      }
      return;
    }

    int? index = current?.children.indexWhere((element) =>
        element.controller.text.isEmpty && element.required == true);
    index ??= -1;
    if (index >= 0) {
      ("${current?.children[index].key} 为必填项").toast();
      return;
    }

    EasyLoading.show(status: "正在保存...");

    Map<String, dynamic> params = {};
    params["type"] = current!.key.toString();
    params.addAll(current!.children2Json());

    var response =
        await SingleAccountPageState.ofApi(context).updateNotifcation(params);
    EasyLoading.dismiss();
    if (response.success) {
      SpUtil.putString(_cacheKey, jsonEncode(params));
      "通知设置保存成功".toast();
      Navigator.of(context).pop();
    } else {
      response.message.toast();
    }
  }
}

class PushBean {
  String key;
  String name;
  List<PushChildBean> children;

  PushBean(this.key, this.name, this.children);

  Map<String, dynamic> children2Json() {
    Map<String, dynamic> data = {};
    for (var e in children) {
      data[e.key] =
          e.controller.text.isEmpty ? '' : e.controller.text.toString();
    }
    return data;
  }
}

class PushChildBean {
  String key;
  String name;
  bool required;
  TextEditingController controller = TextEditingController();

  PushChildBean(this.key, this.name, this.required);
}

class ChannelMeta {
  final IconData icon;
  final Color color;
  final String subtitle;

  ChannelMeta(this.icon, this.color, this.subtitle);
}

ChannelMeta getChannelMeta(String key) {
  switch (key) {
    case "bark":
      return ChannelMeta(
        CupertinoIcons.device_phone_portrait,
        const Color(0xff0EA5E9),
        "iOS 自定义轻量即时推送",
      );
    case "telegramBot":
      return ChannelMeta(
        CupertinoIcons.paperplane_fill,
        const Color(0xff2563EB),
        "Telegram 官方机器人即时通知",
      );
    case "dingtalkBot":
      return ChannelMeta(
        CupertinoIcons.bolt_horizontal_circle_fill,
        const Color(0xff0284C7),
        "钉钉群自定义机器人 Webhook",
      );
    case "weWorkBot":
      return ChannelMeta(
        CupertinoIcons.chat_bubble_2_fill,
        const Color(0xff16A34A),
        "企业微信内部群机器人 Webhook",
      );
    case "weWorkApp":
      return ChannelMeta(
        CupertinoIcons.building_2_fill,
        const Color(0xff059669),
        "企业微信自建应用消息推送",
      );
    case "pushPlus":
      return ChannelMeta(
        CupertinoIcons.bubble_left_bubble_right_fill,
        const Color(0xff10B981),
        "PushPlus 微信模板消息推送",
      );
    case "serverChan":
      return ChannelMeta(
        CupertinoIcons.radiowaves_right,
        const Color(0xffEC4899),
        "Server酱·Turbo 微信/APP推送",
      );
    case "pushDeer":
      return ChannelMeta(
        CupertinoIcons.ant_fill,
        const Color(0xffF97316),
        "PushDeer 快马轻量推送",
      );
    case "email":
      return ChannelMeta(
        CupertinoIcons.mail_solid,
        const Color(0xff8B5CF6),
        "SMTP 邮箱邮件发送服务",
      );
    case "gotify":
      return ChannelMeta(
        CupertinoIcons.bell_fill,
        const Color(0xff6366F1),
        "Gotify 自建实时消息推送服务器",
      );
    case "goCqHttpBot":
      return ChannelMeta(
        CupertinoIcons.person_2_alt,
        const Color(0xff14B8A6),
        "go-cqhttp 个人或群 QQ 消息推送",
      );
    case "iGot":
      return ChannelMeta(
        CupertinoIcons.app_badge_fill,
        const Color(0xffF43F5E),
        "iGot 聚合消息推送",
      );
    case "chat":
      return ChannelMeta(
        CupertinoIcons.cube_box_fill,
        const Color(0xffD97706),
        "Synology 群晖 Chat 消息推送",
      );
    default:
      return ChannelMeta(
        CupertinoIcons.bell_slash_fill,
        Colors.grey,
        "未开启任何推送通知通道",
      );
  }
}

String getNameByKey(String key) {
  if (key == "gotify") {
    return "Gotify";
  } else if (key == "goCqHttpBot") {
    return "go-cqhttp (QQ)";
  } else if (key == "serverChan") {
    return "Server酱";
  } else if (key == "pushDeer") {
    return "PushDeer";
  } else if (key == "bark") {
    return "Bark (iOS)";
  } else if (key == "telegramBot") {
    return "Telegram 机器人";
  } else if (key == "dingtalkBot") {
    return "钉钉机器人";
  } else if (key == "weWorkBot") {
    return "企业微信机器人";
  } else if (key == "weWorkApp") {
    return "企业微信应用";
  } else if (key == "iGot") {
    return "iGot";
  } else if (key == "pushPlus") {
    return "PushPlus (微信)";
  } else if (key == "chat") {
    return "群晖 Chat";
  } else if (key == "email") {
    return "电子邮箱 (SMTP)";
  }
  return "已关闭";
}
