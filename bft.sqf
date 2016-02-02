CODI_BFT_fnc_dist = {
	private["_p1","_p2","_control"];
	_p1 = _this select 0;
	_p2 = _this select 1;
	_control = (findDisplay 12) displayCtrl 51;
	_p1 = _control ctrlMapWorldToScreen _p1;
	_p2 = _control ctrlMapWorldToScreen _p2;
	sqrt(((_p2 select 0) - (_p1 select 0))^2 + ((_p2 select 1) - (_p1 select 1))^2)
};
CODI_BFT_fnc_clean = {
	private["_toBeRemoved","_ownSide"];
	_toBeRemoved = [];
	{
		if (!alive _x) then
		{
			_toBeRemoved pushBack _x;
		};
	}
	forEach CODI_BFT_units;
	CODI_BFT_units = CODI_BFT_units - _toBeRemoved;
	_ownSide = CODI_BFT_side;
	{
		if (side _x == _ownSide) then
		{
			if (!(_x in CODI_BFT_units)) then
			{
				if ([player] call CODI_BFT_fnc_canTrack) then
				{
					if ([_x] call CODI_BFT_fnc_canBeTracked) then
					{
						CODI_BFT_units pushBack _x;
					};
				};
			};
		};
	}
	forEach allUnits;
};
CODI_BFT_fnc_update = {
	private["_maxRange","_marker2","_shipFound","_spzFound","_artyFound","_groupNames","_ownSide","_p","_groupSize","_groupSizeMarkerType","_control","_marker","_groupName","_hasGroupLeader","_markerType","_allInfantry","_planeFound","_helicopterFound","_uavFound","_carFound","_tankFound","_groupPosition","_ownUnits","_groups","_doneSomething","_unit","_unitPos","_nearestGroupIndex","_nearestGroupDistance","_group","_distance","_groupingFactor","_groupMembers","_groupPositionX","_groupPositionY"];
	disableSerialization;
	{
		deleteMarkerLocal _x;
	}
	forEach CODI_BFT_markers;
	CODI_BFT_markers = [];
	_ownSide = CODI_BFT_side;
	_ownUnits = [];
	if (visibleGPS && !visibleMap) then
	{
		{
			_maxRange = (speed(player)*100)/20;
			if (_maxRange < 100) then
			{
				_maxRange = 100;
			};
			if (_maxRange > 1000) then
			{
				_maxRange = 1000;
			};
			if ((getPos _x) distance (getPos player) <= _maxRange) then
			{
				_ownUnits pushBack _x;
			};
		}
		forEach CODI_BFT_units;
	}
	else
	{
		_control = (findDisplay 12) displayCtrl 51;
		{
			_p = _control ctrlMapWorldToScreen (getPos _x);
			if ((_p select 0) >= safezoneX && (_p select 0) <= (safezoneX+safezoneW) && (_p select 1) >= safezoneY && (_p select 1) <= (safezoneY+safezoneH)) then
			{
				_ownUnits pushBack _x;
			};
		}
		forEach CODI_BFT_units;
	};
	_groups = [];
	if (count _ownUnits == 0) exitWith{};
	_groups pushBack [getPos (_ownUnits select 0), [(_ownUnits select 0)]];
	_ownUnits deleteAt 0;
	while {count _ownUnits > 0} do
	{
		{
			_unit = _x;
			_unitPos = getPos _unit;
			_nearestGroupIndex = -1;
			_nearestGroupDistance = 999999;
			{
				_group = _x;
				_distance = 0;
				if (visibleGPS && !visibleMap) then
				{
					_distance = _unitPos distance2D (_group select 0);
				}
				else
				{
					_distance = [_unitPos, _group select 0] call CODI_BFT_fnc_dist;
				};
				if (_distance < _nearestGroupDistance) then
				{
					_nearestGroupDistance = _distance;
					_nearestGroupIndex = _forEachIndex;
				};
			}
			forEach _groups;
			_groupingFactor = 0.05;
			if (visibleGPS && !visibleMap) then
			{
				_groupingFactor = 25;
			};
			if (_nearestGroupDistance < _groupingFactor) then
			{
				_group = _groups select _nearestGroupIndex;
				_groupMembers = _group select 1;
				_groupMembers pushBack _unit;
				_groupPositionX = 0;
				_groupPositionY = 0;
				{
					_p = getPos _x;
					_groupPositionX = _groupPositionX + (_p select 0);
					_groupPositionY = _groupPositionY + (_p select 1);
				}
				forEach _groupMembers;
				_groupMembersCount = count _groupMembers;
				_groupPositionX = _groupPositionX / _groupMembersCount;
				_groupPositionY = _groupPositionY / _groupMembersCount;
				_group = [[_groupPositionX,_groupPositionY], _groupMembers];
				_groups set [_nearestGroupIndex, _group];
				_ownUnits deleteAt _forEachIndex;
			}
			else
			{			
				_groups pushBack [_unitPos, [_unit]];
				_ownUnits deleteAt _forEachIndex;
			};
		}
		forEach _ownUnits;
	};
	{
		_groupPosition = _x select 0;
		_groupMembers = _x select 1;
		_tankFound = false;
		_carFound = false;
		_uavFound = false;
		_helicopterFound = false;
		_planeFound = false;
		_allInfantry = true;
		_artyFound = false;
		_spzFound = false;
		{
			if (!(typeOf(vehicle _x) isKindOf "Man")) then
			{
				_allInfantry = false;
			};
		}
		forEach _groupMembers;
		if (!_allInfantry) then
		{
			{
				if (typeOf(vehicle _x) isKindOf "Helicopter") then
				{
					_helicopterFound = true;
				};
				if (typeOf(vehicle _x) isKindOf "Plane") then
				{
					if (typeOf(vehicle _x) isKindOf "UAV") then
					{
						_uavFound = true;
					}
					else
					{
						_planeFound = true;
					};
				};
				if (typeOf(vehicle _x) isKindOf "Tank") then
				{
					if (getNumber (configFile >> "CfgVehicles" >> typeOf(vehicle _x) >> "transportSoldier") > 0) then
					{
						_spzFound = true;
					}
					else
					{
						if (getNumber (configFile >> "CfgVehicles" >> typeOf(vehicle _x) >> "artilleryScanner") == 1) then
						{
							_artyFound = true;
						}
						else
						{
							_tankFound = true;
						};
					};
				};
				if (typeOf(vehicle _x) isKindOf "Car") then
				{
					_carFound = true;
				};
				if (_vehicle isKindOf "Ship") then
				{
					_shipFound = true;
				};
			}
			forEach _groupMembers;
		};
		_markerType = "_inf";
		if (!_allInfantry) then
		{
			if (_planeFound) then
			{
				_markerType = "_plane";
			}
			else
			{
				if (_uavFound) then
				{
					_markerType = "_uav";
				}
				else
				{
					if (_helicopterFound) then
					{
						_markerType = "_air";
					}
					else
					{
						if (_tankFound) then
						{
							_markerType = "_armor";
						}
						else
						{
							if (_artyFound) then
							{
								_markerType = "_art";
							}
							else
							{
								if (_spzFound) then
								{
									_markerType = "_mech_inf";
								}
								else
								{
									if (_carFound) then
									{
										_markerType = "_motor_inf";
									}
									else
									{
										if (_shipFound) then
										{
											_markerType = "_naval";
										};
									};
								};
							};
						};
					};
				};
			};
		};
		switch (_ownSide) do
		{
			case blufor:
			{
					_markerType = "b" + _markerType;
			};
			case opfor:
			{
					_markerType = "o" + _markerType;
			};
			case independent:
			{
					_markerType = "i" + _markerType;
			};
		};
		_hasGroupLeader = false;
		_groupNames = [];
		{
			if (leader _x == _x) then
			{
					_hasGroupLeader = true;
					_groupNames pushBack groupId(group _x);
			};
		}
		forEach _groupMembers;
		_marker = createMarkerLocal[format["CODI_BFT_group_%1", _forEachIndex], _groupPosition];
		_marker setMarkerTypeLocal _markerType;
		_marker setMarkerAlphaLocal 1;
		_marker setMarkerColorLocal format["Color%1", _ownSide];
		if (!_hasGroupLeader) then
		{
			_marker setMarkerSizeLocal [0.5, 0.5];
		}
		else
		{
			_groupName = "";
			{
				if (_forEachIndex > 0) then
				{
					_groupName = _groupName + "|";
				};
				_groupName = _groupName + _x;
			}
			forEach _groupNames;
			_marker setMarkerTextLocal _groupName;
		};
		CODI_BFT_markers pushBack _marker;
	
		if (visibleGPS && !visibleMap) then
		{
	
		}
		else
		{
			_marker2 = createMarkerLocal[format["CODI_BFT_groupSize_%1", _forEachIndex], _groupPosition];
			_marker2 setMarkerAlphaLocal 1;
			if (!_hasGroupLeader) then
			{
					_marker2 setMarkerSizeLocal [0.75, 0.75];
			}
			else
			{
					_marker2 setMarkerSizeLocal [1.5, 1.5];
			};
			_control = (findDisplay 12) displayCtrl 51;
			if (!_hasGroupLeader) then
			{
					_marker setMarkerSizeLocal [0.5, 0.5];
			};
			_groupSize = count _groupMembers;
			_groupSizeMarkerType = "group_0";
			if (_groupSize > 2 && _groupSize <= 6) then
			{
					_groupSizeMarkerType = "group_1";
			};
			if (_groupSize > 6 && _groupSize <= 12) then
			{
					_groupSizeMarkerType = "group_2";
			};
			if (_groupSize > 12 && _groupSize <= 24) then
			{
					_groupSizeMarkerType = "group_3";
			};
			if (_groupSize > 24 && _groupSize <= 48) then
			{
					_groupSizeMarkerType = "group_4";
			};
			if (_groupSize > 48 && _groupSize <= 96) then
			{
					_groupSizeMarkerType = "group_5";
			};
			if (_groupSize > 96) then
			{
					_groupSizeMarkerType = "group_6";
			};
			_marker2 setMarkerTypeLocal _groupSizeMarkerType;
			CODI_BFT_markers pushBack _marker2;
		};
	}
	forEach _groups;
};
CODI_BFT_fnc_updateGPS = {
	private["_time"];
	_time = time;
	if (_time >= CODI_BFT_time + 1) then
	{
		CODI_BFT_time = _time;
		call CODI_BFT_fnc_update;
	};
};
CODI_BFT_units = [];
CODI_BFT_markers = [];
CODI_BFT_time = time;
CODI_BFT_side = side player;
[] spawn {
	waitUntil{!isNull player};
	while {true} do
	{
		{
			deleteMarkerLocal _x;
		}
		forEach CODI_BFT_markers;
		CODI_BFT_markers = [];
		waitUntil{([player] call CODI_BFT_fnc_canTrack) && visibleMap};
		["CODI_BFT_onEachFrame", "onEachFrame", {[] call CODI_BFT_fnc_update;}] call BIS_fnc_addStackedEventHandler;
		waitUntil{!visibleMap};
		["CODI_BFT_onEachFrame", "onEachFrame"] call BIS_fnc_removeStackedEventHandler;
	};
};
[] spawn {
	waitUntil{!isNull player};
	while {true} do
	{
		{
			deleteMarkerLocal _x;
		}
		forEach CODI_BFT_markers;
		CODI_BFT_markers = [];
		waitUntil{([player] call CODI_BFT_fnc_canTrack) && visibleGPS && !visibleMap};
		["CODI_BFT_onEachFrameGPS", "onEachFrame", {[] call CODI_BFT_fnc_updateGPS;}] call BIS_fnc_addStackedEventHandler;
		waitUntil{!visibleGPS && !visibleMap};
		["CODI_BFT_onEachFrameGPS", "onEachFrame"] call BIS_fnc_removeStackedEventHandler;
	};
};
[] spawn {
	while {true} do
	{
		call CODI_BFT_fnc_clean;
		sleep 10;
	};
};
CODI_BFT_fnc_canTrack = {
	private["_unit","_ret"];
	_unit = _this select 0;
	_ret = true;
	if (isClass (configFile >> "CfgPatches" >> "CODI_BFT_ACE")) then
	{
		_ret = [_unit, "CODI_BFT_Tablet"] call ace_common_fnc_hasItem;
	};
	_ret
};
CODI_BFT_fnc_canBeTracked = {
	private["_unit","_ret"];
	_unit = _this select 0;
	_ret = true;
	if (isClass (configFile >> "CfgPatches" >> "CODI_BFT_ACE")) then
	{
		_ret = [_unit, "CODI_BFT_Tablet"] call ace_common_fnc_hasItem;
	};
	if ((typeOf _unit) == "B_UAV_AI") then
	{
		_ret = true;
	};
	_ret
};