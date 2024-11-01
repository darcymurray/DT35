FileUtils = {}

-- A pattern which describes the set of valid characters for a file or directory name (i.e. doesn't include slashes).
-- The only allowed special characters are: '_', '-', '(' and ')'.
local filenamePatternSet = '[%a%d%.%_%-%(%)]'

--[[
  Validates a path on a SICK AppSpace device.
  A path is valid if the directories and basename in the path are composed of valid characters,
  and all separators are '/'.

  Params:
    path:string -- The path to validate
    relativeOK:bool (optional) -- Whether relative paths (ones which don't start with '/') are allowed. True by default
  Returns:
    valid:bool -- Whether the path provided is valid

  Author: Adrian Forbes
]]
function FileUtils.validatePath(path, relativeOK)
  local function isLegalChar(c) --Whether the character is in the list of legal characters for a file path (excluding /)
    if string.match(c, '^'..filenamePatternSet..'$') then
      return true
    end
    return false
  end

  if relativeOK == nil then
    relativeOK = true
  end

  if type(path) ~= 'string' or path == '' then
    return false
  end

  local state = 0

  for i = 1, string.len(path) + 1 do
    local c
    if i == string.len(path) + 1 then
      c = 'eol'
    else
      c = string.sub(path, i, i)
    end

    -- Pattern recognition state machine which steps through each character in the path 
    if state == 0 then
      if isLegalChar(c) then
        if relativeOK then
          state = 2
        else
          return false --Path begins with a non-slash character
        end
      elseif c == '/' then
        state = 1
      elseif c == 'eol' then
        return false
      else
        return false
      end
    elseif state == 1 then
      if isLegalChar(c) then
        state = 2
      elseif c == '/' then
        return false
      elseif c == 'eol' then
        return true
      else
        return false
      end
    elseif state == 2 then
      if isLegalChar(c) then
        state = 2
      elseif c == '/' then
        state = 1
      elseif c == 'eol' then
        return true
      else
        return false
      end
    end
  end

  return false
end

--[[
  Create file given the destination path.

  Params:
    path:string       -- The destination path for the file
    mode:string       -- Mode with which to open file. Should be a write mode of some sort, not read.
    makeDirs:bool     -- Whether to make directories in the path. If false, and directories do not exist, file creation fails.
    closeFile:bool    -- Whether to close the file after creating it

  Returns:
    success:bool      -- Whether the file could be successfully opened
    fileHandle:handle -- Handle to the file. Is nil if either it couldn't be opened or <closeFile> == true

  Author: Adrian Forbes
]]
function FileUtils.createFile(path, mode, makeDirs, closeFile)
  makeDirs = makeDirs or false
  mode = mode or "w"
  closeFile = closeFile or false

  local success = false
  local fileHandle
  local dirpath, _, _ = File.extractPathElements(path)

  if File.exists(path) then
    fileHandle = File.open(path, mode)
    if fileHandle then
      success = true
    end

  else
    local dirExists = false

    if not File.exists(dirpath) then
      if makeDirs then
        FileUtils.makeDirs(dirpath, true) -- Make path to the containing dir if it doesn't exist
      else
        success = false -- If dirpath doesn't exist (for whatever reason), file creation failed
      end
    end

    if File.exists(dirpath) then
      -- If dirpath exists, attempt to create file
      fileHandle = File.open(path, mode)
      if fileHandle then
        success = true
      end
    end
  end

  if success and closeFile then
    fileHandle:close()
    fileHandle = nil
  end

  return success, fileHandle
end

--[[
  Make all necessary directories recursively.

  Params:
    path:string             -- The path to the desired directory
    existOk:bool (optional) -- Whether existing 
  Returns:
    success:bool -- Whether the operation was successful

  Author: Adrian Forbes
]]
function FileUtils.makeDirs(path, existOK)
  local success = false

  if existOK == nil then
    existOK = false
  end

  local iter = string.gmatch(path, "([^\\/]+)")
  success = iter and true or false
  
  if success then
    local absPath = '/'

    --Create each dir in turn, as necessary
    for dir in iter do
      absPath = FileUtils.join(absPath, dir)

      if not File.exists(absPath) then
        if not existOK then
          error(string.format('Failed to create directory %s - already exists', absPath))
        end
        success = File.mkdir(absPath)

        if not success then
          break
        end
      end
    end

  end

  return success
end

--[[
  Intelligently join two paths, ensuring that there is exactly one file separator between each directory or filename.

  Params:
    path1:string -- The path on which to join <path2>
    path2:string
  Returns:
    outPath:string -- The resulting joined paths

  Author: Adrian Forbes
]]
function FileUtils.join(...)
  local args = table.pack(...)
  local outPath = string.match(args[1], '^/') and '/' or ''

  local i = 1
  for _, path in ipairs(args) do
    local iter = string.gmatch(path, '/*('..filenamePatternSet..'+)')
    
    for part in iter do
      if i ~= 1 then
        outPath = outPath..'/'
      end
      outPath = outPath..part
      i = i + 1
    end
  end

  return outPath
end

--[[
  Generate a new file or directory name given a hint for the name, and a directory
  path in which this file or directory might be created. If a file with the same
  name as the hint already exists there, this function returns a name with the
  smallest possible integer appended to the basename of the hint.

  E.g. if the name hint provided was "foobar.txt", and the following names
  already existed at the path given:
    foobar.txt, foobar1.txt, foobar3.txt
  then, the file foobar2.txt would be created.

  Returns a path to the new (currently non-existent) file or directory.

  Params:
    dirPath:string                   Path to the directory in which to look
    nameHint:string                  Hint for the file or directory name

  Returns:
    newPath:string                   New path to a file or directory, which does not yet exist
]]
function FileUtils.getNewFileSystemNodeName(dirPath, nameHint)
  if not File.exists(dirPath) then
    error("FileUtils.generateNewFile(): dirPath given does not exist; cannot create file here")
  end

  local path = FileUtils.join(dirPath, nameHint)
  local newName = nil
  local newPath = nil

  if File.exists(path) then
    -- If file with same name as provided file name hint already exists,
    -- create a new file name with the next available number appended to its end
    local dirpath, basename, ext = File.extractPathElements(path)
    local fullExt = (ext=="" and "" or "."..ext)
    local files = File.list(dirpath, string.format("%s*%s", basename, fullExt))

    local maxNum = nil
    for i = 1, #files do
      -- Find the filename with the maximum number appended to the basename given
      local num = tonumber(string.match(files[i], string.format("%s(%%d+)%s", basename, fullExt)))
      if maxNum == nil or num > maxNum then
        maxNum = num
      end
    end
    
    if maxNum == nil then
      maxNum = 0
    end

    newName = string.format("%s%d%s", basename, maxNum+1, fullExt)
  else
    -- Otherwise, just use the provided file name hint
    newName = nameHint
  end

  newPath = FileUtils.join(dirPath, newName)

  -- Return the path to the file- or directory-to-be
  return newPath
end

--[[
  Generates a new file at the given directory path given a hint.

  If a file with the same name as the hint already exists, finds the
  next valid name with the smallest possible integer appended to the basename
  (i.e. everything before the first dot).

  If file creation fails due to insufficent privileges etc., nil is returned.

  Params:
    dirPath:string                   Path to the directory in which to look
    fileNameHint:string              Hint for the filename

  Returns:
    newPath:string                   Path to the newly created file
]]
function FileUtils.generateNewFile(dirPath, fileNameHint)
  local newPath = FileUtils.getNewFileSystemNodeName(dirPath, fileNameHint)

  -- Create the new file
  local f = File.open(newPath, "wb")
  if not f then
    return nil
  else
    f:close()
    return newPath
  end
end

--[[
  Generates a new directory at the given directory path given a hint.

  If a directory with the same name as the hint already exists, finds the
  next valid name with the smallest possible integer appended to the basename
  (i.e. everything before the first dot).

  If directory creation fails due to insufficent privileges etc., nil is returned.

  Params:
    dirPath:string                  Path to the directory in which to look
    dirNameHint:string              Hint for the directory name

  Returns:
    newPath:string                   Path to the newly created directory, or nil if failed
]]
function FileUtils.generateNewDirectory(dirPath, dirNameHint)
  -- Create the new file
  local newPath = FileUtils.getNewFileSystemNodeName(dirPath, dirNameHint)
  local success = File.mkdir(newPath)

  if not success then
    return nil
  else
    return newPath
  end
end

--[[
  Given a path to a file (or directory), gets the path to its containing directory.

  Params:
    pathToFile:string                Path to the file

  Returns:
    dirPath:string                   Path to the containing directory
]]
function FileUtils.getDirPath(pathToFile)
  local dirPath, _, _ = File.extractPathElements(pathToFile)

  return dirPath
end

--[[
  Deletes all contents of a directory.
]]
function FileUtils.clearDir(dirPath)
  local success = true

  if not File.isdir(dirPath) then
    success = false
  end

  if success then
    success = File.del(dirPath)
  end

  if success then
    success = File.mkdir(dirPath)
  end

  return success
end