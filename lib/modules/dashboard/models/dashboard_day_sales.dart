class DashboardDaySales {
  final String dayLabel;
  final String dateLabel;
  final DateTime date;
  final double amount;
  final int count;

  DashboardDaySales({
    required this.dayLabel,
    String? dateLabel,
    DateTime? date,
    required this.amount,
    required this.count,
  }) : date = date ?? DateTime.now(),
       dateLabel =
           dateLabel ??
           '${(date ?? DateTime.now()).month.toString().padLeft(2, '0')}-${(date ?? DateTime.now()).day.toString().padLeft(2, '0')}';
}
