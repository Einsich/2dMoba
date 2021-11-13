require daslib/media
require daslib/decs_boost
require daslib/random
var peasantAnimIdx : int = -1
var footmanAnimIdx : int = -1
var elfAnimIdx : int = -1
var mageAnimIdx : int = -1

var peonAnimIdx : int = -1
var orcAnimIdx : int = -1
var trollAnimIdx : int = -1
var ogreAnimIdx : int = -1

var daemonAnimIdx : int = -1
var dkAnimIdx : int = -1
var gryphonAnimIdx : int = -1
var knightAnimIdx : int = -1


let AnimCount = 5
let AnimStates = 4
let IDLE = 0
let MOVE = 1
let ATTACK = 2
let DEATH = 3
struct AnimList
    list : array<float4>[AnimCount]
struct Animation
    imageIdx : int
    states : AnimList[AnimStates]


var animations : array<Animation>
var images : array<Image>


        
def add_image(path : string)
    let lastIdx = length(images)
    images |> emplace(create_image(path))
    return lastIdx

def add_animation(path : string; move, attack, death : int)
    let lastIdx = length(images)
    images |> emplace(create_image(path))
    let img : Image& = images[lastIdx]
    let lastAnim = length(animations);
    animations |> emplace([[Animation imageIdx = lastIdx]])
    let count = 1 + move + attack + death

    let width = img.width / AnimCount
    let height = img.height / count
    let stateOffsets = [[int[] 0; 1; 1 + move; 1 + move + attack]]
    var anim : Animation& = animations[lastAnim]
    for state in range(AnimStates)
        for i in range(AnimCount)
            for j in range(move)
                let x = i * width
                let y = (j + stateOffsets[state]) * height
                anim.states[state].list[i] |> emplace(float4(x, y, width, height))
        
    return lastAnim

def import_animations()
    
    peasantAnimIdx = add_animation("tileset/animations/peasant.png", 4, 5, 3)
    footmanAnimIdx = add_animation("tileset/animations/footman.png",4, 4, 3)
    elfAnimIdx = add_animation("tileset/animations/elven_archer.png", 3, 3, 3)
    mageAnimIdx = add_animation("tileset/animations/mage.png", 4, 4, 7)

    peonAnimIdx = add_animation("tileset/animations/peon.png", 4, 5, 3)
    orcAnimIdx = add_animation("tileset/animations/grunt.png", 4, 4, 3)
    trollAnimIdx = add_animation("tileset/animations/troll.png", 4, 4, 3)
    ogreAnimIdx = add_animation("tileset/animations/ogre.png", 4, 4, 5)

    daemonAnimIdx = add_animation("tileset/animations/daemon.png", 4, 5, 5)
    dkAnimIdx = add_animation("tileset/animations/death_knight.png", 4, 4, 4)
    gryphonAnimIdx = add_animation("tileset/animations/gryphon_rider.png", 3, 3, 6)
    knightAnimIdx = add_animation("tileset/animations/knight.png", 4, 4, 5)


def init_melee(var cmp; attackRadius, attackSector : float)
    cmp |> set("attackRadius", attackRadius)
    cmp |> set("attackSector", attackSector)
def init_ranger(var cmp; attackRadius, shellSpeed : float; shellType : int)
    cmp |> set("attackRadius", attackRadius)
    cmp |> set("shellSpeed", shellSpeed)
    cmp |> set("shellType", shellType)



def init_unit(var cmp;
        animIdx, team : int;
        scale, speed, attackSpeed, hpMax, hpReduction, damage: float;
        position : float2)
    cmp |> set("animIdx", animIdx)
    cmp |> set("position", position)
    cmp |> set("scale", float2(scale, scale))
    cmp |> set("collisionRadius", scale * 0.25)
    cmp |> set("animProgress", 0.0)
    cmp |> set("team", team)
    cmp |> set("direction", 0)
    cmp |> set("damage", damage)
    cmp |> set("state", 0)
    cmp |> set("isMovable", true)
    cmp |> set("isCollidable", true)
    cmp |> set("isActive", true)
    cmp |> set("speed", speed)
    cmp |> set("madeAttack", false)
    cmp |> set("attackSpeed", attackSpeed)
    cmp |> set("attackTime", length(animations[animIdx].states[ATTACK].list[0]))
    cmp |> set("deathTime", length(animations[animIdx].states[DEATH].list[0]))
    cmp |> set("hpMax", hpMax)
    cmp |> set("hp", hpMax)
    cmp |> set("hpReduction", hpReduction)
    cmp |> set("lookAngle", 0.0)
    cmp |> set("heroKillerTeam", -1)

def create_hero(animIdx, team, hero, level: int;
        scale, speed, attackSpeed, hpMax, hpReduction, damage, xp, nextLevel : float;
        position : float2)
    
    create_entity <| @ (eid, cmp)
        cmp |> set("eid", eid)
        cmp |> set("hero", hero)
        cmp |> set("isCreep", false)
        cmp |> set("xp", xp)
        cmp |> set("level", level)
        cmp |> set("nextLevel", nextLevel)
        init_unit(cmp, animIdx, team, scale, speed, attackSpeed, hpMax, hpReduction, damage, position)
        if hero == 0
            init_ranger(cmp, 3.0, 3.5, 0)
        elif hero == 1
            init_ranger(cmp, 3.0, 3.5, 5)
            //init_melee(cmp, 1.05, PI * 0.5)

def spawn_hero(targetTeam : int; position : float2)
    
    if targetTeam == 0
        create_hero(gryphonAnimIdx, 0, 0, 1, 1.0, 3.0, 1.5, 800.0, 10.0, 15.0, 0.0, 10.0, position)
    else
        create_hero(dkAnimIdx, 1, 1, 1, 1.0, 3.0, 1.5, 800.0, 10.0, 15.0, 0.0, 10.0, position)

struct Creep
    scale, speed, attackSpeed, hpMax, hpReduction, damage : float
    rangeType, animId : int

def create_creep(team, level : int;
        var creep : Creep;
        position : float2;
        spawnEid : EntityId)
    create_entity <| @ (eid, cmp)
        cmp |> set("eid", eid)
        cmp |> set("isCreep", true)
        cmp |> set("agrRadius", 3.4)
        cmp |> set("spawnEid", spawnEid)
        cmp |> set("isNeutral", team > 1)
        let levelBonus = 1.0 + float(level) * 0.2
        let levelScale = 1.0 + float(level) * 0.1
        init_unit(cmp, creep.animId, team,
            creep.scale * levelScale,
            creep.speed,
            creep.attackSpeed * levelBonus,
            creep.hpMax * levelBonus,
            creep.hpReduction * levelBonus,
            creep.damage * levelBonus,
            position)
        if creep.rangeType < 0
            init_melee(cmp, 0.75, PI * 0.5)
        else
            let attackRadius = creep.animId == ogreAnimIdx ? 1.9 : 3.0
            let shellSpeed = creep.animId == ogreAnimIdx ? 3.0 : 3.5
            init_ranger(cmp, attackRadius, shellSpeed, creep.rangeType)

var unitSeed = int4(908, 008,77, 898)
def spawn_creeps(team, level : int; position : float2; eid : EntityId)
    var creeps = [[Creep
        scale = 1.0, speed = 1.2, attackSpeed = 1.2, hpMax = 250.0, hpReduction = 4.0, damage = 10.0, rangeType = -1, animId = peasantAnimIdx;
        scale = 1.0, speed = 1.2, attackSpeed = 1.8, hpMax = 500.0, hpReduction = 10.0, damage = 20.0, rangeType = -1, animId = footmanAnimIdx;
        scale = 1.0, speed = 1.4, attackSpeed = 1.3, hpMax = 250.0, hpReduction = 4.0, damage = 15.0, rangeType =  1, animId = elfAnimIdx;
        scale = 1.0, speed = 1.1, attackSpeed = 0.8, hpMax = 100.0, hpReduction = 2.0, damage = 30.0, rangeType =  2, animId = mageAnimIdx;

        scale = 1.0, speed = 1.2, attackSpeed = 1.2, hpMax = 250.0, hpReduction = 4.0, damage = 10.0, rangeType = -1, animId = peonAnimIdx;
        scale = 1.0, speed = 1.2, attackSpeed = 1.8, hpMax = 500.0, hpReduction = 10.0, damage = 20.0, rangeType = -1, animId = orcAnimIdx;
        scale = 1.0, speed = 1.5, attackSpeed = 1.1, hpMax = 250.0, hpReduction = 10.0, damage = 18.0, rangeType =  3, animId = trollAnimIdx;
        scale = 1.0, speed = 0.7, attackSpeed = 0.7, hpMax = 400.0, hpReduction = 15.0, damage = 30.0, rangeType =  4, animId = ogreAnimIdx
    ]]
    var creepsTypes : array<int>[6] 

    creepsTypes[0] <- [{int 1;1;1;2;2}]
    creepsTypes[1] <- [{int 5;5;5;6;6}]
    creepsTypes[2] <- [{int 0;0;0;0}]
    creepsTypes[3] <- [{int 0;0;0;0;3;3}]
    creepsTypes[4] <- [{int 4;4;4;4}]
    creepsTypes[5] <- [{int 4;4;4;4;7;7}]
    
    let creepsCount = length(creepsTypes[team])
    for i in range(creepsCount)
        let randInDisk = random_in_unit_disk(unitSeed)
        let offset = float2(randInDisk.x, randInDisk.y)

        create_creep(team, level, creeps[creepsTypes[team][i]], position + offset, eid)
    return creepsCount
