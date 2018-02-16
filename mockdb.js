module.exports = () => {
  const self = {}
  const data = {}

  const set = (k, v) => {
    data[k] = JSON.stringify(v)
  }
  self.set = set

  const get = k => JSON.parse(data[k])
  self.get = get

  const query = searchTerm => {
    return Object.keys(data).filter(id => {
      const value = data[id]

      // console.log(value);

      if (value.type !== 'TERM') return false
      // console.log(value);
      const cleanSearchTerm = searchTerm.toLowerCase()
      const cleanText = value.text.toLowerCase()

      // console.log({ cleanSearchTerm, cleanText });

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
      .filter(term => term.meta.tags.includes('Noun'))
      .map(term => term.id)
  }
  self.nouns = nouns

  return self
}
