import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/districts.dart';

class DistrictPickerField extends StatelessWidget {
  final String? selectedKey;
  final ValueChanged<String> onSelected;
  final String? errorText;

  const DistrictPickerField({
    super.key,
    required this.selectedKey,
    required this.onSelected,
    this.errorText,
  });

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Select your district', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: kKeralaDistricts.length,
                      itemBuilder: (context, index) {
                        final d = kKeralaDistricts[index];
                        final selected = d.key == selectedKey;
                        return ListTile(
                          title: Text(d.label),
                          trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                          onTap: () => Navigator.of(ctx).pop(d.key),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final label = selectedKey == null ? null : districtLabel(selectedKey!);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'District',
          prefixIcon: const Icon(Icons.map_outlined, size: 20),
          errorText: errorText,
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          label ?? 'Choose district',
          style: TextStyle(
            color: label == null ? AppColors.textMuted : AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
