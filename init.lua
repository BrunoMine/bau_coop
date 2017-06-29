--[[
	Mod Bau_Coop para Minetest
	Copyright (C) 2017 BrunoMine (https://github.com/BrunoMine)
	
	Recebeste uma cópia da GNU Lesser General
	Public License junto com esse software,
	se não, veja em <http://www.gnu.org/licenses/>. 
	
	Inicializador de scripts
  ]]

-- Tabela global
bau_coop = {}

-- Notificador de Inicializador
local notificar = function(msg)
	if minetest.setting_get("log_mods") then
		minetest.debug("[Bau_Coop]"..msg)
	end
end

-- Modpath
local modpath = minetest.get_modpath("bau_coop")

-- Carregar scripts
notificar("Carregando...")
dofile(modpath.."/nodes.lua")
notificar("[OK]!")
