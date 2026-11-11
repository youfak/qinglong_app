import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:qinglong_app/base/base_viewmodel.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/icloud_utils.dart';

class AppKeyViewModel extends BaseViewModel {
  List<Map<String, dynamic>> list = [];

  @override
  void retry(BuildContext context, {bool showLoading = true}) {
    loadData(context, showLoading);
  }

  Future<void> loadData(BuildContext context, [isLoading = true]) async {
    if (isLoading && list.isEmpty) {
      loading(notify: true);
    }

    HttpResponse<String> result =
        await SingleAccountPageState.ofApi(context).appKeys();

    if (result.success && result.bean != null) {
      list.clear();

      List<dynamic>? tempList = jsonDecode(result.bean ?? "[]");

      if (tempList != null && tempList.isNotEmpty) {
        for (int i = 0; i < tempList.length; i++) {
          list.add(tempList[i] as Map<String, dynamic>);
        }
        success();
      } else {
        empty(notify: true);
      }
    } else {
      list.clear();
      if (result.code == 404) {
        failed(result.message, notify: true);
      } else {
        failed(result.message, notify: true);
      }
    }
  }

  Future<void> delAppKey(BuildContext context, dynamic id) async {
    HttpResponse<NullResponse> result =
        await SingleAccountPageState.ofApi(context).deleteAppKey([id]);
    if (result.success) {
      "删除成功".toast();
      loadData(context, false);
    } else {
      failToast(result.message, notify: true);
    }
  }

  Future<void> resetAppKey(BuildContext context, dynamic id) async {
    HttpResponse<NullResponse> result =
        await SingleAccountPageState.ofApi(context).resetAppKey(id);
    if (result.success) {
      "重置成功".toast();
      loadData(context, false);
    } else {
      failToast(result.message, notify: true);
    }
  }

  static const Map<String, String> scopeMap = {
    "crons": "定时任务",
    "envs": "环境变量",
    "subscriptions": "订阅管理",
    "configs": "配置文件",
    "scripts": "脚本管理",
    "logs": "任务日志",
    "dependencies": "依赖管理",
    "system": "系统信息",
    "apps": "应用授权",
    "dashboard": "总览看板",
    "login-log": "登录日志",
  };

  static List<String> getScopeNames(List<dynamic>? scopeKeys) {
    if (scopeKeys == null) return [];
    List<String> result = [];
    for (var key in scopeKeys) {
      final strKey = key.toString();
      result.add(scopeMap[strKey] ?? strKey);
    }
    return result;
  }

  static List<String> getScopeKeys(List<String> scopeNames) {
    final reverseMap = scopeMap.map((k, v) => MapEntry(v, k));
    List<String> result = [];
    for (var name in scopeNames) {
      result.add(reverseMap[name] ?? name);
    }
    return result;
  }
}
