import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class UploadImageScreen extends StatefulWidget {
  final File selectedImage;

  UploadImageScreen({required this.selectedImage, Key? key}) : super(key: key);

  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  final TextEditingController _tagController = TextEditingController();
  String _message = "";
  bool _isLoading = false;

  Future<void> uploadImage() async {
    final String apiUrl = "http://172.29.214.85:8000/api/upload/";

    try {
      // SharedPreferences에서 액세스 토큰 가져오기
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('authToken');

      if (token == null) {
        setState(() {
          _message = "로그인이 필요합니다.";
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _message = "";
      });

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // 요청 헤더에 토큰을 포함
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['tags'] = _tagController.text;
      request.fields['device_name'] = Platform.isAndroid ? "Android" : "iOS";

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        widget.selectedImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      var response = await request.send();

      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        setState(() {
          _message = "이미지 업로드 성공!";
        });
        // 업로드가 완료되면 현재 페이지를 닫고 이전 "로컬 이미지 관리" 페이지로 돌아감
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _message = "업로드 실패: 인증 오류 (로그인 필요)";
        });
      } else {
        setState(() {
          _message = "업로드 실패: ${response.statusCode} - ${responseBody}";
        });
      }
    } catch (e) {
      setState(() {
        _message = "업로드 중 오류 발생: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('이미지 업로드'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2.0),
                    ),
                    child: Image.file(
                      widget.selectedImage,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey,
                          child: Center(
                            child: Icon(Icons.broken_image),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    labelText: '태그 입력 (쉼표로 구분)',
                    border: OutlineInputBorder(),
                    hintText: '예: 여행, 풍경, 휴가',
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : uploadImage,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('업로드'),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
