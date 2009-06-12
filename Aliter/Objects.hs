module Aliter.Objects where

import qualified Config.Main as C

import Aliter.Hex
import Aliter.Log
import Aliter.Pack
import Aliter.Util (fromBS)

import Codec.Compression.Zlib
import Data.IORef (IORef)
import Data.List (intercalate)
import Data.Maybe (fromJust)
import Database.HDBC
import Network.Socket (Socket)
import System.IO
import qualified Data.ByteString.Lazy as B


data State = InitState { sClient :: Socket
                       , sLog :: Log
                       }
           | MidState { sClient :: Socket
                      , sLog :: Log
                      , sAccount :: Account
                      }
           | State { sClient :: Socket
                   , sLog :: Log
                   , sAccount :: Account
                   , sActor :: Character
                   }
           deriving (Eq, Show)

data Account = Account { aID :: Integer
                       , aUsername :: String
                       , aPassword :: String
                       , aEmail :: String
                       , aGender :: Int
                       , aLoginCount :: Integer
                       , aLastLogin :: String
                       , aLastIP :: String
                       , aGMLevel :: Int
                       , aBanUntil :: String
                       }
                       deriving (Eq, Show)

data Character = Character { cID :: Integer
                           , cAccountID :: Integer
                           , cNum :: Int
                           , cName :: String
                           , cJob :: Int
                           , cBLevel :: Int
                           , cBExp :: Integer
                           , cJLevel :: Int
                           , cJExp :: Integer
                           , cZeny :: Integer
                           , cStr :: Int
                           , cAgi :: Int
                           , cVit :: Int
                           , cInt :: Int
                           , cDex :: Int
                           , cLuk :: Int
                           , cMaxHP :: Int
                           , cHP :: Int
                           , cMaxSP :: Int
                           , cSP :: Int
                           , cStatusPoints :: Int
                           , cSkillPoints :: Int
                           , cPartyID :: Integer
                           , cGuildID :: Integer
                           , cPetID :: Integer
                           , cHomunculusID :: Integer
                           , cMercenaryID :: Integer
                           , cHairStyle :: Int
                           , cHairColor :: Int
                           , cClothesColor :: Int
                           , cViewWeapon :: Int
                           , cViewShield :: Int
                           , cViewHeadTop :: Int
                           , cViewHeadMid :: Int
                           , cViewHeadBot :: Int
                           , cMap :: String
                           , cX :: Int
                           , cY :: Int
                           , cSaveMap :: String
                           , cSaveX :: Int
                           , cSaveY :: Int
                           , cOnline :: Int
                           , cFame :: Integer
                           , cGuildPositionID :: Integer
                           , cGuildTaxed :: Integer
                           }
                           deriving (Eq, Show)

data Map = Map { name :: String
               , width :: Int
               , height :: Int
               , tiles :: [[Int]]
               , players :: [(Integer, IORef State)]
               {- , monsters :: [Monster] -}
               {- , npcs :: [NPC] -}
               {- , warps :: [Warp] -}
               }
               deriving (Eq)


instance Show Map where
    show m = "Map { name = " ++ show (name m) ++ ", width = " ++ show (width m) ++ ", height = " ++ show (height m) ++ ", ... }"


getAccount :: Integer -> IO (Maybe Account)
getAccount id = do c <- C.connect
                   res <- quickQuery' c "SELECT * FROM accounts WHERE id = ? LIMIT 1" [toSql id]
                   case res of
                        [] -> return Nothing
                        [attr] -> return (Just $ mkAccount attr)

getAccountBy :: [(String, SqlValue)] -> IO (Maybe Account)
getAccountBy vs = do c <- C.connect
                     res <- quickQuery' c ("SELECT * FROM accounts WHERE " ++ w ++ " LIMIT 1") (map snd vs)
                     case res of
                          [] -> return Nothing
                          [attr] -> return (Just $ mkAccount attr)
                  where
                      w = intercalate " AND " (map (\(s, _) -> s ++ " = ?") vs)

getCharacter :: Integer -> IO (Maybe Character)
getCharacter id = do c <- C.connect
                     res <- quickQuery' c "SELECT * FROM characters WHERE id = ? LIMIT 1" [toSql id]
                     case res of
                          [] -> return Nothing -- logMsg l Error ("Cannot find charactor " ++ red (show id))
                          [attr] -> return (Just $ mkCharacter attr)

getCharacterBy :: [(String, SqlValue)] -> IO (Maybe Character)
getCharacterBy vs = do c <- C.connect
                       res <- quickQuery' c ("SELECT * FROM characters WHERE " ++ w ++ " LIMIT 1") (map snd vs)
                       case res of
                            [] -> return Nothing
                            [attr] -> return (Just $ mkCharacter attr)
                    where
                        w = intercalate " AND " (map (\(s, _) -> s ++ " = ?") vs)

getCharactersBy :: [(String, SqlValue)] -> IO [Character]
getCharactersBy vs = do c <- C.connect
                        res <- quickQuery' c ("SELECT * FROM characters WHERE " ++ w) (map snd vs)
                        return (map mkCharacter res)
                     where
                         w = intercalate " AND " (map (\(s, _) -> s ++ " = ?") vs)

addCharacter :: [(String, SqlValue)] -> IO Character
addCharacter vs = do c <- C.connect
                     quickQuery c ("INSERT INTO characters (" ++ cols ++ ") VALUES (" ++ intercalate ", " (replicate (length vs) "?") ++ ")") (map snd vs)
                     case (lookup "accountID" vs, lookup "charNum" vs) of
                          (Just a, Just c) -> do c <- getCharacterBy [ ("accountId", a)
                                                                     , ("charNum", c)
                                                                     ]
                                                 return (fromJust c)
                  where
                      cols = intercalate ", " (map (\(n, _) -> "`" ++ n ++ "`") vs)


mkAccount as = Account { aID = fromSql (as !! 0)
                       , aUsername = fromSql (as !! 1)
                       , aPassword = fromSql (as !! 2)
                       , aEmail = fromSql (as !! 3)
                       , aGender = fromSql (as !! 4)
                       , aLoginCount = fromSql (as !! 5)
                       , aLastLogin = fromSql (as !! 6)
                       , aLastIP = fromSql (as !! 7)
                       , aGMLevel = fromSql (as !! 8)
                       , aBanUntil = fromSql (as !! 9)
                       }

mkCharacter as = Character { cID = fromSql (as !! 0)
                           , cAccountID = fromSql (as !! 1)
                           , cNum = fromSql (as !! 2)
                           , cName = fromSql (as !! 3)
                           , cJob = fromSql (as !! 4)
                           , cBLevel = fromSql (as !! 5)
                           , cBExp = fromSql (as !! 6)
                           , cJLevel = fromSql (as !! 7)
                           , cJExp = fromSql (as !! 8)
                           , cZeny = fromSql (as !! 9)
                           , cStr = fromSql (as !! 10)
                           , cAgi = fromSql (as !! 11)
                           , cVit = fromSql (as !! 12)
                           , cInt = fromSql (as !! 13)
                           , cDex = fromSql (as !! 14)
                           , cLuk = fromSql (as !! 15)
                           , cMaxHP = fromSql (as !! 16)
                           , cHP = fromSql (as !! 17)
                           , cMaxSP = fromSql (as !! 18)
                           , cSP = fromSql (as !! 19)
                           , cStatusPoints = fromSql (as !! 20)
                           , cSkillPoints = fromSql (as !! 21)
                           , cPartyID = fromSql (as !! 22)
                           , cGuildID = fromSql (as !! 23)
                           , cPetID = fromSql (as !! 24)
                           , cHomunculusID = fromSql (as !! 25)
                           , cMercenaryID = fromSql (as !! 26)
                           , cHairStyle = fromSql (as !! 27)
                           , cHairColor = fromSql (as !! 28)
                           , cClothesColor = fromSql (as !! 29)
                           , cViewWeapon = fromSql (as !! 30)
                           , cViewShield = fromSql (as !! 31)
                           , cViewHeadTop = fromSql (as !! 32)
                           , cViewHeadMid = fromSql (as !! 33)
                           , cViewHeadBot = fromSql (as !! 34)
                           , cMap = fromSql (as !! 35)
                           , cX = fromSql (as !! 36)
                           , cY = fromSql (as !! 37)
                           , cSaveMap = fromSql (as !! 38)
                           , cSaveX = fromSql (as !! 39)
                           , cSaveY = fromSql (as !! 40)
                           , cOnline = fromSql (as !! 41)
                           , cFame = fromSql (as !! 42)
                           , cGuildPositionID = fromSql (as !! 43)
                           , cGuildTaxed = fromSql (as !! 44)
                           }
