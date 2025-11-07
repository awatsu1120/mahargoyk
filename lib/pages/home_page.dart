// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';
import '../models/content_item.dart';
import '../models/course_item.dart'; // ★★★ CourseItemモデルをインポート
import 'spot_detail_page.dart';
import 'content_list_page.dart';
import 'course_detail_page.dart'; // ★★★ CourseDetailPageをインポート
import 'course_list_page.dart'; // ★★★ CourseListPageをインポート

// スポットやイベントのデータを取得する共通関数
Future<List<ContentItem>> _fetchContentFromCollection(
  String collectionName,
) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .limit(3)
        .get();

    return querySnapshot.docs
        .map((doc) => ContentItem.fromFirestore(doc))
        .toList();
  } catch (e) {
    debugPrint('[$collectionName]の読み込み中にエラーが発生しました: $e');
    return [];
  }
}

// ★★★ モデルコースのデータを取得する専用関数を新設 ★★★
Future<List<CourseItem>> _fetchCoursesFromCollection() async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .limit(3)
        .get();

    return querySnapshot.docs
        .map((doc) => CourseItem.fromFirestore(doc))
        .toList();
  } catch (e) {
    debugPrint('[courses]の読み込み中にエラーが発生しました: $e');
    return [];
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _selectedIndex = 0;

  // スポット・イベント用のカードWidget
  Widget _buildContentImageCard(BuildContext context, ContentItem item) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => SpotDetailPage(spot: item)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(item.imageUrl, fit: BoxFit.cover),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ★★★ モデルコース用のカードWidgetを新設 ★★★
  Widget _buildCourseImageCard(BuildContext context, CourseItem item) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CourseDetailPage(courseId: item.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(item.imageUrl, fit: BoxFit.cover),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // スポット・イベント用のセクションWidget
  Widget _buildContentSection(String title, String collectionName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ContentListPage(
                      title: '$title一覧',
                      collectionName: collectionName,
                    ),
                  ),
                );
              },
              child: const Text('もっと見る'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<ContentItem>>(
          future: _fetchContentFromCollection(collectionName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('エラー: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('データが見つかりませんでした。'));
            } else {
              final items = snapshot.data!;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: items.map((item) {
                  return _buildContentImageCard(context, item);
                }).toList(),
              );
            }
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ★★★ モデルコース用のセクションWidgetを新設 ★★★
  Widget _buildCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('モデルコース', style: Theme.of(context).textTheme.headlineSmall),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CourseListPage(),
                  ),
                );
              },
              child: const Text('もっと見る'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<CourseItem>>(
          future: _fetchCoursesFromCollection(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('エラー: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('データが見つかりませんでした。'));
            } else {
              final items = snapshot.data!;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: items.map((item) {
                  return _buildCourseImageCard(context, item);
                }).toList(),
              );
            }
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    hintText: '行き先やキーワードで検索',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 24),
                _buildContentSection('スポット', 'spots'),
                _buildContentSection('イベント', 'events'),
                // ★★★ モデルコースセクションの呼び出しを変更 ★★★
                _buildCoursesSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(currentIndex: _selectedIndex),
    );
  }
}