import 'package:flutter/material.dart';

import 'presentation/order_traking_screen.dart';
import 'utils/notification_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the NotificationHandler
  NotificationHandler().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const OrderTrackingScreen(),
    );
  }
}
