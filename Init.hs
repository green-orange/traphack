module Init where

import Data
import Parts
import Random
import Colors
import Stuff

import System.Random (StdGen)
import qualified Data.Set as S
import qualified Data.Map as M

rectdirs :: (Int, Int, Int, Int) -> (Int, Int, Int, Int) -> Maybe (Int, Int)
rectdirs (xmin, ymin, xmax, ymax) (x, y, dx, dy) =
	if (xnew >= xmin && xnew <= xmax && ynew >= ymin && ynew <= ymax)
	then Just (xnew, ynew)
	else Nothing
	where
		xnew = x + dx
		ynew = y + dy
		
initUnits :: Units
initUnits = Units {
	xF = x',
	yF = y',
	getFirst' = getPlayer,
	list = M.singleton (x', y') getPlayer
} where
	x' = div maxX 2
	y' = div maxY 2

initWorld :: String -> StdGen -> World
initWorld username gen = World {
	worldmap = replicate (1 + maxX) $ replicate (1 + maxY) eMPTY,
	dirs = rectdirs (0, 0, maxX, maxY),
	units' = initUnits,
	message = [("Welcome to the TrapHack, " ++ username ++ ".", bLUE)],
	items = [],
	action = ' ',
	stdgen = gen,
	wave = 1,
	chars = S.empty,
	prevAction = ' ',
	stepsBeforeWave = 1,
	shift = 0,
	slot = toEnum 0
}

getPlayer :: Monster
getPlayer = Monster {
	ai = You,
	parts = zipWith ($) 
		[getBody 1 40, 
		 getHead 1 30, 
		 getLeg  2 20, 
		 getLeg  2 20, 
		 getArm  2 20, 
		 getArm  2 20]
		 [0..],
	name = "You",
	stddmg = dices (1,10) 0.2,
	inv = M.fromList [('a', (fireTrap, 1)),('b',(bearTrap,1)),('c',(poisonTrap,1)),('d',(magicTrap,1))],
	slowness = 100,
	time = 100,
	poison = Nothing,
	res = [0,0..]
}
