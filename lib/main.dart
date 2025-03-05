import 'package:flutter/material.dart';
import 'package:memory_map/pages/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:memory_map/pages/main_page.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp()));
}

class MyApp extends StatefulWidget {
   User? currentUser;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void _getCurrentUser() {
    widget.currentUser = FirebaseAuth.instance.currentUser;
    setState(() {
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getCurrentUser();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context,listen: true);
    return MaterialApp(
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      title: 'MemoryMap',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      home: widget.currentUser==null?LoginPage(): MainPage(),
    );
  }
}

