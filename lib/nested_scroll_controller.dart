library nested_scroll_controller;

import 'package:flutter/widgets.dart';

enum _View { inner, outer }
enum _MovementMethod { animate, jump }

/// Constructed within the [body] of [NestedScrollView], wrapped in a [Builder] to
/// get the [BuildContext] which contains the [innerController] as the [PrimaryScrollController].
class NestedScrollController extends ScrollController {
  NestedScrollController({
    @required ScrollController outerController,
    @required BuildContext bodyContext,
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String debugLabel,

    /// Special [NestedAutoScroller] parameter(s).
    double threshold = 0.0,
    double centerCorrectionOffset = 0.0,
  }) : super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        ) {
    _nestedAutoScroller = _NestedAutoScroller(
      scrollController: outerController,
      innerScrollController: PrimaryScrollController.of(bodyContext),
      threshold: threshold,
      centerCorrectionOffset: centerCorrectionOffset,
    );
  }

  /// The auto scroller which will be used to complete the movements.
  _NestedAutoScroller _nestedAutoScroller;

  @override
  Future<void> jumpTo(double offset) {
    return _nestedAutoScroller.jumpTo(offset);
  }

  @override
  Future<void> animateTo(
    double offset, {
    Duration duration,
    Curve curve,
    Curve endCurve,
  }) {
    return _nestedAutoScroller.animateTo(
      offset,
      duration: duration,
      startCurve: curve,
      endCurve: endCurve,
    );
  }

  Future<void> animateToIndex(
    int index, {
    @required double itemExtent,
    Duration duration,
    Curve curve,
    Curve endCurve,
  }) {
    return _nestedAutoScroller.animateToIndex(
      index,
      itemExtent,
      duration: duration,
      startCurve: curve,
      endCurve: endCurve,
    );
  }
}

class _NestedAutoScroller {
  /// The scroll controllers of the [NestedListView].
  final ScrollController scrollController;
  final ScrollController innerScrollController;

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
  Duration _duration;

  /// The animation [Curve] which will be applied to the first scroll.
  ///
  /// In cases where two [animateToIndex] calls are required, [_startCurve] will
  /// be applied to the first [animateToIndex] as it is at the start of the
  /// overall scroll to the [index].
  Curve _startCurve;

  /// The animated [Curve] which will be applied to the ending scroll.
  ///
  /// In cases where two [animateToIndex] calls are required, [_endCurve] will
  /// be applied to the second [animatedTo] as it is at the end of the
  /// overall scroll to the [index].
  Curve _endCurve;

  /// Suggested pairings for [_startCurve] and [_endCurve] (other than the default) are:
  ///
  /// 1) [Curves.easeInToLinear], [Curves.linearToEaseOut],
  /// 2) [Curves.easeInCubic], [Curves.easeOutCubic]

  /// The offset between the current scroll position (in total) and
  /// the ending position.
  double _distance;

  /// Whether or not to animate or jump when moving.
  _MovementMethod _movementMethod;

  _NestedAutoScroller({
    @required this.scrollController,
    @required this.innerScrollController,
    this.threshold = 0,
    this.centerCorrectionOffset = 50.0,
  })  : assert(scrollController != null && innerScrollController != null),
        assert(threshold >= 0);

  @protected
  double get _currentOuterOffset => scrollController.offset ?? 0.0;

  @protected
  double get _currentInnerOffset => innerScrollController.offset ?? 0.0;

  @protected
  double get _currentTotalOffset =>
      _currentOuterOffset + _currentInnerOffset + centerCorrectionOffset;

  @protected
  double get _totalDuration => duration.inMilliseconds.roundToDouble();

  @protected
  double get _threshold => threshold;

  @protected
  double get _minimumInnerOffset => innerScrollController.position.minScrollExtent;

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
  set duration(Duration newDuration) => _duration = newDuration;

  @protected
  Curve get startCurve => _startCurve ?? Curves.easeInCubic;

  @protected
  set startCurve(Curve newStartCurve) => _startCurve = newStartCurve;

  @protected
  Curve get endCurve => _endCurve ?? Curves.decelerate;

  @protected
  set endCurve(Curve newEndCurve) => _endCurve = newEndCurve;

  @protected
  _MovementMethod get movementMethod => _movementMethod ?? _MovementMethod.animate;

  @protected
  set movementMethod(_MovementMethod newMovementMethod) => _movementMethod = newMovementMethod;

  /// This will throw an error when the duration for the secondary scroll
  /// is zero.
  ///
  /// We ignore this error.
  @protected
  Future<void> onZeroDuration(_) => Future<void>.value();

  /// Scroll a single scroll view (either the inner or the outer).
  @protected
  Future<void> singleScroll(_View scrollView) {
    ScrollController _controller;
    double _newOffset;

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
        return _controller.animateTo(
          _newOffset,
          duration: duration,
          curve: endCurve,
        );
        break;
      case _MovementMethod.jump:
        _controller.jumpTo(_newOffset);
        break;
    }
    return Future<void>.value();
  }

  /// Scrolls both the [scrollController] and the [innerScrollController]
  @protected
  Future<void> doubleScroll(_View startScrollView) {
    ScrollController _startController;
    ScrollController _endController;

    double _newStartOffset;
    double _newEndOffset;
    double _startDuration;
    double _endDuration;

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
        double _outerDistance = (_newEndOffset ?? _currentOuterOffset) - _currentOuterOffset;
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
        double _innerDistance = (_newEndOffset ?? _currentInnerOffset) - _currentInnerOffset;
        _startDuration = (_outerDistance / distance).abs() * _totalDuration;
        _endDuration = (_innerDistance / distance).abs() * _totalDuration;

        break;
    }

    switch (movementMethod) {
      case _MovementMethod.animate:
        return _startController
            .animateTo(
              _newStartOffset,
              duration: Duration(milliseconds: _startDuration.round()),
              curve: startCurve,
            )
            .whenComplete(() => _endController
                .animateTo(
                  _newEndOffset ?? _endController.offset,
                  duration: Duration(milliseconds: _endDuration.round()),
                  curve: endCurve,
                )
                .catchError(onZeroDuration));
        break;
      case _MovementMethod.jump:
        double _scrollControllerOffset;
        double _innerScrollControllerOffset;

        switch (startScrollView) {
          case _View.inner:
            _innerScrollControllerOffset = _newStartOffset;
            _scrollControllerOffset = _newEndOffset ?? _endController.offset;
            break;
          case _View.outer:
            _innerScrollControllerOffset = _newEndOffset ?? _endController.offset;
            _scrollControllerOffset = _newStartOffset;
            break;
        }

        scrollController.jumpTo(_scrollControllerOffset);
        print("Outer jumped to: $_scrollControllerOffset");

        if (_innerScrollControllerOffset > 0) {
          _endController.jumpTo(_innerScrollControllerOffset);
          print("Inner jumped to: $_innerScrollControllerOffset");
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
    Duration duration,
    Curve startCurve,
    Curve endCurve,
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
    Duration duration,
    Curve startCurve,
    Curve endCurve,
  }) {
    assert(_offset >= 0);

    //  FIXME: there is a chance this should be + _offset
    this.distance = _currentTotalOffset - _offset;
    this.movementMethod = _MovementMethod.animate;
    this.duration = duration;
    this.startCurve = startCurve;
    this.endCurve = endCurve;
    return scrollToDistance();
  }

  Future<void> scrollToDistance() {
    /// Some boolean values which make the following conditional much more
    /// clear.
    bool _isScrollUp = distance >= 0;
    bool _shouldScroll = distance.abs() > _threshold;

    /// The scroll view which the animation is starting in.
    bool _isInInner = _currentInnerOffset > _minimumInnerOffset;
    _View _startView = _isInInner ? _View.inner : _View.outer;

    if (_shouldScroll) {
      /// If one of the following is true, complete a [singleScroll]:
      ///   1) The list is currently in the inner scroll view and the request is to scroll down.
      ///   2) The list is currently in the outer scroll view and the request is to scroll up.
      /// Else, complete a [doubleScroll].
      if (_startView == _View.inner && !_isScrollUp || _startView == _View.outer && _isScrollUp) {
        return singleScroll(_startView);
      } else {
        return doubleScroll(_startView);
      }
    }
    return Future<void>.value();
  }
}
