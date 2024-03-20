#include "KnightCommon.as";
#include "Logging.as";

const int SLASH_CHANCE = 300;

void onInit(CBlob@ this) {
    this.setKeyPressed(key_action1, true);
}

void onTick(CBlob@ this) {
    //log("onTick", "test");
    if (!getNet().isServer()) return;

    KnightInfo@ knight;
    if (!this.get("knightInfo", @knight))
        return;

    //log("onTick", "Mouse pressed: " + this.isKeyPressed(key_action1));

    if (knight.swordTimer > 20) {
        log("onTick", "Ending slash");
        this.setKeyPressed(key_action1, false);
    }
    /*
    else {
        if (knight.state == KnightStates::normal && XORRandom(SLASH_CHANCE) == 0) {
            log("onTick", "starting slash");
            this.setKeyPressed(key_action1, true);
        }
    }
        if (XORRandom(SLASH_CHANCE) == 0) {
            log("onTick", "starting slash");
            this.setKeyPressed(key_action1, true);
        }
        */
}
