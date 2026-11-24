import 'package:flutter/material.dart';

import 'core/theme/theme.dart';
import 'features/shell/home_shell.dart';

class MoogsPhoneApp extends StatelessWidget {
  const MoogsPhoneApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: "Moog's Phone",
        debugShowCheckedModeBanner: false,
        theme: MoogsTheme.light,
        darkTheme: MoogsTheme.dark,
        themeMode: ThemeMode.system,
        home: const DialerHomePage(),
      );
}
