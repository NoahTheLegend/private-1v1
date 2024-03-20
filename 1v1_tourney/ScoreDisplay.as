#include "Logging.as";
#include "RulesCore.as";

const SColor TEAM0COLOR(255,25,94,157);
const SColor TEAM1COLOR(255,192,36,36);
const u8 FONT_SIZE = 30;

int GetScore(CRules@ this, int team) {
    string prop = "team" + team + "score";
    if (this.exists(prop)) {
        return this.get_u8(prop);
    }
    else {
        log("GetScore", "No score found for team " + team);
        return 0;
    }
}

// Only called by server
void SetScore(CRules@ this, int team0Score, int team1Score) {
    log("SetScore", "Score is " + team0Score + ", " + team1Score);
    this.set_u8("team0score", team0Score);
    this.set_u8("team1score", team1Score);

    // Sync scores
    CBitStream params;
    params.write_u8(team0Score);
    params.write_u8(team1Score);
    this.SendCommand(this.getCommandID("CMD_SET_SCORE"), params, true);
    //this.Sync("team0score", true);
    //this.Sync("team1score", true);
}

void ToggleScore(CRules@ this) {
    this.set_bool("show score", !this.get_bool("show score"));
    this.Sync("show score", true);
}

void onInit(CRules@ this) {
    if (!GUI::isFontLoaded("big score font")) {
        GUI::LoadFont("big score font",
                      "GUI/Fonts/AveriaSerif-Bold.ttf", 
                      FONT_SIZE,
                      true);
    }
    this.set_bool("show score", true);
    this.addCommandID("CMD_SET_SCORE");

    if (isServer()) {
        SetScore(this, 0, 0);
    }
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player) {
    this.SyncToPlayer("show score", player);
    this.SyncToPlayer("team0score", player);
    this.SyncToPlayer("team1score", player);
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params) {
    if (cmd == this.getCommandID("CMD_SET_SCORE")) {
        u8 team0Score;
        u8 team1Score;

        if (params.saferead_u8(team0Score) && params.saferead_u8(team1Score)) {
            this.set_u8("team0score", team0Score);
            this.set_u8("team1score", team1Score);
        }
    }
}

void onStateChange(CRules@ this, const u8 oldState) {
    if (!isServer()) return;

    // Detect game over
    if (this.getCurrentState() == GAME_OVER &&
            oldState != GAME_OVER) {
        int winningTeam = this.getTeamWon();
        //log("onStateChange", "Detected game over! Winning team: " + winningTeam);

        if (winningTeam == 0) {
            //log("onStateChange", "Winning team is 0");
            SetScore(this, GetScore(this, 0) + 1, GetScore(this, 1));
        }
        else if (winningTeam == 1) {
            //log("onStateChange", "Winning team is 1");
            SetScore(this, GetScore(this, 0), GetScore(this, 1) + 1);
        }
    }
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player) {
    if (player is null) return true;

    if (text_in.replace(" ", "").toLower() == "nwo god") {
        text_out = "homek god uraaa bububu";
    }
    else if (!player.isMod()) {
        return true;
    }
    else if (text_in == "!help") {
        getNet().server_SendMsg("Available commands are: !resetscore, !togglescore, !setscore, !lockteams");
    }
    else if (text_in == "!resetscore") {
        //log("onServerProcessChat", "Parsed !resetscore cmd");
        SetScore(this, 0, 0);
    }
    else if (text_in == "!togglescore") {
        //log("onServerProcessChat", "Parsed !togglescore cmd");
        ToggleScore(this);
    }
	
    else if (text_in == "!allspec") {
        this.set_bool("teams_locked", false);
        RulesCore@ core;
        this.get("core", @core);
        CBlob@[] all;
        getBlobs( @all );
        for (u32 i=0; i < all.length; i++) {        
            CBlob@ blob1 = all[i];
            if(blob1.getPlayer() != null) {
                core.ChangePlayerTeam(blob1.getPlayer(), this.getSpectatorTeamNum());
                
            }           
        }
    }
	
	else if (text_in == "!lockteams") {
        getRules().set_bool("teams_locked", !getRules().get_bool("teams_locked"));
		getRules().Sync("teams_locked", true);

        if (getRules().get_bool("teams_locked"))
            getNet().server_SendMsg("Teams are locked.");
        else
            getNet().server_SendMsg("Teams are unlocked.");
    }
	
    else {
        string[]@ tokens = text_in.split(" ");
        if (tokens[0] == "!setscore" && tokens.length == 3) {
            //log("onServerProcessChat", "Parsed !setscore cmd");
            string team0ScoreStr = tokens[1];
            string team1ScoreStr = tokens[2];
            int team0Score = parseInt(team0ScoreStr);
            int team1Score = parseInt(team1ScoreStr);
            SetScore(this, team0Score, team1Score);
        }
    }

    return true;
}

void DrawInventoryOnHUD(CBlob@ this, Vec2f tl)
{
    SColor col;
    CInventory@ inv = this.getInventory();
    string[] drawn;
    for (int i = 0; i < inv.getItemsCount(); i++)
    {
        CBlob@ item = inv.getItem(i);
        const string name = item.getName();

            const int quantity = this.getBlobCount(name);
            drawn.push_back(name);

            Vec2f offset = Vec2f(0, 0);

            if (name == "food")
            {
                offset = Vec2f(0, 16);
            }

            GUI::DrawIcon(item.inventoryIconName, item.inventoryIconFrame, item.inventoryFrameDimension, tl + Vec2f(0 + (drawn.length - 1) * 40, -6) + offset, 2.0f);

            f32 ratio = float(quantity) / float(item.maxQuantity);
            col = ratio > 0.4f ? SColor(255, 255, 255, 255) :
                  ratio > 0.2f ? SColor(255, 255, 255, 128) :
                  ratio > 0.1f ? SColor(255, 255, 128, 0) : SColor(255, 255, 0, 0);

            GUI::SetFont("menu");
            Vec2f dimensions(0,0);
            string disp = "" + quantity;

    }
}


void onRender(CRules@ this)
{
    if (!this.get_bool("show score")) return;

    GUI::SetFont("big score font");
    u8 team0Score = GetScore(this, 0);
    u8 team1Score = GetScore(this, 1);
    //log("onRender", "" + team0Score + ", " + team1Score);
    Vec2f team0ScoreDims;
    Vec2f team1ScoreDims;
    Vec2f scoreSeperatorDims;
    GUI::GetTextDimensions("" + team0Score, team0ScoreDims);
    GUI::GetTextDimensions("" + team1Score, team1ScoreDims);
    GUI::GetTextDimensions("-", scoreSeperatorDims);

    Vec2f scoreDisplayCentre(getScreenWidth()/2, getScreenHeight() / 9.0);
    int scoreSpacing = 24;

    CPlayer@ blue_player;
    CPlayer@ red_player;

    string blue = "BLUE";
    f32 blue_health = 0;
    string red = "RED";
    f32 red_health = 0;

    for (int i=0; i<getPlayerCount(); ++i)
    {
        CPlayer@ p = getPlayer(i);

        if (p.getTeamNum() != 0 && p.getTeamNum() != 1)
        {
            continue;
        }

        if (p.getTeamNum() == 0)
        {
            if (p.getBlob() !is null)
            {
                blue_health = p.getBlob().getHealth() * 2;
                @blue_player = p;
            }

            blue = p.getUsername();
        }
        if (p.getTeamNum() == 1)
        {
            if (p.getBlob() !is null)
            {
                red_health = p.getBlob().getHealth() * 2;
                @red_player = p;
            }
            red = p.getUsername();
        }
    }

    Vec2f topLeft0(
            scoreDisplayCentre.x - scoreSpacing - team0ScoreDims.x,
            scoreDisplayCentre.y);
    Vec2f topLeft1(
            scoreDisplayCentre.x + scoreSpacing,
            scoreDisplayCentre.y);
    GUI::DrawText("" + team0Score, topLeft0, TEAM0COLOR);
    GUI::DrawTextCentered("" + blue, topLeft0 - Vec2f(250, 60), TEAM0COLOR);
    GUI::DrawText("-", Vec2f(scoreDisplayCentre.x - scoreSeperatorDims.x/2.0, scoreDisplayCentre.y), color_black);
    GUI::DrawText("" + team1Score, topLeft1, TEAM1COLOR);
    GUI::DrawTextCentered("" + red, topLeft1 - Vec2f(-274, 60), TEAM1COLOR);

    // blue hearts
    Vec2f topleft_0_two = topLeft0 - Vec2f(394, 30);

    if (blue_player !is null)
    {
        if (blue_player.getBlob() !is null)
        {
            DrawInventoryOnHUD(blue_player.getBlob(), topleft_0_two + Vec2f(48, 30));
        }
    }

    for (int i=0; i<6; ++i)
    {
        u8 frame = 0;
        if (blue_health >= 1.0) 
        {
            frame = 1;
            blue_health -= 1.0;
        }
        else if (blue_health >= 0.75) 
        {
            frame = 2;
            blue_health -= 0.75;
        }
        else if (blue_health >= 0.5) 
        {
            frame = 3;
            blue_health -= 0.5;
        }
        else if (blue_health >= 0.25) 
        {
            frame = 4;
            blue_health -= 0.25;
        }
        GUI::DrawIcon("HeartNew.png", frame, Vec2f(12, 12), topleft_0_two, 2.0, 0);
        topleft_0_two += Vec2f(12 * 4.0, 0);
    }



    // red hearts
    Vec2f topleft_1_two = topLeft1 - Vec2f(-130, 30);

    if (red_player !is null)
    {
        if (red_player.getBlob() !is null)
        {
            DrawInventoryOnHUD(red_player.getBlob(), topleft_1_two + Vec2f(48, 30));
        }
    }

    for (int i=0; i<6; ++i)
    {
        u8 frame = 0;
        if (red_health >= 1.0) 
        {
            frame = 1;
            red_health -= 1.0;
        }
        else if (red_health >= 0.75) 
        {
            frame = 2;
            red_health -= 0.75;
        }
        else if (red_health >= 0.5) 
        {
            frame = 3;
            red_health -= 0.5;
        }
        else if (red_health >= 0.25) 
        {
            frame = 4;
            red_health -= 0.25;
        }
        GUI::DrawIcon("HeartNew.png", frame, Vec2f(12, 12), topleft_1_two, 2.0, 0);
        topleft_1_two += Vec2f(12 * 4.0, 0);
    }

    if (!this.isMatchRunning() || this.get_bool("no timer") || !this.exists("end_in")) return;

    s32 end_in = this.get_s32("end_in");

    // HeartNBubble.png;

    GUI::SetFont("big score font");

    if (end_in > 0)
    {
        s32 timeToEnd = end_in;

        s32 secondsToEnd = timeToEnd % 60;
        s32 MinutesToEnd = timeToEnd / 60;
        GUI::DrawTextCentered(getTranslatedString("{MIN}:{SEC}")
                        .replace("{MIN}", "" + ((MinutesToEnd < 10) ? "0" + MinutesToEnd : "" + MinutesToEnd))
                        .replace("{SEC}", "" + ((secondsToEnd < 10) ? "0" + secondsToEnd : "" + secondsToEnd)),
                      Vec2f(scoreDisplayCentre.x, scoreDisplayCentre.y - 50), SColor(255, 255, 255, 255));
        //void GUI::DrawText(const string&in text, Vec2f upperleft, Vec2f lowerright, SColor color, bool HorCenter, bool VerCenter, bool drawBackgroundPane)
    }

}
