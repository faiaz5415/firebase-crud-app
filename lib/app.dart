import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crud_app/home_screen.dart';
import 'package:firebase_crud_app/sign_up_screen.dart';
import 'package:flutter/material.dart';

class FootballLiveScoreApp extends StatefulWidget {
  const FootballLiveScoreApp({super.key});

  @override
  State<FootballLiveScoreApp> createState() => _FootballLiveScoreAppState();
}

class _FootballLiveScoreAppState extends State<FootballLiveScoreApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirebaseAuth.instance.currentUser != null
          ? const HomeScreen()
          : const SignUpScreen(),
    );
  }
}