import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

class LocalImageManagementScreen extends StatefulWidget {
  @override
  _LocalImageManagementScreenState createState() =>
      _LocalImageManagementScreenState();
}

class _LocalImageManagementScreenState
    extends State<LocalImageManagementScreen> {
  List<Directory> _directories = [];
  List<File> _images = [];
  Directory? _selectedDirectory;
  File? _selectedFile;
  Directory? _selectedFolder;

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // 앱 실행 시 권한 요청
  }

  // 저장소 권한 요청 함수
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (!await Permission.manageExternalStorage.isGranted) {
        PermissionStatus status =
            await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장소 접근 권한이 필요합니다. 앱 설정에서 권한을 허용해주세요.')),
          );
          return;
        }
      }
    } else {
      PermissionStatus status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장소 접근 권한이 필요합니다. 앱 설정에서 권한을 허용해주세요.')),
          );
          return;
        }
      }
    }
  }

  // 폴더를 선택하는 함수
  Future<void> _pickDirectory() async {
    String? selectedPath = await FilePicker.platform.getDirectoryPath();

    if (selectedPath != null) {
      Directory selectedDirectory = Directory(selectedPath);

      if (_directories.any((dir) => dir.path == selectedDirectory.path)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미 추가된 폴더입니다.')),
        );
        return;
      }

      setState(() {
        _directories.add(selectedDirectory);
        _selectDirectory(selectedDirectory);
      });
    }
  }

  // 디렉토리를 선택했을 때의 콜백
  void _selectDirectory(Directory directory) {
    setState(() {
      _selectedDirectory = directory;
      _selectedFolder = directory;
      _selectedFile = null; // 선택된 폴더가 있을 때 파일은 선택되지 않음
    });

    _loadImages(directory);
  }

  // 선택된 디렉토리 내의 이미지 파일들을 로드하는 함수
  Future<void> _loadImages(Directory directory) async {
    try {
      print("이미지 로드를 시도하는 디렉토리: ${directory.path}");

      final List<FileSystemEntity> files =
          directory.listSync(recursive: false, followLinks: false);
      final List<File> images = files
          .where((file) => file is File && _isImageFile(file.path))
          .map((file) => File(file.path))
          .toList();

      setState(() {
        _images = images;
      });

      print("디렉토리: ${directory.path} 안에 이미지 개수: ${_images.length}");
      for (var image in _images) {
        print("이미지 파일 경로: ${image.path}");
      }
    } catch (e) {
      print("이미지를 불러오는 중 오류 발생: $e");
    }
  }

  // 파일이 이미지인지 확인하는 함수
  bool _isImageFile(String path) {
    final String extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension);
  }

  // 파일이나 폴더를 선택하는 함수
  void _toggleSelection(File? file, Directory? folder) {
    setState(() {
      if (file != null) {
        if (_selectedFile == file) {
          _selectedFile = null; // 선택 해제
        } else {
          _selectedFile = file;
          _selectedFolder = null; // 파일을 선택했으므로 폴더 선택 해제
        }
      } else if (folder != null) {
        if (_selectedFolder == folder) {
          _selectedFolder = null; // 선택 해제
        } else {
          _selectedFolder = folder;
          _selectedFile = null; // 폴더를 선택했으므로 파일 선택 해제
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로컬 이미지 관리'),
        actions: [
          IconButton(
            icon: Icon(Icons.cloud_upload),
            onPressed: () {
              if (_selectedFile != null) {
                Navigator.pushNamed(
                  context,
                  '/upload',
                  arguments: {'selectedImage': _selectedFile},
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('업로드할 파일을 선택해주세요.')),
                );
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // 왼쪽에 있는 폴더 목록
          Expanded(
            flex: 1,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await _requestPermissions();
                    await _pickDirectory(); // 폴더를 선택 후 바로 이미지를 로드
                  },
                  child: Text('추가'),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _directories.length,
                    itemBuilder: (context, index) {
                      String folderName =
                          _directories[index].path.split('/').last;
                      bool isSelected = _selectedFolder == _directories[index];
                      return ListTile(
                        title: Text(folderName),
                        tileColor: isSelected ? Colors.blue.shade100 : null,
                        onTap: () =>
                            _toggleSelection(null, _directories[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 오른쪽에 있는 이미지 목록
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: _images.isEmpty
                      ? Center(child: Text('이미지가 없습니다.'))
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4.0,
                            mainAxisSpacing: 4.0,
                          ),
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            bool isSelected = _selectedFile == _images[index];
                            return GestureDetector(
                              onTap: () =>
                                  _toggleSelection(_images[index], null),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: Image.file(
                                  _images[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey,
                                      child: Center(
                                          child: Icon(Icons.broken_image)),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
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
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.popAndPushNamed(context, '/local_management');
              break;
            case 1:
              Navigator.popAndPushNamed(context, '/remote_image');
              break;
            case 2:
              Navigator.popAndPushNamed(context, '/copy_record');
              break;
          }
        },
      ),
    );
  }
}
