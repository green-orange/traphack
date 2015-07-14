module Utils.Step where

import Data.Const
import Data.World
import Data.Monster
import Data.Define
import Utils.Changes
import Utils.Monsters
import Utils.Stuff
import Utils.HealDamage
import Utils.Items
import Items.Stuff
import Monsters.Wave
import Monsters.Parts
import IO.Colors
import IO.Texts

import System.Random (StdGen, randomR)
import Data.List (sort)
import Data.Maybe (mapMaybe)
import qualified Data.Map as M
import qualified Data.Array as A

bIGpAUSE, pAUSE :: Int
bIGpAUSE = 100
pAUSE    = 3

minSnd :: (Ord b) => (a,b) -> (a,b) -> (a,b)
minSnd x y = if snd x > snd y then y else x

minValue :: (Ord k, Ord a) => M.Map k a -> (k, a)
minValue m = foldr1 minSnd $ M.toList m
	
minimumOn :: (Ord b, Ord k) => (a -> b) -> M.Map k a -> (k, a)
minimumOn f m = (k, m M.! k) where
	k = fst $ minValue $ M.map f m

wait :: Int -> Int
wait n = case mod n 10 of
	0 -> bIGpAUSE
	_ -> pAUSE
	
almostTime :: Monster -> Int
almostTime mon = 
	if alive mon
	then time mon
	else 0

updateFirst :: World -> World
updateFirst w = changeMons newUnits w where
	newUnits = (units' w) {
		xF = x,
		yF = y,
		getFirst' = monNew
	}
	((x, y), monNew) = minimumOn almostTime $ units w

newWaveIf :: World -> World
newWaveIf world
	| not (isPlayerNow world) ||
		levelW world * 3 > wave world = newWorld
	| stepsBeforeWave world > 0 = newWorld
		{stepsBeforeWave = stepsBeforeWave world - 1}
	| stepsBeforeWave world == 0 = callUpon world
	| otherwise = newWorld {stepsBeforeWave = wait $ wave world}
	where
		newWorld = cycleWorld world
		
cycleWorld :: World -> World
cycleWorld w = rotAll $ tempFirst $ actTrapFirst $ regFirst $ cleanFirst 
	$ changeMons newUnits $ addMessages (msgCleanParts monNew) newWorld where
		newUnits = (units' newWorld) {
			xF = x,
			yF = y,
			getFirst' = monNew
		}
		((x, y), monNew) = minimumOn almostTime $ units newWorld
		newWorld = tickFirst w

cleanFirst :: World -> World
cleanFirst w = changeMon (cleanParts $ getFirst w) $ dropPartialCorpse w

remFirst :: World -> World
remFirst world = updateFirst $ changeMons 
	(deleteU (xFirst world, yFirst world) $ units' world) 
	$ changeAction Move world

closestPlayerChar :: Int -> Int -> World -> Maybe (Int, Int)
closestPlayerChar x y w = 
	if M.null yous || abs (x - xP) > xSight || abs (y - yP) > ySight
	then Nothing
	else Just (xP, yP)
	where
	yous = M.filter (\q -> case ai q of
		You -> True
		_ -> False) $ units w
	closest (x1,y1) (x2,y2) = 
		if max (abs $ x1 - x) (abs $ y1 - y) > 
			max (abs $ x2 - x) (abs $ y2 - y)
		then (x2, y2)
		else (x1, y1)
	(xP, yP) = foldr1 closest $ M.keys yous

tempFirst :: World -> World
tempFirst w = changeMon newMon w where
	mon = getFirst w
	newMon = mon {temp = map decMaybe $ temp mon}

decMaybe :: Maybe Int -> Maybe Int
decMaybe Nothing = Nothing
decMaybe (Just 0) = Nothing
decMaybe (Just n) = Just $ n - 1

addDeathDrop :: Monster -> StdGen -> (Monster, StdGen)
addDeathDrop mon g = (changeInv (addCorpse 
	$ M.union (inv mon) newDrop) mon, newGen) where
	(newDrop, newGen) = deathDrop (name mon) g
	corpse = corpseFromMon mon
	addCorpse = case nutrition corpse of
		0 -> id
		_ -> M.insert (head notAlphabet) (corpse, 1)

tickFirst :: World -> World
tickFirst w = changeMon (tickFirstMon $ getFirst w) w

listOfValidChars :: (Object -> Bool) -> World -> String
listOfValidChars f world = sort $ M.keys 
	$ M.filter (f . fst) $ inv $ getFirst world
	
doIfCorrect :: (World, Bool) -> Either World String
doIfCorrect (rez, correct) = 
	if correct
	then Left $ newWaveIf rez
	else Left rez

actTrapFirst :: World -> World
actTrapFirst w = addMessage (newMsg, rED) $ changeGen g $ changeMon newMon w where
	x = xFirst w
	y = yFirst w
	mon = getFirst w
	trap = worldmap w A.! (x,y)
	((newMon, g), newMsg)
		| trap == FireTrap = (dmgRandomElem Fire (Just 8) mon $ stdgen w,
			if name mon == "You"
			then msgFireYou
			else name mon ++ msgFire)
		| trap == PoisonTrap = (randTemp Poison (5, 15) (mon, stdgen w),
			if name mon == "You"
			then msgPoisonYou
			else name mon ++ msgPoison)
		| trap == MagicTrap = let
			(ind, g') = randomR (0, length wANDS - 1) $ stdgen w
			obj = wANDS !! ind
			(newMon', g'') = act obj (mon, g')
			in ((newMon', g''), msgWand (title obj) (name mon))
		| otherwise = ((mon, stdgen w), "")

callUpon :: World -> World
callUpon w = changeAction Move $ addMessage (msgLanding (wave w) , rED) 
	$ newWave $ cycleWorld w {stepsBeforeWave = -1}

dropPartialCorpse :: World -> World
dropPartialCorpse w = changeGen g' $ (foldr ((.) . addItem . wrap . 
	corpseFromPart mon) id $ filter (not . aliveP) $ parts mon) w where
		mindx = if xFirst w == 0 then 0 else -1
		maxdx = if xFirst w == maxX then 0 else 1
		mindy = if yFirst w == 0 then 0 else -1
		maxdy = if yFirst w == maxY then 0 else 1
		(dx, g ) = randomR (mindx, maxdx) $ stdgen w
		(dy, g') = randomR (mindy, maxdy) g
		wrap obj = (xFirst w + dx, yFirst w + dy, obj, 1)
		mon = getFirst w

rotAll :: World -> World
rotAll w = w {items = newItems, units' = (units' w) {list = newMons}} where
	newMons = M.map rotInv $ units w
	newItems = mapMaybe rotItemOnGround $ items w
	rotItemOnGround arg@(x, y, obj, n)
		| not $ isFood obj = Just arg
		| rotRate obj >= rotTime obj = Nothing
		| otherwise = Just (x, y, obj {rotTime = rotTime obj - rotRate obj}, n)

rotInv :: Monster -> Monster
rotInv mon = mon {inv = M.mapMaybe rotItem $ inv mon} where
	rotItem arg@(obj, n)
		| not $ isFood obj = Just arg
		| rotRate obj >= rotTime obj = Nothing
		| otherwise = Just (obj {rotTime = rotTime obj - rotRate obj}, n)
