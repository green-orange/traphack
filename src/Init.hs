module Init where

import Data.Const
import Data.Define
import Data.ID
import Utils.Monsters
--import Utils.Items
import Items.Stuff
import Monsters.Parts
import IO.Colors
import IO.Texts
import MapGen

import System.Random (StdGen)
import qualified Data.Set as S
import qualified Data.Map as M
import Data.Functor ((<$>))
import Data.Char (isDigit)
import Control.Monad (when)

-- | initialize 'units' with in the center
initUnits :: Monster -> Units
initUnits char = Units {
	xF = x',
	yF = y',
	getFirst' = char,
	list = M.singleton (x', y') char
} where
	x' = div maxX 2
	y' = div maxY 2

-- | initialize world with given type of map generator,
-- username and RNG
initWorld :: MapGenType -> Monster -> String -> StdGen -> World
initWorld mapgen char username gen = World {
	worldmap = worldmap',
	units' = initUnits char,
	message = [(msgWelcome username, blue)],
	items = [],
	action = Move,
	stdgen = newStdGen,
	wave = 1,
	chars = S.empty,
	prevAction = ' ',
	shift = 0,
	slot = toEnum 0,
	xInfo = 0,
	yInfo = 0,
	numToSplit = 0,
	colorHeight = defaultColorHeight,
	symbolHeight = defaultSymbolHeight,
	mapType = mapgen
} where (worldmap', newStdGen) = runMap mapgen gen

partsYou, partsStrongYou :: [Part]
partsYou = zipWith ($) [
	getBody 1 40, 
	getHead 1 30, 
	getLeg  2 20, 
	getLeg  2 20, 
	getArm  2 20, 
	getArm  2 20] [0..]

partsStrongYou = zipWith ($) [
	getBody 10 400, 
	getHead 10 300, 
	getLeg  20 200, 
	getLeg  20 200, 
	getArm  20 200, 
	getArm  20 200] [0..]

-- | initialize the Player
getPlayer :: Monster
getPlayer = Monster {
	ai = You,
	parts = partsYou,
	name = "You",
	stddmg = ((1,10), 0.2), -- avg 4.4
	inv = M.empty,
	slowness = 100,
	time = 100,
	res = const 0 <$> (getAll :: [Elem]),
	intr = startIntrs 10,
	temp = startTemps 50,
	idM = idYou,
	xp = 1
}

-- | initialize flying Player
getFlyingPlayer :: Monster
getFlyingPlayer = Monster {
	ai = You,
	parts = partsYou,
	name = "You",
	stddmg = ((1,10), 0.2), -- avg 4.4
	inv = M.empty,
	slowness = 100,
	time = 100,
	res = const 0 <$> (getAll :: [Elem]),
	intr = startIntrs 10,
	temp = startTemps 50,
	idM = idYou,
	xp = 1
}

-- | initialize very strong Player
getStrongPlayer :: Monster
getStrongPlayer = Monster {
	ai = You,
	parts = partsStrongYou,
	name = "You",
	stddmg = ((1000,1000), 0.0), -- avg 1000
	inv = M.empty,
	slowness = 50,
	time = 50,
	res = const 0 <$> (getAll :: [Elem]),
	intr = startIntrs 100,
	temp = startTemps 5000,
	idM = idYou,
	xp = 1
}

getGodlikePlayer :: Monster
getGodlikePlayer = Monster {
	ai = You,
	parts = partsStrongYou,
	name = "You",
	stddmg = ((1,1000), 0.0), -- avg 500
	inv = M.empty,
	slowness = 50,
	time = 50,
	res = const 0 <$> (getAll :: [Elem]),
	intr = startIntrs 1000,
	temp = startTemps 5000,
	idM = idYou,
	xp = 1
}

-- | default parameters for some generators
defMountainCnt, defFlatHeight, defRiverCnt, defSwampDepth, defBonfireCnt, defMagicCnt,
	defSinesCnt, defTrapCnt :: Int
defMountainCnt = 200
defFlatHeight = 9
defRiverCnt = 50
defSwampDepth = 3
defBonfireCnt = defTrapCnt
defMagicCnt = defTrapCnt
defSinesCnt = 10
defTrapCnt = 100

-- | default version of Mountains
defMountains :: HeiGenType
defMountains = Mountains defMountainCnt

-- | show start menu with start map generator choice
showMapChoice :: IO MapGenType
showMapChoice = do
	putStrLn "Choose a map:"
	putStrLn "a - map with mountains and large valleys, DEFAULT"
	putStrLn $ "b - flat map with height = " ++ show defFlatHeight
	putStrLn "c - averaged random map"
	putStrLn "d - (a) with rivers"
	putStrLn "e - (a) with swamps"
	putStrLn "f - (a) with bonfires"
	putStrLn "g - (a) with magic sources"
	putStrLn "* - customize map"
	c <- getLine
	case c of
		"a" -> return $ pureMapGen defMountains
		"b" -> return $ pureMapGen $ Flat defFlatHeight
		"c" -> return $ MapGenType Random 1 NoWater NoTraps
		"d" -> return $ MapGenType defMountains 0 (Rivers defRiverCnt) NoTraps
		"e" -> return $ MapGenType defMountains 0 (Swamp defSwampDepth) NoTraps
		"f" -> return $ MapGenType defMountains 0 NoWater $ Bonfires defBonfireCnt
		"g" -> return $ MapGenType defMountains 0 NoWater $ MagicMap defMagicCnt
		"*" -> customMapChoice
		_ ->  return $ pureMapGen defMountains 

-- | show advanced map menu
customMapChoice :: IO MapGenType
customMapChoice = do
	putStrLn "Choose a height generator: "
	putStrLn "a - sum of n sinuses, DEFAULT"
	putStrLn "b - random map"
	putStrLn "c - mountains, custom"
	putStrLn "d - flat map (with customized height)"
	heigenStr <- getLine
	when (heigenStr == "a") $ putStrLn $ "Put number of sine waves (default: " ++
		show defSinesCnt ++ ")"
	when (heigenStr == "c") $ putStrLn $ "Put number of hills (default: " ++
		show defMountainCnt ++ ")"
	when (heigenStr == "d") $ putStrLn $ "Put height of the map (default: " ++ 
		show defFlatHeight ++ ")"
	hei <- if heigenStr `elem` ["a", "c", "d"] then getLine else return ""
	putStrLn "Choose averaging: (default: 0)"
	avgStr <- getLine
	putStrLn "Choose water: "
	putStrLn "a - without water, DEFAULT"
	putStrLn "b - rivers"
	putStrLn "c - swamps"
	waterStr <- getLine
	when (waterStr == "b") $ putStrLn $ "Put count of rivers (default: " ++
		show defRiverCnt ++ ")"
	when (waterStr == "c") $ putStrLn $ "Put depth of swamps (default: " ++
		show defSwampDepth ++ ")"
	waternum <-	if waterStr == "b" || waterStr == "c" then getLine
		else return ""
	putStrLn "Choose traps: "
	putStrLn "a - without traps, DEFAULT"
	putStrLn "b - bonfires"
	putStrLn "c - magic sources"
	trapStr <- getLine
	when (trapStr == "b" || trapStr == "c")
		$ putStrLn $ "Put count of traps (default: " ++
		show defTrapCnt ++ ")"
	trapnum <- if trapStr == "b" || trapStr == "c" then getLine
		else return ""
	return $ MapGenType (heigen heigenStr hei) (avg avgStr)
		(water waterStr waternum) (trapsType trapStr trapnum)
	where
		maybeReadNum :: Int -> String -> Int
		maybeReadNum def [] = def
		maybeReadNum def str = 
			if all isDigit str then read str else def
		heigen str1 str2 = case str1 of
			"a" -> Sines $ maybeReadNum defSinesCnt str2
			"b" -> Random
			"c" -> Mountains $ maybeReadNum defMountainCnt str2
			"d" -> Flat $ maybeReadNum 9 str2
			_ -> Sines defSinesCnt
		avg = maybeReadNum 0
		water str1 str2 = case str1 of
			"a" -> NoWater
			"b" -> Rivers $ maybeReadNum defRiverCnt str2
			"c" -> Swamp $ maybeReadNum defSwampDepth str2
			_ -> NoWater
		trapsType str1 str2 = case str1 of
			"a" -> NoTraps
			"b" -> Bonfires $ maybeReadNum defBonfireCnt str2
			"c" -> MagicMap $ maybeReadNum defMagicCnt str2
			_ -> NoTraps

-- | get player with default inventory
getDefaultPlayer :: Monster
getDefaultPlayer = getPlayer {inv = listToMap defInv}

-- | show start menu with character choice
showCharChoice :: IO Monster
showCharChoice = do
	putStrLn "Choose your character: "
	putStrLn "a - standard character without items"
	putStrLn "b - (a) with pickaxe and traps, DEFAULT"
	putStrLn "c - (a) with stacks of potions, scrolls, rings, amulets, "
	putStrLn "wands, traps and tools"
	putStrLn "d - flying creature without items"
	putStrLn "e - character with very high stats, maximum armor and weapon"
	putStrLn "f - (c) + (d) + (e)"
	c <- getLine
	return $ case c of
		"a" -> getPlayer
		"b" -> getPlayer {inv = listToMap defInv}
		"c" -> getDefaultPlayer 
		"d" -> getFlyingPlayer
		"e" -> getStrongPlayer {inv = listToMap warInv}
		"f" -> getGodlikePlayer {inv = listToMap $ warInv ++ fullInv}
		_ -> getDefaultPlayer

-- | converts list to a map where alphabet letters are keys
listToMap :: [a] -> M.Map Char a
listToMap = M.fromList . zip alphabet

-- | list of all magical items
fullInv :: [(Object, Int)]
fullInv = zip (map ($ 5) uniqueAmulets ++ map ($ 4) uniqueRings
	++ map ($ 100) uniqueWands ++ tools) [1, 1..] ++ zip (potions ++ scrolls ++ traps) [100, 100..]

-- | default inventory: lotsa traps and a pickaxe
defInv :: [(Object, Int)]
defInv = zip traps [5, 5..] ++ [(pickAxe, 1)]

-- | maximum armor and weapon
warInv :: [(Object, Int)]
warInv = flip zip [1, 1..] $ map (\x -> x {enchantment = 100})
	[crysknife, plateMail, kabuto, gauntlet, highBoot]
