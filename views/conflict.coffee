bindDiscardIcons = ->
        $('.discard-conflict').bind 'click', (event) ->
                target = $(event.currentTarget)
                id = target.data('id')
                $('#conflict-' + id).remove()

$ ->
        bindDiscardIcons()
