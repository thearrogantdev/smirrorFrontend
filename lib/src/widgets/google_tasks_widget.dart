import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smirror_frontend/src/systems/injection.dart';
import 'package:smirror_frontend/src/systems/google_tasks_service.dart';
import 'package:smirror_wire/constants/widget_ids.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class GoogleTasksDisplayWidget extends SmirrorStatefulWidget {
  const GoogleTasksDisplayWidget({super.key, required super.widgetData});

  @override
  State<GoogleTasksDisplayWidget> createState() => _GoogleTasksDisplayWidgetState();
}

class _GoogleTasksDisplayWidgetState extends SmirrorState<GoogleTasksDisplayWidget> {
  late Future<List<GTask>> _future;

  // Properties
  late String _fontFamily;
  late double _fontSize;
  late String _taskListId;

  @override
  void initState() {
    super.initState();

    _taskListId = propString(widget.widgetData.properties, PropertyIdsGoogleTasksWidget.taskListId) ?? '@default';
    _fontSize = (propInt(widget.widgetData.properties, PropertyIdsGoogleTasksWidget.fontSize) ?? 14).toDouble();
    _fontFamily = propString(widget.widgetData.properties, PropertyIdsGoogleTasksWidget.fontFamily) ?? 'Roboto';

    final tasksService = getIt<GoogleTasksService>();
    _future = tasksService.getTodayTasks(taskListId: _taskListId);
  }

  @override
  Widget buildContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headerStyle = GoogleFonts.getFont(
      _fontFamily,
      fontSize: _fontSize * 1.1,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: FutureBuilder<List<GTask>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          if (snap.hasError || !snap.hasData) {
            return const Center(
              child: Icon(
                Icons.report_problem_outlined,
                color: Colors.white24,
                size: 24,
              ),
            );
          }

          final tasks = snap.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_box_outlined,
                    size: _fontSize * 1.3,
                    color: cs.primary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Tasks",
                    style: headerStyle,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (tasks.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: _fontSize * 1.8,
                          color: cs.primary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "All caught up!",
                          style: GoogleFonts.getFont(
                            _fontFamily,
                            fontSize: _fontSize * 0.95,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: tasks.length,
                    itemBuilder: (context, idx) {
                      final t = tasks[idx];
                      return _TaskItemTile(
                        task: t,
                        fontSize: _fontSize,
                        fontFamily: _fontFamily,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TaskItemTile extends StatelessWidget {
  final GTask task;
  final double fontSize;
  final String fontFamily;

  const _TaskItemTile({
    required this.task,
    required this.fontSize,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.getFont(
      fontFamily,
      fontSize: fontSize,
      color: Colors.white.withValues(alpha: 0.9),
    );
    final notesStyle = GoogleFonts.getFont(
      fontFamily,
      fontSize: fontSize * 0.8,
      color: Colors.white38,
      fontStyle: FontStyle.italic,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant circular indicator
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.radio_button_unchecked,
              size: fontSize * 0.9,
              color: Colors.white38,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: titleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.notes != null && task.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.notes!,
                    style: notesStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
