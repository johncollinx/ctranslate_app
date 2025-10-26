import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'translation_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CTranslate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8F9FD),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
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

  final List<String> _pairs = ['ha_en', 'en_ha', 'yo_en', 'en_yo', 'ig_en', 'en_ig'];

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
        body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CTranslate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: "Swap Language Direction",
            onPressed: () {
              setState(() {
                final parts = _selectedPair.split('_');
                _selectedPair = '${parts[1]}_${parts[0]}';
              });
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Card(
                elevation: 4,
                shadowColor: Colors.indigo.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedPair,
                        decoration: InputDecoration(
                          labelText: "Language Pair",
                          labelStyle: TextStyle(color: Colors.indigo.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _pairs.map((pair) {
                          return DropdownMenuItem(
                            value: pair,
                            child: Text(pair.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedPair = val!),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _inputCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Enter text to translate...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _translate,
                        label: const Text('Translate'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (_translatedText.isNotEmpty)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _translatedText,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
