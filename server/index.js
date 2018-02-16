require('env2')('.env')
const fs = require('fs')
const path = require('path')
const htmlToText = require('html-to-text')

const store = require('./mockdb.js')
const app = require('./app.js')

const mockHtml = fs.readFileSync(path.join(__dirname, 'mock_data.html'))
const mockText = htmlToText.fromString(mockHtml)

store.ingest(mockText)

app.listen(3000)
