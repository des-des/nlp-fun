module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    ( Model [] Nothing
    , getArticleIds
    )



-- MODEL
--
-- type EntityType
--     = Concept


type alias Entity =
    { length : Int
    , offset : Int
    , entityType : String
    }


type alias SubBlockState =
    { collapsed : Bool
    }


type alias SubBlock =
    { content : String
    , entities : List Entity
    , id : String
    }


type alias BlockState =
    { collapsed : Bool
    , isHovering : Bool
    }


type alias Block =
    { subBlocks : List SubBlock
    , id : String
    , state : BlockState
    }


type alias DocumentMetaInfo =
    { title : String }


type alias SearchResultMetaInfo =
    { searchText : String }


type BlockGroupMeta
    = DocumentMeta DocumentMetaInfo
    | SearchResultMeta SearchResultMetaInfo


type alias BlockGroup =
    { meta : BlockGroupMeta
    , id : String
    , blocks : List Block
    }


type alias Model =
    { blockGroups : List BlockGroup
    , error : Maybe Http.Error
    }


type Msg
    = ArticleIds (Result Http.Error (List String))
    | GetArticleIds
    | NewDocument (Result Http.Error BlockGroup)
    | GetDocument String
    | BlockMouseEnter String
    | BlockMouseLeave String
    | BlockClick String


model : Model
model =
    Model [] Nothing


updateBlockGroups : (BlockGroup -> BlockGroup) -> Model -> Model
updateBlockGroups updateBlockGroup model =
    { model | blockGroups = List.map updateBlockGroup model.blockGroups }


updateModelBlocks : (Block -> Block) -> Model -> Model
updateModelBlocks updateBlock model =
    updateBlockGroups
        (\blockGroup ->
            { blockGroup
                | blocks = List.map updateBlock blockGroup.blocks
            }
        )
        model


updateBlockState : (BlockState -> BlockState) -> Block -> Block
updateBlockState update block =
    { block | state = update block.state }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetArticleIds ->
            ( model, getArticleIds )

        ArticleIds (Err error) ->
            ( Model [] (Just error), Cmd.none )

        ArticleIds (Ok ids) ->
            case ids of
                [] ->
                    ( model, Cmd.none )

                articleId :: _ ->
                    ( model, getDocument articleId )

        GetDocument articleId ->
            ( model, getDocument articleId )

        NewDocument (Err error) ->
            ( Model [] (Just error), Cmd.none )

        NewDocument (Ok blockGroup) ->
            ( { model | blockGroups = blockGroup :: model.blockGroups }, Cmd.none )

        BlockMouseEnter blockId ->
            ( updateModelBlocks
                (\block ->
                    if block.id == blockId then
                        updateBlockState
                            (\state -> { state | isHovering = True })
                            block
                    else
                        block
                )
                model
            , Cmd.none
            )

        BlockMouseLeave blockId ->
            ( updateModelBlocks
                (\block ->
                    if block.id == blockId then
                        updateBlockState
                            (\state -> { state | isHovering = False })
                            block
                    else
                        block
                )
                model
            , Cmd.none
            )

        BlockClick blockId ->
            ( updateModelBlocks
                (\block ->
                    if block.id == blockId then
                        updateBlockState
                            (\state -> { state | collapsed = False })
                            block
                    else
                        block
                )
                model
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view { blockGroups, error } =
    case error of
        Just error ->
            viewError error

        Nothing ->
            span [] (List.map viewBlockGroup blockGroups)


viewError : Http.Error -> Html Msg
viewError error =
    span [ class "red" ] [ text (toString error) ]


viewBlockGroup : BlockGroup -> Html Msg
viewBlockGroup { blocks } =
    div [ class "mh7 f3" ] (List.map viewBlock blocks)


viewBlock : Block -> Html Msg
viewBlock { subBlocks, state, id } =
    let
        collapsed =
            state.collapsed

        isHovering =
            state.isHovering
    in
        case collapsed of
            True ->
                div
                    [ class "hover-bg-near-white" ]
                    [ span
                        [ class "mv3 hover-bg-yellow pointer"
                        , onMouseEnter (BlockMouseEnter id)
                        , onMouseLeave (BlockMouseLeave id)
                        , onClick (BlockClick id)
                        ]
                        [ text
                            (case isHovering of
                                True ->
                                    "[expand->]"

                                False ->
                                    "[... ... ...]"
                            )
                        ]
                    ]

            False ->
                div [ class "mv3 hover-bg-near-white" ] (List.concatMap viewSubBlock subBlocks)


viewCollapsedBlock : Html Msg
viewCollapsedBlock =
    span [ class "hover-bg-yellow" ] [ text "[ ... ]" ]


trimOffsets : Int -> List Entity -> List Entity
trimOffsets trim entities =
    List.map
        (\entity ->
            { entity
                | offset = entity.offset - trim
            }
        )
        entities


viewSubBlock : SubBlock -> List (Html Msg)
viewSubBlock { content, entities, id } =
    case entities of
        [] ->
            [ span [] [ text content ] ]

        { offset, length } :: restEntities ->
            case offset of
                0 ->
                    let
                        entityText =
                            String.slice 0 length content

                        rest =
                            viewSubBlock
                                { content = String.dropLeft length content
                                , entities = trimOffsets length restEntities
                                , id = id
                                }
                    in
                        (viewEntity entityText) :: rest

                _ ->
                    let
                        entity =
                            span [] [ text (String.slice 0 offset content) ]

                        rest =
                            viewSubBlock
                                { content = String.dropLeft offset content
                                , entities = trimOffsets offset entities
                                , id = id
                                }
                    in
                        entity :: rest


viewEntity : String -> Html Msg
viewEntity content =
    span
        [ class "bg-black-20 hover-bg-light-blue pointer"
        ]
        [ text content ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- HTTP


withDefault : a -> Decode.Decoder a -> Decode.Decoder a
withDefault default decoder =
    Decode.oneOf
        [ decoder
        , Decode.succeed default
        ]


getArticleIds : Cmd Msg
getArticleIds =
    Http.send ArticleIds (Http.get "http://localhost:3000/api/v1/articles" decodeArticleIds)


decodeArticleIds : Decode.Decoder (List String)
decodeArticleIds =
    Decode.list Decode.string


getDocument : String -> Cmd Msg
getDocument articleId =
    let
        url =
            "http://localhost:3000/api/v2/articles/" ++ articleId
    in
        Http.send NewDocument (Http.get url decodeBlockGroup)


decodeEntity : Decode.Decoder Entity
decodeEntity =
    Decode.map3 Entity
        (Decode.field "length" Decode.int)
        (Decode.field "offset" Decode.int)
        (Decode.field "entityType" Decode.string)


decodeSubBlock : Decode.Decoder SubBlock
decodeSubBlock =
    Decode.map3 SubBlock
        (Decode.field "content" Decode.string)
        (Decode.field "entities" (Decode.list decodeEntity))
        (Decode.field "id" Decode.string)


decodeBlockState : Decode.Decoder BlockState
decodeBlockState =
    Decode.map2 BlockState
        (withDefault False (Decode.field "collapsed" Decode.bool))
        (withDefault False (Decode.field "isHovering" Decode.bool))


decodeBlock : Decode.Decoder Block
decodeBlock =
    Decode.map3 Block
        (Decode.field "subBlocks" (Decode.list decodeSubBlock))
        (Decode.field "id" Decode.string)
        decodeBlockState


decodeBlockGroupMeta : Decode.Decoder BlockGroupMeta
decodeBlockGroupMeta =
    (Decode.field "type" Decode.string)
        |> Decode.andThen
            (\blockGroupType ->
                case blockGroupType of
                    "ARTICLE" ->
                        -- lol I do not know what I am doing this is evil
                        Decode.map (\str -> DocumentMeta (DocumentMetaInfo str))
                            (Decode.field "title" Decode.string)

                    _ ->
                        -- should be another case here
                        Decode.map (\str -> SearchResultMeta (SearchResultMetaInfo str))
                            (Decode.field "searchText" Decode.string)
            )


decodeBlockGroup : Decode.Decoder BlockGroup
decodeBlockGroup =
    Decode.map3 BlockGroup
        decodeBlockGroupMeta
        (Decode.field "id" Decode.string)
        (Decode.field "blocks" (Decode.list decodeBlock))
