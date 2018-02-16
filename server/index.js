require('env2')('.env')

const nlp = require('compromise')
const fs = require('fs')
const path = require('path')
const htmlToText = require('html-to-text')
const genId = require('uuid/v4')

const store = require('./mockdb.js')()

const nodeTypes = {
  ARTICLE: 'ARTICLE',
  SENTENCE: 'SENTENCE',
  TERM: 'TERM'
}

const setTerm = (db, term, startIndex, parentId) => {
  const id = genId()

  db.set(id, {
    id,
    parentId,
    type: nodeTypes.TERM,
    text: term.text,
    meta: {
      tags: term.tags,
      startIndex
    }
  })
}

const setSentence = (db, sentence, startIndex, parentId) => {
  const id = genId()

  db.set(id, {
    id,
    parentId,
    type: nodeTypes.SENTENCE,
    text: sentence.out('text'),
    meta: {
      startIndex
    }
  })

  let text = sentence.out('text')
  let len = 0

  sentence.out('terms').forEach(term => {
    const termText = term.text
    const startIndex = text.indexOf(termText)
    const textLength = termText.length

    setTerm(db, term, startIndex + len, id)

    text = text.substring(startIndex + textLength)
    len += startIndex + textLength
  })
}

const setArticle = (db, article) => {
  const id = genId()

  db.set(id, {
    id,
    type: nodeTypes.ARTICLE,
    text: article.out('text')
  })

  let text = article.out('text')
  let len = 0

  article.sentences().forEach(sentence => {
    const sentenceText = sentence.out('text')
    const startIndex = text.indexOf(sentenceText)
    const sentenceLength = sentenceText.length



    // console.log({ len });

    setSentence(db, sentence, startIndex + len, id)

    text = text.substring(startIndex + sentenceLength)
    len += startIndex + sentenceLength
  })

  return id
}


const getMockData = fileName => fs.readFileSync(
  path.join(__dirname, 'mock_data.html')
)

const mockData = getMockData('mock_data.html')

const processed = nlp(htmlToText.fromString(mockData))
const articleId = setArticle(store, processed)

const createOutputHtml = html => `
<!DOCTYPE html>
<html>
  <head>
    <style>
      .concept {
        color: blue;
      }
    </style>
  </head>
  <body>
    ${html}
  </body>
</html>
`

const genHtml = (store, documentId) => {
  const terms = store
    .nouns(documentId)
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

  let text = store.get(documentId).text
  const { html } = terms.reduce(({ index, html }, term, i) => {

    // if (i < 10) {
    //   console.log({ index, html, term})
    //   console.log('>>', text.substring(index, term.meta.startIndexAbs))
    // }

    const pre = (index < term.meta.startIndexAbs)
      ? `<span>${text.substring(index, term.meta.startIndexAbs)}</span>`
      : ''

    return {
      html: html + pre +
        `<span class="concept" data-conceptId="${term.id}">${term.text}</span>`,
      index: term.meta.endIndexAbs
    }
  }, { html: '', index: 0 })

  const parsedHtmlDocument = createOutputHtml(html)

  fs.writeFileSync(
    path.join(__dirname, 'parsed_mock_data.html'),
    parsedHtmlDocument
  );

  // console.log(html)
}

genHtml(store, articleId)
