import 'package:flutter/material.dart';
import 'package:nested_scroll_controller/nested_scroll_controller.dart';

/// A simple example app demonstrating basic usage of [NestedScrollController].
///
/// The code below is copied-and-modified from [https://api.flutter.dev/flutter/widgets/NestedScrollView-class.html].
/// The only modifications made are for the [NestedScrollController] to be used.

void main() {
  runApp(TestApp());
}

final double itemExtent = 48.0;

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "NestedScrollController Example",
      theme: ThemeData(primarySwatch: Colors.orange),
      home: ExamplePage(),
    );
  }
}

class ExamplePage extends StatelessWidget {
  List<String> get _tabs => ["One", "Two", "Three"];

  @override
  Widget build(BuildContext context) {
    ScrollController outerScrollController = ScrollController();
    NestedScrollController nestedScrollController;

    return Scaffold(
      body: DefaultTabController(
        length: _tabs.length,
        child: NestedScrollView(
          /// 1. Use the [controller] field with a custom [ScrollController].
          controller: outerScrollController,
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
              return TabBarView(
                children: _tabs.map((String name) {
                  return SafeArea(
                    top: false,
                    bottom: false,
                    child: Builder(
                      builder: (BuildContext context) {
                        return CustomScrollView(
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
                                        nestedScrollController.animateToIndex(
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
                        );
                      },
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
