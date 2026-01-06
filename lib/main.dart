import 'package:chatapp/domain/constants/appthemes.dart';
import 'package:chatapp/domain/constants/cubits/themecubit.dart';
import 'package:chatapp/domain/constants/cubits/themestates.dart';
import 'package:chatapp/splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'data/notification_service.dart';


Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await NotificationService().init();

  FirebaseMessaging.onBackgroundMessage(
    NotificationService.backgroundHandler,
  );

  runApp(BlocProvider(
    create: (_)=>ThemeCubit(),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeStates>(
      builder: (context, state) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Chat App',
          theme: state is LightThemeStates ? AppThemes.lightTheme : AppThemes.darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
