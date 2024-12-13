import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageDetailScreen extends StatefulWidget {
  final Map<String, dynamic> imageData;

  ImageDetailScreen({required this.imageData});

  @override
  _ImageDetailScreenState createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  bool _isProcessing = false;

  Future<void> _downloadImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    final url =
        "http://172.29.214.85:8000/media/${widget.imageData['filename']}";

    try {
      setState(() {
        _isProcessing = true;
      });

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        // 외부 저장소 접근 권한 요청
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장소 접근 권한이 거부되었습니다. 권한을 허용해주세요.')),
          );
          return;
        }

        // 외부 저장소의 'Pictures' 또는 'Download' 디렉토리에 저장
        final directory = Directory('/storage/emulated/0/Pictures');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final filePath = '${directory.path}/${widget.imageData['filename']}';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);

        // 갤러리에 이미지 추가
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 다운로드 성공: 갤러리에 저장되었습니다. 경로: $filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 다운로드 실패 (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버와의 연결에 실패했습니다. 오류: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("이미지 상세"),
      ),
      body: _isProcessing
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Image.network(
                    widget.imageData['download_link'],
                    fit: BoxFit.contain,
                  ),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _downloadImage,
                  child: Text('이미지 다운로드'),
                ),
              ],
            ),
    );
  }
}
