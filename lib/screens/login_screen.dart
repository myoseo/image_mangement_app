import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = "";

  Future<void> loginUser(String username, String password) async {
    final String apiUrl = "http://172.29.214.85:8000/api/login/";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": username,
          "password": password,
        }),
      );

      // 서버 응답 상태 코드와 본문 로그 추가
      print("서버 응답 상태 코드: ${response.statusCode}");
      print("서버 응답 본문: ${response.body}");

      if (response.statusCode == 200) {
        // UTF-8로 서버 응답을 디코딩하여 JSON 처리
        try {
          final responseData = json.decode(utf8.decode(response.bodyBytes));

          // 응답 로그를 통해 서버가 어떤 데이터를 반환하는지 확인
          print("서버에서 받은 응답 데이터: $responseData");

          // 응답에서 'access' 키를 사용하여 토큰을 가져옴
          if (responseData.containsKey('access')) {
            String accessToken = responseData['access'];

            // SharedPreferences에 토큰 저장
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('authToken', accessToken);

            // 로그인 성공 메시지 설정 및 화면 전환
            setState(() {
              _message = "로그인 성공!";
            });

            // 화면 전환 로그 추가
            print("로그인 성공! 로컬 이미지 관리 화면으로 이동 시도 중...");
            Navigator.pushReplacementNamed(context, '/local_management');
          } else {
            // 서버 응답에 'access' 키가 없을 때 로그 및 메시지 추가
            setState(() {
              _message = "로그인 중 오류 발생: 서버 응답에 'access' 토큰이 없습니다.";
            });
            print("서버 응답에 'access' 토큰이 없습니다: $responseData");
          }
        } catch (e) {
          // JSON 파싱 오류가 발생하면, HTML 응답일 수 있음
          setState(() {
            _message = "로그인 중 오류 발생: 서버에서 예상치 못한 응답을 보냈습니다.";
          });
          print("JSON 파싱 오류: $e");
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _message = "로그인 실패: 아이디 또는 비밀번호가 잘못되었습니다.";
        });
      } else {
        setState(() {
          _message = "로그인 중 오류 발생: ${utf8.decode(response.bodyBytes)}";
        });
      }
    } catch (e) {
      setState(() {
        _message = "서버와의 연결에 실패했습니다: $e";
      });
    } finally {
      _resetFields();
    }
  }

  void _resetFields() {
    _usernameController.clear();
    _passwordController.clear();
    // 상태 메시지는 초기화하지 않음 (사용자에게 정보 제공 목적)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: '아이디'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String username = _usernameController.text.trim();
                String password = _passwordController.text.trim();
                if (username.isNotEmpty && password.isNotEmpty) {
                  loginUser(username, password);
                } else {
                  setState(() {
                    _message = "아이디와 비밀번호를 입력하세요.";
                  });
                }
              },
              child: Text('로그인'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text('회원가입'),
            ),
            SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
