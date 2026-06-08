import 'package:flutter/material.dart';
import 'package:lottie_native/lottie_native.dart';

class IconLoadIndicator extends StatelessWidget {
  final double size;
  const IconLoadIndicator({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: LottieView.fromAsset(
          key: UniqueKey(),
          filePath: Theme.of(context).brightness == Brightness.dark
              ? 'assets/animations/iconLoadDark.json'
              : 'assets/animations/iconLoad.json',
        ),
      ),
    );
  }
}
