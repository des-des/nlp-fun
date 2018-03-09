module State exposing (..)

import Rest
import Types exposing (..)


-- INIT


init : ( Model, Cmd Msg )
init =
    ( Model [] Nothing
    , Rest.getSearch
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetArticleIds ->
            ( model, Rest.getArticleIds )

        ArticleIds (Err error) ->
            ( Model [] (Just error), Cmd.none )

        ArticleIds (Ok ids) ->
            case ids of
                [] ->
                    ( model, Cmd.none )

                articleId :: _ ->
                    ( model, Rest.getDocument articleId )

        GetDocument articleId ->
            ( model, Rest.getDocument articleId )

        NewDocument (Err error) ->
            ( Model [] (Just error), Cmd.none )

        NewDocument (Ok document) ->
            ( addViewFragment (FragmentDocument document) model
            , Cmd.none
            )

        GetSearch ->
            ( model, Rest.getSearch )

        NewSearch (Err error) ->
            ( Model [] (Just error), Cmd.none )

        NewSearch (Ok search) ->
            ( addViewFragment (FragmentSearch search) model
            , Cmd.none
            )



-- BlockMouseEnter blockId ->
--     ( updateModelBlocks
--         (\block ->
--             if block.id == blockId then
--                 updateBlockState
--                     (\state -> { state | isHovering = True })
--                     block
--             else
--                 block
--         )
--         model
--     , Cmd.none
--     )
-- BlockMouseLeave blockId ->
--     ( updateModelBlocks
--         (\block ->
--             if block.id == blockId then
--                 updateBlockState
--                     (\state -> { state | isHovering = False })
--                     block
--             else
--                 block
--         )
--         model
--     , Cmd.none
--     )
--
-- BlockClick blockId ->
--     ( updateModelBlocks
--         (\block ->
--             if block.id == blockId then
--                 updateBlockState
--                     (\state -> { state | collapsed = False })
--                     block
--             else
--                 block
--         )
--         model
--     , Cmd.none
--     )
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
