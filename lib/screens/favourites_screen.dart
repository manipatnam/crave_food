import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/favourites_provider.dart';
import '../models/favourite_model.dart';
import '../services/favourites_service.dart'; // Add this import for SortType
import 'add_favourite_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  bool _sortByName = false;

  @override
  void initState() {
    super.initState();
    // Load favourites when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavouritesProvider>(context, listen: false).loadFavourites();
    });
  }

  void _toggleSort() {
    setState(() {
      _sortByName = !_sortByName;
    });
    final provider = Provider.of<FavouritesProvider>(context, listen: false);
    provider.sortFavourites(_sortByName ? SortType.restaurantName : SortType.dateAdded);
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Favourites',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _sortByName ? Icons.sort_by_alpha : Icons.access_time,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: _toggleSort,
            tooltip: _sortByName ? 'Sort by Date' : 'Sort by Name',
          ),
        ],
      ),
      body: Consumer<FavouritesProvider>(
        builder: (context, favouritesProvider, child) {
          if (favouritesProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (favouritesProvider.favourites.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => favouritesProvider.loadFavourites(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favouritesProvider.favourites.length,
              itemBuilder: (context, index) {
                final favourite = favouritesProvider.favourites[index];
                return _buildFavouriteCard(favourite);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddFavouriteScreen(),
            ),
          );
          if (result == true && mounted) {
            Provider.of<FavouritesProvider>(context, listen: false).loadFavourites();
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Favourite'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.favorite_border,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Favourites Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start building your list of favorite restaurants and dishes!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddFavouriteScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Favourite'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavouriteCard(Favourite favourite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant name and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    favourite.restaurantName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  favourite.formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Food items
            if (favourite.foodNames.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      favourite.foodNamesPreview,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Social links
            if (favourite.hasSocialUrls) ...[
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: favourite.socialUrls.map((url) {
                        IconData iconData = Icons.link;
                        Color iconColor = Colors.blue;
                        
                        if (url.contains('instagram')) {
                          iconData = Icons.camera_alt;
                          iconColor = Colors.purple;
                        } else if (url.contains('youtube')) {
                          iconData = Icons.play_circle;
                          iconColor = Colors.red;
                        }
                        
                        return GestureDetector(
                          onTap: () => _launchUrl(url),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: iconColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(iconData, size: 14, color: iconColor),
                                const SizedBox(width: 4),
                                Text(
                                  url.contains('instagram') ? 'Instagram' :
                                  url.contains('youtube') ? 'YouTube' : 'Link',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: iconColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
            
            // Action buttons
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement edit functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit functionality coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    _showDeleteConfirmation(favourite);
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Favourite favourite) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Favourite'),
          content: Text('Are you sure you want to remove "${favourite.restaurantName}" from your favourites?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<FavouritesProvider>(context, listen: false)
                    .deleteFavourite(favourite.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Favourite removed')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}