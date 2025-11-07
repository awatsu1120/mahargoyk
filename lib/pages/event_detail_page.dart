// lib/pages/event_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/content_item.dart';
import '../services/firestore_service.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/header.dart';
import 'map_page.dart';

class EventDetailPage extends StatefulWidget {
  final ContentItem event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  void _navigateToMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapPage(initialSpot: widget.event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formatDate(DateTime? date) {
      if (date == null) return '未定';
      return DateFormat('yyyy年M月d日').format(date);
    }

    final startDate = widget.event.startDate?.toDate();
    final endDate = widget.event.endDate?.toDate();
    final eventLocation = LatLng(widget.event.latitude, widget.event.longitude);

    String periodText;
    if (startDate != null && endDate != null) {
      if (startDate.isAtSameMomentAs(endDate)) {
        periodText = formatDate(startDate);
      } else {
        periodText = '${formatDate(startDate)} ～ ${formatDate(endDate)}';
      }
    } else {
      periodText = '開催期間未定';
    }

    return Scaffold(
      appBar: const AppHeader(),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.event.imageUrl.isNotEmpty)
                    Align(
                      alignment: Alignment.center,
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.network(
                          widget.event.imageUrl,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.event.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (_user != null)
                              StreamBuilder<bool>(
                                stream: _firestoreService.isFavorite(
                                  'events',
                                  widget.event.id,
                                ),
                                builder: (context, snapshot) {
                                  final isFavorited = snapshot.data ?? false;
                                  return IconButton(
                                    icon: Icon(
                                      isFavorited
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorited
                                          ? Colors.red
                                          : Colors.grey,
                                      size: 30,
                                    ),
                                    onPressed: () {
                                      if (isFavorited) {
                                        _firestoreService.removeFavorite(
                                          'events',
                                          widget.event.id,
                                        );
                                      } else {
                                        _firestoreService.addFavorite(
                                          'events',
                                          widget.event.id,
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildInfoSection(
                          context,
                          icon: Icons.calendar_today,
                          title: '開催期間',
                          content: periodText,
                        ),
                        _buildInfoSection(
                          context,
                          icon: Icons.access_time,
                          title: '開催時間',
                          content: widget.event.hours,
                        ),
                        _buildInfoSection(
                          context,
                          icon: Icons.local_attraction,
                          title: '料金',
                          content: widget.event.price,
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'イベント詳細',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.event.description,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.6),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'アクセス',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoSection(
                          context,
                          icon: Icons.location_on,
                          title: '住所',
                          content: widget.event.address,
                        ),
                        _buildInfoSection(
                          context,
                          icon: Icons.train,
                          title: 'アクセス',
                          content: widget.event.access,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '開催場所',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: eventLocation,
                              initialZoom: 16.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: eventLocation,
                                    width: 80,
                                    height: 80,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToMap(context),
                            icon: const Icon(Icons.map),
                            label: const Text('マップで見る'),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ), 
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 2),
                Text(content, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}