// Enhanced Layouts and Responsive Design
// lib/layouts/enhanced_layouts.dart

import 'package:flutter/material.dart';

// Responsive Layout Helper
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 768) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

// Enhanced Padding System
class AppPadding {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Screen edge padding
  static EdgeInsets get screenPadding => const EdgeInsets.all(md);
  static EdgeInsets get screenHorizontal => const EdgeInsets.symmetric(horizontal: md);
  static EdgeInsets get screenVertical => const EdgeInsets.symmetric(vertical: md);

  // Card padding
  static EdgeInsets get cardPadding => const EdgeInsets.all(lg);
  static EdgeInsets get cardSmall => const EdgeInsets.all(md);

  // Section padding
  static EdgeInsets get sectionPadding => const EdgeInsets.symmetric(vertical: xl);
  static EdgeInsets get betweenSections => const EdgeInsets.only(bottom: xl);
}

// Enhanced Spacing System
class AppSpacing {
  static const SizedBox xs = SizedBox(height: AppPadding.xs);
  static const SizedBox sm = SizedBox(height: AppPadding.sm);
  static const SizedBox md = SizedBox(height: AppPadding.md);
  static const SizedBox lg = SizedBox(height: AppPadding.lg);
  static const SizedBox xl = SizedBox(height: AppPadding.xl);
  static const SizedBox xxl = SizedBox(height: AppPadding.xxl);

  // Horizontal spacing
  static const SizedBox horizontalXs = SizedBox(width: AppPadding.xs);
  static const SizedBox horizontalSm = SizedBox(width: AppPadding.sm);
  static const SizedBox horizontalMd = SizedBox(width: AppPadding.md);
  static const SizedBox horizontalLg = SizedBox(width: AppPadding.lg);
  static const SizedBox horizontalXl = SizedBox(width: AppPadding.xl);
}

// Enhanced Container with Smart Padding
class SmartContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final bool adaptivePadding;

  const SmartContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.adaptivePadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    EdgeInsets effectivePadding = padding ?? AppPadding.screenPadding;
    
    if (adaptivePadding) {
      if (screenWidth > 1200) {
        effectivePadding = EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1,
          vertical: effectivePadding.vertical,
        );
      } else if (screenWidth > 768) {
        effectivePadding = EdgeInsets.symmetric(
          horizontal: AppPadding.xl,
          vertical: effectivePadding.vertical,
        );
      }
    }

    return Container(
      padding: effectivePadding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

// Enhanced Grid Layout
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = mobileColumns;
        
        if (constraints.maxWidth >= 1200) {
          columns = desktopColumns;
        } else if (constraints.maxWidth >= 768) {
          columns = tabletColumns;
        }

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

// Enhanced List Layout with Better Spacing
class EnhancedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final double spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const EnhancedListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.spacing = 16.0,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      padding: padding ?? AppPadding.screenPadding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) => children[index],
    );
  }
}

// Enhanced Form Layout
class EnhancedFormLayout extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final EdgeInsets? padding;
  final CrossAxisAlignment crossAxisAlignment;

  const EnhancedFormLayout({
    super.key,
    required this.children,
    this.spacing = 24.0,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? AppPadding.screenPadding,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: _buildChildrenWithSpacing(),
      ),
    );
  }

  List<Widget> _buildChildrenWithSpacing() {
    final spacedChildren = <Widget>[];
    
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(height: spacing));
      }
    }
    
    return spacedChildren;
  }
}

// Enhanced Card Layout
class EnhancedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final bool adaptiveWidth;

  const EnhancedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.border,
    this.onTap,
    this.adaptiveWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardChild = Container(
      padding: padding ?? AppPadding.cardPadding,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: border,
        boxShadow: elevation != null
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: elevation! * 2,
                  offset: Offset(0, elevation!),
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
      ),
      child: child,
    );

    if (adaptiveWidth) {
      return LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = 600;
          if (constraints.maxWidth > 768) {
            maxWidth = constraints.maxWidth * 0.7;
          }
          
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: cardChild,
            ),
          );
        },
      );
    }

    if (onTap != null) {
      cardChild = GestureDetector(
        onTap: onTap,
        child: cardChild,
      );
    }

    return cardChild;
  }
}

// Enhanced Section Layout
class EnhancedSection extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsets? padding;
  final bool showDivider;

  const EnhancedSection({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.icon,
    this.trailing,
    this.padding,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? AppPadding.sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || subtitle != null) ...[
            _buildSectionHeader(context),
            AppSpacing.lg,
          ],
          child,
          if (showDivider) ...[
            AppSpacing.xl,
            Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              thickness: 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          AppSpacing.horizontalMd,
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (subtitle != null) ...[
                AppSpacing.xs,
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// Enhanced App Bar Layout
class EnhancedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final double? elevation;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const EnhancedAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 2,
      leading: leading ?? (showBackButton ? _buildBackButton(context) : null),
      actions: actions != null ? [
        ...actions!,
        AppSpacing.horizontalSm,
      ] : null,
      titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Enhanced Bottom Sheet Layout
class EnhancedBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool isDismissible;
  final bool enableDrag;
  final double? height;
  final EdgeInsets? padding;

  const EnhancedBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.isDismissible = true,
    this.enableDrag = true,
    this.height,
    this.padding,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    double? height,
    EdgeInsets? padding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedBottomSheet(
        title: title,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        height: height,
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final effectiveHeight = height ?? screenHeight * 0.7;

    return Container(
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          if (enableDrag) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
          
          // Title section
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isDismissible)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            ),
            Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              height: 1,
            ),
          ],
          
          // Content
          Expanded(
            child: Padding(
              padding: padding ?? AppPadding.screenPadding,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Tab Layout
class EnhancedTabView extends StatefulWidget {
  final List<EnhancedTab> tabs;
  final int initialIndex;
  final Function(int)? onTabChanged;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;

  const EnhancedTabView({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.onTabChanged,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
  });

  @override
  State<EnhancedTabView> createState() => _EnhancedTabViewState();
}

class _EnhancedTabViewState extends State<EnhancedTabView>
    with TickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: widget.tabs.length,
      initialIndex: widget.initialIndex,
      vsync: this,
    );
    _controller.addListener(() {
      if (widget.onTabChanged != null) {
        widget.onTabChanged!(_controller.index);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          margin: AppPadding.screenHorizontal,
          child: TabBar(
            controller: _controller,
            indicatorColor: widget.indicatorColor ?? Theme.of(context).colorScheme.primary,
            labelColor: widget.labelColor ?? Theme.of(context).colorScheme.primary,
            unselectedLabelColor: widget.unselectedLabelColor ?? 
                Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            tabs: widget.tabs.map((tab) => Tab(
              icon: tab.icon != null ? Icon(tab.icon, size: 20) : null,
              text: tab.label,
            )).toList(),
          ),
        ),
        AppSpacing.lg,
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: widget.tabs.map((tab) => tab.content).toList(),
          ),
        ),
      ],
    );
  }
}

class EnhancedTab {
  final String label;
  final IconData? icon;
  final Widget content;

  const EnhancedTab({
    required this.label,
    this.icon,
    required this.content,
  });
}

// Enhanced Scaffold with Smart Layout
class EnhancedScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;

  const EnhancedScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Add adaptive constraints for very wide screens
            if (constraints.maxWidth > 1200) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: body,
                ),
              );
            }
            return body;
          },
        ),
      ),
    );
  }
}

// Layout Utilities
class LayoutUtils {
  // Get responsive value based on screen size
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      return desktop ?? tablet ?? mobile;
    } else if (screenWidth >= 768) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  // Get responsive columns count
  static int getColumnsCount(BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    return responsive(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return responsive(
      context,
      mobile: AppPadding.screenPadding,
      tablet: const EdgeInsets.all(AppPadding.xl),
      desktop: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.1,
        vertical: AppPadding.xl,
      ),
    );
  }

  // Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double base,
    double? tablet,
    double? desktop,
  }) {
    return responsive(
      context,
      mobile: base,
      tablet: tablet ?? base * 1.1,
      desktop: desktop ?? base * 1.2,
    );
  }
}

// Smart Spacing Widget
class SmartSpacing extends StatelessWidget {
  final double mobile;
  final double? tablet;
  final double? desktop;
  final bool horizontal;

  const SmartSpacing({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = LayoutUtils.responsive(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );

    return SizedBox(
      height: horizontal ? 0 : spacing,
      width: horizontal ? spacing : 0,
    );
  }
}