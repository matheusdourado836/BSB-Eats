import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'local_notification_widget.dart';

OverlaySupportEntry showNotification({
  required String title,
  String? subtitle,
  String? image,
  String? route,
  String? arguments,
}) {
  return showSimpleNotification(
    background: Colors.transparent,
    elevation: 0,
    slideDismissDirection: DismissDirection.vertical,
    duration: const Duration(seconds: 5),
    LocalNotificationWidget(
      title: title,
      subtitle: subtitle,
      image: image,
      route: route,
      arguments: arguments,
    )
  );
}