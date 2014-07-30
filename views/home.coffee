bindSharedIcons = ->
        $('.shared-icon').bind 'click', (event) ->
                target = $(event.currentTarget)
                shared = target.data('shared')
                target.data('shared',!shared)
                target.toggleClass("glyphicon-ok",!shared)
                target.toggleClass("glyphicon-remove",shared)
                month = target.data('month')
                year = target.data('year')
                url = target.data('url')
                $.ajax url,
                        type: 'POST'
                        dataType: 'html'
                        error: (jqXHR, textStatus, errorThrown) ->
                                console.log "AJAX Error: #{ textStatus }"
                        success: (data, textStatus, jqXHR) ->
                                #console.log document.URL
                                $('#difference').load('/difference')

                                # $('#shared-balance-' + year + '-' + month).load('/monthly/' + year + '/' + month + '/shared_balance')
                                # $('#shared-income-' + year + '-' + month).load('/monthly/' + year + '/' + month + '/shared_income')
                                # $('#shared-expense-' + year + '-' + month).load('/monthly/' + year + '/' + month + '/shared_expense')

                                # $('#yearly-shared-balance-' + year).load('/yearly/' + year + '/shared_balance')
                                # $('#yearly-shared-income-' + year).load('/yearly/' + year + '/shared_income')
                                # $('#yearly-shared-expense-' + year).load('/yearly/' + year + '/shared_expense')

$ ->
        bindSharedIcons()
