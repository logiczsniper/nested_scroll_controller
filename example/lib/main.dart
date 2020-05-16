import 'package:flutter/material.dart';
import 'package:nested_scroll_controller/nested_scroll_controller.dart';

void main() {
  runApp(TestApp());
}

double itemExtent = 60.0;

Widget _buildTile(
  BuildContext context,
  int index,
  NestedScrollController controller,
) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 30.0),
    decoration: BoxDecoration(
      color: Colors.deepOrangeAccent,
      border: Border.all(color: Colors.deepOrange),
      borderRadius: BorderRadius.circular(15.0),
    ),
    child: ListTile(
      title: Text("Item $index"),
      contentPadding: EdgeInsets.all(5.0),
      onTap: () {
        controller.animateToIndex(index, itemExtent: itemExtent);
      },
    ),
  );
}

const tabCount = 2;

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.orange),
      home: TestAppHomePage(),
    );
  }
}

class TestTabBarDelegate extends SliverPersistentHeaderDelegate {
  TestTabBarDelegate({this.controller});

  final TabController controller;

  @override
  double get minExtent => kToolbarHeight;

  @override
  double get maxExtent => kToolbarHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).cardColor,
      height: kToolbarHeight,
      child: TabBar(
        controller: controller,
        key: PageStorageKey<Type>(TabBar),
        indicatorColor: Theme.of(context).primaryColor,
        tabs: <Widget>[
          Tab(text: 'one'),
          Tab(text: 'two'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant TestTabBarDelegate oldDelegate) {
    return oldDelegate.controller != controller;
  }
}

class TestAppHomePage extends StatefulWidget {
  @override
  TestAppHomePageState createState() => TestAppHomePageState();
}

class TestAppHomePageState extends State<TestAppHomePage> with TickerProviderStateMixin {
  ScrollController _scrollController = ScrollController();

  NestedScrollController _nestedScrollController;
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: Text("Test Title"),
              expandedHeight: 100,
            ),
            SliverPersistentHeader(
              delegate: TestTabBarDelegate(controller: _tabController),
            ),
          ];
        },
        body: Builder(builder: (context) {
          _nestedScrollController = NestedScrollController(
            outerController: _scrollController,
            bodyContext: context,
            centerCorrectionOffset: 200.0,
          );
          return TestHomePageBody(
            tabController: _tabController,
            scrollController: _nestedScrollController,
          );
        }),
      ),
    );
  }
}

class TestHomePageBody extends StatefulWidget {
  TestHomePageBody({this.scrollController, this.tabController});

  final NestedScrollController scrollController;
  final TabController tabController;

  TestHomePageBodyState createState() => TestHomePageBodyState();
}

class TestHomePageBodyState extends State<TestHomePageBody> {
  Key _key = PageStorageKey({});

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: widget.tabController,
      key: _key,
      children: List<Widget>.generate(tabCount, (int index) {
        return ListView.builder(
          key: PageStorageKey<int>(index),
          itemBuilder: (context, index) => _buildTile(context, index, widget.scrollController),
          itemCount: 30,
          itemExtent: itemExtent,
        );
      }),
    );
  }
}
