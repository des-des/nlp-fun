module Types exposing (..)

import Http


-- UPDATE


type Msg
    = ArticleIds (Result Http.Error (List String))
    | GetArticleIds
    | NewDocument (Result Http.Error Document)
    | GetDocument String
    | GetSearch
    | NewSearch (Result Http.Error Search)
    | ToggleFragmentCollapsed Int
    | ExpandSearchResult Int Int



-- | BlockMouseEnter String
-- | BlockMouseLeave String
-- | BlockClick String
-- MODEL


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


type alias SearchHitState =
    { isCollapsed : Bool
    }


type alias Document =
    { title : String
    , blocks : List Block
    }


type alias SearchHit =
    { state : SearchHitState
    , index : Int
    , document : Document
    }


type alias Search =
    { searchText : String
    , hits : List SearchHit
    }


type alias FragmentState =
    { isCollapsed : Bool
    }


type FragmentContent
    = DocumentContent Document
    | SearchContent Search


type alias Fragment =
    { index : Int
    , state : FragmentState
    , content : FragmentContent
    }


type alias Model =
    { fragments : List Fragment
    , error : Maybe Http.Error
    }


model : Model
model =
    Model [] Nothing



-- HELPERS


mapFragments : (Fragment -> Fragment) -> Model -> Model
mapFragments mapper model =
    { model | fragments = List.map mapper model.fragments }


updateFragment : (Fragment -> Fragment) -> Int -> Model -> Model
updateFragment update index model =
    { model
        | fragments =
            List.map
                (\fragment ->
                    if fragment.index == index then
                        update fragment
                    else
                        fragment
                )
                model.fragments
    }


updateSearchHit : (SearchHit -> SearchHit) -> Int -> Int -> Model -> Model
updateSearchHit update fragmentIndex searchHitIndex model =
    updateFragment
        (\fragment ->
            case fragment.content of
                DocumentContent document ->
                    fragment

                SearchContent search ->
                    let
                        newHits =
                            List.map
                                (\searchHit ->
                                    if searchHit.index == searchHitIndex then
                                        update searchHit
                                    else
                                        searchHit
                                )
                                search.hits

                        newSearch =
                            { search | hits = newHits }
                    in
                        { fragment
                            | content = SearchContent newSearch
                        }
        )
        fragmentIndex
        model



--
-- updateDocument : (Document -> Document) -> Int -> Model -> Model
-- updateDocument update documentId model =
--     let
--         updateDocument =
--             (\document ->
--                 if document.id == documentId then
--                     update document
--                 else
--                     document
--             )
--     in
--         mapFragments
--             (\fragment ->
--                 case fragment.content of
--                     SearchContent search ->
--                         List.map
--                             (\hit ->
--                                 updateDocument hit.document
--                             )
--                             search.hits
--
--                     DocumentContent document ->
--                         updateDocument document
--             )
--             model


mapFragmentStates : (FragmentState -> FragmentState) -> Model -> Model
mapFragmentStates mapper model =
    { model
        | fragments =
            List.map
                (\fragment -> { fragment | state = mapper fragment.state })
                model.fragments
    }


addViewFragment : FragmentContent -> Model -> Model
addViewFragment fragmentContent model =
    let
        fragments =
            model.fragments

        newFragment =
            Fragment (List.length fragments) (FragmentState False) fragmentContent

        oldFragments =
            fragments
                |> List.map
                    (\fragment ->
                        { fragment | state = (FragmentState True) }
                    )
    in
        { model | fragments = newFragment :: oldFragments }



-- updateBlockGroups : (BlockGroup -> BlockGroup) -> Model -> Model
-- updateBlockGroups updateBlockGroup model =
--     { model | blockGroups = List.map updateBlockGroup model.blockGroups }


updateDocumentBlocks : (Block -> Block) -> Document -> Document
updateDocumentBlocks updateBlock document =
    let
        blocks =
            document
                |> .blocks
                |> List.map updateBlock
    in
        { document | blocks = blocks }


updateDocumentSubBlocks : (SubBlock -> SubBlock) -> Document -> Document
updateDocumentSubBlocks updateSubBlock =
    updateDocumentBlocks
        (\block ->
            let
                subBlocks =
                    block
                        |> .subBlocks
                        |> List.map updateSubBlock
            in
                { block | subBlocks = subBlocks }
        )


filterDocumentEntities : (Entity -> Bool) -> Document -> Document
filterDocumentEntities pred =
    updateDocumentSubBlocks
        (\subBlock ->
            { subBlock | entities = List.filter pred subBlock.entities }
        )



--
--
-- updateModelBlocks : (Block -> Block) -> Model -> Model
-- updateModelBlocks updateBlock model =
--     updateBlockGroups
--         (\blockGroup ->
--             { blockGroup
--                 | blocks = List.map updateBlock blockGroup.blocks
--             }
--         )
--         model


updateBlockState : (BlockState -> BlockState) -> Block -> Block
updateBlockState update block =
    { block | state = update block.state }
