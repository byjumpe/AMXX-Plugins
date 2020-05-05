/** Благодарности: mx?!, w0w */

///////////////////////////////////////////// Настройка статистик ///////////////////////////////////////////////
// 0 - CSStatsX SQL by serfreeman1337
// 1 - Simple Online Logger by mx?!
// 2 - CSStats MySQL by SKAJIbnEJIb
// Default value: "0"
#define STATS 0

#if STATS == 0 || STATS == 1
	// Задержка в секундах перед проверкой игрока (не касается CSStats MySQL by SKAJIbnEJIb).
	// Default value: "3.0"
	const Float: DELAY_CHECK = 3.0;
#endif
/////////////////////////////////////////////// Настройки награды //////////////////////////////////////////////
#define TIME 0 //Если 0 - то время в TOP_TIME указывать в днях, если 1 - то в часах
#define TOP_TIME 3 // Время которое игроку необходимо отыграть, чтобы получить флаг
#define GIVE_FLAGS ADMIN_LEVEL_H // Флаг который игрок получит за онлайн
#define IGNORE_FLAGS (ADMIN_BAN | ADMIN_LEVEL_H) // Флаги при которых игрок не будет проходить проверку на время онлайна
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include <amxmodx>
#include <time>

#if TIME == 0
const NEED_TIME = TOP_TIME * SECONDS_IN_DAY;
#elseif TIME == 1
const NEED_TIME = TOP_TIME * SECONDS_IN_HOUR;
#endif

#if STATS == 0
	#include <csstatsx_sql>
#elseif STATS == 1
	native sol_get_user_time(id)
#elseif STATS == 2
	#include <csstats_mysql>
#endif

const MAX_CHAT_LENGTH = 191;

new g_iTime[MAX_PLAYERS + 1], g_iFlags[MAX_PLAYERS + 1];

public plugin_init(){
	
	register_plugin("Top Time Awards", "0.2.5", "Jumper");
	
	register_clcmd("say /tta", "TopTimeAwards");
	register_clcmd("say_team /tta", "TopTimeAwards");
	
	register_dictionary("Top_Time_Awards.txt");
	register_dictionary("time.txt");
}

public client_infochanged(id){
	
	if(!is_user_connected(id)){
	
		return;
	}

	new szOldName[MAX_NAME_LENGTH], szNewName[MAX_NAME_LENGTH];
	get_user_name(id, szOldName, charsmax(szOldName));
	get_user_info(id, "name", szNewName, charsmax(szNewName));
	
	if(strcmp(szOldName, szNewName)){
	
		func_CheckPlayer(id);
	}  
}

#if STATS == 0 || STATS == 1
public client_putinserver(id){

	set_task(DELAY_CHECK, "task_CheckPlayer", id);
}

public task_CheckPlayer(id){

	func_CheckPlayer(id);
}
#elseif STATS == 2
public csstats_putinserver(id){
	
	func_CheckPlayer(id);
}
#endif	
func_CheckPlayer(id){
	
	if(!is_user_connected(id)){
	
		return;
	}
	
	g_iFlags[id] = get_user_flags(id);
	
	if(g_iFlags[id] & IGNORE_FLAGS){
		
		return;
	}
#if STATS == 0
	g_iTime[id] = get_user_gametime(id);
#elseif STATS == 1
	g_iTime[id] = sol_get_user_time(id);
#elseif STATS == 2
	g_iTime[id] = csstats_get_user_value(id, GAMETIME);
#endif
	if(g_iTime[id] >= NEED_TIME){
		
		set_user_flags(id, g_iFlags[id] | GIVE_FLAGS);
		client_print_color(id, print_team_default, "^1[^4TTA^1] %L", id, "TTA_AWARD_ONLINE");
	}
}

public TopTimeAwards(id){

	new iTime, szTime[MAX_CHAT_LENGTH];

	iTime = NEED_TIME - g_iTime[id];
	get_time_length(id, iTime, timeunit_seconds, szTime, charsmax(szTime))
	
	if(g_iTime[id] >= NEED_TIME || g_iFlags[id] & GIVE_FLAGS){
	
		client_print_color(id, print_team_default, "^1[^4TTA^1] %L", id, "TTA_YOU_VIP");
	}
	else{
	
		client_print_color(id, print_team_default, "^1[^4TTA^1] %L", id, "TTA_NEED_TIME", szTime);
	}
}