require daslib/media
require daslib/decs_boost
require daslib/math
require daslib/random
//options debugger            // uncomment for debug in VS Code
//require daslib/debug        // uncomment for debug in VS Code

require utils
require buildings
require map
require units
require menu


var gameStarted : bool

var effectsIdx, allianceIdx, hordeIdx : int 

def create_shell(team, typeIdx : int;
        position : float2;
        orientation, scale, raduis, speed, damage : float;
        fromHero: bool)
    let N = 24
    let M = 32

    let shellRegions : float4[6] = [[auto[]
    float4(N*12,M*2,M,M);//gryp
    float4(N,N*18,N,N);//elf
    float4(N,N*13,N,N);//mage
    float4(N*12+M*2,M*3,M,M);//troll
    float4(N*12,M*5,M,M);//ogre
    float4(N*12+M*3,M*4,M,M)//dk
    ]]
    let radius = scale * 0.5
    create_entity <| @ (eid, cmp)
        cmp |> set("eid", eid)
        cmp |> set("position", position)
        cmp |> set("orientation", orientation)
        cmp |> set("speed", speed)
        cmp |> set("lifetime", raduis/speed)
        cmp |> set("curtime", 0.0)
        cmp |> set("scale", float2(scale, scale))
        cmp |> set("radius", scale * 0.5)
        cmp |> set("team", team)
        cmp |> set("fromHero", fromHero)
        cmp |> set("damage", damage)
        cmp |> apply_decs_template([[Sprite imageIdx = effectsIdx, region = shellRegions[typeIdx]]])

[export]
def initialize(hard:bool)
    set_resolution(get_desktop_width(), get_desktop_height())
    aspectRatio = float(get_screen_width()) /  float(get_screen_height())
    set_window_title("Einsich") 

    init_tiles()
    import_animations()
    allianceIdx = add_image("tileset/alliance.png")
    hordeIdx = add_image("tileset/horde.png")
    effectsIdx = add_image("tileset/effects.png")
    load_menu_pictures()
    if hard 
        gameStarted = false


def start_game()
 
    gameStarted = true
    create_camera()
    init_map() 
    create_base(allianceIdx, 0)
    create_base(hordeIdx, 1)
    let offsets = [[float2
        float2(-0.9, -0.9);float2(0.0, -0.9);float2(0.9, -0.9);
        float2(-0.9, 0.9);float2(0.0, 0.9);float2(0.9, 0.9)
    ]]
    let types = [[int
        4;3;2;
        4;5;2
    ]]
    for i in range(6)
        let offset = float2(float(mapM)*0.5,float(mapN)*0.5) * offsets[i]
        create_neutral_camp(offset, types[i])
    commit()

[decs(stage = logic)]
def health_hp( hpMax, hpReduction : float; var hp : float&)
    if hp > 0.0
        hp += hpReduction * get_delta_time()
        if hp > hpMax
            hp = hpMax
    else
        hp = -1.0

[decs(stage = logic)]
def update_xp(var level :int&; var xp, nextLevel, hp, hpMax, hpReduction, damage, attackSpeed : float&)
    if xp >= nextLevel
        xp -= nextLevel
        nextLevel += float(level * 4)
        level += 1
        hpMax += 95.0
        hp += 95.0
        hpReduction += 2.6
        damage += 9.5
        attackSpeed += 0.10
        print("new level[{level}] hp {hpMax} hp red {hpReduction} damage {damage} attack speed {attackSpeed}\n")

[decs(stage = logic)]
def hero_spawn(isCastle : bool; var respawning : bool&;
        team : int; position : float2;
        var respawnProgress : float&;
        respawnTime : float)
    if respawning

        respawnProgress += get_delta_time() / respawnTime
        if respawnProgress >= 1.0
            let spawnPos = position + float2(0,-2)
            let targetTeam = team
            let found = find_query() <| $ (hero, team : int;
                    var isActive, isCollidable, isMovable : bool&;
                    var position : float2&;
                    var hp : float&; hpMax : float;
                    var state : int&)
                if team == targetTeam
                    isActive = true
                    isCollidable = true
                    isMovable = true
                    hp = hpMax
                    position = spawnPos
                    state = IDLE
                    return true
            if !found
                spawn_hero(team, spawnPos)
            respawning = false
            respawnProgress = 0.0

[decs(stage = logic)]
def update_hero_death(
        hp : float;
        team, hero, level : int)
    if hp <= 0.0
        let myTeam = team
        query() <| $ (isCastle : bool; var respawning : bool&; team : int; var respawnTime : float& )
            if myTeam == team && !respawning
                respawning = true
                respawnTime = 5.0 + float(level) * 2.0
                killsStatictic[team] += 1
    
[decs(stage = logic)]
def update_death(eid : EntityId;
        hp : float;
        deathTime, heroKillerTeam, team : int;
        var state : int&;
        position : float2;
        var animProgress : float&;
        var isCollidable, isMovable, isActive : bool&;
        isCreep : bool)
    if hp <= 0.0
        if state != DEATH
            state = DEATH
            animProgress = 0.0
            isCollidable = false
            isMovable = false
            let myTeam = team
            let myPos = position
            query() <| $ (team, hero : int; var xp : float&; position : float2)
                if team != myTeam && length(position - myPos) < 5.0
                    let defExp = isCreep ? 1.0 : 5.0
                    xp += defExp * (heroKillerTeam == team ? 5.0 : 1.0)

        animProgress += get_delta_time()
        if animProgress >= float(deathTime)
            if isCreep
                delete_entity(eid)
            else
                isActive = false


[decs(stage = logic)]
def update_building_destroy(eid : EntityId; hp : float; isBuilding : bool; position : float2; team, heroKillerTeam, buildingType : int)
    if hp <= 0.0
        let myTeam = team
        let myPos = position
        query() <| $ (team, hero : int; var xp : float&; position : float2)
            if team != myTeam && length(position - myPos) < 3.0
                xp += heroKillerTeam == team ? 50.0 : 10.0
        if buildingType == CASTLE
            defeatTeam = team
        elif buildingType == TOWER
            if team == 0
                towersFalls.x += 1
            else
                towersFalls.y += 1
        delete_entity(eid)

        
    
[decs(stage = logic)]
def update_barrack_spawn(
        eid : EntityId;
        isBarrack : bool;
        var reinforcementProgress : float&;
        reinforcementTime, collisionRadius: float;
        team : int;
        position, spawnOffset : float2)
    if reinforcementProgress < 1.0
        reinforcementProgress += get_delta_time() / reinforcementTime
    else
        var blocked = false
        if team > 1
            let myPos = position
            query() <| $(position : float2; isActive : bool)
                if !isActive
                    return
                if length(position - myPos) < collisionRadius
                    blocked = true
            
        reinforcementProgress = 0.0
        if !blocked
            let level = team < 2 ? (team == 0 ? towersFalls.x : towersFalls.y) : 0
            spawn_creeps(team, level, position + spawnOffset, eid)


def update_unit(var position : float2&;
        speed, attackSpeed, dt : float;
        attackTime : int;
        var direction, state : int&;
        var animProgress, lookAngle : float&;
        dir : float2;
        wantAttack, isActive : bool;
        var madeAttack : bool&)
    madeAttack = false
    if state == DEATH || !isActive
        return
    if length(dir) > 0.0
        lookAngle = atan2(dir.y, dir.x)
        direction = roundi(((normalize_angle(-lookAngle-PI*0.5)/PI*0.5 + 0.5)) * 8.0)
        if direction >= 8
            direction = 0
    if state == ATTACK
        animProgress += dt * attackSpeed * float(attackTime);
        if (animProgress >= float(attackTime))
            state = IDLE
            animProgress = 0.0
            madeAttack = true
            return

    if state == IDLE || state == MOVE
        if (wantAttack)
            state = ATTACK
            animProgress = 0.0
        else
            if (length(dir) > 0.0)
                if state == 1
                    state = MOVE
                    animProgress = 0.0

                animProgress += get_delta_time() * speed * 4.0
                position += normalize(dir) * get_delta_time() * speed
            else
                state = IDLE
                animProgress = 0.0

[decs(stage = controll)]
def controll_hero(var position : float2&;
        speed, attackSpeed : float;
        team, hero, attackTime : int;
        var madeAttack : bool&; isActive : bool;
        var direction, state : int&;
        var animProgress, lookAngle : float&)
    
    var dir : float2
    var wantToAttack = false
    if team == 0
        if (get_key(VK_W))
            dir += float2(0, 1)
        if (get_key(VK_D))
            dir += float2(1,0)
        if (get_key(VK_S))
            dir += float2(0,-1)
        if (get_key(VK_A))
            dir += float2(-1,0)
        wantToAttack = get_key(VK_SPACE)
    else
        if (get_key(VK_UP))
            dir += float2(0, 1)
        if (get_key(VK_RIGHT))
            dir += float2(1,0)
        if (get_key(VK_DOWN))
            dir += float2(0,-1)
        if (get_key(VK_LEFT))
            dir += float2(-1,0)
        wantToAttack = get_key(VK_RCONTROL)

    update_unit(position, speed, attackSpeed, get_delta_time(),
    attackTime, direction, state,
    animProgress, lookAngle, dir, wantToAttack, isActive, madeAttack)

[decs(stage = controll)]
def controll_creeps(
        spawnEid : EntityId;
        var position : float2&;
        speed, attackSpeed, attackRadius, agrRadius : float;
        team, attackTime : int;
        var madeAttack : bool&;
        var direction, state : int&;
        var animProgress, lookAngle : float&;
        isCreep, isActive, isNeutral : bool)
    if !isCreep
        return
    let dt = get_delta_time()
    let myTeam = team
    let myPos = position
    var maxDist = 10000.0
    
    var dir = float2(0,0)
    var wantToAttack = false;
    var target = INVALID_ENTITY_ID
    query <| $ (eid : EntityId; position : float2; hp, collisionRadius : float; team : int)
        if team != myTeam && hp > 0.0
            let distance = length(position - myPos)
            if distance < maxDist && distance < agrRadius
                maxDist = distance
                dir = position - myPos
                wantToAttack = distance < collisionRadius + attackRadius
                target = eid
    if target == INVALID_ENTITY_ID
        if !isNeutral
            maxDist = 10000.0
            query <| $ (position : float2; team : int; isBuilding : bool)
                if team != myTeam
                    let distance = length(position - myPos)
                    if distance < maxDist 
                        maxDist = distance
                        dir = position - myPos
        else
            query(spawnEid) <| $(position : float2; collisionRadius : float)
                if length(position - myPos) > collisionRadius*0.6
                    dir = position - myPos


    update_unit(position, speed, attackSpeed,
    dt, attackTime, direction,
    state, animProgress, lookAngle,
    dir, wantToAttack, isActive, madeAttack)


[decs(stage = physic)]
def clamp_in_world(var position : float2&;collisionRadius : float; isMovable : bool)
    let bounding = float4(-float(mapM) * 0.5, -float(mapN) * 0.5, float(mapM) * 0.5 - 1.0, float(mapN) * 0.5 - 1.0)
    position.x = clamp(position.x, bounding.x, bounding.z)
    position.y = clamp(position.y, bounding.y, bounding.w)

[decs(stage = physic)]
def update_collision(var position : float2&;collisionRadius : float; isMovable : bool)
    if !isMovable
        return
    var thisPosition :float2& = position
    let thiscollisionRadius = collisionRadius

    query <| $ (position : float2; collisionRadius : float; isCollidable : bool)
        if isCollidable
            let fromOther = thisPosition - position
            let distance = length(fromOther)
            if distance < 0.01
                return
            let sumRadius = thiscollisionRadius + collisionRadius
            if distance < sumRadius
                let t = 1.0 - sumRadius / distance
                thisPosition -= fromOther * t
    position = thisPosition



[decs(stage = logic)]
def made_melee_attack(position : float2; team : int; attackRadius, attackSector, damage, lookAngle : float; madeAttack, isCreep : bool)
    if madeAttack
        let myTeam = team
        let myPos = position
        var target : EntityId
        var minDist = 10000.0
        query() <| $ (eid : EntityId; position : float2; team : int; collisionRadius : float)
            if myTeam != team
                let dir = position - myPos
                let dirLen = length(dir)
                if dirLen < attackRadius + collisionRadius
                    let dirAngle = normalize_angle(atan2(dir.y, dir.x) - lookAngle)

                    if dirLen < minDist && abs(dirAngle) < attackSector
                        minDist = dirLen
                        target := eid
        
        query(target) <| $ (var hp : float&; var heroKillerTeam :int&)
            hp -= damage
            if !isCreep
                heroKillerTeam = myTeam

[decs(stage = logic)]
def made_range_attacking(madeAttack, isCreep : bool;
        position : float2; shellType, team : int;
        attackRadius, shellSpeed, damage, lookAngle : float)
    if madeAttack
        create_shell(team, shellType, position, lookAngle, 0.4, attackRadius, shellSpeed, damage, !isCreep)
        
        
[decs(stage = logic)]
def made_tower_attack(isTower : bool;
        position : float2; shellType, team : int;
        attackRadius, shellSpeed, damage, attackSpeed : float;
        var attackProgress : float&)
    attackProgress += get_delta_time() * attackSpeed
    if attackProgress >= 1.0
        attackProgress = 0.0
        let myTeam = team
        let myPos = position
        var maxDist = 10000.0
        
        var dir = float2(0,0)
        var wantToAttack = false;
        query <| $ (eid : EntityId; position : float2; hp, collisionRadius : float; team : int)
            if team != myTeam && hp > 0.0
                let distance = length(position - myPos)
                if distance < maxDist
                    maxDist = distance
                    dir = position - myPos
                    wantToAttack = distance < collisionRadius + attackRadius
        if wantToAttack
        
            let lookAngle = atan2(dir.y, dir.x)
            create_shell(team, shellType, position, lookAngle, 0.4, attackRadius, shellSpeed, damage, false)

[decs(stage = logic)]
def update_camera(isCamera : bool; var target0, target1 : float2&)

    query() <| $ (position : float2;hero, team : int)
        if team == 0
            target0 = position
        else
            target1 = position
    
    cemaraPosition = (target0 + target1) * 0.5
    var delta = target0 - target1
    if delta.x == 0.0
        delta.x = 0.01
    if delta.y == 0.0
        delta.y = 0.01
    let maxDist = min(float(get_screen_width()) / abs(delta.x), float(get_screen_height()) / abs(delta.y)) 
    cameraScale = min(maxDist * 0.74, 100.0)


[decs(stage = logic)]
def update_shells(eid : EntityId;
        orientation, speed, lifetime, radius, damage : float;
        var curtime : float&;
        var position : float2&;
        team : int;
        fromHero : bool)
    let dt = get_delta_time()
    let myTeam = team
    position += float2(cos(orientation), sin(orientation)) * speed * dt;
    curtime += dt;
    if curtime >= lifetime
        delete_entity(eid)
        return
    let myPos = position
    var found = false
    query() <| $ (position : float2; team : int; var heroKillerTeam : int&;
            collisionRadius : float; var hp : float&;
            isCollidable : bool; eid : EntityId)
        if !found && myTeam != team && isCollidable
            let dir = position - myPos
            let dirLen = length(dir)
            if dirLen < radius + collisionRadius
                hp -= damage
                if fromHero
                    heroKillerTeam = myTeam
                found = true
    if found
        delete_entity(eid)
    
def get_anim(anim : array<float4>[AnimCount]&; var progress : float&; dir : int; var needFlip :bool&)
    var idx = dir
    if dir > 4
        needFlip = true
        idx = 8 - dir 
    let count = length(anim[idx])
    let progressi = floori(progress)
    if progressi >= count
        progress -= float(progressi)
    return anim[idx][floori(progress)]

[decs(stage = draw)]
def draw_anim(animIdx, direction, state : int; position, scale : float2; var animProgress : float&; isActive : bool)
    if !isActive
        return
    var screenPos = world_to_screen_pos(position)
    var screenScale = world_to_screen_size(scale)
    var progress = animProgress
    var flip = false
    
    let subreg = get_anim(animations[animIdx].states[state].list, progress, direction, flip)
    animProgress = progress
    screenPos -= screenScale * 0.5
    if flip
        screenPos.x += screenScale.x
        screenScale.x = -screenScale.x
    images[animations[animIdx].imageIdx] |> draw_image_region(screenPos.x, screenPos.y, subreg, make_color(1.0), screenScale)

[decs(stage = draw)]
def draw_buildings(sprite : Sprite; position, scale : float2; team : int; orientation : float)

    var screenPos = world_to_screen_pos(position)
    let screenScale = world_to_screen_size(scale)
    images[sprite.imageIdx] |> draw_image_transformed(screenPos.x, screenPos.y, sprite.region, make_color(1.0), screenScale, -orientation)
    
[decs(stage = draw_background)]
def draw_map(mapPosition, tileScale : float2)

    var screenScale = world_to_screen_size(tileScale)
    for i in range(mapN)
        for j in range(mapM)
            let tileIdx = map.background[i*mapM+j]
            var screenPos = world_to_screen_pos(mapPosition + tileScale * float2(j, i))
            screenPos -= screenScale * 0.5
            tiles[tileIdx] |> draw_image(screenPos.x, screenPos.y, make_color(1.0), screenScale)


[decs(stage = debugdraw)]
def draw_collision(position : float2;collisionRadius : float)
    
    var screenPos = world_to_screen_pos(position)
    var screenScale = world_to_screen_size(float2(collisionRadius))
    circle(screenPos.x, screenPos.y, screenScale.x, 0xFF00FF00)
[decs(stage = debugdraw)]
def draw_shells(position : float2; radius : float)
    
    var screenPos = world_to_screen_pos(position)
    var screenScale = world_to_screen_size(float2(radius))
    circle(screenPos.x, screenPos.y, screenScale.x, 0xFF00FF00)

[decs(stage = debugdraw)]
def draw_range_radius(position : float2; attackRadius, shellSpeed : float)
    var screenPos = world_to_screen_pos(position)
    var screenScale = world_to_screen_size(float2(attackRadius))
    circle(screenPos.x, screenPos.y, screenScale.x, 0xFFFF0000)
[decs(stage = debugdraw)]
def draw_melee_sector(position : float2; attackRadius, attackSector : float; direction : int)
    var screenPos = world_to_screen_pos(position)
    var screenScale = world_to_screen_size(float2(attackRadius))
    let a = PI * (0.5-float(direction) * 0.25)
    let a0 = a + attackSector * 0.5
    let a1 = a - attackSector * 0.5
    let p0 = world_to_screen_pos(position + float2(cos(a0), sin(a0)) * attackRadius)
    let N = 4
    var p_ = p0
    line(screenPos.x, screenPos.y, p_.x, p_.y, 0xFFFF0000)
    for i in range(N)
        let ai = lerp(a0, a1, float(i + 1) / float(N))
        let pi = world_to_screen_pos(position + float2(cos(ai), sin(ai)) * attackRadius)
        line(pi.x, pi.y, p_.x, p_.y, 0xFFFF0000)
        p_ = pi
    line(screenPos.x, screenPos.y, p_.x, p_.y, 0xFFFF0000)

[decs(stage = latedraw)]
def draw_hpbars(var position : float2; collisionRadius, hp, hpMax: float; team : int; isActive : bool)
    if hp <= 0.0 || !isActive
        return
    let screenScale = world_to_screen_size(float2(collisionRadius))
    let screenPos = world_to_screen_pos(position - float2(collisionRadius)) 
    let width = screenScale.x*2.0
    let height = max(min(screenScale.x*0.3, 8.0), 5.0)
    fill_rect(screenPos.x, screenPos.y, width, height, 0xFFF0F0F0)
    fill_rect(screenPos.x+1.0, screenPos.y+1.0, width-2.0, height - 2.0, 0xFF000000)
    let color = team == 0 ? 0xFF378805 : (team == 1 ? 0xFF8E1600 : 0xFFFFA701)
    fill_rect(screenPos.x+1.0, screenPos.y+1.0, width * hp / hpMax-2.0,  height - 2.0, color)

[decs(stage = latedraw)]
def draw_xpbars(var position : float2; collisionRadius, xp, nextLevel, hp: float; level, hero : int; isActive : bool)
    if hp <= 0.0 || !isActive
        return
    let screenScale = world_to_screen_size(float2(collisionRadius))
    let screenPos = world_to_screen_pos(position - float2(collisionRadius)) + float2(0, 10)
    let width = screenScale.x*2.0
    let height = max(min(screenScale.x*0.3, 8.0), 5.0)
    fill_rect(screenPos.x, screenPos.y, width, height, 0xFFF0F0F0)
    fill_rect(screenPos.x+1.0, screenPos.y+1.0, width-2.0, height-2.0, 0xFF000000)
    if xp > 0.0
        fill_rect(screenPos.x+1.0, screenPos.y+1.0, width * xp / nextLevel-2.0, height-2.0, 0xFF1520A6)
    let screenPos2 = world_to_screen_pos(position - float2(collisionRadius))
    let textCorner = screenPos - float2(20,10)
    fill_rect(textCorner.x, textCorner.y, 20.0, 20.0, 0xFF000000)
    
    text_out(textCorner.x+5.0, textCorner.y, "{level}", 0xFFFFFFFF)

def print_alive_time(needTeam : int; color : uint; x,y : float)
    query() <| $(respawning : bool; respawnProgress, respawnTime : float; team : int)
        if respawning && needTeam == team
            var aliveTimeS = int((1.0 - respawnProgress) * respawnTime)
            var aliveTimeM = aliveTimeS / 60
            aliveTimeS = aliveTimeS % 60
            text_out(x, y, "{aliveTimeM}:{aliveTimeS}", color)


[decs(stage = latedraw)]
def draw_statistic(isCamera : bool)
    let h = float(get_screen_height())
    let w = float(get_screen_width())
     
    let width = 300.0
    let height = 100.0
    let screenPos = float2(-width*0.5, -h*0.5 )

    fill_rect(screenPos.x, screenPos.y, width, height, 0xFF0F0F0F)
    var seconds = int(get_time_after_start())
    var mins = seconds / 60
    seconds = seconds % 60
    text_out(screenPos.x+width*0.43, screenPos.y, "{mins}:{seconds}", 0xFFFFFFFF)
    print_alive_time(0, 0xFF0000FF, screenPos.x+width*0.15, screenPos.y+15.0)
    print_alive_time(1, 0xFFFF0000, screenPos.x+width*0.7, screenPos.y+15.0)
    if defeatTeam >= 0
        set_font_size(26.0)
        if defeatTeam == 1
            text_out(screenPos.x+width*0.01, screenPos.y+20.0, "left player wins!!!", 0xFF0000FF)
        else
            text_out(screenPos.x+width*0.01, screenPos.y+20.0, "right player wins!!!", 0xFFFF0000)
    else
        text_out(screenPos.x+width*0.0, screenPos.y, "left player", 0xFF0000FF)
        text_out(screenPos.x+width*0.58, screenPos.y, "right player", 0xFFFF0000)
        set_font_size(26.0)

        text_out(screenPos.x+width*0.35, screenPos.y+15.0, "kills", 0xFFFFFFFF)
        set_font_size(35.0)

        text_out(screenPos.x+width*0.17, screenPos.y+35.0, "{killsStatictic[1]} ", 0xFF0000FF)
        text_out(screenPos.x+width*0.75, screenPos.y+35.0, "{killsStatictic[0]}", 0xFFFF0000)
    set_font_size(16.0)
[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()

    decs_stage("controll")
    decs_stage("physic")
    decs_stage("logic")
    return

[export]
def draw
    setup_2d_camera(float2(0, 0), 1.0)
    enable_alpha_blend()
    if !gameStarted
        if pick_hero(playerHero)
            start_game()
    decs_stage("draw_background")
    decs_stage("draw")
    decs_stage("latedraw")
    if get_key(VK_P)
        decs_stage("debugdraw")
    return
