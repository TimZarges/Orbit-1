enum GarminConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class GarminStatus {
  final GarminConnectionState state;
  final String? garminUserId;
  final DateTime? connectedAt;
  final DateTime? lastSyncAt;
  final bool isBackfillInProgress;
  final String? errorMessage;

  const GarminStatus({
    this.state = GarminConnectionState.disconnected,
    this.garminUserId,
    this.connectedAt,
    this.lastSyncAt,
    this.isBackfillInProgress = false,
    this.errorMessage,
  });

  factory GarminStatus.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const GarminStatus();

    final stateStr = data['state'] as String?;
    GarminConnectionState state;
    switch (stateStr) {
      case 'CONNECTED':
        state = GarminConnectionState.connected;
        break;
      case 'CONNECTING':
        state = GarminConnectionState.connecting;
        break;
      case 'ERROR':
        state = GarminConnectionState.error;
        break;
      default:
        state = GarminConnectionState.disconnected;
    }

    final backfillData = data['backfill'] as Map<String, dynamic>?;
    final isBackfill = backfillData?['state'] == 'IN_PROGRESS';

    return GarminStatus(
      state: state,
      garminUserId: data['garminUserId'] as String?,
      connectedAt: data['connectedAt'] != null
          ? DateTime.tryParse(data['connectedAt'].toString())
          : null,
      lastSyncAt: data['lastSyncAt'] != null
          ? DateTime.tryParse(data['lastSyncAt'].toString())
          : null,
      isBackfillInProgress: isBackfill,
      errorMessage: data['errorMessage'] as String?,
    );
  }
}
