import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:reality_diorama/src/domain/crafting_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/placement_catalog.dart';
import 'package:reality_diorama/src/domain/visual_layer_catalog.dart';

class BalanceDefinition {
  const BalanceDefinition({
    required this.weatherCooldownMinutes,
    required this.weatherMinimumMinutes,
    required this.surroundingCooldownMinutes,
    required this.surroundingMinimumMinutes,
    required this.surroundingDistanceTriggerMeters,
    required this.surroundingScanSeconds,
    required this.surroundingConfidenceThreshold,
    required this.fallbackDailySteps,
    required this.gridColumns,
    required this.gridRows,
    required this.activeObjectLimit,
    required this.repeatVisitorCooldownHours,
  });

  final int weatherCooldownMinutes;
  final int weatherMinimumMinutes;
  final int surroundingCooldownMinutes;
  final int surroundingMinimumMinutes;
  final int surroundingDistanceTriggerMeters;
  final int surroundingScanSeconds;
  final double surroundingConfidenceThreshold;
  final int fallbackDailySteps;
  final int gridColumns;
  final int gridRows;
  final int activeObjectLimit;
  final int repeatVisitorCooldownHours;

  factory BalanceDefinition.fromJson(Map<String, Object?> json) =>
      BalanceDefinition(
        weatherCooldownMinutes: json['weatherCooldownMinutes']! as int,
        weatherMinimumMinutes: json['weatherMinimumMinutes']! as int,
        surroundingCooldownMinutes: json['surroundingCooldownMinutes']! as int,
        surroundingMinimumMinutes: json['surroundingMinimumMinutes']! as int,
        surroundingDistanceTriggerMeters:
            json['surroundingDistanceTriggerMeters']! as int,
        surroundingScanSeconds: json['surroundingScanSeconds']! as int,
        surroundingConfidenceThreshold:
            (json['surroundingConfidenceThreshold']! as num).toDouble(),
        fallbackDailySteps: json['fallbackDailySteps']! as int,
        gridColumns: json['gridColumns']! as int,
        gridRows: json['gridRows']! as int,
        activeObjectLimit: json['activeObjectLimit']! as int,
        repeatVisitorCooldownHours: json['repeatVisitorCooldownHours']! as int,
      );
}

class ContentCatalog {
  const ContentCatalog({
    required this.recipes,
    required this.visitors,
    required this.balance,
    required this.placement,
    this.craftingArt = CraftingArtCatalog.empty,
    this.visualLayers = VisualLayerCatalog.empty,
  });

  final List<RecipeDefinition> recipes;
  final List<VisitorDefinition> visitors;
  final BalanceDefinition balance;
  final PlacementCatalog placement;
  final CraftingArtCatalog craftingArt;
  final VisualLayerCatalog visualLayers;

  RecipeDefinition recipeById(String id) =>
      recipes.firstWhere((RecipeDefinition recipe) => recipe.id == id);

  VisitorDefinition visitorById(String id) =>
      visitors.firstWhere((VisitorDefinition visitor) => visitor.id == id);

  static Future<ContentCatalog> load(AssetBundle bundle) async {
    final recipeDocument =
        jsonDecode(await bundle.loadString('assets/content/recipes.json'))
            as Map<String, Object?>;
    final visitorDocument =
        jsonDecode(await bundle.loadString('assets/content/visitors.json'))
            as Map<String, Object?>;
    final balanceDocument =
        jsonDecode(await bundle.loadString('assets/content/balance.json'))
            as Map<String, Object?>;
    final placementDocument =
        jsonDecode(
              await bundle.loadString('assets/content/placement_catalog.json'),
            )
            as Map<String, Object?>;
    final craftingArtDocument =
        jsonDecode(
              await bundle.loadString(
                'assets/content/crafting_art_catalog.json',
              ),
            )
            as Map<String, Object?>;
    final visualLayerDocument =
        jsonDecode(
              await bundle.loadString(
                'assets/content/visual_layer_catalog.json',
              ),
            )
            as Map<String, Object?>;

    final recipes = (recipeDocument['recipes']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(RecipeDefinition.fromJson)
        .toList(growable: false);
    final placement = PlacementCatalog.fromJson(placementDocument)
      ..validateRecipes(recipes);
    final craftingArt = CraftingArtCatalog.fromJson(craftingArtDocument)
      ..validateRecipes(recipes);
    final visualLayers = VisualLayerCatalog.fromJson(visualLayerDocument)
      ..validate();

    return ContentCatalog(
      recipes: recipes,
      visitors: (visitorDocument['visitors']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(VisitorDefinition.fromJson)
          .toList(growable: false),
      balance: BalanceDefinition.fromJson(balanceDocument),
      placement: placement,
      craftingArt: craftingArt,
      visualLayers: visualLayers,
    );
  }
}
