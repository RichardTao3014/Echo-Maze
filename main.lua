-- 每格大小
local tileSize = 20

-- 迷宫地图
-- local maze = {
--     {0,0,0,0,0,0,0},
--     {0,1,1,1,0,1,0},
--     {0,1,0,1,0,1,0},
--     {0,1,0,1,1,1,0},
--     {0,1,0,0,0,1,0},
--     {0,1,1,1,1,3,0},
--     {0,0,0,0,0,0,0}
-- }

local maze = {
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,1,1,0,1,1,1,1,1,0,1,1,1,1,1,1,1,1,3,0},
  {0,0,1,0,1,0,0,0,1,0,1,0,0,0,0,0,0,1,1,0},
  {0,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,0,1,1,0},
  {0,1,0,0,0,0,1,0,1,0,1,0,1,0,0,1,0,0,1,0},
  {0,1,1,1,1,1,1,0,1,0,1,1,1,1,0,1,1,1,1,0},
  {0,1,0,0,1,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0},
  {0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0},
  {0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,1,1,0,1,0},
  {0,1,1,1,1,1,1,1,1,1,0,1,0,0,1,0,1,1,1,0},
  {0,1,0,0,0,0,0,1,0,1,0,1,0,0,1,0,0,0,0,0},
  {0,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1,0,0,0},
  {0,1,0,0,0,0,0,0,0,0,0,0,1,1,0,0,1,0,1,0},
  {0,1,1,1,1,1,0,0,1,1,1,0,1,1,1,0,1,1,1,0},
  {0,1,0,0,0,1,0,0,0,0,1,0,0,0,1,0,0,0,1,0},
  {0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,0},
  {0,0,0,1,0,0,1,1,1,0,0,0,1,0,1,0,1,0,1,0},
  {0,1,1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,0},
  {0,1,1,1,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
}



-- 玩家位置
local player = {
    x = 2,  -- 对应列
    y = 19   -- 对应行
}

local gameWon = false



function love.load()
    love.window.setTitle("Maze Game Prototype")
    love.window.setMode(#maze[1] * tileSize, #maze * tileSize)
    selection = nil  -- 玩家当前选中的方向目标格，如 {x=2, y=3}
    hint = ""        -- 显示的提示内容（可用于后期播放声音）
    -- 加载音效
    sound_correct = love.audio.newSource("correct.mp3", "static")
    sound_wrong = love.audio.newSource("wrong.mp3", "static")
    sound_victory = love.audio.newSource("victory.mp3", "static")

    chaser = {
    x = 2,  -- 起始列
    y = 2,  -- 起始行
    steps = 0  -- 记录玩家移动次数
}
end



function love.draw()
    for y = 1, #maze do
        for x = 1, #maze[y] do
            local cell = maze[y][x]
            local drawX = (x - 1) * tileSize
            local drawY = (y - 1) * tileSize

            -- 墙壁
            if cell == 0 then
                -- love.graphics.setColor(1, 1, 1) -- 墙（白色）
                -- love.graphics.rectangle("fill", drawX, drawY, tileSize, tileSize)
                
                local isBorder = x == 1 or x == #maze[1] or y == 1 or y == #maze
                if isBorder or gameWon then
                    love.graphics.setColor(1, 1, 1) -- 墙（白色）
                    love.graphics.rectangle("fill", drawX, drawY, tileSize, tileSize)
                end
            end

            -- 终点
            if cell == 3 then
                love.graphics.setColor(0, 1, 0) -- 终点（绿色）
                love.graphics.rectangle("fill", drawX, drawY, tileSize, tileSize)
            end

            -- 玩家
            if x == player.x and y == player.y then
                love.graphics.setColor(0, 0.5, 1) -- 玩家（蓝色）
                love.graphics.rectangle("fill", drawX, drawY, tileSize, tileSize)
            end
        end
    end

    -- 追踪者
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", (chaser.x - 1) * tileSize, (chaser.y - 1) * tileSize, tileSize, tileSize)

    -- 选中提示（黄色方块）
    if selection then
        love.graphics.setColor(1, 1, 0)
        local sx = (selection.x - 1) * tileSize
        local sy = (selection.y - 1) * tileSize
        love.graphics.rectangle("fill", sx, sy, tileSize, tileSize)
    end

    -- 提示文本
    -- love.graphics.setColor(1, 1, 1)
    -- love.graphics.print("Hint: " .. hint, 20, 20)

    -- 胜利提示
    -- if gameWon then
    --     love.graphics.setColor(1, 1, 0)
    --     love.graphics.print("You Win!", 40, 40)
    -- end
end



function moveChaserTowardPlayer()
    local path = bfsPath(chaser.x, chaser.y, player.x, player.y)

    if path and #path >= 2 then
        -- 第一个是当前位置，第二个是要走的一步
        local nextStep = path[2]
        chaser.x = nextStep.x
        chaser.y = nextStep.y
    end
end



function bfsPath(startX, startY, goalX, goalY)
    local visited = {}
    local queue = {}
    local cameFrom = {}

    local function key(x, y)
        return x .. "," .. y
    end

    table.insert(queue, {x = startX, y = startY})
    visited[key(startX, startY)] = true
    cameFrom[key(startX, startY)] = nil

    local dirs = {
        {x = 1, y = 0}, {x = -1, y = 0},
        {x = 0, y = 1}, {x = 0, y = -1}
    }

    while #queue > 0 do
        local current = table.remove(queue, 1)

        if current.x == goalX and current.y == goalY then
            -- 回溯路径
            local path = {}
            local curKey = key(goalX, goalY)
            while curKey do
                local coords = {}
                for val in string.gmatch(curKey, "[^,]+") do
                    table.insert(coords, tonumber(val))
                end
                table.insert(path, 1, {x = coords[1], y = coords[2]})
                curKey = cameFrom[curKey]
            end
            return path
        end

        for _, d in ipairs(dirs) do
            local nx, ny = current.x + d.x, current.y + d.y
            local nkey = key(nx, ny)

            if maze[ny] and maze[ny][nx] and maze[ny][nx] ~= 0 and not visited[nkey] then
                visited[nkey] = true
                cameFrom[nkey] = key(current.x, current.y)
                table.insert(queue, {x = nx, y = ny})
            end
        end
    end

    return nil -- 没有路径
end



function love.keypressed(key)
    if gameWon then return end

    local dx, dy = 0, 0
    if key == "up" then dy = -1 end
    if key == "down" then dy = 1 end
    if key == "left" then dx = -1 end
    if key == "right" then dx = 1 end

    if dx ~= 0 or dy ~= 0 then
        local tx = player.x + dx
        local ty = player.y + dy
        local cell = maze[ty] and maze[ty][tx]

        if cell then
            selection = {x = tx, y = ty}
            if cell == 0 then
                hint = "Wall ahead."
                sound_wrong:stop()
                sound_wrong:play()
            elseif cell == 1 or cell == 2 then
                hint = "Safe path."
                sound_correct:stop()
                sound_correct:play()
            end
        end
    end

    -- 确认移动
    if key == "return" and selection then
        local cell = maze[selection.y][selection.x]

        if cell == 0 then
            print("You hit a wall! Game over.")
            love.load()
            player.x = 2
            player.y = 19
            gameWon = false
            selection = nil
            hint = ""
            return
        elseif cell == 1 or cell == 2 then
            player.x = selection.x
            player.y = selection.y
            selection = nil
            hint = ""

            -- 玩家移动后，追踪者走一步
            chaser.steps = chaser.steps + 1
            if chaser.steps % 2 == 0 then
                moveChaserTowardPlayer()
            end

            -- 玩家走完后才检测是否被追上
            if chaser.x == player.x and chaser.y == player.y then
                print("Caught by the chaser! Game over.")
                love.load()
                player.x = 2
                player.y = 19
                gameWon = false
                selection = nil
                hint = ""
            end

        elseif cell == 3 then
            player.x = selection.x
            player.y = selection.y
            gameWon = true
            selection = nil
            hint = ""
            sound_victory:stop()
            sound_victory:play()
            return
        end
    end

end
