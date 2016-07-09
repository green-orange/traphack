module MapGen where

import Data.Define
import Data.Const
import Data.World
import Utils.Random

import System.Random
import qualified Data.Array as A
import Data.Functor ((<$>))
import Control.Arrow (first)

-- | instance to add, multiply etc functions from somewhere to numbers
instance Num b => Num (a -> b) where
	(f + g) x = f x + g x
	(f - g) x = f x - g x
	(f * g) x = f x * g x
	fromInteger = const . fromInteger
	(abs f) x = abs $ f x
	(signum f) x = signum $ f x

-- | converts HeiGenType (enumerable type) to height generator function
runHei :: HeiGenType -> HeiGen
runHei (Sines n) = getSineMap n
runHei Random = getRandomHeis
runHei (Mountains n) = getHillMap n
runHei (Flat n) = getFlatMap n

-- | converts given type of water and height generator to a map generator
runWater :: Water -> HeiGen -> MapGen
runWater NoWater = mapGenFromHeightGen
runWater (Rivers n) = addRiversToGen n
runWater (Swamp n) = addSwampsToGen n

-- | add given type of traps to map generator
runTraps :: TrapMap -> MapGen -> MapGen
runTraps NoTraps = id
runTraps (Bonfires n) = foldr (.) id $ replicate n $ addRandomTerr Bonfire
runTraps (MagicMap n) = foldr (.) id $ replicate n $ addRandomTerr MagicNatural

-- | converts MapGenType (enumerable type) to map generator function
runMap :: MapGenType -> MapGen
runMap (MapGenType heigen avg water traps) = runTraps traps $ runWater water
	$ foldr (.) (limit *. runHei heigen) $ replicate avg $ first averaging

-- | return map generator with given height generator and without water
pureMapGen :: HeiGenType -> MapGenType
pureMapGen heigen = MapGenType heigen 0 NoWater NoTraps

-- | generator of the world map
type MapGen = StdGen -> (A.Array (Int, Int) Cell, StdGen)
-- | generator of the height map
type HeiGen = StdGen -> (A.Array (Int, Int) Int, StdGen)

-- | apply first argument to the first element of the result of second argument
infixr 9 *.
(*.) :: (a -> c) -> (b -> (a, b)) -> b -> (c, b)
(f *. g) x = (f rez, x') where
	(rez, x') = g x

-- | heights < 0 reduced to 0, heights > 9 reduced to 9
limit :: A.Array (Int, Int) Int -> A.Array (Int, Int) Int
limit = fmap $ max 0 . min 9

-- | smoothes the map by taking the average of neighboring cells
averaging :: A.Array (Int, Int) Int -> A.Array (Int, Int) Int
averaging arr = A.array ((0, 0), (maxX, maxY))
	[((x, y), avg x y) | x <- [0..maxX], y <- [0..maxY]] where
	d = [-1..1]
	avg x y = (2 * (arr A.! (x, y)) + sum ((arr A.!) <$> nears)) 
		`div` (2 + length nears) where
		nears = [(x + dx, y + dy) | dx <- d, dy <- d,
			isCell (x + dx) (y + dy)]

-- | converts height map to full map without any obstacles
mapFromHeights :: A.Array (Int, Int) Int -> A.Array (Int, Int) Cell
mapFromHeights = fmap (\h -> Cell {terrain = Empty, height = h})

-- | converts height generator to map generator without any obstacles
mapGenFromHeightGen :: HeiGen -> MapGen
mapGenFromHeightGen hgen = mapFromHeights *. hgen

-- | get a map with equal heights
getFlatMap :: Int -> HeiGen
getFlatMap n g = (A.listArray ((0, 0), (maxX, maxY)) 
	[n, n..], g)

-- | get a map with random heights
getRandomHeis :: HeiGen
getRandomHeis g = (A.listArray ((0, 0), (maxX, maxY)) 
	$ randomRs (0, 9) g', g'') where
	(g', g'') = split g

-- | get a parabolic hill with radius r and center (x0, y0)
getHill :: Float -> Float -> Float -> (Int, Int) -> Float
getHill r x0 y0 (x, y) = max 0 $ r ** 2 - (fromIntegral x - x0) ** 2 - (fromIntegral y - y0) ** 2

-- | get sum of n random hills
getSumHills :: Int -> StdGen -> ((Int, Int) -> Float, StdGen)
getSumHills n g = (f, g3) where
	(gr, g1) = split g
	(gx, g2) = split g1
	(gy, g3) = split g2
	rs = randomRs (4.0, 20.0) gr
	xs = randomRs (0.0, fromIntegral maxX) gx
	ys = randomRs (0.0, fromIntegral maxY) gy
	f = sum $ take n $ zipWith3 getHill rs xs ys

-- | get a sine wave with parameters a and b
getSineWave :: Float -> Float -> (Int, Int) -> Float
getSineWave a b (x, y) = sin $ a * fromIntegral x + b * fromIntegral y

-- | get sum of n random sine waves
getSumSines :: Int -> StdGen -> ((Int, Int) -> Float, StdGen)
getSumSines n g = (f, g2) where
	(ga, g1) = split g
	(gb, g2) = split g1
	as = randomRs (0.1, 1.0) ga
	bs = randomRs (0.1, 1.0) gb
	f = sum $ take n $ zipWith getSineWave as bs

-- | get heightmap from a height function
getMapFromFun :: ((Int, Int) -> Float) -> A.Array (Int, Int) Int
getMapFromFun f = normalizeA $ A.array ((0, 0), (maxX, maxY))
	[((x, y), f (x, y)) | x <- [0..maxX], y <- [0..maxY]]

-- | normalize array to [0, 9]
normalizeA :: A.Array (Int, Int) Float -> A.Array (Int, Int) Int
normalizeA a = fmap norm a where
	maxA = maximum $ A.elems a
	minA = minimum $ A.elems a
	norm x = max 0 $ min 9 $ floor $ (x - minA) / (maxA - minA) * 12.0 - 1.0

-- | height generator for hills
getHillMap :: Int -> HeiGen
getHillMap n = getMapFromFun *. getSumHills n

-- | height generator for sine waves
getSineMap :: Int -> HeiGen
getSineMap n = getMapFromFun *. getSumSines n

-- | add one river starts from (x, y) and flowing down
addRiver :: Int -> Int -> (A.Array (Int, Int) Cell, StdGen)
	-> (A.Array (Int, Int) Cell, StdGen)
addRiver x y (wmap, g) =
	if null nears
	then (newWMap, g')
	else uncurry addRiver (uniformFromList q nears) (newWMap, g')
	where
	newWMap = wmap A.// [((x, y), Cell {terrain = Water, 
		height = height $ wmap A.! (x, y)})]
	nears =
		filter (uncurry isCell &&&
		((Empty ==) . terrain . (wmap A.!)) &&&
		((height (wmap A.! (x, y)) >=) . height . (wmap A.!)))
		[(x, y + 1), (x, y - 1), (x + 1, y), (x - 1, y)]
	(q, g')= randomR (0.0, 1.0) g

-- | add 'cnt' rivers
addRivers :: Int -> MapGen -> MapGen
addRivers cnt mgen g = foldr ($) (wmap, g3) $ zipWith addRiver xs ys where
	(wmap, g1) = mgen g
	(gx, g2) = split g1
	(gy, g3) = split g2
	xs = take cnt $ randomRs (0, maxX) gx
	ys = take cnt $ randomRs (0, maxY) gy

-- | add 'n' rivers to height generator
addRiversToGen :: Int -> HeiGen -> MapGen
addRiversToGen n = addRivers n . mapGenFromHeightGen

-- | add swamps with given depth
addSwamps :: Int -> A.Array (Int, Int) Int -> A.Array (Int, Int) Cell
addSwamps maxh = ((\x -> Cell {height = x, terrain =
	if x <= maxh then Water else Empty}) <$>)

-- | add swamps to height generator
addSwampsToGen :: Int -> HeiGen -> MapGen
addSwampsToGen maxh hgen g = (addSwamps maxh heis, g') where
	(heis, g') = hgen g

-- | add given terrain to a random place if this place is 'Empty'
addRandomTerr :: Terrain -> MapGen -> MapGen
addRandomTerr terr mgen g = 
	if terrain cell == Empty
	then (wmap A.// [((x, y), cell {terrain = terr})], g3)
	else (wmap, g3)
	where
	(x, g1) = randomR (0, maxX) g
	(y, g2) = randomR (0, maxY) g1
	(wmap, g3) = mgen g2
	cell = wmap A.! (x, y)
