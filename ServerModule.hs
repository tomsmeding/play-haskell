{-# LANGUAGE ExistentialQuantification #-}
module ServerModule where

import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as Char8
import Data.String (fromString)
import Snap.Core hiding (path)
import System.FilePath ((</>))

import Paste.DB (Database)
import SpamDetect


-- TODO: Perhaps this can be split out over modules as well
data Options = Options { oProxied :: Bool
                       , oDBDir :: FilePath }
  deriving (Show)

defaultOptions :: Options
defaultOptions = Options False "."

data GlobalContext = GlobalContext
  { gcSpam :: SpamDetect ByteString
  , gcDb :: Database }

type MimeType = String

data ServerModule =
    forall ctx req. ServerModule
        { smMakeContext :: GlobalContext -> Options -> (ctx -> IO ()) -> IO ()  -- bracket
        , smParseRequest :: Method -> [ByteString] -> Maybe req
        , smHandleRequest :: GlobalContext -> ctx -> req -> Snap ()
        , smStaticFiles :: [(FilePath, MimeType)]
        , smReloadPages :: ctx -> IO () }


httpError :: Int -> String -> Snap ()
httpError code msg = do
    putResponse $ setResponseCode code emptyResponse
    writeBS (Char8.pack msg)

applyStaticFileHeaders :: String -> Response -> Response
applyStaticFileHeaders mime =
    setContentType (Char8.pack mime)
    . setHeader (fromString "Cache-Control") (Char8.pack "public max-age=3600")

staticFile :: String -> FilePath -> Snap ()
staticFile mime path = do
    modifyResponse (applyStaticFileHeaders mime)
    sendFile ("static" </> path)