
require daslib/decs_boost
require map
let BuildingCount = 3
let M = 130
let H = 100
let T = 69

let buildingsAllianceSubregs : float4[BuildingCount] =[[auto[]
    float4(M*1,0,M,M);
    float4(H*3,2*M+2*H-4,H,H);
    float4(M*3+T,0,T,T)]]

let buildingsHordeSubregs : float4[BuildingCount] = [[auto[]
    float4(M*3,0,M,M);
    float4(H*1,1*M+2*H-2,H,H);
    float4(M*3+10,1*M+4*H+T-10,T,T-4)]]

let CASTLE = 0
let BARRACK = 1
let TOWER = 2


[decs_template]
struct Sprite
    imageIdx : int
    region : float4


def create_building(texId, team, building_type, level : int; position : float2)
    let sizes = [[float[BuildingCount] 2.0;1.5;1.0]]
    let hpMax = [[float[BuildingCount] 4500.0;2750.0;1750.0]]
    let scale = sizes[building_type] * (1.0 + float(level)*0.3)
    let hp = hpMax[building_type] * (1.0 + float(level)*0.3)
    let buildingSprite = team == 0 ? buildingsAllianceSubregs[building_type] : buildingsHordeSubregs[building_type]
    create_entity <| @ (eid, cmp)
        cmp |> set("eid", eid)
        cmp |> set("position", position)
        cmp |> set("orientation", 0.0)
        cmp |> set("scale", float2(scale, scale))
        cmp |> set("collisionRadius", scale * 0.5)
        cmp |> set("team", team)
        cmp |> set("isBuilding", true)
        cmp |> set("isActive", true)
        cmp |> set("isCollidable", true)
        cmp |> set("buildingType", building_type)
        cmp |> set("hpMax", hp)
        cmp |> set("hp", hp)
        cmp |> set("heroKillerTeam", -1)
        cmp |> apply_decs_template([[Sprite imageIdx = texId, region = buildingSprite]])
        if building_type == BARRACK
            cmp |> set("isBarrack", true)
            cmp |> set("reinforcementProgress", 0.9999)
            cmp |> set("reinforcementTime", 30.0)
            cmp |> set("spawnOffset", scale * float2(team == 0 ? 1.0 : -1.0, 0.0))
        elif building_type == TOWER
            let towerAS = [[float[2] 0.7; 1.5]]
            let towerDM = [[float[2] 100.0; 200.0]]
            let towerRad= [[float[2] 3.5; 4.0]]
            cmp |> set("isTower", true)
            cmp |> set("attackSpeed", towerAS[level])
            cmp |> set("attackRadius", towerRad[level])
            cmp |> set("shellSpeed", 5.1)
            cmp |> set("shellType", 1)
            cmp |> set("damage", towerDM[level])
            cmp |> set("attackProgress", 0.0)
        elif building_type == CASTLE
            cmp |> set("isCastle", true)
            cmp |> set("respawning", true)
            cmp |> set("respawnProgress", 1.0)
            cmp |> set("respawnTime", 5.0)



let BuildingInstanceCount = 6
def create_base(texId, team : int)
    let Border = float(mapM) * 0.5
    let BuildingTypes = [[int[BuildingInstanceCount]
        CASTLE;
        BARRACK;
        TOWER;
        TOWER;
        TOWER;
        TOWER
    ]]
    let BuildingLevels = [[int[BuildingInstanceCount]
        0;
        0;
        1;
        1;
        0;
        0
    ]]
    let BuildingPos = [[float2[BuildingInstanceCount]
        float2(Border-1.0, 0.0);
        float2(Border-3.5, 0.0);
        float2(Border-4.5, 1.5);
        float2(Border-4.5, -1.5);
        float2(Border*0.3, 2.0);
        float2(Border*0.3, -2.0)
    ]]
    for i in range(BuildingInstanceCount)
        var pos = BuildingPos[i]
        if team == 0
            pos.x = -pos.x
        pos.x -= 0.5
        create_building(texId, team, BuildingTypes[i], BuildingLevels[i], pos)

def create_neutral_camp(position : float2; team : int)
    create_entity <| @ (eid, cmp)
        cmp |> set("eid", eid)
        cmp |> set("position", position)
        cmp |> set("isBarrack", true)
        cmp |> set("reinforcementProgress", 0.999)
        cmp |> set("reinforcementTime", 30.0)
        cmp |> set("collisionRadius", 1.7)
        cmp |> set("team", team)
        cmp |> set("spawnOffset", float2(0,0))
