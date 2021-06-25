import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';

class NotificationPlugin{
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void init(){
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    if(Platform.isIOS){
      requestPermission();
    }
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iOS = IOSInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        /*onDidReceiveLocalNotification: (id, title, body, payload) async{
          ReceivedNotification receivedNotification = ReceivedNotification(
            id: id,
            title: title,
            body: body,
            payload: payload,
          );
          didReceiveLocalNotification.add(receivedNotification);
        }*/
    );

    final initSettings = InitializationSettings(android: android, iOS: iOS);

    flutterLocalNotificationsPlugin.initialize(initSettings, onSelectNotification: _onSelectNotification);
  }

  requestPermission(){
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        .requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _onSelectNotification(String json) async {
    // todo: handling clicked notification
    final obj = jsonDecode(json);
    if(obj['isSuccess']){
      OpenFile.open(obj['filePath']);
    }
  }

  Future<void> showNotification(Map<String, dynamic> status) async{
    final android = AndroidNotificationDetails(
      'CHANNEL_ID',
      'CHANNEL_NAME',
      'CHANNEL_DESC',
    );
    final iOS = IOSNotificationDetails();
    final platform = NotificationDetails(android: android, iOS: iOS);
    final json = jsonEncode(status);
    final isSuccess = status['isSuccess'];

    await flutterLocalNotificationsPlugin.show(
      0,
      isSuccess ? 'Success' : 'Failure',
      isSuccess ? 'File Downloaded Successfully' : 'There is an error downloading file',
      platform,
      payload: json,
    );
  }
}

/*
class ReceivedNotification{
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });
}*/
