module Ivy where

import Data
import Monsters
import Utils4mon
import Random
import Parts
import Changes
import Move

import System.Random (randomR)

getIvy :: MonsterGen
getIvy = getMonster ivyAI [(getMain 2, (5, 15))] 15
	(dices (2,10) 0) emptyInv 400

ivyAI :: AIfunc
ivyAI xPlayer yPlayer world
	| abs dx <= 1 && abs dy <= 1 = moveFirst dx dy world
	| isEmpty world (xNow + dx') (yNow + dy')
		= spawnMon getIvy (xNow + dx') (yNow + dy') $ changeGen g'' world
	|otherwise = changeGen g'' $ killFirst world where
		xNow = xFirst world
		yNow = yFirst world
		dx = xPlayer - xNow
		dy = yPlayer - yNow
		g = stdgen world
		(dx', g')  = randomR (-1, 1) g
		(dy', g'') = randomR (-1, 1) g'