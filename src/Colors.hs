module Colors where

import Data (Terrain (..))

import UI.HSCurses.Curses
import Data.Maybe (fromJust)

dEFAULT, gREEN, yELLOW, rED, cYAN, mAGENTA, bLUE, rEDiNVERSE :: Int
dEFAULT    = 1
rED        = 2
gREEN      = 3
yELLOW     = 4
bLUE       = 5
mAGENTA    = 6
cYAN       = 7
rEDiNVERSE = 58

colorFromTerr :: Terrain -> Int
colorFromTerr Empty      = 8
colorFromTerr BearTrap   = 32
colorFromTerr FireTrap   = 16
colorFromTerr PoisonTrap = 56
colorFromTerr MagicTrap  = 48

initColors :: IO ()
initColors = sequence_ actions where
	colorList = ["red", "green", "yellow", "blue", "magenta", "cyan", "white"]
	colorListFore = defaultForeground : map (fromJust . color) colorList
	colorListBack = defaultBackground : map (fromJust . color) colorList
	bindColor n = initPair (Pair n) (colorListFore !! mod (n-1) 8) (colorListBack !! div (n-1) 8)
	actions = map bindColor [1..64]

symbolMon :: String -> (Char, Int)
symbolMon "You"               = ('@', dEFAULT)
symbolMon "Homunculus"        = ('h', dEFAULT)
symbolMon "Beetle"            = ('a', dEFAULT)
symbolMon "Bat"               = ('B', rED)
symbolMon "Hunter"            = ('H', dEFAULT)
symbolMon "Ivy"               = ('I', gREEN)
symbolMon "Dummy"             = ('&', bLUE)
symbolMon "Garbage collector" = ('G', bLUE)
symbolMon "Accelerator"       = ('A', dEFAULT)
symbolMon "Troll"             = ('T', dEFAULT)
symbolMon "Rock"              = ('#', dEFAULT)
symbolMon "Tail"              = ('~', dEFAULT)
symbolMon "Worm"              = ('w', dEFAULT)
symbolMon "Golem"             = ('g', bLUE)
symbolMon "Floating eye"      = ('e', mAGENTA)
symbolMon "Red dragon"        = ('D', rED)
symbolMon "White dragon"      = ('D', dEFAULT)
symbolMon "Green dragon"      = ('D', gREEN)
symbolMon "Forgotten beast"   = ('X', mAGENTA)
symbolMon "Spider"            = ('s', dEFAULT)
symbolMon "Soldier"           = ('@', yELLOW)
symbolMon "Umber hulk"        = ('U', dEFAULT)
symbolMon _                   = error "unknown monster"