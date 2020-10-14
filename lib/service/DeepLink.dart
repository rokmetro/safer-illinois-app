/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:uni_links/uni_links.dart';

class DeepLink with Service {
  static const String notifyUri = "edu.illinois.rokwire.deeplink.uri";

  List<Uri> _urisCache;

  static final DeepLink _deepLink = DeepLink._internal();

  factory DeepLink() {
    return _deepLink;
  }

  DeepLink._internal();

  @override
  void createService() {
    // Differentiate initial uri from updated uri

    // Cache uris until UI is displayed
    _urisCache = List<Uri>();

    // 1. Initial Uri
    getInitialUri().then((uri) {
      _notifyUri(uri);
    });

    // 2. Updated uri
    getUriLinksStream().listen((Uri uri) async {
      NotificationService().notify(notifyUri, uri);
    });
  }

  @override
  void initServiceUI() {
    // Make delay as the root panel is not build yet
    Timer(Duration(seconds: 2), _notifyCachedUris);
  }

  void _notifyCachedUris() {
    if (_urisCache != null) {
      List<Uri> urisCache = _urisCache;
      _urisCache = null;
      for (Uri uri in urisCache) {
        _notifyUri(uri);
      }
    }
  }

  void _notifyUri(Uri uri) {
    if (uri != null) {
      if (_urisCache != null) {
        _urisCache.add(uri);
      } else {
        NotificationService().notify(notifyUri, uri);
      }
    }
  }
}
