-- This function will return a string filetree of all files
-- in the folder and files in all subfolders
function recursiveEnumerate(folder, fileTree)
	local filesTable = love.filesystem.getDirectoryItems(folder)
	for i,v in ipairs(filesTable) do
		local file = folder.."/"..v
		local info = love.filesystem.getInfo(file)
		if info then
			if info.type == "file" then
				fileTree = fileTree.."\n"..file
			elseif info.type == "directory" then
				fileTree = fileTree.."\n"..file.." (DIR)"
				fileTree = recursiveEnumerate(file, fileTree)
			end
		end
	end
	return fileTree
end