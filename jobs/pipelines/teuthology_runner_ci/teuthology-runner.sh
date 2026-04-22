#! /usr/bin/env bash
#
# Schedule and block on a teuthology-suite run. Requires a working teuthology install
# on the agent (e.g. ${TEUTHOLOGY_DIR} with virtualenv) and a matching ceph-ci build.
#
# Inputs (Jenkins or shell env):
#   CEPH_REF            Ceph / ceph-ci branch to test (see teuthology-suite -c)
#   SUITE_NAME          qa/suites name (see teuthology-suite -s), e.g. smoke, rgw
#   TEUTHOLOGY_DIR      teuthology checkout; default: /home/ubuntu/teuthology
#   TEUTHOLOGY_MACHINE_TYPE  Machine type; default: openstack
#   TEUTHOLOGY_PRIORITY      Job priority; default: 200 (see teuthology-suite -p)
#   TEUTHOLOGY_BUILD_NUMBER  For naming; default: $BUILD_NUMBER or "local"
#   TEUTHOLOGY_EXTRA_ARGS   Optional: more flags (e.g. -e results@example.com); word-splits on spaces
#   CEPH_SHA1         Optional: if set, passed as teuthology-suite -S (overrides branch build selection; -c is still set)
#   TEUTHOLOGY_OWNER  Optional: if set, passed as teuthology-suite --owner
#   TEUTHOLOGY_LIMIT  Optional: if set, teuthology-suite -l (applies to any suite: smoke, rgw, …)
#
set -euo pipefail

if [[ -n "${TEUTHOLOGY_DIR:-}" && -f "${TEUTHOLOGY_DIR}/virtualenv/bin/activate" ]]; then
  # shellcheck source=/dev/null
  . "${TEUTHOLOGY_DIR}/virtualenv/bin/activate"
fi

: "${CEPH_REF:=}"
: "${SUITE_NAME:=}"
: "${CEPH_SHA1:=}"
: "${TEUTHOLOGY_OWNER:=}"
: "${TEUTHOLOGY_LIMIT:=}"
: "${TEUTHOLOGY_DIR:=/home/ubuntu/teuthology}"
: "${TEUTHOLOGY_PRIORITY:=200}"
: "${TEUTHOLOGY_MACHINE_TYPE:=openstack}"
: "${TEUTHOLOGY_BUILD_NUMBER:=${BUILD_NUMBER:-local}}"

if [[ -z "${CEPH_REF}" || -z "${SUITE_NAME}" ]]; then
  echo "FATAL: CEPH_REF and SUITE_NAME must be set (Ceph branch and suite, e.g. main / smoke)" >&2
  exit 1
fi

export TEUTHOLOGY_RUN_NAME="teuthology-run-${CEPH_REF}-${TEUTHOLOGY_BUILD_NUMBER}"

echo "Running teuthology-suite: ceph=${CEPH_REF} suite=${SUITE_NAME} machine=${TEUTHOLOGY_MACHINE_TYPE} priority=${TEUTHOLOGY_PRIORITY} run_name=${TEUTHOLOGY_RUN_NAME}"
if [[ -n "${CEPH_SHA1// }" ]]; then
  echo "Using user-provided CEPH_SHA1 (teuthology-suite -S): ${CEPH_SHA1}"
fi
if [[ -n "${TEUTHOLOGY_OWNER// }" ]]; then
  echo "Using TEUTHOLOGY_OWNER (teuthology-suite --owner): ${TEUTHOLOGY_OWNER}"
fi
if [[ -n "${TEUTHOLOGY_LIMIT// }" ]]; then
  echo "Using TEUTHOLOGY_LIMIT (teuthology-suite -l): ${TEUTHOLOGY_LIMIT}"
fi
command -v teuthology-suite

sha_args=()
if [[ -n "${CEPH_SHA1// }" ]]; then
  sha_args=(-S "${CEPH_SHA1}")
fi
owner_args=()
if [[ -n "${TEUTHOLOGY_OWNER// }" ]]; then
  owner_args=(--owner "${TEUTHOLOGY_OWNER}")
fi
limit_args=()
if [[ -n "${TEUTHOLOGY_LIMIT// }" ]]; then
  limit_args=(-l "${TEUTHOLOGY_LIMIT}")
fi

# -y: non-interactive. --wait: block until the scheduled run finishes.
if [[ -n "${TEUTHOLOGY_EXTRA_ARGS:-}" ]]; then
  # shellcheck disable=SC2086
  exec teuthology-suite -v -y \
    -c "${CEPH_REF}" \
    "${sha_args[@]}" \
    -s "${SUITE_NAME}" \
    -m "${TEUTHOLOGY_MACHINE_TYPE}" \
    -p "${TEUTHOLOGY_PRIORITY}" \
    "${limit_args[@]}" \
    "${owner_args[@]}" \
    --wait \
    ${TEUTHOLOGY_EXTRA_ARGS}
else
  exec teuthology-suite -v -y \
    -c "${CEPH_REF}" \
    "${sha_args[@]}" \
    -s "${SUITE_NAME}" \
    -m "${TEUTHOLOGY_MACHINE_TYPE}" \
    -p "${TEUTHOLOGY_PRIORITY}" \
    "${limit_args[@]}" \
    "${owner_args[@]}" \
    --wait
fi
