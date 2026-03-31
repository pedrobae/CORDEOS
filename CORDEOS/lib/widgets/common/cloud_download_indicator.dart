import 'package:flutter/material.dart';

class CloudDownloadIndicator extends StatelessWidget {
  final bool isUpload;

  const CloudDownloadIndicator({super.key, this.isUpload = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      height: 35,
      width: 35,
      child: Stack(
        children: [
          SizedBox(
            height: 25,
            width: 25,
            child: CircularProgressIndicator(
              color: colorScheme.onSurface,
              strokeWidth: 5,
            ),
          ),
          Positioned(
            bottom: 2,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceTint,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                isUpload ? Icons.cloud_upload : Icons.cloud_download,
                size: 25,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
