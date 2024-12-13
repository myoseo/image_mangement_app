import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ImageDetailScreen.dart';
import 'local_image_management_screen.dart';
import 'copy_record_screen.dart';

List<Map<String, dynamic>> copyRecords = [];

class RemoteImageGalleryScreen extends StatefulWidget {
  @override
  _RemoteImageGalleryScreenState createState() =>
      _RemoteImageGalleryScreenState();
}

class _RemoteImageGalleryScreenState extends State<RemoteImageGalleryScreen> {
  List<dynamic> _images = [];
  List<String> _deviceOptions = ["모든 장치"];
  String _selectedDevice = "모든 장치";
  String _searchTag = "";
  bool _isLoading = false;

  int _selectedIndex = 1; // '내 저장소' 페이지가 기본 선택된 상태

  @override
  void initState() {
    super.initState();
    _fetchDeviceList();
    _fetchImages();
  }

  // 서버에서 업로드된 디바이스 목록을 가져오는 함수
  Future<void> _fetchDeviceList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    String apiUrl = "http://192.168.0.100:8000/api/device_list/";

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        List<String> deviceList = List<String>.from(json.decode(response.body));
        setState(() {
          _deviceOptions = ["모든 장치", ...deviceList];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('디바이스 목록을 불러오는 중 오류가 발생했습니다. (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버와의 연결에 실패했습니다. 오류: $e')),
      );
    }
  }

  // 서버에서 이미지 목록을 가져오는 함수
  Future<void> _fetchImages({String? deviceName, String? tag}) async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    Uri uri = Uri.parse("http://172.29.214.85:8000/api/list_images/");
    Map<String, String> queryParams = {};
    if (deviceName != null && deviceName != "모든 장치") {
      queryParams['device_name'] = deviceName;
    }
    if (tag != null && tag.isNotEmpty) {
      queryParams['tag'] = tag;
    }
    uri = uri.replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> images = json.decode(response.body);

        // 각 이미지에 download_link 생성 추가
        for (var image in images) {
          image['download_link'] =
              'http://172.29.214.85:8000/media/${image['filename']}';
        }

        setState(() {
          _images = images;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('이미지 목록을 불러오는 중 오류가 발생했습니다. (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버와의 연결에 실패했습니다. 오류: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 검색 기능
  void _searchImages() {
    _fetchImages(tag: _searchTag);
  }

  // 검색 초기화 기능 (전체 이미지 보기)
  void _resetSearch() {
    _searchTag = "";
    _fetchImages();
  }

  // 디바이스 필터링 기능
  void _filterByDevice() {
    String? deviceFilter = _selectedDevice == "모든 장치" ? null : _selectedDevice;
    _fetchImages(deviceName: deviceFilter);
  }

  // 네비게이션 탭 선택 핸들러
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => LocalImageManagementScreen()),
          );
        }
        break;
      case 1:
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CopyRecordScreen(copyRecords: copyRecords)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 저장소'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      _searchTag = value;
                    },
                    decoration: InputDecoration(
                      labelText: '태그로 검색',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchImages,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedDevice,
              items: _deviceOptions
                  .map((device) => DropdownMenuItem<String>(
                        value: device,
                        child: Text(device),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDevice = value!;
                });
                _filterByDevice();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _images.isEmpty
                    ? Center(child: Text('업로드된 이미지가 없습니다.'))
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                        ),
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          final image = _images[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ImageDetailScreen(imageData: image),
                                ),
                              );
                            },
                            child: Image.network(
                              image['download_link'],
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                } else {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  (loadingProgress
                                                          .expectedTotalBytes ??
                                                      1)
                                              : null,
                                    ),
                                  );
                                }
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey,
                                  child: Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
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
