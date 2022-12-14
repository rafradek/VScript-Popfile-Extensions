ClearGameEventCallbacks();

function AddHooksToScope(name, table, scope)
{
	foreach (hookName, func in table) {
		// Entries in hook table must begin with 'On' to be considered hooks
		if (hookName[0] == 'O' && hookName[1] == 'n') {
			if (!("hooks"+hookName in scope)) {
				scope["hooks"+hookName] <- [];
			}
			scope["hooks"+hookName].append(func);
		}
	}
}
function FireHooks(entity, scope, name) {
	if (scope != null && "hooks"+name in scope) {
		foreach (index, func in scope["hooks"+name]) {
			func(entity);
		}
	}
}

function FireHooksParam(entity, scope, name, param) {
	if (scope != null && "hooks"+name in scope) {
		foreach (index, func in scope["hooks"+name]) {
			func(entity, param);
		}
	}
}

function PopulatorThink()
{
	for (local tank = null; (tank = Entities.FindByClassname(tank, "tank_boss")) != null;) {
		tank.ValidateScriptScope();
		if (!("created" in tank.GetScriptScope())) {
			tank.GetScriptScope().created <- true;
			local tankName = tank.GetName();
			foreach (name, table in tankNames) {
				if (tankName == name) {
					tank.ValidateScriptScope();
					local scope = tank.GetScriptScope();
					AddHooksToScope(name, table, scope);

					if ("OnSpawn" in table) {
						table.OnSpawn(tank, name);
					}
				}
			}
		}
	}
	return 0.01;
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
	local player = GetPlayerFromUserID(params.userid);
	if (player != null && player.IsBotOfType(1337)) {
		foreach (tag, table in robotTags) {
			if (player.HasBotTag(tag)) {
				player.ValidateScriptScope();
				local scope = player.GetScriptScope();
				AddHooksToScope(tag, table, scope);

				if ("OnSpawn" in table) {
					table.OnSpawn(player, tag);
				}
			}
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
		FireHooksParam(player, scope, "OnDeath", params);
	}
	local attacker = GetPlayerFromUserID(params.attacker);
	if (attacker != null && attacker.IsBotOfType(1337)) {
		local scope = attacker.GetScriptScope();
		FireHooksParam(attacker, scope, "OnKill", params);
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

__CollectGameEventCallbacks(this);