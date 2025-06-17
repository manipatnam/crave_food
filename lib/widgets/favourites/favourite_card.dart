import 'package:flutter/material.dart';
import '../../models/favourite_model.dart';
import 'favourite_card_header.dart';
import 'favourite_card_content.dart';

class FavouriteCard extends StatelessWidget {
  final Favourite favourite;
  final Function(String) onLaunchUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FavouriteCard({
    super.key,
    required this.favourite,
    required this.onLaunchUrl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant image and header
          FavouriteCardHeader(favourite: favourite),
          
          // Content section
          FavouriteCardContent(
            favourite: favourite,
            onLaunchUrl: onLaunchUrl,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}