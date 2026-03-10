import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/widgets/ciphers/editor/metadata.dart/select_key_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Transposer extends StatelessWidget {
  const Transposer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TranspositionProvider>(
      builder: (context, tp, child) {
        return SizedBox(
          width: 125,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => tp.transposeDown(),
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return SelectKeySheet(needsSave: false);
                    },
                  );
                },
                child: Text(
                  tp.transposedKey ?? tp.originalKey,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => tp.transposeUp(),
              ),
            ],
          ),
        );
      },
    );
  }
}
