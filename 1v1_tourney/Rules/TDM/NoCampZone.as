
#include "/Entities/Common/Attacks/Hitters.as"

u32 seconds_till_max = 40;
u32 blocks_kept = 20;

f32 getBarrierPos(CRules@ this, bool red = false)
{
	u32 match_time = 0;

	if (this.exists("match_time"))
	{
		match_time = this.get_u32("match_time");
	}

	u32 test_time = match_time / 1;

	u32 new_time = test_time * 1;

	u32 max_ticks = seconds_till_max * getTicksASecond();

	CMap@ map = getMap();
	u32 map_width = map.tilemapwidth * map.tilesize;

	if (new_time <= 15 * 30)
	{
		if (!red) return 0;
		if (red) return map_width;
	}
	else
	{
		new_time = new_time - 15 * 30;
	}

	f32 percentage_red = Maths::Min(f32(new_time) / f32(max_ticks), 1);

	if (red)
	{
		f32 barrier_pos = map_width - (((map_width * 0.5) - (blocks_kept * map.tilesize * 0.5)) * percentage_red);
		return barrier_pos;
	}

	else 
	{	
		f32 barrier_pos = ((map_width * 0.5) - (blocks_kept * map.tilesize * 0.5)) * percentage_red;
		return barrier_pos;
	}
}

void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
	if (player !is null)
	{
		this.set_u32("ticks_in_red_" + player.getUsername(), 0);
	}
}

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	for (int i=0; i<getPlayerCount(); ++i)
	{
		CPlayer@ p = getPlayer(i);

		this.set_u32("ticks_in_red_" + p.getUsername(), 0);
	}
}

void onTick(CRules@ this)
{
	if (this is null) return;

	CMap@ map = getMap();
	u32 map_height = map.tilemapheight * map.tilesize;
	u32 map_width = map.tilemapwidth * map.tilesize;

	f32 x1 = getBarrierPos(this);
	f32 x2 = getBarrierPos(this, true);

	CBlob@[] players;

	if (getBlobsByTag("player", players))
	{
		for (uint i = 0; i < players.length; i++)
		{
			CBlob@ b = players[i];

			if (b !is null)
			{
				if (b.getPlayer() !is null)
				{

						Vec2f pos = b.getPosition();
						Vec2f vel = b.getVelocity();

						u32 inred = this.get_u32("ticks_in_red_" + b.getPlayer().getUsername());

						if (inred % 30 == 0 && inred >= 30)
						{
							b.server_Hit(b, pos, Vec2f(0, 0), 0.5f, Hitters::drown, true);
							Sound::Play("Gurgle", pos, 2.0f);
						}

						if (b !is null)
						{
							if (b.getPlayer() !is null)
							{

								if (pos.x < x1 || pos.x > x2)
								{
									this.add_u32("ticks_in_red_" + b.getPlayer().getUsername(), 1);
									this.set_bool("in_red_" + b.getPlayer().getUsername(), true);
									b.Tag("inred");
									//printf("Amogus");
								}
								else 
								{
									this.set_bool("in_red_" + b.getPlayer().getUsername(), true);
									this.set_u32("ticks_in_red_" + b.getPlayer().getUsername(), 0);
									b.Untag("inred");
								}
							}
						}
				}
			}
		}
	}

	return;
}

void onRender(CRules@ this)
{
	CMap@ map = getMap();
	u32 map_height = map.tilemapheight * map.tilesize;
	u32 map_width = map.tilemapwidth * map.tilesize;

		GUI::DrawRectangle(
			getDriver().getScreenPosFromWorldPos(Vec2f(0, 0)),
			getDriver().getScreenPosFromWorldPos(Vec2f(getBarrierPos(this), map_height)),
			SColor(int(50), 235, 0, 0)
		);

		GUI::DrawRectangle(
			getDriver().getScreenPosFromWorldPos(Vec2f(getBarrierPos(this, true), 0)),
			getDriver().getScreenPosFromWorldPos(Vec2f(map_width, map_height)),
			SColor(int(50), 235, 0, 0)
		);

	CBlob@[] blobs;

	if (getBlobsByTag("inred", blobs))
	{
		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			//Vec2f pos = b.getPosition();
			//GUI::DrawIcon("mark.png", 0, Vec2f(8, 12), getDriver().getScreenPosFromWorldPos(pos) - Vec2f(4, 32), 2.0, 1);

			if(true)
			{
				Vec2f p = b.getInterpolatedPosition() + Vec2f(0.0f, -b.getHeight() * 1.5f);
				Vec2f pos = getDriver().getScreenPosFromWorldPos(p);
				Vec2f dim(8, 12);

				s32 markcount = 3;
				if (b.getPlayer() !is null)
				{
					u32 inred = this.get_u32("ticks_in_red_" + b.getPlayer().getUsername());

					GUI::DrawIcon("mark.png", 0, dim,
						      pos + Vec2f((- 1.0f) * dim.x, 0) * 2.0f * getCamera().targetDistance,
						      getCamera().targetDistance * 2);
				}
			}
		}
	}
}
