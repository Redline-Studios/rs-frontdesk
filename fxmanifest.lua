fx_version 'cerulean'
game 'gta5'

author 'Redline Studios'
description 'rs-frontdesk'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
}

client_script {
    'client/*.lua'
}

server_scripts {
	'server/*.lua',
}


lua54 'yes'