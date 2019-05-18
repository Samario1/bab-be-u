function updateUnits(undoing)
  max_layer = 1
  units_by_layer = {}

  for i,v in ipairs(units_by_tile) do
    units_by_tile[i] = {}
  end

  for _,unit in ipairs(units) do
    local tileid = unit.x + unit.y * mapwidth
    table.insert(units_by_tile[tileid], unit)
  end

  local del_units = {}
  local unitcount = #units
  for i,unit in ipairs(units) do
    --[[if i > unitcount then
      break
    end]]
    local deleted = false
    for _,del in ipairs(del_units) do
      if del == unit then
        deleted = true
      end
    end

    if not deleted and not unit.removed_final then
      local tile = tiles_list[unit.tile]
      local tileid = unit.x + unit.y * mapwidth
      local is_u = hasProperty(unit, "u")

      unit.layer = tile.layer

      if not undoing then
        for _,on in ipairs(units_by_tile[tileid]) do
          if hasProperty(on, "no swim") and on ~= unit then
            unit.destroyed = true
            unit.removed = true
            on.destroyed = true
            on.removed = true
            playSound("sink", 0.5)
            addParticles("destroy", unit.x, unit.y, on.color)
            table.insert(del_units, on)
          elseif is_u and hasProperty(on, ":)") then
            win = true
            music_fading = true
            playSound("win", 0.5)
          end
        end
      end

      if is_u and not undoing then
        unit.layer = unit.layer + 10
        for _,on in ipairs(units_by_tile[tileid]) do
          if hasProperty(on, ":)") then
            win = true
            music_fading = true
            playSound("win", 0.5)
          end
        end
      end

      if hasProperty(unit,"slep") and unit.sleepsprite then
        unit.sprite = unit.sleepsprite
      else
        unit.sprite = tiles_list[unit.tile].sprite
      end

      unit.overlay = {}
      if hasProperty(unit,"tranz") then
        table.insert(unit.overlay, "trans")
      end
      if hasProperty(unit,"gay") then
        table.insert(unit.overlay, "gay")
      end

      if not units_by_layer[unit.layer] then
        units_by_layer[unit.layer] = {}
      end
      table.insert(units_by_layer[unit.layer], unit)
      max_layer = math.max(max_layer, unit.layer)

      if unit.removed then
        table.insert(del_units, unit)
      end
    end
  end

  local converted_units = {}

  local unitcount = #units
  for i,unit in ipairs(units) do
    if i > unitcount then
      break
    end
    if rules_with[unit.name] and not undoing then
      for _,rules in ipairs(rules_with[unit.name]) do

      end
    end
  end

  cursor_convert_to = nil

  for _,rules in ipairs(full_rules) do
    local rule = rules[1]
    local obj_name = rule[3]

    local istext = false
    if rule[3] == "text" then
      istext = true
      obj_name = "text_" .. rule[1]
    end
    local obj_id = tiles_by_name[obj_name]
    local obj_tile = tiles_list[obj_id]

    if units_by_name[rule[1]] then
      for i,unit in ipairs(units_by_name[rule[1]]) do
        if rule[3] == "mous" or (obj_tile ~= nil and (obj_tile.type == "object" or istext)) then
          if rule[2] == "got" then
            if unit.destroyed and not undoing then
              local new_unit = createUnit(obj_id, unit.x, unit.y, unit.dir)
              addUndo({"create", new_unit.id, false})
            end
          elseif rule[2] == "be" then
            if not unit.destroyed and rule[3] ~= unit.name and not undoing then
              if not unit.removed then
                table.insert(converted_units, unit)
              end
              unit.removed = true
              if rule[3] == "mous" then
                local new_mouse = createMouse(unit.x, unit.y)
                addUndo({"create_cursor", new_mouse.id})
              else
                local new_unit = createUnit(obj_id, unit.x, unit.y, unit.dir, true)
                addUndo({"create", new_unit.id, true})
              end
            end
          end
        end
      end
    end

    if rule[1] == "mous" then
      if obj_tile ~= nil and (obj_tile.type == "object" or istext) then
        if rule[2] == "be" then
          if rule[3] ~= "mous" then
            cursor_convert_to = obj_id
          end
        end
      end
    end
  end

  deleteUnits(del_units)
  deleteUnits(converted_units,true)
end

function deleteUnits(del_units,convert)
  for _,unit in ipairs(del_units) do
    deleteUnit(unit,convert)
    addUndo({"remove", unit.tile, unit.x, unit.y, unit.dir, convert or false, unit.id})
  end
end

function createMouse_direct(x,y,id_)
  local mouse = {}
  mouse.x = x
  mouse.y = y
  mouse.id = id_ or newMouseID()
  table.insert(cursors, mouse)
  return mouse
end

function createMouse(gamex,gamey,id_)
  local gx,gy = gameTileToScreen(gamex,gamey)
  local mouse = {}
  mouse.x = gx
  mouse.y = gy
  mouse.id = id_ or newMouseID()
  table.insert(cursors, mouse)
  return mouse
end

function deleteMouse(id)
  for i,mous in ipairs(cursors) do
    if cursors[i].id == id then
      table.remove(cursors,i)
      return
    end
  end
end

--[[function deleteMice(gamex,gamey)
  local toBeDeleted = {}
  local numberDeleted = 0
  local hx,hy = gameTileToScreen(gamex,gamey)
  for i,mous in ipairs(cursors) do
  	if cursors[i].x >= hx and cursors[i].x <= hx + TILE_SIZE and cursors[i].y >= hy and cursors[i].y <= hy + TILE_SIZE then
  	  table.insert(toBeDeleted, i)
  	end
  end
  for i=table.getn(toBeDeleted),1,-1 do
    table.remove(toBeDeleted)
    numberDeleted = numberDeleted + 2
  end
  return numberDeleted
end]]--

function createUnit(tile,x,y,dir,convert,id_)
  local unit = {}

  unit.id = id_ or newUnitID()
  unit.x = x or 0
  unit.y = y or 0
  unit.dir = dir or 1
  unit.active = false
  unit.removed = false

  unit.scalex = 1
  unit.scaley = 1
  if convert then
    unit.scaley = 0
  end
  unit.oldx = unit.x
  unit.oldy = unit.y
  unit.move_timer = MAX_MOVE_TIMER
  unit.old_active = unit.active
  unit.overlay = {}

  unit.tile = tile
  unit.sprite = tiles_list[tile].sprite
  unit.type = tiles_list[tile].type
  unit.texttype = tiles_list[tile].texttype or "object"
  unit.allowprops = tiles_list[tile].allowprops or false
  unit.color = tiles_list[tile].color
  unit.layer = tiles_list[tile].layer
  unit.rotate = tiles_list[tile].rotate or false

  unit.fullname = tiles_list[tile].name
  if unit.type == "text" then
    unit.name = "text"
    unit.textname = string.sub(unit.fullname, 6)
  else
    unit.name = unit.fullname
    unit.textname = unit.fullname
  end

  units_by_id[unit.id] = unit

  if not units_by_name[unit.name] then
    units_by_name[unit.name] = {}
  end
  table.insert(units_by_name[unit.name], unit)

  if unit.fullname ~= unit.name then
    if not units_by_name[unit.fullname] then
      units_by_name[unit.fullname] = {}
    end
    table.insert(units_by_name[unit.fullname], unit)
  end

  if not units_by_layer[unit.layer] then
    units_by_layer[unit.layer] = {}
  end
  table.insert(units_by_layer[unit.layer], unit)
  max_layer = math.max(max_layer, unit.layer)

  local tileid = x + y * mapwidth
  table.insert(units_by_tile[tileid], unit)

  table.insert(units, unit)

  return unit
end

function deleteUnit(unit,convert)
  unit.removed = true
  unit.removed_final = true
  removeFromTable(units, unit)
  units_by_id[unit.id] = nil
  removeFromTable(units_by_name[unit.name], unit)
  if unit.name ~= unit.fullname then
    removeFromTable(units_by_name[unit.fullname], unit)
  end
  local tileid = unit.x + unit.y * mapwidth
  removeFromTable(units_by_tile[tileid], unit)
  if not convert then
    removeFromTable(units_by_layer[unit.layer], unit)
  end
end

function moveUnit(unit,x,y)
  unit.oldx = lerp(unit.oldx, unit.x, unit.move_timer/MAX_MOVE_TIMER)
  unit.oldy = lerp(unit.oldy, unit.y, unit.move_timer/MAX_MOVE_TIMER)
  unit.x = x
  unit.y = y
  unit.move_timer = 0

  do_move_sound = true
end

function newUnitID()
  max_unit_id = max_unit_id + 1
  return max_unit_id
end

function newMouseID()
  max_mouse_id = max_mouse_id + 1
  return max_mouse_id
end