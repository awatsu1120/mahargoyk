// lib/pages/course_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_item.dart';
import '../models/content_item.dart';
import '../services/firestore_service.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';
import 'map_page.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;

  const CourseDetailPage({super.key, required this.courseId});

  @override
  CourseDetailPageState createState() => CourseDetailPageState();
}

class CourseDetailPageState extends State<CourseDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;
  late Future<CourseItem> _courseFuture;

  @override
  void initState() {
    super.initState();
    _courseFuture = _firestoreService.getCourseWithSpots(widget.courseId);
  }

  void _navigateToMapPage(ContentItem spot) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => MapPage(initialSpot: spot)));
  }

  Widget _buildTransportLink(String accessInfo) {
    if (accessInfo.trim().isEmpty) {
      accessInfo = "次のスポットへ";
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 70.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_walk, color: Colors.blueAccent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              accessInfo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotCard(BuildContext context, ContentItem spot) {
    final spotLocation = LatLng(spot.latitude, spot.longitude);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(spot.imageUrl, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spot.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  spot.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        spot.address,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: spotLocation,
                initialZoom: 16.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: spotLocation,
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToMapPage(spot),
                icon: const Icon(Icons.map),
                label: const Text('マップで見る'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
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
        child: FutureBuilder<CourseItem>(
          future: _courseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('コースが見つかりません。'));
            }

            final course = snapshot.data!;

            return Center(
              child: SizedBox(
                width: 720,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        course.imageUrl,
                        fit: BoxFit.cover,
                        height: 250,
                        width: double.infinity,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    course.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (_user != null)
                                  StreamBuilder<bool>(
                                    stream: _firestoreService.isFavorite(
                                      'courses',
                                      course.id,
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
                                              'courses',
                                              course.id,
                                            );
                                          } else {
                                            _firestoreService.addFavorite(
                                              'courses',
                                              course.id,
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              course.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const Divider(height: 32),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: course.spots.length,
                        itemBuilder: (context, index) {
                          final spot = course.spots[index];
                          return Column(
                            children: [
                              if (index > 0) _buildTransportLink(spot.access),
                              _buildSpotCard(context, spot),
                              if (index == course.spots.length - 1)
                                const SizedBox(height: 32),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ), 
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
    );
  }
}