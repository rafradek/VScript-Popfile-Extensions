for (local ent = null; (ent = Entities.FindByName(ent, "pop_extension_ent")) != null;) {
	printl("find");
	ent.Kill();
}
popExtEntity <- SpawnEntityFromTable("point_teleport", {targetname = "pop_extension_ent", vscripts="popextensions_hooks"});

popExtEntity.ValidateScriptScope();
popExtScope <- popExtEntity.GetScriptScope();

popExtScope.robotTags <- {};
popExtScope.tankNames <- {};
popExtThinkFuncSet <- false;
AddThinkToEnt(popExtEntity, null);

::PrintTable <- function (table)
{
	DoPrintTable(table, 0);
}
::DoPrintTable <- function (table, indent)
{
	local line = "";
	for(local i = 0; i < indent; i++) {
		line += " ";
	}
	line += typeof table == "array" ? "[" : "{";
	ClientPrint(null, 2, line);
	indent+=2;
	foreach (k,v in table) {
		line = "";
		for(local i = 0; i < indent; i++) {
			line += " ";
		}
		line += k.tostring();
		line += " = "
		if (typeof v == "table" || typeof v == "array") {
			ClientPrint(null, 2, line);
			DoPrintTable(v, indent);
		}
		else {
			try {
				line += v.tostring();
			}
			catch (e){
				line += typeof v;
			}
			ClientPrint(null, 2, line);
		}
	}
	indent-=2;
	line = "";
	for(local i = 0; i < indent; i++) {
		line += " ";
	}
	line += typeof table == "array" ? "]" : "}";
	ClientPrint(null, 2, line);
}

function init(initTable)
{
	if ("robotTags" in initTable && initTable.robotTags.len() > 0) {
		popExtScope.robotTags = initTable.robotTags;
	}
	if ("tankNames" in initTable && initTable.tankNames.len() > 0) {
		AddThinkToEnt(popExtEntity, "PopulatorThink");
		popExtScope.tankNames = initTable.tankNames;
	}
}

function AddRobotTag(tag, table)
{
	popExtScope.robotTags[tag] <- table;
}

function AddTankName(name, table)
{
	if (!popExtThinkFuncSet) {
		AddThinkToEnt(popExtEntity, "PopulatorThink");
		popExtThinkFuncSet = true;
	}
	popExtScope.tankNames[name] <- table;
}