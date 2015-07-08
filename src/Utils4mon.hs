module Utils4mon where

import Data
import Changes
import HealDamage
import Parts
import Messages
import Colors

import System.Random (StdGen, randomR)

nOTsOLDIERS, nOTeNEMIES :: [String]

nOTsOLDIERS = nOTeNEMIES ++ ["Bat", "Ivy", "Worm"]
isSoldier :: Monster -> Bool
isSoldier mon = not $ isPlayer mon || elem (name mon) nOTsOLDIERS

nOTeNEMIES = ["You", "Dummy", "Garbage collector", "Rock", "Tail", "Golem"]
isEnemy :: Monster -> Bool
isEnemy mon = not $ isPlayer mon || elem (name mon) nOTeNEMIES

alive :: Monster -> Bool
alive mon = hasPart bODY mon' && hasPart hEAD mon' || hasPart mAIN mon' where
	mon' = mon {parts = filter ((>0) . hp) $ parts mon}

hasPart :: Int -> Monster -> Bool
hasPart knd mon = 
	any (\x -> kind x == knd) $ parts mon
	
regPart :: Part -> Part
regPart part = heal (regVel part) part

regMonster :: Monster -> Monster
regMonster mon = changeParts (map regPart $ parts mon) mon

regFirst :: World -> World
regFirst w = changeMon newMon w where
	mon = getFirst w
	newMon = case temp mon !! fromEnum Poison of
		Nothing -> regMonster mon
		Just n -> changeTemp Poison (Just $ max 0 $ (-) n 
			$ res mon !! fromEnum Poison') mon

msgCleanParts :: Monster -> [(String, Int)]
msgCleanParts mon = foldr (:) [] $ filter ((/="") . fst) $ map (\x -> (lostMsg (name mon) 
	$ partToStr $ kind x, color)) $ filter (not . aliveP) $ parts mon where
	color = 
		if name mon == "You"
		then rEDiNVERSE
		else gREEN

isFlying :: Monster -> Bool
isFlying = hasPart wING
		
killFirst :: World -> World
killFirst w = changeMon mon w where
	mon = (getFirst w) {parts = [getMain 0 0 0]}
	
canWalk :: Monster -> Bool
canWalk m = name m `notElem` ["Rock", "Ivy", "Tail", "Worm", "Dummy", "Golem"]

randTemp :: Temp -> (Int, Int) -> (Monster, StdGen) -> (Monster, StdGen)
randTemp temp' bounds (mon, g) = (newMon, g') where
	(duration, g') = randomR bounds g
	newMon = setMaxTemp temp' (Just duration) mon