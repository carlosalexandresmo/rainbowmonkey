import 'package:flutter/foundation.dart';

import 'search.dart';
import 'string.dart';

@immutable
class Event extends SearchResult implements Comparable<Event> {
  const Event({
    @required this.id,
    @required this.title,
    @required this.official,
    this.following = false,
    this.description,
    @required this.location,
    @required this.startTime,
    @required this.endTime,
  }) : assert(id != null),
       assert(title != null),
       assert(official != null),
       assert(following != null),
       assert(location != null),
       assert(startTime != null),
       assert(endTime != null);

  final String id; // 16 bytes in hex
  final String title;
  final bool official;
  final bool following;
  final TwitarrString description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;

  @override
  int compareTo(Event other) {
    if (startTime.isBefore(other.startTime))
      return -1;
    if (startTime.isAfter(other.startTime))
      return 1;
    if (endTime.isBefore(other.endTime))
      return -1;
    if (endTime.isAfter(other.endTime))
      return 1;
    if (official && !other.official)
      return -1;
    if (other.official && !official)
      return 1;
    if (location != other.location)
      return location.compareTo(other.location);
    if (title != other.title)
      return title.compareTo(other.title);
    return id.compareTo(other.id);
  }

  bool startsDuring(DateTime startWindow, DateTime endWindow) {
    return startTime.isAfter(startWindow) && startTime.isBefore(endWindow);
  }

  @override
  String toString() => 'Event("$title")';
}

@immutable
class Calendar {
  factory Calendar({
    @required List<Event> events,
  }) {
    assert(events != null);
    return Calendar._(events.toList()..sort());
  }

  const Calendar._(this._events);

  final List<Event> _events;
  List<Event> get events => _events;

  Iterable<Event> upcoming(DateTime serverTime, Duration window) sync* {
    for (Event event in events) {
      if (event.following && event.startsDuring(serverTime, serverTime.add(window)))
        yield event;
    }
  }

  static String getHours(DateTime time, { @required bool use24Hour }) {
    if (use24Hour)
      return '${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}';
    if (time.hour == 12 && time.minute == 00)
      return '12:00nn';
    final String minute = time.minute.toString().padLeft(2, '0');
    final String suffix = time.hour < 12 ? 'am' : 'pm';
    if (time.hour == 00 || time.hour == 12)
      return '12:$minute$suffix';
    return '${(time.hour % 12).toString()}:$minute$suffix';
  }

  @override
  String toString() => 'Calendar($events)';
}

class UpcomingCalendar extends Calendar {
  factory UpcomingCalendar({
    @required List<Event> events,
    @required DateTime serverTime,
  }) {
    assert(events != null);
    return UpcomingCalendar._(events.toList()..sort(), serverTime);
  }

  const UpcomingCalendar._(List<Event> events, this.serverTime) : super._(events);

  final DateTime serverTime;

  @override
  String toString() => 'UpcomingCalendar($serverTime; $events)';
}
