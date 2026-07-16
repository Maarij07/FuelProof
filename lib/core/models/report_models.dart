class DailySpending {
  final String date;
  final double amount;

  DailySpending({required this.date, required this.amount});

  factory DailySpending.fromJson(Map<String, dynamic> json) => DailySpending(
        date: json['date'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      );
}

class FuelBreakdownEntry {
  final String fuelType;
  final double amount;
  final double litres;
  final int count;

  FuelBreakdownEntry({
    required this.fuelType,
    required this.amount,
    required this.litres,
    required this.count,
  });

  factory FuelBreakdownEntry.fromMapEntry(String key, dynamic value) {
    final m = value as Map<String, dynamic>? ?? {};
    return FuelBreakdownEntry(
      fuelType: key,
      amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
      litres: (m['litres'] as num?)?.toDouble() ?? 0.0,
      count: (m['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class MyReportSummary {
  final String period;
  final double totalSpent;
  final double totalLitres;
  final int transactionCount;
  final double avgPerTransaction;
  final List<FuelBreakdownEntry> fuelBreakdown;
  final Map<String, int> paymentBreakdown;
  final List<DailySpending> dailySpending;

  MyReportSummary({
    required this.period,
    required this.totalSpent,
    required this.totalLitres,
    required this.transactionCount,
    required this.avgPerTransaction,
    required this.fuelBreakdown,
    required this.paymentBreakdown,
    required this.dailySpending,
  });

  factory MyReportSummary.fromJson(Map<String, dynamic> json) {
    final fuelMap = (json['fuel_breakdown'] as Map<String, dynamic>?) ?? {};
    final fuelBreakdown = fuelMap.entries
        .map((e) => FuelBreakdownEntry.fromMapEntry(e.key, e.value))
        .toList();

    final payMap = (json['payment_breakdown'] as Map<String, dynamic>?) ?? {};
    final payBreakdown =
        payMap.map((k, v) => MapEntry(k, (v as num).toInt()));

    final dailyList = (json['daily_spending'] as List?) ?? [];
    final dailySpending = dailyList
        .map((e) => DailySpending.fromJson(e as Map<String, dynamic>))
        .toList();

    return MyReportSummary(
      period: json['period'] as String? ?? '',
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      totalLitres: (json['total_litres'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
      avgPerTransaction:
          (json['avg_per_transaction'] as num?)?.toDouble() ?? 0.0,
      fuelBreakdown: fuelBreakdown,
      paymentBreakdown: payBreakdown,
      dailySpending: dailySpending,
    );
  }
}

class PeriodStats {
  final double totalSpent;
  final double totalLitres;
  final int count;

  PeriodStats({
    required this.totalSpent,
    required this.totalLitres,
    required this.count,
  });

  factory PeriodStats.fromJson(Map<String, dynamic> json) => PeriodStats(
        totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
        totalLitres: (json['total_litres'] as num?)?.toDouble() ?? 0.0,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

class MyComparative {
  final String period;
  final PeriodStats current;
  final PeriodStats previous;
  final double changePctSpent;
  final double changePctLitres;
  final double changePctCount;

  MyComparative({
    required this.period,
    required this.current,
    required this.previous,
    required this.changePctSpent,
    required this.changePctLitres,
    required this.changePctCount,
  });

  factory MyComparative.fromJson(Map<String, dynamic> json) {
    final pct = (json['change_pct'] as Map<String, dynamic>?) ?? {};
    return MyComparative(
      period: json['period'] as String? ?? '',
      current:
          PeriodStats.fromJson((json['current'] as Map<String, dynamic>?) ?? {}),
      previous:
          PeriodStats.fromJson((json['previous'] as Map<String, dynamic>?) ?? {}),
      changePctSpent: (pct['spent'] as num?)?.toDouble() ?? 0.0,
      changePctLitres: (pct['litres'] as num?)?.toDouble() ?? 0.0,
      changePctCount: (pct['count'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
