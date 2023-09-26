fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

description "Advanced Banking System - LB Phone integration"
author "Felis Development"
version      '1.0.4'
repository 'https://github.com/felisDevelopment/fd_banking_app'

dependencies {
    '/server:5104',
    '/onesync',
    'lb-phone',
    'fd_banking',
}

files {
    'web/dist/index.html',
    'web/dist/**/*',
    'web/public/**/*'
}

ui_page 'web/dist/index.html'

client_script "client.lua"
