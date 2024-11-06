module UI.Route where

import Prelude

import Data.Either (hush)
import Data.Generic.Rep (class Generic)
import Data.Maybe (fromMaybe)
import Data.Show.Generic (genericShow)
import Effect (Effect)
import Routing.Duplex (RouteDuplex')
import Routing.Duplex (boolean, end, many, parse, print, root, segment) as RD
import Routing.Duplex.Generic (noArgs, sumPrefix) as RD
import Routing.Duplex.Generic.Syntax ((?))
import Routing.PushState (LocationState, PushStateInterface)
import Simple.JSON (undefined)

data Route = Root (Array String)

derive instance Generic Route _
derive instance Eq Route
instance Show Route where
  show = genericShow

route :: RouteDuplex' Route
route = RD.root $ RD.sumPrefix
  { "Root": (RD.many RD.segment :: _ (Array String))
  }

print :: Route -> String
print = RD.print route

fromLocation :: LocationState -> Route
fromLocation = fromMaybe (Root []) <<< hush <<< RD.parse route <<< _.path

get :: PushStateInterface -> Effect Route
get { locationState } = fromLocation <$> locationState

goto :: PushStateInterface -> Route -> Effect Unit
goto { pushState } r = pushState undefined (print r)
