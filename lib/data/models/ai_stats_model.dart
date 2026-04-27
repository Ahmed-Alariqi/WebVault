// Lightweight DTOs that mirror the `get_ai_*` Postgres RPCs powering the
// admin AI stats dashboard. Kept hand-rolled (no codegen) so the file stays
// dependency-free.

enum AiStatsPeriod {
  today(label: 'اليوم', days: 1),
  week(label: '7 أيام', days: 7),
  max(label: '15 يوم', days: 15);

  final String label;
  final int days;
  const AiStatsPeriod({required this.label, required this.days});
}

class AiOverviewStats {
  final int total;
  final int successCount;
  final int errorCount;
  final double avgMs;
  final double successPct;

  const AiOverviewStats({
    required this.total,
    required this.successCount,
    required this.errorCount,
    required this.avgMs,
    required this.successPct,
  });

  factory AiOverviewStats.fromJson(Map<String, dynamic> j) => AiOverviewStats(
        total: (j['total'] as num?)?.toInt() ?? 0,
        successCount: (j['success_count'] as num?)?.toInt() ?? 0,
        errorCount: (j['error_count'] as num?)?.toInt() ?? 0,
        avgMs: (j['avg_ms'] as num?)?.toDouble() ?? 0,
        successPct: (j['success_pct'] as num?)?.toDouble() ?? 0,
      );

  static const empty = AiOverviewStats(
    total: 0,
    successCount: 0,
    errorCount: 0,
    avgMs: 0,
    successPct: 0,
  );
}

class AiPersonaUsage {
  final String? personaId;
  final String name;
  final String icon;
  final int count;

  const AiPersonaUsage({
    required this.personaId,
    required this.name,
    required this.icon,
    required this.count,
  });

  factory AiPersonaUsage.fromJson(Map<String, dynamic> j) => AiPersonaUsage(
        personaId: j['persona_id'] as String?,
        name: (j['name'] as String?) ?? 'محذوف',
        icon: (j['icon'] as String?) ?? 'robot',
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

class AiProviderUsage {
  final String? providerId;
  final String name;
  final String slug;
  final int count;
  final double successPct;

  const AiProviderUsage({
    required this.providerId,
    required this.name,
    required this.slug,
    required this.count,
    required this.successPct,
  });

  factory AiProviderUsage.fromJson(Map<String, dynamic> j) => AiProviderUsage(
        providerId: j['provider_id'] as String?,
        name: (j['name'] as String?) ?? 'محذوف',
        slug: (j['slug'] as String?) ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
        successPct: (j['success_pct'] as num?)?.toDouble() ?? 0,
      );
}

class AiUserUsage {
  final String? userId;
  final String username;
  final String fullName;
  final String email;
  final int count;

  const AiUserUsage({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.email,
    required this.count,
  });

  factory AiUserUsage.fromJson(Map<String, dynamic> j) => AiUserUsage(
        userId: j['user_id'] as String?,
        username: (j['username'] as String?) ?? '—',
        fullName: (j['full_name'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
      );

  /// Best-effort display label: prefer username → email → short id.
  String get displayLabel {
    if (username.isNotEmpty && username != '—') return '@$username';
    if (email.isNotEmpty) return email;
    if (fullName.isNotEmpty) return fullName;
    return userId == null ? 'غير معروف' : userId!.substring(0, 8);
  }
}

/// Per-key health row. The API key itself is never exposed — only the last
/// 4 characters (`keySuffix`) so the admin can correlate against the keys
/// they entered in the providers tab.
class AiKeyHealth {
  final String? providerId;
  final String providerName;
  final String keySuffix;
  final int success;
  final int fail;
  final int? lastStatus;
  final DateTime? lastErrorAt;

  const AiKeyHealth({
    required this.providerId,
    required this.providerName,
    required this.keySuffix,
    required this.success,
    required this.fail,
    required this.lastStatus,
    required this.lastErrorAt,
  });

  factory AiKeyHealth.fromJson(Map<String, dynamic> j) => AiKeyHealth(
        providerId: j['provider_id'] as String?,
        providerName: (j['provider_name'] as String?) ?? 'محذوف',
        keySuffix: (j['key_suffix'] as String?) ?? '????',
        success: (j['success'] as num?)?.toInt() ?? 0,
        fail: (j['fail'] as num?)?.toInt() ?? 0,
        lastStatus: (j['last_status'] as num?)?.toInt(),
        lastErrorAt: j['last_error_at'] == null
            ? null
            : DateTime.tryParse(j['last_error_at'].toString()),
      );

  /// Tri-state health classification used to colour the indicator in the UI.
  /// We only label a key 🔴 once it has more failures than successes AND
  /// at least 5 failures, to avoid alarming on a single transient blip.
  AiKeyHealthLevel get level {
    if (fail == 0) return AiKeyHealthLevel.healthy;
    if (fail >= 5 && fail >= success) return AiKeyHealthLevel.broken;
    return AiKeyHealthLevel.warning;
  }
}

enum AiKeyHealthLevel { healthy, warning, broken }

class AiErrorEntry {
  final DateTime createdAt;
  final String providerName;
  final int statusCode;
  final String? errorMessage;
  final String? keySuffix;

  const AiErrorEntry({
    required this.createdAt,
    required this.providerName,
    required this.statusCode,
    required this.errorMessage,
    required this.keySuffix,
  });

  factory AiErrorEntry.fromJson(Map<String, dynamic> j) => AiErrorEntry(
        createdAt: DateTime.parse(j['created_at'].toString()),
        providerName: (j['provider_name'] as String?) ?? 'محذوف',
        statusCode: (j['status_code'] as num?)?.toInt() ?? 0,
        errorMessage: j['error_message'] as String?,
        keySuffix: j['key_suffix'] as String?,
      );
}
