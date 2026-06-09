import 'package:flutter/material.dart';
import 'package:homestay/screens/homestay_list_screen.dart';

void main() {
  runApp(const HomestayApp());
}

class HomestayApp extends StatelessWidget {
  const HomestayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homestay2U Malaysia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 34, 65, 240), 
          foregroundColor: Color.fromARGB(255, 242, 246, 246), 
          elevation: 0,
          centerTitle: true, 
          titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold, 
            fontSize: 22,
            color: Color.fromARGB(255, 216, 245, 245), 
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      home: const HomestayListScreen(),
    );
  }
}