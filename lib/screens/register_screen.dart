import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = "";

  String getApiUrl() {
    if (Platform.isAndroid) {
      return "http://172.29.214.85:8000/api/register/";
    } else if (Platform.isIOS) {
      return "http://localhost:8000/api/register/";
    } else {
      return "http://127.0.0.1:8000/api/register/";
    }
  }

  Future<void> registerUser() async {
    final String apiUrl = getApiUrl();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": _usernameController.text,
          "name": _nameController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _message = "회원가입 성공";
        });

        // 회원가입 성공 후 입력 필드 초기화 및 1초 후 로그인 화면으로 돌아감
        Future.delayed(Duration(seconds: 1), () {
          _resetFields();
          Navigator.pop(context); // 로그인 화면으로 이동
        });
      } else {
        final Map<String, dynamic> responseData =
            json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _message =
              "회원가입 실패: ${response.statusCode} - ${responseData['message']}";
        });
      }
    } catch (e) {
      setState(() {
        _message = "오류 발생: $e";
      });
    }
  }

  void _resetFields() {
    _usernameController.clear();
    _nameController.clear();
    _passwordController.clear();
    setState(() {
      _message = ""; // 상태 메시지 초기화
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("회원가입"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "아이디"),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "이름"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "비밀번호"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: registerUser,
              child: Text("회원가입"),
            ),
            SizedBox(height: 20),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
