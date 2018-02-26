const genId = require('uuid/v4')
const nlp = require('compromise')

const nodeTypes = {
  ARTICLE: 'ARTICLE',
  BLOCK: 'BLOCK',
  SENTENCE: 'SENTENCE',
  TERM: 'TERM'
}

const createStore = () => {
  const self = {}
  const data = {}


  const set = (k, v) => {
    data[k] = v
  }
  self.set = set

  const get = k => data[k]
  self.get = get

  const keys = () => Object.keys(data)

  const values = () => keys().map(get)

  const query = query => {
    const isMatch = record => Object
      .keys(query)
      .reduce((isMatch, searchKey) => {
        if (!isMatch) return isMatch

        return query[searchKey] === record[searchKey]
      }, true)

    return keys()
      .map(get)
      .filter(isMatch)
  }
  self.query = query

  const ingestTerm = (term, startIndex, parentId) => {
    const id = genId()
    const text = term.out('text')

    set(id, {
      id,
      parentId,
      type: nodeTypes.TERM,
      text: text,
      offset: startIndex,
      length: text.length,
      meta: {
        // tags: term.tags,
        startIndex
      }
    })
  }

  const ingestSentence = (sentence, startIndex, parentId) => {
    const id = genId()

    set(id, {
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

    sentence.nouns().forEach((noun, i) => {
      const termText = noun.out('text')
      const startIndex = text.indexOf(termText)
      const textLength = termText.length

      ingestTerm(noun, startIndex + len, id)

      text = text.substring(startIndex + textLength)
      len += startIndex + textLength
    })
  }

  const ingestBlock = (block, startIndex, parentId) => {
    const doc = nlp(block)
    const id = genId()

    set(id, {
      id,
      parentId,
      type: nodeTypes.BLOCK,
      text: doc.out('text'),
      meta: {
        startIndex
      }
    })

    let text = doc.out('text')
    let len = 0

    doc.sentences().forEach(sentence => {
      const sentenceText = sentence.out('text')
      const startIndex = text.indexOf(sentenceText)
      const sentenceLength = sentenceText.length

      ingestSentence(sentence, startIndex + len, id)

      text = text.substring(startIndex + sentenceLength)
      len += startIndex + sentenceLength
    })

    return id
  }
  self.ingestBlock = ingestBlock

  const ingest = article => {
    const id = genId()

    set(id, {
      id,
      type: nodeTypes.ARTICLE,
      text: article
    })

    let text = article
    let len = 0

    article.split('\n').forEach(blockText => {
      const startIndex = text.indexOf(blockText)
      const blockLength = blockText.length

      ingestBlock(blockText, startIndex + len, id)

      text = text.substring(startIndex + blockLength)
      len += startIndex + blockLength
    })

    return id
  }
  self.ingest = ingest

  const nouns = articleId => {
    return Object
      .keys(data)
      .map(id => self.get(id))
      .filter(node => node.type === 'TERM')
      .filter(term => self.get(term.parentId).parentId === articleId)
      .map(term => term.id)
  }
  self.nouns = nouns

  const articles = () => {
    return Object
      .keys(data)
      .map(id => self.get(id))
      .filter(node => node.type === nodeTypes.ARTICLE)
      .map(node => node.id)
  }
  self.articles = articles

  return self
}

module.exports = createStore()
