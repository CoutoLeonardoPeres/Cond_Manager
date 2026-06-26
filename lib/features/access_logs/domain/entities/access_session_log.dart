import 'package:equatable/equatable.dart';

class AccessSessionLog extends Equatable {
  const AccessSessionLog({
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

  bool get isActive => endedAt == null;

  @override
  List<Object?> get props => [id];
}

class AccessLogFilter extends Equatable {
  const AccessLogFilter({
    this.companyId,
    this.condominiumId,
    this.year,
    this.month,
    this.day,
    this.userNameQuery,
  });

  final String? companyId;
  final String? condominiumId;
  final int? year;
  final int? month;
  final int? day;
  final String? userNameQuery;

  AccessLogFilter copyWith({
    String? companyId,
    String? condominiumId,
    int? year,
    int? month,
    int? day,
    String? userNameQuery,
    bool clearCompany = false,
    bool clearCondominium = false,
    bool clearYear = false,
    bool clearMonth = false,
    bool clearDay = false,
    bool clearUserName = false,
  }) {
    return AccessLogFilter(
      companyId: clearCompany ? null : (companyId ?? this.companyId),
      condominiumId:
          clearCondominium ? null : (condominiumId ?? this.condominiumId),
      year: clearYear ? null : (year ?? this.year),
      month: clearMonth ? null : (month ?? this.month),
      day: clearDay ? null : (day ?? this.day),
      userNameQuery: clearUserName ? null : (userNameQuery ?? this.userNameQuery),
    );
  }

  @override
  List<Object?> get props =>
      [companyId, condominiumId, year, month, day, userNameQuery];
}

class AccessLogSummary extends Equatable {
  const AccessLogSummary({
    required this.sessionCount,
    required this.totalDurationSeconds,
    required this.uniqueUsers,
  });

  final int sessionCount;
  final int totalDurationSeconds;
  final int uniqueUsers;

  @override
  List<Object?> get props => [sessionCount, totalDurationSeconds, uniqueUsers];
}
