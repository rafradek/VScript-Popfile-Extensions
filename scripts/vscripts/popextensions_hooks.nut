function AddHooksToScope(name, table, scope)
{
	foreach (hookName, func in table) {
		// Entries in hook table must begin with 'On' to be considered hooks
		if (hookName[0] == 'O' && hookName[1] == 'n') {
			if (!("popHooks" in scope)) {
				scope["popHooks"] <- {};
			}
			if (!(hookName in scope.popHooks)) {
				scope.popHooks[hookName] <- [];
			}
			scope.popHooks[hookName].append(func);
		}
	}
}
function FireHooks(entity, scope, name) {
	if (scope != null && "popHooks" in scope && name in scope.popHooks) {
		foreach (index, func in scope.popHooks[name]) {
			func(entity);
		}
	}
}

function FireHooksParam(entity, scope, name, param) {
	if (scope != null && "popHooks" in scope && name in scope.popHooks) {
		foreach (index, func in scope.popHooks[name]) {
			func(entity, param);
		}
	}
}

function PopulatorThink()
{
	for (local tank = null; (tank = Entities.FindByClassname(tank, "tank_boss")) != null;) {
		tank.ValidateScriptScope();
		local scope = tank.GetScriptScope();
		if (!("created" in scope)) {
			scope.created <- true;
			local tankName = tank.GetName();
			foreach (name, table in tankNamesWildcard) {
				if (name == tankName || name == tankName.slice(0, name.len())) {
					AddHooksToScope(tankName, table, scope);

					if ("OnSpawn" in table) {
						table.OnSpawn(tank, tankName);
					}
				}
			}
			if (tankName in tankNames) {
				local table = tankNames[tankName];
				AddHooksToScope(tankName, table, scope);

				if ("OnSpawn" in table) {
					table.OnSpawn(tank, tankName);
				}
			}
		}
	}
	for (local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
	{
		local player = PlayerInstanceFromIndex(i);
		if (player == null) continue;
		if (player.IsBotOfType(1337)) {
			player.ValidateScriptScope();
			local scope = player.GetScriptScope();
			local alive = NetProps.GetPropInt(player, "m_lifeState") == 0;
			if (alive && !("botCreated" in scope)) {
				scope.botCreated <- true;
				foreach (tag, table in robotTags) {
					if (player.HasBotTag(tag)) {
						scope.popFiredDeathHook <- false;
						AddHooksToScope(tag, table, scope);
						if ("OnSpawn" in table) {
							table.OnSpawn(player, tag);
						}
					}
				}
			}
			// Make sure that ondeath hook is fired always
			if (!alive && "popFiredDeathHook" in scope) {
				local scope = player.GetScriptScope();
				if (!scope.popFiredDeathHook) {
					printl("Print death2");
					FireHooksParam(player, scope, "OnDeath", null);
				}
				delete scope.popFiredDeathHook;
			}
		}
	}
	return 0.00;
}

function OnScriptHook_OnTakeDamage(params)
{
	local victim = params.const_entity;
	if (victim != null && ((victim.IsPlayer() && victim.IsBotOfType(1337)) || victim.GetClassname() == "tank_boss")) {
		local scope = victim.GetScriptScope();
		FireHooksParam(victim, scope, "OnTakeDamage", params);
	}
	local attacker = params.attacker;
	if (attacker != null && attacker.IsPlayer() && attacker.IsBotOfType(1337)) {
		local scope = attacker.GetScriptScope();
		FireHooksParam(attacker, scope, "OnDealDamage", params);
	}
}

function OnGameEvent_player_spawn(params)
{
	printl("playerspawn "+ self.IsValid())
	local player = GetPlayerFromUserID(params.userid);

	if (player.GetScriptScope() != null && "popWearablesToDestroy" in player.GetScriptScope()) {
		foreach(i, wearable in player.GetScriptScope().popWearablesToDestroy) {
			if (wearable.IsValid()) {
				wearable.Kill();
			}
		}
		delete player.GetScriptScope().popWearablesToDestroy;
	}

	if (player != null && player.IsBotOfType(1337)) {
		player.ValidateScriptScope();
		local scope = player.GetScriptScope();

		if ("popFiredDeathHook" in scope) {
			if (!scope.popFiredDeathHook) {
				FireHooksParam(player, scope, "OnDeath", null);
			}
			delete scope.popFiredDeathHook;
		}

		// Reset hooks
		if ("botCreated" in scope) {
			delete scope.botCreated;
		}
		if ("popHooks" in scope) {
			delete scope.popHooks;
		}
	}
}

function OnGameEvent_player_hurt(params)
{
	local victim = GetPlayerFromUserID(params.userid);
	if (victim != null && victim.IsBotOfType(1337)) {
		local scope = victim.GetScriptScope();
		FireHooksParam(victim, scope, "OnTakeDamagePost", params);
	}
	local attacker = GetPlayerFromUserID(params.attacker);
	if (attacker != null && attacker.IsBotOfType(1337)) {
		local scope = attacker.GetScriptScope();
		FireHooksParam(attacker, scope, "OnDealDamagePost", params);
	}
}

function OnGameEvent_player_death(params)
{
	local player = GetPlayerFromUserID(params.userid);
	if (player != null && player.IsBotOfType(1337)) {
		local scope = player.GetScriptScope();
		scope.popFiredDeathHook <- true;
		FireHooksParam(player, scope, "OnDeath", params);
	}
	local attacker = GetPlayerFromUserID(params.attacker);
	if (attacker != null && attacker.IsBotOfType(1337)) {
		local scope = attacker.GetScriptScope();
		FireHooksParam(attacker, scope, "OnKill", params);
	}

	if (player.GetScriptScope() != null && "popWearablesToDestroy" in player.GetScriptScope()) {
		foreach(i, wearable in player.GetScriptScope().popWearablesToDestroy) {
			if (wearable.IsValid()) {
				wearable.Kill();
			}
		}
		delete player.GetScriptScope().popWearablesToDestroy;
	}
}

function OnGameEvent_npc_hurt(params)
{
	local victim = EntIndexToHScript(params.entindex);
	if (victim != null && victim.GetClassname() == "tank_boss") {
		local scope = victim.GetScriptScope();
		local dead = (victim.GetHealth() - params.damageamount) <= 0;

		FireHooksParam(victim, scope, "OnTakeDamagePost", params);
		if (dead) {
			FireHooksParam(victim, scope, "OnDeath", params);
		}
	}
}

function OnGameEvent_mvm_begin_wave(params)
{
	if ("waveIconsFunction" in this) {
		this.waveIconsFunction();
	}
}
__CollectGameEventCallbacks(this);