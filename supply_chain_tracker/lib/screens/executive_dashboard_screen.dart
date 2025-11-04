import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/dashboard_provider.dart';
import '../theme/colors.dart';
import '../widgets/hyper_text.dart';

class ExecutiveDashboardScreen extends ConsumerStatefulWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  ConsumerState<ExecutiveDashboardScreen> createState() => _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState extends ConsumerState<ExecutiveDashboardScreen> {
  int? _supplierSortColumnIndex;
  bool _supplierSortAscending = true;
  int? _disruptionTypesSortColumnIndex;
  bool _disruptionTypesSortAscending = true;

  @override
  Widget build(BuildContext context) {
    final WidgetRef ref = this.ref;
    final dashboardState = ref.watch(executiveDashboardProvider);

    return Scaffold(
      body: dashboardState.when(
        data: (data) {
          print('Dashboard data loaded: ${data.keys}');
          return _buildDashboard(context, data);
        },
        loading: () {
          print('Dashboard loading...');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading Executive Dashboard...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        },
        error: (error, stack) {
          print('Dashboard error: $error');
          print('Stack trace: $stack');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading dashboard: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(executiveDashboardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and subtitle
          Text(
            data['title'] ?? 'Executive Dashboard',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                data['subtitle'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Based on last one month\'s data',
                padding: const EdgeInsets.all(12),
                textStyle: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Top KPI cards row (including Supplier Risk Score)
          _buildTopKPISection(data['kpi_cards'] ?? [], data['supplier_risk'] ?? {}),
          const SizedBox(height: 32),

          // Main content area
          LayoutBuilder(
            builder: (context, constraints) {
              // If screen width is less than 1000px, stack vertically
              if (constraints.maxWidth < 1000) {
                return Column(
                  children: [
                    _buildDemandForecasting(data['demand_forecasting'] ?? {}),
                    const SizedBox(height: 24),
                    _buildInventoryLevels(data['inventory_levels'] ?? {}),
                  ],
                );
              }

              // Desktop: Side by side
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildDemandForecasting(data['demand_forecasting'] ?? {}),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: _buildInventoryLevels(data['inventory_levels'] ?? {}),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildLogisticsTransportation(data['logistics_transportation'] ?? {}),
          const SizedBox(height: 24),
          _buildThreeColumnRiskSection(
            data['supplier_performance'] ?? {},
            data['risk_assessment'] ?? {},
            data['predictive_risk_analysis'] ?? {},
          ),
        ],
      ),
    );
  }

  Widget _buildTopKPISection(List<dynamic> kpiCards, Map<String, dynamic> riskData) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Combine KPI cards and supplier risk score
        final allCards = [
          ...kpiCards,
          {
            'id': 'supplier_risk',
            'label': riskData['label'] ?? 'Supplier Risk Score',
            'value': riskData['value'] ?? 'Low',
            'change': riskData['change'] ?? 0,
            'change_unit': riskData['change_unit'] ?? '%',
            'is_risk_card': true,
          }
        ];

        // Determine how many cards per row based on screen width
        int cardsPerRow;
        if (constraints.maxWidth >= 1400) {
          cardsPerRow = 5; // Desktop: All 5 cards in a row
        } else if (constraints.maxWidth >= 1000) {
          cardsPerRow = 3; // Medium: 3 cards per row
        } else if (constraints.maxWidth >= 600) {
          cardsPerRow = 2; // Tablet: 2 cards per row
        } else {
          cardsPerRow = 1; // Mobile: 1 card per row
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: allCards.map<Widget>((card) {
            // Calculate card width based on cards per row
            final cardWidth = (constraints.maxWidth - (16 * (cardsPerRow - 1))) / cardsPerRow;

            return SizedBox(
              width: cardWidth,
              child: ShadCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card['label'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    HyperText(
                      text: card['is_risk_card'] == true
                          ? (card['value'] ?? '')
                          : '${card['prefix'] ?? ''}${card['value']}${card['unit'] ?? ''}',
                      duration: const Duration(milliseconds: 1000),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          (card['change'] ?? 0) >= 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                          color: card['is_risk_card'] == true
                              ? ((card['change'] ?? 0) >= 0
                                  ? AppColors.negativeChange
                                  : AppColors.positiveChange)
                              : ((card['change'] ?? 0) >= 0
                                  ? AppColors.positiveChange
                                  : AppColors.negativeChange),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(card['change'] ?? 0) > 0 ? '+' : ''}${card['change']}${card['change_unit'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: card['is_risk_card'] == true
                                ? ((card['change'] ?? 0) >= 0
                                    ? AppColors.negativeChange
                                    : AppColors.positiveChange)
                                : ((card['change'] ?? 0) >= 0
                                    ? AppColors.positiveChange
                                    : AppColors.negativeChange),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildKPICardsRow(List<dynamic> kpiCards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine how many cards per row based on screen width
        int cardsPerRow;
        if (constraints.maxWidth >= 1200) {
          cardsPerRow = 4; // Desktop: 4 cards in a row
        } else if (constraints.maxWidth >= 800) {
          cardsPerRow = 2; // Tablet: 2 cards in a row
        } else {
          cardsPerRow = 1; // Mobile: 1 card per row
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: kpiCards.map<Widget>((card) {
            // Calculate card width based on cards per row
            final cardWidth = (constraints.maxWidth - (16 * (cardsPerRow - 1))) / cardsPerRow;

            return SizedBox(
              width: cardWidth,
              child: ShadCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card['label'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    HyperText(
                      text: '${card['prefix'] ?? ''}${card['value']}${card['unit'] ?? ''}',
                      duration: const Duration(milliseconds: 1000),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          (card['change'] ?? 0) >= 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                          color: (card['change'] ?? 0) >= 0
                              ? AppColors.positiveChange
                              : AppColors.negativeChange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(card['change'] ?? 0) > 0 ? '+' : ''}${card['change']}${card['change_unit'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: (card['change'] ?? 0) >= 0
                                ? AppColors.positiveChange
                                : AppColors.negativeChange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSupplierRiskCard(Map<String, dynamic> riskData) {
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskData['label'] ?? 'Supplier Risk Score',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                HyperText(
                  text: riskData['value'] ?? 'Low',
                  duration: const Duration(milliseconds: 1000),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      (riskData['change'] ?? 0) >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                      color: (riskData['change'] ?? 0) >= 0
                          ? AppColors.negativeChange
                          : AppColors.positiveChange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(riskData['change'] ?? 0) > 0 ? '+' : ''}${riskData['change']}${riskData['change_unit'] ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: (riskData['change'] ?? 0) >= 0
                            ? AppColors.negativeChange
                            : AppColors.positiveChange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandForecasting(Map<String, dynamic> forecastData) {
    final chartData = forecastData['chart_data'] as List<dynamic>? ?? [];

    // Transform data for fl_chart
    final chartDataList = chartData.map((item) => {
      'month': item['month']?.toString() ?? '',
      'value': (item['value'] ?? 0).toDouble(),
    }).toList();

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white70 : Colors.black87;
          final gridColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);

          return SizedBox(
            height: 450, // Fixed height for consistent alignment
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            children: [
              Text(
                forecastData['title'] ?? 'Demand Forecasting',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Forecast Accuracy compared to Actuals.\nCalculated as 1-MAPE',
                padding: const EdgeInsets.all(12),
                textStyle: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  forecastData['accuracy_label'] ?? 'Demand Forecast Accuracy',
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
                const SizedBox(height: 8),
                HyperText(
                  text: '${forecastData['accuracy_value']}${forecastData['unit'] ?? ''}',
                  duration: const Duration(milliseconds: 1000),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  forecastData['period'] ?? '',
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (chartDataList.isNotEmpty)
            SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 16),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: gridColor,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value.toInt() >= 0 && value.toInt() < chartDataList.length) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  chartDataList[value.toInt()]['month'].toString(),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 20,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (chartDataList.length - 1).toDouble(),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartDataList.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value['value'] as double,
                          );
                        }).toList(),
                        isCurved: true,
                        color: const Color(0xFF3B82F6),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF3B82F6),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildInventoryLevels(Map<String, dynamic> inventoryData) {
    final locations = inventoryData['locations'] as List<dynamic>? ?? [];

    // Transform data for fl_chart
    final chartDataList = locations.map((item) => {
      'location': item['name']?.toString() ?? '',
      'value': (item['value'] ?? 0).toDouble(),
    }).toList();

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white70 : Colors.black87;
          final gridColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);

          return SizedBox(
            height: 450, // Fixed height to match Demand Forecasting
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
              inventoryData['title'] ?? 'Inventory Levels',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inventoryData['subtitle'] ?? 'Inventory Levels by Location',
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    HyperText(
                      text: '\$${inventoryData['total_value']}${inventoryData['unit'] ?? ''}',
                      duration: const Duration(milliseconds: 1000),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inventoryData['period'] ?? '',
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (chartDataList.isNotEmpty)
            SizedBox(
              height: 280,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 16),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: chartDataList.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b) * 1.3,
                    minY: 0,
                    gridData: const FlGridData(
                      show: false,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value.toInt() >= 0 && value.toInt() < chartDataList.length) {
                              final label = chartDataList[value.toInt()]['location'].toString();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: SizedBox(
                                  width: 80,
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 9,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              value.toStringAsFixed(1),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: chartDataList.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value['value'] as double,
                            color: const Color(0xFF3B82F6),
                            width: 40,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                        showingTooltipIndicators: [0],
                      );
                    }).toList(),
                    barTouchData: BarTouchData(
                      enabled: false,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.transparent,
                        tooltipPadding: EdgeInsets.zero,
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '\$${rod.toY.toStringAsFixed(1)}M',
                            TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildSupplierPerformance(Map<String, dynamic> supplierData) {
    List<dynamic> suppliers = List.from(supplierData['suppliers'] as List<dynamic>? ?? []);

    // Apply sorting
    if (_supplierSortColumnIndex != null && suppliers.isNotEmpty) {
      suppliers.sort((a, b) {
        dynamic aValue;
        dynamic bValue;

        switch (_supplierSortColumnIndex) {
          case 0: // Supplier name
            aValue = a['name'] ?? '';
            bValue = b['name'] ?? '';
            break;
          case 1: // On-Time Delivery
            aValue = a['on_time_delivery'] ?? 0;
            bValue = b['on_time_delivery'] ?? 0;
            break;
          case 2: // Quality Score
            aValue = a['quality_score'] ?? 0;
            bValue = b['quality_score'] ?? 0;
            break;
          case 3: // Lead Time
            aValue = int.tryParse((a['lead_time'] ?? '0').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            bValue = int.tryParse((b['lead_time'] ?? '0').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            break;
          case 4: // Risk Score
            final riskMap = {'low': 1, 'medium': 2, 'high': 3};
            aValue = riskMap[(a['risk_score'] ?? '').toString().toLowerCase()] ?? 0;
            bValue = riskMap[(b['risk_score'] ?? '').toString().toLowerCase()] ?? 0;
            break;
          default:
            return 0;
        }

        int comparison;
        if (aValue is String && bValue is String) {
          comparison = aValue.compareTo(bValue);
        } else {
          comparison = (aValue as num).compareTo(bValue as num);
        }

        return _supplierSortAscending ? comparison : -comparison;
      });
    }

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : Colors.black87;
          final progressBgColor = isDark ? Colors.grey[800] : Colors.grey[300];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    supplierData['title'] ?? 'Supplier Performance',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Score card based on composite metric index',
                    padding: const EdgeInsets.all(12),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: _supplierSortColumnIndex,
                  sortAscending: _supplierSortAscending,
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? Colors.grey[850] : Colors.grey[100],
                  ),
                  columns: [
                    DataColumn(
                      label: Text(
                        'Supplier',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onSort: (columnIndex, ascending) {
                        setState(() {
                          _supplierSortColumnIndex = columnIndex;
                          _supplierSortAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: Text(
                        'On-Time Delivery',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onSort: (columnIndex, ascending) {
                        setState(() {
                          _supplierSortColumnIndex = columnIndex;
                          _supplierSortAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: Text(
                        'Quality Score',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onSort: (columnIndex, ascending) {
                        setState(() {
                          _supplierSortColumnIndex = columnIndex;
                          _supplierSortAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: Text(
                        'Lead Time',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onSort: (columnIndex, ascending) {
                        setState(() {
                          _supplierSortColumnIndex = columnIndex;
                          _supplierSortAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: Text(
                        'Risk Score',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onSort: (columnIndex, ascending) {
                        setState(() {
                          _supplierSortColumnIndex = columnIndex;
                          _supplierSortAscending = ascending;
                        });
                      },
                    ),
                  ],
                  rows: suppliers.map<DataRow>((supplier) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            supplier['name'] ?? '',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: (supplier['on_time_delivery'] ?? 0) / 100,
                                    backgroundColor: progressBgColor,
                                    color: Colors.blue,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${supplier['on_time_delivery']}%',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: (supplier['quality_score'] ?? 0) / 100,
                                    backgroundColor: progressBgColor,
                                    color: Colors.blue,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${supplier['quality_score']}%',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            supplier['lead_time'] ?? '',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        DataCell(
                          ShadBadge(
                            backgroundColor: _getRiskColor(supplier['risk_score']),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Text(
                                supplier['risk_score'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Color _getRiskColor(String? risk) {
    switch (risk?.toLowerCase()) {
      case 'low':
        return AppColors.riskLow;
      case 'medium':
        return AppColors.riskMedium;
      case 'high':
        return AppColors.riskHigh;
      default:
        return AppColors.riskDefault;
    }
  }

  Widget _buildThreeColumnRiskSection(
    Map<String, dynamic> supplierPerformanceData,
    Map<String, dynamic> riskAssessmentData,
    Map<String, dynamic> predictiveRiskData,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If screen width is less than 1000px (tablet size), stack vertically
        if (constraints.maxWidth < 1000) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSupplierPerformance(supplierPerformanceData),
              const SizedBox(height: 24),
              _buildPredictiveRiskAnalysis(predictiveRiskData),
            ],
          );
        }

        // Desktop: Two columns side by side
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _buildSupplierPerformance(supplierPerformanceData),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: _buildPredictiveRiskAnalysis(predictiveRiskData),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPredictiveRiskAnalysis(Map<String, dynamic> riskData) {
    final contributingFactors =
        riskData['contributing_factors'] as List<dynamic>? ?? [];
    List<dynamic> disruptionTypes = List.from(riskData['disruption_types'] as List<dynamic>? ?? []);

    // Apply sorting to disruption types
    if (_disruptionTypesSortColumnIndex != null && disruptionTypes.isNotEmpty) {
      disruptionTypes.sort((a, b) {
        dynamic aValue;
        dynamic bValue;

        switch (_disruptionTypesSortColumnIndex) {
          case 0: // Disruption Type
            aValue = a['type'] ?? '';
            bValue = b['type'] ?? '';
            break;
          case 1: // Probability
            aValue = a['probability'] ?? 0;
            bValue = b['probability'] ?? 0;
            break;
          default:
            return 0;
        }

        int comparison;
        if (aValue is String && bValue is String) {
          comparison = aValue.compareTo(bValue);
        } else {
          comparison = (aValue as num).compareTo(bValue as num);
        }

        return _disruptionTypesSortAscending ? comparison : -comparison;
      });
    }

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : Colors.black87;
          final progressBgColor = isDark ? Colors.grey[800] : Colors.grey[300];
          final cardBgColor = isDark ? Colors.grey[900] : Colors.grey[200];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            children: [
              Text(
                riskData['title'] ?? 'Predictive Risk Analysis',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Forward looking risk assessment based on current news, events, weather & economic data',
                padding: const EdgeInsets.all(12),
                textStyle: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskData['disruption_label'] ??
                      'Potential Supply Chain Disruptions',
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  riskData['disruption_level'] ?? 'High',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  riskData['period'] ?? '',
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Contributing Factors',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          ...contributingFactors.map((factor) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        factor['name'] ?? '',
                        style: TextStyle(fontSize: 12, color: textColor),
                      ),
                      Text(
                        '${factor['value']}',
                        style: TextStyle(fontSize: 12, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (factor['value'] ?? 0) / 100,
                    backgroundColor: progressBgColor,
                    color: Colors.blue,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          Text(
            'Disruption Types',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: _disruptionTypesSortColumnIndex,
              sortAscending: _disruptionTypesSortAscending,
              headingRowColor: WidgetStateProperty.all(
                isDark ? Colors.grey[850] : Colors.grey[100],
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Disruption Type',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _disruptionTypesSortColumnIndex = columnIndex;
                      _disruptionTypesSortAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: Text(
                    'Probability',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _disruptionTypesSortColumnIndex = columnIndex;
                      _disruptionTypesSortAscending = ascending;
                    });
                  },
                ),
              ],
              rows: disruptionTypes.map<DataRow>((disruption) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        disruption['type'] ?? '',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: (disruption['probability'] ?? 0) / 100,
                                backgroundColor: progressBgColor,
                                color: Colors.blue,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${disruption['probability']}%',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          ],
        );
      }),
    );
  }

  Widget _buildLogisticsTransportation(Map<String, dynamic> logisticsData) {
    final expeditedDelayed = logisticsData['expedited_delayed'] as Map<String, dynamic>? ?? {};
    final otifOverTime = logisticsData['otif_over_time'] as Map<String, dynamic>? ?? {};

    final expeditedChartData = expeditedDelayed['chart_data'] as List<dynamic>? ?? [];
    final otifChartData = otifOverTime['chart_data'] as List<dynamic>? ?? [];

    // Transform data for fl_chart
    final expeditedDataList = expeditedChartData.map((item) => {
      'month': item['month']?.toString() ?? '',
      'value': (item['value'] ?? 0).toDouble(),
    }).toList();

    final otifDataList = otifChartData.map((item) => {
      'month': item['month']?.toString() ?? '',
      'value': (item['value'] ?? 0).toDouble(),
    }).toList();

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white70 : Colors.black87;
          final gridColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(
            logisticsData['title'] ?? 'Logistics & Transportation',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expeditedDelayed['label'] ?? '% of Shipments Expedited or Delayed',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${expeditedDelayed['value']}${expeditedDelayed['unit'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expeditedDelayed['period'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    if (expeditedDataList.isNotEmpty)
                      SizedBox(
                        height: 180,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8, top: 8),
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 5,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: gridColor,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 25,
                                    interval: 1,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      if (value.toInt() >= 0 && value.toInt() < expeditedDataList.length) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text(
                                            expeditedDataList[value.toInt()]['month'].toString(),
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 9,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 5,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: (expeditedDataList.length - 1).toDouble(),
                              minY: 0,
                              maxY: 25,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: expeditedDataList.asMap().entries.map((entry) {
                                    return FlSpot(
                                      entry.key.toDouble(),
                                      entry.value['value'] as double,
                                    );
                                  }).toList(),
                                  isCurved: true,
                                  color: const Color(0xFFF97316),
                                  barWidth: 2.5,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 3,
                                        color: const Color(0xFFF97316),
                                        strokeWidth: 1.5,
                                        strokeColor: Colors.white,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: const Color(0xFFF97316).withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otifOverTime['label'] ?? 'OTIF Over Time',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${otifOverTime['value']}${otifOverTime['unit'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      otifOverTime['period'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    if (otifDataList.isNotEmpty)
                      SizedBox(
                        height: 180,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8, top: 8),
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 20,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: gridColor,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 25,
                                    interval: 1,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      if (value.toInt() >= 0 && value.toInt() < otifDataList.length) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text(
                                            otifDataList[value.toInt()]['month'].toString(),
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 9,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 20,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: (otifDataList.length - 1).toDouble(),
                              minY: 0,
                              maxY: 100,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: otifDataList.asMap().entries.map((entry) {
                                    return FlSpot(
                                      entry.key.toDouble(),
                                      entry.value['value'] as double,
                                    );
                                  }).toList(),
                                  isCurved: true,
                                  color: const Color(0xFF10B981),
                                  barWidth: 2.5,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 3,
                                        color: const Color(0xFF10B981),
                                        strokeWidth: 1.5,
                                        strokeColor: Colors.white,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          ],
        );
      }),
    );
  }
}
