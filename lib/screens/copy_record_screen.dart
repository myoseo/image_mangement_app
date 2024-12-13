import 'package:flutter/material.dart';
import 'local_image_management_screen.dart';
import 'remote_image_screen.dart';

class CopyRecordScreen extends StatefulWidget {
  final List<Map<String, dynamic>> copyRecords;

  CopyRecordScreen({required this.copyRecords});

  @override
  _CopyRecordScreenState createState() => _CopyRecordScreenState();
}

class _CopyRecordScreenState extends State<CopyRecordScreen> {
  int _selectedIndex = 2; // '복사 기록' 페이지가 기본 선택된 상태

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // 이미 선택된 페이지인 경우 리턴

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LocalImageManagementScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RemoteImageGalleryScreen()),
        );
        break;
      case 2:
        // 현재 페이지이므로 아무 작업도 하지 않음
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('복사 기록'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: widget.copyRecords.isEmpty
            ? Center(child: Text('복사된 이미지가 없습니다.'))
            : ListView.builder(
                itemCount: widget.copyRecords.length,
                itemBuilder: (context, index) {
                  final record = widget.copyRecords[index];
                  return ListTile(
                    title: Text('복사된 시간: ${record['timestamp']}'),
                    leading: Image.network(
                      record['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    onTap: () {
                      // 해당 이미지를 다시 복사하는 기능 구현
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('해당 이미지가 다시 클립보드에 복사되었습니다.')),
                      );
                    },
                  );
                },
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: '로컬',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: '내 저장소',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.content_copy),
            label: '복사 기록',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
