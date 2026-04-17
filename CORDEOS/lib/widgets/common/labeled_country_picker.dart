import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LabeledCountryPicker extends StatefulWidget {
  final String? countryCode;
  final Function(Country) onCountryChanged;

  const LabeledCountryPicker({
    super.key,
    this.countryCode,
    required this.onCountryChanged,
  });

  @override
  State<LabeledCountryPicker> createState() => _LabeledCountryPickerState();
}

class _LabeledCountryPickerState extends State<LabeledCountryPicker> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          AppLocalizations.of(context)!.country,
          style: textTheme.labelLarge,
        ),
        GestureDetector(
          onTap: () => showCountrySheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.shadow, width: 1),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.countryCode == null || widget.countryCode!.isEmpty
                      ? AppLocalizations.of(context)!.countryHint
                      : Country.parse(widget.countryCode!).name,
                  style: textTheme.bodyLarge?.copyWith(
                    color:
                        widget.countryCode == null ||
                            widget.countryCode!.isEmpty
                        ? colorScheme.shadow
                        : colorScheme.onSurface,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void showCountrySheet(BuildContext context) {
    context.read<NavigationProvider>().push(
      () => CountrySheet(
        countryCode: widget.countryCode,
        onCountryChanged: widget.onCountryChanged,
      ),
    );
  }
}

class CountrySheet extends StatefulWidget {
  final String? countryCode;
  final Function(Country) onCountryChanged;

  const CountrySheet({
    super.key,
    this.countryCode,
    required this.onCountryChanged,
  });

  @override
  State<CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<CountrySheet> {
  final CountryService _countryService = CountryService();
  final TextEditingController _searchController = TextEditingController();
  late final List<Country> _allCountries;
  final filteredCountries = <Country>[];

  @override
  void initState() {
    super.initState();

    _allCountries = _countryService.getAll();

    filteredCountries.addAll(_allCountries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.shadow, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.chooseCountry,
                  style: textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () =>
                      context.read<NavigationProvider>().attemptPop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // COUNTRY OPTIONS
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: colorScheme.shadow, width: 1),
                ),
                borderRadius: BorderRadius.circular(0),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shrinkWrap: true,
                itemCount: filteredCountries.length,
                itemBuilder: (context, index) {
                  final country = filteredCountries[index];
                  bool isSelected = country.countryCode == widget.countryCode;
            
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FilledTextButton(
                      text: country.name,
                      isDark: isSelected,
                      trailingIcon: Icons.chevron_right,
                      onPressed: () {
                        widget.onCountryChanged(country);
                        context.read<NavigationProvider>().pop();
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // SEARCH FIELD
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchCountry,
                prefixIcon: const Icon(Icons.search),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: BorderSide(color: colorScheme.shadow, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: colorScheme.shadow, width: 2),
                ),
                visualDensity: VisualDensity.compact,
              ),
              onChanged: (value) {
                setState(() {
                  filteredCountries.clear();
                  filteredCountries.addAll(
                    _allCountries.where(
                      (country) => country.name.toLowerCase().contains(
                        value.toLowerCase(),
                      ),
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
