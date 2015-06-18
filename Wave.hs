module Wave where

import Data
import Monsters
import MonsterList
import Ivy
import Utils4mon

import System.Random (StdGen, randomR)
import qualified Data.Map as M

nameFromGen :: MonsterGen -> String
nameFromGen mgen = name $ fst $ mgen lol

addWave :: Int -> (Units, StdGen) -> (Units, StdGen)
addWave n (uns, g) = 
	if null ms
	then addWave n (uns, g')
	else addMonsters ms (uns, g')
	where
		(ms, g') = genWave n g
		
weigthW :: World -> Int
weigthW w = M.foldr (+) 0 $ M.map (weigth . name) $ M.filter isSoldier $ units w
		
weigth :: String -> Int
weigth "Bat"             = 1
weigth "Homunculus"      = 2
weigth "Beetle"          = 3
weigth "Ivy"             = 3
weigth "Accelerator"     = 3
weigth "Floating eye"    = 3
weigth "Hunter"          = 4
weigth "Troll"           = 4
weigth "Worm"            = 4
weigth "Dragon"          = 7
weigth "Forgotten beast" = 10
weigth _                 = 0
		
genWave :: Int -> StdGen -> ([MonsterGen], StdGen)
genWave n g = 
	if n <= 0
	then ([], g)
	else if d > n
	then (oldWave, g'')
	else (genM frac : oldWave, g'')
	where
		p, frac :: Float
		(p, g') = randomR (0.0, 11.0) g
		frac = p - fromIntegral ind
		ind :: Int
		ind = floor p
		genM = case ind of
			0  -> getHomunculus
			1  -> getBeetle
			2  -> getBat
			3  -> getHunter
			4  -> getIvy
			5  -> getAccelerator
			6  -> getTroll
			7  -> getWorm
			8  -> getFloatingEye
			9  -> getDragon
			10 -> getForgottenBeast
			_  -> error "value error in function genWave"
		d = weigth $ nameFromGen $ genM frac
		(oldWave, g'') = genWave (n - d) g'

newWave :: World -> World
newWave w = w {units' = newUnits, stdgen = newStdGen, wave = wave w + 1} where
	(newUnits, newStdGen) = addWave (wave w) (units' w, stdgen w)
