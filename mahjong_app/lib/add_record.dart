import 'package:flutter/material.dart';
import 'game_table.dart'; // 換成這個新檔案

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MahjongApp());
}

class MahjongApp extends StatelessWidget {
  const MahjongApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '麻將計分王',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
      ),
      home: const GameTableScreen(), // 把首頁換成這個
    );
  }
}