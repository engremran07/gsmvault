import 'package:ac_techs/l10n/app_localizations.dart';

/// Centralized date/time formatting that respects locale.
class AppFormatters {
  AppFormatters._();

  /// Format a date as dd/MM/yyyy.
  static String date(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  /// SAR currency with no decimals.
  static String currency(double amount) {
    return 'SAR ${amount.toStringAsFixed(0)}';
  }

  /// Plural-safe unit count.
  static String units(int count) {
    return '$count ${count == 1 ? 'unit' : 'units'}';
  }

  /// Format a date+time as dd/MM/yyyy HH:mm.
  static String dateTime(DateTime? dt) {
    if (dt == null) return '';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${date(dt)}  $hh:$mm';
  }

  /// Returns '' for null; strips newlines and trims whitespace.
  static String safeText(String? value) {
    if (value == null) return '';
    return value.replaceAll('\n', ' ').trim();
  }

  /// Returns true when the delivery/expense note indicates the customer paid
  /// in cash (used in PDF and Excel export to suppress SAR charge display).
  static bool isCustomerCashPaid(String? note) {
    final normalized = safeText(note).toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized.contains('cash') ||
        normalized.contains('customer paid') ||
        normalized.contains('paid by customer');
  }

  /// Midnight at the start of [dt] (defaults to today).
  static DateTime startOfDay([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  /// 23:59:59.999 at the end of [dt] (defaults to today).
  static DateTime endOfDay([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
  }

  /// First moment of the month containing [dt] (defaults to today).
  static DateTime startOfMonth([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateTime(d.year, d.month);
  }

  /// Last moment of the month containing [dt] (defaults to today).
  static DateTime endOfMonth([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateTime(d.year, d.month + 1, 0, 23, 59, 59, 999);
  }

  /// Short name for display (first 8 chars + ..).
  static String shortName(String name, [int max = 8]) {
    if (name.length <= max) return name;
    return '${name.substring(0, max)}..';
  }

  // ── Filename / export utilities ─────────────────────────────────────────────

  /// Converts a string to a lowercase kebab-case slug safe for file names.
  /// e.g. "Ahmed Shah" → "ahmed-shah", "INV-001/A" → "inv-001-a"
  static String slugify(String input) {
    final lower = input.toLowerCase().trim();
    final sanitized = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return sanitized
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Returns a lowercase month-year token for file names, e.g. "january-2025".
  static String monthToken(DateTime month) {
    const monthNames = <String>[
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    return '${monthNames[month.month - 1]}-${month.year}';
  }

  /// Returns just the lowercase month name token, e.g. "january".
  static String monthNameToken(DateTime month) {
    const monthNames = <String>[
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    return monthNames[month.month - 1];
  }

  /// Returns a localized "Month YYYY" label using ARB-sourced month names.
  /// Use this in widget contexts where [AppLocalizations] is available.
  static String monthLabel(AppLocalizations l, DateTime month) {
    final names = <String>[
      l.january,
      l.february,
      l.march,
      l.april,
      l.may,
      l.june,
      l.july,
      l.august,
      l.september,
      l.october,
      l.november,
      l.december,
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  /// Returns a localized "Month YYYY" label using inline locale strings.
  /// Use this in non-widget contexts (PDF, Excel, export filenames).
  static String monthLabelForLocale(String locale, DateTime month) {
    final names = switch (locale) {
      'ur' => const <String>[
        'جنوری',
        'فروری',
        'مارچ',
        'اپریل',
        'مئی',
        'جون',
        'جولائی',
        'اگست',
        'ستمبر',
        'اکتوبر',
        'نومبر',
        'دسمبر',
      ],
      'ar' => const <String>[
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ],
      _ => const <String>[
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ],
    };
    return '${names[month.month - 1]} ${month.year}';
  }
}
