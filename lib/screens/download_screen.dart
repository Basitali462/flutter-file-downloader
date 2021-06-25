import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:flutter_download_file_app/resources/file_link.dart';
import 'package:flutter_download_file_app/resources/local_notification.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';


class DownloadPage extends StatefulWidget {
  DownloadPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  String _progress = '-';
  final Dio _dio = Dio();
  final fromKey = GlobalKey<FormState>();
  TextEditingController urlController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  bool loading = false;

  Future<void> _download() async{
    if(fromKey.currentState.validate()){
      setState(() {
        FileLink.fileUrl = urlController.text;
        FileLink.fileName = nameController.text;
        loading = true;
      });
      //print('url text ${urlController.text}');
      final dir = await _getDownloadDirectory();
      final isPermissionGranted = await _requestPermission(Permission.storage);
      if(isPermissionGranted){
        final savePath = path.join(dir.path, FileLink.fileName);
        await _startDownload(savePath);
      }
    }
  }

  Future<void> _startDownload(String savePath) async{
    Map<String, dynamic> result = {
      'isSuccess': false,
      'filePath': null,
      'error': null,
    };
    try{
      final resp = await _dio.download(
        FileLink.fileUrl,
        savePath,
        onReceiveProgress: _onReceiveProgress,
      );
      result['isSuccess'] = resp.statusCode == 200;
      result['filePath'] = savePath;
      print(resp.statusCode);
      urlController.clear();
      nameController.clear();
    }catch(e){
      result['error'] = e.toString();
    }finally{
      await NotificationPlugin().showNotification(result);
      setState(() {
        loading = false;
        _progress = '-';
      });
    }
  }

  Future<Directory> _getDownloadDirectory() async{
    if(Platform.isAndroid){
      return await DownloadsPathProvider.downloadsDirectory;
    }
    return await getApplicationDocumentsDirectory();
  }

  void _onReceiveProgress(int received, int total){
    if(total != -1){
      setState(() {
        _progress = (received / total * 100).toStringAsFixed(0) + "%";
      });
    }
  }

  Future<bool> _requestPermission(Permission permission) async{
    if(await permission.isGranted){
      return true;
    }else{
      var result = await permission.request();
      if(result == PermissionStatus.granted) {
        return true;
      }else{
        return false;
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //NotificationPlugin().init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
              child: Form(
                key: fromKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: urlController,
                      decoration: InputDecoration(
                        hintText: 'File url',
                      ),
                      validator: (value){
                        if(value.isEmpty || value == ''){
                          return 'Please Provide a URL';
                        }else{
                          return null;
                        }
                      },
                    ),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'File Name',
                      ),
                      validator: (value){
                        if(value.isEmpty || value == ''){
                          return 'Please Provide File Name';
                        }else{
                          return null;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            Text(
              'Download Progress',
            ),
            Text(
              '$_progress',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _download,
        child: loading ? CircularProgressIndicator(backgroundColor: Colors.white,) : Icon(Icons.file_download),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}