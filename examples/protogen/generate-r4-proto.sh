#!/bin/bash
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ROOT_PATH=../..
INPUT_PATH=$ROOT_PATH/spec/hl7.fhir.core/4.0.0/package/
PROTO_GENERATOR=$ROOT_PATH/bazel-bin/java/ProtoGenerator

OUTPUT_PATH="$(dirname $0)/../../proto/r4/"
DESCRIPTOR_OUTPUT_PATH="$(dirname $0)/../../testdata/r4/descriptors/"
FHIR_PROTO_ROOT="proto/r4"
FHIR_STRUCT_DEF_ZIP="$ROOT_PATH/bazel-genfiles/spec/fhir_r4_structure_definitions.zip"
FHIR_PACKAGE_INFO="$ROOT_PATH//spec/fhir_r4_package_info.prototxt"

COMMON_FLAGS=" \
  --emit_proto \
  --emit_descriptors \
  --fhir_proto_root $FHIR_PROTO_ROOT \
  --package_info $FHIR_PACKAGE_INFO \
  --struct_def_dep_pkg $FHIR_STRUCT_DEF_ZIP|$FHIR_PACKAGE_INFO \
  --output_directory $OUTPUT_PATH \
  --descriptor_output_directory $DESCRIPTOR_OUTPUT_PATH "
#
# Build the binary.
bazel build //java:ProtoGenerator

if [ $? -ne 0 ]
then
 echo "Build Failed"
 exit 1;
fi

# generate datatypes.proto
$PROTO_GENERATOR \
  $COMMON_FLAGS \
  --output_name datatypes \
  --input_bundle $INPUT_PATH/Bundle-types.json \
  --exclude Reference \
  --exclude Extension

# Some datatypes are manually generated.
# These include:
# * FHIR-defined valueset codes
# * Proto for Reference, which allows more structure than FHIR spec provides.
# * Extension, which has a field order discrepancy between spec and test data.
# TODO: generate Extension proto with custom ordering.
# TODO: generate codes.proto
if [ $? -eq 0 ]
then
  echo -e "\n//End of auto-generated messages.\n" >> $OUTPUT_PATH/datatypes.proto
  cat "$(dirname $0)/r4/datatypes_supplement.txt" >> $OUTPUT_PATH/datatypes.proto
fi

# generate resources.proto
$PROTO_GENERATOR \
  $COMMON_FLAGS \
  --include_contained_resource \
  --output_name resources \
  --input_bundle $INPUT_PATH/Bundle-resources.json

# generate profiles.proto
# exclude familymemberhistory-genetic due to
# https://gforge.hl7.org/gf/project/fhir/tracker/?action=TrackerItemEdit&tracker_id=677&tracker_item_id=19239
# TODO: enable once profiles are vetted
# $PROTO_GENERATOR \
#   $COMMON_FLAGS \
#   --output_name profiles \
#   --input_bundle $INPUT_PATH/Bundle-profiles-others.json \
#   --exclude familymemberhistory-genetic


# generate extensions
$PROTO_GENERATOR \
  $COMMON_FLAGS \
  --output_name extensions \
  --input_bundle $INPUT_PATH/Bundle-extensions.json
