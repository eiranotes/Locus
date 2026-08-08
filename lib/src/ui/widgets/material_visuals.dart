import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
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
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.72)),
      ),
      child: Icon(icon, color: color, size: 27),
    );
  }
}
