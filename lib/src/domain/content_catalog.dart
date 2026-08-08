import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:reality_diorama/src/domain/entities.dart';

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
  });

  final List<RecipeDefinition> recipes;
  final List<VisitorDefinition> visitors;
  final BalanceDefinition balance;

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

    return ContentCatalog(
      recipes: (recipeDocument['recipes']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(RecipeDefinition.fromJson)
          .toList(growable: false),
      visitors: (visitorDocument['visitors']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(VisitorDefinition.fromJson)
          .toList(growable: false),
      balance: BalanceDefinition.fromJson(balanceDocument),
    );
  }
}
