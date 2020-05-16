import 'package:flutter/material.dart';
import 'package:nested_scroll_controller/nested_scroll_controller.dart';

/// A simple example app demonstrating basic usage of [NestedScrollController].
///
/// The code below is copied-and-modified from [https://api.flutter.dev/flutter/widgets/NestedScrollView-class.html].
/// The only modifications made are for the [NestedScrollController] to be clearly used.

void main() {
  runApp(TestApp());
}

final double itemExtent = 48.0;

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "NestedScrollController Example",
      home: ExamplePage(),
    );
  }
}

class ExamplePage extends StatelessWidget {
  List<String> get _tabs => ["One", "Two"];

  @override
  Widget build(BuildContext context) {
    /// Create the [NestedScrollController].
    NestedScrollController nestedScrollController = NestedScrollController();

    return Scaffold(
      body: DefaultTabController(
        length: _tabs.length,
        child: NestedScrollView(
          /// 2. Give the controller to the [NestedScrollView].
          controller: nestedScrollController,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  title: const Text('Books'),
                  pinned: true,
                  expandedHeight: 150.0,
                  forceElevated: innerBoxIsScrolled,
                  bottom: TabBar(
                    tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                  ),
                ),
              ),
            ];
          },

          /// 3. Wrap the body in a [Builder] to provide the [NestedScrollView.body] [BuildContext].
          body: Builder(
            builder: (BuildContext context) {
              /// 4. Set the [NestedScrollView.innerScrollController].
              nestedScrollController.setInnerScrollController(context);
              return TabBarView(
                children: _tabs.map((String name) {
                  return SafeArea(
                    top: false,
                    bottom: false,
                    child: CustomScrollView(
                      key: PageStorageKey<String>(name),
                      slivers: <Widget>[
                        SliverOverlapInjector(
                          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                        ),
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
                                  },
                                );
                              },
                              childCount: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}
