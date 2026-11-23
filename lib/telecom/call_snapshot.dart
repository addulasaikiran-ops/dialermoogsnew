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

