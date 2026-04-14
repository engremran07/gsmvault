import 'package:ac_techs/core/models/models.dart';

class ReportBrandIdentity {
  const ReportBrandIdentity({
    required this.name,
    this.logoBase64 = '',
    this.phoneNumber = '',
  });

  final String name;
  final String logoBase64;
  final String phoneNumber;

  bool get hasLogo => logoBase64.trim().isNotEmpty;
}

class ReportBrandingContext {
  const ReportBrandingContext({
    required this.serviceCompany,
    this.clientCompany,
  });

  final ReportBrandIdentity serviceCompany;
  final ReportBrandIdentity? clientCompany;

  bool get hasClientCompany =>
      clientCompany != null && clientCompany!.name.trim().isNotEmpty;

  factory ReportBrandingContext.fromAppBranding({
    required AppBrandingConfig appBranding,
    required String fallbackServiceName,
    CompanyModel? clientCompany,
    String? fallbackClientName,
  }) {
    final serviceName = appBranding.companyName.trim().isEmpty
        ? fallbackServiceName
        : appBranding.companyName.trim();
    final clientName = clientCompany?.name.trim().isNotEmpty ?? false
        ? clientCompany!.name.trim()
        : (fallbackClientName?.trim().isNotEmpty ?? false)
        ? fallbackClientName!.trim()
        : '';

    return ReportBrandingContext(
      serviceCompany: ReportBrandIdentity(
        name: serviceName,
        logoBase64: appBranding.logoBase64,
        phoneNumber: appBranding.phoneNumber,
      ),
      clientCompany: clientName.isEmpty
          ? null
          : ReportBrandIdentity(
              name: clientName,
              logoBase64: clientCompany?.logoBase64 ?? '',
            ),
    );
  }
}
