import 'dart:async';

// Flutter 3.50 currently deprecates the Material library while its replacement
// is still evolving; retain the stable Material 3 API until migration is supported.
// ignore: deprecated_member_use
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

class CallSnapshot {
  const CallSnapshot({
    required this.hasCall,
    required this.number,
    required this.displayName,
    required this.direction,
    required this.state,
    required this.muted,
    required this.speaker,
    required this.canHold,
    required this.isHeld,
    required this.connectedDurationMillis,
  });

  final bool hasCall;
  final String number;
  final String displayName;
  final String direction;
  final String state;
  final bool muted;
  final bool speaker;
  final bool canHold;
  final bool isHeld;
  final int connectedDurationMillis;

  factory CallSnapshot.fromMap(Map<dynamic, dynamic> map) => CallSnapshot(
        hasCall: map['hasCall'] == true,
        number: map['number']?.toString() ?? '',
        displayName: map['displayName']?.toString() ?? '',
        direction: map['direction']?.toString() ?? 'unknown',
        state: map['state']?.toString() ?? 'unknown',
        muted: map['muted'] == true,
        speaker: map['speaker'] == true,
        canHold: map['canHold'] == true,
        isHeld: map['isHeld'] == true,
        connectedDurationMillis: (map['connectedDurationMillis'] as num?)?.toInt() ?? 0,
      );

  String get title => displayName.isNotEmpty ? displayName : (number.isNotEmpty ? number : 'Unknown caller');
  bool get isRinging => state == 'ringing';
  bool get isActive => state == 'active' || state == 'holding';
}

class TelecomBridge {
  static const _methods = MethodChannel('com.moogs.phone/telecom');
  static const _events = EventChannel('com.moogs.phone/call_events');

  static Stream<CallSnapshot> get callEvents => _events
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map((event) => CallSnapshot.fromMap(event as Map));

  static Future<CallSnapshot> currentCall() async {
    final result = await _methods.invokeMapMethod<dynamic, dynamic>('getCallSnapshot');
    return CallSnapshot.fromMap(result ?? const {'hasCall': false});
  }

  static Future<void> act(String action, [Map<String, Object?> args = const {}]) =>
      _methods.invokeMethod<void>(action, args);

  static Future<void> placeCall(String number) =>
      act('placeCall', {'number': number});

  static Future<void> requestDefaultDialer() => act('requestDefaultDialer');
}

class DialerHomePage extends StatefulWidget {
  const DialerHomePage({super.key});

  @override
  State<DialerHomePage> createState() => _DialerHomePageState();
}

class _DialerHomePageState extends State<DialerHomePage> {
  static const _digits = <String>[
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#'
  ];
  String _number = '';
  bool _requestingRole = false;
  CallSnapshot? _call;
  StreamSubscription<CallSnapshot>? _callSubscription;

  @override
  void initState() {
    super.initState();
    _callSubscription = TelecomBridge.callEvents.listen(
      (snapshot) {
        if (mounted) setState(() => _call = snapshot.hasCall ? snapshot : null);
      },
      onError: (_) {},
    );
    _loadCall();
  }

  Future<void> _loadCall() async {
    try {
      final snapshot = await TelecomBridge.currentCall();
      if (mounted) setState(() => _call = snapshot.hasCall ? snapshot : null);
    } on PlatformException {
      // The app can still be used for keypad entry before it becomes the dialer.
    }
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestDefaultDialer() async {
    setState(() => _requestingRole = true);
    try {
      await TelecomBridge.requestDefaultDialer();
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
      await TelecomBridge.placeCall(_number);
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
    final call = _call;
    if (call != null) {
      return CallScreen(
        key: const ValueKey('call-screen'),
        call: call,
      );
    }

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
                    child: const Icon(Icons.call_rounded, color: MoogsTheme.ice),
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

class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.call});
  final CallSnapshot call;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? _clock;
  int _elapsedSeconds = 0;
  bool _showKeypad = false;

  @override
  void initState() {
    super.initState();
    _syncElapsed();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.call.isActive) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CallScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.call.connectedDurationMillis != widget.call.connectedDurationMillis ||
        oldWidget.call.state != widget.call.state) {
      _syncElapsed();
    }
  }

  // Android's connectTimeMillis is based on elapsedRealtime(), not wall-clock
  // time. The native layer supplies a duration to avoid mixing clock domains.
  void _syncElapsed() {
    final duration = widget.call.connectedDurationMillis;
    if (mounted) setState(() => _elapsedSeconds = duration > 0 ? duration ~/ 1000 : 0);
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  String get _time {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _action(String name, [Map<String, Object?> args = const {}]) async {
    try {
      await TelecomBridge.act(name, args);
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Call action failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final incoming = call.isRinging && call.direction == 'incoming';
    final connected = call.isActive;
    final subtitle = connected
        ? _time
        : switch (call.state) {
            'ringing' => incoming ? 'Incoming call' : 'Ringing…',
            'dialing' => 'Calling…',
            'connecting' => 'Connecting…',
            'holding' => 'On hold',
            'disconnecting' => 'Ending call…',
            _ => 'Call in progress',
          };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MoogsTheme.ice.withValues(alpha: .14),
                  border: Border.all(color: MoogsTheme.ice.withValues(alpha: .45), width: 1.2),
                ),
                child: const Icon(Icons.person_rounded, size: 64, color: MoogsTheme.ice),
              ),
              const SizedBox(height: 28),
              Text(call.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.6,
                      )),
              const SizedBox(height: 10),
              Text(subtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .62),
                        letterSpacing: .4,
                      )),
              const Spacer(flex: 2),
              if (incoming) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RoundCallButton(
                      icon: Icons.call_end_rounded,
                      label: 'Decline',
                      color: MoogsTheme.missed,
                      onTap: () => _action('reject'),
                    ),
                    _RoundCallButton(
                      icon: Icons.call_rounded,
                      label: 'Answer',
                      color: MoogsTheme.call,
                      onTap: () => _action('answer'),
                    ),
                  ],
                ),
              ] else ...[
                if (_showKeypad && connected)
                  SizedBox(
                    width: 240,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      childAspectRatio: 1.3,
                      children: ['1','2','3','4','5','6','7','8','9','*','0','#']
                          .map((digit) => TextButton(
                                onPressed: () => _action('dtmf', {'digit': digit}),
                                child: Text(digit, style: Theme.of(context).textTheme.titleLarge),
                              ))
                          .toList(),
                    ),
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 18,
                    runSpacing: 18,
                    children: [
                      _CallControl(
                        icon: call.muted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
                        label: call.muted ? 'Muted' : 'Mute',
                        selected: call.muted,
                        onTap: () => _action('mute', {'enabled': !call.muted}),
                      ),
                      _CallControl(
                        icon: Icons.dialpad_rounded,
                        label: 'Keypad',
                        onTap: () => setState(() => _showKeypad = true),
                      ),
                      _CallControl(
                        icon: call.speaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        label: 'Speaker',
                        selected: call.speaker,
                        onTap: () => _action('speaker', {'enabled': !call.speaker}),
                      ),
                      if (call.canHold)
                        _CallControl(
                          icon: call.isHeld ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          label: call.isHeld ? 'Resume' : 'Hold',
                          selected: call.isHeld,
                          onTap: () => _action('hold', {'enabled': !call.isHeld}),
                        ),
                    ],
                  ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_showKeypad)
                      IconButton(
                        tooltip: 'Hide keypad',
                        onPressed: () => setState(() => _showKeypad = false),
                        icon: const Icon(Icons.keyboard_hide_rounded),
                      ),
                    _RoundCallButton(
                      icon: Icons.call_end_rounded,
                      label: 'End call',
                      color: MoogsTheme.missed,
                      onTap: () => _action('disconnect'),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              Text("MOOG'S PHONE",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 2.2,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4),
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 88,
        child: Column(
          children: [
            Material(
              color: selected
                  ? MoogsTheme.ice.withValues(alpha: .25)
                  : Theme.of(context).colorScheme.surface.withValues(alpha: .8),
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: onTap,
                icon: Icon(icon),
                iconSize: 25,
                padding: const EdgeInsets.all(18),
              ),
            ),
            const SizedBox(height: 7),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      );
}

class _RoundCallButton extends StatelessWidget {
  const _RoundCallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Material(
            color: color,
            shape: const CircleBorder(),
            elevation: 5,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.mediumImpact();
                onTap();
              },
              child: SizedBox(
                width: 68,
                height: 68,
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      );
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.digit, required this.onTap});
  final String digit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.white.withValues(alpha: dark ? .07 : .72),
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
