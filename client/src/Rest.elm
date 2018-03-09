module Rest exposing (..)

import Http
import Json.Decode as Decode
import Types exposing (..)


-- HTTP


getArticleIds : Cmd Msg
getArticleIds =
    Http.send
        ArticleIds
        (Http.get "http://localhost:3000/api/v1/articles" decodeArticleIds)


getDocument : String -> Cmd Msg
getDocument articleId =
    let
        url =
            "http://localhost:3000/api/v2/articles/" ++ articleId
    in
        Http.send NewDocument (Http.get url decodeDocument)


getSearch : Cmd Msg
getSearch =
    let
        url =
            "http://localhost:3000/api/v1/search"
    in
        Http.send NewSearch (Http.get url decodeSearch)



-- DECODERS


withDefault : a -> Decode.Decoder a -> Decode.Decoder a
withDefault default decoder =
    Decode.oneOf
        [ decoder
        , Decode.succeed default
        ]


decodeArticleIds : Decode.Decoder (List String)
decodeArticleIds =
    Decode.list Decode.string


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


decodeDocument : Decode.Decoder Document
decodeDocument =
    Decode.map2 Document
        (Decode.field "title" Decode.string)
        (Decode.field "blocks" (Decode.list decodeBlock))


decodeSearchHit : Decode.Decoder SearchHit
decodeSearchHit =
    Decode.map2 SearchHit
        (Decode.succeed (SearchHitState True))
        (Decode.field "document" decodeDocument)


decodeSearch : Decode.Decoder Search
decodeSearch =
    Decode.map2 Search
        (Decode.field "searchText" Decode.string)
        (Decode.field "hits" (Decode.list decodeSearchHit))
