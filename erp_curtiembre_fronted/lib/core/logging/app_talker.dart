import 'package:talker_flutter/talker_flutter.dart';

abstract final class AppTalkerKeys {
  static const String ui = 'ui';
  static const String cubit = 'cubit';
  static const String repository = 'repository';
  static const String dataSource = 'data-source';
  static const String storage = 'storage';
  static const String global = 'global';

  static const List<String> registered = <String>[
    ui,
    cubit,
    repository,
    dataSource,
    storage,
    global,
  ];
}

enum AppLogLayer { ui, cubit, repository, dataSource, storage, global }

extension AppLogLayerX on AppLogLayer {
  String get key => switch (this) {
    AppLogLayer.ui => AppTalkerKeys.ui,
    AppLogLayer.cubit => AppTalkerKeys.cubit,
    AppLogLayer.repository => AppTalkerKeys.repository,
    AppLogLayer.dataSource => AppTalkerKeys.dataSource,
    AppLogLayer.storage => AppTalkerKeys.storage,
    AppLogLayer.global => AppTalkerKeys.global,
  };

  String get title => switch (this) {
    AppLogLayer.ui => 'ui',
    AppLogLayer.cubit => 'cubit',
    AppLogLayer.repository => 'repository',
    AppLogLayer.dataSource => 'data-source',
    AppLogLayer.storage => 'storage',
    AppLogLayer.global => 'global',
  };

  LogLevel get defaultLevel => switch (this) {
    AppLogLayer.ui => LogLevel.debug,
    AppLogLayer.cubit => LogLevel.info,
    AppLogLayer.repository => LogLevel.info,
    AppLogLayer.dataSource => LogLevel.debug,
    AppLogLayer.storage => LogLevel.debug,
    AppLogLayer.global => LogLevel.error,
  };

  AnsiPen get pen => switch (this) {
    AppLogLayer.ui => AnsiPen()..xterm(45),
    AppLogLayer.cubit => AnsiPen()..xterm(81),
    AppLogLayer.repository => AnsiPen()..xterm(111),
    AppLogLayer.dataSource => AnsiPen()..xterm(141),
    AppLogLayer.storage => AnsiPen()..xterm(214),
    AppLogLayer.global => AnsiPen()..red(),
  };
}

class AppTalkerLog extends TalkerLog {
  AppTalkerLog({
    required AppLogLayer layer,
    required String message,
    LogLevel? logLevel,
    Object? exception,
    StackTrace? stackTrace,
  }) : super(
         message,
         key: layer.key,
         title: layer.title,
         pen: layer.pen,
         logLevel: logLevel ?? layer.defaultLevel,
         exception: exception,
         stackTrace: stackTrace,
       );
}

Talker createAppTalker() {
  final settings = TalkerSettings(
    enabled: true,
    useConsoleLogs: true,
    useHistory: true,
    maxHistoryItems: 2000,
    titles: <String, String>{
      AppTalkerKeys.ui: 'ui',
      AppTalkerKeys.cubit: 'cubit',
      AppTalkerKeys.repository: 'repository',
      AppTalkerKeys.dataSource: 'data-source',
      AppTalkerKeys.storage: 'storage',
      AppTalkerKeys.global: 'global',
    },
    colors: <String, AnsiPen>{
      AppTalkerKeys.ui: AppLogLayer.ui.pen,
      AppTalkerKeys.cubit: AppLogLayer.cubit.pen,
      AppTalkerKeys.repository: AppLogLayer.repository.pen,
      AppTalkerKeys.dataSource: AppLogLayer.dataSource.pen,
      AppTalkerKeys.storage: AppLogLayer.storage.pen,
      AppTalkerKeys.global: AppLogLayer.global.pen,
    },
  );
  settings.registerKeys(AppTalkerKeys.registered);
  return TalkerFlutter.init(settings: settings);
}

extension AppTalkerX on Talker {
  void ui(
    String message, {
    LogLevel logLevel = LogLevel.debug,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    logCustom(
      AppTalkerLog(
        layer: AppLogLayer.ui,
        message: message,
        logLevel: logLevel,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  void cubit(
    String message, {
    LogLevel logLevel = LogLevel.info,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    logCustom(
      AppTalkerLog(
        layer: AppLogLayer.cubit,
        message: message,
        logLevel: logLevel,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  void repository(
    String message, {
    LogLevel logLevel = LogLevel.info,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    logCustom(
      AppTalkerLog(
        layer: AppLogLayer.repository,
        message: message,
        logLevel: logLevel,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  void dataSource(
    String message, {
    LogLevel logLevel = LogLevel.debug,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    logCustom(
      AppTalkerLog(
        layer: AppLogLayer.dataSource,
        message: message,
        logLevel: logLevel,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  void storage(
    String message, {
    LogLevel logLevel = LogLevel.debug,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    logCustom(
      AppTalkerLog(
        layer: AppLogLayer.storage,
        message: message,
        logLevel: logLevel,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  void global(
    String message, {
    LogLevel logLevel = LogLevel.error,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    logCustom(
      AppTalkerLog(
        layer: AppLogLayer.global,
        message: message,
        logLevel: logLevel,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }
}
