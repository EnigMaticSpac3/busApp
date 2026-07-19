import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';

class StopMarker extends StatelessWidget {
  final int? orden;
  final double size;
  final bool showNumber;

  const StopMarker({
    super.key,
    this.orden,
    this.size = 12.0,
    this.showNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [AppShadows.shadowSm],
      ),
      child: (showNumber && orden != null)
          ? Center(
              child: Text(
                '$orden',
                style: TextStyle(
                  fontSize: size * 0.6,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            )
          : null,
    );
  }
}
