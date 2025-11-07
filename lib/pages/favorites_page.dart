// lib/pages/favorites_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/content_item.dart';
import '../models/course_item.dart';
import '../services/firestore_service.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';
import 'spot_detail_page.dart';
import 'course_detail_page.dart';
import 'event_detail_page.dart';
import 'login_page.dart'; // ログインページをインポート

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'お気に入り機能を使用するには\nログインが必要です。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text('ログインページへ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
body: SelectionArea(
        child: _user == null
            ? _buildLoginPrompt()
            : DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Colors.black87,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blueAccent,
                      tabs: [
                        Tab(icon: Icon(Icons.place), text: 'スポット'),
                        Tab(icon: Icon(Icons.directions_walk), text: 'モデルコース'),
                        Tab(icon: Icon(Icons.event), text: 'イベント'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildFavoritesList('spots'),
                          _buildFavoritesList('courses'),
                          _buildFavoritesList('events'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),      // currentIndexに無効な値を渡してクラッシュするのを防ぎ、選択色もグレーにする
      bottomNavigationBar: const AppBottomNavigation(currentIndex: -1),
    );
  }

  Widget _buildFavoritesList(String type) {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: _firestoreService.getFavorites(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('お気に入り登録済みのアイテムはありません。'));
        }

        final items = snapshot.data!;
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = items[index];
            if (doc.data() == null) {
              return const ListTile(title: Text("データエラー"));
            }

            // アイテムの種類によって表示と遷移先を切り替え
            if (type == 'courses') {
              final course = CourseItem.fromFirestore(doc);
              return ListTile(
                leading: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.network(course.imageUrl, fit: BoxFit.cover),
                ),
                title: Text(course.title),
                subtitle: Text(
                  course.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CourseDetailPage(courseId: course.id),
                  ),
                ),
              );
            } else {
              final content = ContentItem.fromFirestore(doc);
              return ListTile(
                leading: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.network(content.imageUrl, fit: BoxFit.cover),
                ),
                title: Text(content.title),
                subtitle: Text(
                  content.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  if (type == 'spots') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SpotDetailPage(spot: content),
                      ),
                    );
                  } else if (type == 'events') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EventDetailPage(event: content),
                      ),
                    );
                  }
                },
              );
            }
          },
        );
      },
    );
  }
}
