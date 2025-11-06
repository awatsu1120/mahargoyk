import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_item.dart';
import 'spot_detail_page.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/header.dart';

class ContentListPage extends StatefulWidget {
  final String title;
  final String collectionName;

  const ContentListPage({
    super.key,
    required this.title,
    required this.collectionName,
  });

  @override
  ContentListPageState createState() => ContentListPageState();
}

class ContentListPageState extends State<ContentListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  int _selectedIndex = 0;

  // ★★★ 状態管理をページ番号方式に変更 ★★★
  int _currentPage = 1;
  final int _itemsPerPage = 12;

  final Map<String, bool> _genreFilters = {
    '観光': false,
    'グルメ': false,
    'ショッピング': false,
    'ホテル・旅館': false,
    'お土産': false,
    'イベント': false,
    'ライフスタイル': false,
  };

  final Map<String, bool> _areaFilters = {
    '三宮・元町': false,
    '北野・新神戸': false,
    'メリケンパーク・ハーバーランド': false,
    '六甲山・摩耶山': false,
    '有馬温泉': false,
    '灘・東灘': false,
    '兵庫・長田': false,
    '須磨・垂水': false,
    'ポートアイランド・神戸空港': false,
    '西神・北神': false,
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
        _currentPage = 1;
      });
    });
    _selectedIndex = 1;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ★★★ ページネーションコントロールを構築するウィジェット ★★★
  Widget _buildPaginationControls(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: _currentPage > 1
              ? () => setState(() {
                  _currentPage--;
                })
              : null,
        ),
        ...List.generate(totalPages, (index) {
          final page = index + 1;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              onPressed: () => setState(() {
                _currentPage = page;
              }),
              style: TextButton.styleFrom(
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                backgroundColor: _currentPage == page
                    ? Colors.blue[50]
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(
                    color: _currentPage == page
                        ? Colors.blueAccent
                        : Colors.grey.shade300,
                  ),
                ),
              ),
              child: Text(
                '$page',
                style: TextStyle(
                  color: _currentPage == page
                      ? Colors.blueAccent
                      : Colors.black87,
                  fontWeight: _currentPage == page
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: _currentPage < totalPages
              ? () => setState(() {
                  _currentPage++;
                })
              : null,
        ),
      ],
    );
  }

  Widget _buildFilterSection(String title, Map<String, bool> filterOptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            childAspectRatio: 4.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: filterOptions.length,
          itemBuilder: (context, index) {
            final key = filterOptions.keys.elementAt(index);
            return InkWell(
              onTap: () {
                setState(() {
                  filterOptions[key] = !filterOptions[key]!;
                  _currentPage = 1;
                });
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.only(left: 4.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: filterOptions[key]!
                      ? Colors.blue[50]
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Checkbox(
                        value: filterOptions[key],
                        onChanged: (bool? value) {
                          setState(() {
                            filterOptions[key] = value!;
                            _currentPage = 1;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: Text(
                        key,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildImageCard(BuildContext context, ContentItem item) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: SelectionArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'キーワードで検索',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFilterSection('ジャンル', _genreFilters),
                    _buildFilterSection('エリア', _areaFilters),
                    const Divider(),
                  ],
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(widget.collectionName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('エラー: ${snapshot.error}')),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('データが見つかりませんでした。')),
                  );
                }

                final activeGenreFilters = _genreFilters.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();
                final activeAreaFilters = _areaFilters.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  final item = ContentItem.fromFirestore(doc);
                  final matchesText =
                      _searchText.isEmpty ||
                      item.title.toLowerCase().contains(
                        _searchText.toLowerCase(),
                      );
                  final matchesGenre =
                      activeGenreFilters.isEmpty ||
                      activeGenreFilters.contains(item.genre);
                  final matchesArea =
                      activeAreaFilters.isEmpty ||
                      activeAreaFilters.contains(item.area);

                  return matchesText && matchesGenre && matchesArea;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('条件に合うスポットが見つかりませんでした。')),
                  );
                }

                // ★★★ ページネーションのための計算 ★★★
                final totalItems = filteredDocs.length;
                final totalPages = (totalItems / _itemsPerPage).ceil();
                final startIndex = (_currentPage - 1) * _itemsPerPage;
                final endIndex = (startIndex + _itemsPerPage).clamp(
                  0,
                  totalItems,
                );
                final displayedDocs = filteredDocs.sublist(startIndex, endIndex);

                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = ContentItem.fromFirestore(
                            displayedDocs[index],
                          );
                          return _buildImageCard(context, item);
                        }, childCount: displayedDocs.length),
                      ),
                    ),
                    // ★★★ ページネーションコントロールを表示 ★★★
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: _buildPaginationControls(totalPages),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ), 
      bottomNavigationBar: AppBottomNavigation(currentIndex: _selectedIndex),
    );
  }
}