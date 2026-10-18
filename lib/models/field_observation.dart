import 'dart:convert';
import 'dart:typed_data';

class FieldObservation {
  final String id;
  final String speciesName;
  final String location;
  final String notes;
  final String? photoBase64;
  final DateTime observedAt;

  const FieldObservation({
    required this.id,
    required this.speciesName,
    required this.location,
    required this.notes,
    required this.photoBase64,
    required this.observedAt,
  });

  factory FieldObservation.fromJson(Map<String, dynamic> json) {
    return FieldObservation(
      id: json['id'] as String,
      speciesName: json['speciesName'] as String,
      location: json['location'] as String,
      notes: json['notes'] as String,
      photoBase64: json['photoBase64'] as String?,
      observedAt: DateTime.parse(json['observedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'speciesName': speciesName,
    'location': location,
    'notes': notes,
    'photoBase64': photoBase64,
    'observedAt': observedAt.toIso8601String(),
  };

  Uint8List? get photoBytes =>
      photoBase64 == null ? null : base64Decode(photoBase64!);
}
