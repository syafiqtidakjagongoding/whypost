import 'package:flutter/material.dart';

class FediverseImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const FediverseImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,

        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            color: Colors.grey[200],
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
            ),
          );
        },

        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              size: 32,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }
}
