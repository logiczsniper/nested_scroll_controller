# nested_scroll_controller
[![Pub Version](https://img.shields.io/pub/v/nested_scroll_controller)](https://pub.dev/packages/nested_scroll_controller)
<br><br>
A widget used in conjunction with a basic [ScrollController](https://api.flutter.dev/flutter/widgets/ScrollController-class.html) to allow for controlling a [NestedScrollView](https://api.flutter.dev/flutter/widgets/NestedScrollView-class.html) like it was a regular scroll view. <br>
This is a small library which empowers you in every way (and more!) that a standard scroll controller would on a scroll view:
- animate to an offset or an index
- jump to an offset or an index
- add listeners to the total offset
- TODO: utilize NestedScrollPositions with NestedScrollController as you would ScrollPositions with ScrollController!
<br>

## Usage

See [example](example/lib/main.dart).
<br>
To utilize [NestedScrollController] there are four main steps:

```dart
    /// In build method...
    ScrollController outerScrollController = ScrollController();
    NestedScrollController nestedScrollController;

    return ... /// [Scaffold] and [DefaultTabController] here.
         NestedScrollView(
          /// 1. Use the [controller] field with a custom [ScrollController].
          controller: outerScrollController,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) { ... },

          /// 2. Wrap the body in a [Builder] to provide the [NestedScrollView.body]
          /// [BuildContext].
          body: Builder(
            builder: (context) {
              /// 3. Create the [NestedScrollController] here!
              ///
              /// In this example, I noticed that the center** was originally around
              /// the 2nd index, hence the 3rd parameter.
              ///
              /// ** See [NestedScrollController.centerCorrectionOffset] for more information
              /// on this term.
              nestedScrollController = NestedScrollController(
                bodyContext: context,
                outerController: outerScrollController,
                centerCorrectionOffset: itemExtent * 4,
              );
              return ... /// [TabBarView] with [CustomScrollView] here.
                    SliverPadding(
                        padding: const EdgeInsets.all(8.0),
                        sliver: SliverFixedExtentList(
                        itemExtent: itemExtent,
                        delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                            return ListTile(
                                title: Text('Item $index'),
                                onTap: () {
                                /// 4. Use the [NestedScrollController]!
                                nestedScrollController.animateToIndex(
                                    index,
                                    itemExtent: itemExtent,
                                );
                                      ...
```
