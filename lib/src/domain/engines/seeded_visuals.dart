int stableSeed(Iterable<Object?> parts) {
  var hash = 0x811c9dc5;
  for (final part in parts) {
    final text = part?.toString() ?? 'null';
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    hash ^= 0xff;
  }
  return hash & 0x7fffffff;
}
