import 'dart:ui';

import 'package:flutter/material.dart';

class GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const GlassButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: .18),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
