local aukitPath = "aukit.lua"
local austreamPath = "austream.lua"
local upgradePath = "upgrade"
local playlistFile = "playlist.json"
local playlistURL = "https://github.com/nicogb2007/spotifo-2/raw/refs/heads/main/playlist.json"

local function fileExists(path)
  return fs.exists(path) and not fs.isDir(path)
end

-- Télécharger les fichiers nécessaires
if not fileExists(aukitPath) then
  shell.run("wget", "https://github.com/MCJack123/AUKit/raw/master/aukit.lua", aukitPath)
end

if not fileExists(austreamPath) then
  shell.run("wget", "https://github.com/MCJack123/AUKit/raw/master/austream.lua", austreamPath)
end

if not fileExists(upgradePath) then
  shell.run("pastebin", "get", "PvwtVW1S", upgradePath)
end

-- Télécharger la playlist
local response = http.get(playlistURL)
if not response then
  print("Erreur lors du téléchargement de la playlist.")
  return
end

local playlistData = response.readAll()
response.close()

local success, onlinePlaylist = pcall(textutils.unserializeJSON, playlistData)
if not success or type(onlinePlaylist) ~= "table" then
  print("Erreur de parsing de la playlist en ligne.")
  return
end

-- Charger ou initialiser la playlist locale
local playlist = {}
if fileExists(playlistFile) then
  local handle = fs.open(playlistFile, "r")
  local content = handle.readAll()
  handle.close()
  local ok, localData = pcall(textutils.unserializeJSON, content)
  if ok and type(localData) == "table" then
    playlist = localData
  end
end

-- Fusionner sans doublons
local titles = {}
for _, track in ipairs(playlist) do
  titles[track.title] = true
end
for _, track in ipairs(onlinePlaylist) do
  if not titles[track.title] then
    table.insert(playlist, track)
    titles[track.title] = true
  end
end

-- Sauvegarder la playlist fusionnée
local handle = fs.open(playlistFile, "w")
handle.write(textutils.serializeJSON(playlist))
handle.close()

-- Liste de titres
local musicList = {}
for _, track in ipairs(playlist) do
  table.insert(musicList, track.title)
end

-- Fonction pour lire une musique
local function playMusic(_, url)
  shell.run(austreamPath, url)
end


-- Affichage du menu
local function displayMusicMenu()
  local itemsPerPage = 6
  local currentPage = 1
  local selectedIndex = 1
  local totalPages = math.ceil(#musicList / itemsPerPage)

  while true do
    term.clear()
    local w, h = term.getSize()
    term.setCursorPos((w - #"Spotifo") / 2, 2)
    term.setTextColor(colors.green)
    term.write("Spotifo")
    term.setCursorPos((w - #"by Dartsgame") / 2, 3)
    term.write("by Dartsgame")

    local startIndex = (currentPage - 1) * itemsPerPage + 1
    local endIndex = math.min(startIndex + itemsPerPage - 1, #musicList)

    for i = startIndex, endIndex do
      term.setCursorPos(1, 5 + i - startIndex)
      if i - startIndex + 1 == selectedIndex then
        term.setTextColor(colors.green)
      else
        term.setTextColor(colors.white)
      end
      term.write((i - startIndex + 1) .. ". " .. musicList[i])
    end

    term.setCursorPos((w - 15) / 2, h)
    term.setTextColor(colors.white)
    term.write("Page " .. currentPage .. "/" .. totalPages)

    local _, key = os.pullEvent("key")
    if key == keys.up then
      selectedIndex = selectedIndex - 1
      if selectedIndex < 1 then selectedIndex = endIndex - startIndex + 1 end
    elseif key == keys.down then
      selectedIndex = selectedIndex + 1
      if selectedIndex > endIndex - startIndex + 1 then selectedIndex = 1 end
    elseif key == keys.left and currentPage > 1 then
      currentPage = currentPage - 1
      selectedIndex = 1
    elseif key == keys.right and currentPage < totalPages then
      currentPage = currentPage + 1
      selectedIndex = 1
    elseif key == keys.enter then
      local selected = playlist[startIndex + selectedIndex - 1]
      playMusic(selected.title, selected.url)
    end
  end
end

displayMusicMenu()
