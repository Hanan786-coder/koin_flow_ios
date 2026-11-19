int _idCounter = 0;

/// Unique even when many records are created in the same microsecond.
String newId() => '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

class Expense {
  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  }) : id = id ?? newId();

  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String note;

  Expense copyWith({
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
  }) => Expense(
    id: id,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    date: date ?? this.date,
    note: note ?? this.note,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory Expense.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    return Expense(
      // Older saves have no id; derive a stable one from the record.
      id:
          json['id'] as String? ??
          '${date.microsecondsSinceEpoch}-${(json['title'] as String).hashCode}',
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: date,
      note: json['note'] as String? ?? '',
    );
  }
}

class MoneyEntry {
  MoneyEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.note,
    required this.isOwedToMe,
    this.dueDate,
    this.settled = false,
  });

  final String id;
  final String name;
  final double amount;
  final String note;
  final bool isOwedToMe;
  final DateTime? dueDate;
  final bool settled;

  MoneyEntry copyWith({bool? settled}) => MoneyEntry(
    id: id,
    name: name,
    amount: amount,
    note: note,
    isOwedToMe: isOwedToMe,
    dueDate: dueDate,
    settled: settled ?? this.settled,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'note': note,
    'isOwedToMe': isOwedToMe,
    'dueDate': dueDate?.toIso8601String(),
    'settled': settled,
  };

  factory MoneyEntry.fromJson(Map<String, dynamic> json) => MoneyEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    amount: (json['amount'] as num).toDouble(),
    note: json['note'] as String,
    isOwedToMe: json['isOwedToMe'] as bool,
    dueDate: json['dueDate'] != null
        ? DateTime.parse(json['dueDate'] as String)
        : null,
    settled: json['settled'] as bool? ?? false,
  );
}

/// A bill or subscription that repeats every month on [dueDay].
class Bill {
  Bill({
    String? id,
    required this.name,
    required this.amount,
    required this.dueDay,
    this.category = 'Bills',
    this.paidMonths = const [],
  }) : id = id ?? newId();

  final String id;
  final String name;
  final double amount;
  final int dueDay; // 1–28
  final String category;

  /// Months already paid, as "yyyy-mm".
  final List<String> paidMonths;

  static String monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  bool isPaidFor(DateTime month) => paidMonths.contains(monthKey(month));

  DateTime dueDateIn(DateTime month) =>
      DateTime(month.year, month.month, dueDay);

  /// Days from [today] until this month's due date. Negative = overdue.
  int daysUntilDue(DateTime today) {
    final t = DateTime(today.year, today.month, today.day);
    return dueDateIn(today).difference(t).inDays;
  }

  Bill copyWith({
    String? name,
    double? amount,
    int? dueDay,
    String? category,
    List<String>? paidMonths,
  }) => Bill(
    id: id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    dueDay: dueDay ?? this.dueDay,
    category: category ?? this.category,
    paidMonths: paidMonths ?? this.paidMonths,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'dueDay': dueDay,
    'category': category,
    'paidMonths': paidMonths,
  };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: json['id'] as String,
    name: json['name'] as String,
    amount: (json['amount'] as num).toDouble(),
    dueDay: (json['dueDay'] as num).toInt().clamp(1, 28),
    category: json['category'] as String? ?? 'Bills',
    paidMonths: (json['paidMonths'] as List? ?? const [])
        .map((e) => e as String)
        .toList(),
  );
}
