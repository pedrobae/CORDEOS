import 'package:cordeos/providers/transposition_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/widgets/ciphers/editor/metadata.dart/select_key_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Transposer extends StatelessWidget {
  const Transposer({super.key});

  @override
  Widget build(BuildContext context) {
    final trans = context.read<TranspositionProvider>();
    final localVer = context.read<LocalVersionProvider>();

    return Selector<
      TranspositionProvider,
      ({String? transposed, String original, int versionID})
    >(
      selector: (context, tp) => (
        transposed: tp.transposedKey,
        original: tp.originalKey,
        versionID: tp.versionID,
      ),
      builder: (context, s, child) {
        return SizedBox(
          width: 125,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => trans.transposeDown(),
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return SelectKeySheet(
                        initialKey: s.transposed,
                        originalKey: s.original,
                        onKeySelected: (key) {
                          trans.setTransposedKey(key);
                        },
                        onSave: (key) async {
                          if (s.versionID == -2) return; // CLOUD / TESTING CASE
                          localVer.cacheUpdates(
                            s.versionID,
                            transposedKey: key,
                          );
                          await localVer.saveVersion(versionID: s.versionID);
                          trans.setTransposedKey(key);
                          trans.setOriginalKey(key, s.versionID);
                        },
                      );
                    },
                  );
                },
                child: Text(
                  s.transposed ?? s.original,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => trans.transposeUp(),
              ),
            ],
          ),
        );
      },
    );
  }
}
