import 'package:flutter/material.dart';
import 'package:vinnylock/app/app.dart';
import 'package:vinnylock/app/container.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(VinnyLockApp(container: AppContainer.production()));
}
