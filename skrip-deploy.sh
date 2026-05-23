#!/bin/sh
# =============================================================================
# skrip-deploy.sh - Pembantu Deploy Odoo Multi-Versi dengan BastilleBSD
# =============================================================================
# Skrip ini membantu deploy jail Odoo untuk pelbagai versi secara automatik.
# Jalankan sebagai root di hos FreeBSD dengan BastilleBSD dipasang.
#
# Penggunaan:
#   sh skrip-deploy.sh [versi] [nama_jail] [ip_jail] [ip_db]
#
# Contoh:
#   sh skrip-deploy.sh 18 odoo-prod 10.10.0.10 10.10.0.20
#   sh skrip-deploy.sh 17 odoo-staging 10.10.0.11 10.10.0.20
# =============================================================================

set -e

# ─── Tetapan ──────────────────────────────────────────────────────────────────
ODOO_VERSION="${1:-18}"
JAIL_NAME="${2:-odoo${ODOO_VERSION}}"
JAIL_IP="${3:-10.0.0.10}"
DB_IP="${4:-10.0.0.20}"
FREEBSD_RELEASE="${5:-14.2-RELEASE}"
BRIDGE="${6:-lo1}"
TEMPLATE_DIR="${7:-$(dirname "$0")}"

# ─── Peta Versi → Konfigurasi ─────────────────────────────────────────────────
case "${ODOO_VERSION}" in
    16)
        ODOO_BRANCH="16.0"
        PYTHON_VER="310"
        ;;
    17)
        ODOO_BRANCH="17.0"
        PYTHON_VER="311"
        ;;
    18)
        ODOO_BRANCH="18.0"
        PYTHON_VER="311"
        ;;
    19)
        # Versi akan datang
        ODOO_BRANCH="19.0"
        PYTHON_VER="312"
        ;;
    master)
        ODOO_BRANCH="master"
        PYTHON_VER="312"
        ;;
    *)
        echo "Versi tidak dikenali: ${ODOO_VERSION}"
        echo "Versi yang disokong: 16, 17, 18, 19, master"
        exit 1
        ;;
esac

# ─── Semak root ───────────────────────────────────────────────────────────────
if [ "$(id -u)" != "0" ]; then
    echo "Ralat: Skrip ini memerlukan keistimewaan root."
    exit 1
fi

# ─── Fungsi Pembantu ──────────────────────────────────────────────────────────
log() { echo "==> $*"; }
err() { echo "!!! RALAT: $*" >&2; exit 1; }

check_cmd() {
    command -v "$1" >/dev/null 2>&1 || err "Perintah '$1' tidak dijumpai."
}

# ─── Periksa Keperluan ────────────────────────────────────────────────────────
check_cmd bastille
check_cmd git

log "======================================================"
log " Deploy Odoo ${ODOO_BRANCH} dalam jail '${JAIL_NAME}'"
log "======================================================"
log "  FreeBSD Release : ${FREEBSD_RELEASE}"
log "  IP Jail         : ${JAIL_IP}"
log "  IP Database     : ${DB_IP}"
log "  Python          : ${PYTHON_VER}"
log "  Bridge/Antara   : ${BRIDGE}"
log ""

# ─── Semak jika jail sudah wujud ─────────────────────────────────────────────
if bastille list | grep -q "^${JAIL_NAME}"; then
    log "Jail '${JAIL_NAME}' sudah wujud. Langkau penciptaan."
else
    log "Mencipta jail '${JAIL_NAME}'..."
    bastille create "${JAIL_NAME}" "${FREEBSD_RELEASE}" "${JAIL_IP}" "${BRIDGE}"
fi

# ─── Jana kata laluan rawak ───────────────────────────────────────────────────
DB_PASSWORD=$(openssl rand -base64 20 | tr -dc 'A-Za-z0-9' | head -c 20)
ADMIN_PASSWD=$(openssl rand -base64 20 | tr -dc 'A-Za-z0-9' | head -c 20)

log "Kata laluan DB dijanakan (simpan ini!): ${DB_PASSWORD}"
log "Kata laluan Admin dijanakan (simpan ini!): ${ADMIN_PASSWD}"

# Simpan kata laluan ke fail selamat
cat > "/root/.odoo_${JAIL_NAME}_credentials.txt" <<EOF
# Kelayakan Jail Odoo: ${JAIL_NAME}
# Dijanakan pada: $(date)
ODOO_VERSION=${ODOO_BRANCH}
JAIL_NAME=${JAIL_NAME}
JAIL_IP=${JAIL_IP}
DB_HOST=${DB_IP}
DB_USER=odoo
DB_PASSWORD=${DB_PASSWORD}
ADMIN_PASSWD=${ADMIN_PASSWD}
EOF
chmod 600 "/root/.odoo_${JAIL_NAME}_credentials.txt"
log "Kelayakan disimpan di: /root/.odoo_${JAIL_NAME}_credentials.txt"

# ─── Apply template ───────────────────────────────────────────────────────────
log "Memasang template Odoo ${ODOO_BRANCH}..."

bastille template "${JAIL_NAME}" "${TEMPLATE_DIR}" \
    --arg "ODOO_VERSION=${ODOO_VERSION}" \
    --arg "ODOO_BRANCH=${ODOO_BRANCH}" \
    --arg "PYTHON_VER=${PYTHON_VER}" \
    --arg "ODOO_USER=odoo" \
    --arg "ODOO_HOME=/usr/local/odoo" \
    --arg "ODOO_PORT=8069" \
    --arg "ODOO_LONGPOLL_PORT=8072" \
    --arg "DB_HOST=${DB_IP}" \
    --arg "DB_PORT=5432" \
    --arg "DB_USER=odoo" \
    --arg "DB_PASSWORD=${DB_PASSWORD}" \
    --arg "ADMIN_PASSWD=${ADMIN_PASSWD}" \
    --arg "WORKERS=4" \
    --arg "MAX_CRON_THREADS=2" \
    --arg "LOG_LEVEL=info" \
    --arg "FREEBSD_VERSION=14"

log ""
log "======================================================"
log " Odoo ${ODOO_BRANCH} berjaya dipasang!"
log "======================================================"
log ""
log " URL Akses:"
log "   http://${JAIL_IP}:8069"
log ""
log " Semak log:"
log "   bastille cmd ${JAIL_NAME} tail -f /var/log/odoo/odoo-${ODOO_BRANCH}.log"
log ""
log " Status servis:"
log "   bastille cmd ${JAIL_NAME} service odoo status"
log ""
log " Kelayakan disimpan di:"
log "   /root/.odoo_${JAIL_NAME}_credentials.txt"
log ""
