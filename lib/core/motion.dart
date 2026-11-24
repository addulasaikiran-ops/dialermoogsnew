import 'package:flutter/material.dart';

/// Returns zero when the platform requests reduced motion.
Duration moogMs(BuildContext context, int ms) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : Duration(milliseconds: ms);
