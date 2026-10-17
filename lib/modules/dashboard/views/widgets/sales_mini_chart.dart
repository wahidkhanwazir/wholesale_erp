import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../models/dashboard_day_sales.dart';

class SalesMiniChart extends StatefulWidget {
  final List<DashboardDaySales> data;

  const SalesMiniChart({super.key, required this.data});

  @override
  State<SalesMiniChart> createState() => _SalesMiniChartState();
}

class _SalesMiniChartState extends State<SalesMiniChart> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final totalWeekSales = data.fold(0.0, (sum, e) => sum + e.amount);
    final maxAmount = data.isEmpty
        ? 0.0
        : data.map((e) => e.amount).reduce(max);

    final (maxY, stepY) = _calculateYAxis(maxAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title, subtitle, and total turnover badge
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Sales Performance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Last 7 days turnover across wholesale orders',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Total: ${CurrencyFormatter.format(totalWeekSales)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Spline Area Chart with Hover interaction
          SizedBox(
            height: 200,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MouseRegion(
                  onHover: (event) {
                    if (data.isEmpty) return;
                    const leftPadding = 58.0;
                    const rightPadding = 18.0;
                    final chartWidth =
                        constraints.maxWidth - leftPadding - rightPadding;
                    if (chartWidth <= 0) return;

                    final localX = event.localPosition.dx;
                    if (localX < leftPadding - 10 ||
                        localX > constraints.maxWidth - rightPadding + 10) {
                      if (_hoveredIndex != -1) {
                        setState(() => _hoveredIndex = -1);
                      }
                      return;
                    }

                    final colWidth = data.length > 1
                        ? chartWidth / (data.length - 1)
                        : chartWidth;
                    final nearest = ((localX - leftPadding) / colWidth)
                        .round()
                        .clamp(0, data.length - 1);

                    if (_hoveredIndex != nearest) {
                      setState(() => _hoveredIndex = nearest);
                    }
                  },
                  onExit: (_) {
                    if (_hoveredIndex != -1) {
                      setState(() => _hoveredIndex = -1);
                    }
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SplineChartPainter(
                            data: data,
                            maxY: maxY,
                            stepY: stepY,
                            hoveredIndex: _hoveredIndex,
                          ),
                        ),
                      ),
                      // Tooltip bubble on hover
                      if (_hoveredIndex >= 0 && _hoveredIndex < data.length)
                        _buildTooltipOverlay(
                          data[_hoveredIndex],
                          constraints.maxWidth,
                          constraints.maxHeight,
                          maxY,
                          data.length,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltipOverlay(
    DashboardDaySales item,
    double totalWidth,
    double totalHeight,
    double maxY,
    int totalPoints,
  ) {
    const leftPadding = 58.0;
    const rightPadding = 18.0;
    const topPadding = 14.0;
    const bottomPadding = 26.0;

    final chartWidth = totalWidth - leftPadding - rightPadding;
    final chartHeight = totalHeight - topPadding - bottomPadding;
    final colWidth = totalPoints > 1
        ? chartWidth / (totalPoints - 1)
        : chartWidth;

    final posX = leftPadding + (_hoveredIndex * colWidth);
    final clampedAmount = item.amount.clamp(0.0, maxY);
    final posY =
        (topPadding + chartHeight) - (clampedAmount / maxY) * chartHeight;

    // Position tooltip safely above or below point
    final tooltipOnLeft = _hoveredIndex >= totalPoints - 2;
    final tooltipOffset = tooltipOnLeft ? -130.0 : 10.0;
    final tooltipTop = (posY - 48).clamp(topPadding, totalHeight - 65.0);

    return Positioned(
      left: (posX + tooltipOffset).clamp(leftPadding, totalWidth - 140.0),
      top: tooltipTop,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2419),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item.dateLabel} • ${item.dayLabel}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.format(item.amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                item.count > 0 ? '${item.count} orders' : 'No sales',
                style: TextStyle(
                  color: item.count > 0
                      ? const Color(0xFF68D391)
                      : const Color(0xFF94A3B8),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Calculates clean, rounded Y-axis intervals matching the user's provided design:
  /// 0, 20,000, 40,000, 60,000, 80,000, 100,000, 120,000.
  (double maxY, double stepY) _calculateYAxis(double maxAmount) {
    const defaultMax = 120000.0;
    const defaultStep = 20000.0;
    const tickCount = 6;

    if (maxAmount <= defaultMax) {
      return (defaultMax, defaultStep);
    }

    final rawStep = maxAmount / tickCount;
    double step;
    if (rawStep <= 25000.0) {
      step = 25000.0;
    } else if (rawStep <= 50000.0) {
      step = 50000.0;
    } else if (rawStep <= 100000.0) {
      step = 100000.0;
    } else {
      step = (rawStep / 50000.0).ceil() * 50000.0;
    }

    return (step * tickCount, step);
  }
}

class _SplineChartPainter extends CustomPainter {
  final List<DashboardDaySales> data;
  final double maxY;
  final double stepY;
  final int hoveredIndex;

  _SplineChartPainter({
    required this.data,
    required this.maxY,
    required this.stepY,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 58.0;
    const bottomPadding = 26.0;
    const topPadding = 14.0;
    const rightPadding = 18.0;

    final chartRect = Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );

    // Grid paint
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw chart outer border rectangle
    canvas.drawRect(chartRect, gridPaint);

    // Draw horizontal grid lines & Y-axis labels
    final int yTickCount = (maxY / stepY).round();
    final yTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    for (int i = 0; i <= yTickCount; i++) {
      final tickValue = i * stepY;
      final yPos = chartRect.bottom - (tickValue / maxY) * chartRect.height;

      // Draw horizontal line inside chart
      if (i > 0 && i < yTickCount) {
        canvas.drawLine(
          Offset(chartRect.left, yPos),
          Offset(chartRect.right, yPos),
          gridPaint,
        );
      }

      // Draw Y label (right-aligned to chartRect.left - 8)
      final labelText = CurrencyFormatter.format(tickValue, showSymbol: false);
      yTextPainter.text = TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
      );
      yTextPainter.layout();
      yTextPainter.paint(
        canvas,
        Offset(
          chartRect.left - yTextPainter.width - 8,
          yPos - (yTextPainter.height / 2),
        ),
      );
    }

    if (data.isEmpty) return;

    // Calculate X and Y coordinates for each data point
    final int n = data.length;
    final points = <Offset>[];
    final double colWidth = n > 1 ? chartRect.width / (n - 1) : chartRect.width;

    final xTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < n; i++) {
      final x = chartRect.left + (i * colWidth);
      final rawAmount = data[i].amount;
      final clampedAmount = rawAmount.clamp(0.0, maxY);
      final y = chartRect.bottom - (clampedAmount / maxY) * chartRect.height;
      points.add(Offset(x, y));

      // Draw vertical grid line
      if (i > 0 && i < n - 1) {
        canvas.drawLine(
          Offset(x, chartRect.top),
          Offset(x, chartRect.bottom),
          gridPaint,
        );
      }

      // Draw X label (e.g. 10-08)
      final dateText = data[i].dateLabel.isNotEmpty
          ? data[i].dateLabel
          : data[i].dayLabel;
      xTextPainter.text = TextSpan(
        text: dateText,
        style: TextStyle(
          color: hoveredIndex == i
              ? const Color(0xFF00B67A)
              : const Color(0xFF64748B),
          fontSize: 11,
          fontWeight: hoveredIndex == i ? FontWeight.w700 : FontWeight.w500,
        ),
      );
      xTextPainter.layout();
      xTextPainter.paint(
        canvas,
        Offset(x - (xTextPainter.width / 2), chartRect.bottom + 7),
      );
    }

    // Build Monotone Cubic Spline (Fritsch-Carlson algorithm)
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (n == 2) {
      path.lineTo(points[1].dx, points[1].dy);
    } else if (n > 2) {
      // Calculate secant slopes delta_k
      final deltas = List<double>.filled(n - 1, 0.0);
      for (int i = 0; i < n - 1; i++) {
        final dx = points[i + 1].dx - points[i].dx;
        final dy = points[i + 1].dy - points[i].dy;
        deltas[i] = dx != 0 ? dy / dx : 0.0;
      }

      // Initial tangents m_k
      final m = List<double>.filled(n, 0.0);
      m[0] = deltas[0];
      m[n - 1] = deltas[n - 2];
      for (int i = 1; i < n - 1; i++) {
        if (deltas[i - 1] * deltas[i] <= 0) {
          m[i] = 0.0; // Local extremum
        } else {
          m[i] = (deltas[i - 1] + deltas[i]) / 2.0;
        }
      }

      // Fritsch-Carlson adjustment for strict monotonicity (prevents overshoot/dip below 0)
      for (int i = 0; i < n - 1; i++) {
        if (deltas[i] == 0) {
          m[i] = 0.0;
          m[i + 1] = 0.0;
        } else {
          final alpha = m[i] / deltas[i];
          final beta = m[i + 1] / deltas[i];
          final sumSq = alpha * alpha + beta * beta;
          if (sumSq > 9.0) {
            final tau = 3.0 / sqrt(sumSq);
            m[i] = tau * alpha * deltas[i];
            m[i + 1] = tau * beta * deltas[i];
          }
        }
      }

      // Create cubic Bezier segments
      for (int i = 0; i < n - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final dx = (p1.dx - p0.dx) / 3.0;

        final cp1 = Offset(p0.dx + dx, p0.dy + m[i] * dx);
        final cp2 = Offset(p1.dx - dx, p1.dy - m[i + 1] * dx);

        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
      }
    }

    // Draw Area Fill underneath the curve
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, chartRect.bottom);
    fillPath.lineTo(points.first.dx, chartRect.bottom);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00B67A).withValues(alpha: 0.16),
          const Color(0xFF00B67A).withValues(alpha: 0.02),
        ],
      ).createShader(chartRect);

    canvas.drawPath(fillPath, fillPaint);

    // Draw Smooth Stroke Line
    final linePaint = Paint()
      ..color = const Color(0xFF00B67A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Draw Data Point Circles (Hollow emerald circles with white inner fill)
    final dotFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotStrokePaint = Paint()
      ..color = const Color(0xFF00B67A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      // White center
      canvas.drawCircle(p, 4.5, dotFillPaint);
      // Emerald stroke ring
      canvas.drawCircle(p, 4.5, dotStrokePaint);
    }

    // Draw Hover Guide Line & Active Glow Indicator
    if (hoveredIndex >= 0 && hoveredIndex < points.length) {
      final hp = points[hoveredIndex];

      // Vertical guide line
      final guidePaint = Paint()
        ..color = const Color(0xFF00B67A).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(hp.dx, chartRect.top),
        Offset(hp.dx, chartRect.bottom),
        guidePaint,
      );

      // Glow ring
      final glowPaint = Paint()
        ..color = const Color(0xFF00B67A).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(hp, 8.5, glowPaint);

      // Inner dot & ring
      canvas.drawCircle(hp, 5.0, dotFillPaint);
      final activeStroke = Paint()
        ..color = const Color(0xFF00B67A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(hp, 5.0, activeStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _SplineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.maxY != maxY ||
        oldDelegate.stepY != stepY ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}
