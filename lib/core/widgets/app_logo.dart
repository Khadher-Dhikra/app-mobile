import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppLogoIcon extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const AppLogoIcon({
    super.key,
    this.size = 40,
    this.backgroundColor = AppColors.primary,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.55, size * 0.55),
          painter: _RouteLogoPainter(color: iconColor),
        ),
      ),
    );
  }
}

class _RouteLogoPainter extends CustomPainter {
  final Color color;

  _RouteLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    // Route from bottom left to top right via S-curve
    final p1 = Offset(size.width * 0.22, size.height * 0.75);
    final p2 = Offset(size.width * 0.45, size.height * 0.25);
    final p3 = Offset(size.width * 0.55, size.height * 0.75);
    final p4 = Offset(size.width * 0.78, size.height * 0.25);

    path.moveTo(p1.dx, p1.dy);
    path.cubicTo(p2.dx, p2.dy, p3.dx, p3.dy, p4.dx, p4.dy);

    canvas.drawPath(path, paintLine);

    final dotRadius = size.width * 0.14;
    canvas.drawCircle(p1, dotRadius, paintDot);
    canvas.drawCircle(p4, dotRadius, paintDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isHorizontal;
  final bool isLight;
  final String? subtitle;

  const AppLogo({
    super.key,
    this.size = 38,
    this.showText = true,
    this.isHorizontal = true,
    this.isLight = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = AppLogoIcon(
      size: size,
      backgroundColor: isLight ? Colors.white.withAlpha(40) : AppColors.primary,
      iconColor: Colors.white,
    );

    if (!showText) {
      return iconWidget;
    }

    final textColor = isLight ? Colors.white : AppColors.textPrimary;
    final textStyle = GoogleFonts.outfit(
      fontSize: size * 0.65,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: textColor,
    );

    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('tawsila', style: textStyle),
              if (subtitle != null) ...[
                Text(
                  subtitle!,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: isLight ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(height: 10),
        Text('tawsila', style: textStyle),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: isLight ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
