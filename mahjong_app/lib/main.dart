import 'package:flutter/material.dart';
import 'root_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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