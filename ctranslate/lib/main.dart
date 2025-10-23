import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CTranslateApp());
}

class CTranslateApp extends StatefulWidget {
  const CTranslateApp({super.key});

  @override
  State<CTranslateApp> createState() => _CTranslateAppState();
}

class _CTranslateAppState extends State<CTranslateApp> {
  ThemeMode _themeMode = ThemeMode.system;
  LocalePair _currentPair = LocalePair('en', 'ha');

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final from = prefs.getString('from_lang') ?? 'en';
    final to = prefs.getString('to_lang') ?? 'ha';
    setState(() {
      _currentPair = LocalePair(from, to);
      _themeMode = (prefs.getBool('dark_mode') ?? false)
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('from_lang', _currentPair.from);
    await prefs.setString('to_lang', _currentPair.to);
    await prefs.setBool('dark_mode', _themeMode == ThemeMode.dark);
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
    _savePreferences();
  }

  void _switchLanguage(LocalePair pair) {
    setState(() => _currentPair = pair);
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CTranslate',
      themeMode: _themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: TranslatorScreen(
        pair: _currentPair,
        onSwitchLang: _switchLanguage,
        onToggleTheme: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class LocalePair {
  final String from;
  final String to;
  LocalePair(this.from, this.to);

  String get assetPath => 'assets/${from}_$to.json';
}

class TranslatorScreen extends StatefulWidget {
  final LocalePair pair;
  final bool isDark;
  final Function(LocalePair) onSwitchLang;
  final VoidCallback onToggleTheme;

  const TranslatorScreen({
    super.key,
    required this.pair,
    required this.isDark,
    required this.onSwitchLang,
    required this.onToggleTheme,
  });

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  Map<String, String> _dictionary = {};
  final _controller = TextEditingController();
  String _translated = '';

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    final data = await rootBundle.loadString(widget.pair.assetPath);
    final jsonMap = json.decode(data) as Map<String, dynamic>;
    setState(() {
      _dictionary = jsonMap.map((k, v) => MapEntry(k.toLowerCase(), v));
    });
  }

  void _translate() {
    final input = _controller.text.trim().toLowerCase();
    setState(() {
      _translated = _dictionary[input] ?? 'No translation found.';
    });
  }

  void _swapLanguages() {
    final newPair = LocalePair(widget.pair.to, widget.pair.from);
    widget.onSwitchLang(newPair);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Translate (${widget.pair.from} → ${widget.pair.to})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Swap languages',
            onPressed: _swapLanguages,
          ),
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter text',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _translate(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _translate,
              child: const Text('Translate'),
            ),
            const SizedBox(height: 24),
            SelectableText(
              _translated,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
