local gui = flow.widgets
local S = minetest.get_translator("usermgr")
local b_S = minetest.get_translator("__builtin")

local roles = {
	server = S("Admin"),
	privs = S("Admin"),
}

local function len(v)
	local c = #v
	if type(v) == "table" then
		c = 0
		for x,y in pairs(v) do
			c = c + 1
		end
	end
	return c
end

local function rmdup(t)
	local tt = {}
	for x,y in ipairs(t) do
		tt[y] = true
	end
	local rt = {}
	for x,y in pairs(tt) do
		table.insert(rt,x)
	end
	return rt
end

local function btn_event(tab)
	return function(player,ctx)
		ctx.tab = tab
		return true
	end
end

local function bug(msg)
	return gui.HBox {
		gui.VBox {
			gui.Label { label = msg },
			gui.Label { label = S("This is a bug.") },
		},
		gui.Button { name = "tab_main", label = S("Back"), on_event = btn_event("main") },
	}
end

local function popup(msg,back)
	return gui.HBox {
		gui.Label { label = msg },
		gui.Button { name = "tab_" .. (back or "main"), label = S("Back"), on_event = btn_event(back or "main") },
	}
end

local NA = popup(S("Not allowed to do this!"))

local pstatus = {
	online  = minetest.colorize("#7aeb7a",S("Online")),
	offline = S("Offline"),
	ban     = minetest.colorize("#e76464",S("Banned")),
}

local function get_pstatus(pname)
	if minetest.get_player_ip(pname) then -- Only return non-nil if the player is online
		return pstatus.online
	end
	local banned = false
	-- TODO: Check for builtin ban system
	if rawget(_G,"xban") then
		local a,b = xban.get_info(pname)
		if a then
			banned = banned or b
		end
	end
	if banned then
		return pstatus.ban
	end
	return pstatus.offline
end

local info = function () return gui.VBox {
	gui.Label { label = S("Player Management System: Software Information") },
	gui.ScrollableVBox {
		name = "info_svbox",
		h = 6,
		w = 8,

		gui.Label { label = S("Author: @1","Emoji (https://github.com/Emojigit)") },
		gui.Label { label = S("Source Code: @1","https://github.com/C-C-Minetest-Server/usermgr") },

		gui.Label { label = S("License: MIT License") },
		gui.Textarea { default =  [[
Copyright (c) 2022 Cato Yiu (Emoji)

Permission is hereby granted, free of charge, to any
person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the
Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice
shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY
OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
OR OTHER DEALINGS IN THE SOFTWARE.]] },
	},
	gui.Button { name = "tab_main", label = S("Back"), on_event = btn_event("main"), expand = true, align_h = "right"},
} end

local my_gui = flow.make_gui(function(player, ctx)
	local form = ctx.form or {}

	ctx.tab = ctx.tab or "main"
	if not ctx.players or ctx.rebuild_player then
		ctx.rebuild_player = nil
		ctx.players = {}
		local auth = minetest.get_auth_handler()
		for x,y in auth.iterate() do
			if y then
				table.insert(ctx.players,x)
			end
		end
		table.sort(ctx.players)
	end

	if ctx.tab ~= "privs" then
		ctx.privs = nil
	end

	if ctx.popup then
		local m_popup = ctx.popup
		local m_back = ctx.popup_back or ctx.tab
		ctx.popup = nil
		ctx.popup_back = nil
		return popup(m_popup,m_back)
	elseif ctx.tab == "main" then
		local right = gui.Label { label = S("No player selected."), w = 7, align_h = "centre" }
		if form.player then
			ctx.player = ctx.players[form.player]
			if ctx.player then
				local pprivs = minetest.get_player_privs(ctx.player)
				local privs = minetest.get_player_privs(player:get_player_name())
				local elems = {}
				table.insert(elems,gui.Label { label = S("Player: @1 (@2)",ctx.player,get_pstatus(ctx.player)) })
				do -- Privs
					local boxelem = {}
					local role = nil
					if ctx.player == "singleplayer" then
						role = S("Singleplayer")
					else
						for x,y in pairs(roles) do
							if pprivs[x] then
								role = y
								break
							end
						end
					end
					if role then
						table.insert(boxelem,gui.Label { label = S("Privs: @1 (@2)",len(pprivs),role) })
					else
						table.insert(boxelem,gui.Label { label = S("Privs: @1",len(pprivs)) })
					end
					if privs.privs then
						table.insert(boxelem,gui.Spacer{})
						table.insert(boxelem,gui.Button { name = "tab_privs", label = S("Manage"), on_event = btn_event("privs"), })
					end
					table.insert(elems,gui.HBox(boxelem))
				end
				local pobj = minetest.get_player_by_name(ctx.player)
				if privs.kick and privs.ban and pobj then -- Bans
					table.insert(elems,gui.HBox {
						gui.Button { name = "tab_kick", label = S("Kick"), on_event = btn_event("kick"), expand = true, align_h = "right"},
						gui.Button { name = "tab_ban", label = S("Ban"), on_event = btn_event("ban") },
						gui.Button { name = "tab_unban", label = S("Unban"), on_event = btn_event("unban")},
					})
				elseif privs.kick and pobj then
					table.insert(elems,gui.HBox {
						gui.Button { name = "tab_kick", label = S("Kick"), on_event = btn_event("kick"), expand = true, align_h = "right"},
					})
				elseif privs.ban then
					table.insert(elems,gui.HBox {
						gui.Button { name = "tab_ban", label = S("Ban"), on_event = btn_event("ban"), expand = true, align_h = "right" },
						gui.Button { name = "tab_unban", label = S("Unban"), on_event = btn_event("unban")},
					})
				end
				elems.min_w = 7
				right = gui.VBox(elems)
			end
		end
		return gui.VBox {
			gui.Label { label = S("Player Management System: Players List") },
			gui.HBox {
				gui.VBox {
					gui.Textlist {
						h = 6,
						w = 4,
						name = "player",
						on_event = function() return true end,
						listelems = ctx.players,
					},
					gui.HBox {
						gui.Button { name = "tab_newplayer", label = "+", on_event = btn_event("newplayer"), w = 0.7, h = 0.7 },
						gui.Button { name = "tab_delplayer", label = "-", on_event = btn_event("delplayer"), w = 0.7, h = 0.7 },
						gui.Button { name = "tab_info", label = S("Info"), on_event = btn_event("info"), expand = true, align_h = "right", w = 1, h = 0.7},
					}
				},
				gui.VBox {
					right,
					gui.HBox {
						gui.Label { label = S("Copyright (c) 2022 Emoji"), expand = true, align_h = "right" },
						gui.Button_exit { label = S("Exit") },
						expand = true,
						align_v = "bottom"
					}
				},
			}
		}
	elseif ctx.tab == "privs" then
		if not minetest.check_player_privs(player,{privs=true}) then
			return NA
		end
		ctx.privs = ctx.privs or {}
		local data = ctx.privs
		if not ctx.player then
			return bug(S("No player selected."))
		end
		if not data.privslist then
			data.privslist = {}
			for x,y in pairs(minetest.registered_privileges) do
				table.insert(data.privslist,x)
			end
			table.sort(data.privslist)
		end
		if not data.currprivslist then
			data.currprivslist = {}
			for x,y in pairs(minetest.get_player_privs(ctx.player)) do
				table.insert(data.currprivslist,x)
			end
		end
		data.currprivslist = rmdup(data.currprivslist)
		table.sort(data.currprivslist)
		return gui.VBox {
			gui.Label { label = S("Player Management System: Privilege -> @1",ctx.player) },
			gui.HBox {
				gui.Textlist {
					h = 6,
					w = 4,
					name = "privslist",
					listelems = data.privslist,
				},
				gui.VBox {
					gui.Button { name = "privs_add", label = ">", on_event = function(player,ctx)
						local form = ctx.form or {}
						local data = ctx.privs or {}
						if form.privslist then
							data.currprivslist[#data.currprivslist + 1] = data.privslist[form.privslist]
						end
						return true
					end },
					gui.Button { name = "privs_rm", label = "<", on_event = function(player,ctx)
						local form = ctx.form or {}
						local data = ctx.privs or {}
						if form.currprivslist then
							local privs_def = minetest.registered_privileges[data.currprivslist[form.currprivslist]]
							if ctx.player == "singleplayer" and privs_def.give_to_singleplayer then
								return true
							elseif minetest.settings:get("name") == ctx.player and (privs_def.give_to_singleplayer or privs_def.give_to_admin) then
								return true
							end
							table.remove(data.currprivslist, form.currprivslist)
						end
						return true
					end },
					gui.Spacer{},
					gui.Button { name = "privs_apply", label = S("Apply"), on_event = function(player,ctx)
						if not minetest.check_player_privs(player,{privs=true}) then
							return true
						end
						local privslist = {}
						for x,y in ipairs(data.currprivslist) do
							privslist[y] = true
						end
						minetest.set_player_privs(ctx.player,privslist)
						ctx.tab = "main"
						return true
					end },
					gui.Button { name = "tab_main", label = S("Discard"), on_event = btn_event("main") },
				},
				gui.Textlist {
					h = 6,
					w = 4,
					name = "currprivslist",
					listelems = data.currprivslist,
				},
			}
		}
	elseif ctx.tab == "ban" then
		if not minetest.check_player_privs(player,{ban=true}) then
			return NA
		end
		if not ctx.player then
			return bug(S("No player selected."))
		end
		if ctx.player == "singleplayer" then
			return popup(S("You cannot ban singleplayer!"))
		elseif ctx.player == player:get_player_name() then
			return popup(S("You don't want to ban yourself, right?"))
		end

		if rawget(_G,"xban") then -- Feature-rich bans!
			local function ban_event(player,ctx)
				if not minetest.check_player_privs(player,{ban=true}) then
					return true
				end
				local form = ctx.form or {}
				local ban_dur = tonumber(form.xban_duration)
				if ban_dur == nil then
					ctx.popup = S("Invalid Ban Duration!")
					ctx.popup_back = "ban"
					return true
				end
				if ban_dur == 0 then
					an_dur = nil
				else
					ban_dur = os.time() + ban_dur
				end
				local ban_reason = form.xban_reason
				if not ban_reason or ban_reason == "" then
					ctx.popup = S("No Ban Reason!")
					ctx.popup_back = "ban"
					return true
				end
				xban.ban_player(ctx.player, player:get_player_name(), ban_dur, ban_reason)
				ctx.tab = "main"
				return true
			end
			return gui.VBox {
				gui.Label { label = S("Player Management System: Ban -> @1",ctx.player) },
				gui.Label { label = S("Ban Duration, in second (0 = Infinity)") },
				gui.Field { name = "xban_duration", default = "0"},
				gui.Label { label = S("Ban Reason (Required)") },
				gui.Field { name = "xban_reason"},
				gui.HBox {
					gui.Button { name = "tab_main", label = S("Discard"), on_event = btn_event("main") , expand = true, align_h = "right" },
					gui.Button { name = "xban_apply", label = S("Apply"), on_event = ban_event },
				}
			}
		else -- Built-in ban...
			if not minetest.get_player_by_name(ctx.player) then
				return popup(b_S("Player is not online."))
			else
				local function ban_event(player,ctx)
					if not minetest.check_player_privs(player,{ban=true}) then
						return true
					end
					if not core.ban_player(ctx.player) then
						ctx.popup = b_S("Failed to ban player.")
						ctx.popup_back = "main"
						return true
					end
					ctx.tab = "main"
					return true
				end
				return gui.VBox {
					gui.Label { label = S("Player Management System: Ban -> @1",ctx.player) },
					gui.Label { label = S("Do you really want to ban @1?",ctx.player), h = 1.5 },
					gui.HBox {
						gui.Button { name = "tab_main", label = S("Discard"), on_event = btn_event("main") , expand = true, align_h = "right" },
						gui.Button { name = "ban_apply", label = S("Apply"), on_event = ban_event },
					}
				}
			end
		end
	elseif ctx.tab == "unban" then
		if not minetest.check_player_privs(player,{ban=true}) then
			return NA
		end
		return gui.VBox {
			gui.Label { label = S("Player Management System: Unban -> @1",ctx.player) },
			gui.Label { label = S("Do you really want to unban @1?",ctx.player), h = 1.5 },
			gui.HBox {
				gui.Button { name = "tab_main", label = S("Discard"), on_event = btn_event("main") , expand = true, align_h = "right" },
				gui.Button { name = "unban_apply", label = S("Apply"), on_event = function(player,ctx)
					if not minetest.check_player_privs(player,{ban=true}) then
						return NA
					end
					local form = ctx.form
					minetest.unban_player_or_ip(ctx.player)
					if rawget(_G,"xban") then
						xban.unban_player(ctx.player, player:get_player_name())
					end
					ctx.tab = "main"
					return true
				end },
			}
		}
	elseif ctx.tab == "kick" then
		if not minetest.check_player_privs(player,{kick=true}) then
			return NA
		end
		if not ctx.player then
			return bug(S("No player selected."))
		end
		if not minetest.get_player_by_name(ctx.player) then
			return popup(b_S("Player is not online."))
		end
		return gui.VBox {
			gui.Label { label = S("Player Management System: Kick -> @1",ctx.player) },
			gui.Label { label = S("Kick Reason (Optional)") },
			gui.Field { name = "kick_reason" },
			gui.HBox {
				gui.Button { name = "tab_main", label = S("Discard"), expand = true, align_h = "right", on_event = btn_event("main") },
				gui.Button { name = "ban_qpply", label = S("Apply"), on_event = function(player,ctx)
					if not minetest.check_player_privs(player,{kick=true}) then
						return NA
					end
					local form = ctx.form
					local reason = form.kick_reason
					if reason == "" then reason = nil end
					minetest.kick_player(ctx.player,reason)
					ctx.tab = "main"
					return true
				end },
			}
		}
	elseif ctx.tab == "newplayer" then
		if not minetest.check_player_privs(player,{server=true}) then
			return NA
		end
		return gui.VBox {
			gui.Label { label = S("Player Management System: New Player") },
			gui.Label { label = S("Username") },
			gui.Field { name = "np_uname" },
			gui.Label { label = S("Password (Empty to clear)") },
			gui.Field { name = "np_passwd" },
			gui.HBox {
				gui.Button { name = "tab_main", label = S("Discard"), expand = true, align_h = "right", on_event = btn_event("main") },
				gui.Button { name = "np_apply", label = S("Apply"), on_event = function(player,ctx)
					if not minetest.check_player_privs(player,{server=true}) then
						return NA
					end
					local form = ctx.form
					local uname = form.np_uname or ""
					local passwd = form.np_passwd or ""
					if uname == "" then
						ctx.popup = "No username!"
						return true
					elseif uname == "singleplayer" then
						ctx.popup = "Singleplayer must have no password!"
						return true
					end
					minetest.set_player_password(uname,passwd)
					ctx.rebuild_player = true
					ctx.tab = "main"
					return true
				end },
			}
		}
	elseif ctx.tab == "delplayer" then
		if not minetest.check_player_privs(player,{server=true}) then
			return NA
		elseif not ctx.player then
			return bug(S("No player selected."))
		elseif ctx.player == player:get_player_name() then
			return popup(S("You cannot delete yourself!"),"main")
		end
		return gui.VBox {
			gui.Label { label = S("Player Management System: Delete Player -> @1",ctx.player) },
			gui.Label { label = S("Do you really want to delete @1?",ctx.player), h = 1.5 },
			gui.HBox {
				gui.Button { name = "tab_main", label = S("Discard"), on_event = btn_event("main") , expand = true, align_h = "right" },
				gui.Button { name = "ban_qpply", label = S("Apply"), on_event = function(player,ctx)
					if not minetest.check_player_privs(player,{server=true}) then
						return NA
					end
					local form = ctx.form
					ctx.rebuild_player = true
					minetest.disconnect_player(ctx.player,"The server admin deleted your account.")
					minetest.remove_player(ctx.player)
					minetest.remove_player_auth(ctx.player)
					ctx.tab = "main"
					return true
				end },
			}
		}
	elseif ctx.tab == "info" then
		return info()
	else
		return bug(S("Unknown Tab!"))
	end
end)

minetest.register_chatcommand("usermgr",{
	description = S("GUI to manage players"),
	-- privs = {privs = true}, -- Each tab have their individual privs setting
	func = function(player,param)
		my_gui:show(player,{})
		return true
	end
})
