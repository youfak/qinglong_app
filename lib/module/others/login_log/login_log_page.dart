import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/utils.dart';

import 'login_log_bean.dart';

class LoginLogPage extends ConsumerStatefulWidget {
  const LoginLogPage({Key? key}) : super(key: key);

  @override
  _LoginLogPageState createState() => _LoginLogPageState();
}

class _LoginLogPageState extends ConsumerState<LoginLogPage> with LazyLoadState<LoginLogPage> {
  List<LoginLogBean> list = [];
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final isDark = theme.isDark();
    final primaryColor = theme.primaryColor;
    final titleColor = theme.themeColor.titleColor();
    final descColor = theme.themeColor.descColor();
    final cardBg = isDark ? const Color(0xFF1E2638) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final successCount = list.where((item) => item.status == 0).length;
    final failedCount = list.where((item) => item.status != 0).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: QlAppBar(
        canBack: true,
        title: "登录日志",
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: "刷新",
            onPressed: () {
              loadData();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: LoadingWidget())
          : RefreshIndicator(
              color: primaryColor,
              onRefresh: loadData,
              child: list.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.shield_outlined, size: 48, color: primaryColor),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "暂无登录日志",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "未检测到历史登录记录",
                                style: TextStyle(fontSize: 13, color: descColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      slivers: [
                        // 顶部统计概览栏
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: Row(
                              children: [
                                _buildStatChip(
                                  icon: Icons.history_rounded,
                                  label: "共 ${list.length} 条记录",
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  bgColor: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
                                  borderColor: borderColor,
                                ),
                                const SizedBox(width: 8),
                                _buildStatChip(
                                  icon: Icons.check_circle_rounded,
                                  label: "$successCount 成功",
                                  color: const Color(0xFF10B981),
                                  bgColor: const Color(0xFF10B981).withOpacity(0.12),
                                  borderColor: const Color(0xFF10B981).withOpacity(0.2),
                                ),
                                const SizedBox(width: 8),
                                if (failedCount > 0)
                                  _buildStatChip(
                                    icon: Icons.warning_rounded,
                                    label: "$failedCount 异常/失败",
                                    color: const Color(0xFFEF4444),
                                    bgColor: const Color(0xFFEF4444).withOpacity(0.12),
                                    borderColor: const Color(0xFFEF4444).withOpacity(0.2),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // 登录日志列表
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = list[index];
                                final isSuccess = item.status == 0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSuccess ? borderColor : const Color(0xFFEF4444).withOpacity(0.3),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 第一行：状态图标、IP、复制、状态药丸
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: BoxDecoration(
                                                color: (isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                                    .withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                isSuccess ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                                                size: 18,
                                                color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  SelectableText(
                                                    item.ip ?? "未知IP",
                                                    style: TextStyle(
                                                      fontFamily: 'monospace',
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: titleColor,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (item.ip != null) {
                                                        Clipboard.setData(ClipboardData(text: item.ip!));
                                                        "已复制 IP: ${item.ip}".toast();
                                                      }
                                                    },
                                                    child: Icon(Icons.copy_rounded, size: 14, color: descColor.withOpacity(0.7)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: (isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                                    .withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isSuccess ? "登录成功" : "登录失败",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Divider(height: 1, color: borderColor.withOpacity(0.6)),
                                        const SizedBox(height: 10),
                                        // 第二行：属地位置与平台信息
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 15, color: descColor),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                (item.address != null && item.address!.isNotEmpty)
                                                    ? item.address!
                                                    : "未知属地",
                                                style: TextStyle(fontSize: 13, color: descColor),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // 时间标签
                                            Icon(Icons.access_time_rounded, size: 14, color: descColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              Utils.formatMessageTime(item.timestamp ?? 0),
                                              style: TextStyle(fontSize: 12, color: descColor),
                                            ),
                                          ],
                                        ),
                                        // 第三行：客户端平台/设备信息（若有）
                                        if (item.platform != null && item.platform!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF141E30) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.devices_rounded, size: 13, color: descColor),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    item.platform!,
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontFamily: 'monospace',
                                                      color: descColor,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: list.length,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
            ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      HttpResponse<List<LoginLogBean>> response =
          await SingleAccountPageState.ofApi(context).loginLog();

      if (response.success) {
        list.clear();
        list.addAll(response.bean ?? []);
      } else {
        response.message?.toast();
      }
    } catch (e) {
      e.toString().toast();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void onLazyLoad() {
    loadData();
  }
}
