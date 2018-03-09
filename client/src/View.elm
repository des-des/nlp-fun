module View exposing (..)

import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (..)


-- VIEW


root : Model -> Html Msg
root { fragments, error } =
    case error of
        Just error ->
            viewError error

        Nothing ->
            span [ class "athelas" ] (List.map viewFragment fragments)


viewFragment : Fragment -> Html Msg
viewFragment fragment =
    case fragment of
        FragmentDocument document ->
            viewDocument document

        FragmentSearch search ->
            viewSearch search


viewDocument : Document -> Html Msg
viewDocument document =
    let
        blockElements =
            List.map viewBlock document.blocks
    in
        div [] blockElements


viewBlock : Block -> Html Msg
viewBlock block =
    div
        [ class "mv3 ph5 hover-bg-black-10" ]
        (List.concatMap viewSubBlock block.subBlocks)


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


trimOffsets : Int -> List Entity -> List Entity
trimOffsets trim entities =
    List.map
        (\entity ->
            { entity
                | offset = entity.offset - trim
            }
        )
        entities


viewTextElement : String -> String -> Html Msg
viewTextElement classString content =
    span [ class classString ] [ text content ]


viewEntity : String -> Html Msg
viewEntity =
    viewTextElement "bg-black-10 hover-bg-light-blue pointer"


viewSearchResultText : String -> Html Msg
viewSearchResultText =
    viewTextElement "bg-yellow"


viewError : Http.Error -> Html Msg
viewError error =
    span [ class "red" ] [ text (toString error) ]


viewSearch : Search -> Html Msg
viewSearch search =
    div [] (List.map viewSearchHit search.hits)


viewSearchHit : SearchHit -> Html Msg
viewSearchHit searchHit =
    let
        isCollapsed =
            searchHit.state.isCollapsed
    in
        case isCollapsed of
            True ->
                viewCollapsedSearchHit searchHit

            False ->
                viewExpandedSearchHit searchHit



--
--
-- viewBlockGroup : BlockGroup -> Html Msg
-- viewBlockGroup blockGroup =
--     let
--         collapsed =
--             blockGroup.state.collapsed
--     in
--         case collapsed of
--             True ->
--                 viewCollapsedSearchHit blockGroup
--
--             False ->
--                 div
--                     [ class "f4" ]
--                     (List.map viewBlock blockGroup.blocks)
--


viewCollapsedSearchHit : SearchHit -> Html Msg
viewCollapsedSearchHit searchHit =
    let
        document =
            searchHit
                |> .document
                |> filterDocumentEntities (\entity -> entity.entityType == "SEARCH_MATCH")

        result =
            document.blocks
                |> List.map (\block -> reduceBlockSearchHits block.subBlocks)
                |> reduceBlockSearchHits
                |> viewCollapsedSubBlock
    in
        div
            []
            (result
                ++ [ span [] [ text "..." ] ]
            )


reduceBlockSearchHitsReducer : SubBlock -> SubBlock -> SubBlock
reduceBlockSearchHitsReducer subBlock acc =
    let
        content =
            acc.content

        entities =
            acc.entities

        mapEnties =
            (\entity ->
                { entity
                    | offset = entity.offset + String.length content
                }
            )

        newEntities =
            subBlock.entities
                |> List.map mapEnties
    in
        SubBlock
            (acc.content ++ subBlock.content)
            (entities ++ newEntities)
            acc.id


reduceBlockSearchHits : List SubBlock -> SubBlock
reduceBlockSearchHits subBlocks =
    List.foldl
        reduceBlockSearchHitsReducer
        (SubBlock "" [] "0")
        subBlocks


viewCollapsedSubBlock : SubBlock -> List (Html Msg)
viewCollapsedSubBlock subBlock =
    let
        searchResultsEntities =
            List.filter
                (\entity -> entity.entityType == "SEARCH_MATCH")
                subBlock.entities
    in
        case searchResultsEntities of
            [] ->
                []

            _ ->
                viewSubBlockSearchHits
                    { subBlock
                        | entities = searchResultsEntities
                    }


viewSubBlockSearchHits : SubBlock -> List (Html Msg)
viewSubBlockSearchHits { content, entities, id } =
    -- should be foldr I think
    List.foldl
        (\entity ->
            (\result ->
                let
                    contextLength =
                        30

                    preText =
                        "... "
                            ++ (String.slice
                                    (entity.offset - contextLength)
                                    (entity.offset)
                                    content
                               )

                    searchTerm =
                        String.slice
                            (entity.offset)
                            (entity.offset + entity.length)
                            content

                    endText =
                        String.slice
                            (entity.offset + entity.length)
                            (entity.offset + entity.length + contextLength)
                            content
                in
                    (List.concat
                        [ result
                        , [ span [] [ text preText ]
                          , span [ class "bg-yellow" ] [ text searchTerm ]
                          , span [] [ text endText ]
                          ]
                        ]
                    )
            )
        )
        []
        entities


viewExpandedSearchHit : SearchHit -> Html Msg
viewExpandedSearchHit searchHit =
    viewDocument searchHit.document
