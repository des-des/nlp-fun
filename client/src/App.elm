module App exposing (..)

import Html
import State
import Types exposing (..)
import View


main : Program Never Model Msg
main =
    Html.program
        { init = State.init
        , view = View.root
        , update = State.update
        , subscriptions = State.subscriptions
        }
