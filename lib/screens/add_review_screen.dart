// lib/screens/add_review_screen.dart

import 'dart:math' as math; // For Math.max in reviews_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/google_places_services.dart';
import '../services/reviews_service.dart';
import '../services/restaurants_service.dart';
import '../models/place_model.dart';
import '../models/restaurant_review.dart';
import '../models/dish_review.dart';
import '../models/review_enums.dart';
import '../widgets/add_review/restaurant_search_section.dart';
import '../widgets/add_review/selected_restaurant_card.dart';
import '../widgets/add_review/rating_section.dart';
import '../widgets/add_review/dish_reviews_section.dart';
import '../widgets/add_review/visit_context_section.dart';
import '../widgets/add_review/written_review_section.dart';
import '../widgets/add_review/privacy_section.dart';
import '../widgets/add_review/submit_review_button.dart';

class AddReviewScreen extends StatefulWidget {
  final PlaceModel? initialPlace; // If coming from restaurant detail page
  
  const AddReviewScreen({
    super.key,
    this.initialPlace,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final GooglePlacesService _placesService = GooglePlacesService();
  final ReviewsService _reviewsService = ReviewsService();
  final RestaurantsService _restaurantsService = RestaurantsService();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Selected restaurant
  PlaceModel? _selectedPlace;
  
  // Multi-dimensional ratings
  double _foodRating = 3.0;
  double _serviceRating = 3.0;
  double _ambienceRating = 3.0;
  double _valueRating = 3.0;
  double _overallRating = 3.0;
  bool _autoCalculateOverall = true;
  
  // Dish reviews
  final List<DishReview> _dishReviews = [];
  
  // Visit context
  DateTime _visitDate = DateTime.now();
  VisitType _visitType = VisitType.casual;
  MealTime _mealTime = MealTime.dinner;
  Occasion _occasion = Occasion.casual;
  
  // Content
  final TextEditingController _writtenReviewController = TextEditingController();
  
  // Privacy
  ReviewPrivacy _privacy = ReviewPrivacy.public;
  
  // Form state
  bool _isSubmitting = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize with provided place if any
    if (widget.initialPlace != null) {
      _selectedPlace = widget.initialPlace;
    }
    
    // Update overall rating when individual ratings change
    _updateOverallRating();
    
    // Track unsaved changes
    _writtenReviewController.addListener(() {
      _markUnsavedChanges();
    });
  }

  @override
  void dispose() {
    _writtenReviewController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Write Review',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          if (_hasUnsavedChanges)
            TextButton(
              onPressed: _clearForm,
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant Selection
                RestaurantSearchSection(
                  selectedPlace: _selectedPlace,
                  onPlaceSelected: _onRestaurantSelected,
                  placesService: _placesService,
                ),
                
                if (_selectedPlace != null) ...[
                  const SizedBox(height: 16),
                  
                  // Selected Restaurant Card
                  SelectedRestaurantCard(
                    selectedPlace: _selectedPlace!,
                    onClear: () => _onRestaurantSelected(null),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Multi-Dimensional Rating Section
                  RatingSection(
                    foodRating: _foodRating,
                    serviceRating: _serviceRating,
                    ambienceRating: _ambienceRating,
                    valueRating: _valueRating,
                    overallRating: _overallRating,
                    autoCalculateOverall: _autoCalculateOverall,
                    onFoodRatingChanged: (rating) {
                      setState(() {
                        _foodRating = rating;
                        _updateOverallRating();
                        _markUnsavedChanges();
                      });
                    },
                    onServiceRatingChanged: (rating) {
                      setState(() {
                        _serviceRating = rating;
                        _updateOverallRating();
                        _markUnsavedChanges();
                      });
                    },
                    onAmbienceRatingChanged: (rating) {
                      setState(() {
                        _ambienceRating = rating;
                        _updateOverallRating();
                        _markUnsavedChanges();
                      });
                    },
                    onValueRatingChanged: (rating) {
                      setState(() {
                        _valueRating = rating;
                        _updateOverallRating();
                        _markUnsavedChanges();
                      });
                    },
                    onOverallRatingChanged: (rating) {
                      setState(() {
                        _overallRating = rating;
                        _autoCalculateOverall = false;
                        _markUnsavedChanges();
                      });
                    },
                    onAutoCalculateToggled: (auto) {
                      setState(() {
                        _autoCalculateOverall = auto;
                        if (auto) _updateOverallRating();
                        _markUnsavedChanges();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Dish Reviews Section (Optional)
                  DishReviewsSection(
                    dishReviews: _dishReviews,
                    onDishAdded: _addDishReview,
                    onDishRemoved: _removeDishReview,
                    onDishUpdated: _updateDishReview,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Visit Context Section
                  VisitContextSection(
                    visitDate: _visitDate,
                    visitType: _visitType,
                    mealTime: _mealTime,
                    occasion: _occasion,
                    onVisitDateChanged: (date) {
                      setState(() {
                        _visitDate = date;
                        _markUnsavedChanges();
                      });
                    },
                    onVisitTypeChanged: (type) {
                      setState(() {
                        _visitType = type;
                        _markUnsavedChanges();
                      });
                    },
                    onMealTimeChanged: (mealTime) {
                      setState(() {
                        _mealTime = mealTime;
                        _markUnsavedChanges();
                      });
                    },
                    onOccasionChanged: (occasion) {
                      setState(() {
                        _occasion = occasion;
                        _markUnsavedChanges();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Written Review Section
                  WrittenReviewSection(
                    controller: _writtenReviewController,
                    onChanged: _markUnsavedChanges,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Privacy Section
                  PrivacySection(
                    privacy: _privacy,
                    onPrivacyChanged: (privacy) {
                      setState(() {
                        _privacy = privacy;
                        _markUnsavedChanges();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  SubmitReviewButton(
                    isSubmitting: _isSubmitting,
                    onSubmit: _submitReview,
                    isEnabled: _isFormValid(),
                  ),
                  
                  const SizedBox(height: 32), // Bottom padding
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Event Handlers
  void _onRestaurantSelected(PlaceModel? place) {
    setState(() {
      _selectedPlace = place;
      _markUnsavedChanges();
    });
  }

  void _addDishReview() {
    setState(() {
      _dishReviews.add(DishReview(
        dishName: '',
        rating: 3.0,
      ));
      _markUnsavedChanges();
    });
  }

  void _removeDishReview(int index) {
    setState(() {
      if (index >= 0 && index < _dishReviews.length) {
        _dishReviews.removeAt(index);
        _markUnsavedChanges();
      }
    });
  }

  void _updateDishReview(int index, DishReview updatedDish) {
    setState(() {
      if (index >= 0 && index < _dishReviews.length) {
        _dishReviews[index] = updatedDish;
        _markUnsavedChanges();
      }
    });
  }

  void _updateOverallRating() {
    if (_autoCalculateOverall) {
      setState(() {
        _overallRating = (_foodRating + _serviceRating + _ambienceRating + _valueRating) / 4.0;
      });
    }
  }

  void _markUnsavedChanges() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  bool _isFormValid() {
    return _selectedPlace != null && 
           _writtenReviewController.text.trim().isNotEmpty;
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate() || !_isFormValid()) {
      _showErrorSnackBar('Please complete all required fields');
      return;
    }

    if (_selectedPlace == null) {
      _showErrorSnackBar('Please select a restaurant');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // First, ensure restaurant exists in our system
      await _restaurantsService.getOrCreateRestaurant(_selectedPlace!.placeId);

      // Create review object
      final review = RestaurantReview(
        id: '', // Will be set by service
        restaurantId: _selectedPlace!.placeId,
        userId: '', // Will be set by service
        restaurantName: _selectedPlace!.name,
        restaurantAddress: _selectedPlace!.displayAddress,
        restaurantCoordinates: _selectedPlace!.geoPoint,
        userName: '', // Will be set by service
        ratings: ReviewRatings(
          foodRating: _foodRating,
          serviceRating: _serviceRating,
          ambienceRating: _ambienceRating,
          valueRating: _valueRating,
          overallRating: _overallRating,
        ),
        dishReviews: _dishReviews.where((dish) => dish.dishName.isNotEmpty).toList(),
        writtenReview: _writtenReviewController.text.trim(),
        visitDate: _visitDate,
        visitType: _visitType,
        mealTime: _mealTime,
        occasion: _occasion,
        privacy: _privacy,
        reviewDate: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      // Submit review
      final reviewId = await _reviewsService.addReview(review);

      // Update restaurant stats
      await _restaurantsService.updateRestaurantStats(_selectedPlace!.placeId);

      // Show success and navigate
      _showSuccessSnackBar('Review submitted successfully!');
      
      // Clear form
      _clearForm();
      
      // Navigate to reviews tab to see the new review
      // You might want to navigate differently based on your navigation structure
      
    } catch (e) {
      _showErrorSnackBar('Failed to submit review: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _selectedPlace = null;
      _foodRating = 3.0;
      _serviceRating = 3.0;
      _ambienceRating = 3.0;
      _valueRating = 3.0;
      _overallRating = 3.0;
      _autoCalculateOverall = true;
      _dishReviews.clear();
      _visitDate = DateTime.now();
      _visitType = VisitType.casual;
      _mealTime = MealTime.dinner;
      _occasion = Occasion.casual;
      _writtenReviewController.clear();
      _privacy = ReviewPrivacy.public;
      _hasUnsavedChanges = false;
    });
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Are you sure you want to leave?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
    }
    return true;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}