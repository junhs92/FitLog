import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/exercise_volume_history_entity.dart';

/// Chart widget showing exercise volume progression over sessions
class ExerciseVolumeChart extends StatefulWidget {
  final ExerciseVolumeHistoryEntity history;

  const ExerciseVolumeChart({
    required this.history,
    super.key,
  });

  @override
  State<ExerciseVolumeChart> createState() => _ExerciseVolumeChartState();
}

class _ExerciseVolumeChartState extends State<ExerciseVolumeChart> {
  int? _touchedIndex;

  static const Color _regularDotColor = AppColors.primary;
  static const Color _prDotColor = Color(0xFFFFD700); // Gold
  static const Color _lineColor = AppColors.primary;
  static const Color _gradientTopColor = Color(0x404F46E5);
  static const Color _gradientBottomColor = Color(0x004F46E5);

  @override
  Widget build(BuildContext context) {
    final sessions = widget.history.sessions;

    if (sessions.isEmpty) {
      return _buildEmptyState();
    }

    if (sessions.length == 1) {
      return _buildSingleSessionState(sessions.first);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: LineChart(_buildLineChartData(sessions)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildLegend(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: AppColors.neutral400,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '운동 기록이 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSessionState(ExerciseSessionVolumeEntity session) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (session.hasPR) ...[
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFD700),
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                session.volumeDisplay,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            DateFormat('M/d (E)').format(session.sessionDate),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '더 많은 세션을 완료하면 추이 그래프가 표시됩니다',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neutral500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(List<ExerciseSessionVolumeEntity> sessions) {
    final spots = <FlSpot>[];
    final prIndices = <int>{};

    for (var i = 0; i < sessions.length; i++) {
      spots.add(FlSpot(i.toDouble(), sessions[i].totalVolume));
      if (sessions[i].hasPR) {
        prIndices.add(i);
      }
    }

    // Calculate Y axis range
    final maxVolume = widget.history.maxSessionVolume;
    final minVolume = widget.history.minSessionVolume;
    final range = maxVolume - minVolume;
    final padding = range * 0.15;
    final yMin = (minVolume - padding).clamp(0.0, double.infinity);
    final yMax = maxVolume + padding;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _calculateYInterval(yMax - yMin),
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.neutral200,
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: _calculateYInterval(yMax - yMin),
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _formatVolumeLabel(value),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.neutral600,
                ),
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _calculateXInterval(sessions.length),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= sessions.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  DateFormat('M/d').format(sessions[index].sessionDate),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.neutral600,
                  ),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (sessions.length - 1).toDouble(),
      minY: yMin,
      maxY: yMax,
      lineTouchData: LineTouchData(
        enabled: true,
        touchCallback: (event, response) {
          if (event is FlTapUpEvent || event is FlLongPressEnd) {
            setState(() => _touchedIndex = null);
          } else if (response?.lineBarSpots != null &&
              response!.lineBarSpots!.isNotEmpty) {
            setState(() => _touchedIndex = response.lineBarSpots!.first.spotIndex);
          }
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => AppColors.neutralBlack.withValues(alpha: 0.9),
          tooltipRoundedRadius: 8,
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final index = spot.spotIndex;
              final session = sessions[index];
              final prText = session.hasPR ? '\n${session.prTypeDisplayKo}' : '';
              return LineTooltipItem(
                '${DateFormat('M/d (E)').format(session.sessionDate)}\n${session.volumeDisplay}$prText',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: _lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              final isPR = prIndices.contains(index);
              final isTouched = _touchedIndex == index;

              if (isPR) {
                return FlDotCirclePainter(
                  radius: isTouched ? 8 : 6,
                  color: _prDotColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              }

              return FlDotCirclePainter(
                radius: isTouched ? 6 : 4,
                color: _regularDotColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_gradientTopColor, _gradientBottomColor],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: _regularDotColor,
          label: '일반 세션',
        ),
        const SizedBox(width: AppSpacing.lg),
        _LegendItem(
          color: _prDotColor,
          label: 'PR 달성',
          icon: Icons.emoji_events,
        ),
      ],
    );
  }

  double _calculateYInterval(double range) {
    if (range <= 500) return 100;
    if (range <= 1000) return 200;
    if (range <= 2000) return 500;
    if (range <= 5000) return 1000;
    return 2000;
  }

  double _calculateXInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 5;
    return 10;
  }

  String _formatVolumeLabel(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}t';
    }
    return '${value.toInt()}kg';
  }
}

/// Legend item widget
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final IconData? icon;

  const _LegendItem({
    required this.color,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
        ] else ...[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }
}
