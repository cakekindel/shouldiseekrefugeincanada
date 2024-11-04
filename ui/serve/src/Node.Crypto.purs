module Node.Crypto where

import Prelude

import Effect (Effect)
import Node.Buffer (Buffer)

foreign import data Hash :: Type

data Algorithm = MD5

algorithmString :: Algorithm -> String
algorithmString MD5 = "md5"

foreign import createHashImpl :: String -> Effect Hash
foreign import update :: Hash -> String -> Effect Unit
foreign import digest :: Hash -> Effect Buffer

createHash :: Algorithm -> Effect Hash
createHash = createHashImpl <<< algorithmString
