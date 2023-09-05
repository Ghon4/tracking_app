import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

/// how to send local notifi
//NotificationHandler notificationHandler = NotificationHandler();
//
// // Inside a function or event handler, call the showLocalNotification method
// notificationHandler.showLocalNotification(
//   title: 'Notification Title',
//   body: 'Notification Body',
// );
class NotificationHandler {
  void initialize() {
    AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Channel',
        channelDescription: 'Channel for basic app topics',
        importance: NotificationImportance.High,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        playSound: true,
        vibrationPattern: lowVibrationPattern,
        ledColor: Colors.white,
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
    ]);
  }

  // Show a local notification
  Future<bool> showLocalNotification({
    required String title,
    required String body,
  }) async {
    final content = NotificationContent(
      id: 0,
      title: title,
      body: body,
      channelKey: 'basic_channel',
    );
    return await AwesomeNotifications().createNotification(content: content);
  }
}
