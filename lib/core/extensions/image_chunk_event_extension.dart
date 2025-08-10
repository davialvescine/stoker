import 'package:flutter/material.dart';

extension ImageChunkEventExtension on ImageChunkEvent {
  double sum(int current, int total) {
    return current / total;
  }
}
