import 'package:flutter/material.dart';
import 'root_screen.dart';

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
        brightness: Brightness.light,
        primaryColor: Colors.green[800],
        scaffoldBackgroundColor: const Color(0xFFE8E8E8),
      ),
      home: const RootScreen(),
    );
  }
}