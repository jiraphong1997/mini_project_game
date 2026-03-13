enum AgentAiProvider { ruleBased, ollama }

class AgentAiSettings {
  final AgentAiProvider provider;
  final String ollamaBaseUrl;
  final String ollamaModel;
  final int requestTimeoutSeconds;
  final double temperature;
  final bool fallbackToRuleBased;

  const AgentAiSettings({
    this.provider = AgentAiProvider.ruleBased,
    this.ollamaBaseUrl = 'http://127.0.0.1:11434',
    this.ollamaModel = 'llama3.2:3b',
    this.requestTimeoutSeconds = 20,
    this.temperature = 0.7,
    this.fallbackToRuleBased = true,
  });

  bool get usesOllama => provider == AgentAiProvider.ollama;

  String get providerLabel {
    switch (provider) {
      case AgentAiProvider.ollama:
        return 'Ollama';
      case AgentAiProvider.ruleBased:
        return 'Rule-based';
    }
  }

  String get summaryLabel {
    if (!usesOllama) {
      return 'ใช้ระบบตัดสินใจในเกม';
    }
    return '$providerLabel • $ollamaModel';
  }

  AgentAiSettings copyWith({
    AgentAiProvider? provider,
    String? ollamaBaseUrl,
    String? ollamaModel,
    int? requestTimeoutSeconds,
    double? temperature,
    bool? fallbackToRuleBased,
  }) {
    return AgentAiSettings(
      provider: provider ?? this.provider,
      ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      requestTimeoutSeconds:
          requestTimeoutSeconds ?? this.requestTimeoutSeconds,
      temperature: temperature ?? this.temperature,
      fallbackToRuleBased: fallbackToRuleBased ?? this.fallbackToRuleBased,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider.name,
      'ollamaBaseUrl': ollamaBaseUrl,
      'ollamaModel': ollamaModel,
      'requestTimeoutSeconds': requestTimeoutSeconds,
      'temperature': temperature,
      'fallbackToRuleBased': fallbackToRuleBased,
    };
  }

  factory AgentAiSettings.fromMap(Map<String, dynamic> map) {
    final providerName =
        map['provider'] as String? ?? AgentAiProvider.ruleBased.name;
    return AgentAiSettings(
      provider: AgentAiProvider.values.firstWhere(
        (value) => value.name == providerName,
        orElse: () => AgentAiProvider.ruleBased,
      ),
      ollamaBaseUrl:
          map['ollamaBaseUrl'] as String? ?? 'http://127.0.0.1:11434',
      ollamaModel: map['ollamaModel'] as String? ?? 'llama3.2:3b',
      requestTimeoutSeconds: map['requestTimeoutSeconds'] as int? ?? 20,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
      fallbackToRuleBased: map['fallbackToRuleBased'] as bool? ?? true,
    );
  }
}
