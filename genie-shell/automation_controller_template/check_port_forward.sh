#!/bin/bash

readonly DASHBOARD_PATTERN="kubectl port-forward svc/awx-service"
readonly POSTGRES_PATTERN="kubectl port-forward svc/awx-postgres"
readonly PROXY_PATTERN="kubectl proxy --address=0.0.0.0"
dashboard_failures=0

start_dashboard_forward() {
    nohup kubectl port-forward svc/awx-service -n awx --address 0.0.0.0 80:80 >> /var/log/genie-port-forward.log 2>&1 &
}

start_postgres_forward() {
    nohup kubectl port-forward svc/awx-postgres -n awx --address 0.0.0.0 5432:5432 >> /var/log/genie-port-forward.log 2>&1 &
}

start_kubernetes_proxy() {
    nohup kubectl proxy --address=0.0.0.0 --disable-filter=true >> /var/log/genie-port-forward.log 2>&1 &
}

while true; do
    if pgrep -f "${DASHBOARD_PATTERN}" > /dev/null; then
        if curl --silent --fail --max-time 5 --output /dev/null http://localhost:80/api/v2/ping/; then
            dashboard_failures=0
        else
            dashboard_failures=$((dashboard_failures + 1))
        fi

        if [ "${dashboard_failures}" -ge 3 ]; then
            pkill -f "${DASHBOARD_PATTERN}" || true
            dashboard_failures=0
            sleep 2
            start_dashboard_forward
        fi
    else
        dashboard_failures=0
        start_dashboard_forward
    fi

    if ! pgrep -f "${POSTGRES_PATTERN}" > /dev/null; then
        start_postgres_forward
    fi

    if ! pgrep -f "${PROXY_PATTERN}" > /dev/null; then
        start_kubernetes_proxy
    fi

    sleep 5
done
