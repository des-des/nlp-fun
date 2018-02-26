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
    title: 'some article',
    type: 'ARTICLE',
    blocks: store
      .query(blockQuery(articleId))
      .map((block, i) => ({
        collapsed: (i === 10),
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
  '/api/search',
  ctx => {
    // const {
    //   query: text
    // } = ctx

    const searchText = 'NSA'

    const articleHit = require('./mocks/document_1.json')

    const result = {
      type: 'SEARCH_RESULT',
      searchText,
      hits: [{
        type: 'DOCUMENT',
        blocks: articleHit.blocks
          .map(block => {
            const containsText = block.text.includes(searchText)

            if (!containsText) {
              return {
                ...block,
                collapsed: true
              }
            }

            const subBlocks = block.subBlocks.map(subBlock => {
              const containsText = subBlock.text.includes(searchText)

              if (!containsText) {
                return {
                  ...subBlock,
                  collapsed: true,
                }
              }

              const newEntities = subBlock.entities.concat({
                type: 'SEARCH_MATCH',
                offset: subBlock.text.indexOf(searchText),
                length: searchText.length
              })

              newEntities.sort((a, b) => a.offset < b.offset)

              return {
                ...subblock,
                collapsed: false,
                entities: newEntities
              }
            })

            return {
              ...block,
              collapsed: false,
              subBlocks
            }
          })
      }]
    }
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
