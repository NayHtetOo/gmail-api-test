import 'package:flutter/material.dart';
import 'package:mail_api_test/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // when use gmail api ,configure google cloud console and firebase
  // Both google cloud and firebase need sha1 key ,so to generate sha1
  // need to configure two build.gradle files
  // add classpath to 
    // -/android/build.gradle and
  // add plugins,dependencies, and apply plugin
    // -/android/app/build.gradle
  // after doing this, go under android folder
  // - d/NayHtetOo/Flutter/mail_api_test/android
  // ./gradlew signingReport (java version 11)
  // copy sha1 12:3C:DD:.....................
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Home()
    );
  }
}
