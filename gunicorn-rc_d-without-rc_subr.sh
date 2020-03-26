#!/bin/sh

GUNICORN=/usr/local/bin/gunicorn
ROOT=/var/www/mysite
PID=/var/run/gunicorn.pid
APP=mysite.wsgi:application

stop_app () {
    if [ -f $PID ]; then
        kill $(cat $PID)
    fi
}

start_app () {
    cd $ROOT && $GUNICORN -c $ROOT/gunicorn.conf.py --pid=$PID $APP --daemon
}

status_app () {
    if [ -f $PID ]; then
        echo "Gunicorn is runnig !!!"
    else
        echo "Gunicorn NOT run !!!"
    fi
}

case $1 in
    start)
        start_app
        ;;
    restart)
        stop_app && start_app
        ;;
    stop)
        stop_app
        ;;
    status)
        status_app
        ;;
    *)
        if [ -f $PID ]; then
            echo "Type start, stop, restart"
        else
            cd $ROOT && $GUNICORN -c $ROOT/gunicorn.conf.py --pid=$PID $APP --daemon
        fi
        ;;
esac
