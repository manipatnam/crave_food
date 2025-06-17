import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/favourites_provider.dart';
import '../models/favourite_model.dart';
import '../services/favourites_service.dart';
import 'add_favourite_screen.dart';
import '../widgets/favourites/favourites_app_bar.dart';
import '../widgets/favourites/favourites_loading_state.dart';
import '../widgets/favourites/favourites_error_state.dart';
import '../widgets/favourites/favourites_empty_state.dart';
import '../widgets/favourites/favourites_list.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen>
    with TickerProviderStateMixin {
  bool _sortByName = false;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavouritesProvider>(context, listen: false).loadFavourites();
      _fabController.forward();
    });
  }

  void _initializeAnimations() {
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
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
          _showSnackBar('Could not launch $url', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error opening link: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showDeleteConfirmation(Favourite favourite) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Delete Favourite',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to remove "${favourite.restaurantName}" from your favourites?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<FavouritesProvider>(context, listen: false)
                    .deleteFavourite(favourite.id);
                _showSnackBar('Favourite removed successfully');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToAddFavourite() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddFavouriteScreen(),
      ),
    );
    
    if (result == true && mounted) {
      Provider.of<FavouritesProvider>(context, listen: false).loadFavourites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          FavouritesAppBar(
            sortByName: _sortByName,
            onToggleSort: _toggleSort,
          ),
          SliverToBoxAdapter(
            child: Consumer<FavouritesProvider>(
              builder: (context, favouritesProvider, child) {
                if (favouritesProvider.isLoading) {
                  return const FavouritesLoadingState();
                }

                if (favouritesProvider.errorMessage != null) {
                  return FavouritesErrorState(
                    errorMessage: favouritesProvider.errorMessage!,
                    onRetry: () {
                      favouritesProvider.clearError();
                      favouritesProvider.loadFavourites();
                    },
                  );
                }

                if (favouritesProvider.favourites.isEmpty) {
                  return FavouritesEmptyState(
                    onAddFavourite: _navigateToAddFavourite,
                  );
                }

                return FavouritesList(
                  favourites: favouritesProvider.favourites,
                  onLaunchUrl: _launchUrl,
                  onDeleteFavourite: _showDeleteConfirmation,
                  onEditFavourite: (favourite) {
                    _showSnackBar('Edit functionality coming soon!');
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _navigateToAddFavourite,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Favourite'),
          elevation: 8,
        ),
      ),
    );
  }
}