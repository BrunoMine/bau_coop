--[[
	Mod Bau_Coop para Minetest
	Copyright (C) 2018 BrunoMine (https://github.com/BrunoMine)
	
	Recebeste uma cópia da GNU Lesser General
	Public License junto com esse software,
	se não, veja em <http://www.gnu.org/licenses/>. 
	
	Inicializador de scripts
  ]]

-- Tabela global
bau_coop = {}

-- Limite de acessos em um bau compartilhado
bau_coop.lim_acess = tonumber(minetest.setting_get("bau_coop_limite_acessos") or 10)

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
dofile(modpath.."/tradutor.lua")
dofile(modpath.."/nodes.lua")
notificar("[OK]!")
