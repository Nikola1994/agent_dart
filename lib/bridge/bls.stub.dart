// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'bls.base.dart';

/// Implemented in `browser_client.dart` and `io_client.dart`.
BaseBLS createBLS() => throw UnsupportedError(
      'Cannot create a client without dart:html or dart:io.',
    );
