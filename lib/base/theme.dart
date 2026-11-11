import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/utils/codeeditor_theme.dart';
import 'package:qinglong_app/utils/sp_utils.dart';

var themeProvider = ChangeNotifierProvider((ref) => ThemeViewModel());

Color whiteColor = const Color(0xfff8fafc);

int modeDark = 2;
int modeLight = 0;
int modeWhite = 1;

Color _primaryColor = const Color(0xFF10B981);
// Color _primaryColor = Colors.redAccent;

class ThemeViewModel extends ChangeNotifier {
  late ThemeData currentTheme;

  int _themeMode = modeLight;

  Color primaryColor = _primaryColor;

  ThemeColors themeColor = LightThemeColors();

  ThemeViewModel() {
    if (SpUtil.getBool(spThemeFollowSystem, defValue: false)) {
      changeThemeWithSystemStatus();
    } else {
      _themeMode = SpUtil.getInt(spThemeStyle, defValue: SpUtil.getInt(spVIP, defValue: typeNormal) != typeNormal ? modeWhite : modeLight);
    }

    changeThemeReal(_themeMode, false);
  }

  void changeThemeWithSystemStatus([bool must = true]) {
    if (SpUtil.getBool(spThemeFollowSystem, defValue: false) == false) return;
    var brightness = SchedulerBinding.instance.window.platformBrightness;
    int theme;
    if (brightness == Brightness.dark) {
      theme = modeDark;
    } else {
      theme = SpUtil.getInt(spVIP, defValue: typeNormal) != typeNormal ? modeWhite : modeLight;
    }
    if (!must && _themeMode == theme) return;
    changeThemeReal(theme);
  }

  void changeTheme(int themeMode) {
    if (_themeMode == themeMode) return;
    changeThemeReal(themeMode);
  }

  void changeThemeReal(int themeMode, [bool notify = true]) {
    _themeMode = themeMode;
    SpUtil.putInt(spThemeStyle, _themeMode);
    if (_themeMode == modeLight) {
      currentTheme = getLightTheme();
      themeColor = LightThemeColors();
    } else if (_themeMode == modeDark) {
      currentTheme = getDartTheme();
      themeColor = DartThemeColors();
    } else {
      currentTheme = getWhiteTheme();
      themeColor = WhiteThemeColors();
    }
    if (Platform.isAndroid) {
      SystemUiOverlayStyle style;
      if (_themeMode == modeDark) {
        style = const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.black);
      } else {
        style = const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.white);
      }
      SystemChrome.setSystemUIOverlayStyle(style);
    }
    if (notify) {
      notifyListeners();
    }
  }

  get themeMode => _themeMode;

  bool isDark() => _themeMode == modeDark;

  ThemeData getWhiteTheme() {
    return ThemeData.light().copyWith(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      splashColor: Colors.transparent,
      colorScheme: ColorScheme.light(
        secondary: _primaryColor,
        primary: _primaryColor,
        surface: Colors.white,
        background: const Color(0xffF8FAFC),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
      ),
      scaffoldBackgroundColor: const Color(0xffffffff),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xff94A3B8),
        ),
        labelStyle: TextStyle(
          color: _primaryColor,
          fontSize: 14,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffE2E8F0), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffE2E8F0), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffE2E8F0), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: whiteColor,
        titleTextStyle: const TextStyle(
          color: Color(0xff1E293B),
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        toolbarTextStyle: TextStyle(
          color: _primaryColor,
        ),
        iconTheme: IconThemeData(
          color: _primaryColor,
        ),
        actionsIconTheme: IconThemeData(
          color: _primaryColor,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: _primaryColor,
        backgroundColor: const Color(0xBBF9F9F9),
        elevation: 0,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: _primaryColor,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _primaryColor,
      ),
      tabBarTheme: TabBarTheme(
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
        ),
        labelColor: _primaryColor,
        unselectedLabelColor: const Color(0xff94A3B8),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      hintColor: const Color(0xff94A3B8),
      toggleableActiveColor: _primaryColor,
      checkboxTheme: CheckboxThemeData(
        checkColor: MaterialStateProperty.resolveWith(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.transparent;
            }
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return Colors.black;
          },
        ),
      ),
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: _primaryColor,
        scaffoldBackgroundColor: const Color(0xfff8fafc),
      ),
    );
  }

  ThemeData getLightTheme() {
    return ThemeData.light().copyWith(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      splashColor: Colors.transparent,
      colorScheme: ColorScheme.light(
        secondary: _primaryColor,
        primary: _primaryColor,
        surface: Colors.white,
        background: const Color(0xffF8FAFC),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
      ),
      scaffoldBackgroundColor: const Color(0xffffffff),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xff94A3B8),
        ),
        labelStyle: TextStyle(
          color: _primaryColor,
          fontSize: 14,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffE2E8F0), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffE2E8F0), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffE2E8F0), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        toolbarTextStyle: TextStyle(
          color: Colors.white,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        actionsIconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: _primaryColor,
        backgroundColor: const Color(0xBBF9F9F9),
        elevation: 0,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: _primaryColor,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _primaryColor,
      ),
      tabBarTheme: TabBarTheme(
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
        ),
        labelColor: _primaryColor,
        unselectedLabelColor: const Color(0xff94A3B8),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      hintColor: const Color(0xff94A3B8),
      toggleableActiveColor: _primaryColor,
      checkboxTheme: CheckboxThemeData(
        checkColor: MaterialStateProperty.resolveWith(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.transparent;
            }
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return Colors.black;
          },
        ),
      ),
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: _primaryColor,
        scaffoldBackgroundColor: const Color(0xfff8fafc),
      ),
    );
  }

  ThemeData getDartTheme() {
    return ThemeData.dark().copyWith(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashColor: Colors.transparent,
      dividerColor: const Color(0xff262626),
      canvasColor: const Color(0xff1E1E1E),
      dividerTheme: const DividerThemeData(
        color: Color(0xff262626),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: const Color(0xff1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xff1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF1E2638),
        foregroundColor: Color(0xFF10B981),
      ),
      brightness: Brightness.dark,
      primaryColor: const Color(0xffffffff),
      scaffoldBackgroundColor: const Color(0xff111111),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: const Color(0xff111111),
        titleTextStyle: const TextStyle(
          color: Color(0xffffffff),
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        toolbarTextStyle: TextStyle(
          color: _primaryColor,
        ),
        iconTheme: IconThemeData(
          color: _primaryColor,
        ),
        actionsIconTheme: IconThemeData(
          color: _primaryColor,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: _primaryColor,
        backgroundColor: const Color(0x991B1B1B),
        elevation: 0,
      ),
      hintColor: const Color(0xff71717A),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xff71717A),
        ),
        labelStyle: TextStyle(
          color: _primaryColor,
          fontSize: 14,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xff3F3F46), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xff3F3F46), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xff3F3F46), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      tabBarTheme: const TabBarTheme(
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
        ),
        labelColor: Color(0xffffffff),
        unselectedLabelColor: Color(0xff71717A),
      ),
      colorScheme: ColorScheme.dark(
        secondary: _primaryColor,
        primary: _primaryColor,
        surface: const Color(0xff1E1E1E),
        background: const Color(0xff111111),
      ),
      toggleableActiveColor: _primaryColor,
      checkboxTheme: CheckboxThemeData(
        checkColor: MaterialStateProperty.resolveWith(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.transparent;
            }
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return Colors.white;
          },
        ),
      ),
      cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xffffffff),
        scaffoldBackgroundColor: Colors.black,
      ),
    );
  }
}

abstract class ThemeColors {
  Color settingBgColor();

  Color bg2Color();

  Color blackAndWhite();

  Color codeBgColor();

  Color pinedAndWhite();

  Color settingBordorColor();

  Color titleColor();

  Color title2Color();

  Color hintColor();

  Color descColor();

  Color filterColor();

  Color tabBarColor();

  Color pinColor();

  Color searchBgColor();

  Color buttonBgColor();

  Color segmentedUnCheckBg();

  Color otherFuncBg();

  Map<String, TextStyle> codeEditorTheme();

  List<Color> appBarBg();
}

class LightThemeColors extends ThemeColors {
  @override
  Color titleColor() {
    return const Color(0xff0f172a);
  }

  @override
  Color pinColor() {
    return whiteColor;
  }

  @override
  Map<String, TextStyle> codeEditorTheme() {
    return qinglongLightTheme;
  }

  @override
  Color descColor() {
    return const Color(0xff64748b);
  }

  @override
  Color settingBgColor() {
    return Colors.white;
  }

  @override
  Color buttonBgColor() {
    return _primaryColor;
  }

  @override
  Color settingBordorColor() {
    return const Color(0xffe2e8f0);
  }

  @override
  Color tabBarColor() {
    return Colors.white;
  }

  @override
  List<Color> appBarBg() {
    return [
      const Color(0xff10b981),
      const Color(0xff059669),
    ];
  }

  @override
  Color blackAndWhite() {
    return Colors.white;
  }

  @override
  Color filterColor() {
    return const Color(0xff475569);
  }

  @override
  Color title2Color() {
    return const Color(0xff1e293b);
  }

  @override
  Color hintColor() {
    return const Color(0xff94a3b8);
  }

  @override
  Color bg2Color() {
    return whiteColor;
  }

  @override
  Color segmentedUnCheckBg() {
    return const Color(0xffF0F0F0);
  }

  @override
  Color pinedAndWhite() {
    return Colors.white;
  }

  @override
  Color searchBgColor() {
    return whiteColor;
  }

  @override
  Color otherFuncBg() {
    return Colors.white;
  }

  @override
  Color codeBgColor() {
    return const Color(0xffffffff);
  }
}

class WhiteThemeColors extends ThemeColors {
  @override
  Color titleColor() {
    return const Color(0xff0f172a);
  }

  @override
  Color codeBgColor() {
    return const Color(0xffffffff);
  }

  @override
  Color pinColor() {
    return whiteColor;
  }

  @override
  Color searchBgColor() {
    return whiteColor;
  }

  @override
  Color otherFuncBg() {
    return Colors.white;
  }

  @override
  Map<String, TextStyle> codeEditorTheme() {
    return qinglongLightTheme;
  }

  @override
  Color descColor() {
    return const Color(0xff64748b);
  }

  @override
  Color pinedAndWhite() {
    return Colors.white;
  }

  @override
  Color settingBgColor() {
    return Colors.white;
  }

  @override
  Color buttonBgColor() {
    return _primaryColor;
  }

  @override
  Color settingBordorColor() {
    return const Color(0xffe2e8f0);
  }

  @override
  Color tabBarColor() {
    return Colors.white;
  }

  @override
  List<Color> appBarBg() {
    return [
      const Color(0xff10b981),
      const Color(0xff059669),
    ];
  }

  @override
  Color blackAndWhite() {
    return Colors.white;
  }

  @override
  Color filterColor() {
    return const Color(0xff475569);
  }

  @override
  Color title2Color() {
    return const Color(0xff1e293b);
  }

  @override
  Color hintColor() {
    return const Color(0xff94a3b8);
  }

  @override
  Color bg2Color() {
    return whiteColor;
  }

  @override
  Color segmentedUnCheckBg() {
    return const Color(0xffF0F0F0);
  }
}

class DartThemeColors extends ThemeColors {
  @override
  Color hintColor() {
    return const Color(0xff64748b);
  }

  @override
  Color title2Color() {
    return const Color(0xfff1f5f9);
  }

  @override
  Color filterColor() {
    return const Color(0xfff8fafc);
  }

  @override
  Color pinedAndWhite() {
    return pinColor();
  }

  @override
  Color blackAndWhite() {
    return const Color(0xff18181f);
  }

  @override
  Color titleColor() {
    return const Color(0xfff8fafc);
  }

  @override
  Color pinColor() {
    return const Color(0xff22222a);
  }

  @override
  Map<String, TextStyle> codeEditorTheme() {
    return qinglongDarkTheme;
  }

  @override
  Color descColor() {
    return const Color(0xff94a3b8);
  }

  @override
  Color settingBgColor() {
    return const Color(0xff18181f);
  }

  @override
  Color buttonBgColor() {
    return const Color(0xff272733);
  }

  @override
  Color settingBordorColor() {
    return const Color(0xff272733);
  }

  @override
  Color tabBarColor() {
    return const Color(0xff18181f);
  }

  @override
  List<Color> appBarBg() {
    return [const Color(0xff18181f)];
  }

  @override
  Color searchBgColor() {
    return const Color(0xff18181f);
  }

  @override
  Color bg2Color() {
    return const Color(0xff121217);
  }

  @override
  Color otherFuncBg() {
    return Colors.transparent;
  }

  @override
  Color segmentedUnCheckBg() {
    return const Color(0xff272733);
  }

  @override
  Color codeBgColor() {
    return const Color(0xff0f1117);
  }
}
