const genId = require('uuid/v4')
const nlp = require('compromise')

const nodeTypes = {
  ARTICLE: 'ARTICLE',
  SENTENCE: 'SENTENCE',
  TERM: 'TERM'
}

const createStore = () => {
  const self = {}
  const data = {}

  const set = (k, v) => {
    data[k] = JSON.stringify(v)
  }
  self.set = set

  const get = k => JSON.parse(data[k])
  self.get = get

  const ingestTerm = (term, startIndex, parentId) => {
    const id = genId()

    set(id, {
      id,
      parentId,
      type: nodeTypes.TERM,
      text: term.out('text'),
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

  const ingest = article => {
    const doc = nlp(article)
    const id = genId()

    set(id, {
      id,
      type: nodeTypes.ARTICLE,
      text: doc.out('text')
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
  self.ingest = ingest

  const query = searchTerm => {
    return Object.keys(data).filter(id => {
      const value = data[id]

      if (value.type !== 'TERM') return false
      const cleanSearchTerm = searchTerm.toLowerCase()
      const cleanText = value.text.toLowerCase()

      return cleanText.includes(cleanSearchTerm)
    })
  }
  self.query = query

  const nouns = articleId => {
    return Object
      .keys(data)
      .map(id => self.get(id))
      .filter(node => node.type === 'TERM')
      .filter(term => self.get(term.parentId).parentId === articleId)
      // .filter(term => term.meta.tags.includes('Noun'))
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
