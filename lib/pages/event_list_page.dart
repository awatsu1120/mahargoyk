import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/content_item.dart';
import 'event_detail_page.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/header.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedArea;

  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;
  String? _appliedArea;

  // ★★★ 状態管理をページ番号方式に変更 ★★★
  int _currentPage = 1;
  final int _itemsPerPage = 12;

  final List<String> _areaOptions = const [
    'すべてのエリア',
    '三宮・元町',
    '北野・新神戸',
    'メリケンパーク・ハーバーランド',
    '六甲山・摩耶山',
    '有馬温泉',
    '灘・東灘',
    '兵庫・長田',
    '須磨・垂水',
    'ポートアイランド・神戸空港',
    '西神・北神',
    '北区',
    'ウォーターフロント',
    '六甲アイランド',
    '花隈',
    '新開地',
  ];

  @override
  void initState() {
    super.initState();
    _selectedArea = _areaOptions.first;
    _applyFilters();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          (isStartDate ? _selectedStartDate : _selectedEndDate) ??
          DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ja', 'JP'),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
        } else {
          _selectedEndDate = picked;
        }
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _appliedStartDate = _selectedStartDate;
      _appliedEndDate = _selectedEndDate;
      _appliedArea = _selectedArea == 'すべてのエリア' ? null : _selectedArea;
      // ★★★ フィルター適用時に1ページ目に戻す ★★★
      _currentPage = 1;
    });
  }

  String _getEventStatus(ContentItem item) {
    final now = DateTime.now();
    final startDate = item.startDate?.toDate();
    final endDate = item.endDate?.toDate();

    if (startDate == null || endDate == null) return '';

    final inclusiveEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    if (now.isAfter(startDate) && now.isBefore(inclusiveEndDate)) return '開催中';
    if (now.isBefore(startDate)) return '開催前';
    return '終了';
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
                    Text(
                      'イベント一覧',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildDateField(context, isStartDate: true),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('〜'),
                        ),
                        _buildDateField(context, isStartDate: false),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildAreaDropdown(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'この条件で絞り込む',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                  ],
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .orderBy('startDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('イベント情報がありません。')),
                  );
                }

                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final item = ContentItem.fromFirestore(doc);
                  final matchesArea =
                      _appliedArea == null || item.area == _appliedArea;
                  final eventStartDate = item.startDate?.toDate();
                  final eventEndDate = item.endDate?.toDate();
                  bool matchesDate = true;
                  if (eventStartDate != null && eventEndDate != null) {
                    if (_appliedStartDate != null &&
                        eventEndDate.isBefore(_appliedStartDate!)) {
                      matchesDate = false;
                    }
                    if (_appliedEndDate != null &&
                        eventStartDate.isAfter(_appliedEndDate!)) {
                      matchesDate = false;
                    }
                  }
                  return matchesArea && matchesDate;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('条件に合うイベントが見つかりませんでした。')),
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          '${filteredDocs.length}件 / ${allDocs.length}件中',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = ContentItem.fromFirestore(
                            displayedDocs[index],
                          );
                          return _buildEventCard(item);
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
      ), // ★★★ 変更点: SelectionAreaの閉じタグ ★★★
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildDateField(BuildContext context, {required bool isStartDate}) {
    DateTime? date = isStartDate ? _selectedStartDate : _selectedEndDate;
    String label = isStartDate ? '期間' : ' ';

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectDate(context, isStartDate),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                date == null ? label : DateFormat('yyyy/MM/dd').format(date),
                style: TextStyle(
                  color: date == null ? Colors.grey.shade700 : Colors.black,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAreaDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedArea,
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (String? newValue) =>
              setState(() => _selectedArea = newValue),
          items: _areaOptions
              .map(
                (value) =>
                    DropdownMenuItem<String>(value: value, child: Text(value)),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildEventCard(ContentItem item) {
    final status = _getEventStatus(item);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => EventDetailPage(event: item)),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(item.imageUrl, fit: BoxFit.cover),
                  if (status.isNotEmpty)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: status == '開催中'
                              ? Colors.redAccent
                              : (status == '開催前'
                                    ? Colors.blueAccent
                                    : Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.2,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.startDate != null)
                          Text(
                            "${DateFormat('MM/dd').format(item.startDate!.toDate())} - ${DateFormat('MM/dd').format(item.endDate!.toDate())}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        if (item.area.isNotEmpty)
                          Text(
                            "エリア: ${item.area}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}