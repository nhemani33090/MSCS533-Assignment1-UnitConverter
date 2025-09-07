import 'package:flutter/material.dart';

void main() {
  runApp(const UnitConverterApp());
}

/// A simple, well-structured unit converter covering
/// metric & imperial for length, weight, and temperature.
class UnitConverterApp extends StatelessWidget {
  const UnitConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unit Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ConverterScreen(),
    );
  }
}

enum Category { length, weight, temperature }

/// Supported units per category. Includes both metric and imperial.
const Map<Category, List<String>> kUnitsByCategory = {
  Category.length: ['meters', 'kilometers', 'feet', 'miles'],
  Category.weight: ['grams', 'kilograms', 'ounces', 'pounds'],
  Category.temperature: ['celsius', 'fahrenheit'],
};

/// Linear conversion factors are provided relative to a base unit:
/// - Length base: meters
/// - Weight base: grams
///
/// Temperature uses custom formulas (C/F), so no factors here.
const Map<String, double> kToBaseFactor = {
  // Length to meters
  'meters': 1.0,
  'kilometers': 1000.0,
  'feet': 0.3048,
  'miles': 1609.344,

  // Weight to grams
  'grams': 1.0,
  'kilograms': 1000.0,
  'ounces': 28.349523125,
  'pounds': 453.59237,
};

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  Category _category = Category.length;
  late List<String> _units = kUnitsByCategory[_category]!;
  String _fromUnit = 'meters';
  String _toUnit = 'kilometers';
  final TextEditingController _inputCtrl = TextEditingController();
  String? _resultText;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _applyCategoryDefaults();
  }

  void _applyCategoryDefaults() {
    _units = kUnitsByCategory[_category]!;
    // Choose sensible defaults per category
    switch (_category) {
      case Category.length:
        _fromUnit = 'miles';
        _toUnit = 'kilometers';
        break;
      case Category.weight:
        _fromUnit = 'kilograms';
        _toUnit = 'pounds';
        break;
      case Category.temperature:
        _fromUnit = 'celsius';
        _toUnit = 'fahrenheit';
        break;
    }
    _resultText = null;
    _errorText = null;
    _inputCtrl.clear();
    setState(() {});
  }

  bool get _isTemperature => _category == Category.temperature;

  void _convert() {
    setState(() {
      _errorText = null;
      _resultText = null;
    });

    final raw = _inputCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorText = 'Please enter a value.');
      return;
    }

    final value = double.tryParse(raw);
    if (value == null) {
      setState(() => _errorText = 'Invalid number.');
      return;
    }

    final double converted;
    try {
      if (_isTemperature) {
        converted = _convertTemperature(value, _fromUnit, _toUnit);
      } else {
        converted = _convertLinear(value, _fromUnit, _toUnit);
      }
    } catch (e) {
      setState(() => _errorText = 'Conversion error: $e');
      return;
    }

    setState(() {
      _resultText = '$value $_fromUnit = ${_format(converted)} $_toUnit';
    });
  }

  /// Linear conversions use a base unit strategy:
  /// 1) Convert from source unit to base (meters or grams)
  /// 2) Convert base to target unit
  double _convertLinear(double value, String from, String to) {
    // Disallow mixing units across categories (shouldn't happen via UI).
    if (!_units.contains(from) || !_units.contains(to)) {
      throw StateError('Mismatched units for the selected category.');
    }
    final toBase = kToBaseFactor[from]!;
    final fromBase = kToBaseFactor[to]!;
    final inBase = value * toBase;
    return inBase / fromBase;
  }

  /// Temperature conversions (C <-> F) use explicit formulas.
  double _convertTemperature(double value, String from, String to) {
    if (from == to) return value;
    if (from == 'celsius' && to == 'fahrenheit') {
      return value * 9 / 5 + 32;
    }
    if (from == 'fahrenheit' && to == 'celsius') {
      return (value - 32) * 5 / 9;
    }
    throw UnsupportedError('Unsupported temperature units.');
  }

  String _format(double v) {
    // Reasonable formatting for display
    final s = v.toStringAsFixed(6);
    // Trim trailing zeros
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Converter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category selector
                Row(
                  children: [
                    const Text(
                      'Category:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<Category>(
                      value: _category,
                      items: Category.values.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            switch (c) {
                              Category.length => 'Length (Metric/Imperial)',
                              Category.weight => 'Weight (Metric/Imperial)',
                              Category.temperature => 'Temperature',
                            },
                          ),
                        );
                      }).toList(),
                      onChanged: (c) {
                        if (c == null) return;
                        _category = c;
                        _applyCategoryDefaults();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Input field
                TextField(
                  controller: _inputCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Value',
                    hintText: 'Enter a number',
                    border: const OutlineInputBorder(),
                    errorText: _errorText,
                  ),
                  onSubmitted: (_) => _convert(),
                ),
                const SizedBox(height: 16),

                // From / To unit dropdowns
                Row(
                  children: [
                    Expanded(
                      child: _UnitSelect(
                        label: 'From',
                        value: _fromUnit,
                        units: _units,
                        onChanged: (u) => setState(() => _fromUnit = u),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      tooltip: 'Swap units',
                      onPressed: () {
                        setState(() {
                          final tmp = _fromUnit;
                          _fromUnit = _toUnit;
                          _toUnit = tmp;
                        });
                      },
                      icon: const Icon(Icons.swap_horiz),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UnitSelect(
                        label: 'To',
                        value: _toUnit,
                        units: _units,
                        onChanged: (u) => setState(() => _toUnit = u),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Convert button
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _convert,
                    child: const Text('Convert'),
                  ),
                ),
                const SizedBox(height: 20),

                // Result
                if (_resultText != null)
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _resultText!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                const Spacer(),

                // Tiny help text
                Text(
                  'Tip: Choose category, enter a value, pick units (metric or imperial), then Convert.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitSelect extends StatelessWidget {
  const _UnitSelect({
    required this.label,
    required this.value,
    required this.units,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> units;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: units
              .map((u) => DropdownMenuItem(value: u, child: Text(_label(u))))
              .toList(),
          onChanged: (u) {
            if (u != null) onChanged(u);
          },
        ),
      ),
    );
  }

  String _label(String unit) {
    // Capitalize for display
    return '${unit[0].toUpperCase()}${unit.substring(1)}';
  }
}
