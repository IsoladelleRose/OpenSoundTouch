class Preset {
  final int id;
  final String? itemName;
  final String? source;
  final String? location;
  final String? sourceAccount;
  final String? containerArt;

  Preset({
    required this.id,
    this.itemName,
    this.source,
    this.location,
    this.sourceAccount,
    this.containerArt,
  });

  bool get isEmpty => itemName == null || itemName!.isEmpty;
}
