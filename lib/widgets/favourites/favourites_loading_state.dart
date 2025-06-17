import 'package:flutter/material.dart';

class FavouritesLoadingState extends StatelessWidget {
  const FavouritesLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading your favourites...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}