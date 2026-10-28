
import 'package:flutter/material.dart';

class RoomPhotoSlider extends StatefulWidget {
  final List<String> photoUrls;
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
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.photoUrls;

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
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: urls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return Image.network(
                urls[index],
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;

                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image_outlined, size: 42),
                  );
                },
              );
            },
          ),

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
                  '${_currentIndex + 1} / ${urls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          if (urls.length > 1) ...[
            Positioned(
              left: 4,
              child: IconButton(
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
