import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.size = 44});

  final String category;
  final double size;

  static const _map = <String, (IconData, Color)>{
    'food': (Icons.restaurant_rounded, Color(0xFFFF6B6B)),
    'groceries': (Icons.shopping_basket_rounded, Color(0xFF55EFC4)),
    'transport': (Icons.directions_car_rounded, Color(0xFF74B9FF)),
    'shopping': (Icons.shopping_bag_rounded, Color(0xFFFD79A8)),
    'rent': (Icons.home_rounded, Color(0xFFFFC857)),
    'utilities': (Icons.bolt_rounded, Color(0xFFFAB1A0)),
    'entertainment': (Icons.movie_rounded, Color(0xFFA29BFE)),
    'travel': (Icons.flight_takeoff_rounded, Color(0xFF44C4FF)),
    'health': (Icons.favorite_rounded, Color(0xFFE17055)),
    'gifts': (Icons.card_giftcard_rounded, Color(0xFF00B894)),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _map[category] ?? (Icons.category_rounded, const Color(0xFF6C5CE7));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.25), color.withOpacity(0.10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
