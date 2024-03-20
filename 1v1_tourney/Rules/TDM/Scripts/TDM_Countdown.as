void onTick(CRules@ this)
{
	if (this.isWarmup())
	{
		CBlob@[] blobs;
		getBlobsByTag("player", @blobs);
		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];
			blob.DisableKeys(key_left | key_right | key_up | key_down |
							key_action1 | key_action2 | key_action3 |
							key_use | key_inventory | key_pickup | key_eat);
		}
	}
}
