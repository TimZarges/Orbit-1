/// @file garmin_status.dart
/// @description Datenmodell für den Verbindungs- und Synchronisationsstatus von Garmin Connect.

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
  final int lastSyncCount;
  final String? lastSyncMessage;
  final bool isBackfillInProgress;
  final int receivedActivities;
  final int receivedHealthDays;
  final int targetDays;
  final String? errorMessage;

  const GarminStatus({
    this.state = GarminConnectionState.disconnected,
    this.garminUserId,
    this.connectedAt,
    this.lastSyncAt,
    this.lastSyncCount = 0,
    this.lastSyncMessage,
    this.isBackfillInProgress = false,
    this.receivedActivities = 0,
    this.receivedHealthDays = 0,
    this.targetDays = 90,
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
    final receivedActivities =
        (backfillData?['receivedActivities'] as num?)?.toInt() ?? 0;
    final receivedHealthDays =
        (backfillData?['receivedHealthDays'] as num?)?.toInt() ?? 0;
    final targetDays = (backfillData?['targetDays'] as num?)?.toInt() ?? 90;

    return GarminStatus(
      state: state,
      garminUserId: data['garminUserId'] as String?,
      connectedAt: data['connectedAt'] != null
          ? DateTime.tryParse(data['connectedAt'].toString())
          : null,
      lastSyncAt: data['lastSyncAt'] != null
          ? DateTime.tryParse(data['lastSyncAt'].toString())
          : null,
      lastSyncCount: (data['lastSyncCount'] as num?)?.toInt() ?? 0,
      lastSyncMessage: data['lastSyncMessage'] as String?,
      isBackfillInProgress: isBackfill,
      receivedActivities: receivedActivities,
      receivedHealthDays: receivedHealthDays,
      targetDays: targetDays,
      errorMessage: data['errorMessage'] as String?,
    );
  }
}
