import 'package:flutter/material.dart';
import '../../models/favourite_model.dart';
import 'favourites_stats_card.dart';
import 'favourite_card.dart';

class FavouritesList extends StatelessWidget {
  final List<Favourite> favourites;
  final Function(String) onLaunchUrl;
  final Function(Favourite) onDeleteFavourite;
  final Function(Favourite) onEditFavourite;

  const FavouritesList({
    super.key,
    required this.favourites,
    required this.onLaunchUrl,
    required this.onDeleteFavourite,
    required this.onEditFavourite,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats card
          FavouritesStatsCard(favouritesCount: favourites.length),
          
          const SizedBox(height: 20),

          // Favourites list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: favourites.length,
            itemBuilder: (context, index) {
              return FavouriteCard(
                favourite: favourites[index],
                onLaunchUrl: onLaunchUrl,
                onEdit: () => onEditFavourite(favourites[index]),
                onDelete: () => onDeleteFavourite(favourites[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}