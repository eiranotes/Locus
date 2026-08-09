import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/atmospheric_trait_catalog.dart';
import 'package:reality_diorama/src/domain/enums.dart';

class AtmosphericTraitChips extends StatelessWidget {
  const AtmosphericTraitChips({
    required this.traits,
    required this.catalog,
    this.showEffects = false,
    super.key,
  });

  final List<AtmosphericTrait> traits;
  final AtmosphericTraitCatalog catalog;
  final bool showEffects;

  @override
  Widget build(BuildContext context) {
    if (traits.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: traits
          .map((AtmosphericTrait trait) {
            final definition = catalog.tryDefinitionFor(trait);
            if (definition == null) return const SizedBox.shrink();
            final label = showEffects
                ? '${definition.labelKo} · ${definition.effectLabelKo}'
                : definition.labelKo;
            return Semantics(
              label: '${definition.labelKo}, ${definition.descriptionKo}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: PixelPalette.blue.withValues(alpha: 0.12),
                  border: Border.all(
                    color: PixelPalette.blue.withValues(alpha: 0.45),
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: PixelPalette.cream,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

String atmosphericTraitSummary(
  List<AtmosphericTrait> traits,
  AtmosphericTraitCatalog catalog,
) => traits
    .map(catalog.tryDefinitionFor)
    .whereType<AtmosphericTraitDefinition>()
    .map((AtmosphericTraitDefinition value) => value.labelKo)
    .join(' · ');
