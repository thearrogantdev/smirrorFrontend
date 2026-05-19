import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'src/app.dart';
import 'src/bloc/view_cubit.dart';
import 'src/systems/injection.dart';
import 'src/systems/backend_socket.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();

  await GetIt.I.allReady();

  runApp(
      MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ViewCubit(getIt<BackendSocket>()),
      child: const App(),
    );
  }
}
