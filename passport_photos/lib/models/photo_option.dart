enum PhotoType { passport, stamp, custom }

class PhotoOption {
  final PhotoType type;
  final double? width;
  final double? height;
  final int numberOfPhotos; // ✅ added this

  PhotoOption({
    required this.type,
    this.width,
    this.height,
    required this.numberOfPhotos, // ✅ required now
  });

  factory PhotoOption.passport({required int numberOfPhotos}) {
    return PhotoOption(
      type: PhotoType.passport,
      numberOfPhotos: numberOfPhotos,
    );
  }

  factory PhotoOption.stamp({required int numberOfPhotos}) {
    return PhotoOption(
      type: PhotoType.stamp,
      numberOfPhotos: numberOfPhotos,
    );
  }

  factory PhotoOption.custom({
    double? width,
    double? height,
    required int numberOfPhotos,
  }) {
    return PhotoOption(
      type: PhotoType.custom,
      width: width,
      height: height,
      numberOfPhotos: numberOfPhotos,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PhotoOption &&
              runtimeType == other.runtimeType &&
              type == other.type &&
              width == other.width &&
              height == other.height &&
              numberOfPhotos == other.numberOfPhotos; // ✅ compare numberOfPhotos too

  @override
  int get hashCode =>
      type.hashCode ^
      width.hashCode ^
      height.hashCode ^
      numberOfPhotos.hashCode; // ✅ included

  @override
  String toString() {
    switch (type) {
      case PhotoType.passport:
        return 'Passport Photo ($numberOfPhotos photos)';
      case PhotoType.stamp:
        return 'Stamp Photo ($numberOfPhotos photos)';
      case PhotoType.custom:
        return 'Custom Photo (${width ?? 'N/A'} x ${height ?? 'N/A'}, $numberOfPhotos photos)';
    }
  }
}
