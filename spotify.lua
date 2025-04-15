local aukitPath = "aukit.lua"
local austreamPath = "austream.lua"
local upgradePath = "upgrade"

local function fileExists(path)
  return fs.exists(path) and not fs.isDir(path)
end

-- Télécharger les fichiers nécessaires si ils n'existent pas déjà
if not fileExists(aukitPath) then
  shell.run("wget", "https://github.com/MCJack123/AUKit/raw/master/aukit.lua", aukitPath)
end

if not fileExists(austreamPath) then
  shell.run("wget", "https://github.com/MCJack123/AUKit/raw/master/austream.lua", austreamPath)
end

if not fileExists(upgradePath) then
  shell.run("pastebin", "get", "PvwtVW1S", upgradePath)
end

-- Télécharger la playlist JSON en ligne
local playlistFile = "playlist.json"
local playlistURL = "https://raw.githubusercontent.com/Miniprimestaff/music-cc/main/program/playlist.json"
local response = http.get(playlistURL)

if response then
  local playlistData = response.readAll()
  response.close()

  local success, onlinePlaylist = pcall(textutils.unserializeJSON, playlistData)
  if success and type(onlinePlaylist) == "table" then
    local playlist = {}

    -- Charger ou créer une playlist locale
    if fileExists(playlistFile) then
      local fileHandle = fs.open(playlistFile, "r")
      local localPlaylistData = fileHandle.readAll()
      fileHandle.close()
      playlist = textutils.unserializeJSON(localPlaylistData)
    else
      local fileHandle = fs.open(playlistFile, "w")
      fileHandle.write(textutils.serializeJSON(playlist))
      fileHandle.close()
    end

    -- Ajouter la playlist en ligne à la locale
    for _, entry in ipairs(onlinePlaylist) do
      table.insert(playlist, entry)
    end

    -- Sauvegarder la nouvelle playlist locale
    local fileHandle = fs.open(playlistFile, "w")
    fileHandle.write(textutils.serializeJSON(playlist))
    fileHandle.close()

    local musicList = {}
    for _, entry in ipairs(playlist) do
      table.insert(musicList, entry.title)
    end

    -- Fonction pour lire la musique avec austream
    local function playMusic(title, musicURL)
      shell.run(austreamPath, musicURL)
    end

    -- Affichage du menu de sélection de musique
    local function displayMusicMenu()
      local itemsPerPage = 6
      local currentPage = 1
      local totalOptions = #musicList
      local totalPages = math.ceil(totalOptions / itemsPerPage)
      local selectedIndex = 1

      while true do
        term.clear()
        term.setCursorPos(1, 3)

        -- Affichage du logo
        local screenWidth, screenHeight = term.getSize()
        local logoText = "Spotifo"
        local byText = "by Dartsgame"
        term.setTextColor(colors.green)
        term.setCursorPos((screenWidth - #logoText) / 2, 2)
        term.write(logoText)
        term.setCursorPos((screenWidth - #byText) / 2, 3)
        term.write(byText)

        -- Affichage de la playlist
        local startIndex = (currentPage - 1) * itemsPerPage + 1
        local endIndex = math.min(startIndex + itemsPerPage - 1, totalOptions)

        for i = startIndex, endIndex do
          local optionIndex = i - startIndex + 1
          local option = musicList[i]

          if optionIndex == selectedIndex then
            term.setTextColor(colors.green)
          else
            term.setTextColor(colors.white)
          end
          print(optionIndex .. ". " .. option)
        end

        -- Affichage du footer avec la page actuelle
        term.setTextColor(colors.white)
        local pageText = "Page " .. currentPage .. " / " .. totalPages
        term.setCursorPos((screenWidth - #pageText) / 2, screenHeight)
        term.write(pageText)

        -- Navigation avec les flèches et sélection
        local _, key = os.pullEvent("key")

        if key == keys.up then
          selectedIndex = selectedIndex - 1
          if selectedIndex < 1 then
            selectedIndex = endIndex - startIndex + 1
          end
        elseif key == keys.down then
          selectedIndex = selectedIndex + 1
          if selectedIndex > endIndex - startIndex + 1 then
            selectedIndex = 1
          end
        elseif key == keys.left and currentPage > 1 then
          currentPage = currentPage - 1
          selectedIndex = 1
        elseif key == keys.right and currentPage < totalPages then
          currentPage = currentPage + 1
          selectedIndex = 1
        elseif key == keys.enter then
          local selectedOption = startIndex + selectedIndex - 1
          local selectedMusic = playlist[selectedOption]
          playMusic(selectedMusic.title, selectedMusic.url)
        end
      end
    end

    displayMusicMenu()
  else
    print("Erreur de parsing de la playlist en ligne.")
  end
else
  print("Erreur lors du téléchargement de la playlist.")
end
