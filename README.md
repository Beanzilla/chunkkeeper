# chunkkeeper
Keep sections of nodes loaded/running code and growing in minetest

## How it works

You place a Chunk Keeper down, then put burnable items into it (careful, I didn't test what happens to non-burnable items, so expect it to eat it).

Burnable items increate the time the Keeper can work for, so get lots of burnable items so the keeper can burn for long times.

Then just toggle `Run: On` and there you go, it will count down but keep the chunk (Actually a mapblock) loaded.

> For those who are interested in hiding their identity, you can just set `Owner: Hidden`.

## Crafting

Just get 4 iron/steel ingots, 1 gold, and 2 diamond.

Craft it like so:

```
I = Iron ingot (or Steel)
G = Gold ingot
D = Diamond

_ D _
I D I
I G I
```

## For server owners

If you want to have a Chunk Keeper always running say at spawn or somewhere like a public farm, `/giveme chunkkeeper:keeper_inf_off` (Use the infinitive keeper)

> Highly not recommended to provide the infiniative Chunk Keepers as they increase the server load keeping mapblocks loaded.

## Future plans

* Support multiple mapblocks from one Keeper (selecting it will loose the bonus to fuel and possibly increase the fuel consumption too)
* Possible limit max fuel and or even a Refund option (refund burn times by returning coal roughtly equal to the burn time, will return 1 stack at a time if you have that much time essentially "banked")
* Support persistent fuel and settings so you can pick up a Keeper and move it. (Also currently a bug, I don't protect the node from digs only adding fuel or changing options can be done by the owner / who placed the Keeper)

