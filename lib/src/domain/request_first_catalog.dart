import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

class RequestFirstBalance {
  const RequestFirstBalance({
    required this.tutorialRequestSlots,
    required this.requestSlots,
    required this.gameDayBoundaryHour,
    required this.requestLifetimeHours,
    required this.requestReplacementCooldownHours,
    required this.specimenCaptureSeconds,
    required this.minimumCaptureConfidence,
    required this.everydayRequestRatio,
    required this.overlapPairRate,
    required this.historyRequestMinimumSpecimens,
    required this.relationshipStageThresholds,
    required this.gridColumns,
    required this.gridRows,
    required this.activeObjectLimit,
  });

  final int tutorialRequestSlots;
  final int requestSlots;
  final int gameDayBoundaryHour;
  final int requestLifetimeHours;
  final int requestReplacementCooldownHours;
  final int specimenCaptureSeconds;
  final double minimumCaptureConfidence;
  final double everydayRequestRatio;
  final double overlapPairRate;
  final int historyRequestMinimumSpecimens;
  final List<int> relationshipStageThresholds;
  final int gridColumns;
  final int gridRows;
  final int activeObjectLimit;

  factory RequestFirstBalance.fromJson(Map<String, Object?> json) =>
      RequestFirstBalance(
        tutorialRequestSlots: json['tutorialRequestSlots']! as int,
        requestSlots: json['requestSlots']! as int,
        gameDayBoundaryHour: json['gameDayBoundaryHour']! as int,
        requestLifetimeHours: json['requestLifetimeHours']! as int,
        requestReplacementCooldownHours:
            json['requestReplacementCooldownHours']! as int,
        specimenCaptureSeconds: json['specimenCaptureSeconds']! as int,
        minimumCaptureConfidence: (json['minimumCaptureConfidence']! as num)
            .toDouble(),
        everydayRequestRatio: (json['everydayRequestRatio']! as num).toDouble(),
        overlapPairRate: (json['overlapPairRate']! as num).toDouble(),
        historyRequestMinimumSpecimens:
            json['historyRequestMinimumSpecimens']! as int,
        relationshipStageThresholds:
            (json['relationshipStageThresholds']! as List<Object?>).cast<int>(),
        gridColumns: json['gridColumns']! as int,
        gridRows: json['gridRows']! as int,
        activeObjectLimit: json['activeObjectLimit']! as int,
      );
}

class SenseAxisDefinition {
  const SenseAxisDefinition({
    required this.axis,
    required this.nameKo,
    required this.initiallyUnlocked,
    required this.channel,
  });

  final SenseAxis axis;
  final String nameKo;
  final bool initiallyUnlocked;
  final SenseChannel channel;

  factory SenseAxisDefinition.fromJson(Map<String, Object?> json) =>
      SenseAxisDefinition(
        axis: SenseAxis.values.byName(json['id']! as String),
        nameKo: json['nameKo']! as String,
        initiallyUnlocked: json['initiallyUnlocked']! as bool,
        channel: SenseChannel.values.byName(json['channel']! as String),
      );
}

class RequestTemplateDefinition {
  RequestTemplateDefinition({
    required this.id,
    required List<String> visitorIds,
    required this.promptKo,
    required List<RequestConstraint> constraints,
    required Set<String> overlapTags,
    required this.accessTier,
    required this.difficulty,
    required this.minimumRelationshipStage,
    required this.historyComparison,
  }) : visitorIds = List<String>.unmodifiable(visitorIds),
       constraints = List<RequestConstraint>.unmodifiable(constraints),
       overlapTags = Set<String>.unmodifiable(overlapTags);

  final String id;
  final List<String> visitorIds;
  final String promptKo;
  final List<RequestConstraint> constraints;
  final Set<String> overlapTags;
  final RequestAccessTier accessTier;
  final int difficulty;
  final int minimumRelationshipStage;
  final HistoryComparison historyComparison;

  Set<SenseAxis> get requiredAxes =>
      constraints.map((RequestConstraint value) => value.axis).toSet();

  factory RequestTemplateDefinition.fromJson(Map<String, Object?> json) =>
      RequestTemplateDefinition(
        id: json['id']! as String,
        visitorIds: (json['visitorIds']! as List<Object?>).cast<String>(),
        promptKo: json['promptKo']! as String,
        constraints: (json['constraints']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(RequestConstraint.fromJson)
            .toList(growable: false),
        overlapTags: (json['overlapTags'] as List<Object?>? ?? const [])
            .whereType<String>()
            .toSet(),
        accessTier: enumByName(
          RequestAccessTier.values,
          json['accessTier'] as String? ?? '',
          RequestAccessTier.everyday,
        ),
        difficulty: json['difficulty']! as int,
        minimumRelationshipStage: json['minimumRelationshipStage'] as int? ?? 0,
        historyComparison: enumByName(
          HistoryComparison.values,
          json['historyComparison'] as String? ?? '',
          HistoryComparison.none,
        ),
      );
}

class RelationshipMilestoneDefinition {
  const RelationshipMilestoneDefinition({
    required this.stage,
    required this.fulfilledCount,
    this.unlockAxis,
    this.sceneObjectId,
    this.becomesResident = false,
  });

  final int stage;
  final int fulfilledCount;
  final SenseAxis? unlockAxis;
  final String? sceneObjectId;
  final bool becomesResident;

  factory RelationshipMilestoneDefinition.fromJson(Map<String, Object?> json) =>
      RelationshipMilestoneDefinition(
        stage: json['stage']! as int,
        fulfilledCount: json['fulfilledCount']! as int,
        unlockAxis: json['unlockAxis'] == null
            ? null
            : SenseAxis.values.byName(json['unlockAxis']! as String),
        sceneObjectId: json['sceneObjectId'] as String?,
        becomesResident: json['becomesResident'] as bool? ?? false,
      );
}

class RelationshipTrackDefinition {
  RelationshipTrackDefinition({
    required this.visitorId,
    required List<RelationshipMilestoneDefinition> milestones,
  }) : milestones = List<RelationshipMilestoneDefinition>.unmodifiable(
         milestones.toList()..sort(
           (
             RelationshipMilestoneDefinition a,
             RelationshipMilestoneDefinition b,
           ) => a.fulfilledCount.compareTo(b.fulfilledCount),
         ),
       );

  final String visitorId;
  final List<RelationshipMilestoneDefinition> milestones;

  factory RelationshipTrackDefinition.fromJson(Map<String, Object?> json) =>
      RelationshipTrackDefinition(
        visitorId: json['visitorId']! as String,
        milestones: (json['milestones']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(RelationshipMilestoneDefinition.fromJson)
            .toList(growable: false),
      );
}

class SceneObjectDefinition {
  const SceneObjectDefinition({
    required this.id,
    required this.nameKo,
    required this.legacyRecipeId,
  });

  final String id;
  final String nameKo;
  final String legacyRecipeId;

  factory SceneObjectDefinition.fromJson(Map<String, Object?> json) =>
      SceneObjectDefinition(
        id: json['id']! as String,
        nameKo: json['nameKo']! as String,
        legacyRecipeId: json['legacyRecipeId']! as String,
      );
}

class RequestFirstCatalog {
  RequestFirstCatalog({
    required this.balance,
    required List<SenseAxisDefinition> axes,
    required List<RequestTemplateDefinition> templates,
    required List<RelationshipTrackDefinition> relationshipTracks,
    required List<SceneObjectDefinition> sceneObjects,
  }) : axes = List<SenseAxisDefinition>.unmodifiable(axes),
       templates = List<RequestTemplateDefinition>.unmodifiable(templates),
       relationshipTracks = List<RelationshipTrackDefinition>.unmodifiable(
         relationshipTracks,
       ),
       sceneObjects = List<SceneObjectDefinition>.unmodifiable(sceneObjects);

  final RequestFirstBalance balance;
  final List<SenseAxisDefinition> axes;
  final List<RequestTemplateDefinition> templates;
  final List<RelationshipTrackDefinition> relationshipTracks;
  final List<SceneObjectDefinition> sceneObjects;

  Set<SenseAxis> get initiallyUnlockedAxes => axes
      .where((SenseAxisDefinition value) => value.initiallyUnlocked)
      .map((SenseAxisDefinition value) => value.axis)
      .toSet();

  RelationshipTrackDefinition trackForVisitor(String visitorId) =>
      relationshipTracks.firstWhere(
        (RelationshipTrackDefinition value) => value.visitorId == visitorId,
      );

  SceneObjectDefinition sceneObjectById(String id) =>
      sceneObjects.firstWhere((SceneObjectDefinition value) => value.id == id);

  static Future<RequestFirstCatalog> load(AssetBundle bundle) async {
    Map<String, Object?> document(String raw) =>
        jsonDecode(raw) as Map<String, Object?>;

    final balance = document(
      await bundle.loadString('assets/content/request_first_balance.json'),
    );
    final axes = document(
      await bundle.loadString('assets/content/sense_axes.json'),
    );
    final requests = document(
      await bundle.loadString('assets/content/request_templates.json'),
    );
    final relationships = document(
      await bundle.loadString('assets/content/relationship_tracks.json'),
    );
    final sceneObjects = document(
      await bundle.loadString('assets/content/scene_objects.json'),
    );

    return RequestFirstCatalog(
      balance: RequestFirstBalance.fromJson(balance),
      axes: (axes['axes']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(SenseAxisDefinition.fromJson)
          .toList(growable: false),
      templates: (requests['templates']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(RequestTemplateDefinition.fromJson)
          .toList(growable: false),
      relationshipTracks: (relationships['tracks']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(RelationshipTrackDefinition.fromJson)
          .toList(growable: false),
      sceneObjects: (sceneObjects['objects']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(SceneObjectDefinition.fromJson)
          .toList(growable: false),
    );
  }
}
