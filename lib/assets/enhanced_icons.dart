// Enhanced Icons and Imagery System
// lib/assets/enhanced_icons.dart

import 'package:flutter/material.dart';

// Custom App Icons
class AppIcons {
  // Food & Restaurant Icons
  static const IconData restaurant = Icons.restaurant_rounded;
  static const IconData fastFood = Icons.fastfood_rounded;
  static const IconData pizza = Icons.local_pizza_rounded;
  static const IconData coffee = Icons.local_cafe_rounded;
  static const IconData dining = Icons.lunch_dining_rounded;
  static const IconData ramen = Icons.ramen_dining_rounded;
  static const IconData riceBowl = Icons.rice_bowl_rounded;
  static const IconData icecream = Icons.icecream_rounded;
  static const IconData bakery = Icons.bakery_dining_rounded;
  
  // Navigation Icons
  static const IconData home = Icons.home_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData profile = Icons.person_rounded;
  static const IconData map = Icons.map_rounded;
  static const IconData location = Icons.location_on_rounded;
  
  // Action Icons
  static const IconData add = Icons.add_circle_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData delete = Icons.delete_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData save = Icons.bookmark_rounded;
  static const IconData camera = Icons.camera_alt_rounded;
  static const IconData phone = Icons.phone_rounded;
  static const IconData website = Icons.language_rounded;
  static const IconData instagram = Icons.camera_alt_rounded;
  
  // UI Icons
  static const IconData back = Icons.arrow_back_ios_rounded;
  static const IconData forward = Icons.arrow_forward_ios_rounded;
  static const IconData up = Icons.keyboard_arrow_up_rounded;
  static const IconData down = Icons.keyboard_arrow_down_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData star = Icons.star_rounded;
  static const IconData starOutline = Icons.star_outline_rounded;
  
  // Status Icons
  static const IconData open = Icons.schedule_rounded;
  static const IconData closed = Icons.schedule_rounded;
  static const IconData verified = Icons.verified_rounded;
  static const IconData warning = Icons.warning_rounded;
  static const IconData error = Icons.error_rounded;
  static const IconData info = Icons.info_rounded;
  static const IconData success = Icons.check_circle_rounded;
  
  // Filter Icons
  static const IconData filter = Icons.tune_rounded;
  static const IconData sort = Icons.sort_rounded;
  static const IconData grid = Icons.grid_view_rounded;
  static const IconData list = Icons.view_list_rounded;
  
  // Time Icons
  static const IconData time = Icons.access_time_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData schedule = Icons.schedule_rounded;
}

// Enhanced Icon Button
class EnhancedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final String? tooltip;
  final bool showBadge;
  final String? badgeText;
  final Color? badgeColor;

  const EnhancedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 24.0,
    this.padding = const EdgeInsets.all(8),
    this.borderRadius,
    this.tooltip,
    this.showBadge = false,
    this.badgeText,
    this.badgeColor,
  });

  @override
  State<EnhancedIconButton> createState() => _EnhancedIconButtonState();
}

class _EnhancedIconButtonState extends State<EnhancedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget iconButton = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            boxShadow: widget.backgroundColor != null
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );

    if (widget.showBadge) {
      iconButton = Stack(
        clipBehavior: Clip.none,
        children: [
          iconButton,
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.badgeColor ?? Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: widget.badgeText != null
                  ? Text(
                      widget.badgeText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),
          ),
        ],
      );
    }

    if (widget.tooltip != null) {
      iconButton = Tooltip(
        message: widget.tooltip!,
        child: iconButton,
      );
    }

    return iconButton;
  }
}

// Food Category Icons with Colors
class FoodCategoryIcon extends StatelessWidget {
  final String category;
  final double size;
  final Color? color;

  const FoodCategoryIcon({
    super.key,
    required this.category,
    this.size = 24,
    this.color,
  });

  static const Map<String, Map<String, dynamic>> _categoryIcons = {
    'pizza': {
      'icon': Icons.local_pizza_rounded,
      'color': Color(0xFFFF6B35),
    },
    'burger': {
      'icon': Icons.lunch_dining_rounded,
      'color': Color(0xFFFF8C42),
    },
    'sushi': {
      'icon': Icons.rice_bowl_rounded,
      'color': Color(0xFF2ECC71),
    },
    'coffee': {
      'icon': Icons.local_cafe_rounded,
      'color': Color(0xFF8B4513),
    },
    'dessert': {
      'icon': Icons.icecream_rounded,
      'color': Color(0xFFFF69B4),
    },
    'noodles': {
      'icon': Icons.ramen_dining_rounded,
      'color': Color(0xFFFFD700),
    },
    'bakery': {
      'icon': Icons.bakery_dining_rounded,
      'color': Color(0xFFDEB887),
    },
    'indian': {
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFFFF4500),
    },
    'chinese': {
      'icon': Icons.rice_bowl_rounded,
      'color': Color(0xFFDC143C),
    },
    'mexican': {
      'icon': Icons.fastfood_rounded,
      'color': Color(0xFF228B22),
    },
    'italian': {
      'icon': Icons.local_pizza_rounded,
      'color': Color(0xFF008000),
    },
    'american': {
      'icon': Icons.lunch_dining_rounded,
      'color': Color(0xFF4169E1),
    },
    'thai': {
      'icon': Icons.ramen_dining_rounded,
      'color': Color(0xFFFF6347),
    },
    'japanese': {
      'icon': Icons.rice_bowl_rounded,
      'color': Color(0xFF800080),
    },
    'korean': {
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFFFF1493),
    },
    'mediterranean': {
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFF20B2AA),
    },
    'vegetarian': {
      'icon': Icons.eco_rounded,
      'color': Color(0xFF32CD32),
    },
    'vegan': {
      'icon': Icons.grass_rounded,
      'color': Color(0xFF00FF00),
    },
    'healthy': {
      'icon': Icons.favorite_rounded,
      'color': Color(0xFF00CED1),
    },
    'fast_food': {
      'icon': Icons.fastfood_rounded,
      'color': Color(0xFFFF4500),
    },
    'fine_dining': {
      'icon': Icons.restaurant_menu_rounded,
      'color': Color(0xFF8B008B),
    },
    'casual': {
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFF4682B4),
    },
    'default': {
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFF666666),
    },
  };

  @override
  Widget build(BuildContext context) {
    final categoryData = _categoryIcons[category.toLowerCase()] ?? 
                        _categoryIcons['default']!;
    
    return Icon(
      categoryData['icon'] as IconData,
      size: size,
      color: color ?? categoryData['color'] as Color,
    );
  }
}

// Rating Stars Widget
class RatingStars extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool allowHalfRating;

  const RatingStars({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 16,
    this.activeColor,
    this.inactiveColor,
    this.allowHalfRating = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? Colors.amber[600]!;
    final inactive = inactiveColor ?? Colors.grey[300]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starRating = index + 1;
        
        if (rating >= starRating) {
          // Full star
          return Icon(
            AppIcons.star,
            size: size,
            color: active,
          );
        } else if (allowHalfRating && rating >= starRating - 0.5) {
          // Half star
          return Stack(
            children: [
              Icon(
                AppIcons.starOutline,
                size: size,
                color: inactive,
              ),
              ClipRect(
                clipper: _HalfClipper(),
                child: Icon(
                  AppIcons.star,
                  size: size,
                  color: active,
                ),
              ),
            ],
          );
        } else {
          // Empty star
          return Icon(
            AppIcons.starOutline,
            size: size,
            color: inactive,
          );
        }
      }),
    );
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}

// Status Indicator Widget
class StatusIndicator extends StatelessWidget {
  final String status;
  final double size;
  final bool showText;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 12,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'open':
        color = Colors.green;
        icon = Icons.circle;
        break;
      case 'closed':
        color = Colors.red;
        icon = Icons.circle;
        break;
      case 'busy':
        color = Colors.orange;
        icon = Icons.circle;
        break;
      case 'verified':
        color = Colors.blue;
        icon = AppIcons.verified;
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: size,
          color: color,
        ),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

// Enhanced Avatar Widget
class EnhancedAvatar extends StatelessWidget {
  final String? imageUrl;
  final IconData? icon;
  final String? initials;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const EnhancedAvatar({
    super.key,
    this.imageUrl,
    this.icon,
    this.initials,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? (icon != null
              ? Icon(icon, size: radius)
              : (initials != null
                  ? Text(
                      initials!,
                      style: TextStyle(
                        fontSize: radius * 0.6,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Icon(AppIcons.profile, size: radius)))
          : null,
    );

    if (showBorder) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? Theme.of(context).colorScheme.primary,
            width: borderWidth,
          ),
        ),
        child: avatar,
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}

// Enhanced Image Widget with Loading and Error States
class EnhancedImage extends StatefulWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? fallbackAsset;

  const EnhancedImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fallbackAsset,
  });

  @override
  State<EnhancedImage> createState() => _EnhancedImageState();
}

class _EnhancedImageState extends State<EnhancedImage> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (widget.url != null && !_hasError) {
      imageWidget = Image.network(
        widget.url!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _hasError = true;
            });
          });
          return _buildErrorWidget();
        },
      );
    } else if (widget.fallbackAsset != null) {
      imageWidget = Image.asset(
        widget.fallbackAsset!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    } else {
      imageWidget = _buildErrorWidget();
    }

    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Icon(
            Icons.image_not_supported_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 40,
          ),
        );
  }
}

// Icon Badge Widget
class IconBadge extends StatelessWidget {
  final IconData icon;
  final String? badgeText;
  final int? badgeCount;
  final Color? badgeColor;
  final Color? iconColor;
  final double iconSize;
  final VoidCallback? onTap;

  const IconBadge({
    super.key,
    required this.icon,
    this.badgeText,
    this.badgeCount,
    this.badgeColor,
    this.iconColor,
    this.iconSize = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = badgeText != null || (badgeCount != null && badgeCount! > 0);
    
    Widget iconWidget = Icon(
      icon,
      size: iconSize,
      color: iconColor ?? Theme.of(context).colorScheme.onSurface,
    );

    if (onTap != null) {
      iconWidget = GestureDetector(
        onTap: onTap,
        child: iconWidget,
      );
    }

    if (!showBadge) {
      return iconWidget;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor ?? Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              badgeText ?? badgeCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

// Animated Icon Widget
class AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final Duration duration;
  final AnimationType animationType;

  const AnimatedIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 24,
    this.duration = const Duration(milliseconds: 300),
    this.animationType = AnimationType.scale,
  });

  @override
  State<AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    switch (widget.animationType) {
      case AnimationType.scale:
        _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        );
        break;
      case AnimationType.rotation:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        break;
      case AnimationType.fade:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeIn),
        );
        break;
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.animationType) {
          case AnimationType.scale:
            return Transform.scale(
              scale: _animation.value,
              child: Icon(
                widget.icon,
                size: widget.size,
                color: widget.color,
              ),
            );
          case AnimationType.rotation:
            return Transform.rotate(
              angle: _animation.value * 2 * 3.14159,
              child: Icon(
                widget.icon,
                size: widget.size,
                color: widget.color,
              ),
            );
          case AnimationType.fade:
            return Opacity(
              opacity: _animation.value,
              child: Icon(
                widget.icon,
                size: widget.size,
                color: widget.color,
              ),
            );
        }
      },
    );
  }
}

enum AnimationType {
  scale,
  rotation,
  fade,
}

// Social Media Icon Widget
class SocialMediaIcon extends StatelessWidget {
  final SocialPlatform platform;
  final double size;
  final VoidCallback? onTap;

  const SocialMediaIcon({
    super.key,
    required this.platform,
    this.size = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: platform.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: platform.color.withOpacity(0.3),
          ),
        ),
        child: Icon(
          platform.icon,
          size: size,
          color: platform.color,
        ),
      ),
    );
  }
}

// Social Platform Enum
enum SocialPlatform {
  instagram(
    icon: Icons.camera_alt_rounded,
    color: Color(0xFFE4405F),
    name: 'Instagram',
  ),
  website(
    icon: Icons.language_rounded,
    color: Color(0xFF1DA1F2),
    name: 'Website',
  ),
  phone(
    icon: Icons.phone_rounded,
    color: Color(0xFF25D366),
    name: 'Phone',
  ),
  email(
    icon: Icons.email_rounded,
    color: Color(0xFF4285F4),
    name: 'Email',
  ),
  whatsapp(
    icon: Icons.chat_rounded,
    color: Color(0xFF25D366),
    name: 'WhatsApp',
  ),
  facebook(
    icon: Icons.facebook_rounded,
    color: Color(0xFF4267B2),
    name: 'Facebook',
  ),
  twitter(
    icon: Icons.alternate_email_rounded,
    color: Color(0xFF1DA1F2),
    name: 'Twitter',
  );

  const SocialPlatform({
    required this.icon,
    required this.color,
    required this.name,
  });

  final IconData icon;
  final Color color;
  final String name;
}

// Gradient Icon Widget
class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientIcon({
    super.key,
    required this.icon,
    required this.colors,
    this.size = 24,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: begin,
        end: end,
        colors: colors,
      ).createShader(bounds),
      child: Icon(
        icon,
        size: size,
      ),
    );
  }
}

// Image Icon Button
class ImageIconButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onPressed;
  final double size;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const ImageIconButton({
    super.key,
    required this.imagePath,
    this.onPressed,
    this.size = 24,
    this.padding = const EdgeInsets.all(8),
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          boxShadow: backgroundColor != null
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// Icon Utils
class IconUtils {
  // Get icon for food category
  static IconData getFoodCategoryIcon(String category) {
    const categoryIcons = {
      'pizza': Icons.local_pizza_rounded,
      'burger': Icons.lunch_dining_rounded,
      'sushi': Icons.rice_bowl_rounded,
      'coffee': Icons.local_cafe_rounded,
      'dessert': Icons.icecream_rounded,
      'noodles': Icons.ramen_dining_rounded,
      'bakery': Icons.bakery_dining_rounded,
      'indian': Icons.restaurant_rounded,
      'chinese': Icons.rice_bowl_rounded,
      'mexican': Icons.fastfood_rounded,
      'italian': Icons.local_pizza_rounded,
      'american': Icons.lunch_dining_rounded,
      'thai': Icons.ramen_dining_rounded,
      'japanese': Icons.rice_bowl_rounded,
      'korean': Icons.restaurant_rounded,
      'vegetarian': Icons.eco_rounded,
      'vegan': Icons.grass_rounded,
    };
    
    return categoryIcons[category.toLowerCase()] ?? Icons.restaurant_rounded;
  }

  // Get color for food category
  static Color getFoodCategoryColor(String category) {
    const categoryColors = {
      'pizza': Color(0xFFFF6B35),
      'burger': Color(0xFFFF8C42),
      'sushi': Color(0xFF2ECC71),
      'coffee': Color(0xFF8B4513),
      'dessert': Color(0xFFFF69B4),
      'noodles': Color(0xFFFFD700),
      'bakery': Color(0xFFDEB887),
      'indian': Color(0xFFFF4500),
      'chinese': Color(0xFFDC143C),
      'mexican': Color(0xFF228B22),
      'italian': Color(0xFF008000),
      'american': Color(0xFF4169E1),
      'thai': Color(0xFFFF6347),
      'japanese': Color(0xFF800080),
      'korean': Color(0xFFFF1493),
      'vegetarian': Color(0xFF32CD32),
      'vegan': Color(0xFF00FF00),
    };
    
    return categoryColors[category.toLowerCase()] ?? const Color(0xFF666666);
  }

  // Create icon with background
  static Widget createIconWithBackground({
    required IconData icon,
    required Color backgroundColor,
    Color? iconColor,
    double size = 24,
    double padding = 8,
    BorderRadius? borderRadius,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: size,
        color: iconColor ?? Colors.white,
      ),
    );
  }

  // Create gradient icon
  static Widget createGradientIcon({
    required IconData icon,
    required List<Color> colors,
    double size = 24,
  }) {
    return GradientIcon(
      icon: icon,
      colors: colors,
      size: size,
    );
  }
}