import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/tokens.dart';
import 'core/widgets/moog_logo.dart';
import 'features/dialer/keypad_key.dart';
import 'features/dialer/number_display.dart';
import 'core/widgets/glass_surface.dart';
import 'core/widgets/aurora_backdrop.dart';
import 'features/shell/home_shell.dart';
import 'app.dart';

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
      home: CallGate<CallSnapshot>(
        events: TelecomBridge.callEvents,
        loadCurrent: TelecomBridge.currentCall,
        hasCall: (call) => call.hasCall,
        callBuilder: (call) => CallScreen(key: const ValueKey('call-screen'), call: call),
        child: const DialerHomePage(),
      ),
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
        extensions: const [
          MoogTokens(
            bgTop: Color(0xFFF4F1EC), bgBottom: Color(0xFFE9E6F0),
            orbs: [Color(0xFF8CCBFA), Color(0xFFB9A7E8), Color(0xFFF0BFA8)],
            glassFillHi: Color(0xB3FFFFFF), glassFillLo: Color(0x73FFFFFF),
            borderHi: Color(0xE6FFFFFF), borderLo: Color(0x33FFFFFF),
            shadow: Color(0x1F000000), text: Color(0xFF1B1D22),
            textMuted: Color(0x991B1D22), accentA: Color(0xFF8CCBFA),
            accentB: Color(0xFF2FD07A),
          ),
        ],
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
        extensions: const [
          MoogTokens(
            bgTop: Color(0xFF0A0D14), bgBottom: Color(0xFF151A26),
            orbs: [Color(0xFF8CCBFA), Color(0xFFB9A7E8), Color(0xFFB85C68)],
            glassFillHi: Color(0x24FFFFFF), glassFillLo: Color(0x0FFFFFFF),
            borderHi: Color(0x59FFFFFF), borderLo: Color(0x1AFFFFFF),
            shadow: Color(0x66000000), text: Color(0xFFEEF1F7),
            textMuted: Color(0x99EEF1F7), accentA: Color(0xFF8CCBFA),
            accentB: Color(0xFF2FD07A),
          ),
        ],
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

  static Future<void> placeCall(String number, int simSlot) =>
      act('placeCall', {'number': number, 'simSlot': simSlot});

  static Future<void> requestDefaultDialer() => act('requestDefaultDialer');
}


class PhoneDataBridge {
  static const _channel = MethodChannel('com.moogs.phone/phone_data');

  static Future<bool> requestPermission(String kind) async =>
      await _channel.invokeMethod<bool>('requestPermission', {'kind': kind}) ?? false;

  static Future<List<PhoneEntry>> contacts() async =>
      _entries(await _channel.invokeListMethod<dynamic>('getContacts'));

  static Future<List<PhoneEntry>> recents() async =>
      _entries(await _channel.invokeListMethod<dynamic>('getRecents'));

  static Future<List<PhoneEntry>> favorites() async =>
      _entries(await _channel.invokeListMethod<dynamic>('getFavorites'));

  static Future<void> setFavorite(PhoneEntry entry, bool favorite) =>
      _channel.invokeMethod<void>('setFavorite', {'number': entry.number, 'name': entry.displayName, 'favorite': favorite});

  static List<PhoneEntry> _entries(List<dynamic>? values) => (values ?? const [])
      .whereType<Map>()
      .map((value) => PhoneEntry.fromMap(value))
      .toList(growable: false);
}

class PhoneEntry {
  const PhoneEntry({required this.name, required this.number, this.dateMillis = 0, this.callType = 0});
  final String name;
  final String number;
  final int dateMillis;
  final int callType;

  factory PhoneEntry.fromMap(Map<dynamic, dynamic> map) => PhoneEntry(
    name: map['name']?.toString() ?? '',
    number: map['number']?.toString() ?? '',
    dateMillis: (map['dateMillis'] as num?)?.toInt() ?? 0,
    callType: (map['callType'] as num?)?.toInt() ?? 0,
  );

  String get displayName => name.isNotEmpty ? name : (number.isNotEmpty ? number : 'Unknown');
}

class DialerHomePage extends StatefulWidget {
  const DialerHomePage({super.key});

  @override
  State<DialerHomePage> createState() => _DialerHomePageState();
}

class _DialerHomePageState extends State<DialerHomePage> {
  int _selectedTab = 3;
  int _selectedSim = 0;
  String _number = '';
  String _search = '';
  bool _requestingRole = false;
  bool _loading = false;
  String? _loadError;
  List<PhoneEntry> _contacts = const [];
  List<PhoneEntry> _recents = const [];
  List<PhoneEntry> _favorites = const [];

  Future<void> _loadTab(int tab, {bool askPermission = true}) async {
    setState(() { _selectedTab = tab; _loading = true; _loadError = null; });
    try {
      if (tab == 0 || tab == 2) {
        if (askPermission && !await PhoneDataBridge.requestPermission('contacts')) {
          throw PlatformException(code: 'CONTACTS_PERMISSION', message: 'Allow Contacts access to show your phonebook.');
        }
        final contacts = await PhoneDataBridge.contacts();
        final favorites = await PhoneDataBridge.favorites();
        if (mounted) setState(() { _contacts = contacts; _favorites = favorites; });
      } else if (tab == 1) {
        if (askPermission && !await PhoneDataBridge.requestPermission('callLog')) {
          throw PlatformException(code: 'CALL_LOG_PERMISSION', message: 'Allow call history access to show recent calls.');
        }
        final recent = await PhoneDataBridge.recents();
        moogMissedCount.value = recent.where((entry) => entry.callType == 3).length;
        if (mounted) setState(() => _recents = recent);
      }
    } on PlatformException catch (error) {
      if (mounted) setState(() => _loadError = error.message ?? 'Permission is required to show this information.');
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Could not load this screen. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestDefaultDialer() async {
    setState(() => _requestingRole = true);
    try { await TelecomBridge.requestDefaultDialer(); }
    on PlatformException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Could not open dialer settings')));
    } finally { if (mounted) setState(() => _requestingRole = false); }
  }

  Future<void> _placeCall() async {
    if (_number.trim().isEmpty) return;
    try { await TelecomBridge.placeCall(_number, _selectedSim); }
    on PlatformException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Unable to start call')));
    }
  }

  void _append(String value) => setState(() => _number += value);

  Future<void> _toggleFavorite(PhoneEntry entry) async {
    final exists = _favorites.any((item) => item.number == entry.number);
    try {
      await PhoneDataBridge.setFavorite(entry, !exists);
      final values = await PhoneDataBridge.favorites();
      if (mounted) setState(() => _favorites = values);
    } on PlatformException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Could not update favorite')));
    }
  }

  void _dialEntry(PhoneEntry entry) {
    setState(() { _number = entry.number; _selectedTab = 3; });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.white : const Color(0xFF20232B);
    return HomeShell(
      selectedIndex: _selectedTab,
      onSelected: _loadTab,
      missedCount: moogMissedCount.value,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
        child: Row(children: [
          const MoogLogo(size: 40),
          const SizedBox(width: 12),
          Expanded(child: Text("Moog's Phone", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -.5))),
          IconButton(
            tooltip: 'Set as default dialer',
            onPressed: _requestingRole ? null : _requestDefaultDialer,
            icon: _requestingRole ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.settings_phone_rounded),
          ),
        ]),
      ),
      pages: [
        Padding(padding: const EdgeInsets.only(bottom: 96), child: _buildListScreen('Favorites', _favorites, Icons.star_rounded, empty: 'Your favorite contacts will appear here.')),
        Padding(padding: const EdgeInsets.only(bottom: 96), child: _buildListScreen('Recents', _recents, Icons.call_made_rounded, showCallType: true, empty: 'Your recent calls will appear here.')),
        Padding(padding: const EdgeInsets.only(bottom: 96), child: _buildContactsScreen()),
        Padding(padding: const EdgeInsets.only(bottom: 96), child: _buildKeypad(foreground)),
      ],
    );
  }

  static const _keyLabels = <String, String>{
    '1': '', '2': 'ABC', '3': 'DEF',
    '4': 'GHI', '5': 'JKL', '6': 'MNO',
    '7': 'PQRS', '8': 'TUV', '9': 'WXYZ',
    '*': '', '0': '+', '#': '',
  };

  void _longPressKey(String digit) {
    if (digit == '0') {
      _append('+');
    } else if (digit == 'backspace') {
      setState(() => _number = '');
    }
  }

  Widget _buildKeypad(Color foreground) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 14.0;
      final widthKeySize = math.min((constraints.maxWidth - 2 * gap) / 3, 84.0);
      final heightKeySize = (constraints.maxHeight - 280) / 4;
      final keySize = math.max(36.0, math.min(widthKeySize, heightKeySize));
      final rows = [
        ['1', '2', '3'], ['4', '5', '6'],
        ['7', '8', '9'], ['*', '0', '#'],
      ];
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
        child: Column(
          children: [
            const SizedBox(height: 4),
            NumberDisplay(number: _number),
            const SizedBox(height: 10),
            SizedBox(
              height: 24,
              child: Center(
                child: Text(
                  'Suggestions will appear here',
                  style: TextStyle(fontSize: 11, color: context.moog.textMuted, letterSpacing: .2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final row in rows) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((digit) => KeypadKey(
                  digit: digit,
                  label: _keyLabels[digit] ?? '',
                  size: keySize,
                  onTap: () => _append(digit),
                  onLongPress: digit == '0' ? () => _longPressKey('0') : null,
                )).toList(),
              ),
              const SizedBox(height: 8),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _simChip(0),
                const SizedBox(width: 10),
                _simChip(1),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 76),
                GestureDetector(
                  onTap: _placeCall,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF58E69A), Color(0xFF20B967), Color(0xFF159653)],
                      ),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF2FD07A).withValues(alpha: .35), blurRadius: 36, spreadRadius: 1, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Icon(Icons.call_rounded, color: Colors.white, size: 32),
                  ),
                ),
                SizedBox(
                  width: 76,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _number.isEmpty ? null : () => setState(() => _number = _number.substring(0, _number.length - 1)),
                    onLongPress: _number.isEmpty ? null : () => _longPressKey('backspace'),
                    child: const SizedBox(
                      height: 48,
                      child: Center(child: Icon(Icons.backspace_outlined)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      );
    },
  );

  Widget _simChip(int slot) {
    final selected = _selectedSim == slot;
    final t = context.moog;
    return GestureDetector(
      onTap: () => setState(() => _selectedSim = slot),
      child: GlassSurface(
        radius: 999,
        tint: selected ? t.accentA.withValues(alpha: .28) : null,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Text(
          'SIM ${slot + 1}',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: .8,
            fontWeight: FontWeight.w600,
            color: selected ? t.text : t.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildContactsScreen() {
    final filtered = _contacts.where((entry) =>
      entry.displayName.toLowerCase().contains(_search.toLowerCase()) || entry.number.contains(_search)).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 10), child: TextField(
        onChanged: (value) => setState(() => _search = value),
        decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: 'Search contacts',
          filled: true, fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: .8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
      )),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) :
        _loadError != null ? _errorPanel(_loadError!, 2) :
        filtered.isEmpty ? _emptyPanel('No contacts found', 'Allow contacts access or add contacts to your phone.') :
        ListView.builder(itemCount: filtered.length, itemBuilder: (context, index) => _entryTile(filtered[index], favoriteButton: true))),
    ]);
  }

  Widget _buildListScreen(String title, List<PhoneEntry> entries, IconData icon, {bool showCallType = false, required String empty}) =>
    Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 12), child: Align(alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 34, fontWeight: FontWeight.w200, letterSpacing: -.8)))),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) :
        _loadError != null ? _errorPanel(_loadError!, _selectedTab) :
        entries.isEmpty ? _emptyPanel('Nothing here yet', empty) :
        ListView.builder(itemCount: entries.length, itemBuilder: (context, index) => _entryTile(entries[index], leading: showCallType ? _callTypeIcon(entries[index].callType) : icon, favoriteButton: !showCallType))),
    ]);

  Widget _entryTile(PhoneEntry entry, {IconData? leading, bool favoriteButton = false}) {
    final isFavorite = _favorites.any((item) => item.number == entry.number);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: CircleAvatar(backgroundColor: MoogsTheme.ice.withValues(alpha: .18),
        child: Icon(leading ?? Icons.person_rounded, color: MoogsTheme.ice)),
      title: Text(entry.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(entry.number, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (favoriteButton) IconButton(icon: Icon(isFavorite ? Icons.star_rounded : Icons.star_border_rounded, color: isFavorite ? Colors.amber : null),
          onPressed: () => _toggleFavorite(entry)),
        IconButton(icon: const Icon(Icons.call_rounded, color: MoogsTheme.call), onPressed: () => _dialEntry(entry)),
      ]),
      onTap: () => _dialEntry(entry),
    );
  }

  IconData _callTypeIcon(int type) => switch (type) {
    3 => Icons.call_missed_rounded,
    2 => Icons.call_made_rounded,
    1 => Icons.call_received_rounded,
    _ => Icons.call_rounded,
  };

  Widget _emptyPanel(String title, String message) => Center(child: Padding(
    padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.inbox_rounded, size: 42, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .35)),
      const SizedBox(height: 12), Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 6), Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
    ]),
  ));

  Widget _errorPanel(String message, int tab) => Center(child: Padding(
    padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.lock_outline_rounded, size: 38, color: MoogsTheme.ice),
      const SizedBox(height: 12), Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 14), OutlinedButton(onPressed: () => _loadTab(tab), child: const Text('Try again')),
    ]),
  ));
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
  String _enteredDigits = '';

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  @override
  void didUpdateWidget(covariant CallScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateElapsed();
  }

  void _updateElapsed() {
    final duration = widget.call.connectedDurationMillis;
    if (mounted) setState(() => _elapsedSeconds = duration.clamp(0, 1 << 30) ~/ 1000);
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

  String get _initials {
    final parts = widget.call.title.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
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

  void _sendDigit(String digit) {
    setState(() => _enteredDigits += digit);
    _action('dtmf', {'digit': digit});
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final incoming = call.isRinging && call.direction == 'incoming';
    final connected = call.isActive;
    final t = context.moog;
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

    final controls = GlassSurface(
      blur: true,
      radius: 30,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 6,
        childAspectRatio: 1.05,
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
          _CallControl(
            icon: call.isHeld ? Icons.play_arrow_rounded : Icons.pause_rounded,
            label: call.isHeld ? 'Resume' : 'Hold',
            selected: call.isHeld,
            enabled: call.canHold,
            onTap: () => _action('hold', {'enabled': !call.isHeld}),
          ),
          const _CallControl(icon: Icons.bluetooth_rounded, label: 'Bluetooth', enabled: false),
          const _CallControl(icon: Icons.person_outline_rounded, label: 'Contacts', enabled: false),
        ],
      ),
    );

    final keypad = GlassSurface(
      blur: true,
      radius: 30,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 28,
            child: Center(
              child: Text(
                _enteredDigits.isEmpty ? 'Enter keypad digits' : _enteredDigits,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, letterSpacing: 2, color: t.text),
              ),
            ),
          ),
          const SizedBox(height: 6),
          for (final row in const [
            ['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['*', '0', '#'],
          ]) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((digit) => KeypadKey(
                digit: digit,
                label: '',
                size: 54,
                onTap: () => _sendDigit(digit),
              )).toList(),
            ),
            const SizedBox(height: 6),
          ],
          TextButton.icon(
            onPressed: () => setState(() => _showKeypad = false),
            icon: const Icon(Icons.keyboard_hide_rounded, size: 18),
            label: const Text('Hide keypad'),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuroraBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [t.borderHi, t.accentA.withValues(alpha: .24), t.borderLo],
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.glassFillHi,
                        border: Border.all(color: t.borderHi.withValues(alpha: .5), width: .5),
                      ),
                      child: Center(
                        child: Text(_initials, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w300, letterSpacing: 1, color: t.text)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    call.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 34, height: 1.12, fontWeight: FontWeight.w300, letterSpacing: -.8, color: t.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: t.textMuted,
                      letterSpacing: .35,
                      fontFeatures: connected ? const [FontFeature.tabularFigures()] : null,
                    ),
                  ),
                  const Spacer(flex: 1),
                  if (incoming) ...[
                    SlideToAnswer(
                      onAnswer: () => _action('answer'),
                    ),
                    const SizedBox(height: 22),
                    _RoundCallButton(
                      icon: Icons.call_end_rounded,
                      label: 'Decline',
                      color: MoogsTheme.missed,
                      onTap: () => _action('reject'),
                    ),
                  ] else ...[
                    AnimatedCrossFade(
                      firstChild: controls,
                      secondChild: keypad,
                      crossFadeState: _showKeypad && connected ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 260),
                      sizeCurve: Curves.easeInOut,
                    ),
                    const SizedBox(height: 18),
                    GlassSurface(
                      radius: 999,
                      blur: true,
                      tint: MoogsTheme.missed.withValues(alpha: .88),
                      shadow: true,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _action('disconnect');
                        },
                        child: const SizedBox(
                          width: 72,
                          height: 72,
                          child: Icon(Icons.call_end_rounded, color: Colors.white, size: 29),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text("MOOG'S PHONE", style: TextStyle(fontSize: 10, letterSpacing: 2.2, color: t.textMuted.withValues(alpha: .65))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.icon,
    required this.label,
    this.onTap,
    this.selected = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.moog;
    return Opacity(
      opacity: enabled ? 1 : .4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            color: selected ? t.accentA.withValues(alpha: .25) : t.glassFillHi,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled && onTap != null
                  ? () {
                      HapticFeedback.selectionClick();
                      onTap!();
                    }
                  : null,
              child: SizedBox(width: 54, height: 54, child: Icon(icon, size: 23, color: t.text)),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: t.textMuted)),
        ],
      ),
    );
  }
}

class SlideToAnswer extends StatefulWidget {
  const SlideToAnswer({super.key, required this.onAnswer});

  final VoidCallback onAnswer;

  @override
  State<SlideToAnswer> createState() => _SlideToAnswerState();
}

class _SlideToAnswerState extends State<SlideToAnswer>
    with SingleTickerProviderStateMixin {
  static const _handle = 64.0;
  double _dx = 0;
  double _from = 0;

  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..addListener(_handleBack);

  void _handleBack() {
    if (!mounted) return;
    setState(() {
      _dx = _from *
          (1 - Curves.easeOutBack.transform(_back.value)).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final maxDx =
              (constraints.maxWidth - _handle - 8).clamp(0.0, double.infinity);
          return Semantics(
            button: true,
            label: 'Answer call',
            onTap: widget.onAnswer,
            child: GlassSurface(
              radius: 999,
              child: SizedBox(
                height: 72,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Center(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (1 - (_dx / (maxDx == 0 ? 1 : maxDx)))
                              .clamp(0.0, 1.0),
                          child: Text(
                            'slide to answer',
                            style: TextStyle(
                              color: context.moog.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 4 + _dx,
                      top: 4,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: (_) => _back.stop(),
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _dx = (_dx + details.delta.dx)
                                .clamp(0.0, maxDx)
                                .toDouble();
                          });
                        },
                        onHorizontalDragEnd: (_) {
                          if (maxDx > 0 && _dx > maxDx * .85) {
                            HapticFeedback.heavyImpact();
                            widget.onAnswer();
                          } else {
                            _from = _dx;
                            _back.forward(from: 0);
                          }
                        },
                        child: Container(
                          width: _handle,
                          height: _handle,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF64EBA4),
                                Color(0xFF2FD07A),
                                Color(0xFF159653),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: MoogsTheme.call.withValues(alpha: .42),
                                blurRadius: 24,
                                spreadRadius: 1,
                                offset: const Offset(0, 5),
                              ),
                              const BoxShadow(
                                color: Color(0x55FFFFFF),
                                blurRadius: 5,
                                offset: Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_rounded,
                            color: Colors.white,
                            size: 27,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

