class AppBrandingConfig {
  const AppBrandingConfig({
    required this.companyName,
    required this.phoneNumber,
    required this.logoBase64,
  });

  final String companyName;
  final String phoneNumber;
  final String logoBase64;

  factory AppBrandingConfig.defaults() =>
      const AppBrandingConfig(companyName: '', phoneNumber: '', logoBase64: '');

  factory AppBrandingConfig.fromMap(Map<String, dynamic>? data) {
    return AppBrandingConfig(
      companyName: data?['companyName'] as String? ?? '',
      phoneNumber: data?['phoneNumber'] as String? ?? '',
      logoBase64: data?['logoBase64'] as String? ?? '',
    );
  }

  AppBrandingConfig copyWith({
    String? companyName,
    String? phoneNumber,
    String? logoBase64,
  }) {
    return AppBrandingConfig(
      companyName: companyName ?? this.companyName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      logoBase64: logoBase64 ?? this.logoBase64,
    );
  }

  Map<String, dynamic> toMap() => {
    'companyName': companyName,
    'phoneNumber': phoneNumber,
    'logoBase64': logoBase64,
  };
}
