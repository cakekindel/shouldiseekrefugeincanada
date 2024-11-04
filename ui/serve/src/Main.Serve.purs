module Main.Serve where

import Prelude

import Control.Monad.Error.Class (try)
import Control.Parallel (parOneOf)
import Data.Array as Array
import Data.Either (Either(..), hush)
import Data.Filterable (filter)
import Data.Foldable (fold)
import Data.Int as Int
import Data.Maybe (fromMaybe, maybe)
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Data.Posix.Signal (Signal(..))
import Data.Profunctor (dimap)
import Data.Set (Set)
import Data.Set as Set
import Data.String as String
import Data.Traversable (for, for_, traverse)
import Data.Tuple (fst, snd)
import Data.Tuple.Nested ((/\))
import Dotenv as Dotenv
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Aff as Aff
import Effect.Class (liftEffect)
import Effect.Console (log)
import HTTPurple (Method(..), Request, Response, catchAll, header, headers, methodNotAllowed, ok', serve)
import HTTPurple.Headers (ResponseHeaders)
import Node.Buffer (Buffer)
import Node.Crypto as Crypto
import Node.Encoding (Encoding(..))
import Node.EventEmitter as Event
import Node.FS.Aff as FS
import Node.FS.Stats as FS.Stat
import Node.Path as Path
import Node.Process (mkSignalH)
import Node.Process as Process
import Routing.Duplex (RouteDuplex')

foreign import contentTypeFromExtension :: String -> Effect (Nullable String)

readRec :: String -> Aff (Array String)
readRec base = do
  contentsUnresolved <- FS.readdir base
  contents <- liftEffect $ for contentsUnresolved $ Path.resolve [ base ]
  stats <- for contents (\c -> FS.stat c <#> (_ /\ c))
  recFiles <- for (filter (FS.Stat.isDirectory <<< fst) stats) \(_ /\ path) -> do
    p <- liftEffect $ Path.resolve [ base ] path
    readRec p
  let
    files = snd <$> filter (FS.Stat.isFile <<< fst) stats
  pure $ fold recFiles <> files

publicFiles :: Aff (Set String)
publicFiles = do
  cwd <- liftEffect Process.cwd
  public <- liftEffect $ Path.resolve [ cwd ] "public"
  files <- readRec "public"
  pure $ Set.fromFoldable $ Path.relative public <$> files

publicFilesHash :: Aff Buffer
publicFilesHash = do
  hash <- liftEffect $ Crypto.createHash Crypto.MD5
  files <- publicFiles >>=
    (liftEffect <<< traverse (Path.resolve [ "public" ]) <<< Array.fromFoldable)
  for_ files \f -> do
    c <- FS.readTextFile UTF8 f
    liftEffect $ Crypto.update hash c
  liftEffect $ Crypto.digest hash

requestPath :: RouteDuplex' (Array String)
requestPath = dimap (filter (not <<< String.null)) (filter (not <<< String.null))
  catchAll

corsHeaders :: ResponseHeaders
corsHeaders = headers
  [ "access-control-allow-origin" /\ "*"
  , "access-control-allow-headers" /\ "*"
  , "access-control-allow-methods" /\ "*"
  ]

router
  :: Request (Array String)
  -> Aff Response
router req
  | req.method /= Get = methodNotAllowed
  | otherwise = do
      liftEffect $ log $ show req.route
      files <- publicFiles
      let
        path = Path.normalize $ Path.concat req.route
      liftEffect $ log $ "GET " <> path
      if Set.member path files then do
        contentType <- liftEffect $ (Nullable.toMaybe <=< hush) <$> try
          (contentTypeFromExtension path)
        let
          hs = maybe (corsHeaders) ((corsHeaders <> _) <<< header "content-type")
            contentType
        buf <- FS.readFile =<< liftEffect (Path.resolve [ "public" ] path)
        ok' hs buf
      else
        router $ req { route = [ "index.html" ] }

main :: Effect Unit
main = launchAff_ do
  void $ try $ Dotenv.loadFile
  stopServer <- liftEffect runServer
  let
    signal sig =
      Aff.makeAff \cb ->
        Event.once (mkSignalH sig) (cb $ Right unit) Process.process
          $> Aff.nonCanceler

  void $ parOneOf [ signal SIGINT, signal SIGTERM, signal SIGKILL ]
  liftEffect $ stopServer

runServer :: Effect (Effect Unit)
runServer = do
  listenHostname <-
    Process.lookupEnv "UI_LISTEN_HOSTNAME"
      <#> fromMaybe "0.0.0.0"
  listenPort <-
    Process.lookupEnv "UI_LISTEN_PORT"
      <#> (flip bind Int.fromString)
      <#> fromMaybe 8080
  stop <-
    serve
      { hostname: listenHostname, port: listenPort }
      { route: requestPath, router }
  pure $ stop (pure unit)
