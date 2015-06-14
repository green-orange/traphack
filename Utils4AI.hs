module Utils4AI where

import Data
import Utils4all

import qualified Data.Map as M
import Data.Maybe (isJust, fromJust)

needToBeHealedM :: Monster -> Bool
needToBeHealedM mon =
	foldl (||) False $ map (\x -> kind x == bODY && needToBeHealed x) $ parts mon

needToBeHealed :: Part -> Bool
needToBeHealed part = 2 * (hp part) < maxhp part

canBeHealed :: Monster -> Bool
canBeHealed mon = M.foldl (||) False $ M.map (isHealing . fst) $ inv mon

isHealing :: Object -> Bool
isHealing obj = title obj == "potion of healing"

healingAI :: World -> Char
healingAI world = fst $ M.findMin $ M.filter (isHealing . fst) $ inv $ getFirst world

canZapToAttack :: Monster -> Bool
canZapToAttack mon = M.foldl (||) False $ M.map (isAttackWand . fst) $ inv mon

canFire :: Monster -> Bool
canFire mon = any (isValidMissile mon) alphabet
	
isValidMissile :: Monster -> Char -> Bool
isValidMissile mon c = 
	(isJust objs) && (weapon mon /= ' ') 
	&& (isMissile weap) 
	&& (launcher $ fst $ fromJust $ objs) == (category weap) where
	objs = M.lookup c $ inv mon
	weap = fst $ (M.!) (inv mon) (weapon mon)

haveLauncher :: Monster -> Bool
haveLauncher mon = M.foldl (||) False $ M.map (isLauncher . fst) $ inv mon

isAttackWand :: Object -> Bool
isAttackWand obj = isWand obj && charge obj > 0 && 
	title obj == "wand of striking" ||
	title obj == "wand of radiation"

zapAI :: World -> Char
zapAI world = fst $ M.findMin $ M.filter (isAttackWand . fst) $ inv $ getFirst world

missileAI :: World -> Char
missileAI world = head $ filter (isValidMissile mon) alphabet where
	mon = getFirst world

launcherAI :: World -> Char
launcherAI world = fst $ M.findMin $ M.filter (isLauncher . fst) $ inv $ getFirst world

isOnLine :: Int -> Int -> Int -> Int -> Int -> Bool
isOnLine d x1 y1 x2 y2 = abs (x1 - x2) <= d && abs (y1 - y2) <= d &&
	(x1 == x2 || y1 == y2 || x1 - y1 == x2 - y1 || x1 + y1 == x2 + y2)

