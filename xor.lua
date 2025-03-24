-- shorthand
local char = string.char
local byte = string.byte


-- lessen hooking
local function floor(x)
    return x - (x % 1)
end


-- predetermine xor bytes
local xort = {}

for i = 0, 255 do
    xort[i] = {}

    for j = 0, 255 do
        local result, bit = 0, 1
        local a,      b   = i, j

        while a > 0 or b > 0 do
            local abit, bbit = a % 2, b % 2
            
            if abit ~= bbit then
                result = result + bit
            end

            a, b, bit = floor(a / 2), floor(b / 2), bit * 2
        end
        
        xort[i][j] = result
    end
end


-- xor cipher
local function xor(str, key)
    local klen = #key
    local enc = {}

    for i = 1, #str do
        local index = (i - 1) % klen + 1

        enc[i] = char(xort[byte(str, i)][key[index]])
    end

    return table.concat(enc)
end


-- file functions
local function readf(fn, binary)
    local file = io.open(fn,  binary and 'rb' or 'r')

    if not file then
        return nil
    end

    local content = file:read('*a')

    file:close()

    return content
end

local function writef(fn, data, binary)
    local file = io.open(fn, binary and 'wb' or 'w')

    if file then
        file:write(data)
        file:close()
    end
end


-- hex to bytes
local function tobytes(hex)
    local bytes = {}

    for h in hex:gmatch('%S+') do
        table.insert(bytes, tonumber(h, 16))
    end

    return bytes
end


-- key generation
local function key(length)
    local parts = {}

    for i = 1, length do
        parts[i] = string.format('%02X', math.random(0, 255))
    end

    return table.concat(parts, ' ')
end


-- benchmarking
local function stamp()
    return os.clock() * 1e6
end

-- for when they're done
local function finished()
    io.write('\npress any key to exit ...')

    local _ = io.read()
end

-- main function
local function go()
    local files = {
        {'encrypted.txt', '[for the most recently encrypted data]'},
        {'decrypted.txt', '[for the most recently decrypted data]'},
        {'data.txt',      '[for what data is to be obfuscated]'},
        {'key.txt',       '[for the most recently generated key, or the key to be used]'}
    }

    for i, v in ipairs(files) do
        if not readf(v[1]) then
            writef(v[1], v[2])
        end
    end

    print('if you\'re decrypting xor, please store the necessary key in [key.txt]')
    io.write('\nencrypt or decrypt? (e/d): ')

    local choice = io.read()

    print('\n')

    if choice == 'e' then
        local data = readf('data.txt', true)

        if not data then
            return error('no data file (data.txt) not found.')
        end

        math.randomseed(os.time() + math.random())

        local rawk = key(#data)
        writef('key.txt', rawk, false)
        print('[unique key generated, check your file]')

        local bytes     = tobytes(rawk)
        local begin     = stamp()
        local encrypted = xor(data, bytes)
        local micros    = stamp() - begin

        writef('encrypted.txt', encrypted, true)
        print(('[encrypted in %.2f microseconds]'):format(micros))

        finished()
    elseif choice == 'd' then
        local data = readf('encrypted.txt', true)
        local rawk = readf('key.txt', false)

        if not data or not rawk then
            return error('missing file for encrypted data [encrypted.txt] or the key [key.txt]')
        end

        local bytes     = tobytes(rawk)
        local begin     = stamp()
        local decrypted = xor(data, bytes)
        local micros    = stamp() - begin

        writef('decrypted.txt', decrypted, true) 
        print(('[decrypted in %.2f microseconds]'):format(micros))

        finished()
    else
        go()
    end
end


-- go!
go()
