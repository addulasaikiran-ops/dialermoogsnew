import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoogsPhoneApp());
}

class MoogsPhoneApp extends StatelessWidget {
  const MoogsPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Moog's Phone",
      debugShowCheckedModeBanner: false,
      theme: MoogsTheme.light,
      darkTheme: MoogsTheme.dark,
      themeMode: ThemeMode.system,
      home: const DialerHomePage(),
    );
  }
}

class MoogsTheme {
  static const pearl = Color(0xFFF4F1EC);
  static const midnight = Color(0xFF0A0D14);
  static const ice = Color(0xFF8CCBFA);
  static const call = Color(0xFF2FD07A);
  static const missed = Color(0xFFFF3B4E);

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: pearl,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ice,
          brightness: Brightness.light,
          surface: const Color(0xFFFAF9F6),
        ),
        useMaterial3: true,
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: midnight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ice,
          brightness: Brightness.dark,
          surface: const Color(0xFF151A26),
        ),
        useMaterial3: true,
      );
}

class DialerHomePage extends StatefulWidget {
  const DialerHomePage({super.key});

  @override
  State<DialerHomePage> createState() => _DialerHomePageState();
}

class _DialerHomePageState extends State<DialerHomePage> {
  static const _native = MethodChannel('com.moogs.phone/telecom');
  static const _digits = <String>[
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#'
  ];
  String _number = '';
  bool _requestingRole = false;

  Future<void> _requestDefaultDialer() async {
    setState(() => _requestingRole = true);
    try {
      await _native.invokeMethod<bool>('requestDefaultDialer');
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Could not open dialer settings')),
        );
      }
    } finally {
      if (mounted) setState(() => _requestingRole = false);
    }
  }

  Future<void> _placeCall() async {
    if (_number.trim().isEmpty) return;
    try {
      await _native.invokeMethod<void>('placeCall', {'number': _number});
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to start call')),
        );
      }
    }
  }

  void _append(String value) => setState(() => _number += value);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.white : const Color(0xFF20232B);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MoogsTheme.ice.withValues(alpha: .16),
                      border: Border.all(color: MoogsTheme.ice.withValues(alpha: .5)),
                    ),
                    child: Icon(Icons.call_rounded, color: MoogsTheme.ice),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text("Moog's Phone",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.5,
                            )),
                  ),
                  IconButton(
                    tooltip: 'Set as default dialer',
                    onPressed: _requestingRole ? null : _requestDefaultDialer,
                    icon: _requestingRole
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.settings_phone_rounded),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _number.isEmpty ? 'Enter a number' : _number,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 300,
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 18,
                  childAspectRatio: 1.18,
                  children: _digits.map((digit) => _KeypadButton(
                    digit: digit,
                    onTap: () => _append(digit),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 64),
                  InkWell(
                    onTap: _placeCall,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MoogsTheme.call,
                        boxShadow: [
                          BoxShadow(
                            color: MoogsTheme.call.withValues(alpha: .28),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: const Icon(Icons.call_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: IconButton(
                      tooltip: 'Delete last digit',
                      onPressed: _number.isEmpty
                          ? null
                          : () => setState(() => _number = _number.substring(0, _number.length - 1)),
                      icon: const Icon(Icons.backspace_outlined),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text('FAVORITES     RECENTS     CONTACTS     KEYPAD',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.1,
                        color: foreground.withValues(alpha: .55),
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.digit, required this.onTap});
  final String digit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: (dark ? Colors.white : Colors.white).withValues(alpha: dark ? .07 : .72),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Center(
          child: Text(digit,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: dark ? Colors.white : const Color(0xFF252832),
                  )),
        ),
      ),
    );
  }
}
