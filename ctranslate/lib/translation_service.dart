import 'package:flutter/material.dart';
import 'translation_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CTranslate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const TranslatorPage(),
    );
  }
}

class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  final TranslationService _service = TranslationService();
  final TextEditingController _inputCtrl = TextEditingController();
  bool _isLoading = true;
  String _selectedPair = 'ha_en';
  String _translatedText = '';

  final List<String> _pairs = [
    'ha_en',
    'en_ha',
    'yo_en',
    'en_yo',
    'ig_en',
    'en_ig'
  ];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    await _service.loadAll();
    setState(() => _isLoading = false);
  }

  void _translate() {
    final query = _inputCtrl.text.trim();
    if (query.isEmpty) return;

    final exact = _service.lookup(_selectedPair, query);
    final fuzzy = _service.fuzzyLookup(_selectedPair, query);

    setState(() {
      if (exact != null) {
        _translatedText = exact;
      } else if (fuzzy != null) {
        _translatedText = '${fuzzy.value} (closest: ${fuzzy.key})';
      } else {
        _translatedText = 'No translation found';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CTranslate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              // Flip direction (e.g., ha_en <-> en_ha)
              setState(() {
                if (_selectedPair.contains('_')) {
                  final parts = _selectedPair.split('_');
                  _selectedPair = '${parts[1]}_${parts[0]}';
                }
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedPair,
              isExpanded: true,
              items: _pairs.map((pair) {
                return DropdownMenuItem(
                  value: pair,
                  child: Text(pair.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedPair = val!),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _inputCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter text',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _translate,
              icon: const Icon(Icons.translate),
              label: const Text('Translate'),
            ),
            const SizedBox(height: 30),
            Text(
              _translatedText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
