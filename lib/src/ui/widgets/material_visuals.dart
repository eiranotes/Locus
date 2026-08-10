import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/enums.dart';

Color weatherColor(WeatherMaterialKind kind) => switch (kind) {
  WeatherMaterialKind.clear => PixelPalette.amber,
  WeatherMaterialKind.rain => PixelPalette.blue,
  WeatherMaterialKind.cloudy => const Color(0xFF9EADB0),
  WeatherMaterialKind.windy => PixelPalette.mint,
  WeatherMaterialKind.cold => const Color(0xFFB8D8E8),
  WeatherMaterialKind.warm => const Color(0xFFD98855),
};

IconData weatherIcon(WeatherMaterialKind kind) => switch (kind) {
  WeatherMaterialKind.clear => Icons.wb_sunny_outlined,
  WeatherMaterialKind.rain => Icons.water_drop_outlined,
  WeatherMaterialKind.cloudy => Icons.cloud_outlined,
  WeatherMaterialKind.windy => Icons.air,
  WeatherMaterialKind.cold => Icons.ac_unit,
  WeatherMaterialKind.warm => Icons.local_fire_department_outlined,
};

IconData surroundingIcon(SurroundingMaterialKind kind) => switch (kind) {
  SurroundingMaterialKind.dense => Icons.hub_outlined,
  SurroundingMaterialKind.dynamic => Icons.multiple_stop,
  SurroundingMaterialKind.stable => Icons.anchor_outlined,
  SurroundingMaterialKind.sparse => Icons.open_in_full,
};

IconData objectIcon(ObjectKind kind) => switch (kind) {
  ObjectKind.alleyLamp => Icons.light_outlined,
  ObjectKind.signpost => Icons.signpost_outlined,
  ObjectKind.planter => Icons.local_florist_outlined,
  ObjectKind.bench => Icons.chair_outlined,
  ObjectKind.stairs => Icons.stairs_outlined,
  ObjectKind.tree => Icons.park_outlined,
  ObjectKind.busStop => Icons.directions_bus_outlined,
  ObjectKind.pond => Icons.water_outlined,
  ObjectKind.bridge => Icons.linear_scale,
  ObjectKind.tower => Icons.cell_tower_outlined,
  ObjectKind.mailbox => Icons.markunread_mailbox_outlined,
  ObjectKind.rainShelter => Icons.roofing_outlined,
  ObjectKind.stoneGate => Icons.door_sliding_outlined,
  ObjectKind.clockPost => Icons.access_time,
  ObjectKind.bookKiosk => Icons.menu_book_outlined,
  ObjectKind.laundryLine => Icons.dry_cleaning_outlined,
  ObjectKind.flowerArch => Icons.local_florist_outlined,
  ObjectKind.birdBath => Icons.water_drop_outlined,
  ObjectKind.greenhouse => Icons.house_siding_outlined,
  ObjectKind.fountain => Icons.water_outlined,
  ObjectKind.picnicTable => Icons.table_restaurant_outlined,
  ObjectKind.willow => Icons.park_outlined,
  ObjectKind.lanternString => Icons.lightbulb_outline,
  ObjectKind.windChime => Icons.notifications_none,
  ObjectKind.teaTable => Icons.emoji_food_beverage_outlined,
  ObjectKind.marketStall => Icons.storefront_outlined,
  ObjectKind.stoneLantern => Icons.emoji_objects_outlined,
  ObjectKind.observatory => Icons.settings_input_antenna,
};

class MaterialOrb extends StatelessWidget {
  const MaterialOrb.weather(this.weather, {super.key}) : surroundings = null;

  const MaterialOrb.surroundings(this.surroundings, {super.key})
    : weather = null;

  final WeatherMaterialKind? weather;
  final SurroundingMaterialKind? surroundings;

  @override
  Widget build(BuildContext context) {
    final color = weather == null
        ? PixelPalette.violet
        : weatherColor(weather!);
    final icon = weather == null
        ? surroundingIcon(surroundings!)
        : weatherIcon(weather!);
    final assetPath = weather == null
        ? GeneratedArtPaths.surroundingMaterial(surroundings!)
        : GeneratedArtPaths.weatherMaterial(weather!);
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.72)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          frameBuilder: (BuildContext context, Widget child, int? frame, _) =>
              frame == null ? Icon(icon, color: color, size: 27) : child,
          errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 27),
        ),
      ),
    );
  }
}
