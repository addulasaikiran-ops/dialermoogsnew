import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/tokens.dart';
import '../../telecom/call_snapshot.dart';
import '../../telecom/telecom_bridge.dart';

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
                  color: context.moog.accentA.withValues(alpha: .14),
                  border: Border.all(color: context.moog.accentA.withValues(alpha: .45), width: 1.2),
                ),
                child: Icon(Icons.person_rounded, size: 64, color: context.moog.accentA),
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
                      color: context.moog.accentB,
                      onTap: () => _action('reject'),
                    ),
                    _RoundCallButton(
                      icon: Icons.call_rounded,
                      label: 'Answer',
                      color: context.moog.accentB,
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
                      color: context.moog.accentB,
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
                  ? context.moog.accentA.withValues(alpha: .25)
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
                child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      );
}

