# nested_scroll_controller
[![Pub Version](https://img.shields.io/pub/v/nested_scroll_controller)](https://pub.dev/packages/nested_scroll_controller)
<br><br>
A widget used to allow for controlling a [NestedScrollView](https://api.flutter.dev/flutter/widgets/NestedScrollView-class.html) like it was a regular scroll view. <br>
This is a small library which empowers you to control the offset of a [NestedScrollView](https://api.flutter.dev/flutter/widgets/NestedScrollView-class.html) just like you would a regular scroll view:
- animate to an offset or an index
- jump to an offset or an index
- add listeners to the total offset
<br>

## Usage

See [example](example/lib/main.dart).
<br>
To utilize [NestedScrollController] there are four main steps:

```dart
    /// 1. Create the [NestedScrollController].
    NestedScrollController nestedScrollController = NestedScrollController();

    return ... /// [Scaffold] and [DefaultTabController] here.
         NestedScrollView(
          /// 2. Set the controller of the [NestedScrollView] to the nestedScrollController.
          controller: nestedScrollController,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) { ... },

          /// 3. Wrap the body in a [Builder] to provide the [NestedScrollView.body] [BuildContext].
          body: Builder(
            builder: (context) {
              /// 4. Set the [NestedScrollView.innerScrollController].
              nestedScrollController.setInnerScrollController(context);
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
                                nestedScrollController.nestedAnimateToIndex(
                                    index,
                                    itemExtent: itemExtent,
                                );
                                      ...
```
