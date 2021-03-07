-- start server

-- local lfs_file = 'lfs.img';
-- if file.exists(lfs_file) then
-- 	node.LFS.reload("lfs.img")
-- 	print('loaded lfs file, restart...')
-- 	file.remove("lfs.img")
-- 	-- node.restart()
-- end

if node.LFS._init ~= nil then
	node.LFS._init()
end

local function load_module(module)
	print('Find module:', module)
	print('>>>>> Heap before load', module, node.heap())
	local ok, rs = pcall(function() 
		dofile(module)
		print('<<<<<< Heap after load', module, node.heap())
	end)
	if not ok then
		print('!!!!! Load module failed', module)
	end	
end

print('>>>>> Start find module.')

local module_flag1 = '__module__.lc'
local module_flag2 = '__module__.lua'
for module in pairs(file.list()) do
	if (module:len() > module_flag1:len()) and (module:sub(-module_flag1:len()) == module_flag1) then
		load_module(module)
	end
	if (module:len() > module_flag2:len()) and (module:sub(-module_flag2:len()) == module_flag2) then
		load_module(module)
	end
end
print('>>>>> End find module.')