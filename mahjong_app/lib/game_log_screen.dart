import 'package:flutter/material.dart';

class GameLogScreen extends StatelessWidget {
  final String gameName;
  final List<String> players;
  final List<List<int>> fullHistory;

  const GameLogScreen({
    Key? key,
    required this.gameName,
    required this.players,
    required this.fullHistory,
  }) : super(key: key);

  bool _isManualAdjustment(List<int> prevState, List<int> currState) {
    if (prevState.length < 16 || currState.length < 16) return false;
    
    // Check if any win/selfDrawn/chuck count changed
    for (int i = 4; i < 16; i++) {
      if (prevState[i] != currState[i]) return false;
    }
    
    // If stats didn't change, but scores DID change, it's a manual adjustment
    for (int i = 0; i < 4; i++) {
      if (prevState[i] != currState[i]) return true;
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Generate the rows from history
    List<Widget> contentWidgets = [];

    // We group by Jiang and Round
    int currentJiang = -1;
    int currentRound = -1;
    int realHandCount = 0;
    
    final List<String> windNames = ['東', '南', '西', '北'];

    for (int i = 1; i < fullHistory.length; i++) {
      List<int> prevState = fullHistory[i - 1];
      List<int> currState = fullHistory[i];

      int prevDealerPass = prevState.length >= 36 ? prevState[35] : (prevState.length > 23 ? prevState[23] : 0);
      
      // Use previous dealer pass to determine the wind for the transition
      int jiang = prevDealerPass ~/ 16;
      int round = (prevDealerPass % 16) ~/ 4;
      int dealerWind = prevDealerPass % 4;

      if (jiang != currentJiang || round != currentRound) {
        currentJiang = jiang;
        currentRound = round;
        contentWidgets.add(_buildSectionHeader(jiang, round, windNames));
      }

      bool isAdjustment = _isManualAdjustment(prevState, currState);
      if (!isAdjustment) {
        realHandCount++;
      }

      contentWidgets.add(_buildLogItem(
        handNumber: isAdjustment ? -1 : realHandCount,
        dealerWindName: isAdjustment ? '微調' : (windNames[dealerWind] + '風'),
        prevState: prevState,
        currState: currState,
        isAdjustment: isAdjustment,
      ));
      
      contentWidgets.add(const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)));
    }

    if (fullHistory.length <= 1) {
      contentWidgets.add(
        const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text("尚無牌局紀錄", style: TextStyle(color: Colors.grey, fontSize: 16))),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(gameName.split(' ').first, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
            Text('牌局紀錄', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              children: contentWidgets,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(int jiang, int round, List<String> windNames) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              '第 ${jiang + 1} 將 ${windNames[round]}風圈',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          )
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 60,
            child: Center(child: Text('局數', style: TextStyle(fontWeight: FontWeight.bold))),
          ),
          ...players.map((p) => Expanded(
            child: Column(
              children: [
                const Icon(Icons.person, color: Colors.green, size: 20),
                const SizedBox(height: 4),
                Text(p, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildLogItem({
    required int handNumber,
    required String dealerWindName,
    required List<int> prevState,
    required List<int> currState,
    bool isAdjustment = false,
  }) {
    List<int> deltas = [];
    List<int> currentScores = [];
    
    for (int i = 0; i < 4; i++) {
      int prevScore = prevState.length > i ? prevState[i] : 0;
      int currScore = currState.length > i ? currState[i] : 0;
      deltas.add(currScore - prevScore);
      currentScores.add(currScore);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      color: isAdjustment ? Colors.yellow[50] : (handNumber % 2 == 0 ? Colors.grey[50] : Colors.white),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isAdjustment)
                  Text('$handNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(dealerWindName, style: TextStyle(color: isAdjustment ? Colors.orange[800] : Colors.grey, fontSize: 12, fontWeight: isAdjustment ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ),
          ...List.generate(4, (index) {
            int delta = deltas[index];
            int current = currentScores[index];
            
            Color deltaColor = Colors.transparent;
            if (delta > 0) deltaColor = Colors.green[700]!;
            if (delta < 0) deltaColor = Colors.red[700]!;

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    delta > 0 ? '(+$delta)' : (delta < 0 ? '($delta)' : ''),
                    style: TextStyle(
                      color: deltaColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$current',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
