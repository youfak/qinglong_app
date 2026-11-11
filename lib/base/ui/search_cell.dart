import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';

class SearchCell extends ConsumerStatefulWidget {
  final TextEditingController controller;

  const SearchCell({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  ConsumerState createState() => _SearchCellState();
}

class _SearchCellState extends ConsumerState<SearchCell> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider).themeMode == modeDark;
    final descColor = ref.watch(themeProvider).themeColor.descColor();
    final titleColor = ref.watch(themeProvider).themeColor.title2Color();

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff22222b) : const Color(0xfff1f4f8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xff2d2d38) : const Color(0xffe2e8f0),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 18,
            color: descColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14.5,
                color: titleColor,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                hintText: "搜索任务名称、命令、规则...",
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  color: descColor.withOpacity(0.8),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onEditingComplete: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                widget.controller.clear();
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  CupertinoIcons.clear_circled_solid,
                  size: 18,
                  color: descColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
