#include <sdktools>
#include <FakeRank_Sync>
#include <shop>
#include <IFR>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name		= "[FRS][Shop] Shop",
	version		= "1.0",
	description	= "Fake Ranks for shop",
	author		= "ღ λŌK0ЌЭŦ ღ ™",
	url			= "https://github.com/IL0co"
}


#define IND "shop"
#define CATEGORY_NAME "FakeRanks"
#define ITEM_PREFIX "fakerank_"
int preview_enable;
int iId[MAXPLAYERS+1];

KeyValues kv;

public void OnPluginEnd()
{
	FRS_UnRegisterMe();
	Shop_UnregisterMe();
}

public void OnPluginStart()
{
	FRS_OnCoreLoaded();
	
	LoadCfg();
	LoadTranslations("shop_fakerank.phrases");
	
	if(Shop_IsStarted())
		Shop_Started();

	HookEvent("player_disconnect", Event_PlayerSpawn, EventHookMode_Pre);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	iId[client] = 0;
}

public void Shop_Started()
{
	LoadShopFunctionals();
}

public void OnMapStart()
{
	char buff[256];

	if(kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetSectionName(buff, sizeof(buff));
			FormatEx(buff, sizeof(buff), "materials/panorama/images/icons/skillgroups/skillgroup%i.svg", buff);
			if(FileExists(buff)) 
				AddFileToDownloadsTable(buff);

		}
		while(kv.GotoNextKey());
	}

	kv.Rewind();
}

public void FRS_OnCoreLoaded()
{
	FRS_RegisterKey(IND);
}

public void FRS_OnClientLoaded(int client)
{
	FRS_SetClientRankId(client, iId[client], IND);
}

stock void LoadCfg()
{
	if(kv) delete kv;
	kv = CreateKeyValues("FakeRank");
	
	char buffer[256];
	Shop_GetCfgFile(buffer, sizeof(buffer), "FakeRank.txt");
	
	if (!FileToKeyValues(kv, buffer))
		SetFailState("Couldn't parse file %s", buffer);

	preview_enable = view_as<bool>(kv.GetNum("PreviewEnable", 1));
}

stock void LoadShopFunctionals()
{
	char buffer[256], item[64];
	
	Format(item, sizeof(item), "%T", CATEGORY_NAME, 0);
	CategoryId category_id = Shop_RegisterCategory(CATEGORY_NAME, item, "", OnCategoryDisplay);

	if(kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetSectionName(item, sizeof(item));
			Format(item, sizeof(item), "%s%s", ITEM_PREFIX, item);

			if(Shop_StartItem(category_id, item))
			{
				kv.GetString("name", buffer, sizeof(buffer), item);
				Shop_SetInfo(buffer, "", kv.GetNum("price", 5000), kv.GetNum("sell_price", 2500), Item_Togglable, kv.GetNum("duration", 86400));
				
				if(preview_enable)
					Shop_SetCallbacks(_, OnEquipItem, _, _, _, OnPreviewItem);
				else 
					Shop_SetCallbacks(_, OnEquipItem);

				kv.JumpToKey("Attributes", true);
				Shop_KvCopySubKeysCustomInfo(kv);
				kv.GoBack();	

				Shop_EndItem();
			}
		}
		while(kv.GotoNextKey());
	}

	kv.Rewind();
}

public bool OnCategoryDisplay(int client, CategoryId category_id, const char[] category, const char[] name, char[] buffer, int maxlen)
{
	Format(buffer, maxlen, "%T", CATEGORY_NAME, client);
	return true;
}

public void OnPreviewItem(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item)
{
	static char buff[32];

	Format(buff, sizeof(buff), item);
	ReplaceString(buff, sizeof(buff), ITEM_PREFIX, "", false);

	if(preview_enable)
		IFR_ShowHintFakeRank(client, StringToInt(buff));
}

public ShopAction OnEquipItem(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		iId[client] = 0;
		FRS_SetClientRankId(client, 0, IND);
		return Shop_UseOff;
	}

	char buff[64];
	Format(buff, sizeof(buff), item);
	ReplaceString(buff, sizeof(buff), ITEM_PREFIX, "", false);

	int id = StringToInt(buff);

	iId[client] = id;
	FRS_SetClientRankId(client, id, IND);

	return Shop_UseOn;
}
