import 'package:cond_manager/features/access_logs/domain/entities/access_session_log.dart';

class AccessSessionLogModel {
  AccessSessionLogModel({
    required this.id,
    required this.userId,
    required this.userFullName,
    this.companyId,
    this.companyName,
    this.condominiumId,
    this.condominiumName,
    this.contractManagerName,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    required this.accessYear,
    required this.accessMonth,
    required this.accessDay,
  });

  final String id;
  final String userId;
  final String userFullName;
  final String? companyId;
  final String? companyName;
  final String? condominiumId;
  final String? condominiumName;
  final String? contractManagerName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final int accessYear;
  final int accessMonth;
  final int accessDay;

  factory AccessSessionLogModel.fromJson(Map<String, dynamic> json) {
    return AccessSessionLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userFullName: json['user_full_name'] as String? ?? '',
      companyId: json['company_id'] as String?,
      companyName: json['company_name'] as String?,
      condominiumId: json['condominium_id'] as String?,
      condominiumName: json['condominium_name'] as String?,
      contractManagerName: json['contract_manager_name'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int?,
      accessYear: json['access_year'] as int,
      accessMonth: json['access_month'] as int,
      accessDay: json['access_day'] as int,
    );
  }

  AccessSessionLog toEntity() => AccessSessionLog(
        id: id,
        userId: userId,
        userFullName: userFullName,
        companyId: companyId,
        companyName: companyName,
        condominiumId: condominiumId,
        condominiumName: condominiumName,
        contractManagerName: contractManagerName,
        startedAt: startedAt,
        endedAt: endedAt,
        durationSeconds: durationSeconds,
        accessYear: accessYear,
        accessMonth: accessMonth,
        accessDay: accessDay,
      );
}
