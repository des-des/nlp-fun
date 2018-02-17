(function() {
  var tag = function(tagName) {
    return function(getConfig) {
      return function(data) {
        const config = Object.assign(getConfig(data), { tag: tagName })
        config.attributes = config.attributes || {}
        config.children = config.children || []

        const domNode = document.createElement(config.tag)
        domNode.classList.add(config.classNames)

        Object.keys(config.attributes).forEach(function(attributeName) {
          domNode.setAttribute(attributeName, config.attributes[attributeName])
        })

        if (config.textContent) {
          domNode.textContent = config.textContent
        }

        if (config.innerHtml) {
          domNode.innerHtml = config.innerHtml
        }

        config.children.forEach(child => {
          domNode.appendChild(child)
        })

        return domNode
      }
    }
  }
  var span = tag('span')
  var div = tag('div')

  var createApp = function(domTargetId, getNode) {
    var self = {}

    var update = function(data) {
      var targetNode = document.getElementById(domTargetId)
      var newNode = getNode(data)
      newNode.setAttribute('id', domTargetId)

      targetNode.parentNode.replaceChild(newNode, targetNode)
    }
    self.update = update

    return self
  }

  var request = function(opts, cb) {
    const method = opts.method || 'GET'
    const url = '/api/v1' + opts.url

    var httpRequest = new XMLHttpRequest()

    httpRequest.onreadystatechange = function() {
      if (httpRequest.readyState === XMLHttpRequest.DONE) {
        if (httpRequest.status >= 200 && httpRequest.status < 300) {
          cb(null, httpRequest.responseText)
        } else {
          cb('request failed')
        }
      }
    }

    httpRequest.open(method, url)
    httpRequest.send()
  }

  var textNode = span(function(content) {
    return {
      textContent: content
    }
  })

  var nounNode = span(function(content) {
    return {
      textContent: content,
      classNames: 'noun'
    }
  })

  var brNode = tag('br')(function() { return {} })

  var app = createApp('app', div(function(data) {
    let text = data.text

    var children = data.terms.reduce((acc, term, i) => {
      var children = acc.children
      var index = acc.index

      var pre = []
      if (index < term.meta.startIndexAbs) {
        var parts = text
          .substring(index, term.meta.startIndexAbs)
          .split('\n')

        parts.forEach(function(part, i) {
          pre.push(textNode(part))

          if (i < parts.length - 1) {
            pre.push(brNode())
          }
        })
      }

      var noun = nounNode(term.text)

      return {
        children: children
          .concat(pre)
          .concat(noun),
        index: term.meta.endIndexAbs
      }
    }, { children: [], index: 0 }).children

    return {
      children: children
    }
  }))

  var getArticleData = function(cb) {
    request({ url: '/articles' }, function(err, json) {

      if (err) return cb(err)

      const articleId = JSON.parse(json)[0]
      request({ url: '/articles/' + articleId }, function(err, json) {

        if (err) return cb(err)

        const articleData = JSON.parse(json)
        cb(null, articleData)
      })
    })
  }

  var init = function() {
    getArticleData(function(err, data) {
      if (err) {
        console.error(err)
        return
      }
      app.update(data)
    })
  }

  init()
})()
