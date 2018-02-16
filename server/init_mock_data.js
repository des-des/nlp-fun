require('env2')('.env')

// https://www.theguardian.com/technology/2017/may/07/the-great-british-brexit-robbery-hijacked-democracy

const Guardian = require('guardian-js')
const fs = require('fs')
const path = require('path')

const save = fileName => (...args) => new Promise((resolve, reject) => {
  const filePath = path.join(__dirname, fileName)
  const cb = (err, res) => {
    if (err) return reject(err)

    resolve(res)
  }

  fs.writeFile(...[filePath, ...args, cb])
})

const api = new Guardian(process.env.GUARDIAN_API_KEY, false)
const html = res => JSON.parse(res.body).response.content.fields.body
const targetArticleId = [
  'technology',
  '2017',
  'may',
  '07',
  'the-great-british-brexit-robbery-hijacked-democracy'
].join('/')

api.item.search(targetArticleId, {
  'show-fields': 'body'
})
  .then(html)
  .then(save('mock_data.html'))
  .catch(e => {
    console.error(e)
  })
