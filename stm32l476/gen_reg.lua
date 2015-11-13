-- reg_reg.lua
fname=[[C:\Users\jeanjo\Downloads\stm\STMicroelectronics_CMSIS_SVD\STM32L4x6.svd]]
PERIPHERAL_O="<peripheral>"
PERIPHERAL_C="</peripheral>"
f=io.open(fname,"r")
cv=f:read("*a")
f:close()
local root={}
local objectStack={root}
local currentItem=objectStack[#objectStack]

peripheralsByName={}
peripherals={}
currentPeripheral={}
currentItem={}
currentRegisterSet={}

local function copy(dest, source)
  for k,v in pairs(source) do
    dest[k]=v
  end
end
local function newPeripheral(tag, bopen,value, attrib)
  if(bopen) then
    currentPeripheral = currentItem
    peripherals[#peripherals+1]=currentItem
  else
    peripheralsByName[currentPeripheral.name]=currentPeripheral
    print("Peripheral", currentPeripheral.name)
  end
end

local function addDescription(bopen, value)
  if(bOpen) then
    currentItem.description=value 
  end
end

local function setProperty(tag,bOpen, val)
  if(bOpen==true) then
    local parent=objectStack[#objectStack-1]
    if parent ~= nil then
      parent[tag]=val
    end
  end
end
local function addRegisterSet(tag,bOpen, val)
  if(bOpen==true) then
    currentRegisterSet=currentItem
  end
end
local taglist={
  peripheral  = newPeripheral,
  name        = setProperty,
  description = setProperty,
  displayName = setProperty,
  addressOffset = setProperty,
  registers = addRegisterSet,
}
local function attribList(attribs)
  local list
  if attribs ~= nil then
    do
      list={}
      attribs:gsub("([0-9a-zA-Z:]+)[%s%c]*=[%s%c]*\"([^\"]*)\"",function(attrib,val) list[attrib]=val end)
    end
  end
  return list
end
local function parser(oc,tag, attribs,value)
  if tag~=nil then
    f=taglist[tag]
    if(f ~= nil) then
      -- print(tag, oc, value)
      bOpen = (oc==nil or oc=="")
      if bOpen == true then
        newItem = {tag=tag, val=value,}
        currentItem[#currentItem+1]=newItem
        currentItem = newItem
        objectStack[#objectStack+1]=currentItem
        print("open",tag,#objectStack)
      else
        print("close",tag,#objectStack)
        if objectStack[#objectStack].tag ~= tag then
          print("unmatched closing tag",objectStack[#objectStack].tag, tag, #objectStack)
        end
        objectStack[#objectStack]=nil
        currentItem=objectStack[#objectStack]
      end
      f(tag, bOpen, value, attribs)
    end
  end
end
--               tag name     attributes  values
cv:gsub("<(/?)([a-zA-Z0-9_]*)([^<>/%s%c]*)>([^<>/]*)", parser)
--[[
for l in io.lines(fname) do
  tag_open=string.match(l,"<([^</>]*)>")
  if tag_open ~= nil then
    print("open",tag_open)
  else
    tag_close=string.match(l,"</([^</>]*)>")
    if tag_close ~= nil then
      print("close", tag_close)
    else
      
    end
  end
end
]]
