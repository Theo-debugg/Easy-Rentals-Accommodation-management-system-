import 'package:flutter/material.dart';

/// A horizontally swipeable image carousel for displaying a room's photos.
///
/// Shows a full-width [PageView] of network images with:
/// - a loading spinner while each image downloads,
/// - a broken-image icon if an image fails to load,
/// - a "current / total" counter pill,
/// - previous/next arrow buttons (only when there is more than one photo).
///
/// Renders a placeholder icon when [photoUrls] is empty.
class RoomPhotoSlider extends StatefulWidget {
  /// The image URLs to display, in order.
  final List<String> photoUrls;

  /// Fixed height of the slider. Defaults to 220 logical pixels.
  final double height;

  const RoomPhotoSlider({
    super.key,
    required this.photoUrls,
    this.height = 220,
  });

  @override
  State<RoomPhotoSlider> createState() =>
      _RoomPhotoSliderState();
}

class _RoomPhotoSliderState extends State<RoomPhotoSlider> {
  // Drives the PageView and powers the prev/next arrow buttons.
  final PageController _controller = PageController();

  // Index of the currently visible page; shown in the counter pill.
  int _currentIndex = 0;

  @override
  void dispose() {
    // Always dispose the controller to avoid leaking its listeners/ticker.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.photoUrls;

    // Empty state: show a neutral placeholder at the configured height so
    // surrounding layouts don't collapse or jump.
    if (urls.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 42),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        // Anchor the counter pill and arrow buttons to the bottom edge.
        alignment: Alignment.bottomCenter,
        children: [
          // Swipeable image pages.
          PageView.builder(
            controller: _controller,
            itemCount: urls.length,
            onPageChanged: (index) {
              // Keep the counter and arrow enabled states in sync with the
              // visible page.
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return Image.network(
                urls[index],
                width: double.infinity,
                // Cover keeps aspect ratio while filling the full width.
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  // When progress is null the image has finished loading.
                  if (progress == null) return child;

                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  // Fallback for network errors or invalid URLs.
                  return const Center(
                    child: Icon(Icons.broken_image_outlined, size: 42),
                  );
                },
              );
            },
          ),

          // "Current / total" counter pill — hidden for single-image sliders.
          if (urls.length > 1)
            Positioned(
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  // _currentIndex is 0-based; display it 1-based.
                  '${_currentIndex + 1} / ${urls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // Left/right navigation arrows, shown only when there's more than
          // one image. Each is disabled (`onPressed: null`) at its boundary.
          if (urls.length > 1) ...[
            Positioned(
              left: 4,
              child: IconButton(
                // Disabled on the first page.
                onPressed: _currentIndex > 0
                    ? () => _controller.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        )
                    : null,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black38,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            Positioned(
              right: 4,
              child: IconButton(
                // Disabled on the last page.
                onPressed: _currentIndex < urls.length - 1
                    ? () => _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        )
                    : null,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black38,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}