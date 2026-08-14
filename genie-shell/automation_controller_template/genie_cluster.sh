#!/bin/bash

CMD="$1"

if [ "${CMD}" = "start" ]; then

    ansible-playbook /root/deploy_automation_controller.yml --tags "start minikube"

elif [ "${CMD}" = "stop" ]; then
    pkill -f "kubectl proxy" || true
    minikube stop

elif [ "${CMD}" = "status" ]; then

    minikube status

else

    echo "Usage: $0 {start|stop|status}" >&2
    exit 2

fi
