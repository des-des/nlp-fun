if (!window.dpx) window.dpx = {}

; (function () { window.dpx.searchbar = function ( id ) {

    var self = {}
    var listeners = []
    var listenersCount = 0
    var lastText = ''
    var inputNode = document.getElementById( id || 'search' )

    nlp.plugin({
        name: "xpx",
        words: {
            filter: "Verb"
        }
    })

    var pipe = function () {

        var args = arguments

        return function( x ) {

            var i
            var result = x

            for ( i = 0; i < args.length; i++ ) {

              result = args[i]( result )
            }


            return result
        }
    }


    var subscribe = function ( eventType, actionName, f ) {

        var listenerIndex = listenersCount

        listeners.push({
            actionName: actionName,
            f: f,
            index: listenerIndex,
            eventType: eventType
        })

        listenersCount++

        return listenerIndex
    }
    self.subscribe = subscribe


    var unsubscribe = function ( listenerIndex ) {

      listeners = listeners.filter( function ( listener ) {

          return lister.listenerIndex !== listenerIndex
      } )
    }
    self.unsubscribe = unsubscribe


    var emit = function ( eventType, actionName, text ) {

        listeners
            .filter ( function ( listener ) {

                return listener.actionName === actionName
            } )
            .filter ( function ( listener ) {

              return listener.eventType === eventType
            } )
            .forEach ( function ( listener ) {

              listener.f(text)
            } )
    }

    var isVerb = function ( term ) {

        if ( term === undefined || term.tags === undefined ) return false

        var result = false
        var i

        for ( i = 0; i < term.tags.length; i++ ) {

          if (term.tags[i] === 'Verb') {

            result = true

            break
          }
        }

        return result
    }


    var processEvent = pipe (

        function( event ) {

            return {
              terms: nlp(event.text).out('terms'),
              type: event.type
            }
        },

        function ( event ) {

            var terms = event.terms
            var eventType = event.type

            var actionName = terms[0]
                .text
                .toUpperCase()

            var details = terms
                .slice(1)
                .map(function ( term ) {

                    return term.text
                })
                .join( ' ' )
                .trim()


            if ( isVerb ( terms[0] ) ) {
                emit ( eventType, actionName, details )
            }
        }
    )

    inputNode.addEventListener( 'keyup', function( event ) {

        var text = event.target.value

        var enterPressed = event.keyCode === 13

        if (enterPressed) {
          processEvent( {
            text: text,
            type: 'SUBMIT'
          } )

          return
        }

        if (lastText !== text) {
          processEvent( {
            text: text,
            type: 'INPUT'
          } )
        }

        lastText = text
    } )

    return self
} }() )
