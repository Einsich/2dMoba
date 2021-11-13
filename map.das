require daslib/media
require daslib/decs_boost

require utils

let mapN = 20;
let mapM = 30;
struct Map
    background : int[mapN * mapM]
var tiles : array<Image>

var map : Map
def init_tiles()
    tiles |> emplace(create_image("tileset/world_24x24/oryx_16bit_fantasy_world_835.png"))//grass0
    tiles |> emplace(create_image("tileset/world_24x24/oryx_16bit_fantasy_world_834.png"))//dirt1
    tiles |> emplace(create_image("tileset/world_24x24/oryx_16bit_fantasy_world_860.png"))//road2
    tiles |> emplace(create_image("tileset/world_24x24/oryx_16bit_fantasy_world_861.png"))//road break3
    tiles |> emplace(create_image("tileset/world_24x24/oryx_16bit_fantasy_world_831.png"))//gray2
    tiles |> emplace(create_image("tileset/world_24x24/oryx_16bit_fantasy_world_828.png"))
    tiles |> emplace(create_image("tileset/world_24x24/oryx_16bit_fantasy_world_829.png"))
    tiles |> emplace(create_image("tileset/world_24x24/oryx_16bit_fantasy_world_830.png"))
    tiles |> emplace(create_image("tileset/world_24x24/oryx_16bit_fantasy_world_832.png"))
    tiles |> emplace(create_image("tileset/world_24x24/oryx_16bit_fantasy_world_833.png"))
    map.background = [[ int[mapN * mapM]
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;2;2;2;2;3;2;3;2;2;2;3;2;3;3;3;2;2;2;3;1;1;1;1;1;1;
    0;0;0;0;0;3;2;2;2;3;2;2;3;2;2;3;2;2;2;3;3;2;3;2;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;
    0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1
    ]]

def init_map()
    create_entity <| @ (eid, cmp)
        cmp |> set("eid", eid)
        cmp |> set("mapPosition", float2(-float(mapM) * 0.5,-float(mapN) * 0.5))
        cmp |> set("tileScale", float2(1,1))


