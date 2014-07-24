bindSharedIcons = ->
        $('.shared-icon').bind 'click', (event) ->
                target = $(event.currentTarget)
                shared = target.data('shared')
                target.data('shared',!shared)
                target.toggleClass("glyphicon-ok",!shared)
                target.toggleClass("glyphicon-remove",shared)
                url = target.data('url')
                $.ajax url,
                        type: 'POST'
                        dataType: 'html'
                        error: (jqXHR, textStatus, errorThrown) ->
                                console.log "AJAX Error: #{ textStatus }"

$ ->
        bindSharedIcons()
