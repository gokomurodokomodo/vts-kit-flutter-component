import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vts_component/components/carousel/styles.dart';

class VTSCarousel extends StatefulWidget {
  const VTSCarousel({
    Key? key,
    required this.items,
    this.aspectRatio = 16 / 9,
    this.viewportFraction = 0.8,
    this.height,

    this.enlargeMainPage = false,
    this.scrollDirection = Axis.horizontal,

    this.pagination = true,
    this.indicatorSize,
    this.activeIndicator,
    this.inactiveIndicator,
    this.indicatorMargin,
    this.indicatorBuilder,
    
    this.initialPage = 0,
    this.enableInfiniteScroll = true,
    this.reverse = false,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.autoPlayAnimationDuration = const Duration(milliseconds: 800),
    this.autoPlayCurve = Curves.fastOutSlowIn,
    this.pauseAutoPlayOnTouch,

    this.scrollPhysics,

    this.onPageChanged,
  }) : assert(viewportFraction >= 0 && viewportFraction <= 1.0),
       super(key: key);

  /// The widgets to be shown as sliders.
  final List<Widget> items;

  /// Aspect ratio is used if no height have been declared. Defaults to 16:9 aspect ratio.
  final double aspectRatio;

  /// The fraction of the viewport that each page should occupy. Defaults to 0.8, which means each page fills 80% of the slide.
  final double viewportFraction;

  /// Set slide widget height and overrides any existing [aspectRatio].
  final double? height;

  /// Determines if current page should be larger then the side images,
  /// creating a feeling of depth in the carousel. Defaults to false.
  /// works only if viewportFraction set to 1.0.
  final bool enlargeMainPage;

  /// The axis along which the page view scrolls. Defaults to [Axis.horizontal].
  final Axis scrollDirection;

  /// The [VTSCarousel] shows pagination on state true.
  final bool? pagination;

  /// The pagination dots size can be defined using [double].
  final double? indicatorSize;

  /// The slider pagination's active color.
  final Color? activeIndicator;

  /// The slider pagination's passive color.
  final Color? inactiveIndicator;

  // Margin between indicator
  final EdgeInsetsGeometry? indicatorMargin;

  // Customize indicator rendering
  final Widget Function(bool active)? indicatorBuilder;

  /// The initial page to show when first creating the [VTSCarousel]. Defaults to 0.
  final int initialPage;

  /// Determines if slides should loop infinitely or be limited to item length. Defaults to true, i.e. infinite loop.
  final bool enableInfiniteScroll;

  /// Reverse the order of items if set to true. Defaults to false.
  final bool reverse;

  /// Enables auto play, sliding one page at a time. Use [autoPlayInterval] to determent the frequency of slides. Defaults to false.
  final bool autoPlay;

  /// Sets Duration to determent the frequency of slides when [autoPlay] is set to true. Defaults to 4 seconds.
  final Duration autoPlayInterval;

  /// The animation duration bestuckValue two transitioning pages while in auto playback. Defaults to 800 ms.
  final Duration autoPlayAnimationDuration;

  /// Determines the animation curve physics. Defaults to [Curves.fastOutSlowIn].
  final Curve autoPlayCurve;

  /// Sets a timer on touch detected that pause the auto play with the given [Duration]. Touch Detection is only active if [autoPlay] is true.
  final Duration? pauseAutoPlayOnTouch;

  /// How the carousel should respond to user input.
  ///
  /// For example, determines how the items continues to animate after the
  /// user stops dragging the page view.
  ///
  /// The physics are modified to snap to page boundaries using
  /// [PageScrollPhysics] prior to being used.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? scrollPhysics;

  /// Called whenever the page in the center of the viewport changes.
  final Function(int index)? onPageChanged;

  List<T> map<T>(List list, Function handler) {
    List<T> result;
    result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }
    return result;
  }

  @override
  _VTSCarouselState createState() => _VTSCarouselState();
}

class _VTSCarouselState extends State<VTSCarousel> with TickerProviderStateMixin {
  Timer? timer;

  /// Size of cell
  double size = 0;

  /// Width of cells container
  double width = 0;

  /// [pageController] is created using the properties passed to the constructor
  /// and can be used to control the [PageView] it is passed to.
  late PageController pageController;

  /// The actual index of the [PageView].
  int realPage = 10000;
  int currentSlide = 0;

  @override
  void initState() {
    super.initState();

    currentSlide = widget.initialPage < widget.items.length ? widget.initialPage : 0;
    realPage = _getRealIndex(currentSlide, realPage, widget.items.length);

    pageController = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: realPage,
    );
    timer = getPlayTimer();
  }

  Timer getPlayTimer() => Timer.periodic(widget.autoPlayInterval, (_) {
        if (widget.autoPlay && widget.items.length > 1) {
          pageController.nextPage(
              duration: widget.autoPlayAnimationDuration,
              curve: widget.autoPlayCurve);
        }
      });

  void pauseOnTouch() {
    timer?.cancel();
    timer = Timer(widget.pauseAutoPlayOnTouch!, () {
      timer = getPlayTimer();
    });
  }

  Widget getPageWrapper(Widget child) {
    if (widget.height != null) {
      final Widget wrapper = Container(height: widget.height, child: child);
      return widget.autoPlay && widget.pauseAutoPlayOnTouch != null
          ? addGestureDetection(wrapper)
          : wrapper;
    } else {
      final Widget wrapper =
          AspectRatio(aspectRatio: widget.aspectRatio, child: child);
      return widget.autoPlay && widget.pauseAutoPlayOnTouch != null
          ? addGestureDetection(wrapper)
          : wrapper;
    }
  }

  Widget addGestureDetection(Widget child) =>
      GestureDetector(onPanDown: (_) => pauseOnTouch(), child: child);

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void onPageSlide(int index) {
    setState(() => currentSlide = index);
  }

  Widget renderPagination(BuildContext context) {
    if (widget.pagination != true)
      return const SizedBox.shrink();
    
    Widget Function(int pagerIndex, dynamic url) paginationFn = (pagerIndex, url) => const SizedBox.shrink();
    final activeIndicator = widget.activeIndicator == null ? VTSCarouselStyle.get('activeIndicator') : widget.activeIndicator!;
    final inactiveIndicator = widget.inactiveIndicator == null ? VTSCarouselStyle.get('inactiveIndicator') : widget.inactiveIndicator!;
    if (widget.indicatorBuilder != null)
      paginationFn = 
        (pagerIndex, url) {
          final isActive = currentSlide == pagerIndex;
          return DefaultTextStyle(
            style: TextStyle(
              color: isActive
                ? activeIndicator
                : inactiveIndicator
              ), 
            child: IconTheme(
              data: IconThemeData(
                color: isActive
                  ? activeIndicator
                  : inactiveIndicator
                ),
              child: widget.indicatorBuilder!(isActive)
            )
          );
        };
    else
      paginationFn = 
        (pagerIndex, url) {
          final isActive = currentSlide == pagerIndex;
          return Container(
            width: widget.indicatorSize == null
                ? VTSCarouselStyle.get('indicatorSize')
                : widget.indicatorSize,
            height: widget.indicatorSize == null
                ? VTSCarouselStyle.get('indicatorSize')
                : widget.indicatorSize,
            margin: widget.indicatorMargin ?? VTSCarouselStyle.get('indicatorMargin'),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive                
                ? activeIndicator
                : inactiveIndicator
            )
          );
        };

    return Positioned(
      left: 0,
      right: 0,
      bottom: VTSCarouselStyle.get('indicatorBottom'),
      child: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.map<Widget>(
              widget.items,
              (pagerIndex, url) => paginationFn(pagerIndex, url)
            ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[
          getPageWrapper(PageView.builder(
            physics: widget.scrollPhysics,
            scrollDirection: widget.scrollDirection,
            controller: pageController,
            reverse: widget.reverse,
            itemCount: widget.items.length == 1
                ? widget.items.length
                : widget.enableInfiniteScroll
                    ? null
                    : widget.items.length,
            onPageChanged: (int index) {
              int currentPage;
              currentPage = _getRealIndex(
                  index + widget.initialPage, realPage, widget.items.length);
              if (widget.onPageChanged != null) {
                widget.onPageChanged!(currentPage);
              }
              if (widget.pagination == true) {
                onPageSlide(currentPage);
              }
            },
            itemBuilder: (BuildContext context, int i) {
              int index;
              index = _getRealIndex(
                i + widget.initialPage,
                realPage,
                widget.items.length,
              );
              currentSlide = widget.initialPage;
              return AnimatedBuilder(
                animation: pageController,
                child: widget.items[index],
                builder: (BuildContext context, child) {
                  double value;
                  try {
                    value = pageController.page! - i;
                    // ignore: avoid_catches_without_on_clauses
                  } catch (e) {
                    final BuildContext storageContext =
                        pageController.position.context.storageContext;
                    final double? previousSavedPosition =
                        PageStorage.of(storageContext)
                            ?.readState(storageContext);
                    if (previousSavedPosition != null) {
                      value = previousSavedPosition - i.toDouble();
                    } else {
                      value = realPage.toDouble() - i.toDouble();
                    }
                  }
                  value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);

                  final double height = widget.height ??
                      MediaQuery.of(context).size.width *
                          (1 / widget.aspectRatio);

                  final double distortionValue = widget.enlargeMainPage
                      ? Curves.easeOut.transform(value)
                      : 1.0;

                  if (widget.scrollDirection == Axis.horizontal) {
                    return Center(
                      child: Container(
                        height: distortionValue * height,
                        child: child,
                      ),
                    );
                  } else {
                    return Center(
                      child: SizedBox(
                          width: distortionValue *
                              MediaQuery.of(context).size.width,
                          child: child),
                    );
                  }
                },
              );
            },
          )),
          renderPagination(context),
        ],
      );
}

/// Converts an index of a set size to the corresponding index of a collection of another size
/// as if they were circular.
///
/// Takes a [position] from collection Foo, a [base] from where Foo's index originated
/// and the [length] of a second collection Baa, for which the correlating index is sought.
///
/// For example; We have a Carousel of 10000(simulating infinity) but only 6 images.
/// We need to repeat the images to give the illusion of a never ending stream.
/// By calling _getRealIndex with position and base we get an offset.
/// This offset modulo our length, 6, will return a number bestuckValue 0 and 5, which represent the image
/// to be placed in the given position.
int _getRealIndex(int position, int base, int length) {
  final int offset = position - base;
  return _remainder(offset, length);
}

/// Returns the remainder of the modulo operation [input] % [source], and adjust it for
/// negative values.
int _remainder(int input, int source) {
  final int result = input % source;
  return result < 0 ? source + result : result;
}
