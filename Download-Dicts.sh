#!/bin/sh

set -euf; unset -v IFS; export LC_ALL=C

echo() {
  printf '[TASK] %s\n' "$*"
}
die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

TAB='	'
tsv_read() {
  # See https://github.com/jakwings/shellcard
  # XXX(performance): tsv_read x x x; tsv_read 2 3 4; tsv_read -r x=y
  IFS='' read -r ${1+"$@"} || return
  while [ 1 -lt "$#" ]; do
    eval "
      case \"\${$1}\" in
        (*'${TAB}'*)
          $2=\"\${$1#*\"${TAB}\"}\"
          $1=\"\${$1%%\"${TAB}\"*}\"
          shift
          ;;
        (*) false
      esac
    " || break
  done
}

download() (
  set -e
  i=50 cont=''
  while [ 0 -le "$(( i -= 1 ))" ]; do
    curl ${MY_PROXY:+--proxy "${MY_PROXY}"} ${cont:+-C -} \
         --fail-early --connect-timeout 5 \
         --user-agent '' --location "$@" \
         || {
              cont=1
              continue
            }
    return 0
  done
  return 1
)

SCRIPT_DIR="$(dirname -- "$0")"

DATA_DIR="$1"

# TODO: get compatibility version
# is there something like /System/Library/Assets/AssetTypeDescriptors.plist ?
VERSION="$2"

XML_URL='https://mesu.apple.com/assets/macos/com_apple_MobileAsset_DictionaryServices_dictionaryOSX/com_apple_MobileAsset_DictionaryServices_dictionaryOSX.xml'
XML_DIR='/System/Library/AssetsV2/com_apple_MobileAsset_DictionaryServices_dictionaryOSX'
XML_FILE="${XML_DIR}/com_apple_MobileAsset_DictionaryServices_dictionaryOSX.xml"

data_xsl="${SCRIPT_DIR}/dicts.xsl"
data_xml="${DATA_DIR}/dicts.xml"
data_tsv="${DATA_DIR}/dicts.tsv"

# fetch the catalog of dictionary assets
if ! [ -e "${data_xml}" ]; then
  mkdir -p "${DATA_DIR}"
  if [ -e "${XML_FILE}" ]; then
    cp "${XML_FILE}" "${data_xml}"
  else
    _="$(download -o "${data_xml}" "${XML_URL}" >&2)" \
      || die "download failed: ${XML_URL}"
  fi
fi

# transform the catalog into a useful table
xsltproc --nonet --path "${SCRIPT_DIR}/utils" \
         "${data_xsl}" "${data_xml}" >"${data_tsv}"

# fetch and extract asset data
while tsv_read vers size algo hash base path bundle name _; do
  if [ x"${vers}" != x"${VERSION}" ]; then
    continue
  fi
  echo "Fetching asset: ${name}"
  url="${base%/}/${path}"
  zipball="${path##*/}"
  asset="${zipball%.zip}.asset"
  if [ -e "${XML_DIR}/${asset}" ] || [ -e "${DATA_DIR}/${asset}" ]; then
    continue
  fi
  zipball="${DATA_DIR}/${zipball}"
  case "${url}" in ('http://updates-http.cdn-apple.com/'*)
    url="https://updates${url#'http://updates-http'}"
  esac
  if ! [ -e "${zipball}" ]; then
    _="$(download -o "${zipball}" "${url}" >&2)" \
      || die "download failed: ${name}"
  else
    _size="$(wc -c <"${zipball}")"
    if [ "${_size}" -ne "${size}" ]; then
      _="$(download -C - -o "${zipball}" "${url}" >&2)" \
        || die "download failed: ${name}"
    fi
  fi
  case "${algo}" in
    (SHA-1) algo=sha1 ;;
    (*) die "unknown checksum algorithm: \"${algo}\""
  esac
  digest="$(openssl dgst -"${algo}" <"${zipball}")"
  hash="$(printf '%s\n' "${hash}" | openssl base64 -d | xxd -p)"
  [ x"${hash}" = x"${digest##*\ }" ] || die "downloaded data corrupted: ${name}"
  mkdir -p "${DATA_DIR}/${asset}"
  unzip -q -o -d "${DATA_DIR}/${asset}" "${zipball}"
done <"${data_tsv}"

# Install Dictionaries
# 1. Run "csrutil disable" in Recovery Mode first!
# 2. This!
# 3. Run "csrutil enable" again if you don't know what you are doing!
printf 'Installing assets to "%s" ? [y/N] ' "${XML_DIR}" >&2
if read -r answer && ! case "${answer}" in ([yY]*) false; esac; then
  set +f
  sudo chown -R _nsurlsessiond:_nsurlsessiond "${DATA_DIR}"/*.asset
  sudo mv -v "${DATA_DIR}"/*.asset "${XML_DIR}"
  echo 'Done!'
else
  echo 'Canceled.'
fi
