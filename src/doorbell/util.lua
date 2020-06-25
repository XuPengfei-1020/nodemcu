function split(str, sep)
    local sidx = 1
    local aidx = 0
    local result = {}
    while true do
       local nidx = str:find(sep, sidx)
       if not nidx then
        result[aidx] = str:sub(sidx, string.len(str))
        break
       end
       result[aidx] = str:sub(sidx, nidx - 1)
       sidx = nidx + sep:len()
       aidx = aidx + 1
    end
    return result
end