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
            span
                [ class "athelas f5" ]
                (viewVerticleRule :: (List.map viewFragment fragments))


viewFragment : Fragment -> Html Msg
viewFragment fragment =
    let
        headerText =
            case fragment.content of
                DocumentContent document ->
                    "DOCUMENT"

                SearchContent search ->
                    "SEARCH RESULTS: \"" ++ search.searchText ++ "\""

        header =
            viewFragmentHeader fragment.index headerText fragment.state.isCollapsed

        content =
            case fragment.state.isCollapsed of
                True ->
                    span [] []

                False ->
                    viewFragmentContent fragment.index fragment.content
    in
        div
            []
            [ header
            , div [ class "mh4" ] [ content ]
            , viewVerticleRule
            ]


viewVerticleRule : Html Msg
viewVerticleRule =
    hr [ class "ma3 bb bw1 b--black-10" ] []


viewFragmentHeader : Int -> String -> Bool -> Html Msg
viewFragmentHeader fragmentIndex description isCollapsed =
    let
        toggleIcon =
            if isCollapsed then
                icon "arrow_up"
            else
                icon "arrow_down"
    in
        div
            []
            [ div
                [ class "cf mh4" ]
                [ span [ class "f4" ] [ text description ]
                , span
                    [ class "fr pointer"
                    , onClick (ToggleFragmentCollapsed fragmentIndex)
                    ]
                    [ toggleIcon ]
                ]
            ]


viewFragmentContent : Int -> FragmentContent -> Html Msg
viewFragmentContent fragmentIndex fragmentContent =
    case fragmentContent of
        DocumentContent document ->
            viewDocument document

        SearchContent search ->
            viewSearch fragmentIndex search


viewDocument : Document -> Html Msg
viewDocument document =
    let
        titleElement =
            h1 [ class "f4 fw3" ] [ text document.title ]

        blockElements =
            List.map viewBlock document.blocks
    in
        div [] (titleElement :: blockElements)


viewBlock : Block -> Html Msg
viewBlock block =
    div
        [ class "mv3 ph2" ]
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
    viewTextElement ""


viewSearchResultText : String -> Html Msg
viewSearchResultText =
    viewTextElement "bg-yellow"


viewError : Http.Error -> Html Msg
viewError error =
    span [ class "red" ] [ text (toString error) ]


viewSearch : Int -> Search -> Html Msg
viewSearch fragmentIndex search =
    div [] (List.map (viewSearchHit fragmentIndex) search.hits)


viewSearchHit : Int -> SearchHit -> Html Msg
viewSearchHit fragmentIndex searchHit =
    let
        isCollapsed =
            searchHit.state.isCollapsed
    in
        case isCollapsed of
            True ->
                viewCollapsedSearchHit fragmentIndex searchHit

            False ->
                viewExpandedSearchHit searchHit


subBlockHasSearchHit : SubBlock -> Bool
subBlockHasSearchHit subBlock =
    List.foldl
        (\entity ->
            (\hasSearchHit ->
                if (hasSearchHit) then
                    True
                else
                    entity.entityType == "SEARCH_MATCH"
            )
        )
        False
        subBlock.entities


blockHasSearchHit : Block -> Bool
blockHasSearchHit block =
    List.foldl
        (\subBlock ->
            (\hasSearchHit ->
                if (hasSearchHit) then
                    True
                else
                    subBlockHasSearchHit subBlock
            )
        )
        False
        block.subBlocks


viewCollapsedSearchHit : Int -> SearchHit -> Html Msg
viewCollapsedSearchHit fragmentIndex searchHit =
    let
        sourceDocument =
            searchHit.document

        document =
            sourceDocument
                |> filterDocumentEntities
                    (\entity ->
                        entity.entityType == "SEARCH_MATCH"
                    )

        result =
            document.blocks
                |> List.filter blockHasSearchHit
                |> List.map viewCollapsedSearchHitBlock

        maxHits =
            5

        sliced =
            List.take maxHits result

        numberCut =
            (List.length result) - maxHits

        endTextSpan =
            if numberCut > 0 then
                span [] [ text ("+ " ++ (toString numberCut) ++ " more paragraphs") ]
            else
                span [] [ text "" ]

        title =
            h3
                [ class "f4 mt0" ]
                [ text searchHit.document.title ]
    in
        div
            [ class "ba bw1 pa3 b--light-gray pointer hover-bg-light-gray"
            , onClick (ExpandSearchResult fragmentIndex searchHit.index)
            ]
            (title :: sliced ++ [ endTextSpan ])


viewCollapsedSearchHitBlock : Block -> Html Msg
viewCollapsedSearchHitBlock block =
    let
        subBlocks =
            block.subBlocks
                |> List.filter subBlockHasSearchHit
                |> List.concatMap viewCollapsedSearchHitSubBlock
    in
        div
            [ class "mv2" ]
            ([ span [] [ text "..." ] ]
                ++ subBlocks
                ++ [ span [] [ text "..." ] ]
            )


viewCollapsedSearchHitSubBlock : SubBlock -> List (Html Msg)
viewCollapsedSearchHitSubBlock { content, entities, id } =
    let
        contextLength =
            120

        reduction =
            List.foldl
                (\entity ->
                    (\result ->
                        let
                            nodes =
                                result.nodes

                            lastEntityEndIndex =
                                result.lastEntityEndIndex

                            lastSectionEndIndex =
                                result.lastSectionEndIndex

                            entityOffset =
                                entity.offset

                            nextStartIndex =
                                entity.offset - contextLength

                            preText =
                                if nextStartIndex < lastSectionEndIndex then
                                    String.slice
                                        lastEntityEndIndex
                                        entityOffset
                                        content
                                else
                                    (String.slice
                                        lastEntityEndIndex
                                        lastSectionEndIndex
                                        content
                                    )
                                        ++ "..."
                                        ++ (String.slice
                                                nextStartIndex
                                                entityOffset
                                                content
                                           )

                            preTextSpan =
                                span [] [ text preText ]

                            nextEntityEndIndex =
                                entityOffset + entity.length

                            searchTerm =
                                String.slice
                                    entityOffset
                                    nextEntityEndIndex
                                    content

                            entitySpan =
                                span [ class "bg-yellow" ] [ text searchTerm ]

                            nextSectionEndIndex =
                                entityOffset + contextLength
                        in
                            { nodes = nodes ++ [ preTextSpan, entitySpan ]
                            , lastEntityEndIndex = nextEntityEndIndex
                            , lastSectionEndIndex = nextSectionEndIndex
                            }
                    )
                )
                { nodes = [], lastEntityEndIndex = 0, lastSectionEndIndex = 0 }
                entities

        nodes =
            reduction.nodes

        lastEntityEndIndex =
            reduction.lastEntityEndIndex

        lastSectionEndIndex =
            reduction.lastSectionEndIndex

        contentLength =
            String.length content

        endText =
            if lastSectionEndIndex > contentLength then
                String.slice
                    lastEntityEndIndex
                    contentLength
                    content
            else
                (String.slice
                    lastEntityEndIndex
                    lastSectionEndIndex
                    content
                )
                    ++ "..."

        endTextSpan =
            span [] [ text endText ]
    in
        nodes ++ [ endTextSpan ]


viewExpandedSearchHit : SearchHit -> Html Msg
viewExpandedSearchHit searchHit =
    viewDocument searchHit.document


icon : String -> Html Msg
icon name =
    img [ src ("/icons/" ++ name ++ ".svg") ] []
