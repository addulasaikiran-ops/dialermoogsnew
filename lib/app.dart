import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Places the live call experience above the normal tab shell.
///
/// Keeping call state here means the home shell can remain mounted and retain
/// its tab state while Android reports an incoming, active, or ending call.
class CallGate<T> extends StatefulWidget {
  const CallGate({
    super.key,
    required this.child,
    required this.events,
    required this.loadCurrent,
    required this.hasCall,
    required this.callBuilder,
  });

  final Widget child;
  final Stream<T> events;
  final Future<T> Function() loadCurrent;
  final bool Function(T value) hasCall;
  final Widget Function(T value) callBuilder;

  @override
  State<CallGate<T>> createState() => _CallGateState<T>();
}

class _CallGateState<T> extends State<CallGate<T>> {
  StreamSubscription<T>? _subscription;
  T? _call;

  @override
  void initState() {
    super.initState();
    _subscription = widget.events.listen(
      (value) {
        if (mounted) setState(() => _call = widget.hasCall(value) ? value : null);
      },
      onError: (_) {},
    );
    _restoreCurrentCall();
  }

  Future<void> _restoreCurrentCall() async {
    try {
      final value = await widget.loadCurrent();
      if (mounted) setState(() => _call = widget.hasCall(value) ? value : null);
    } on PlatformException {
      // Keep the regular dialer available when Telecom is not ready yet.
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = _call;
    final page = call == null ? widget.child : widget.callBuilder(call);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .96, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(call == null ? 'phone-shell' : 'live-call'),
        child: page,
      ),
    );
  }
}
