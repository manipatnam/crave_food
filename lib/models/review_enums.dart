// lib/models/review_enums.dart

enum ReviewPrivacy {
  public,
  friends,
  private;

  String get displayName {
    switch (this) {
      case ReviewPrivacy.public:
        return 'Public';
      case ReviewPrivacy.friends:
        return 'Friends Only';
      case ReviewPrivacy.private:
        return 'Private';
    }
  }

  String get description {
    switch (this) {
      case ReviewPrivacy.public:
        return 'Everyone can see this review';
      case ReviewPrivacy.friends:
        return 'Only your friends can see this review';
      case ReviewPrivacy.private:
        return 'Only you can see this review';
    }
  }
}

enum VisitType {
  solo,
  date,
  family,
  business,
  casual,
  friends;

  String get displayName {
    switch (this) {
      case VisitType.solo:
        return 'Solo';
      case VisitType.date:
        return 'Date';
      case VisitType.family:
        return 'Family';
      case VisitType.business:
        return 'Business';
      case VisitType.friends:
        return 'Friends';
      case VisitType.casual:
        return 'Casual';
    }
  }

  String get emoji {
    switch (this) {
      case VisitType.solo:
        return '🚶';
      case VisitType.date:
        return '💕';
      case VisitType.family:
        return '👨‍👩‍👧‍👦';
      case VisitType.business:
        return '💼';
      case VisitType.friends:
        return '👥';
      case VisitType.casual:
        return '😊';
    }
  }
}

enum MealTime {
  breakfast,
  lunch,
  dinner,
  lateNight;

  String get displayName {
    switch (this) {
      case MealTime.breakfast:
        return 'Breakfast';
      case MealTime.lunch:
        return 'Lunch';
      case MealTime.dinner:
        return 'Dinner';
      case MealTime.lateNight:
        return 'Late Night';
    }
  }

  String get emoji {
    switch (this) {
      case MealTime.breakfast:
        return '🌅';
      case MealTime.lunch:
        return '☀️';
      case MealTime.dinner:
        return '🌙';
      case MealTime.lateNight:
        return '🌃';
    }
  }

  String get timeRange {
    switch (this) {
      case MealTime.breakfast:
        return '6:00 AM - 11:00 AM';
      case MealTime.lunch:
        return '11:00 AM - 4:00 PM';
      case MealTime.dinner:
        return '4:00 PM - 10:00 PM';
      case MealTime.lateNight:
        return '10:00 PM - 6:00 AM';
    }
  }
}

enum Occasion {
  casual,
  birthday,
  business,
  special,
  celebration,
  anniversary;

  String get displayName {
    switch (this) {
      case Occasion.casual:
        return 'Casual';
      case Occasion.birthday:
        return 'Birthday';
      case Occasion.business:
        return 'Business';
      case Occasion.special:
        return 'Special';
      case Occasion.celebration:
        return 'Celebration';
      case Occasion.anniversary:
        return 'Anniversary';
    }
  }

  String get emoji {
    switch (this) {
      case Occasion.casual:
        return '😊';
      case Occasion.birthday:
        return '🎂';
      case Occasion.business:
        return '🤝';
      case Occasion.special:
        return '✨';
      case Occasion.celebration:
        return '🎉';
      case Occasion.anniversary:
        return '💖';
    }
  }
}

// Helper functions for enum conversion
class ReviewEnumUtils {
  // Convert string to ReviewPrivacy enum
  static ReviewPrivacy? reviewPrivacyFromString(String? value) {
    if (value == null) return null;
    try {
      return ReviewPrivacy.values.firstWhere(
        (e) => e.toString().split('.').last == value,
      );
    } catch (e) {
      return null;
    }
  }

  // Convert string to VisitType enum
  static VisitType? visitTypeFromString(String? value) {
    if (value == null) return null;
    try {
      return VisitType.values.firstWhere(
        (e) => e.toString().split('.').last == value,
      );
    } catch (e) {
      return null;
    }
  }

  // Convert string to MealTime enum
  static MealTime? mealTimeFromString(String? value) {
    if (value == null) return null;
    try {
      return MealTime.values.firstWhere(
        (e) => e.toString().split('.').last == value,
      );
    } catch (e) {
      return null;
    }
  }

  // Convert string to Occasion enum
  static Occasion? occasionFromString(String? value) {
    if (value == null) return null;
    try {
      return Occasion.values.firstWhere(
        (e) => e.toString().split('.').last == value,
      );
    } catch (e) {
      return null;
    }
  }

  // Convert enum to string for storage
  static String enumToString(dynamic enumValue) {
    return enumValue.toString().split('.').last;
  }
}