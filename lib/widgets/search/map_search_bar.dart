// FILE: lib/widgets/search/map_search_bar.dart

import 'package:flutter/material.dart';

class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final Function(String) onSearch;
  final VoidCallback onCurrentLocation;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onSearch,
    required this.onCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Search restaurants, cuisines...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                prefixIcon: isSearching
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.search,
                        color: Colors.grey[500],
                      ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          controller.clear();
                          onSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: onCurrentLocation,
              icon: Icon(
                Icons.my_location,
                color: Theme.of(context).primaryColor,
              ),
              tooltip: 'Go to current location',
            ),
          ),
        ],
      ),
    );
  }
}