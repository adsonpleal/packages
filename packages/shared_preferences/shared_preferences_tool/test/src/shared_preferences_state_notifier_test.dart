// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:devtools_app_shared/service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences_tool/src/async_state.dart';
import 'package:shared_preferences_tool/src/shared_preferences_state.dart';
import 'package:shared_preferences_tool/src/shared_preferences_state_notifier.dart';
import 'package:shared_preferences_tool/src/shared_preferences_tool_eval.dart';

@GenerateNiceMocks(<MockSpec<dynamic>>[
  MockSpec<SharedPreferencesToolEval>(),
  MockSpec<ConnectedApp>()
])
import 'shared_preferences_state_notifier_test.mocks.dart';

void main() {
  group('SharedPreferencesStateNotifier', () {
    late MockSharedPreferencesToolEval evalMock;
    late SharedPreferencesStateNotifier notifier;

    setUpAll(() {
      provideDummy(const SharedPreferencesData.int(value: 42));
    });

    setUp(() {
      evalMock = MockSharedPreferencesToolEval();
      notifier = SharedPreferencesStateNotifier(evalMock);
    });

    test('should start in the loading state', () {
      expect(
        notifier.value,
        equals(const AsyncState<SharedPreferencesState>.loading()),
      );
    });

    test('should fetch all keys', () async {
      const List<String> keys = <String>['key1', 'key2'];
      when(evalMock.fetchAllKeys()).thenAnswer((_) async => keys);

      await notifier.fetchAllKeys();

      expect(
        notifier.value,
        equals(
          const AsyncState<SharedPreferencesState>.data(
            SharedPreferencesState(
              allKeys: keys,
            ),
          ),
        ),
      );
    });

    test('should select key', () async {
      const List<String> keys = <String>['key1', 'key2'];
      const SharedPreferencesData keyValue =
          SharedPreferencesData.string(value: 'value');
      when(evalMock.fetchAllKeys()).thenAnswer((_) async => keys);
      when(evalMock.fetchValue('key1')).thenAnswer((_) async => keyValue);
      await notifier.fetchAllKeys();

      await notifier.selectKey('key1');

      expect(
        notifier.value,
        equals(
          const AsyncState<SharedPreferencesState>.data(
            SharedPreferencesState(
              allKeys: keys,
              selectedKey: SelectedSharedPreferencesKey(
                key: 'key1',
                value: AsyncState<SharedPreferencesData>.data(keyValue),
              ),
            ),
          ),
        ),
      );
    });

    test('should filter keys and clear filter', () async {
      const List<String> keys = <String>['key1', 'key2'];
      when(evalMock.fetchAllKeys()).thenAnswer((_) async => keys);
      await notifier.fetchAllKeys();

      notifier.filter('key1');

      expect(
        notifier.value,
        equals(
          const AsyncState<SharedPreferencesState>.data(
            SharedPreferencesState(
              allKeys: <String>['key1'],
            ),
          ),
        ),
      );

      notifier.filter('');

      expect(
        notifier.value,
        equals(
          const AsyncState<SharedPreferencesState>.data(
            SharedPreferencesState(
              allKeys: keys,
            ),
          ),
        ),
      );
    });

    test('should start/stop editing', () async {
      const List<String> keys = <String>['key1', 'key2'];
      when(evalMock.fetchAllKeys()).thenAnswer((_) async => keys);
      await notifier.fetchAllKeys();
      notifier.startEditing();

      expect(
        notifier.value,
        equals(
          const AsyncState<SharedPreferencesState>.data(
            SharedPreferencesState(
              allKeys: keys,
              editing: true,
            ),
          ),
        ),
      );

      notifier.stopEditing();

      expect(
        notifier.value,
        equals(
          const AsyncState<SharedPreferencesState>.data(
            SharedPreferencesState(
              allKeys: keys,
              // ignore: avoid_redundant_argument_values
              editing: false,
            ),
          ),
        ),
      );
    });

    test('should change value', () async {
      const List<String> keys = <String>['key1', 'key2'];
      const SharedPreferencesData keyValue =
          SharedPreferencesData.string(value: 'value');
      when(evalMock.fetchAllKeys()).thenAnswer((_) async => keys);
      when(evalMock.fetchValue('key1')).thenAnswer((_) async => keyValue);
      await notifier.fetchAllKeys();
      await notifier.selectKey('key1');

      await notifier.deleteKey(notifier.value.dataOrNull!.selectedKey!.key);

      verify(evalMock.deleteKey('key1')).called(1);
    });

    test('should change value', () async {
      const List<String> keys = <String>['key1', 'key2'];
      const SharedPreferencesData keyValue =
          SharedPreferencesData.string(value: 'value');
      when(evalMock.fetchAllKeys()).thenAnswer((_) async => keys);
      when(evalMock.fetchValue('key1')).thenAnswer((_) async => keyValue);
      await notifier.fetchAllKeys();
      await notifier.selectKey('key1');

      await notifier.changeValue(
        'key1',
        const SharedPreferencesData.string(value: 'newValue'),
      );

      verify(
        evalMock.changeValue(
          'key1',
          const SharedPreferencesData.string(value: 'newValue'),
        ),
      ).called(1);
    });
  });
}