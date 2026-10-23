function setup_bosh_proxy {
  set +x
  SSH_TUNNEL_USER=${1}; shift
  SSH_TUNNEL_IP=${1}; shift
  SSH_TUNNEL_PRIVATE_KEY=${1}; shift

  local key_file
  key_file=$(mktemp "${TMPDIR:-/tmp}/bosh-proxy.XXXXXX") || return
  prefix_pattern="-----BEGIN\|-----END\|RSA\|PRIVATE\|PUBLIC"
  printf '%s\n' "$SSH_TUNNEL_PRIVATE_KEY" \
    | sed -e "s/\(${prefix_pattern}\) /\1\t/g" \
    | sed -e "s/ /\n/g" \
    | sed -e "s/\(${prefix_pattern}\)\t/\1 /g" > "${key_file}"

  export BOSH_ALL_PROXY="ssh+socks5://${SSH_TUNNEL_USER}@${SSH_TUNNEL_IP}:22?private-key=${key_file}"
}
