import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/tokens.dart';
import 'core/widgets/aurora_backdrop.dart';
import 'core/widgets/moog_logo.dart';

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

  static Future<void> placeCall(String number) =>
      act('placeCall', {'number': number});

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
  static const _digits = <String>['1','2','3','4','5','6','7','8','9','*','0','#'];
  int _selectedTab = 3;
  String _number = '';
  String _search = '';
  bool _requestingRole = false;
  bool _loading = false;
  String? _loadError;
  List<PhoneEntry> _contacts = const [];
  List<PhoneEntry> _recents = const [];
  List<PhoneEntry> _favorites = const [];
  CallSnapshot? _call;
  StreamSubscription<CallSnapshot>? _callSubscription;

  @override
  void initState() {
    super.initState();
    _callSubscription = TelecomBridge.callEvents.listen(
      (snapshot) { if (mounted) setState(() => _call = snapshot.hasCall ? snapshot : null); },
      onError: (_) {},
    );
    _loadCall();
  }

  Future<void> _loadCall() async {
    try {
      final snapshot = await TelecomBridge.currentCall();
      if (mounted) setState(() => _call = snapshot.hasCall ? snapshot : null);
    } on PlatformException { /* Preview mode remains usable. */ }
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

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
    try { await TelecomBridge.placeCall(_number); }
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
    final call = _call;
    if (call != null) return CallScreen(key: const ValueKey('call-screen'), call: call);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.white : const Color(0xFF20232B);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuroraBackdrop(),
          SafeArea(
            child: Column(children: [
          Padding(
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
              Expanded(child: _buildSelectedContent(foreground)),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => _loadTab(index),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.star_border_rounded), selectedIcon: Icon(Icons.star_rounded), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.history_rounded), selectedIcon: Icon(Icons.history_rounded), label: 'Recents'),
          NavigationDestination(icon: Icon(Icons.contacts_outlined), selectedIcon: Icon(Icons.contacts_rounded), label: 'Contacts'),
          NavigationDestination(icon: Icon(Icons.dialpad_rounded), selectedIcon: Icon(Icons.dialpad_rounded), label: 'Keypad'),
        ],
      ),
    );
  }

  Widget _buildSelectedContent(Color foreground) {
    // Build only the selected page. This keeps first launch lighter on entry-level devices.
    switch (_selectedTab) {
      case 0:
        return _buildListScreen('Favorites', _favorites, Icons.star_rounded, empty: 'Your favorite contacts will appear here.');
      case 1:
        return _buildListScreen('Recents', _recents, Icons.call_made_rounded, showCallType: true, empty: 'Your recent calls will appear here.');
      case 2:
        return _buildContactsScreen();
      default:
        return _buildKeypad(foreground);
    }
  }

  Widget _buildKeypad(Color foreground) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
    child: Column(children: [
      const Spacer(),
      Text(_number.isEmpty ? 'Enter a number' : _number, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: foreground, fontWeight: FontWeight.w400, letterSpacing: 2)),
      const SizedBox(height: 20),
      SizedBox(width: 276, child: GridView.count(
        crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 7, crossAxisSpacing: 14, childAspectRatio: 1.38,
        children: _digits.map((digit) => _KeypadButton(digit: digit, onTap: () => _append(digit))).toList(),
      )),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 64),
        InkWell(onTap: _placeCall, customBorder: const CircleBorder(), child: Container(
          width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: MoogsTheme.call,
            boxShadow: [BoxShadow(color: MoogsTheme.call.withValues(alpha: .22), blurRadius: 16, offset: const Offset(0, 5))]),
          child: const Icon(Icons.call_rounded, color: Colors.white, size: 28))),
        SizedBox(width: 64, child: IconButton(
          tooltip: 'Delete last digit',
          onPressed: _number.isEmpty ? null : () => setState(() => _number = _number.substring(0, _number.length - 1)),
          icon: const Icon(Icons.backspace_outlined))),
      ]),
      const Spacer(),
    ]),
  );

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
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)))),
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
    if (mounted) {
      setState(() => _elapsedSeconds = duration.clamp(0, 1 << 30) ~/ 1000);
    }
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
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuroraBackdrop(),
          SafeArea(
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
        ],
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
