import 'dart:convert';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:vidlib/vidlib.dart';
import '../serializers.dart';
part 'cloner_configuration.g.dart';

// Contains all the information required to perform a clone operation
abstract class ClonerConfiguration
    implements Built<ClonerConfiguration, ClonerConfigurationBuilder> {
  // The single-word name of the feed to create or use (e.g. "gamegrumps").
  // This will be used in the url for the feed resulting from the clone. To
  // avoid collisions, this should be unique among all ClonerConfigurations
  // used.
  String get feedName;

  // A human-readable name that can be used for display purposes
  String get displayName;

  // Identifies the source collection of videos to clone
  SourceCollection get sourceCollection;

  // Specifies which media converter to use, and the arguments to configure it
  MediaConversionArgs get mediaConversionArgs;

  // The id of the uploader to use
  String get uploaderId;

  // The id of the feed manager to use
  String get feedManagerId;

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
