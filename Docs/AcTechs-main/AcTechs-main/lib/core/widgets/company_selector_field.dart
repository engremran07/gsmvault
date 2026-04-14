import 'package:flutter/material.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class CompanySelectorField extends StatelessWidget {
  const CompanySelectorField({
    super.key,
    required this.companies,
    required this.selectedCompanyId,
    required this.onChanged,
    this.enabled = true,
    this.includeNoCompanyOption = true,
    this.labelText,
    this.hintText,
    this.prefixIcon,
  });

  final List<CompanyModel> companies;
  final String? selectedCompanyId;
  final ValueChanged<CompanyModel?> onChanged;
  final bool enabled;
  final bool includeNoCompanyOption;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    CompanyModel? selected;
    for (final company in companies) {
      if (company.id == selectedCompanyId) {
        selected = company;
        break;
      }
    }

    return DropdownButtonFormField<String>(
      initialValue: selected?.id,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText ?? l.selectCompany,
        prefixIcon:
            prefixIcon ??
            const Icon(
              Icons.apartment_rounded,
              color: ArcticTheme.arcticTextSecondary,
            ),
      ),
      items: [
        if (includeNoCompanyOption)
          DropdownMenuItem<String>(
            value: '',
            child: Text(
              l.noCompany,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ArcticTheme.arcticTextSecondary,
              ),
            ),
          ),
        ...companies.map(
          (company) => DropdownMenuItem<String>(
            value: company.id,
            child: Text(company.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: !enabled
          ? null
          : (value) {
              if (value == null || value.isEmpty) {
                onChanged(null);
                return;
              }
              CompanyModel? company;
              for (final item in companies) {
                if (item.id == value) {
                  company = item;
                  break;
                }
              }
              onChanged(company);
            },
    );
  }
}
