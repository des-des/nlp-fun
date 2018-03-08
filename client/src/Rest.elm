module Rest exposing (..)

import Http
import Json.Decode as Decode
import Types exposing (..)


-- HTTP


withDefault : a -> Decode.Decoder a -> Decode.Decoder a
withDefault default decoder =
    Decode.oneOf
        [ decoder
        , Decode.succeed default
        ]


getArticleIds : Cmd Msg
getArticleIds =
    Http.send
        ArticleIds
        (Http.get "http://localhost:3000/api/v1/articles" decodeArticleIds)


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


getSearchResult : Cmd Msg
getSearchResult =
    let
        url =
            "http://localhost:3000/api/v1/search"
    in
        Http.send NewSearchResult (Http.get url decodeBlockGroups)


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
                        Decode.map
                            (\str ->
                                -- lol what I am doing
                                DocumentMeta (DocumentMetaInfo str)
                            )
                            (Decode.field "title" Decode.string)

                    _ ->
                        -- should be another case here
                        Decode.map
                            (\str ->
                                SearchResultMeta (SearchResultMetaInfo str)
                            )
                            (Decode.field "searchText" Decode.string)
            )


decodeBlockGroup : Decode.Decoder BlockGroup
decodeBlockGroup =
    Decode.map4 BlockGroup
        decodeBlockGroupMeta
        (Decode.succeed { collapsed = True })
        (Decode.field "id" Decode.string)
        (Decode.field "blocks" (Decode.list decodeBlock))


decodeBlockGroups : Decode.Decoder (List BlockGroup)
decodeBlockGroups =
    Decode.list decodeBlockGroup
