import 'package:flutter/material.dart';

import '../models/agent_ai_settings.dart';
import '../services/agent_ai_service.dart';

class AiSettingsScreen extends StatefulWidget {
  final AgentAiSettings initialSettings;
  final ValueChanged<AgentAiSettings> onSaved;

  const AiSettingsScreen({
    super.key,
    required this.initialSettings,
    required this.onSaved,
  });

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  late AgentAiProvider _provider;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  late final TextEditingController _timeoutController;
  double _temperature = 0.7;
  bool _fallbackToRuleBased = true;
  bool _isTesting = false;
  String? _testMessage;
  List<String> _availableModels = const [];

  @override
  void initState() {
    super.initState();
    _provider = widget.initialSettings.provider;
    _baseUrlController = TextEditingController(
      text: widget.initialSettings.ollamaBaseUrl,
    );
    _modelController = TextEditingController(
      text: widget.initialSettings.ollamaModel,
    );
    _timeoutController = TextEditingController(
      text: widget.initialSettings.requestTimeoutSeconds.toString(),
    );
    _temperature = widget.initialSettings.temperature;
    _fallbackToRuleBased = widget.initialSettings.fallbackToRuleBased;
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  AgentAiSettings get _draftSettings {
    final timeout = int.tryParse(_timeoutController.text.trim()) ?? 20;
    return AgentAiSettings(
      provider: _provider,
      ollamaBaseUrl: _baseUrlController.text.trim(),
      ollamaModel: _modelController.text.trim(),
      requestTimeoutSeconds: timeout.clamp(5, 120),
      temperature: _temperature,
      fallbackToRuleBased: _fallbackToRuleBased,
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testMessage = null;
      _availableModels = const [];
    });

    final result = await AgentAiService.testConnection(_draftSettings);
    if (!mounted) {
      return;
    }

    setState(() {
      _isTesting = false;
      _testMessage = result.message;
      _availableModels = result.availableModels;
    });
  }

  void _save() {
    widget.onSaved(_draftSettings);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final usingOllama = _provider == AgentAiProvider.ollama;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่า AI'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'โหมดการตัดสินใจ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AgentAiProvider>(
                    initialValue: _provider,
                    decoration: const InputDecoration(
                      labelText: 'ผู้ให้บริการ AI',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AgentAiProvider.ruleBased,
                        child: Text('ระบบในเกม (Rule-based)'),
                      ),
                      DropdownMenuItem(
                        value: AgentAiProvider.ollama,
                        child: Text('Ollama ภายในเครื่อง'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _provider = value;
                        _testMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    usingOllama
                        ? 'เมื่อกดขอคำแนะนำระหว่างเหตุการณ์ ระบบจะเรียก Ollama ก่อน และ fallback กลับมาใช้ระบบในเกมถ้าตั้งค่าไว้'
                        : 'ตอนนี้เกมจะใช้ logic ตัดสินใจในตัวทั้งหมด เหมาะกับเล่นทดสอบแบบไม่ต้องพึ่งโมเดล',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ollama',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _baseUrlController,
                    enabled: usingOllama,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'http://127.0.0.1:11434',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _modelController,
                    enabled: usingOllama,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      hintText: 'llama3.2:3b',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _timeoutController,
                    enabled: usingOllama,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Timeout (วินาที)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Temperature: ${_temperature.toStringAsFixed(2)}'),
                  Slider(
                    value: _temperature,
                    min: 0.1,
                    max: 1.2,
                    divisions: 11,
                    label: _temperature.toStringAsFixed(2),
                    onChanged: usingOllama
                        ? (value) => setState(() => _temperature = value)
                        : null,
                  ),
                  SwitchListTile(
                    value: _fallbackToRuleBased,
                    onChanged: usingOllama
                        ? (value) =>
                              setState(() => _fallbackToRuleBased = value)
                        : null,
                    title: const Text(
                      'Fallback กลับมาใช้ระบบในเกมเมื่อ Ollama ล้ม',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: usingOllama && !_isTesting
                            ? _testConnection
                            : null,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.network_ping),
                        label: const Text('ทดสอบการเชื่อมต่อ'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('บันทึก'),
                      ),
                    ],
                  ),
                  if (_testMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_testMessage!),
                  ],
                  if (_availableModels.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'โมเดลที่พบ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableModels
                          .map((model) => Chip(label: Text(model)))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
