-- Assurez-vous que l'API HTTP est activée dans la config de CC:Tweaked

local aukitPath = "aukit.lua"
local austreamPath = "austream.lua"
local upgradePath = "upgrade"

local function fileExists(path)
  return fs.exists(path) and not fs.isDir(path)
end

-- Téléchargement des dépendances
if not fileExists(aukitPath) then
  shell.run("wget run https://github.com/MCJack123/AUKit/raw/master/aukit.lua")
end

if not fileExists(austreamPath) then
  shell.run("wget run https://github.com/MCJack123/AUKit/raw/master/austream.lua")
end

if not fileExists(upgradePath) then
  shell.run("pastebin get PvwtVW1S " .. upgradePath)
end

-- Récupérer la playlist
local playlistURL = "https://github.com/nicogb2007/spotifo-2/raw/refs/heads/main/playlist.json"
local response = http.get(playlistURL)

if not response then
  print("Erreur : impossible de télécharger la playlist.")
  return
end

local data = response.readAll()
response.close()

local ok, onlinePlaylist = pcall(textutils.unserializeJSON, data)
if not ok or type(onlinePlaylist) ~= "table" then
  print("Erreur : playlist en ligne invalide.")
  return
end

-- Charger ou initialiser la playlist locale
local playlistFile = "playlist.json"
local playlist = {}

if fileExists(playlistFile) then
  local f = fs.open(playlistFile, "r")
  local localData = f.readAll()
  f.close()
  playlist = textutils.unserializeJSON(localData) or {}
end

-- Fusionner les playlists
for _, entry in ipairs(onlinePlaylist) do
  table.insert(playlist, entry)
end

-- Sauvegarder la nouvelle playlist
local f = fs.open(playlistFile, "w")
f.write(textutils.serializeJSON(playlist))
f.close()

-- Affichage du menu
local function playMusic(title, url)
  print("Lecture de : " .. title)
  shell.run(austreamPath, url)
end

local function displayMenu()
  local musicList = {}
  for _, e in ipairs(playlist) do table.insert(musicList, e.title) end

  local page, selection = 1, 1
  local perPage = 6
  local maxPage = math.ceil(#musicList / perPage)

  while true do
    term.clear()
    term.setCursorPos(1, 1)
    print("Spotifo - by Dartsgame")
    print(string.rep("-", 20))

    local startIdx = (page - 1) * perPage + 1
    for i = 0, perPage - 1 do
      local idx = startIdx + i
      if idx > #musicList then break end
      if i + 1 == selection then
        term.setTextColor(colors.green)
      else
        term.setTextColor(colors.white)
      end
      print((i + 1) .. ". " .. musicList[idx])
    end

    term.setTextColor(colors.white)
    print(string.format("Page %d / %d", page, maxPage))
    local _, key = os.pullEvent("key")

    if key == keys.up then
      selection = selection - 1
      if selection < 1 then selection = perPage end
    elseif key == keys.down then
      selection = selection + 1
      if selection > perPage then selection = 1 end
    elseif key == keys.left then
      if page > 1 then page = page - 1 selection = 1 end
    elseif key == keys.right then
      if page < maxPage then page = page + 1 selection = 1 end
    elseif key == keys.enter then
      local idx = (page - 1) * perPage + selection
      if playlist[idx] then
        playMusic(playlist[idx].title, playlist[idx].url)
      end
    end
  end
end

displayMenu()
