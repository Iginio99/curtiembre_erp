import 'dart:async';
import 'dart:ui';

import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/app/app.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await configureDependencies();

    final talker = getIt<Talker>();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);

      talker.global(
        'Flutter capturó un error no controlado.',
        exception: details.exception,
        stackTrace: details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (
      Object error,
      StackTrace stackTrace,
    ) {
      talker.global(
        'PlatformDispatcher capturó un error no controlado.',
        exception: error,
        stackTrace: stackTrace,
      );

      return true;
    };

    runApp(const ErpCurtiembreApp());
  }, (Object error, StackTrace stackTrace) {
    final talker = getIt.isRegistered<Talker>() ? getIt<Talker>() : null;

    talker?.global(
      'La zona principal capturó un error no controlado.',
      exception: error,
      stackTrace: stackTrace,
    );
  });
}