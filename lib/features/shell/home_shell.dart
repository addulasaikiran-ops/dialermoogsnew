import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/theme.dart';
import '../../telecom/call_snapshot.dart';
import '../../telecom/telecom_bridge.dart';
import '../call/call_screen.dart';
import '../dialer/keypad_key.dart';

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
    final foreground = context.moog.text;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: context.moog.accentA.withValues(alpha: .16), border: Border.all(color: context.moog.accentA.withValues(alpha: .5))),
                child: Icon(Icons.call_rounded, color: context.moog.accentA)),
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
        children: _digits.map((digit) => KeypadKey(digit: digit, onTap: () => _append(digit))).toList(),
      )),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 64),
        InkWell(onTap: _placeCall, customBorder: const CircleBorder(), child: Container(
          width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: context.moog.accentB,
            boxShadow: [BoxShadow(color: context.moog.accentB.withValues(alpha: .22), blurRadius: 16, offset: const Offset(0, 5))]),
          child: const Icon(Icons.call_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 28))),
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
      leading: CircleAvatar(backgroundColor: context.moog.accentA.withValues(alpha: .18),
        child: Icon(leading ?? Icons.person_rounded, color: context.moog.accentA)),
      title: Text(entry.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(entry.number, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (favoriteButton) IconButton(icon: Icon(isFavorite ? Icons.star_rounded : Icons.star_border_rounded, color: isFavorite ? Colors.amber : null),
          onPressed: () => _toggleFavorite(entry)),
        IconButton(icon: const Icon(Icons.call_rounded, color: context.moog.accentB), onPressed: () => _dialEntry(entry)),
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
      const Icon(Icons.lock_outline_rounded, size: 38, color: context.moog.accentA),
      const SizedBox(height: 12), Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 14), OutlinedButton(onPressed: () => _loadTab(tab), child: const Text('Try again')),
    ]),
  ));
}

