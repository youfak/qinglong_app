import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';



class RunningWidget extends ConsumerWidget {
  const RunningWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final Color primary = ref.watch(themeProvider).primaryColor;
    return Container(
      decoration: BoxDecoration(
        color: primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: primary.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingWidget(
            color: primary,
            size: 11,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            "运行中",
            style: TextStyle(
              color: primary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
