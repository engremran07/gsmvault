class InvoiceUtils {
  InvoiceUtils._();

  /// Normalizes invoice values for storage and duplicate checks.
  /// Strips legacy "INV-"/"INV " prefixes and trims whitespace.
  static String normalize(String invoice) {
    final trimmed = invoice.trim();
    if (trimmed.isEmpty) return '';

    final upper = trimmed.toUpperCase();
    if (upper.startsWith('INV-') || upper.startsWith('INV ')) {
      return trimmed.substring(4).trim();
    }

    return trimmed;
  }

  /// Removes a selected company prefix from the start of a stored invoice.
  static String normalizeWithCompanyPrefix(
    String invoice, {
    String? companyPrefix,
  }) {
    var normalized = normalize(invoice);
    if (normalized.isEmpty) return normalized;

    final trimmedPrefix = companyPrefix?.trim() ?? '';
    if (trimmedPrefix.isEmpty) {
      return normalized;
    }

    final upperInvoice = normalized.toUpperCase();
    final upperPrefix = trimmedPrefix.toUpperCase();
    final prefixVariants = <String>[
      '$upperPrefix-',
      '$upperPrefix ',
      '$upperPrefix/',
    ];

    for (final variant in prefixVariants) {
      if (upperInvoice.startsWith(variant)) {
        normalized = normalized.substring(variant.length).trim();
        break;
      }
    }

    if (normalized == invoice.trim()) {
      if (upperInvoice == upperPrefix) {
        normalized = '';
      } else if (upperInvoice.startsWith(upperPrefix) &&
          upperInvoice.length > upperPrefix.length) {
        final nextChar = upperInvoice.substring(
          upperPrefix.length,
          upperPrefix.length + 1,
        );
        if (RegExp(r'\d').hasMatch(nextChar)) {
          normalized = normalized.substring(upperPrefix.length).trim();
        }
      }
    }

    return normalize(normalized);
  }

  static String sharedInstallGroupKey({
    required String companyId,
    required String invoiceNumber,
  }) {
    final normalizedInvoice = normalize(invoiceNumber).toLowerCase();
    final normalizedCompanyId = companyId.trim().toLowerCase();
    final companyToken = normalizedCompanyId.isEmpty
        ? 'no-company'
        : normalizedCompanyId;
    if (normalizedInvoice.isEmpty) {
      return companyToken;
    }
    return '$companyToken-$normalizedInvoice';
  }

  static String invoiceClaimDocumentId(String invoiceNumber) {
    final normalized = normalize(invoiceNumber).trim().toLowerCase();
    return normalized.isEmpty ? 'unknown_invoice' : normalized;
  }
}
