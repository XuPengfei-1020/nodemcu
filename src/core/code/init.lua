-- start server
-- node.LFS.reload("lfs.img")

if node.LFS._init ~= nil then
	print('init LFS.')
	node.LFS._init()
end

local function is_module(f)
	local module_flag1 = '__module__.lc'
	local module_flag2 = '__module__.lua'
	if (f:len() > module_flag1:len()) and (f:sub(-module_flag1:len()) == module_flag1) then
		return true
	end
	return (f:len() > module_flag2:len()) and (f:sub(-module_flag2:len()) == module_flag2)
end

local function load_module(module)
	print('Find module:', module)
	print('>>>>> Heap before load', module, node.heap())
	local ok, rs = pcall(function() 
		dofile(module)
		print('<<<<<< Heap after load', module, node.heap())
	end)
	if not ok then
		print('!!!!! Load module failed', module, rs)
	end	
end

print('>>>>> Load config.')
SDK_CFG = {}
local fd = file.open('sdk.cfg', 'r')
if fd then
    local content = fd:read()
    fd:close()
    print('SDK config:', content)
    local ok, config = pcall(sjson.decode, content)
    if ok then
		SDK_CFG = config
    else
		print('Parse json failed, sdk cfg is invalid')
    end
end

print('>>>>> Start find module.')
-- load from LFS
for i, module in pairs(node.LFS.list()) do
	module = module .. '.lua'
	if is_module(module) then
		load_module(module)
	end
end

for module, size in pairs(file.list()) do
	if is_module(module) then
		load_module(module)
	end
end
print('>>>>> End find module.')