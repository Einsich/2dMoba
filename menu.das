require daslib/media

var menuBackGround : Image

struct Player
    heroPreview : array<Image>
    heroIdx : array<int>
    heroDescr : array<string>
    descr : string
    pickedHero : int
    color : uint

var players : Player[2]
var mousePos : int2

def load_menu_pictures()
    menuBackGround <- create_image("tileset/Warcraft.jpg")
    players <- [[Player
        descr = "Left player - alliance\nMovement - WASD\nAttack - Space",
        pickedHero = -1,
        color = 0xFF378805,
        heroIdx <- [{int 0;1}],
        heroPreview <- [{Image
            create_image("tileset/light_knigth_art.jpg");
            create_image("tileset/grypho_art.png")
        }],
        heroDescr <- [{string
            "Light Knight\nMelee hero.";
            "Grypho\nRange hero."
        }];
    
        descr = "Right player - horde\nMovement - Arrows\nAttack - Right Ctrl",
        pickedHero = -1, 
        color = 0xFF8E1600,
        heroIdx <- [{int 2;3}],
        heroPreview <- [{Image
            create_image("tileset/deamon_art.jpg");
            create_image("tileset/death_knight_art.jpg")
        }],
        heroDescr <- [{string
            "Deamon\nMelee hero.";
            "Death Knight\nRange hero."
        }]
    ]]

def boxTest(minCorner, maxCorner, point: int2 )
    return minCorner.x <= point.x && point.x <= maxCorner.x && minCorner.y <= point.y && point.y <= maxCorner.y

def button(var x, y : int; size : int2; text : string; color : uint)
    x -= size.x / 2
    y -= size.y / 2
    let pos = int2(x,y)
    let border = 4
    let inside = boxTest(pos, pos + size, mousePos)
    fill_rect(x-border, y-border, size.x+border*2, size.y+border*2,inside? make_color(1.0) : color)
    fill_rect(x, y, size.x, size.y, make_color(0.4))
    set_font_size(35.0)
    text_out(x, y, text, 0xFFFFFFFF)
    return inside && get_mouse_button_down(MB_LEFT)

def text(var x, y : int; size : int2; text : string)
    x -= size.x / 2
    y -= size.y / 2
    set_font_size(35.0)
    text_out(x, y, text, 0xFFFFFFFF)

def pick_hero(var playerHero : int2&)

    let screenSize = int2(get_screen_width(), get_screen_height())
    let screenHalf = float2(screenSize.x, screenSize.y) * 0.5
    let width = 200
    let height = 300
    let size = int2(width, height)
    menuBackGround |> draw_image(-screenSize.x/2, -screenSize.y/2, make_color(0.4) , screenSize)

    set_font_size(35.0)
    text_out(-screenHalf.x*0.15, -screenHalf.y*0.8, "Pick your hero", 0xFFFFFFFF)
    
    let itemSpace = 30
    let xOffset = (width + itemSpace*2) / 2
    let yOffset = int(-screenHalf.y*0.8) + 58
    let xPickOffset = (width*3 + itemSpace*2)
    let yPickOffset = int(screenHalf.y*0.5)
    let descrXPos = screenSize.x / 2 - 300
    let descrYPos = screenSize.y / 2 - 100
    mousePos = int2(get_mouse_position()) - screenSize / 2
    var playersReady = true
    for playerIdx in range(2)
        var player : Player& = players[playerIdx]
        let dir = playerIdx == 0 ? -1 : 1
        var pickedHero = false
        text(descrXPos * dir, -descrYPos, int2(300, 100), player.descr)
        for i in range(length(player.heroPreview))
            let screenPos = int2(-width/2 + dir * xOffset,yOffset) + int2(dir * i * (width + itemSpace), 0)
            let inside = boxTest(screenPos, screenPos + size, mousePos)
            if inside && get_mouse_button_down(MB_LEFT)
                player.pickedHero = i
            let border = 4
            fill_rect(screenPos.x-border, screenPos.y-border, size.x+border*2, size.y+border*2, inside ? 0xFFFFE800 : make_color(0.4))
            let picked = player.pickedHero == i
            pickedHero = pickedHero || picked
            player.heroPreview[i] |> draw_image(screenPos.x, screenPos.y, picked ? make_color(0.3) : make_color(1.0), size)
            if picked 
                let descrW = width  *2
                let descrH = height*2
                text(descrW / 2 * dir, descrH / 2, int2(descrW, descrH), player.heroDescr[i])
        playersReady = playersReady && pickedHero
    
    if playersReady
        playerHero.x = players[0].heroIdx[players[0].pickedHero]
        playerHero.y = players[1].heroIdx[players[1].pickedHero]
        if button(0, yPickOffset+110, int2(105, 50), "start", 0xFF0000FF)
            return true
    return false