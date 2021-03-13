library nested_scroll_controller;

import 'package:flutter/widgets.dart';

enum _View { inner, outer }
enum _MovementMethod { animate, jump }

typedef _ScrollerFunction = Future<void> Function(_NestedAutoScroller);

/// Constructed within the [body] of [NestedScrollView], wrapped in a [Builder] to
/// get the [BuildContext] which contains the [innerController] as the [PrimaryScrollController].
class NestedScrollController extends ScrollController {
  /// The [ScrollController] of the inner scroll view.
  ///
  /// Must be set before attempting to scroll.
  ScrollController? innerScrollController;

  /// The offset which 'centers' an item when it is scrolled to.
  ///
  /// * See [_NestedAutoScroller.centerCorrectionOffset].
  double? centerCorrectionOffset;

  /// * See [_NestedAutoScroller.threshold].
  final double threshold;

  /// * See [ScrollController.initialScrollOffset]
  final double initialScrollOffset;

  /// * See [ScrollController.keepScrollOffset]
  final bool keepScrollOffset;

  /// Whether or not to center the item on the screen when
  /// it is scrolled to.
  final bool centerScroll;

  NestedScrollController({
    this.initialScrollOffset = 0.0,
    this.keepScrollOffset = true,
    String? debugLabel,

    /// Special [NestedAutoScroller] parameter(s).
    this.threshold = 0.0,
    this.centerCorrectionOffset,
    this.centerScroll = true,
  })  : _listeners = [],
        super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        );

  @protected
  List<VoidCallback> _listeners;

  @protected
  Future<void> useScroller(
    _ScrollerFunction _scrollerFunction,
    ScrollController outerScrollController,
  ) {
    assert(
      innerScrollController != null,
      "The inner scroll controller must not be null when attempting to scroll!\nHint: call NestedScrollController.enableScroll in the body of your NestedScrollView. Head over to https://pub.dev/packages/nested_scroll_controller for more information.",
    );
    assert(
      centerCorrectionOffset != null || centerScroll != true,
      "The centerCorrectionOffset must not be null when attempting to center scroll!\nHint: call NestedScrollController.enableCenterScroll in the body of your NestedScrollView. Head over to https://pub.dev/packages/nested_scroll_controller for more information.",
    );

    /// Create and use the [_NestedAutoScroller].
    var _nestedAutoScroller = _NestedAutoScroller(
      scrollController: this,
      innerScrollController: innerScrollController,
      threshold: threshold,
      centerCorrectionOffset: centerCorrectionOffset ?? 0.0,
    );

    return _scrollerFunction(_nestedAutoScroller);
  }

  /// Sets the [innerScrollController] for the [NestedScrollController].
  ///
  /// This is required before attempting to scroll. The [bodyContext] must be
  /// a [BuildContext] aquired from the [body] of the [NestedScrollView]. Using this
  /// context, we can obtain (and set) the [innerScrollController].
  void enableScroll(BuildContext bodyContext) {
    innerScrollController = PrimaryScrollController.of(bodyContext);

    /// Add each listener to the new [innerScrollController].
    for (VoidCallback listener in _listeners)
      innerScrollController!.addListener(listener);
  }

  /// Sets the [centerCorrectionOffset] for the [NestedScrollController].
  ///
  /// This is required before attempting to scroll if [centerScroll] is true. The [constraints]
  /// must be a [BoxConstraints] aquired from the body of the [NestedScrollView]. Using
  /// [contraints.maxHeight], we can roughly obtain (and set) the correct [centerCorrectionOffset].
  void enableCenterScroll(BoxConstraints constraints) {
    if (centerScroll && centerCorrectionOffset == null) {
      centerCorrectionOffset = constraints.maxHeight / 4;
    }
  }

  double get innerOffset => innerScrollController?.offset ?? 0.0;
  double get totalOffset => offset + innerOffset;

  /// Jump to the [offset] in the [NestedScrollView].
  ///
  /// * See [_NestedAutoScroller.jumpTo].
  Future<void> nestedJumpTo(double offset) {
    return useScroller((scroller) => scroller.jumpTo(offset), this);
  }

  /// Animate to the [offset] in the [NestedScrollView].
  ///
  /// * See [_NestedAutoScroller.animateTo].
  Future<void> nestedAnimateTo(
    double offset, {
    Duration? duration,
    Curve? curve,
    Curve? endCurve,
  }) {
    return useScroller(
        (scroller) => scroller.animateTo(
              offset,
              duration: duration,
              startCurve: curve,
              endCurve: endCurve,
            ),
        this);
  }

  /// Animate to the [index] in the [NestedScrollView].
  ///
  /// * See [_NestedAutoScroller.animateToIndex].
  Future<void> nestedAnimateToIndex(
    int index, {
    required double itemExtent,
    Duration? duration,
    Curve? curve,
    Curve? endCurve,
  }) {
    return useScroller(
        (scroller) => scroller.animateToIndex(
              index,
              itemExtent,
              duration: duration,
              startCurve: curve,
              endCurve: endCurve,
            ),
        this);
  }

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    innerScrollController?.addListener(listener);
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    innerScrollController?.removeListener(listener);
    _listeners.remove(listener);
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    innerScrollController?.notifyListeners();
  }

  @override
  bool get hasListeners => _listeners.isNotEmpty;

  @override
  double get offset {
    if (super.positions.isNotEmpty)
      return super.offset;
    else
      return 0.0;
  }

  @override
  int get hashCode {
    /// Cantor pairing function.
    int k1 = super.hashCode;
    int k2 = innerScrollController?.hashCode ?? 0;

    return (0.5 * (k1 + k2) * (k1 + k2 + 1) + k2).toInt();
  }

  @override
  bool operator ==(dynamic other) {
    return other is NestedScrollController && other.hashCode == super.hashCode;
  }

  @override
  void dispose() {
    _listeners = [];
    innerScrollController?.dispose();
    super.dispose();
  }
}

class _NestedAutoScroller {
  /// The scroll controllers of the [NestedListView].
  final NestedScrollController scrollController;
  final ScrollController? innerScrollController;

  /// The offset applied from the top of the list which 'centers' the [index] when
  /// [animateToIndex] is called.
  ///
  /// The [threshold] is centered around this value in the scrollview.
  ///
  /// The 'center' is like a point on the list which is floating- as the list scrolls it
  /// remains where it is on the screen. The threshold is +/- offset from this 'center'.
  /// [centerCorrectionOffset] gives the user a chance to more accurately place this 'center'
  /// in the actual vertically aligned center of the screen.
  ///
  /// Increase the [centerCorrectionOffset] to move the 'center' down and vice versa.
  final double centerCorrectionOffset;

  /// The minimum value that the distance must be to cause a scroll.
  ///
  /// The smaller the threshold, the distance must be greater and vice versa.
  /// Defaults to 0, meaning it will always scroll when methods are called.
  final double threshold;

  /// The total duration of the entire scroll.
  Duration? _duration;

  /// The animation [Curve] which will be applied to the first scroll.
  ///
  /// In cases where two [animateToIndex] calls are required, [_startCurve] will
  /// be applied to the first [animateToIndex] as it is at the start of the
  /// overall scroll to the [index].
  Curve? _startCurve;

  /// The animated [Curve] which will be applied to the ending scroll.
  ///
  /// In cases where two [animateToIndex] calls are required, [_endCurve] will
  /// be applied to the second [animatedTo] as it is at the end of the
  /// overall scroll to the [index].
  Curve? _endCurve;

  /// Suggested pairings for [_startCurve] and [_endCurve] (other than the default) are:
  ///
  /// 1) [Curves.easeInToLinear], [Curves.linearToEaseOut],
  /// 2) [Curves.easeInCubic], [Curves.easeOutCubic]

  /// The offset between the current scroll position (in total) and
  /// the ending position.
  double? _distance;

  /// Whether or not to animate or jump when moving.
  _MovementMethod? _movementMethod;

  _NestedAutoScroller({
    required this.scrollController,
    required this.innerScrollController,
    this.threshold = 0,
    this.centerCorrectionOffset = 50.0,
  })  : assert(scrollController != null && innerScrollController != null),
        assert(threshold >= 0);

  @protected
  double get _currentOuterOffset => scrollController.offset ?? 0.0;

  @protected
  double get _currentInnerOffset => innerScrollController!.offset ?? 0.0;

  @protected
  double get _currentTotalOffset =>
      _currentOuterOffset + _currentInnerOffset + centerCorrectionOffset;

  @protected
  double get _totalDuration => duration.inMilliseconds.roundToDouble();

  @protected
  double get _threshold => threshold;

  @protected
  double get _minimumInnerOffset =>
      innerScrollController!.position.minScrollExtent;

  @protected
  double get _maximumOuterOffset => scrollController.position.maxScrollExtent;

  /// The total distance that will be traveled.
  ///
  /// This can be a negative number; if it is, this indicates a downward
  /// scroll and vice versa.
  @protected
  double get distance => _distance ?? 0.0;

  @protected
  set distance(double newDistance) => _distance = newDistance;

  @protected
  Duration get duration => _duration ?? const Duration(milliseconds: 800);

  @protected
  set duration(Duration? newDuration) => _duration = newDuration;

  @protected
  Curve get startCurve => _startCurve ?? Curves.easeInCubic;

  @protected
  set startCurve(Curve? newStartCurve) => _startCurve = newStartCurve;

  @protected
  Curve get endCurve => _endCurve ?? Curves.decelerate;

  @protected
  set endCurve(Curve? newEndCurve) => _endCurve = newEndCurve;

  @protected
  _MovementMethod get movementMethod =>
      _movementMethod ?? _MovementMethod.animate;

  @protected
  set movementMethod(_MovementMethod newMovementMethod) =>
      _movementMethod = newMovementMethod;

  /// This will throw an error when the duration for the secondary scroll
  /// is zero.
  ///
  /// We ignore this error.
  @protected
  Future<void> onZeroDuration(_) => Future<void>.value();

  /// Scroll a single scroll view (either the inner or the outer).
  @protected
  Future<void> singleScroll(_View scrollView) {
    ScrollController? _controller;
    late double _newOffset;

    switch (scrollView) {
      case _View.inner:
        _newOffset = _currentInnerOffset - distance;
        _controller = innerScrollController;

        break;
      case _View.outer:
        _newOffset = _currentOuterOffset - distance;
        _controller = scrollController;

        break;
    }

    switch (movementMethod) {
      case _MovementMethod.animate:
        return _controller!.animateTo(
          _newOffset,
          duration: duration,
          curve: endCurve,
        );
        break;
      case _MovementMethod.jump:
        _controller!.jumpTo(_newOffset);
        break;
    }
    return Future<void>.value();
  }

  /// Scrolls both the [scrollController] and the [innerScrollController]
  @protected
  Future<void> doubleScroll(_View startScrollView) {
    ScrollController? _startController;
    ScrollController? _endController;

    double? _newStartOffset;
    double? _newEndOffset;
    double? _startDuration;
    late double _endDuration;

    switch (startScrollView) {
      case _View.inner:
        _startController = innerScrollController;
        _endController = scrollController;
        _newStartOffset = _currentInnerOffset - distance;

        if (_newStartOffset < _minimumInnerOffset) {
          _newEndOffset = _currentOuterOffset + _newStartOffset;
          _newStartOffset = _minimumInnerOffset;
        }

        double _innerDistance = (_newStartOffset - _currentInnerOffset);
        double _outerDistance =
            (_newEndOffset ?? _currentOuterOffset) - _currentOuterOffset;
        _endDuration = (_outerDistance / distance).abs() * _totalDuration;
        _startDuration = (_innerDistance / distance).abs() * _totalDuration;

        break;
      case _View.outer:
        _startController = scrollController;
        _endController = innerScrollController;

        _newStartOffset = _currentOuterOffset - distance;

        if (_newStartOffset > _maximumOuterOffset) {
          _newEndOffset = _newStartOffset - _maximumOuterOffset;
          _newStartOffset = _maximumOuterOffset;
        }

        double _outerDistance = _newStartOffset - _currentOuterOffset;
        double _innerDistance =
            (_newEndOffset ?? _currentInnerOffset) - _currentInnerOffset;
        _startDuration = (_outerDistance / distance).abs() * _totalDuration;
        _endDuration = (_innerDistance / distance).abs() * _totalDuration;

        break;
    }

    if (_startDuration == 0) return onZeroDuration(null);

    switch (movementMethod) {
      case _MovementMethod.animate:
        return _startController!
            .animateTo(
              _newStartOffset,
              duration: Duration(milliseconds: _startDuration.round()),
              curve: startCurve,
            )
            .whenComplete(() => _endController!
                .animateTo(
                  _newEndOffset ?? _endController.offset,
                  duration: Duration(milliseconds: _endDuration.round()),
                  curve: endCurve,
                )
                .catchError(onZeroDuration));
        break;
      case _MovementMethod.jump:
        double? _scrollControllerOffset;
        double? _innerScrollControllerOffset;

        switch (startScrollView) {
          case _View.inner:
            _innerScrollControllerOffset = _newStartOffset;
            _scrollControllerOffset = _newEndOffset ?? _endController!.offset;
            break;
          case _View.outer:
            _innerScrollControllerOffset =
                _newEndOffset ?? _endController!.offset;
            _scrollControllerOffset = _newStartOffset;
            break;
        }

        scrollController.jumpTo(_scrollControllerOffset);
        // print("Outer jumped to: $_scrollControllerOffset");

        if (_innerScrollControllerOffset > 0) {
          _endController!.jumpTo(_innerScrollControllerOffset);
          // print("Inner jumped to: $_innerScrollControllerOffset");
        }

        break;
    }
    return Future<void>.value();
  }

  Future<void> jumpTo(double _offset) {
    assert(_offset >= 0);

    this.distance = _currentTotalOffset - _offset;
    this.movementMethod = _MovementMethod.jump;
    return scrollToDistance();
  }

  /// Animated to the given [_index] in the nested scroll view.
  Future<void> animateToIndex(
    int _index,
    double _itemExtent, {
    Duration? duration,
    Curve? startCurve,
    Curve? endCurve,
  }) {
    assert(_index >= 0);

    this.distance = _currentTotalOffset - (_itemExtent * _index);
    this.movementMethod = _MovementMethod.animate;
    this.duration = duration;
    this.startCurve = startCurve;
    this.endCurve = endCurve;
    return scrollToDistance();
  }

  /// Animated to the given [_offset] in the nested scroll view.
  Future<void> animateTo(
    double _offset, {
    Duration? duration,
    Curve? startCurve,
    Curve? endCurve,
  }) {
    assert(_offset >= 0);

    this.distance = _currentTotalOffset - _offset;
    this.movementMethod = _MovementMethod.animate;
    this.duration = duration;
    this.startCurve = startCurve;
    this.endCurve = endCurve;
    return scrollToDistance();
  }

  Future<void> scrollToDistance() {
    /// The scroll view which the animation is starting in.
    bool _isInInner = _currentInnerOffset > _minimumInnerOffset;
    _View _startView = _isInInner ? _View.inner : _View.outer;

    bool _shouldScroll = distance.abs() > _threshold;

    /// Overflow meaning that the scroll starts in one [_View]
    /// and ends in the opposite [_View].
    bool _isOverflow = (_startView == _View.inner &&
            (_currentInnerOffset - distance) < _minimumInnerOffset) ||
        (_startView == _View.outer &&
            (_currentOuterOffset - distance) > _maximumOuterOffset);

    if (_shouldScroll) {
      if (_isOverflow) {
        return doubleScroll(_startView);
      } else {
        return singleScroll(_startView);
      }
    }
    return Future<void>.value();
  }
}
