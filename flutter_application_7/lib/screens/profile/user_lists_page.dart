import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/backend_service.dart';
import 'create_list_page.dart';

class UserListsPage extends StatefulWidget {
  const UserListsPage({super.key});

  @override
  State<UserListsPage> createState() => _UserListsPageState();
}

class _UserListsPageState extends State<UserListsPage> {
  final BackendService backend = BackendService();

  List<dynamic> userLists = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      final lists = await backend.getUserLists(token);

      setState(() {
        userLists = lists;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading lists: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateListPage()),
          ).then((_) => _loadLists());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userLists.isEmpty
              ? _buildEmptyState()
              : _buildListGrid(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list_alt, size: 100, color: Colors.white10),
          SizedBox(height: 16),
          Text(
            "No lists yet",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          Text(
            "Tap + to create your first movie collection",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildListGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: userLists.length,
      itemBuilder: (context, index) {
        final list = userLists[index];

        return Card(
          color: const Color(0xFF2C2F33),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list['name'] ?? "",
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  list['description'] ?? "",
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 12),

                // ✅ MOVIE POSTERS
                if (list['movies'] != null &&
                    list['movies'].isNotEmpty)
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: list['movies'].length,
                      itemBuilder: (_, i) {
                        final movie = list['movies'][i];
                        final posterPath = movie['poster_path'];

                        return Padding(
                          padding:
                              const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8),
                            child: Image.network(
                              posterPath != null &&
                                      posterPath.isNotEmpty
                                  ? "https://image.tmdb.org/t/p/w500$posterPath"
                                  : "https://via.placeholder.com/300x450?text=No+Poster",
                              width: 110,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                width: 110,
                                color: Colors.black26,
                                child: const Icon(
                                  Icons.movie,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
