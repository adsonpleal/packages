// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../shared_preferences.dart';

const String _eventPrefix = 'shared_preferences:';

typedef _PostEvent = void Function(
  String eventKind,
  Map<String, Object?> eventData,
);

/// A helper class that provides data to the devtool extension.
///
/// It is only visible for testing and eval.
@visibleForTesting
class DevtoolsExtension {
  /// The default constructor for [DevtoolsExtension].
  ///
  /// Accepts an optional [_PostEvent] that should only be overwritten when testing.
  DevtoolsExtension([this._postEvent = developer.postEvent]);

  final _PostEvent _postEvent;

  /// Requests all legacy and async keys and post an event with the result.
  Future<void> requestAllKeys() async {
    final SharedPreferences legacyPrefs = await SharedPreferences.getInstance();
    final Set<String> legacyKeys = legacyPrefs.getKeys();
    final Set<String> asyncKeys = await SharedPreferencesAsync().getKeys();

    _postEvent('${_eventPrefix}all_keys', <String, List<String>>{
      'asyncKeys': asyncKeys.toList(),
      'legacyKeys': legacyKeys.toList(),
    });
  }

  /// Requests the value for a given key and post and event with the result.
  Future<void> requestValue(String key, bool legacy) async {
    final Object? value;
    if (legacy) {
      final SharedPreferences legacyPrefs =
          await SharedPreferences.getInstance();
      value = legacyPrefs.get(key);
    } else {
      value = await SharedPreferencesAsync().getAll(allowList: <String>{
        key
      }).then((Map<String, Object?> map) => map.values.firstOrNull);
    }

    _postEvent('${_eventPrefix}value', <String, Object?>{
      'value': value,
      'kind': value.runtimeType.toString(),
    });
  }

  /// Requests the a value change for the give key and post an empty event when finished;
  Future<void> requestValueChange(
    String key,
    String serializedValue,
    String kind,
    bool legacy,
  ) async {
    final Object? value = jsonDecode(serializedValue);
    if (legacy) {
      final SharedPreferences legacyPrefs =
          await SharedPreferences.getInstance();
      // we need to check the kind because sometimes a double
      // gets interpreted as an int. If this was not and issue
      // we'd only need to do a simple pattern matching on value.
      switch (kind) {
        case 'int':
          await legacyPrefs.setInt(key, value! as int);
        case 'bool':
          await legacyPrefs.setBool(key, value! as bool);
        case 'double':
          await legacyPrefs.setDouble(key, value! as double);
        case 'String':
          await legacyPrefs.setString(key, value! as String);
        case 'List<String>':
          await legacyPrefs.setStringList(key, value! as List<String>);
      }
    } else {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      // we need to check the kind because sometimes a double
      // gets interpreted as an int. If this was not and issue
      // we'd only need to do a simple pattern matching on value.
      switch (kind) {
        case 'int':
          await prefs.setInt(key, value! as int);
        case 'bool':
          await prefs.setBool(key, value! as bool);
        case 'double':
          await prefs.setDouble(key, value! as double);
        case 'String':
          await prefs.setString(key, value! as String);
        case 'List<String>':
          await prefs.setStringList(key, value! as List<String>);
      }
    }
    _postEvent('${_eventPrefix}change_value', <String, Object?>{});
  }

  /// Requests a key removal and post an empty event when removed.
  Future<void> requestRemoveKey(String key, bool legacy) async {
    if (legacy) {
      final SharedPreferences legacyPrefs =
          await SharedPreferences.getInstance();
      await legacyPrefs.remove(key);
    } else {
      await SharedPreferencesAsync().remove(key);
    }
    _postEvent('${_eventPrefix}remove', <String, Object?>{});
  }
}
