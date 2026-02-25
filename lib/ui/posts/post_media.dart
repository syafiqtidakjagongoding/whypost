import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whypost/routing/routes.dart';
import 'package:whypost/ui/utils/fediverse_image.dart';
import 'package:whypost/ui/utils/fediverse_video.dart';


class PostMedia extends StatefulWidget {
  final List<dynamic> media;
  final bool sensitive;

  const PostMedia({super.key, required this.media, required this.sensitive});

  @override
  State<PostMedia> createState() => _PostMediaState();
}

class _PostMediaState extends State<PostMedia> {
  int current = 0;
  bool revealed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) return const SizedBox.shrink();

    final media = widget.media;

    return Column(
      children: [
        // --- SENSITIVE OVERLAY ---
        GestureDetector(
          onTap: () {
            if (widget.sensitive && !revealed) {
              setState(() => revealed = !revealed);
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: media.length,
                  onPageChanged: (i) => setState(() => current = i),
                  itemBuilder: (context, i) {
                    final m = media[i];
                    final type = m['type'];
                    final url = m['url'];
                    final preview = m['preview_url'];

                    Widget child;

                    if (type == "video" || type == "gifv") {
                      child = child = GestureDetector(
                        onTap: () {
                          context.push(Routes.viewVideo, extra: url);
                        },
                        child: FediverseVideo(url: url),
                      );
                    } else {
                      child = child = GestureDetector(
                        onTap: () {
                          context.push(Routes.viewImages, extra: url);
                        },
                        child: FediverseImage(
                          url: preview ?? url,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      );
                    }

                    return ClipRRect(
                      child: widget.sensitive && !revealed
                          ? Stack(
                              children: [
                                Positioned.fill(
                                  child: ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      Colors.transparent,
                                      BlendMode.srcATop,
                                    ),
                                    child: ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                        sigmaX: 18,
                                        sigmaY: 18,
                                      ),
                                      child: child,
                                    ),
                                  ),
                                ),
                                const Center(
                                  child: Icon(
                                    Icons.visibility_off,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              ],
                            )
                          : child,
                    );
                  },
                ),
              ),

              // Tap to reveal text
              if (widget.sensitive && !revealed)
                Positioned(
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: const Text(
                      "Sensitive content – tap to reveal",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // --- DOT INDICATOR ---
        if (media.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(media.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: current == i ? 12 : 8,
                  height: current == i ? 12 : 8,
                  decoration: BoxDecoration(
                    color: current == i
                        ? Colors.blueAccent
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
