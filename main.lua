local ESP_Enabled                       = CreateClientConVar("fj_esp_enabled", "1")
local ESP_Boxes                         = CreateClientConVar("fj_esp_boxes", "1")
local ESP_Chams                         = CreateClientConVar("fj_esp_chams", "0")
local ESP_Name                          = CreateClientConVar("fj_esp_name", "1")
local ESP_Team                          = CreateClientConVar("fj_esp_team", "1")
local ESP_Health                        = CreateClientConVar("fj_esp_health", "1")
local ESP_Armor                         = CreateClientConVar("fj_esp_armor", "1")
local ESP_Weapon                        = CreateClientConVar("fj_esp_weapon", "1")
local ESP_Distance                      = CreateClientConVar("fj_esp_distance", "1")
local ESP_ViewLines                     = CreateClientConVar("fj_esp_viewlines", "1")
local ESP_Color1                        = CreateClientConVar("fj_esp_color1", "0 255 0 255")
local ESP_Color2                        = CreateClientConVar("fj_esp_color1", "255 0 0 255")
local ESP_ChamsColor1                   = CreateClientConVar("fj_esp_chamscolor1", "0 255 0 255")
local ESP_ChamsColor2                   = CreateClientConVar("fj_esp_chamscolor2", "255 0 0 255")

local Misc_DisableDefaultCrosshair      = CreateClientConVar("fj_misc_disabledefaultcrosshair", "1")
local Misc_Crosshair                    = CreateClientConVar("fj_misc_crosshair", "1")
local Misc_CrosshairColor               = CreateClientConVar("fj_misc_crosshaircolor", "0 0 255 255")
local Misc_CrosshairSize                = CreateClientConVar("fj_misc_crosshairsize", "10")
local Misc_CrosshairGap                 = CreateClientConVar("fj_misc_crosshairgap", "1")
local Misc_CrosshairCenterDot           = CreateClientConVar("fj_misc_crosshaircenterdot", "1")
local Misc_BHop                         = CreateClientConVar("fj_misc_bhop", "1")

local LocalPly = LocalPlayer()

local ESPFont = "DefaultSmall"

local Laser = Material("trails/laser")
local LaserSprite = Material("sprites/glow04_noz")
local LaserColor = Color(255, 0, 0)

local ChamsBackMaterial = CreateMaterial("chams_back", "VertexLitGeneric", {
    ["$basetexture"] = "models/debug/debugwhite",
    ["$model"] = 1,
    ["$translucent"] = 1,
    ["$vertexalpha"] = 1,
    ["$vertexcolor"] = 1,
    ["$ignorez"] = 0
})

local ChamsFrontMaterial = CreateMaterial("chams_front", "VertexLitGeneric", {
    ["$basetexture"] = "models/debug/debugwhite",
    ["$model"] = 1,
    ["$translucent"] = 1,
    ["$vertexalpha"] = 1,
    ["$vertexcolor"] = 1,
    ["$ignorez"] = 1
})

local fj = {}
fj.hooks = {}

function fj.AddHook(eventName, id, func)
    if fj.hooks[eventName] == nil then
        fj.hooks[eventName] = {}
    end

    fj.hooks[eventName][id] = func

    hook.Add(eventName, id, func)
end

function fj.DrawValueBar(x, y, w, h, min, max, value, color, text_color, border, border_color)
	draw.RoundedBox(0, math.ceil(x), math.ceil(y), w, h, border_color)

	if value > min then
		draw.RoundedBox(0, math.ceil(x + border), math.ceil(y + border), (w - (border * 2)) * (math.Clamp(value, min, max) / max), h - (border * 2), color)
	end

	draw.SimpleTextOutlined(value, Font, x + (w / 2), y + (h / 2), text_color, 1, 1, 1, border_color)
end

function fj.GetCorners(target)
    if not IsValid(target) then
        return
    end

    local min, max = target:OBBMins(), target:OBBMaxs()

    local corners = {
        Vector( min.x, min.y, min.z ),
        Vector( min.x, min.y, max.z ),
        Vector( min.x, max.y, min.z ),
        Vector( min.x, max.y, max.z ),
        Vector( max.x, min.y, min.z ),
        Vector( max.x, min.y, max.z ),
        Vector( max.x, max.y, min.z ),
        Vector( max.x, max.y, max.z )
    }

    local x1, y1, x2, y2

    for i = 1, #corners do
        local pos = target:LocalToWorld(corners[i]):ToScreen()

        x1, y1 = math.min(x1 or pos.x, pos.x), math.min(y1 or pos.y, pos.y)
        x2, y2 = math.max(x2 or pos.x, pos.x), math.max(y2 or pos.y, pos.y)
    end

    return x1, y1, x2, y2
end

// Detours
fj.detours = {}
fj.detours.hook_GetTable = hook.GetTable

function hook.GetTable()
    tab = table.Copy(fj.detours.hook_GetTable())

    for event, ids in pairs(fj.hooks) do
        for id, _ in pairs(ids) do
            tab[event][id] = nil
        end
    end

    return tab
end

// Hooks
fj.AddHook("CreateMove", "FJ_Movement", function(cmd) 
	if Misc_BHop:GetInt() == 1 and LocalPly:GetMoveType() != MOVETYPE_NOCLIP then
		if not LocalPly:IsOnGround() then 
			cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_JUMP)))
		end
    end
end)

fj.AddHook("HUDShouldDraw", "FJ_HideDefaultCrosshair", function(element)
	if element == "CHudCrosshair" and Misc_DisableDefaultCrosshair:GetInt() == 1 then
		return false
	end
end)

fj.AddHook("RenderScreenspaceEffects", "FJ_DrawChams", function()
    if ESP_Chams:GetInt() == 0 then return end
    
    local color

    cam.Start3D(EyePos(), EyeAngles())
        render.SuppressEngineLighting(true)

        color = string.ToColor(ESP_ChamsColor2:GetString())
        render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
        render.ModelMaterialOverride(ChamsFrontMaterial)

        for _, p in pairs(player.GetAll()) do
            p:DrawModel()
        end

        color = string.ToColor(ESP_ChamsColor1:GetString())
        render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
        render.ModelMaterialOverride(ChamsBackMaterial)

        for _, p in pairs(player.GetAll()) do
            p:DrawModel()
        end

        render.SuppressEngineLighting(false)
    cam.End3D()

end)

fj.AddHook("HUDPaint", "FJ_DrawESP", function()
    if Misc_Crosshair:GetInt() == 1 then
        local width, height, size, gap = ScrW()/2, ScrH()/2, Misc_CrosshairSize:GetInt(), Misc_CrosshairGap:GetInt()

        surface.SetDrawColor(string.ToColor(Misc_CrosshairColor:GetString()))

        surface.DrawRect(width - size - gap, height - 1, size, 2)
        surface.DrawRect(width + gap, height - 1, size, 2)

        surface.DrawRect(width - 1, height - size - gap, 2, size)
        surface.DrawRect(width - 1, height + gap, 2, size)

        if Misc_Crosshair:GetInt() == 1 then
            surface.DrawRect(width - 1, height - 1, 2, 2)
        end
    end

    if ESP_Enabled:GetInt() == 0 then return end

    local plys = player.GetAll()

    for k, p in pairs(plys) do
        if p != LocalPly and p:IsValid() and p:Alive() then
            local pos = p:GetPos()
            local x1, y1, x2, y2 = fj.GetCorners(p)
            
            if ESP_Boxes:GetInt() == 1 then
                surface.SetDrawColor(string.ToColor(ESP_Color1:GetString()))
                surface.DrawOutlinedRect(x1, y1, x2 - x1, y2 - y1)
            end

            if ESP_ViewLines:GetInt() == 1 then
                local eye = p:GetAttachment(p:LookupAttachment("eyes")).Pos
                local eye_angles

				local trace = util.TraceLine(
					{
						filter = p,
						start = eye,
						endpos = eye + p:EyeAngles():Forward() * 100000
					}
				)

				cam.Start3D()
					render.SetMaterial(Laser)
					render.DrawBeam(eye, trace.HitPos, 24, 1, 1, LaserColor)

					render.SetMaterial(LaserSprite)
					render.DrawSprite(trace.HitPos + (trace.HitNormal), 24, 24, LaserColor)
				cam.End3D()
			end	

            local screen_pos = pos:ToScreen()
            local label_offset = 12

            local label_pos_x = x2 + 2
            local label_pos_y = y2 - label_offset

            if ESP_Distance:GetInt() == 1 then
                draw.SimpleTextOutlined(tostring(math.Round(LocalPly:GetPos():Distance(p:GetPos()) * 0.75 * 0.0254)) .. "m", ESPFont, label_pos_x, label_pos_y, color_white, 0, 0, 1, color_black)
                label_pos_y = label_pos_y - label_offset
            end

            if ESP_Weapon:GetInt() == 1 then
                draw.SimpleTextOutlined(p:GetActiveWeapon():GetPrintName(), ESPFont, label_pos_x, label_pos_y, color_white, 0, 0, 1, color_black)
                label_pos_y = label_pos_y - label_offset
            end

            if ESP_Armor:GetInt() == 1 and p:Armor() > 0 then
                fj.DrawValueBar(label_pos_x, label_pos_y + 2, 60, 10, 0, 100, p:Armor(), Color(75, 75, 255), text_color, 1, color_black)
                label_pos_y = label_pos_y - label_offset
            end

            if ESP_Health:GetInt() == 1 then
                fj.DrawValueBar(label_pos_x, label_pos_y + 2, 60, 10, 0, 100, p:Health(), Color(255, 75, 75), text_color, 1, color_black)
                label_pos_y = label_pos_y - label_offset
            end

            if ESP_Team:GetInt() == 1 then
                draw.SimpleTextOutlined(team.GetName(p:Team()), ESPFont, label_pos_x, label_pos_y, color_white, 0, 0, 1, color_black)
                label_pos_y = label_pos_y - label_offset
            end

            if ESP_Name:GetInt() == 1 then
                draw.SimpleTextOutlined(p:GetName(), ESPFont, label_pos_x, label_pos_y, color_white, 0, 0, 1, color_black)
                label_pos_y = label_pos_y - label_offset
            end
        end
    end
end)