#!/usr/bin/env bash
#
# End-to-end smoke test for the svn-docker image.
#
# It expects a container started from the built image with ports 80 and 3690
# published, and checks Apache/WebDAV, svnserve, the access-control file and
# the SVNADMIN web UI.
#
# Usage:
#   CONTAINER=svn-ci BASE_URL=http://127.0.0.1:8080 \
#     SVN_URL=svn://127.0.0.1:3690 bash .github/scripts/smoke-test.sh

set -euo pipefail

CONTAINER="${CONTAINER:-svn-ci}"
BASE_URL="${BASE_URL:-http://127.0.0.1:8080}"
SVN_URL="${SVN_URL:-svn://127.0.0.1:3690}"
SVN_USER="${SVN_USER:-ci-user}"
SVN_PASSWORD="${SVN_PASSWORD:-ci-password}"
REPO="${REPO:-ci-repo}"

step() { printf '\n==> %s\n' "$1"; }
pass() { printf '    ok: %s\n' "$1"; }
die() {
    printf '\nFAILED: %s\n' "$1" >&2
    exit 1
}

http_code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }

svn_cmd() {
    svn "$@" --non-interactive --no-auth-cache \
        --username "$SVN_USER" --password "$SVN_PASSWORD"
}

container_running() {
    local running
    running="$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null || true)"
    [ "$running" = "true" ]
}

step "Waiting for Apache to answer on ${BASE_URL}"
ready=false
for _ in $(seq 1 60); do
    container_running || die "container ${CONTAINER} is not running"
    code="$(http_code "${BASE_URL}/svn/" || true)"
    if [ "$code" = "401" ]; then
        ready=true
        break
    fi
    sleep 1
done
[ "$ready" = "true" ] || die "Apache did not answer with 401 on ${BASE_URL}/svn/"
pass "Apache is listening"

step "Anonymous WebDAV access is rejected"
headers="$(curl -s -D - -o /dev/null "${BASE_URL}/svn/")"
printf '%s\n' "$headers" | grep -qi '^WWW-Authenticate: Basic' ||
    die "missing WWW-Authenticate: Basic header"
pass "HTTP Basic authentication is enforced"

step "Creating test repository and user inside the container"
docker exec "$CONTAINER" svnadmin create "/home/svn/${REPO}"
docker exec "$CONTAINER" htpasswd -bc /etc/subversion/passwd "$SVN_USER" "$SVN_PASSWORD"
pass "repository /home/svn/${REPO} and user ${SVN_USER} created"

step "Custom protocol (svn://) serves the repository"
served=false
for _ in $(seq 1 15); do
    if svn info "${SVN_URL}/${REPO}" >/dev/null 2>&1; then
        served=true
        break
    fi
    sleep 1
done
[ "$served" = "true" ] || die "svn info ${SVN_URL}/${REPO} failed"
pass "svnserve is serving ${SVN_URL}/${REPO}"

step "WebDAV serves the repository to authenticated users"
code="$(http_code -u "${SVN_USER}:${SVN_PASSWORD}" "${BASE_URL}/svn/${REPO}/")"
[ "$code" = "200" ] || die "expected HTTP 200, got ${code}"
pass "authenticated read works over HTTP"

step "Checkout, then verify the default access-control file is read-only"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

svn_cmd checkout "${BASE_URL}/svn/${REPO}/" "$workdir/wc" >/dev/null
printf 'hello from ci\n' >"$workdir/wc/hello.txt"
svn_cmd add "$workdir/wc/hello.txt" >/dev/null

if svn_cmd commit "$workdir/wc" -m "ci: add hello.txt" >/dev/null 2>&1; then
    die "commit succeeded although subversion-access-control grants read-only access"
fi
pass "commit is rejected by the default access-control rules"

step "Granting write access to ${SVN_USER} and committing"
printf '[groups]\n\n[/]\n* = r\n%s = rw\n' "$SVN_USER" |
    docker exec -i "$CONTAINER" tee /etc/subversion/subversion-access-control >/dev/null

svn_cmd commit "$workdir/wc" -m "ci: add hello.txt" >/dev/null
svn_cmd cat "${BASE_URL}/svn/${REPO}/hello.txt" | grep -qx 'hello from ci' ||
    die "committed content could not be read back"
pass "commit and read-back over HTTP work"

step "SVNADMIN web UI is served"
code="$(http_code "${BASE_URL}/svnadmin/index.php")"
case "$code" in
    200 | 301 | 302 | 303) ;;
    *) die "expected HTTP 2xx/3xx from /svnadmin/index.php, got ${code}" ;;
esac
pass "SVNADMIN answers on /svnadmin/index.php"

printf '\nAll smoke tests passed.\n'
