import 'dart:ui';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/user_avatar_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ZoomImageWidget extends StatelessWidget {
  final String? profilePhotoUrl;
  final Widget child;
  const ZoomImageWidget({
    super.key,
    required this.profilePhotoUrl,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showDialog(
        context: context,
        useSafeArea: false,
        builder: (context) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withValues(alpha: .2),
                alignment: Alignment.center,
                child: Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(),
                    image: DecorationImage(
                      filterQuality: FilterQuality.high,
                      image: CachedNetworkImageProvider(
                        profilePhotoUrl ?? '',
                        errorListener: (error) => const NoBgUser(),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

class ZoomImagesListWidget extends StatefulWidget {
  final List<String>? images;
  final int? imageIndex;
  final Widget child;
  const ZoomImagesListWidget({super.key, this.images, this.imageIndex, required this.child});

  @override
  State<ZoomImagesListWidget> createState() => _ZoomImagesListWidgetState();
}

class _ZoomImagesListWidgetState extends State<ZoomImagesListWidget> {
  PageController _pageController = PageController();
  final ValueNotifier<int> _currentPage = ValueNotifier(1);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _pageController = PageController(initialPage: widget.imageIndex ?? 0);
        _currentPage.value = (widget.imageIndex ?? 0) + 1;
        showDialog(
          context: context,
          useSafeArea: false,
          builder: (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Stack(
                  children: [
                    Container(
                      color: Colors.black.withValues(alpha: .2),
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: mediaQuery().size.width,
                        height: mediaQuery().size.height * .7,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (p) => setState(() => _currentPage.value = p + 1),
                          itemCount: widget.images?.length ?? 0,
                          itemBuilder: (context, index) {
                            final image = widget.images?[index];
                            return InteractiveViewer(
                              child: CachedNetworkImage(
                                imageUrl: image ?? '',
                                progressIndicatorBuilder: (c, v, d) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: d.progress,
                                      strokeWidth: 1.5,
                                    ),
                                  );
                                },
                                errorWidget: (c, v, d) => const Icon(Icons.error),
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 70,
                      width: mediaQuery().size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white)
                          ),
                          ValueListenableBuilder(
                            valueListenable: _currentPage,
                            builder: (context, value, _) => Text('$value de ${widget.images?.length ?? 0}', style: const TextStyle(color: Colors.white)),
                          ),
                          IconButton(
                            onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white)
                          )
                        ],
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
