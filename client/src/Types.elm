module Types exposing (..)

import Http


-- UPDATE


type Msg
    = ArticleIds (Result Http.Error (List String))
    | GetArticleIds
    | NewDocument (Result Http.Error BlockGroup)
    | GetDocument String
    | GetSearchResult
    | NewSearchResult (Result Http.Error (List BlockGroup))
    | BlockMouseEnter String
    | BlockMouseLeave String
    | BlockClick String



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


type alias DocumentMetaInfo =
    { title : String }


type alias SearchResultMetaInfo =
    { searchText : String }


type BlockGroupMeta
    = DocumentMeta DocumentMetaInfo
    | SearchResultMeta SearchResultMetaInfo


type alias BlockGroupState =
    { collapsed : Bool
    }


type alias BlockGroup =
    { meta : BlockGroupMeta
    , state : BlockGroupState
    , id : String
    , blocks : List Block
    }


type alias Model =
    { blockGroups : List BlockGroup
    , error : Maybe Http.Error
    }


model : Model
model =
    Model [] Nothing



-- HELPERS


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
