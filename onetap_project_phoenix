//region dependencies

//region helpers
function dictLength(dict) {
    var count = 0;
    for (_ in dict) {
        count++;
    }
    return count;
}

function is_active(value, index)
{
    var mask = 1 << index;
    return value & mask;
}


function GetObjectKeys(obj)
{
    const arr = [];
    for (var i in obj)
        if (obj.hasOwnProperty(i))
            arr.push(i);
    return arr;
}
//endregion

//endregion
var steam_id = -1
//region globals & variables
var Cheat_ = "RazvanDard , Alex23Pvp , slashxx2167 , TwisTyMEOW , TheShy112 , fraxster, adr1an";
const WeaponGroups = {
    "Global":           [ ],
    "Autosnipers":      [ "scar 20", "g3sg1" ],
    "Heavy pistols":    [ "desert eagle", "r8 revolver" ],
    "Pistols":          [ "usp s", "tec 9", "glock 18", "cz75 auto", "five seven", "p250", "p2000", "dual berettas" ],
    "AWP":              [ "awp" ],
    "Scout":            [ "ssg 08" ],
    "Rifles":           [ "galil ar", "ak 47", "m4a4", "m4a1 s", "sg 553", "famas", "aug" ],
    "SMGs":             [ "mac 10", "mp9", "mp7", "ump 45", "pp bizon", "p90" ],
    "Heavy":            [ "nova", "xm1014", "sawed off", "mag 7", "m249", "negev" ]
};

const Exceptions = [ "CKnife", "CSmokeGrenade", "CFlashbang", "CHEGrenade", "CDecoyGrenade", "CIncendiaryGrenade", "CMolotovGrenade", "CC4" ];

const DropdownValues = {
    "Hitboxes": [ "Head", "Upper chest", "Chest", "Lower chest", "Stomach", "Pelvis", "Legs", "Feet" , "Arms" ],
    "Autostops": [ "Duck", "Early", "On center only", "Lethal only", "Visible only", "In air", "Between shots", "Force accuracy" ],
    "BaimDisablers": [ "Target Resolved" , "Safepoint Headshot" , "Low Damage", "High velocity","Target shot fired","In air","Legit AA"] ,
    "SafepointDisablers": [ "Target Resolved" , "High velocity" ,"Target shot fired","Legit AA"],
    "ForceSPLimbs": [ "Target Resolved" , "Have to predict" , "High velocity" ,"Target shot fired","Legit AA"],
    "DTImprovements": ["Faster recharge","Instant DT","Adaptive Teleport"],
    "EnhanceBodyMP": [ "Target Resolved" , "Have to predict" , "High velocity" ,"Target shot fired","Legit AA","Low Damage"],
    "EnhanceHeadshotMP": ["Target Resolved" , "Legit AA" , "Low Damage", "High velocity","Target shot fired"]
};

const AdaptivePath = [ "Rage", "Project Phoenix", "Project Phoenix" ];

const RagePaths = {
    "Damage":       ["Rage", "Target", "General", "Minimum damage"],
    "Hitboxes":     ["Rage", "Target", "General", "Hitboxes"],
    "Multipoint":   ["Rage", "Target", "General", "Multipoint hitboxes"],
    "Headps":       ["Rage", "Target", "General", "Head pointscale"],
    "Bodyps":       ["Rage", "Target", "General", "Body pointscale"],

    "Hitchance":    ["Rage", "Accuracy", "General", "Hitchance"],
    "Autoscope":    ["Rage", "Accuracy", "General", "Auto scope"],
    "Autostop":     ["Rage", "Accuracy", "General", "Auto stop"],
    "Stopmode":     ["Rage", "Accuracy", "General", "Auto stop mode"],
    "Prefersafe":   ["Rage", "Accuracy", "General", "Prefer safe point"],
    "Preferbaim":   ["Rage", "Accuracy", "General", "Prefer body aim"]
};

var Font, ActiveSelectionBit, ActiveWeaponGroup, SelectedWeaponGroup, CachedWeaponGroup, disable_baim , disable_sp , enhancebody , enhanceheadshot;
//endregion

//region menu

function HandleMenu()
{
    if (!UI.IsMenuOpen( )) return;

    const WeaponKeys = GetObjectKeys(WeaponGroups);
    ActiveSelectionBit = UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "Weapon group"]);
    SelectedWeaponGroup = WeaponKeys[ActiveSelectionBit];

    for (var i in WeaponKeys)
    {
        var WeaponGroupName = WeaponKeys[i];
        var display_autoscope = WeaponGroupName != "Pistols" && WeaponGroupName != "Heavy pistols" && WeaponGroupName != "SMGs" && WeaponGroupName != "Heavy"
        
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Enabled"], i == ActiveSelectionBit ? 1 : 0);

        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Minimum damage"], i == ActiveSelectionBit ? 1 : 0);
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Minimum damage override"], i == ActiveSelectionBit ? 1 : 0);
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Hitboxes"], i == ActiveSelectionBit ? 1 : 0);
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Multipoint hitboxes"], i == ActiveSelectionBit ? 1 : 0);
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Head pointscale"], i == ActiveSelectionBit ? 1 : 0);
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Body pointscale"], i == ActiveSelectionBit ? 1 : 0);

        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Hitchance"], i == ActiveSelectionBit ? 1 : 0);
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Auto scope"], i == ActiveSelectionBit && display_autoscope ? 1 : 0);
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Auto stop"], i == ActiveSelectionBit ? 1 : 0);
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Auto stop mode"], i == ActiveSelectionBit ? 1 : 0);

        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Prefer safe point"], i == ActiveSelectionBit ? 1 : 0);
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Prefer body aim"], i == ActiveSelectionBit ? 1 : 0);
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Force safepoint on limbs"], i == ActiveSelectionBit ? 1 : 0);

        var ps = UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Prefer safe point"]);
        var pb = UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Prefer body aim"]);
        var force_sp_limbs = UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Force safepoint on limbs"]);
        
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Force safepoint on limbs disablers"], i == ActiveSelectionBit && force_sp_limbs ? 1 : 0);

        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Prefer safe point disablers"], i == ActiveSelectionBit && ps ? 1 : 0);
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Prefer body aim disablers"], i == ActiveSelectionBit && pb ? 1 : 0);

        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Enhance multipoint on limbs and body if"], i == ActiveSelectionBit ? 1 : 0);
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Limbs & Body"], i == ActiveSelectionBit ? 1 : 0);

        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Enhance multipoint on head"], i == ActiveSelectionBit ? 1 : 0);
        UI.SetEnabled([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + WeaponGroupName + "] Head"], i == ActiveSelectionBit ? 1 : 0);
    }
}

function SetupMenu()
{
    const WeaponKeys = GetObjectKeys(WeaponGroups);

    UI.AddSubTab(["Rage", "SUBTAB_MGR"], "Project Phoenix");
    UI.AddMultiDropdown(AdaptivePath, "DT Improvements", DropdownValues.DTImprovements);
    UI.AddCheckbox(AdaptivePath,        "Skeet Fakelag");
    UI.AddCheckbox(AdaptivePath,        "Improved target selection");
    //UI.AddCheckbox(AdaptivePath,        "Ragebot Logs");
    //UI.AddCheckbox(AdaptivePath,        "Zeus Warning");
    UI.AddCheckbox(AdaptivePath,        "Clantag");
    UI.AddHotkey(["Rage", "General", "Key assignment"], "Damage override key", "Damage override");
    UI.AddDropdown(AdaptivePath, "Weapon group", WeaponKeys, 1);
    

    for (var i in WeaponKeys)
    {
        var WeaponGroupName = WeaponKeys[i];

        UI.AddCheckbox(AdaptivePath,        "[" + WeaponGroupName + "] Enabled");

        UI.AddMultiDropdown(AdaptivePath,   "[" + WeaponGroupName + "] Hitboxes", DropdownValues.Hitboxes);
        UI.AddMultiDropdown(AdaptivePath,   "[" + WeaponGroupName + "] Multipoint hitboxes", DropdownValues.Hitboxes);
        UI.AddSliderInt(AdaptivePath,       "[" + WeaponGroupName + "] Head pointscale", 0, 100);
        UI.AddSliderInt(AdaptivePath,       "[" + WeaponGroupName + "] Body pointscale", 0, 100);

        UI.AddSliderInt(AdaptivePath,       "[" + WeaponGroupName + "] Hitchance", 0, 100);
        UI.AddSliderInt(AdaptivePath,       "[" + WeaponGroupName + "] Minimum damage", 0, 130);
        UI.AddSliderInt(AdaptivePath,       "[" + WeaponGroupName + "] Minimum damage override", 0, 130);
        
        UI.AddCheckbox(AdaptivePath,        "[" + WeaponGroupName + "] Auto scope");
        UI.AddCheckbox(AdaptivePath,        "[" + WeaponGroupName + "] Auto stop");
        UI.AddMultiDropdown(AdaptivePath,   "[" + WeaponGroupName + "] Auto stop mode", DropdownValues.Autostops);

        UI.AddCheckbox(AdaptivePath,        "[" + WeaponGroupName + "] Prefer safe point");
        UI.AddCheckbox(AdaptivePath,        "[" + WeaponGroupName + "] Prefer body aim");
        UI.AddCheckbox(AdaptivePath,        "[" + WeaponGroupName + "] Force safepoint on limbs");

        UI.AddMultiDropdown(AdaptivePath,   "[" + WeaponGroupName + "] Prefer safe point disablers", DropdownValues.SafepointDisablers);
        UI.AddMultiDropdown(AdaptivePath,   "[" + WeaponGroupName + "] Prefer body aim disablers", DropdownValues.BaimDisablers);
        UI.AddMultiDropdown(AdaptivePath,   "[" + WeaponGroupName + "] Force safepoint on limbs disablers", DropdownValues.ForceSPLimbs);

        UI.AddMultiDropdown(AdaptivePath,   "[" + WeaponGroupName + "] Enhance multipoint on limbs and body if", DropdownValues.EnhanceBodyMP);
        UI.AddSliderInt(AdaptivePath,       "[" + WeaponGroupName + "] Limbs & Body", 0, 100);
        UI.AddMultiDropdown(AdaptivePath,   "[" + WeaponGroupName + "] Enhance multipoint on head", DropdownValues.EnhanceHeadshotMP);
        UI.AddSliderInt(AdaptivePath,       "[" + WeaponGroupName + "] Head", 0, 100);
    }
}

//endregion

//region main

function GetWeaponGroup(wpn)
{
    if (wpn == null) 
        return "Global";

    for (var i in WeaponGroups)
        for (var j in WeaponGroups[i])
            if (WeaponGroups[i][j] == wpn)
                return i;
    
    return "Global";
}

function SafepointHitboxes(hb)
{
    for (var i in hb)
        Ragebot.ForceHitboxSafety(hb[i]);
}

function SetConfig()
{
    if (UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Enabled"]) == 0)
        ActiveWeaponGroup = "Global";

    UI.SetValue(RagePaths.Hitboxes, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Hitboxes"]));
    UI.SetValue(RagePaths.Multipoint, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Multipoint hitboxes"]));

    if(!enhanceheadshot)
        UI.SetValue(RagePaths.Headps, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Head pointscale"]));
    else 
        UI.SetValue(RagePaths.Headps, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Head"]));

    if(!enhancebody)
        UI.SetValue(RagePaths.Bodyps, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Body pointscale"]));
    else 
        UI.SetValue(RagePaths.Bodyps, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Limbs & Body"]));


    UI.SetValue(RagePaths.Hitchance, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Hitchance"]));
    
    if (UI.GetValue(["Rage", "General", "Key assignment", "Damage override key"]) == 1)
        UI.SetValue(RagePaths.Damage, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Minimum damage override"]));
    else
        UI.SetValue(RagePaths.Damage, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Minimum damage"]));


    UI.SetValue(RagePaths.Autoscope, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Auto scope"]));
    UI.SetValue(RagePaths.Autostop, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Auto stop"]));
    UI.SetValue(RagePaths.Stopmode, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Auto stop mode"]));

    UI.SetValue(RagePaths.Prefersafe, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Prefer safe point"]) && !disable_sp ? 1 : 0 );
    UI.SetValue(RagePaths.Preferbaim, UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Prefer body aim"]) && !disable_baim ? 1 : 0 );
}
//endregion

//region init
function CommandHandler()
{
    const Me = Entity.GetLocalPlayer();

    if (!Entity.IsValid(Me) || !Entity.IsAlive(Me))
        return;

    const wpn = Entity.GetWeapon(Me);

    for (var i in Exceptions)
        if (Entity.GetClassName(wpn) == Exceptions[i])
            return;

    ActiveWeaponGroup = GetWeaponGroup(Entity.GetName(wpn));

    // if (ActiveWeaponGroup != CachedWeaponGroup)
    // {
        SetConfig();
        //CachedWeaponGroup = ActiveWeaponGroup;
    //}
}

function Initialize()
{
    SetupMenu();
    UI.SetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[Global] Enabled"], 1);

    Cheat.RegisterCallback("Draw", "HandleMenu");
    Cheat.RegisterCallback("CreateMove", "CommandHandler");
}

Initialize();
//endregion
//endregion
function is_in_air(ent)
{
  return Entity.GetProp( ent, "CBasePlayer", "m_hGroundEntity");
}

var targets_resolved = {};
for(var i = 0; i <= 64;i++) 
    targets_resolved[i] = false;

var shots_fired = {};
var used_sp = true;
for(var i = 0; i <= 64;i++) 
    shots_fired[i] = 0;

var choked_cmd = 0;
function on_weapon_fire()
{
    var target = Entity.GetEntityFromUserID(Event.GetInt("userid"));
    shots_fired[target] = Globals.Tickcount();

    if(target == Entity.GetLocalPlayer())
        choked_cmd = 0;
}

function aimbot_fire()
{
    used_sp = Event.GetInt("safepoint");
}

function on_player_hurt()
{
    var attacker = Entity.GetEntityFromUserID(Event.GetInt("attacker"));
    var target = Entity.GetEntityFromUserID(Event.GetInt("userid"));
    if (attacker != Entity.GetLocalPlayer() || attacker == target) return;


    var hitbox = Event.GetInt('hitgroup');
    if(hitbox == 1 && !used_sp)
        targets_resolved[target] = true;
}
function local_has_to_predict()
{
    var enemies = Entity.GetEnemies();
    var local = Entity.GetLocalPlayer( );

    if(!Entity.IsAlive(local)) return false;

    var local_pos = Entity.GetEyePosition(local) 
    var local_hp = Entity.GetProp( local, "CBasePlayer", "m_iHealth" );
    var extrapolated_local = extrapolate(local,18,local_pos[0],local_pos[1],local_pos[2])
    for(var i = 0; i < enemies.length;i++)
    {
        var enemy = enemies[i];
        if(!Entity.IsAlive(enemy) || Entity.IsDormant(enemy)) continue;

        var enemy_pos = Entity.GetHitboxPosition(enemy,3);
        var extrapolated_enemy = extrapolate(enemy,10,enemy_pos[0],enemy_pos[1],enemy_pos[2])
        var before_data = Trace.RawLine(local,local_pos,enemy_pos,0x4600400b,0);
        var data = Trace.RawLine(local,local_pos,extrapolated_enemy,0x4600400b,0);


        if(data[1] > 0.9 && before_data[0] != enemy)
        {
            var enemy_eye = Entity.GetEyePosition(enemy);
            var extrapolated_enemy = extrapolate(enemy,10,enemy_eye[0],enemy_eye[1],enemy_eye[2])

            var bullet_data = Trace.Bullet(enemy, local , extrapolated_enemy , Entity.GetHitboxPosition(local,3));
            if(bullet_data[1] >= local_hp) // damage
                return true;
        }
        
        
    }
    return false;
    // deci daca stau pe loc si 
}
function create_move()
{
    var local = Entity.GetLocalPlayer();
    var target = Ragebot.GetTarget();

    disable_sp = false;
    disable_baim = false;
    enhanceheadshot = false;
    enhancebody = false;

    if(!Entity.IsValid(local) || !Entity.IsValid(target) || !Entity.IsAlive(local) || !Entity.IsAlive(target)) return;
    
    var weapon = Entity.GetName(Entity.GetWeapon(local))

    sp_limbs = true;

    var in_air = is_in_air(target);
    var target_shot_fired = Globals.Tickcount() - shots_fired[target] < 15;
    var sp_hs = false; // need functions we do later np

    var dif = Math.abs(local_yaw - yaw);
    if(dif >= 360)
        dif = dif - 360;
    if(dif >= 45 && dif <= 135 || dif >= 225 && dif <= 315 )
        sp_hs = true;
    else
    {
        if(speed > 150)
            sp_hs = true;
    }

    var resolved = targets_resolved[target];
    var velocity = Entity.GetProp( target, "CBasePlayer", "m_vecVelocity[0]" );
    var speed = Math.sqrt(velocity[0] * velocity[0] + velocity[1] * velocity[1] + velocity[2] * velocity[2]);

    var pitch = Entity.GetProp( target, "CCSPlayer", "m_angEyeAngles[0]")[0];
    var yaw = Entity.GetProp( target, "CCSPlayer", "m_angEyeAngles[1]")[0];
    var local_yaw = Local.GetRealYaw();

    var legit_aa = pitch < 20 && !target_shot_fired;

    var body_damage = Trace.Bullet(local, target , Entity.GetEyePosition(local) , Entity.GetHitboxPosition( target, 2 ));
    var need_predict = local_has_to_predict();

    var multi_sp = UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Prefer safe point disablers"])
    var multi_baim = UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Prefer body aim disablers"])
    var multi_limbs_sp =  UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Force safepoint on limbs disablers"])
    var multi_enhancebody = UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Enhance multipoint on limbs and body if"])
    var multi_enhanceheadshot = UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Enhance multipoint on head"])

    if(is_active(multi_baim , 0) && resolved)
        disable_baim = true;
    else if(is_active(multi_baim ,1) && sp_hs)
        disable_baim = true;
    else if (is_active(multi_baim ,2) && body_damage <= 15)
        disable_baim = true;
    else if(is_active(multi_baim ,3) && speed >= 170)
        disable_baim = true;
    else if(is_active(multi_baim ,4) && target_shot_fired)
        disable_baim = true;
    else if(is_active(multi_baim ,5) && in_air)
        disable_baim = true;
    else if(is_active(multi_baim ,6) && legit_aa)
        disable_baim = true;


    if(is_active(multi_sp , 0) && resolved)
        disable_sp = true;
    else if(is_active(multi_sp ,1) && speed >= 170)
        disable_sp = true;
    else if(is_active(multi_sp ,2) && target_shot_fired)
        disable_sp = true;
    else if(is_active(multi_sp ,3) && legit_aa)
        disable_sp = true;
    
      //  "ForceSPLimbs": [ "Target Resolved" , "Have to predict" , "High velocity" ,"Target shot fired","Legit AA"],

    if(is_active(multi_limbs_sp,0) && resolved )
        sp_limbs = false;
    else if(is_active(multi_limbs_sp,1) && need_predict)
        sp_limbs = false;
    else if(is_active(multi_limbs_sp,2) && speed >= 170)
        sp_limbs = false;
    else if(is_active(multi_limbs_sp,3) && target_shot_fired)
        sp_limbs = false;
    else if(is_active(multi_limbs_sp,4) && legit_aa)
        sp_limbs = false;

    if(sp_limbs && UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "[" + ActiveWeaponGroup + "] Force safepoint on limbs"]))
        SafepointHitboxes([7, 8, 9, 10, 11, 12]);

    
   // "EnhanceBodyMP": [ "Target Resolved" , "Have to predict" , "High velocity" ,"Target shot fired","Legit AA","Low Damage"],
   // "EnhanceHeadshotMP": ["Target Resolved" , "Legit AA" , "Low Damage", "High velocity","Target shot fired"]

    if(is_active(multi_enhancebody,0) && resolved)
        enhancebody = true;
    else if(is_active(multi_enhancebody,1) && need_predict)
        enhancebody = true;
    else if(is_active(multi_enhancebody,2) && speed >= 170)
        enhancebody = true;
    else if(is_active(multi_enhancebody,3) && target_shot_fired)
        enhancebody = true;
    else if(is_active(multi_enhancebody,4) && legit_aa)
        enhancebody = true;
    else if(is_active(multi_enhancebody,5) && body_damage <= 15)
        enhancebody = true;

    
    if(is_active(multi_enhanceheadshot,0) && resolved)
        enhanceheadshot = true;
    else if(is_active(multi_enhanceheadshot,1) && legit_aa)
        enhanceheadshot = true;
    else if(is_active(multi_enhanceheadshot,2) && body_damage <= 15)
        enhanceheadshot = true;
    else if(is_active(multi_enhanceheadshot,3) && speed >= 170)
        enhanceheadshot = true;
    else if(is_active(multi_enhanceheadshot,4) && target_shot_fired)
        enhanceheadshot = true;

    
    
    SetConfig();
    
}

function can_shift_shot(ticks_to_shift) {
    var me = Entity.GetLocalPlayer();
    var wpn = Entity.GetWeapon(me);

    if (me == null || wpn == null)
        return false;

    var tickbase = Entity.GetProp(me, "CCSPlayer", "m_nTickBase");
    var curtime = Globals.TickInterval() * (tickbase-ticks_to_shift)

    if (curtime < Entity.GetProp(me, "CCSPlayer", "m_flNextAttack"))
        return false;

    if (curtime < Entity.GetProp(wpn, "CBaseCombatWeapon", "m_flNextPrimaryAttack"))
        return false;

    return true;
}
function extrapolate(ent , ticks,x,y,z)
{
  var velocity = Entity.GetProp( ent, "CBasePlayer", "m_vecVelocity[0]" );

  var new_pos = [x,y,z];
  new_pos[0] = new_pos[0] + velocity[0] * ticks * Globals.TickInterval();
  new_pos[1] = new_pos[1] + velocity[1] * ticks * Globals.TickInterval();
  new_pos[2] = new_pos[2] + velocity[2] * ticks * Globals.TickInterval();
	return new_pos;
}

function distance_3d(x,y)
{
    return Math.sqrt((x[0] - y[0]) * (x[0] - y[0]) + (x[1] - y[1]) * (x[1] - y[1]) + (x[2] - y[2]) * (x[2] - y[2]));
}
function is_visible(enemy)
{
    var local = Entity.GetLocalPlayer();
    var local_eye = Entity.GetEyePosition(local)
    for(var i = 0; i <= 8;i++)
    {
        var ray = Trace.Line(local,local_eye,Entity.GetHitboxPosition(enemy,i))
        if(ray)
            if(ray[0] == enemy)
                return true;
    }
    return false;
}
function on_peek(enemy)
{
    var local = Entity.GetLocalPlayer();
    var local_eye = Entity.GetEyePosition(local)

    var ticks = 14 - choked_cmd;
    var extrapolated_eye = extrapolate(local,ticks,local_eye[0],local_eye[1],local_eye[2]);
    
    
    if(distance_3d(local_eye,extrapolated_eye) < 10 || is_visible(enemy)) return false;

    var enemy_pos = Entity.GetHitboxPosition(enemy,4);
    var bullet = Trace.Bullet(local,enemy,extrapolated_eye , enemy_pos)
    var state = bullet[1] > 0  
    var send_tick = false 

    if(!state)
    {
        ticks = 14;
        extrapolated_eye = extrapolate(local,ticks,local_eye[0],local_eye[1],local_eye[2]);

        bullet = Trace.Bullet(local,enemy,extrapolated_eye , enemy_pos);
        state = bullet[1] > 0 ;

        send_tick = state 
    }
    return {state,send_tick};

}
var max_choke = 14;
var c = 0;
function fakelag()
{
    var skeet_fakelag = UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "Skeet Fakelag"])
    if(!skeet_fakelag)
        return; 

    var local = Entity.GetLocalPlayer();
    if(!Entity.IsValid(local) || !Entity.IsAlive(local)) return;

    if(choked_cmd >= max_choke)
    {
        c = c + 1
        UserCMD.Send();
        choked_cmd = 0;
    }
    else 
    {
        UserCMD.Choke();
        choked_cmd += 1;
    }

    var player_list = Entity.GetEnemies();
    for(var i = 0; i < player_list.length;i++)
    {
      var enemy = player_list[i]
      if(!Entity.IsValid(enemy) || !Entity.IsAlive(enemy) || Entity.IsDormant(enemy)) continue;
      var peek_data = on_peek(enemy);
      var state = peek_data[0]
      var send_tick = peek_data[1];
      if (state && send_tick)
      {
        UserCMD.Send();
        choked_cmd = 0;
        max_choke = 14
        c = 0
        return;
      }
      else if (state && !send_tick)
      {
        max_choke = 14
        c = 0
        return;
      }
      
    }
    if (c >= 10) 
        max_choke = Math.floor(Math.random() * 14) + 9;

}
function will_get_hit()
{
    var enemies = Entity.GetEnemies();
    var local = Entity.GetLocalPlayer( );

    if(!Entity.IsAlive(local)) return;
    var local_pos = Entity.GetHitboxPosition(local,3);
    var extrapolated_local = extrapolate(local,18,local_pos[0],local_pos[1],local_pos[2])
    for(var i = 0; i < enemies.length;i++)
    {
        var enemy = enemies[i];
        if(!Entity.IsAlive(enemy) || Entity.IsDormant(enemy)) continue;
        var enemy_eye_pos = Entity.GetEyePosition(enemy)
       
        var data = Trace.RawLine(enemy,enemy_eye_pos,extrapolated_local,0x4600400b,0);
        if(data)
        {
            var frac = data[1];
            if(frac > 0.9)
                return true;
        }
        
    }
    return false;
}
function improved_dt() {

    var hit = will_get_hit();
    var is_charged = Exploit.GetCharge()
    var enemy = Ragebot.GetTarget();
    var ok = !Entity.IsValid(enemy) || !Entity.IsAlive(enemy);
    
    var multi_dt = UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "DT Improvements"])
    if(is_active(multi_dt,0))
    {
        Exploit[(is_charged != 1 ? "Enable" : "Disable") + "Recharge"]()

        if (can_shift_shot(17) && is_charged != 1 && !hit && ok) {
            Exploit.DisableRecharge();
            Exploit.Recharge()
        }

    }
    else 
        Exploit.EnableRecharge();

    if(is_active(multi_dt,1))
    {
        
        Exploit.OverrideTolerance(0);
        Exploit.OverrideShift(18);
    }
    else 
    {
        Exploit.OverrideTolerance(2);
        Exploit.OverrideShift(12);
    }
}


function on_unload()
{
    Exploit.EnableRecharge();
}
var last_update = 0;
var clan_tags = ["ph","phoe","phoenix","ph03nix" , "phoenix" , "phoe" , "ph" , "" , ""];
var clantag_index = 0;
function clantag()
{
    if(!UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "Clantag"]))
    {
        if(last_update != 0)
        {
            last_update = 0;
            Local.SetClanTag("");
        }
        return;
    } 

    var time_passed = Globals.Curtime() - last_update;
    var delay = 0.45;
    if(time_passed > delay)
    {
        Local.SetClanTag(String(clan_tags[clantag_index]));
        clantag_index += 1;
        last_update = Globals.Curtime();
        if(clantag_index >= clan_tags.length)
            clantag_index = 0;
    }
   
}

function ragebot_priority()
{
    if(!UI.GetValue([AdaptivePath[0], AdaptivePath[1], AdaptivePath[2], "Improved target selection"])) return;

    var enemies = Ragebot.GetTargets();
    var in_air_targets = 0;
    var local = Entity.GetLocalPlayer()

    if(enemies.length < 2 || !Entity.IsAlive(local))
        return;

    for(var i = 0; i < enemies.length;i++) // if there's only 1 enemy we can hit then it's useless to find a better target
    {
        var enemy = enemies[i];
        var flags = Entity.GetProp(enemy,"CBasePlayer" ,"m_fFlags");

        if(!(flags & 1) && in_air(enemy)) // aka in air
        {
            in_air_targets += 1;
        } 
    }
   
    if(in_air_targets != enemies.length)
    {
        for(var i = 0; i < enemies.length;i++)
        {
            var enemy = enemies[i];
            var flags = Entity.GetProp(enemy,"CBasePlayer" ,"m_fFlags");

            if(!(flags & 1) && in_air(enemy)) // aka in air
            {
                Ragebot.IgnoreTarget(enemy);
            } 
        }
    }
}

function ragebot_mindmg()
{
    var enemies = Entity.GetEnemies();
    var local = Entity.GetLocalPlayer( );

    if(!Entity.IsAlive(local)) return;

    var local_pos = Entity.GetEyePosition(local);
    var extrapolated_local = extrapolate(local,8,local_pos[0],local_pos[1],local_pos[2])

    for(var i = 0; i < enemies.length;i++)
    {
        var enemy = enemies[i];
        if(!Entity.IsAlive(enemy) || Entity.IsDormant(enemy)) continue;
        
        var enemy_pos = Entity.GetHitboxPosition(enemy,3);
        var hp = Entity.GetProp( enemy, "CBasePlayer", "m_iHealth" );
        var bullet_data = Trace.Bullet(local, enemy , extrapolated_local , enemy_pos);

        if(bullet_data[1] >= hp)
            Ragebot.ForceTargetMinimumDamage(enemy, hp + 5);
    }
    return false;
}
if(!(Cheat.RegisterCallback("weapon_fire","on_weapon_fire") != steam_id))
Cheat.ExecuteCommand( "quit" );
if(!(Cheat.RegisterCallback("CreateMove", "create_move") != steam_id))
Cheat.ExecuteCommand( "quit" );
if(!(Cheat.RegisterCallback("CreateMove","fakelag") != steam_id))
Cheat.ExecuteCommand( "quit" );
if(!(Cheat.RegisterCallback("CreateMove","ragebot_mindmg") != steam_id))
Cheat.ExecuteCommand( "quit" );
if(!(Cheat_.search(Cheat.GetUsername()) != steam_id))
Cheat.ExecuteCommand( "quit" );
if(!(Cheat.RegisterCallback("CreateMove","improved_dt") != steam_id))
Cheat.ExecuteCommand( "quit" );
if(!(Cheat.RegisterCallback("Unload", "on_unload") != steam_id))
Cheat.ExecuteCommand( "quit" );
if(!(Cheat.RegisterCallback("player_hurt", "on_player_hurt") != steam_id))
Cheat.ExecuteCommand( "quit" );
if(!(Cheat.RegisterCallback("ragebot_fire", "aimbot_fire") != steam_id))
Cheat.ExecuteCommand( "quit" );
if(!(Cheat.RegisterCallback("Draw","clantag") != steam_id))
Cheat.ExecuteCommand( "quit" );



   
