# /etc/init.d/carbon-{{ type }}-{{ instance_num}}
### BEGIN INIT INFO
# Provides:          carbon-{{ type }}-{{ instance_num }}
# Required-Start:    $network $syslog
# Required-Stop:     $network $syslog
# Should-Start:      $time
# Should-Stop:       $time
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start and stop the carbon {{ type }} daemon
# Description:       carbon-{{ type }} instance {{ instance_num }} daemon
### END INIT INFO

CARBON_{{ type|upper }}={{ install_path }}/bin/carbon-{{ type }}.py
PIDFILE={{ install_path }}/storage/carbon-{{ type }}-{{ instance_num }}.pid

start() {
    echo "Starting carbon-{{ type}} instance {{ instance_num }}..."

    /sbin/start-stop-daemon --start --chuid carbon:carbon --pidfile $PIDFILE --exec $CARBON_{{ type|upper }} -- --pidfile=$PIDFILE --instance {{ instance_num }} start
}

stop() {
    echo "Stopping carbon-{{ type}} instance {{ instance_num }}..."
    /sbin/start-stop-daemon --stop --pidfile $PIDFILE
    while [ -f $PIDFILE  ] ; do sleep 1 ; done
    echo "carbon-{{ type}} instance {{ instance_num }} fully stopped."
}

status() {
    if [ -f $PIDFILE ];
    then
      PID=`cat $PIDFILE`
      echo "carbon-{{ type}} instance {{ instance_num }}: running at PID: ${PID}"
    else
      echo "carbon-{{ type}} instance {{ instance_num }}: not running."
      exit 1
    fi
}


case "$1" in
  start)
    start
    ;;

  stop)
    stop
    ;;

  restart|reload|force-reload)
    stop
    start
    ;;

  status)
    status
    ;;

  *)
    echo "Usage: /etc/init.d/carbon-{{ type }}-{{ instance_num }} {start|stop|reload|force-reload|restart|status}"
    exit 1

esac

exit 0
