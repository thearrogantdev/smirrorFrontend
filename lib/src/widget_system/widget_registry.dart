import 'package:flutter/material.dart';
import 'package:smirror_wire/generated/view_view_structure_generated.dart' as bfmsg;
import 'package:smirror_wire/constants/widget_ids.dart';
import 'package:smirror_frontend/src/widgets/bus_stop_widget.dart';
import 'package:smirror_frontend/src/widgets/calendar_widget.dart';
import 'package:smirror_frontend/src/widgets/calendar_widget_two_days.dart';
import 'package:smirror_frontend/src/widgets/entertain/cat_gif.dart';
import 'package:smirror_frontend/src/widgets/entertain/cat_image.dart';
import 'package:smirror_frontend/src/widgets/entertain/pokemon_of_the_day.dart';
import 'package:smirror_frontend/src/widgets/entertain/pokemon_random.dart';
import 'package:smirror_frontend/src/widgets/entertain/random_compliment.dart';
import 'package:smirror_frontend/src/widgets/entertain/random_dog.dart';
import 'package:smirror_frontend/src/widgets/entertain/random_insult.dart';
import 'package:smirror_frontend/src/widgets/entertain/useless_fact.dart';
import 'package:smirror_frontend/src/widgets/haDashboards/ha_multi_dashboard.dart';
import 'package:smirror_frontend/src/widgets/haDashboards/ha_single_dashboard.dart';
import 'package:smirror_frontend/src/widgets/image_widget.dart';
import 'package:smirror_frontend/src/widgets/text_widget.dart';
import 'package:smirror_frontend/src/widgets/weather_current_widget.dart';
import 'package:smirror_frontend/src/widgets/weather_forecast_widget.dart';
import 'package:smirror_frontend/src/widgets/system_usage_widget.dart';
import 'package:smirror_frontend/src/widgets/rain_radar_widget.dart';
import 'package:smirror_frontend/src/widgets/digital_clock_widget.dart';
import 'package:smirror_frontend/src/widgets/google_tasks_widget.dart';
import 'package:smirror_frontend/src/widgets/rain_forecast_widget.dart';

typedef WidgetBuilderFunction = Widget Function(bfmsg.Widget widgetData);

class WidgetRegistry {
  static Widget create(int widgetId, bfmsg.Widget widgetData) {
    return switch (widgetId) {
      WidgetIds.textWidget          => TextWidget(widgetData: widgetData),
      WidgetIds.image               => ImageWidget(widgetData: widgetData),
      WidgetIds.weatherCurrent      => WeatherSmallWidget(widgetData: widgetData),
      WidgetIds.weatherForecast     => WeatherForecastWidget(widgetData: widgetData),
      WidgetIds.googleCalendarUpcoming => CalendarWidget(widgetData: widgetData),
      WidgetIds.singleHADashboard   => HASingleDashboard(widgetData: widgetData),
      WidgetIds.cataasImage         => CataasImageWidget(widgetData: widgetData),
      WidgetIds.cataasGif           => CataasGitWidget(widgetData: widgetData),
      WidgetIds.randomDog           => RandomDogWidget(widgetData: widgetData),
      WidgetIds.pokemonOfTheDay     => PokemonOfTheDayWidget(widgetData: widgetData),
      WidgetIds.randomPokemon       => RandomPokemonWidget(widgetData: widgetData),
      WidgetIds.randomCompliment    => RandomComplimentWidget(widgetData: widgetData),
      WidgetIds.randomInsult        => RandomInsultWidget(widgetData: widgetData),
      WidgetIds.randomUselessFact   => RandomUselessFact(widgetData: widgetData),
      WidgetIds.multiHADashboard    => MultiHADashboardWidget(widgetData: widgetData),
      WidgetIds.busStop             => BusStopDisplayWidget(widgetData: widgetData),
      WidgetIds.googleCalendarTwoDays => CalendarTwoDaysWidget(widgetData: widgetData),
      WidgetIds.systemUsage         => SystemUsageWidget(widgetData: widgetData),
      WidgetIds.rainRadar           => RainRadarWidget(widgetData: widgetData),
      WidgetIds.digitalClock        => DigitalClockWidget(widgetData: widgetData),
      WidgetIds.googleTasks         => GoogleTasksDisplayWidget(widgetData: widgetData),
      WidgetIds.rainForecast        => RainForecastWidget(widgetData: widgetData),
      _                             => const Icon(Icons.error, color: Colors.red),
    };
  }
}
