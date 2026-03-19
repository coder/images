a#!/bin/sh
a# shellcheck shell=dash
a
a# This is just a little script that can be downloaded from the internet to
a# install rustup. It just does platform detection, downloads the installer
a# and runs it.
a
a# It runs on Unix shells like {a,ba,da,k,z}sh. It uses the common `local`
a# extension. Note: Most shells limit `local` to 1 var per line, contra bash.
a
aif [ "$KSH_VERSION" = 'Version JM 93t+ 2010-03-05' ]; then
a    # The version of ksh93 that ships with many illumos systems does not
a    # support the "local" extension.  Print a message rather than fail in
a    # subtle ways later on:
a    echo 'rustup does not work with this ksh93 version; please try bash!' >&2
a    exit 1
afi
a
a
aset -u
a
a# If RUSTUP_UPDATE_ROOT is unset or empty, default it.
aRUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-https://static.rust-lang.org/rustup}"
a
a#XXX: If you change anything here, please make the same changes in setup_mode.rs
ausage() {
a    cat 1>&2 <<EOF
arustup-init 1.25.1 (48d233f65 2022-07-12)
aThe installer for rustup
a
aUSAGE:
a    rustup-init [FLAGS] [OPTIONS]
a
aFLAGS:
a    -v, --verbose           Enable verbose output
a    -q, --quiet             Disable progress output
a    -y                      Disable confirmation prompt.
a        --no-modify-path    Don't configure the PATH environment variable
a    -h, --help              Prints help information
a    -V, --version           Prints version information
a
aOPTIONS:
a        --default-host <default-host>              Choose a default host triple
a        --default-toolchain <default-toolchain>    Choose a default toolchain to install
a        --default-toolchain none                   Do not install any toolchains
a        --profile [minimal|default|complete]       Choose a profile
a    -c, --component <components>...                Component name to also install
a    -t, --target <targets>...                      Target name to also install
aEOF
a}
a
amain() {
a    downloader --check
a    need_cmd uname
a    need_cmd mktemp
a    need_cmd chmod
a    need_cmd mkdir
a    need_cmd rm
a    need_cmd rmdir
a
a    get_architecture || return 1
a    local _arch="$RETVAL"
a    assert_nz "$_arch" "arch"
a
a    local _ext=""
a    case "$_arch" in
a        *windows*)
a            _ext=".exe"
a            ;;
a    esac
a
a    local _url="${RUSTUP_UPDATE_ROOT}/dist/${_arch}/rustup-init${_ext}"
a
a    local _dir
a    _dir="$(ensure mktemp -d)"
a    local _file="${_dir}/rustup-init${_ext}"
a
a    local _ansi_escapes_are_valid=false
a    if [ -t 2 ]; then
a        if [ "${TERM+set}" = 'set' ]; then
a            case "$TERM" in
a                xterm*|rxvt*|urxvt*|linux*|vt*)
a                    _ansi_escapes_are_valid=true
a                ;;
a            esac
a        fi
a    fi
a
a    # check if we have to use /dev/tty to prompt the user
a    local need_tty=yes
a    for arg in "$@"; do
a        case "$arg" in
a            --help)
a                usage
a                exit 0
a                ;;
a            *)
a                OPTIND=1
a                if [ "${arg%%--*}" = "" ]; then
a                    # Long option (other than --help);
a                    # don't attempt to interpret it.
a                    continue
a                fi
a                while getopts :hy sub_arg "$arg"; do
a                    case "$sub_arg" in
a                        h)
a                            usage
a                            exit 0
a                            ;;
a                        y)
a                            # user wants to skip the prompt --
a                            # we don't need /dev/tty
a                            need_tty=no
a                            ;;
a                        *)
a                            ;;
a                        esac
a                done
a                ;;
a        esac
a    done
a
a    if $_ansi_escapes_are_valid; then
a        printf "\33[1minfo:\33[0m downloading installer\n" 1>&2
a    else
a        printf '%s\n' 'info: downloading installer' 1>&2
a    fi
a
a    ensure mkdir -p "$_dir"
a    ensure downloader "$_url" "$_file" "$_arch"
a    ensure chmod u+x "$_file"
a    if [ ! -x "$_file" ]; then
a        printf '%s\n' "Cannot execute $_file (likely because of mounting /tmp as noexec)." 1>&2
a        printf '%s\n' "Please copy the file to a location where you can execute binaries and run ./rustup-init${_ext}." 1>&2
a        exit 1
a    fi
a
a    if [ "$need_tty" = "yes" ] && [ ! -t 0 ]; then
a        # The installer is going to want to ask for confirmation by
a        # reading stdin.  This script was piped into `sh` though and
a        # doesn't have stdin to pass to its children. Instead we're going
a        # to explicitly connect /dev/tty to the installer's stdin.
a        if [ ! -t 1 ]; then
a            err "Unable to run interactively. Run with -y to accept defaults, --help for additional options"
a        fi
a
a        ignore "$_file" "$@" < /dev/tty
a    else
a        ignore "$_file" "$@"
a    fi
a
a    local _retval=$?
a
a    ignore rm "$_file"
a    ignore rmdir "$_dir"
a
a    return "$_retval"
a}
a
acheck_proc() {
a    # Check for /proc by looking for the /proc/self/exe link
a    # This is only run on Linux
a    if ! test -L /proc/self/exe ; then
a        err "fatal: Unable to find /proc/self/exe.  Is /proc mounted?  Installation cannot proceed without /proc."
a    fi
a}
a
aget_bitness() {
a    need_cmd head
a    # Architecture detection without dependencies beyond coreutils.
a    # ELF files start out "\x7fELF", and the following byte is
a    #   0x01 for 32-bit and
a    #   0x02 for 64-bit.
a    # The printf builtin on some shells like dash only supports octal
a    # escape sequences, so we use those.
a    local _current_exe_head
a    _current_exe_head=$(head -c 5 /proc/self/exe )
a    if [ "$_current_exe_head" = "$(printf '\177ELF\001')" ]; then
a        echo 32
a    elif [ "$_current_exe_head" = "$(printf '\177ELF\002')" ]; then
a        echo 64
a    else
a        err "unknown platform bitness"
a    fi
a}
a
ais_host_amd64_elf() {
a    need_cmd head
a    need_cmd tail
a    # ELF e_machine detection without dependencies beyond coreutils.
a    # Two-byte field at offset 0x12 indicates the CPU,
a    # but we're interested in it being 0x3E to indicate amd64, or not that.
a    local _current_exe_machine
a    _current_exe_machine=$(head -c 19 /proc/self/exe | tail -c 1)
a    [ "$_current_exe_machine" = "$(printf '\076')" ]
a}
a
aget_endianness() {
a    local cputype=$1
a    local suffix_eb=$2
a    local suffix_el=$3
a
a    # detect endianness without od/hexdump, like get_bitness() does.
a    need_cmd head
a    need_cmd tail
a
a    local _current_exe_endianness
a    _current_exe_endianness="$(head -c 6 /proc/self/exe | tail -c 1)"
a    if [ "$_current_exe_endianness" = "$(printf '\001')" ]; then
a        echo "${cputype}${suffix_el}"
a    elif [ "$_current_exe_endianness" = "$(printf '\002')" ]; then
a        echo "${cputype}${suffix_eb}"
a    else
a        err "unknown platform endianness"
a    fi
a}
a
aget_architecture() {
a    local _ostype _cputype _bitness _arch _clibtype
a    _ostype="$(uname -s)"
a    _cputype="$(uname -m)"
a    _clibtype="gnu"
a
a    if [ "$_ostype" = Linux ]; then
a        if [ "$(uname -o)" = Android ]; then
a            _ostype=Android
a        fi
a        if ldd --version 2>&1 | grep -q 'musl'; then
a            _clibtype="musl"
a        fi
a    fi
a
a    if [ "$_ostype" = Darwin ] && [ "$_cputype" = i386 ]; then
a        # Darwin `uname -m` lies
a        if sysctl hw.optional.x86_64 | grep -q ': 1'; then
a            _cputype=x86_64
a        fi
a    fi
a
a    if [ "$_ostype" = SunOS ]; then
a        # Both Solaris and illumos presently announce as "SunOS" in "uname -s"
a        # so use "uname -o" to disambiguate.  We use the full path to the
a        # system uname in case the user has coreutils uname first in PATH,
a        # which has historically sometimes printed the wrong value here.
a        if [ "$(/usr/bin/uname -o)" = illumos ]; then
a            _ostype=illumos
a        fi
a
a        # illumos systems have multi-arch userlands, and "uname -m" reports the
a        # machine hardware name; e.g., "i86pc" on both 32- and 64-bit x86
a        # systems.  Check for the native (widest) instruction set on the
a        # running kernel:
a        if [ "$_cputype" = i86pc ]; then
a            _cputype="$(isainfo -n)"
a        fi
a    fi
a
a    case "$_ostype" in
a
a        Android)
a            _ostype=linux-android
a            ;;
a
a        Linux)
a            check_proc
a            _ostype=unknown-linux-$_clibtype
a            _bitness=$(get_bitness)
a            ;;
a
a        FreeBSD)
a            _ostype=unknown-freebsd
a            ;;
a
a        NetBSD)
a            _ostype=unknown-netbsd
a            ;;
a
a        DragonFly)
a            _ostype=unknown-dragonfly
a            ;;
a
a        Darwin)
a            _ostype=apple-darwin
a            ;;
a
a        illumos)
a            _ostype=unknown-illumos
a            ;;
a
a        MINGW* | MSYS* | CYGWIN* | Windows_NT)
a            _ostype=pc-windows-gnu
a            ;;
a
a        *)
a            err "unrecognized OS type: $_ostype"
a            ;;
a
a    esac
a
a    case "$_cputype" in
a
a        i386 | i486 | i686 | i786 | x86)
a            _cputype=i686
a            ;;
a
a        xscale | arm)
a            _cputype=arm
a            if [ "$_ostype" = "linux-android" ]; then
a                _ostype=linux-androideabi
a            fi
a            ;;
a
a        armv6l)
a            _cputype=arm
a            if [ "$_ostype" = "linux-android" ]; then
a                _ostype=linux-androideabi
a            else
a                _ostype="${_ostype}eabihf"
a            fi
a            ;;
a
a        armv7l | armv8l)
a            _cputype=armv7
a            if [ "$_ostype" = "linux-android" ]; then
a                _ostype=linux-androideabi
a            else
a                _ostype="${_ostype}eabihf"
a            fi
a            ;;
a
a        aarch64 | arm64)
a            _cputype=aarch64
a            ;;
a
a        x86_64 | x86-64 | x64 | amd64)
a            _cputype=x86_64
a            ;;
a
a        mips)
a            _cputype=$(get_endianness mips '' el)
a            ;;
a
a        mips64)
a            if [ "$_bitness" -eq 64 ]; then
a                # only n64 ABI is supported for now
a                _ostype="${_ostype}abi64"
a                _cputype=$(get_endianness mips64 '' el)
a            fi
a            ;;
a
a        ppc)
a            _cputype=powerpc
a            ;;
a
a        ppc64)
a            _cputype=powerpc64
a            ;;
a
a        ppc64le)
a            _cputype=powerpc64le
a            ;;
a
a        s390x)
a            _cputype=s390x
a            ;;
a        riscv64)
a            _cputype=riscv64gc
a            ;;
a        *)
a            err "unknown CPU type: $_cputype"
a
a    esac
a
a    # Detect 64-bit linux with 32-bit userland
a    if [ "${_ostype}" = unknown-linux-gnu ] && [ "${_bitness}" -eq 32 ]; then
a        case $_cputype in
a            x86_64)
a                if [ -n "${RUSTUP_CPUTYPE:-}" ]; then
a                    _cputype="$RUSTUP_CPUTYPE"
a                else {
a                    # 32-bit executable for amd64 = x32
a                    if is_host_amd64_elf; then {
a                         echo "This host is running an x32 userland; as it stands, x32 support is poor," 1>&2
a                         echo "and there isn't a native toolchain -- you will have to install" 1>&2
a                         echo "multiarch compatibility with i686 and/or amd64, then select one" 1>&2
a                         echo "by re-running this script with the RUSTUP_CPUTYPE environment variable" 1>&2
a                         echo "set to i686 or x86_64, respectively." 1>&2
a                         echo 1>&2
a                         echo "You will be able to add an x32 target after installation by running" 1>&2
a                         echo "  rustup target add x86_64-unknown-linux-gnux32" 1>&2
a                         exit 1
a                    }; else
a                        _cputype=i686
a                    fi
a                }; fi
a                ;;
a            mips64)
a                _cputype=$(get_endianness mips '' el)
a                ;;
a            powerpc64)
a                _cputype=powerpc
a                ;;
a            aarch64)
a                _cputype=armv7
a                if [ "$_ostype" = "linux-android" ]; then
a                    _ostype=linux-androideabi
a                else
a                    _ostype="${_ostype}eabihf"
a                fi
a                ;;
a            riscv64gc)
a                err "riscv64 with 32-bit userland unsupported"
a                ;;
a        esac
a    fi
a
a    # Detect armv7 but without the CPU features Rust needs in that build,
a    # and fall back to arm.
a    # See https://github.com/rust-lang/rustup.rs/issues/587.
a    if [ "$_ostype" = "unknown-linux-gnueabihf" ] && [ "$_cputype" = armv7 ]; then
a        if ensure grep '^Features' /proc/cpuinfo | grep -q -v neon; then
a            # At least one processor does not have NEON.
a            _cputype=arm
a        fi
a    fi
a
a    _arch="${_cputype}-${_ostype}"
a
a    RETVAL="$_arch"
a}
a
asay() {
a    printf 'rustup: %s\n' "$1"
a}
a
aerr() {
a    say "$1" >&2
a    exit 1
a}
a
aneed_cmd() {
a    if ! check_cmd "$1"; then
a        err "need '$1' (command not found)"
a    fi
a}
a
acheck_cmd() {
a    command -v "$1" > /dev/null 2>&1
a}
a
aassert_nz() {
a    if [ -z "$1" ]; then err "assert_nz $2"; fi
a}
a
a# Run a command that should never fail. If the command fails execution
a# will immediately terminate with an error showing the failing
a# command.
aensure() {
a    if ! "$@"; then err "command failed: $*"; fi
a}
a
a# This is just for indicating that commands' results are being
a# intentionally ignored. Usually, because it's being executed
a# as part of error handling.
aignore() {
a    "$@"
a}
a
a# This wraps curl or wget. Try curl first, if not installed,
a# use wget instead.
adownloader() {
a    local _dld
a    local _ciphersuites
a    local _err
a    local _status
a    local _retry
a    if check_cmd curl; then
a        _dld=curl
a    elif check_cmd wget; then
a        _dld=wget
a    else
a        _dld='curl or wget' # to be used in error message of need_cmd
a    fi
a
a    if [ "$1" = --check ]; then
a        need_cmd "$_dld"
a    elif [ "$_dld" = curl ]; then
a        check_curl_for_retry_support
a        _retry="$RETVAL"
a        get_ciphersuites_for_curl
a        _ciphersuites="$RETVAL"
a        if [ -n "$_ciphersuites" ]; then
a            _err=$(curl $_retry --proto '=https' --tlsv1.2 --ciphers "$_ciphersuites" --silent --show-error --fail --location "$1" --output "$2" 2>&1)
a            _status=$?
a        else
a            echo "Warning: Not enforcing strong cipher suites for TLS, this is potentially less secure"
a            if ! check_help_for "$3" curl --proto --tlsv1.2; then
a                echo "Warning: Not enforcing TLS v1.2, this is potentially less secure"
a                _err=$(curl $_retry --silent --show-error --fail --location "$1" --output "$2" 2>&1)
a                _status=$?
a            else
a                _err=$(curl $_retry --proto '=https' --tlsv1.2 --silent --show-error --fail --location "$1" --output "$2" 2>&1)
a                _status=$?
a            fi
a        fi
a        if [ -n "$_err" ]; then
a            echo "$_err" >&2
a            if echo "$_err" | grep -q 404$; then
a                err "installer for platform '$3' not found, this may be unsupported"
a            fi
a        fi
a        return $_status
a    elif [ "$_dld" = wget ]; then
a        if [ "$(wget -V 2>&1|head -2|tail -1|cut -f1 -d" ")" = "BusyBox" ]; then
a            echo "Warning: using the BusyBox version of wget.  Not enforcing strong cipher suites for TLS or TLS v1.2, this is potentially less secure"
a            _err=$(wget "$1" -O "$2" 2>&1)
a            _status=$?
a        else
a            get_ciphersuites_for_wget
a            _ciphersuites="$RETVAL"
a            if [ -n "$_ciphersuites" ]; then
a                _err=$(wget --https-only --secure-protocol=TLSv1_2 --ciphers "$_ciphersuites" "$1" -O "$2" 2>&1)
a                _status=$?
a            else
a                echo "Warning: Not enforcing strong cipher suites for TLS, this is potentially less secure"
a                if ! check_help_for "$3" wget --https-only --secure-protocol; then
a                    echo "Warning: Not enforcing TLS v1.2, this is potentially less secure"
a                    _err=$(wget "$1" -O "$2" 2>&1)
a                    _status=$?
a                else
a                    _err=$(wget --https-only --secure-protocol=TLSv1_2 "$1" -O "$2" 2>&1)
a                    _status=$?
a                fi
a            fi
a        fi
a        if [ -n "$_err" ]; then
a            echo "$_err" >&2
a            if echo "$_err" | grep -q ' 404 Not Found$'; then
a                err "installer for platform '$3' not found, this may be unsupported"
a            fi
a        fi
a        return $_status
a    else
a        err "Unknown downloader"   # should not reach here
a    fi
a}
a
acheck_help_for() {
a    local _arch
a    local _cmd
a    local _arg
a    _arch="$1"
a    shift
a    _cmd="$1"
a    shift
a
a    local _category
a    if "$_cmd" --help | grep -q 'For all options use the manual or "--help all".'; then
a      _category="all"
a    else
a      _category=""
a    fi
a
a    case "$_arch" in
a
a        *darwin*)
a        if check_cmd sw_vers; then
a            case $(sw_vers -productVersion) in
a                10.*)
a                    # If we're running on macOS, older than 10.13, then we always
a                    # fail to find these options to force fallback
a                    if [ "$(sw_vers -productVersion | cut -d. -f2)" -lt 13 ]; then
a                        # Older than 10.13
a                        echo "Warning: Detected macOS platform older than 10.13"
a                        return 1
a                    fi
a                    ;;
a                11.*)
a                    # We assume Big Sur will be OK for now
a                    ;;
a                *)
a                    # Unknown product version, warn and continue
a                    echo "Warning: Detected unknown macOS major version: $(sw_vers -productVersion)"
a                    echo "Warning TLS capabilities detection may fail"
a                    ;;
a            esac
a        fi
a        ;;
a
a    esac
a
a    for _arg in "$@"; do
a        if ! "$_cmd" --help $_category | grep -q -- "$_arg"; then
a            return 1
a        fi
a    done
a
a    true # not strictly needed
a}
a
a# Check if curl supports the --retry flag, then pass it to the curl invocation.
acheck_curl_for_retry_support() {
a  local _retry_supported=""
a  # "unspecified" is for arch, allows for possibility old OS using macports, homebrew, etc.
a  if check_help_for "notspecified" "curl" "--retry"; then
a    _retry_supported="--retry 3"
a  fi
a
a  RETVAL="$_retry_supported"
a
a}
a
a# Return cipher suite string specified by user, otherwise return strong TLS 1.2-1.3 cipher suites
a# if support by local tools is detected. Detection currently supports these curl backends:
a# GnuTLS and OpenSSL (possibly also LibreSSL and BoringSSL). Return value can be empty.
aget_ciphersuites_for_curl() {
a    if [ -n "${RUSTUP_TLS_CIPHERSUITES-}" ]; then
a        # user specified custom cipher suites, assume they know what they're doing
a        RETVAL="$RUSTUP_TLS_CIPHERSUITES"
a        return
a    fi
a
a    local _openssl_syntax="no"
a    local _gnutls_syntax="no"
a    local _backend_supported="yes"
a    if curl -V | grep -q ' OpenSSL/'; then
a        _openssl_syntax="yes"
a    elif curl -V | grep -iq ' LibreSSL/'; then
a        _openssl_syntax="yes"
a    elif curl -V | grep -iq ' BoringSSL/'; then
a        _openssl_syntax="yes"
a    elif curl -V | grep -iq ' GnuTLS/'; then
a        _gnutls_syntax="yes"
a    else
a        _backend_supported="no"
a    fi
a
a    local _args_supported="no"
a    if [ "$_backend_supported" = "yes" ]; then
a        # "unspecified" is for arch, allows for possibility old OS using macports, homebrew, etc.
a        if check_help_for "notspecified" "curl" "--tlsv1.2" "--ciphers" "--proto"; then
a            _args_supported="yes"
a        fi
a    fi
a
a    local _cs=""
a    if [ "$_args_supported" = "yes" ]; then
a        if [ "$_openssl_syntax" = "yes" ]; then
a            _cs=$(get_strong_ciphersuites_for "openssl")
a        elif [ "$_gnutls_syntax" = "yes" ]; then
a            _cs=$(get_strong_ciphersuites_for "gnutls")
a        fi
a    fi
a
a    RETVAL="$_cs"
a}
a
a# Return cipher suite string specified by user, otherwise return strong TLS 1.2-1.3 cipher suites
a# if support by local tools is detected. Detection currently supports these wget backends:
a# GnuTLS and OpenSSL (possibly also LibreSSL and BoringSSL). Return value can be empty.
aget_ciphersuites_for_wget() {
a    if [ -n "${RUSTUP_TLS_CIPHERSUITES-}" ]; then
a        # user specified custom cipher suites, assume they know what they're doing
a        RETVAL="$RUSTUP_TLS_CIPHERSUITES"
a        return
a    fi
a
a    local _cs=""
a    if wget -V | grep -q '\-DHAVE_LIBSSL'; then
a        # "unspecified" is for arch, allows for possibility old OS using macports, homebrew, etc.
a        if check_help_for "notspecified" "wget" "TLSv1_2" "--ciphers" "--https-only" "--secure-protocol"; then
a            _cs=$(get_strong_ciphersuites_for "openssl")
a        fi
a    elif wget -V | grep -q '\-DHAVE_LIBGNUTLS'; then
a        # "unspecified" is for arch, allows for possibility old OS using macports, homebrew, etc.
a        if check_help_for "notspecified" "wget" "TLSv1_2" "--ciphers" "--https-only" "--secure-protocol"; then
a            _cs=$(get_strong_ciphersuites_for "gnutls")
a        fi
a    fi
a
a    RETVAL="$_cs"
a}
a
a# Return strong TLS 1.2-1.3 cipher suites in OpenSSL or GnuTLS syntax. TLS 1.2
a# excludes non-ECDHE and non-AEAD cipher suites. DHE is excluded due to bad
a# DH params often found on servers (see RFC 7919). Sequence matches or is
a# similar to Firefox 68 ESR with weak cipher suites disabled via about:config.
a# $1 must be openssl or gnutls.
aget_strong_ciphersuites_for() {
a    if [ "$1" = "openssl" ]; then
a        # OpenSSL is forgiving of unknown values, no problems with TLS 1.3 values on versions that don't support it yet.
a        echo "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384"
a    elif [ "$1" = "gnutls" ]; then
a        # GnuTLS isn't forgiving of unknown values, so this may require a GnuTLS version that supports TLS 1.3 even if wget doesn't.
a        # Begin with SECURE128 (and higher) then remove/add to build cipher suites. Produces same 9 cipher suites as OpenSSL but in slightly different order.
a        echo "SECURE128:-VERS-SSL3.0:-VERS-TLS1.0:-VERS-TLS1.1:-VERS-DTLS-ALL:-CIPHER-ALL:-MAC-ALL:-KX-ALL:+AEAD:+ECDHE-ECDSA:+ECDHE-RSA:+AES-128-GCM:+CHACHA20-POLY1305:+AES-256-GCM"
a    fi
a}
a
amain "$@" || exit 1
