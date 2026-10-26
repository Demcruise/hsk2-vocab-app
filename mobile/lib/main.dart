import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/app_state.dart';
import 'data/content.dart';
import 'data/services.dart';
import 'ui/duo.dart';
import 'ui/home_shell.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final content = ContentRepository();
  await content.load();
  ContentRepositoryHolder.instance = content;

  final prefs = await SharedPreferences.getInstance();
  final state = AppState();
  await state.load(prefs);
  content.setLevel(state.level);

  final tts = TtsService();
  await tts.init();
  TtsServiceHolder.instance = tts;
  AppStateHolder.instance = state;

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(Hsk2App(state: state, content: content, tts: tts, sfx: SfxService(), backup: BackupService()));
}

class Hsk2App extends StatelessWidget {
  final AppState state;
  final ContentRepository content;
  final TtsService tts;
  final SfxService sfx;
  final BackupService backup;

  const Hsk2App({super.key, required this.state, required this.content, required this.tts, required this.sfx, required this.backup});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final dark = state.theme == 'dark' ||
            (state.theme == 'system' && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        return MaterialApp(
          title: 'Kunkwan HSK',
          debugShowCheckedModeBanner: false,
          theme: _theme(false),
          darkTheme: _theme(true),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: HomeShell(state: state, content: content, tts: tts, sfx: sfx, backup: backup),
        );
      },
    );
  }

  ThemeData _theme(bool dark) {
    final base = dark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: dark ? Duo.dBg : Duo.bg,
      cardColor: dark ? Duo.dCard : Colors.white,
      dividerColor: dark ? Duo.dBorder : Duo.border,
      colorScheme: (dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: Duo.green,
        surface: dark ? Duo.dCard : Colors.white,
        onSurface: dark ? Duo.dText : Duo.text,
      ),
      textTheme: base.textTheme.apply(fontFamily: 'Nunito', bodyColor: dark ? Duo.dText : Duo.text, displayColor: dark ? Duo.dText : Duo.text),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
