require daslib/media
require daslib/decs_boost
var aspectRatio : float = 1.0
var cameraScale : float = 100.0
var cemaraPosition : float2 = float2(1,1)
var seed = int4(10,1,100,1314)
var killsStatictic : int2
var towersFalls : int2
var defeatTeam = -1

def world_to_screen_pos(var pos : float2)
    pos = (pos - cemaraPosition) * cameraScale;
    pos = pos * float2(1, -1) + float2(0.5, 0.5)
    return pos

def world_to_screen_size(size : float2)
    return size * cameraScale

def create_camera()
    create_entity <| @ (eid, cmp)
        cmp |> set("eid", eid)
        cmp |> set("isCamera", true)
        cmp |> set("target0", float2(0,0))
        cmp |> set("target1", float2(0,0))