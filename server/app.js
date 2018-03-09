const Koa = require('koa')
const Router = require('koa-router')
const logger = require('koa-logger')
const path = require('path')

const store = require('./mockdb.js')

const app = new Koa()
const api = new Router()

const getArticleData = articleId => {
  const terms = store
    .nouns(articleId)
    .map(termId => store.get(termId))
    .map(term => {
      const parentIndex = store.get(term.parentId).meta.startIndex

      const startIndexAbs = term.meta.startIndex + parentIndex
      const endIndexAbs = startIndexAbs + term.text.length

      return {
        ...term,
        meta: {
          ...term.meta,
          startIndexAbs,
          endIndexAbs
        }
      }
    })
    .sort((a, b) => a.meta.startIndexAbs - b.meta.startIndexAbs)

    return {
      terms,
      text: store.get(articleId).text
    }
}

const getArticleDataV2 = articleId => {
  const blockQuery = articleId => ({
    parentId: articleId,
    type: 'BLOCK'
  })

  const sentenceQuery = blockId => ({
    parentId: blockId,
    type: 'SENTENCE'
  })

  const conceptQuery = sentenceId => ({
    parentId: sentenceId,
    type: 'TERM'
  })

  return {
    id: articleId,
    title: 'The great British Brexit robbery: how our democracy was hijacked',
    type: 'ARTICLE',
    blocks: store
      .query(blockQuery(articleId))
      .map((block, i) => ({
        collapsed: false,
        id: block.id,
        subBlocks: store
          .query(sentenceQuery(block.id))
          .map(sentence => ({
            collapsed: false,
            id: sentence.id,
            content: sentence.text,
            entities: store
            .query(conceptQuery(sentence.id))
            .map(concept => ({
              offset: concept.offset,
              length: concept.length,
              entityType: 'CONCEPT'
            }))
          }))
      }))
  }
}

api.get(
  '/api/v1/articles',
  ctx => {
    ctx.body = store.articles()
  }
)

api.get(
  '/api/v1/articles/:articleId',
  ctx => {
    ctx.body = getArticleData(ctx.params.articleId)
  }
)

api.get(
  '/api/v1/search',
  ctx => {

    console.log(ctx.query);

    const searchText = ctx.query.text

    const articleHit = require('./mocks/document_1.json')

    const result = {
      searchText,
      hits: [{
        index: 0,
        document: {
          ...articleHit,
          blocks: articleHit.blocks
          .map(block => {
            const subBlocks = block.subBlocks.map(subBlock => {

              const newEntities = subBlock.content.includes(searchText)
                ? subBlock.entities.concat({
                  entityType: 'SEARCH_MATCH',
                  offset: subBlock.content.indexOf(searchText),
                  length: searchText.length
                }) : subBlock.entities

              newEntities.sort((a, b) => a.offset < b.offset)

              return {
                ...subBlock,
                entities: newEntities
              }
            })

            return {
              ...block,
              collapsed: true,
              subBlocks
            }
          })
        }
      }]
    }

    ctx.body = result
  }
)

api.get(
  '/api/v2/articles/:articleId',
  ctx => {
    ctx.body = getArticleDataV2(ctx.params.articleId)
  }
)

app
  .use(logger())
  .use(require('koa-static')(path.join(__dirname, 'public')))
  .use(api.routes())
  .use(api.allowedMethods());

module.exports = app
