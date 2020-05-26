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
To utilize [NestedScrollController] there are five main steps:

```dart
    /// 1. Create the [NestedScrollController].
    final NestedScrollController nestedScrollController = NestedScrollController();
```

```dart
    NestedScrollView(
        /// 2. Set the controller of the [NestedScrollView] to the nestedScrollController.
        controller: nestedScrollController,
```

```dart
        /// 3. Wrap the body of the [NestedScrollView] in a [LayoutBuilder].
        ///
        /// NOTE: if [nestedScrollController.centerScroll] is false (defaults to true),
        ///       then [constraints] is not needed and a [Builder] can be used instead of
        ///       the [LayoutBuilder].
        body: LayoutBuilder(
            builder: (context, constraints) {
                /// 4. Enable scrolling and center scrolling.
                ///
                /// NOTE: Only call [enableCenterScroll] if 
                ///       [nestedScrollController.centerScroll] is true (defaults to true).
                nestedScrollController.enableScroll(context);
                nestedScrollController.enableCenterScroll(constraints);
```

```dart
                ListTile(
                    title: Text('Item $index'),
                    onTap: () {
                    /// 5. Use the [NestedScrollController] anywhere (after step 4).
                        nestedScrollController.nestedAnimateToIndex(
                            index,
                            itemExtent: itemExtent,
                        );
                    }
                );
                                      
```

Ofcourse, you can add/remove listeners just like a regular scroll controller:

```dart
    nestedScrollController.addListener(() {
      print("Outer: ${nestedScrollController.offset}");
      print("Inner: ${nestedScrollController.innerOffset}");
      print("Total: ${nestedScrollController.totalOffset}");
    });
```

## Result

See the example result [here](https://github.com/logiczsniper/nested_scroll_controller/blob/master/example/demo.gif).