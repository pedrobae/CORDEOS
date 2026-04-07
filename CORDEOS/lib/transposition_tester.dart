import 'package:cordeos/helpers/chords/chords.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/transposition_provider.dart';
import 'package:cordeos/widgets/ciphers/transposer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const TranspositionTestApp());
}

class TranspositionTestApp extends StatelessWidget {
  const TranspositionTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TranspositionProvider()..setOriginalKey('C', -2),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', ''), Locale('pt', 'BR')],
        home: const TranspositionSandboxScreen(),
      ),
    );
  }
}

class TranspositionSandboxScreen extends StatefulWidget {
  const TranspositionSandboxScreen({super.key});

  @override
  State<TranspositionSandboxScreen> createState() =>
      _TranspositionSandboxScreenState();
}

class _TranspositionSandboxScreenState
    extends State<TranspositionSandboxScreen> {
  final List<String> _allRoots = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  final List<String> _sharpRoots = ['C#', 'D#', 'F#', 'G#', 'A#'];
  final List<String> _flatRoots = ['Db', 'Eb', 'Gb', 'Ab', 'Bb'];

  final Map<String, List<String>> _sampleChordGroups = {
    'Modifiers': [
      'Cadd9',
      'Csus2',
      'Csus4',
      'Caug',
      'Cdim',
      'A#dim',
    ],
    'Slash bass chords': [
      'G/B',
      'Eb/G',
      'D/F#',
      'Bb/D',
      'F#m/C#',
      'Abmaj7/C',
      'E7/G#',
      'Gm7/Bb',
      'Bdim/F',
    ],
  };

  Widget _buildChordRow(String original, String transposed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(original, style: const TextStyle(fontSize: 15))),
          const Text('->'),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              transposed,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChordGroupCard(
    BuildContext context,
    String title,
    List<String> chords,
    TranspositionProvider tp,
  ) {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        initiallyExpanded: title == 'Modifiers',
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 6),
          ...chords.map((chord) => _buildChordRow(chord, tp.transposeChord(chord))),
        ],
      ),
    );
  }

  Widget _buildAllRootsCard(TranspositionProvider tp) {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        initiallyExpanded: true,
        title: const Text(
          'All roots',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 6),
          ..._allRoots.map((root) => _buildChordRow(root, tp.transposeChord(root))),
        ],
      ),
    );
  }

  Widget _buildSharpFlatColumnsCard(TranspositionProvider tp) {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        initiallyExpanded: true,
        title: const Text(
          'Sharps and flats',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Sharp roots',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Flat roots',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...List.generate(_sharpRoots.length, (index) {
            final sharp = _sharpRoots[index];
            final flat = _flatRoots[index];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text('$sharp -> ${tp.transposeChord(sharp)}'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('$flat -> ${tp.transposeChord(flat)}'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKeySetupCard(
    BuildContext context,
    TranspositionProvider tp,
    String originalKey,
    String activeKey,
  ) {
    final hasTransposition = tp.transposedKey != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key setup',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: originalKey,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Original key',
                      isDense: true,
                    ),
                    items: ChordHelper.keyList
                        .map(
                          (k) => DropdownMenuItem<String>(
                            value: k,
                            child: Text(k),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        tp.setOriginalKey(value, -2);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: hasTransposition
                      ? () => tp.setTransposedKey(null)
                      : null,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Center(child: Transposer()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(label: Text('Original: $originalKey')),
                Chip(
                  label: Text(
                    hasTransposition ? 'Current: $activeKey' : 'Current: Original',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TranspositionProvider>(
      builder: (context, tp, child) {
        final originalKey = tp.originalKey.isEmpty ? 'C' : tp.originalKey;
        final activeKey = tp.transposedKey ?? originalKey;

        return Scaffold(
          appBar: AppBar(title: const Text('Transposition Sandbox')),
          body: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              _buildKeySetupCard(context, tp, originalKey, activeKey),
              const SizedBox(height: 2),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Text(
                  'Chord checks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildAllRootsCard(tp),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSharpFlatColumnsCard(tp),
              ),
              ..._sampleChordGroups.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildChordGroupCard(context, entry.key, entry.value, tp),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
