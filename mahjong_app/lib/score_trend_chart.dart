import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ScoreTrendChart extends StatelessWidget {
  final List<List<int>> history;
  final List<int> currentScores;
  final List<String> players;

  const ScoreTrendChart({
    Key? key,
    required this.history,
    required this.currentScores,
    required this.players,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // build full data points
    List<List<int>> fullData = List.from(history);
    // currentScores contains just the current state's scores (4 items), we extract just the first 4 elements to be safe
    fullData.add(currentScores.sublist(0, 4));

    int maxY = 0;
    int minY = 0;
    for (var data in fullData) {
      for (int i = 0; i < 4; i++) {
        if (data[i] > maxY) maxY = data[i];
        if (data[i] < minY) minY = data[i];
      }
    }
    
    // Add some padding to Y axis
    maxY = maxY + (maxY == 0 ? 100 : (maxY * 0.2).abs().ceil());
    minY = minY - (minY == 0 ? 100 : (minY * 0.2).abs().ceil());

    final List<Color> playerColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
    ];

    List<LineChartBarData> lineBarsData = [];
    for (int pIndex = 0; pIndex < 4; pIndex++) {
      List<FlSpot> spots = [];
      for (int hIndex = 0; hIndex < fullData.length; hIndex++) {
        spots.add(FlSpot(hIndex.toDouble(), fullData[hIndex][pIndex].toDouble()));
      }
      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: playerColors[pIndex],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return Container(
      height: 450,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            '本局分數走勢圖',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: playerColors[index],
                  ),
                  const SizedBox(width: 4),
                  Text(players[index]),
                ],
              );
            }),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final textStyle = TextStyle(
                          color: touchedSpot.bar.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        );
                        return LineTooltipItem(
                          '${players[touchedSpot.barIndex]}: ${touchedSpot.y.toInt()}',
                          textStyle,
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('局數 (次)'),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 == 0) {
                          return Text(value.toInt().toString());
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                minX: 0,
                maxX: (fullData.length - 1).toDouble() > 0 ? (fullData.length - 1).toDouble() : 1.0,
                minY: minY.toDouble(),
                maxY: maxY.toDouble(),
                lineBarsData: lineBarsData,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
