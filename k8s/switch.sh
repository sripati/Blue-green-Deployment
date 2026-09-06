#!/usr/bin/env bash
# Blue-green switch helper.
#
#   ./k8s/switch.sh green      # send live traffic to the Enhanced (green) frontend
#   ./k8s/switch.sh blue       # send live traffic to the Basic   (blue)  frontend
#   ./k8s/switch.sh status     # show which colour is currently live
#
# All it does is patch the "version" label in the frontend-service selector.
# Nothing about the backend or MongoDB changes, so no data is lost and the
# previous colour stays running and ready for an instant rollback.
set -euo pipefail

NS="blue-green"
SVC="frontend-service"

current() {
  kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.selector.version}'
}

show_status() {
  echo "Live colour     : $(current)"
  echo "Service selector: $(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.selector}')"
  echo "Active endpoints : $(kubectl -n "$NS" get endpoints "$SVC" -o jsonpath='{.subsets[*].addresses[*].ip}')"
  echo "Serving          : $(kubectl -n "$NS" exec deploy/backend -- wget -qO- http://frontend-service/health 2>/dev/null || echo '(unreachable)')"
}

case "${1:-}" in
  blue|green)
    target="$1"
    echo ">> switching $SVC from '$(current)' to '$target'"
    kubectl -n "$NS" patch service "$SVC" \
      -p "{\"spec\":{\"selector\":{\"app\":\"frontend\",\"version\":\"$target\"}}}"
    sleep 2
    show_status
    ;;
  status|"")
    show_status
    ;;
  *)
    echo "usage: $0 [blue|green|status]" >&2
    exit 1
    ;;
esac
