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
import 'package:smirror_frontend/src/systems/backend_socket.dart' as _i889;
import 'package:smirror_frontend/src/systems/google_calendar_service.dart' as _i45;
import 'package:smirror_frontend/src/systems/ha_data_service.dart' as _i471;
import 'package:smirror_frontend/src/systems/home_assistant_repo.dart' as _i816;
import 'package:smirror_frontend/src/systems/images.dart' as _i386;
import 'package:smirror_frontend/src/systems/logger.dart' as _i601;
import 'package:smirror_frontend/src/systems/pokemon_data_service.dart' as _i928;
import 'package:smirror_frontend/src/systems/token_service.dart' as _i132;
import 'package:smirror_frontend/src/systems/weather_service.dart' as _i185;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i889.BackendSocket>(
      () => _i889.BackendSocket(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i386.ImageService>(() => _i386.ImageService());
    gh.lazySingleton<_i928.PokemonDataService>(
      () => _i928.PokemonDataService(),
    );
    gh.lazySingleton<_i132.TokenService>(
      () => _i132.TokenService(gh<_i889.BackendSocket>()),
    );
    gh.lazySingleton<_i816.HomeAssistantRepository>(
      () => _i816.HomeAssistantRepository(gh<_i889.BackendSocket>()),
    );
    gh.singleton<_i601.Logger>(() => _i601.Logger(gh<_i889.BackendSocket>()));
    gh.lazySingleton<_i185.WeatherService>(
      () => _i185.WeatherService(gh<_i132.TokenService>()),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i45.GoogleCalendarService>(
      () => _i45.GoogleCalendarService(gh<_i132.TokenService>()),
    );
    gh.lazySingleton<_i471.HomeAssistantDataService>(
      () => _i471.HomeAssistantDataService(gh<_i132.TokenService>()),
    );
    return this;
  }
}
