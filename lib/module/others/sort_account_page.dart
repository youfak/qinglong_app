import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/multi_account_userinfo_viewmodel.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../../main.dart';

class SortAccountPage extends ConsumerStatefulWidget {
  const SortAccountPage({Key? key}) : super(key: key);

  @override
  _SortAccountPageState createState() => _SortAccountPageState();
}

class _SortAccountPageState extends ConsumerState<SortAccountPage> {
  List<TokenBean> list = [];

  @override
  void initState() {
    super.initState();
    try {
      String json =
          jsonEncode(getIt<MultiAccountUserInfoViewModel>().tokenBeans);
      list.addAll(
          (jsonDecode(json) as List).map((e) => TokenBean.fromJson(e)).toList());
    } catch (_) {}
    FocusManager.instance.primaryFocus?.unfocus();
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

    return Scaffold(
      backgroundColor: theme.themeColor.bg2Color(),
      appBar: QlAppBar(
        title: "账号排序",
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                getIt<MultiAccountUserInfoViewModel>().resetTokenBeans(list);
                "排序已保存，重启 App 后生效".toast();
                Navigator.of(context).pop();
              },
              child: const Text(
                "保存",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: list.isEmpty
          ? Center(
              child: Text(
                "暂无配置账号",
                style: TextStyle(color: descColor, fontSize: 14),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 提示栏
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          color: primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "按住卡片右侧的拖拽图标上下滑动，即可调整多实例的展示顺序。",
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor.withOpacity(0.9),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 可排序列表
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    onReorder: (int oldIndex, int newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final TokenBean item = list.removeAt(oldIndex);
                        list.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final alias = item.alias?.isNotEmpty == true
                          ? item.alias!
                          : "青龙实例 #${index + 1}";
                      final host = item.host?.isNotEmpty == true
                          ? item.host!
                          : "未设置服务器地址";

                      return Container(
                        key: ValueKey(item.host ?? index.toString()),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // 序号
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.black.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: titleColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 别名与主机
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
                              const SizedBox(width: 10),

                              // 拖动手柄
                              Icon(
                                CupertinoIcons.bars,
                                color: descColor.withOpacity(0.5),
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
    );
  }
}
