local Translations = {

    client = {
        lang_1 = 'Open Stash',
        lang_2 = 'Destroy Stash',
        lang_3 = 'Confirm Destroy',
        lang_4 = 'Destroy Stash',
        lang_5 = '⛔️ destroying the stash will also destroy the contents!',
        lang_6 = 'Yes',
        lang_7 = 'No',
        lang_8 = 'Destroying Stash',
        lang_9 = 'Max Stashes Reached',
        lang_10 = 'Can\'t Place Here',
    },

    server = {
        lang_1 = 'loading ',
        lang_2 = ' prop with ID: ',
    },

}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

-- Lang:t('client.lang_1')
-- Lang:t('server.lang_1')
