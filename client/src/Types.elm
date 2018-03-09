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
    , document : Document
    }


type alias Search =
    { searchText : String
    , hits : List SearchHit
    }


type Fragment
    = FragmentDocument Document
    | FragmentSearch Search


type alias Model =
    { fragments : List Fragment
    , error : Maybe Http.Error
    }


model : Model
model =
    Model [] Nothing



-- HELPERS


addViewFragment : Fragment -> Model -> Model
addViewFragment viewFragment model =
    { model | fragments = viewFragment :: model.fragments }



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
