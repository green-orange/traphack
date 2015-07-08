{-# LANGUAGE CPP #-}
module Main where

import Data
import Step
import Changes (clearMessage)
import Show
import Init
import Colors
import Texts

import UI.HSCurses.Curses
import Control.Monad (unless)
import System.Random (getStdGen)
#if linux_HOST_OS
import System.Posix.User
#endif

logName :: String
logName = "trapHack.log"

loop :: World -> IO String
loop world =
	if isPlayerNow world
	then do
		c <- redraw world
		(_, width) <- scrSize
		maybeAppendFile logName $ filter (not . null) 
			$ map fst $ message world
		case step (clearMessage width world) c of
			Left newWorld -> loop newWorld
			Right msg ->
				appendFile logName (msg ++ "\n")
				>> return msg
	else
		case step world $ KeyChar ' ' of
			Left newWorld -> loop newWorld
			Right msg -> redraw world >> 
				appendFile logName (msg ++ "\n") >> return msg
	where
	maybeAppendFile fileName strings = 
		unless (null strings) $ appendFile fileName $ unwords strings ++ "\n"

main :: IO ()
main = do
	writeFile logName ""
	_ <- initScr
	(h, w) <- scrSize
	_ <- endWin
	if w <= 2 * xSight + 42 || h <= 2 * ySight + 5
	then putStrLn msgSmallScr
	else do gen <- getStdGen
#if linux_HOST_OS
		username <- getLoginName
#else
		print msgAskName
		username <- getLine
#endif
		initScr >> initCurses >> startColor >> initColors >>
			keypad stdScr True >> echo False >>
			cursSet CursorInvisible >> return ()
		loop (initWorld username gen) >>= (\msg -> endWin >> putStrLn msg)