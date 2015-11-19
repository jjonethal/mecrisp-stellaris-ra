local fin = io.open("mecrisp-stellaris-stm32f411.bin","rb")
local fout= io.open("mecrisp-stellaris-stm32f411.txt","w")
local buIn = fin:read("*a")
fin:close()
local l=1
local csum=0
local function updateCsum(b, csum)
  csum=csum or 0
  csum=csum+b
  while csum >= 65536 do
    csum = csum - 65536
    csum=csum + 1
  end
  return csum
end

fout:write(string.format("\n#%d constant IMAGE-SIZE\n IMAGE-SIZE buffer: flash-image-buffer\n",#buIn))
fout:write(string.format("flash-image-buffer flash-image-buffer-adr !\n"))
fout:write(string.format("IMAGE-SIZE flash-image-size !\n"))

for i=1, #buIn do
  local b = string.byte(string.sub(buIn,i,i))
  csum = updateCsum(b,csum)
  io.write(string.format("\rcsum: %06d           ",csum))
  fout:write(string.format("$%02X , ", b))
  l = l + 1
  if l > 16 then
    fout:write("\n")
    l=1
  end
end
fout:write("\n")
fout:write(string.format("#%d csum\n",csum))
fout:close()
