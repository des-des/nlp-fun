const Koa = require('koa')
const Router = require('koa-router')
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

app
  .use(require('koa-static')(path.join(__dirname, 'public')))
  .use(api.routes())
  .use(api.allowedMethods());

module.exports = app
