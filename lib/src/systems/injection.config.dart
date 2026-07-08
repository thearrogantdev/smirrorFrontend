// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:smirror_frontend/src/systems/backend_socket.dart' as _i938;
import 'package:smirror_frontend/src/systems/google_calendar_service.dart'
    as _i380;
import 'package:smirror_frontend/src/systems/google_tasks_service.dart'
    as _i806;
import 'package:smirror_frontend/src/systems/ha_data_service.dart' as _i958;
import 'package:smirror_frontend/src/systems/home_assistant_repo.dart' as _i855;
import 'package:smirror_frontend/src/systems/images.dart' as _i180;
import 'package:smirror_frontend/src/systems/logger.dart' as _i1034;
import 'package:smirror_frontend/src/systems/pokemon_data_service.dart' as _i32;
import 'package:smirror_frontend/src/systems/token_service.dart' as _i621;
import 'package:smirror_frontend/src/systems/weather_service.dart' as _i292;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i938.BackendSocket>(
      () => _i938.BackendSocket(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i180.ImageService>(() => _i180.ImageService());
    gh.lazySingleton<_i32.PokemonDataService>(() => _i32.PokemonDataService());
    gh.lazySingleton<_i621.TokenService>(
      () => _i621.TokenService(gh<_i938.BackendSocket>()),
    );
    gh.lazySingleton<_i958.HomeAssistantDataService>(
      () => _i958.HomeAssistantDataService(gh<_i621.TokenService>()),
    );
    gh.singleton<_i1034.Logger>(() => _i1034.Logger(gh<_i938.BackendSocket>()));
    gh.lazySingleton<_i855.HomeAssistantRepository>(
      () => _i855.HomeAssistantRepository(gh<_i938.BackendSocket>()),
    );
    gh.factory<_i380.GoogleCalendarService>(
      () => _i380.GoogleCalendarService(gh<_i621.TokenService>()),
    );
    gh.factory<_i806.GoogleTasksService>(
      () => _i806.GoogleTasksService(gh<_i621.TokenService>()),
    );
    gh.lazySingleton<_i292.WeatherService>(
      () => _i292.WeatherService(gh<_i621.TokenService>()),
      dispose: (i) => i.dispose(),
    );
    return this;
  }
}
