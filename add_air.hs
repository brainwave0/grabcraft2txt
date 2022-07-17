#!/usr/bin/env runhaskell
{-# LANGUAGE DeriveGeneric, NamedFieldPuns, QuasiQuotes #-}
import System.IO (stdin)
import GHC.Generics (Generic)
import Data.Aeson (FromJSON, eitherDecode')
import Data.HashMap.Strict (empty, insert, HashMap, elems, keys, lookupDefault)
import Data.List (foldl', intercalate, group, replicate, stripPrefix, isPrefixOf, find, inits, intersperse, transpose)
import Data.ByteString.Lazy (hGetContents)
import Data.String.Interpolate (i)
import Data.Maybe (isJust, isNothing)
data Block = Block {x :: Int, y :: String, z :: String, name :: String} deriving Generic
instance FromJSON Block
type BlockMap = HashMap Int (HashMap Int (HashMap Int String))
data SimplifyResult a = Count Int [SimplifyResult a] | Occurrence a deriving (Eq, Show)

main :: IO ()
main = do
    json <- hGetContents stdin
    let eitherBlocks = eitherDecode' json
        blockMap = case eitherBlocks of
                       Left message -> error message
                       Right blocks -> buildMap blocks
        lists = toLists blockMap
    putStrLn $ toInstructions lists

buildMap :: [Block] -> BlockMap
buildMap blocks = foldl' buildMap' empty blocks where
    buildMap' currentMap Block{x, y, z, name} = insert zindex yMap' currentMap where
        xMap = lookupDefault empty yindex yMap
        yMap = lookupDefault empty zindex currentMap
        yMap' = insert yindex xMap' yMap
        xMap' = insert xindex name xMap
        xindex = x
        yindex = read z
        zindex = read y

toLists :: BlockMap -> [[[String]]]
toLists blockMap = map (map (toLists' "air" maxX) . toLists' empty maxY) [lookupDefault empty i blockMap | i <- [1..maxZ]]
    where
        toLists' default_ max_ submap = [lookupDefault default_ i submap | i <- reverse [1..max_]]
        maxZ = maximum $ keys blockMap
        maxY = maximum $ map maximum $ map keys $ elems blockMap
        maxX = maximum $ map maximum $ map keys $ concatMap elems $ elems blockMap

toInstructions :: [[[String]]] -> String
toInstructions = format . simplify . concat . concat . addLevelMarkers . map addRowMarkers

format2 :: Int -> SimplifyResult String -> String
format2 indents (Occurrence string) = indent indents ++ string
format2 indents (Count n xs) = indent indents ++ show n ++ " times:\n" ++ init (unlines (map (format2 (indents + 1)) xs))

format = unlines . map (format2 0)

indent :: Int -> String
indent indents = replicate (4 * indents) ' '

simplify :: Eq a => [a] -> [SimplifyResult a]
simplify = simplify3 . simplify2 . map Occurrence

simplify2 :: Eq a => [SimplifyResult a] -> [SimplifyResult a]
simplify2 [] = []
simplify2 [x] = [x]
simplify2 xs = 
    case pattern xs of
        Just pattern_ -> Count (length suffixes_) pattern_ : simplify2 (last suffixes_) where
            suffixes_ = suffixes pattern_ xs
        Nothing -> head xs : simplify2 (tail xs)

simplify3 :: Eq a => [SimplifyResult a] -> [SimplifyResult a]
simplify3 prev = if result == prev then result else simplify3 result where
    result = simplify2 prev

count (Count n _) = n
count (Occurrence _) = 1

pattern :: Eq a => [a] -> Maybe [a]
pattern xs = find ((> 1) . length . flip suffixes xs) (take 10 $ tail $ inits xs)

suffixes :: Eq a => [a] -> [a] -> [[a]]
suffixes xs ys =
    case maybeSuffix of
        Just suffix -> suffix : suffixes xs suffix
        Nothing -> []
    where
        maybeSuffix = stripPrefix xs ys

addRowMarkers :: [[String]] -> [[String]]
addRowMarkers rows = map concat $ transpose [markers, rows] where
    markers = [[[i|row #{n}|]] | n <- [1..length rows]]

addLevelMarkers :: [[[String]]] -> [[[String]]]
addLevelMarkers levels = map concat $ transpose [markers, levels] where
    markers = [[[[i|level #{n}|]]] | n <- [1..length levels]]
