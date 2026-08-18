import 'dart:async';

import 'package:erp_curtiembre_fronted/app/router/app_router.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_theme.dart';
import 'package:erp_curtiembre_fronted/core/theme/theme_mode_controller.dart';
import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ErpCurtiembreApp extends StatefulWidget {
  const ErpCurtiembreApp({super.key});

  @override
  State<ErpCurtiembreApp> createState() => _ErpCurtiembreAppState();
}

class _ErpCurtiembreAppState extends State<ErpCurtiembreApp> {
  late final AuthCubit _authCubit;
  late final AppRouter _appRouter;
  late final ThemeModeController _themeModeController;
  late final SecurityAccessCubit _securityAccessCubit;
  StreamSubscription<AuthState>? _authSubscription;
  int? _loadedAccessForUserId;

  @override
  void initState() {
    super.initState();
    _authCubit = getIt<AuthCubit>();
    _securityAccessCubit = getIt<SecurityAccessCubit>();
    _authSubscription = _authCubit.stream.listen(_syncSecurityAccess);
    _authCubit.bootstrap();
    _appRouter = AppRouter(_authCubit, _securityAccessCubit);
    _themeModeController = getIt<ThemeModeController>();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _securityAccessCubit.close();
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider<SecurityAccessCubit>.value(value: _securityAccessCubit),
      ],
      child: AnimatedBuilder(
        animation: _themeModeController,
        builder: (context, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'ERP Curtiembre',
          themeMode: _themeModeController.themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          routerConfig: _appRouter.router,
          builder: (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: AppBreakpoints.breakpoints,
          ),
        ),
      ),
    );
  }

  void _syncSecurityAccess(AuthState state) {
    final session = state.session;
    if (state.status == AuthStatus.authenticated && session != null) {
      if (_loadedAccessForUserId != session.usuarioId) {
        _loadedAccessForUserId = session.usuarioId;
        _securityAccessCubit.load(usuarioId: session.usuarioId);
      }
      return;
    }
    if (state.status == AuthStatus.unauthenticated) {
      _loadedAccessForUserId = null;
      _securityAccessCubit.clear();
    }
  }
}
