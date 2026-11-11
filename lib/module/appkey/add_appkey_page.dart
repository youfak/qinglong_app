import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/module/appkey/appkey_viewmodel.dart';
import 'package:qinglong_app/utils/extension.dart';

class AddAppKeyPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> bean;

  const AddAppKeyPage({
    Key? key,
    required this.bean,
  }) : super(key: key);

  @override
  ConsumerState<AddAppKeyPage> createState() => _AddAppKeyPageState();
}

class _AddAppKeyPageState extends ConsumerState<AddAppKeyPage> {
  final TextEditingController _nameController = TextEditingController();

  final List<String> _allPermissions = [
    "定时任务",
    "环境变量",
    "订阅管理",
    "配置文件",
    "脚本管理",
    "任务日志",
    "依赖管理",
    "应用授权",
    "总览看板",
    "登录日志",
    "系统信息",
  ];

  final List<String> selectedPermissions = ["定时任务"];

  @override
  void initState() {
    super.initState();
    if (widget.bean.isNotEmpty) {
      _nameController.text = widget.bean["name"] ?? "";
      selectedPermissions.clear();
      selectedPermissions
          .addAll(AppKeyViewModel.getScopeNames(widget.bean["scopes"]));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

    final isEdit = widget.bean.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.themeColor.bg2Color(),
      appBar: QlAppBar(
        title: isEdit ? "编辑应用" : "创建应用",
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. 应用基本信息
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
                    Icon(
                      CupertinoIcons.app_badge,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "应用名称",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "*",
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  autofocus: false,
                  style: TextStyle(fontSize: 14, color: titleColor),
                  decoration: InputDecoration(
                    hintText: "请输入应用标识名称（如：快捷指令 / 脚本调用）",
                    hintStyle: TextStyle(fontSize: 13, color: descColor),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. 权限多选卡片
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
                    Icon(
                      CupertinoIcons.checkmark_shield,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "权限范围 (可多选)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "*",
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        setState(() {
                          if (selectedPermissions.length == _allPermissions.length) {
                            selectedPermissions.clear();
                          } else {
                            selectedPermissions.clear();
                            selectedPermissions.addAll(_allPermissions);
                          }
                        });
                      },
                      child: Text(
                        selectedPermissions.length == _allPermissions.length
                            ? "取消全选"
                            : "全选",
                        style: TextStyle(fontSize: 12, color: primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "选择该应用调用 OpenAPI 时所拥有的数据读写权限",
                  style: TextStyle(fontSize: 12, color: descColor),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _allPermissions.map((perm) {
                    final isSelected = selectedPermissions.contains(perm);
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedPermissions.remove(perm);
                          } else {
                            selectedPermissions.add(perm);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withOpacity(0.12)
                              : (isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.black.withOpacity(0.03)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : (isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.08)),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              size: 16,
                              color: isSelected ? primaryColor : descColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              perm,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? primaryColor : titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 保存大按钮
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
            child: Text(
              isEdit ? "保存更改" : "立即创建应用",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void commit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      "请输入应用名称".toast();
      return;
    }

    if (selectedPermissions.isEmpty) {
      "请至少选择一项权限".toast();
      return;
    }

    EasyLoading.show(status: "正在提交...");

    HttpResponse<NullResponse> response;

    Map<String, dynamic> data = {
      "name": name,
      "scopes": AppKeyViewModel.getScopeKeys(selectedPermissions),
    };
    if (widget.bean.containsKey("_id") || widget.bean.containsKey("id")) {
      if (widget.bean.containsKey("_id")) {
        data["_id"] = widget.bean["_id"];
      } else {
        data["id"] = widget.bean["id"];
      }
      response = await SingleAccountPageState.ofApi(context).updateAppKey(data);
    } else {
      response = await SingleAccountPageState.ofApi(context).addAppKey(data);
    }
    EasyLoading.dismiss();

    if (response.success) {
      "保存成功".toast();
      Navigator.of(context).pop(true);
    } else {
      response.message.toast();
    }
  }
}
