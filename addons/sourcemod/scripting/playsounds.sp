#pragma semicolon 1
#pragma newdecls required

#include <clientprefs>
#include <sdktools_sound>
#include <sdktools_stringtables>

#include <csgo_colors>

static const char
	PL_NAME[]	= "Playing Sounds in Radius",
	PL_VER[]	= "1.1.0";

Handle
	g_hCookie;
Menu
	mMain,
	mVolume,
	mList;
ArrayList
	g_aPath,
	g_aName;
int
	g_iVolume[MAXPLAYERS + 1];
float
	g_fTimer[MAXPLAYERS + 1];
char
	g_sTag[128];

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Воспроизведение звуков в радиусе",
	author		= "Grey83, HenryTownshand",
	url			= "https://steamcommunity.com/groups/grey83ds & https://tkofficial.ru"
}

public void OnPluginStart()
{
	CreateConVar("sm_playsounds_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_playsounds_volume", "20", "Дефолтный уровень громкости звуков (5 - 100)", _, true, 5.0, true, 100.0);
	cvar.AddChangeHook(CVarChange_Volume);
	g_iVolume[0] = cvar.IntValue;

	cvar = CreateConVar("sm_playsounds_time", "10.0", "Таймаут между воспроизведением звуков", _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Time);
	g_fTimer[0] = cvar.FloatValue;

	cvar = CreateConVar("sm_playsounds_tag", "ГC", "Тег плагина в чате", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChange_Tag);
	CVarChange_Tag(cvar, NULL_STRING, NULL_STRING);

	AutoExecConfig(true, "TK_PlaySounds");

	RegConsoleCmd("sm_playsound", Cmd_PlaySounds);
	RegConsoleCmd("sm_gs", Cmd_PlaySounds);
	RegConsoleCmd("sm_ps", Cmd_PlaySounds);

	g_hCookie = RegClientCookie("VolumePS", "Громкость", CookieAccess_Public);

	mMain = new Menu(Menu_Main);
	mMain.SetTitle("Меню Звуков\n ");
	mMain.AddItem(NULL_STRING, "Звуки");
	mMain.AddItem(NULL_STRING, "Громкость");
	mMain.ExitButton = true;

	mVolume = new Menu(Menu_Volume, MenuAction_DrawItem|MenuAction_Display);
	mVolume.SetTitle("Громкость: %i%%", g_iVolume[0]);
	mVolume.AddItem(NULL_STRING, "+5%%");
	mVolume.AddItem(NULL_STRING, "-5%%");
	mVolume.ExitBackButton = true;

	mList = new Menu(Menu_List);
	mList.ExitBackButton = true;

	g_aPath = new ArrayList(ByteCountToCells(64));
	g_aName = new ArrayList(ByteCountToCells(64));
}

public void CVarChange_Volume(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_iVolume[0] = cvar.IntValue;
}

public void CVarChange_Time(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_fTimer[0] = cvar.FloatValue;
}

public void CVarChange_Tag(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	cvar.GetString(g_sTag, sizeof(g_sTag));
	if(g_sTag[0]) Format(g_sTag, sizeof(g_sTag), "{DEFAULT}[{BLUE}%s{DEFAULT}] ", g_sTag);
}

public void OnMapStart()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/playsounds.cfg");

	KeyValues kv = new KeyValues("Sounds");
	if(kv.ImportFromFile(path))
	{
		kv.Rewind();
		if(!kv.GotoFirstSubKey(false))
		{
			LogError("<PS> Config is empty");
			CloseHandle(kv);
			return;
		}

		g_aPath.Clear();
		g_aName.Clear();
		mList.RemoveAllItems();

		int len;
		char name[64], buffer[64];
		do
		{
			if(!kv.GetSectionName(name, sizeof(name)) || !TrimString(name))
				continue;

			kv.GetString(NULL_STRING, path, sizeof(path));
			if((len = TrimString(path) - 4) < 1	// слишком короткий путь (даже расширение неправильное)
			|| strcmp(path[len], ".mp3", false) && strcmp(path[len], ".wav", false))	// не звук
				continue;

			AddToStringTable(FindStringTable("soundprecache"), path);
			FormatEx(buffer, sizeof(buffer), "sound/%s", path);
			AddFileToDownloadsTable(buffer);

			g_aPath.PushString(path);
			g_aName.PushString(name);
			FormatEx(path, sizeof(path), "%s (#%i)", name, g_aPath.Length);
			mList.AddItem(NULL_STRING, path);
		} while(kv.GotoNextKey(false));

		if(!(len = mList.ItemCount))
		{
			mList.SetTitle("Список звуков\n ");
			mList.AddItem("", "Звуки отсутствуют", ITEMDRAW_DISABLED);
		}
		else mList.SetTitle("Список звуков (%i)\n ", len);
	}
	else LogError("<PS> Unable to load config");
	CloseHandle(kv);
}

public void OnClientCookiesCached(int iClient)
{
	char szValue[4];
	GetClientCookie(iClient, g_hCookie, szValue, sizeof(szValue));

	int vol = szValue[0] ? StringToInt(szValue) : g_iVolume[0];
	if(vol < 5) vol = 5;
	if(vol > 100) vol = 100;

	g_iVolume[iClient] = vol;
}

public void OnClientDisconnect(int iClient)
{
	g_iVolume[iClient] = g_iVolume[0];
	g_fTimer[iClient] = 0.0;
}

public Action Cmd_PlaySounds(int client, int args)
{
	if(!client || !IsClientInGame(client))
		return Plugin_Handled;

	if(args < 1)
	{
		mMain.Display(client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}

	char arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	int id = StringToInt(arg);
	if(id < 0 || id >= g_aPath.Length)
	{
		CGOPrintToChat(client, "%s{RED}Неправильный Id трека: {LIGHTRED}%s", g_sTag, arg);
		mMain.Display(client, MENU_TIME_FOREVER);
	}
	else TryPlaySound(client, id);

	return Plugin_Handled;
}

public int Menu_Main(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_Select)
	{
		if(!iItem)
			mList.Display(iClient, MENU_TIME_FOREVER);
		else mVolume.Display(iClient, MENU_TIME_FOREVER);
	}

	return 0;
}

public int Menu_Volume(Menu hMenu, MenuAction action, int iClient, int item)
{
	switch(action)
	{
		case MenuAction_DrawItem:
		{
			if(!item) return g_iVolume[iClient] < 100 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
			else return g_iVolume[iClient] > 5 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
		}
		case MenuAction_Display:mVolume.SetTitle("Громкость: %i%%", g_iVolume[iClient]);
		case MenuAction_Select:
		{
			switch(item)
			{
				case 0:
				{
					g_iVolume[iClient] += 5;
					if(g_iVolume[iClient] > 100) g_iVolume[iClient] = 100;
				}
				case 1:
				{
					g_iVolume[iClient] -= 5;
					if(g_iVolume[iClient] < 5) g_iVolume[iClient] = 5;
				}
			}

			char buffer[4];
			FormatEx(buffer, sizeof(buffer), "%i", g_iVolume[iClient]);
			SetClientCookie(iClient, g_hCookie, buffer);
			mVolume.Display(iClient, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:	if(item == MenuCancel_ExitBack) mMain.Display(iClient, MENU_TIME_FOREVER);
	}

	return 0;
}

public int Menu_List(Menu hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		TryPlaySound(client, item);
		mList.DisplayAt(client, mList.Selection, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		mMain.Display(client, MENU_TIME_FOREVER);

	return 0;
}

stock void TryPlaySound(int client, int id)
{
	if(IsPlayerAlive(client))
	{
		float time = g_fTimer[client] - GetEngineTime();
		if(time <= 0.0)
		{
			char buffer[PLATFORM_MAX_PATH];
			g_aName.GetString(id, buffer, sizeof(buffer));
			CGOPrintToChat(client, "%s{GRAY}Играет: {RED}%s", g_sTag, buffer);
			g_aPath.GetString(id, buffer, sizeof(buffer));
			EmitSoundToAll(buffer, client, _, SNDLEVEL_NORMAL, _, (g_iVolume[client] / 100.0));
			g_fTimer[client] = GetEngineTime() + g_fTimer[0];
		}
		else CGOPrintToChat(client, "%sПодожди ещё%s", g_sTag, Second(time));
	}
	else CGOPrintToChat(client, "%sВы должны быть живы", g_sTag);
}

stock char Second(float val)
{
	static const char NAME[][] = {"секунду", "секунды", "секунд"};

	int form, num = RoundToCeil(val);
	switch(num)
	{
		case 0:		form = 2;
		case 1:		form = 0;
		case 2,3,4:	form = 1;
		default:
		{
			if(num < 21)	form = 2;
			else switch(num%10)
			{
				case 1:		form = 0;
				case 2,3,4:	form = 1;
				default:	form = 2;
			}
		}
	}

	char buffer[32];
	FormatEx(buffer, sizeof(buffer), " %i %s", num, NAME[form]);
	return buffer;
}