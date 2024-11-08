module Main.UI where

import Prelude hiding (div)

import Control.Alt (class Alt)
import Control.Monad.Error.Class (class MonadError, liftMaybe)
import Control.Monad.Maybe.Trans (runMaybeT)
import DOM.HTML.Indexed.InputType (InputType(..))
import Data.Array as Array
import Data.Maybe (Maybe(..))
import Data.Newtype (wrap)
import Data.Variant (Variant)
import Data.Variant as Variant
import Effect (Effect)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (liftEffect)
import Effect.Exception (Error, error)
import Halogen (modify_)
import Halogen as H
import Halogen.Aff as H.Aff
import Halogen.HTML (HTML, a, button, div, form, h1, h2, img, input, label, span, text)
import Halogen.HTML.Events (onChange, onClick)
import Halogen.HTML.Properties (ButtonType(..), checked, class_, href, src, type_)
import Halogen.Subscription as H.Subscription
import Halogen.VDom.Driver as H.VDom
import Routing.PushState (PushStateInterface)
import Routing.PushState as Routing.PushState
import Type.Prelude (Proxy(..))
import UI.Route (Route)
import UI.Route as Route
import Web.DOM.Document as Document
import Web.DOM.Node as DOM.Node
import Web.HTML (window) as Window
import Web.HTML.HTMLDocument as HTMLElement.Document
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.HTMLLinkElement as HTMLElement.Link
import Web.HTML.Window (document) as Window

main :: Effect Unit
main = H.Aff.runHalogenAff do
  body <- H.Aff.awaitBody
  routing <- liftEffect Routing.PushState.makeInterface
  H.VDom.runUI component { routing } body

type Action = Variant
  ( init :: Unit
  , nav :: Route
  , setWhiteMan :: Boolean
  , setLikeCheetoMan :: Boolean
  )

type State =
  { routing :: PushStateInterface
  , route :: Route
  , whiteMan :: Maybe Boolean
  , likeCheetoMan :: Maybe Boolean
  }

type Input = { routing :: PushStateInterface }

component
  :: forall q o m
   . Alt m
  => MonadError Error m
  => MonadAff m
  => H.Component q Input o m
component = H.mkComponent
  { initialState: \{ routing } ->
      { routing
      , route: Route.Root []
      , whiteMan: Nothing
      , likeCheetoMan: Nothing
      }
  , eval: H.mkEval $ H.defaultEval
      { handleAction = liftEffect >=> handleAction
      , initialize = Just $ pure $ Variant.inj (Proxy @"init") unit
      }
  , render
  }

render :: forall i. State -> HTML i (Effect Action)
render { route, whiteMan, likeCheetoMan } =
  let
    app =
      div
        [ class_ $ wrap $ "flex flex-col w-full h-full gap-8 items-center justify-center"
        ]
    footer =
      div
        [ class_ $ wrap "shrink w-full bg-neutral-900 text-neutral-50 p-8 flex justify-end" ]
        [ a
            [ href "https://github.com/cakekindel/shouldiseekrefugeincanada"
            , class_ $ wrap "flex items-center gap-2 px-4 py-2 rounded-lg bg-primary-700"
            ]
            [ img [ src "/assets/github.light.png", class_ $ wrap $ "w-[1rem] h-[1rem]" ]
            , span [ class_ $ wrap "font-mono" ] [ text "cakekindel/shouldiseekrefugeincanada" ]
            ]
        ]
  in
    case route of
      Route.Root _ ->
        app
          $
            [ form
                [ class_ $ wrap "m-12 gap-4 grid grid-cols-[1fr_min-content_min-content] auto-rows-min items-center justify-items-center" ]
                [ label [ class_ $ wrap "justify-self-end" ] [ h2 [] [ text "Are you a white man?" ] ]
                , button
                    [ class_ $ wrap $ "hover:bg-primary-100 text-neutral-900 font-bold text-4xl p-8" <> (if whiteMan == Just true then " bg-primary-200" else " bg-neutral-200")
                    , type_ ButtonButton
                    , onClick $ const $ pure $ Variant.inj (Proxy @"setWhiteMan") true
                    ]
                    [ text "Yes"
                    ]
                , button
                    [ class_ $ wrap $ "hover:bg-primary-100 text-neutral-900 font-bold text-4xl p-8" <> (if whiteMan == Just false then " bg-primary-200" else " bg-neutral-200")
                    , type_ ButtonButton
                    , onClick $ const $ pure $ Variant.inj (Proxy @"setWhiteMan") false
                    ]
                    [ text "No"
                    ]
                , label [ class_ $ wrap "justify-self-end" ] [ h2 [] [ text "Do you support orange man?" ] ]
                , button
                    [ class_ $ wrap $ "hover:bg-primary-100 text-neutral-900 font-bold text-4xl p-8" <> (if likeCheetoMan == Just true then " bg-primary-200" else " bg-neutral-200")
                    , type_ ButtonButton
                    , onClick $ const $ pure $ Variant.inj (Proxy @"setLikeCheetoMan") true
                    ]
                    [ text "Yes"
                    ]
                , button
                    [ class_ $ wrap $ "hover:bg-primary-100 text-neutral-900 font-bold text-4xl p-8" <> (if likeCheetoMan == Just false then " bg-primary-200" else " bg-neutral-200")
                    , type_ ButtonButton
                    , onClick $ const $ pure $ Variant.inj (Proxy @"setLikeCheetoMan") false
                    ]
                    [ text "No"
                    ]
                ]
            , case whiteMan, likeCheetoMan of
                Just whiteMan', Just likeCheetoMan' ->
                  h1
                    [ class_ $ wrap "grow inline self-center text-6xl" ]
                    [ text $ if likeCheetoMan' then "GO FUCK YOURSELF." else if whiteMan' then "PROBABLY NOT." else "YEAH. :(" ]
                _, _ -> div [ class_ $ wrap "grow" ] []
            , footer
            ]

handleAction
  :: forall m o
   . MonadError Error m
  => MonadAff m
  => Action
  -> H.HalogenM State (Effect Action) () o m Unit
handleAction =
  let
    initRouting = do
      { routing } <- H.get
      route <- liftEffect $ Route.get routing
      handleAction $ Variant.inj (Proxy @"nav") route
      { emitter, listener } <- liftEffect H.Subscription.create
      let
        locationChanged loc =
          H.Subscription.notify listener
            $ pure
            $ Variant.inj (Proxy @"nav")
            $ Route.fromLocation loc
      void $ liftEffect $ routing.listen locationChanged
      void $ H.subscribe emitter
  in
    Variant.match
      { nav: \route ->
          H.modify_ (_ { route = route })
            *> H.get
            >>= (\{ routing, route: prev } -> when (prev /= route) (liftEffect $ Route.goto routing route))
      , init: const $ initRouting
      , setWhiteMan: \a -> modify_ \s -> s { whiteMan = Just a }
      , setLikeCheetoMan: \a -> modify_ \s -> s { likeCheetoMan = Just a }
      }

