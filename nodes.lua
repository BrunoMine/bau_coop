--[[
	Mod Bau_Coop para Minetest
	Copyright (C) 2017 BrunoMine (https://github.com/BrunoMine)
	
	Recebeste uma cópia da GNU Lesser General
	Public License junto com esse software,
	se não, veja em <http://www.gnu.org/licenses/>. 
	
	Nodes
  ]]

-- Tradutor
local S = bau_coop.S

-- Variavel de acesso
local acessos = {}

-- Remover nome dos acessos ao sair
minetest.register_on_leaveplayer(function(player)
	acessos[player:get_player_name()] = nil
end)

-- Formspec de acesso negado
local formspec_acesso_negado = "size[7,2]"
	.. default.gui_bg
	.. default.gui_bg_img
	.. "image[0,0;2,2;bau_coop_acesso.png]"
	.. "label[2,0.75;"..core.colorize("#FF0000", S("Acesso Negado")).."]"


local function pegar_formspec_bau_compartilhado(pos)
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	local formspec =
		"size[8,10]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"list[nodemeta:" .. spos .. ";main;0,1.3;8,4;]" ..
		"list[current_player;main;0,5.85;8,1;]" ..
		"list[current_player;main;0,7.08;8,3;8]" ..
		"listring[nodemeta:" .. spos .. ";main]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0,5.85) ..
		"label[0,0;"..S("Bau Compartilhado").."]" ..
		"image_button[7,0;1,1;bau_coop_acesso.png;controle_acesso;]"
	return formspec
end

local function pegar_formspec_painel_acesso(name, meta, msg, erro)
	local lista = ""
	local donos = meta:get_string("permitidos")
	if donos and donos ~= "" then
		donos = minetest.deserialize(donos)
		for _,n in ipairs(donos) do
			if lista ~= "" then lista = lista .. "," end
			lista = lista .. n
		end
	end
	local formspec = "size[8,7]"
		.. default.gui_bg
		.. default.gui_bg_img
		.. "image[0,0;2,2;bau_coop_acesso.png]"
		.. "label[2,0;"..S("Bau Compartilhado").."]"
		.. "button[6,0;2,1;voltar;"..S("Voltar").."]"
		-- Adicionar acesso
		.. "field[0.3,2.8;4.8,1;novo_acesso;"..S("Adicionar novo jogador")..";]"
		.. "button[5,2.49;3,1;adicionar;"..S("Adicionar Acesso").."]"
		-- Remover acesso
		.. "label[0,3.7;"..S("Jogadores com acesso").."]"
		.. "dropdown[0,4.125;5,1;nome_acesso;"..lista..";]"
		.. "button[5,4;3,1;remover;"..S("Remover Acesso").."]"
	
	if msg then
		if erro then
			formspec = formspec .. "label[2,1;"..core.colorize("#FF0000", msg).."]"
		else
			formspec = formspec .. "label[2,1;"..msg.."]"
		end
	end
	
	return formspec
end

local function verificar_acesso(meta, player)
	local name = ""
	if player then
		if minetest.check_player_privs(player, "protection_bypass") then
			return true
		end
		name = player:get_player_name()
	end
	
	if meta:get_string("permitidos") == "" then
		return true
	end
	
	for _,n in ipairs(minetest.deserialize(meta:get_string("permitidos"))) do
		if name == n then
			return true
		end
	end
	return false
end

-- Fechar bau
local fechar = function(name)
	local pos = acessos[name]
	if not pos then return end
	local node = minetest.get_node(pos)
	
	-- Verifica se tem mais alguem acessando 
	for k, v in pairs(acessos) do
		if k ~= name and pos.x == pos.x and pos.y == pos.y and pos.z == pos.z then
			acessos[name] = nil -- Remover nome dos acessos
			return
		end
	end
	minetest.after(0.2, minetest.swap_node, minetest.deserialize(minetest.serialize(pos)), { name = "bau_coop:bau_compartilhado",
			param2 = node.param2 })
	minetest.sound_play("bau_coop_close", {gain = 0.3, pos = pos, max_hear_distance = 10})
	acessos[name] = nil -- Remover nome dos acessos
end


-- Receptor de botoes
minetest.register_on_player_receive_fields(function(player, formname, fields)
	
	-- Ao sair
	if formname == "bau_coop:bau_compartilhado" and fields.quit then
		local name = player:get_player_name()
		fechar(name)
	end
	
	-- Dono
	if formname == "bau_coop:bau_compartilhado" then
		if not acessos[player:get_player_name()] then return end
		local pos = acessos[player:get_player_name()]
		local meta = minetest.get_meta(pos)
		
		-- Verificar se eh o dono
		if meta:get_string("dono") ~= player:get_player_name() then
			return
		end
		
		if verificar_acesso(meta, player) == false then
			return minetest.show_formspec(
				player:get_player_name(),
				"bau_coop:bau_compartilhado",
				formspec_acesso_negado
			)
		end
		
		-- Acessar painel de controle de acesso
		if fields.controle_acesso then
			
			return minetest.show_formspec(
				player:get_player_name(),
				"bau_coop:bau_compartilhado",
				pegar_formspec_painel_acesso(player:get_player_name(), meta)
			)
		
		-- Adicionar acesso de um jogador
		elseif fields.adicionar then
			local donos = minetest.deserialize(meta:get_string("permitidos"))
			
			-- Verificar se um nome foi especificado
			if fields.novo_acesso == "" then
				return minetest.show_formspec(
					player:get_player_name(),
					"bau_coop:bau_compartilhado",
					pegar_formspec_painel_acesso(player:get_player_name(), meta, S("Nenhum nome especificado"), true)
				)
			end
			
			-- Verificar se ja esta no limite de acessos
			if table.maxn(donos) >= bau_coop.lim_acess then
				return minetest.show_formspec(
					player:get_player_name(),
					"bau_coop:bau_compartilhado",
					pegar_formspec_painel_acesso(player:get_player_name(), meta, S("Limite de @1 jogadores", bau_coop.lim_acess), true)
				)
			end
			
			-- Verificar se ja esta registrado
			for _,n in ipairs(donos) do
				if n == fields.novo_acesso then
					return minetest.show_formspec(
						player:get_player_name(),
						"bau_coop:bau_compartilhado",
						pegar_formspec_painel_acesso(player:get_player_name(), meta, S("Jogador ja registrado"), true)
					)
				end
			end
			
			-- Adiciona o acesso ao jogador
			table.insert(donos, fields.novo_acesso)
			meta:set_string("permitidos", minetest.serialize(donos))
			
			minetest.sound_play("bau_coop_blip", {gain = 0.2,
					pos = pos, max_hear_distance = 10})
			
			return minetest.show_formspec(
				player:get_player_name(),
				"bau_coop:bau_compartilhado",
				pegar_formspec_painel_acesso(player:get_player_name(), meta, S("@1 agora tem acesso", fields.novo_acesso))
			)
			
		-- Remover acesso de um jogador
		elseif fields.remover then
			local donos = minetest.deserialize(meta:get_string("permitidos"))
			
			-- Verifica se eh o proprio dono se removendo
			if fields.nome_acesso == meta:get_string("dono") then
				return minetest.show_formspec(
					player:get_player_name(),
					"bau_coop:bau_compartilhado",
					pegar_formspec_painel_acesso(player:get_player_name(), meta, S("Nao pode remover a si mesmo"), true)
				)
			end
			
			-- Verificar se o jogador selecionado eh ultimo dono
			if table.maxn(donos) == 1 then
				return minetest.show_formspec(
					player:get_player_name(),
					"bau_coop:bau_compartilhado",
					pegar_formspec_painel_acesso(player:get_player_name(), meta, S("Apenas um dono restante"), true)
				)
			end
			
			-- Remover o acesso
			local tb = {}
			for _,n in ipairs(donos) do
				if n ~= fields.nome_acesso then
					table.insert(tb, n)
				end
			end
			donos = tb
			meta:set_string("permitidos", minetest.serialize(donos))
			
			-- Verifica se o jogador ainda tem acesso
			if verificar_acesso(meta, player) == false then
				return minetest.show_formspec(
					player:get_player_name(),
					"bau_coop:bau_compartilhado",
					formspec_acesso_negado
				)
			end
			
			minetest.sound_play("bau_coop_blip", {gain = 0.2,
					pos = pos, max_hear_distance = 10})
			
			return minetest.show_formspec(
				player:get_player_name(),
				"bau_coop:bau_compartilhado",
				pegar_formspec_painel_acesso(player:get_player_name(), meta, S("@1 perdeu o acesso", fields.nome_acesso))
			)
			
		-- Voltar para a formspec normal do bau
		elseif fields.voltar then
			if verificar_acesso(meta, player) then
				minetest.show_formspec(
					player:get_player_name(),
					"bau_coop:bau_compartilhado",
					pegar_formspec_bau_compartilhado(pos)
				)
			end
		
		end
		
	end
	
end)

minetest.register_node("bau_coop:bau_compartilhado", {
	description = S("Bau Compartilhado"),
	tiles = {
		"default_chest_top.png", 
		"default_chest_top.png", 
		"default_chest_side.png^[transformFX",
		"default_chest_side.png", 
		"default_chest_side.png", 
		"default_chest_side.png^bau_coop_frente.png"
	},
	paramtype2 = "facedir",
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("dono", placer:get_player_name())
		meta:set_string("permitidos", minetest.serialize({placer:get_player_name()}))
		meta:set_string("infotext", S("Bau Compartilhado (@1)", placer:get_player_name()))
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 8 * 4)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return ( inv:is_empty("main") and verificar_acesso(meta, player) ) or minetest.check_player_privs(player, "protection_bypass")
	end,
	
	
	allow_metadata_inventory_move = function(pos, from_list, from_index,
			to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		if minetest.check_player_privs(player, "protection_bypass") then return count end
		if not verificar_acesso(meta, player) then
			return 0
		end
		return count
	end,
	
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if minetest.check_player_privs(player, "protection_bypass") then return stack:get_count() end
		if not verificar_acesso(meta, player) then
			return 0
		end
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if minetest.check_player_privs(player, "protection_bypass") then return stack:get_count() end
		if not verificar_acesso(meta, player) then
			return 0
		end
		return stack:get_count()
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name() ..
			" moveu " .. stack:get_name() ..
			" para o bau compartilhado em " .. minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name() ..
			" pegou " .. stack:get_name()  ..
			" do bau compartilhado em " .. minetest.pos_to_string(pos))
	end,
	
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		
		local name = clicker:get_player_name()
		local meta = minetest.get_meta(pos)
		
		if verificar_acesso(meta, clicker) then
			
			if minetest.get_node(pos).name == "bau_coop:bau_compartilhado" then
				minetest.sound_play("bau_coop_open", {gain = 0.2,
					pos = pos, max_hear_distance = 10})
				minetest.after(0.1 , minetest.swap_node, minetest.deserialize(minetest.serialize(pos)),
							{ name = "bau_coop:bau_compartilhado_aceso",
							param2 = node.param2 })
				if minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z}).name == "air" then
					minetest.after(0.5 , minetest.swap_node, minetest.deserialize(minetest.serialize(pos)),
							{ name = "bau_coop:bau_compartilhado_open",
							param2 = node.param2 })
				end
			end
			
			acessos[clicker:get_player_name()] = {x=pos.x, y=pos.y, z=pos.z}
			minetest.after(0.65, minetest.show_formspec,
				clicker:get_player_name(),
				"bau_coop:bau_compartilhado",
				pegar_formspec_bau_compartilhado(pos)
			)
		end
		return itemstack
	end,
	on_blast = function() end,
})

-- Bau com telinha acessa
do
	-- Copiar tabela de definições
	local def = {}
	for n,d in pairs(minetest.registered_nodes["bau_coop:bau_compartilhado"]) do
		def[n] = d
	end
	-- Mantem a tabela groups separada
	def.groups = minetest.deserialize(minetest.serialize(def.groups))
	def.groups.not_in_creative_inventory = 1
	def.drop = "bau_coop:bau_compartilhado"
	
	-- Altera alguns paremetros
	def.tiles = {
		"default_chest_top.png", 
		"default_chest_top.png", 
		"default_chest_side.png^[transformFX",
		"default_chest_side.png", 
		"default_chest_side.png", 
		"default_chest_side.png^bau_coop_frente_acesa.png"
	}
	
	-- Registra o novo node
	minetest.register_node("bau_coop:bau_compartilhado_aceso", def)
end

-- Bau aberto
do
	-- Copiar tabela de definições
	local def = {}
	for n,d in pairs(minetest.registered_nodes["bau_coop:bau_compartilhado"]) do
		def[n] = d
	end
	-- Mantem a tabela groups separada
	def.groups = minetest.deserialize(minetest.serialize(def.groups))
	
	-- Altera alguns paremetros
	def.tiles = {
		"default_chest_top.png", 
		"default_chest_top.png", 
		"default_chest_side.png",
		"default_chest_side.png", 
		"default_chest_side.png^bau_coop_frente_acesa.png", 
		"default_chest_inside.png"
	}
	def.drawtype = "mesh"
	def.visual = "mesh"
	def.paramtype = "light"
	def.paramtype2 = "facedir"
	def.legacy_facedir_simple = true
	def.is_ground_content = false
	def.groups.not_in_creative_inventory = 1
	def.mesh = "chest_open.obj"
	def.drop = "bau_coop:bau_compartilhado"
	def.selection_box = {
		type = "fixed",
		fixed = { -1/2, -1/2, -1/2, 1/2, 3/16, 1/2 },
		}
	def.can_dig = function()
		return false
	end
	
	-- Registra o novo node
	minetest.register_node("bau_coop:bau_compartilhado_open", def)
end

-- Fecha baus que ficaram abertos ao fechar o mundo
minetest.register_lbm({
	name = "bau_coop:fechar_bau",
	nodenames = {"bau_coop:bau_compartilhado_open"},
	run_at_every_load = true,
	action = function(pos, node)
		minetest.swap_node(pos, { name = "bau_coop:bau_compartilhado",
				param2 = node.param2 })
	end,
})

minetest.register_craft({
	output = 'bau_coop:bau_compartilhado',
	recipe = {
		{'default:chest_locked', 'default:copper_ingot'},
		{'default:tin_ingot', 'default:glass'}
	}
})
