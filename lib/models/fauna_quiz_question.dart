class FaunaQuizQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String speciesId;
  final String category;
  final String region;

  const FaunaQuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.speciesId,
    required this.category,
    required this.region,
  });

  // Backward compatibility getters for legacy code
  String get question => prompt;
  int get correct => correctIndex;

  /// Map compatibility accessor for existing test expectations
  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'prompt':
      case 'question':
        return prompt;
      case 'options':
        return options;
      case 'correctIndex':
      case 'correct':
        return correctIndex;
      case 'explanation':
        return explanation;
      case 'speciesId':
        return speciesId;
      case 'category':
        return category;
      case 'region':
        return region;
      default:
        return null;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'prompt': prompt,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'speciesId': speciesId,
        'category': category,
        'region': region,
      };

  factory FaunaQuizQuestion.fromMap(Map<String, dynamic> map) {
    return FaunaQuizQuestion(
      id: map['id'] as String,
      prompt: (map['prompt'] ?? map['question']) as String,
      options: List<String>.from(map['options'] as List),
      correctIndex: (map['correctIndex'] ?? map['correct']) as int,
      explanation: map['explanation'] as String,
      speciesId: map['speciesId'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      region: map['region'] as String? ?? 'Jammu & Kashmir',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaunaQuizQuestion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FaunaQuizQuestion(id: $id, prompt: $prompt, speciesId: $speciesId)';
}
