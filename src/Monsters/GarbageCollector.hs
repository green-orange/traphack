module Monsters.GarbageCollector where

import Data.Const
import Data.World
import Data.Monster
import Data.Define
import Utils.Changes
import Items.ItemsOverall
import Monsters.Monsters
import Monsters.Move
import Monsters.Parts
import Monsters.AIrepr

import Data.List (minimumBy)
import Data.Function (on)
import Data.Maybe (fromJust)

collectorAI :: AIfunc
collectorAI _ _ _ world = 
	if isItemHere
	then fromJust $ fst $ pickFirst $ foldr changeChar world alphabet
	else moveFirst dx dy world
	where
		isItemHere = any (\ (x, y, _, _) -> x == xNow && y == yNow) (items world)
		xNow = xFirst world
		yNow = yFirst world
		(xItem, yItem, _, _) = minimumBy cmp $ items world
		dist x y = max (x - xNow) (y - yNow)
		cmp = on compare (\(x, y, _, _) -> dist x y)
		(dx, dy) = 
			if null $ items world
			then (0, 0)
			else (signum $ xItem - xNow,
				  signum $ yItem - yNow)

getGarbageCollector :: MonsterGen		  
getGarbageCollector = getMonster (getEatAI CollectorAI)
	[(getBody 1, (20, 40)), 
	 (getHead 1, (10, 30)),
	 (getLeg  1, ( 8, 12)),
	 (getLeg  1, ( 8, 12)),
	 (getArm  1, ( 8, 12)),
	 (getArm  1, ( 8, 12))]
	 17 ((2,4), 0.4) emptyInv 100 100