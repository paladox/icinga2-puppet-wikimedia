# = Class: icinga2::ircbot
#
# Sets up an ircecho instance that sends icinga alerts to IRC
class icinga2::ircbot(
    $ensure='present'
) {
    if $ensure == 'present' {
        $ircecho_logs   = {
            '/var/log/icinga2/irc.log'             => '#wikimedia-bots-testing',
        }
        $ircecho_nick   = 'icinga2-wm'
        $ircecho_server = 'chat.freenode.net'

        class { '::ircecho':
            ircecho_logs   => $ircecho_logs,
            ircecho_nick   => $ircecho_nick,
            ircecho_server => $ircecho_server,
        }
    }
}
