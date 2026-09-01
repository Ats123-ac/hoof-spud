#!/usr/bin/env bash
# One-off generator for the farm TileSet resource.
# Enumerating ~300 atlas tiles by hand is error-prone, so the repetitive
# "X:Y/0 = 0" tile declarations are emitted programmatically.
set -euo pipefail

PROJECT="E:/games made by me/hoof & spud/hoof-&-spud"
OUT="$PROJECT/tilesets/farm_tileset.tres"
mkdir -p "$PROJECT/tilesets"

# Emit one tile declaration per atlas cell.
emit_tiles() {
  local cols=$1 rows=$2 x y
  for ((y = 0; y < rows; y++)); do
    for ((x = 0; x < cols; x++)); do
      printf '%d:%d/0 = 0\n' "$x" "$y"
    done
  done
}

TS="res://Assets/farming sprites/Tilesets"

{
  echo '[gd_resource type="TileSet" load_steps=15 format=3]'
  echo
  echo "[ext_resource type=\"Texture2D\" path=\"$TS/Grass.png\" id=\"1_grass\"]"
  echo "[ext_resource type=\"Texture2D\" path=\"$TS/Hills.png\" id=\"2_hills\"]"
  echo "[ext_resource type=\"Texture2D\" path=\"$TS/Tilled_Dirt.png\" id=\"3_dirt\"]"
  echo "[ext_resource type=\"Texture2D\" path=\"$TS/Water.png\" id=\"4_water\"]"
  echo "[ext_resource type=\"Texture2D\" path=\"$TS/Fences.png\" id=\"5_fence\"]"
  echo "[ext_resource type=\"Texture2D\" path=\"$TS/Wooden House.png\" id=\"6_house\"]"
  echo "[ext_resource type=\"Texture2D\" path=\"$TS/Doors.png\" id=\"7_door\"]"
  echo

  echo '[sub_resource type="TileSetAtlasSource" id="atlas_grass"]'
  echo 'resource_name = "Grass"'
  echo 'texture = ExtResource("1_grass")'
  echo 'texture_region_size = Vector2i(16, 16)'
  emit_tiles 11 7
  echo

  echo '[sub_resource type="TileSetAtlasSource" id="atlas_hills"]'
  echo 'resource_name = "Hills"'
  echo 'texture = ExtResource("2_hills")'
  echo 'texture_region_size = Vector2i(16, 16)'
  emit_tiles 11 9
  echo

  echo '[sub_resource type="TileSetAtlasSource" id="atlas_dirt"]'
  echo 'resource_name = "Tilled Dirt"'
  echo 'texture = ExtResource("3_dirt")'
  echo 'texture_region_size = Vector2i(16, 16)'
  emit_tiles 11 7
  echo

  # Water is one tile whose 4 atlas cells are animation frames, not 4 tiles.
  echo '[sub_resource type="TileSetAtlasSource" id="atlas_water"]'
  echo 'resource_name = "Water"'
  echo 'texture = ExtResource("4_water")'
  echo 'texture_region_size = Vector2i(16, 16)'
  echo '0:0/0 = 0'
  echo '0:0/animation_columns = 0'
  echo '0:0/animation_frames_count = 4'
  echo '0:0/animation_speed = 2.0'
  echo '0:0/animation_frame_0/duration = 1.0'
  echo '0:0/animation_frame_1/duration = 1.0'
  echo '0:0/animation_frame_2/duration = 1.0'
  echo '0:0/animation_frame_3/duration = 1.0'
  echo

  echo '[sub_resource type="TileSetAtlasSource" id="atlas_fence"]'
  echo 'resource_name = "Fences"'
  echo 'texture = ExtResource("5_fence")'
  echo 'texture_region_size = Vector2i(16, 16)'
  emit_tiles 4 4
  echo

  echo '[sub_resource type="TileSetAtlasSource" id="atlas_house"]'
  echo 'resource_name = "Wooden House"'
  echo 'texture = ExtResource("6_house")'
  echo 'texture_region_size = Vector2i(16, 16)'
  emit_tiles 7 5
  echo

  echo '[sub_resource type="TileSetAtlasSource" id="atlas_door"]'
  echo 'resource_name = "Doors"'
  echo 'texture = ExtResource("7_door")'
  echo 'texture_region_size = Vector2i(16, 16)'
  emit_tiles 1 4
  echo

  cat <<'RESOURCE'
[resource]
resource_name = "Farm TileSet"
tile_size = Vector2i(16, 16)
physics_layer_0/collision_layer = 1
terrain_set_0/mode = 0
terrain_set_0/terrain_0/name = "Grass"
terrain_set_0/terrain_0/color = Color(0.42, 0.72, 0.34, 1)
terrain_set_0/terrain_1/name = "Hills"
terrain_set_0/terrain_1/color = Color(0.36, 0.55, 0.28, 1)
terrain_set_0/terrain_2/name = "Tilled Dirt"
terrain_set_0/terrain_2/color = Color(0.55, 0.38, 0.26, 1)
terrain_set_0/terrain_3/name = "Water"
terrain_set_0/terrain_3/color = Color(0.35, 0.6, 0.85, 1)
custom_data_layer_0/name = "tillable"
custom_data_layer_0/type = 1
custom_data_layer_1/name = "tilled"
custom_data_layer_1/type = 1
sources/0 = SubResource("atlas_grass")
sources/1 = SubResource("atlas_hills")
sources/2 = SubResource("atlas_dirt")
sources/3 = SubResource("atlas_water")
sources/4 = SubResource("atlas_fence")
sources/5 = SubResource("atlas_house")
sources/6 = SubResource("atlas_door")
RESOURCE
} >"$OUT"

echo "wrote $OUT ($(wc -l <"$OUT") lines)"
