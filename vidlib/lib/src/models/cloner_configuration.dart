import 'dart:convert';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:vidlib/vidlib.dart';
import '../serializers.dart';
part 'cloner_configuration.g.dart';

// Contains all the information required to perform a clone operation for a
// single source collection
abstract class ClonerConfiguration
    implements Built<ClonerConfiguration, ClonerConfigurationBuilder> {
  // Specifies which feed manager to use, and the arguments to configure it
  ClonerTaskArgs get feedManager;

  // Specifies which downloader to use, and the arguments to configure it
  ClonerTaskArgs get downloader;

  // Specifies which media converter to use, and the arguments to configure it
  ClonerTaskArgs get mediaConverter;

  // Specifies which uploader to use, and the arguments to configure it
  ClonerTaskArgs get uploader;

  // The builder pattern is required by built_value, which we use for
  // serialization
  ClonerConfiguration._();
  factory ClonerConfiguration(
      [Function(ClonerConfigurationBuilder b) updates]) = _$ClonerConfiguration;
  factory ClonerConfiguration.fromJson(String json) {
    final data = jsonDecode(json);
    return jsonSerializers.deserialize(data) as ClonerConfiguration;
  }

  static Serializer<ClonerConfiguration> get serializer =>
      _$clonerConfigurationSerializer;
}
