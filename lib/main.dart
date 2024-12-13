import 'package:flutter/material.dart';
import 'screens/upload_image_screen.dart';
import 'screens/ImageDetailScreen.dart' as detail;
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/local_image_management_screen.dart';
import 'screens/remote_image_screen.dart';
import 'screens/copy_record_screen.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final List<Map<String, dynamic>> copyRecords = [];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/local_management': (context) => LocalImageManagementScreen(),
        '/remote_image': (context) => RemoteImageGalleryScreen(),
        '/copy_record': (context) => CopyRecordScreen(copyRecords: copyRecords),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/upload') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null && args.containsKey('selectedImage')) {
            final File selectedImage = args['selectedImage'];
            return MaterialPageRoute(
              builder: (context) =>
                  UploadImageScreen(selectedImage: selectedImage),
            );
          } else {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text('선택된 이미지가 없습니다.'),
                ),
              ),
            );
          }
        } else if (settings.name == '/image_detail') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null && args.containsKey('imageData')) {
            final imageData = args['imageData'];
            return MaterialPageRoute(
              builder: (context) =>
                  detail.ImageDetailScreen(imageData: imageData),
            );
          } else {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text('이미지 데이터가 제공되지 않았습니다.'),
                ),
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
