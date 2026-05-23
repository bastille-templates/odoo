# BastilleBSD Template - Odoo Source Install (Dinamik)

Template BastilleBSD untuk memasang Odoo terus dari source code GitHub,
direka untuk menyokong **pelbagai versi Odoo** secara dinamik menggunakan
sistem ARG BastilleBSD.

## Struktur Template

```
bastille-odoo/
├── Bastillefile                        ← Skrip utama template
├── README.md                           ← Fail ini
├── etc/
│   └── rc.d/
│       └── odoo                        ← Skrip rc.d FreeBSD untuk servis Odoo
└── usr/
    └── local/
        └── etc/
            └── odoo/
                └── odoo.conf           ← Fail konfigurasi Odoo
```

## Keperluan

| Komponen         | Minimum          | Disyorkan        |
|-----------------|-----------------|-----------------|
| FreeBSD          | 13.x             | 14.x / 15.x     |
| BastilleBSD      | 0.9+             | 1.x terbaru     |
| RAM (per jail)   | 2GB              | 4GB+            |
| Storan           | 20GB             | 50GB+           |

## Keserasian Versi Odoo

| Odoo Version | ODOO_BRANCH | PYTHON_VER | Catatan                     |
|-------------|-------------|------------|-----------------------------|
| 16.0         | 16.0        | 310        | Python 3.10+                |
| 17.0         | 17.0        | 310/311    | Python 3.10+ (311 disyorkan)|
| 18.0         | 18.0        | 311        | Python 3.11+ (stabil)       |
| 18.0 (CE)    | 18.0        | 311        | Community Edition           |
| master       | master      | 312        | Pembangunan sahaja          |

## Cara Penggunaan

### 1. Bootstrap template (sekali sahaja)

```sh
# Salin template ke direktori bastille
cp -r bastille-odoo /usr/local/bastille/templates/myorg/odoo
```

### 2. Cipta jail

```sh
# Cipta jail dengan FreeBSD 14.2 dan IP dalaman
bastille create odoo18 14.2-RELEASE 10.0.0.10 lo1
```

### 3. Pasang PostgreSQL (dalam jail berasingan atau host)

```sh
# Pilihan A: Jail PostgreSQL berasingan (disyorkan)
bastille create pgdb 14.2-RELEASE 10.0.0.20 lo1
bastille pkg pgdb install postgresql16-server
bastille sysrc pgdb postgresql_enable=YES
bastille service pgdb postgresql initdb
bastille service pgdb postgresql start
bastille cmd pgdb sudo -u postgres createuser -d -R -S odoo
bastille cmd pgdb sudo -u postgres psql -c "ALTER USER odoo WITH PASSWORD 'changeme';"
```

### 4. Apply template ke jail

**Odoo 18 (terkini):**
```sh
bastille template odoo18 myorg/odoo \
    --arg ODOO_VERSION=18 \
    --arg ODOO_BRANCH=18.0 \
    --arg PYTHON_VER=311 \
    --arg ODOO_USER=odoo \
    --arg ODOO_HOME=/usr/local/odoo \
    --arg ODOO_PORT=8069 \
    --arg DB_HOST=10.0.0.20 \
    --arg DB_PORT=5432 \
    --arg DB_USER=odoo \
    --arg DB_PASSWORD=changeme_password \
    --arg ADMIN_PASSWD=admin_secret_rahsia \
    --arg WORKERS=4 \
    --arg LOG_LEVEL=info
```

**Odoo 17:**
```sh
bastille template odoo17 myorg/odoo \
    --arg ODOO_VERSION=17 \
    --arg ODOO_BRANCH=17.0 \
    --arg PYTHON_VER=311 \
    --arg ODOO_PORT=8069 \
    --arg DB_HOST=10.0.0.20 \
    --arg DB_USER=odoo \
    --arg DB_PASSWORD=changeme_password \
    --arg ADMIN_PASSWD=admin_secret_rahsia \
    --arg WORKERS=2
```

**Odoo 16:**
```sh
bastille template odoo16 myorg/odoo \
    --arg ODOO_VERSION=16 \
    --arg ODOO_BRANCH=16.0 \
    --arg PYTHON_VER=310 \
    --arg ODOO_PORT=8069 \
    --arg DB_HOST=10.0.0.20 \
    --arg DB_USER=odoo \
    --arg DB_PASSWORD=changeme_password \
    --arg ADMIN_PASSWD=admin_secret_rahsia \
    --arg WORKERS=2
```

### 5. Redirect port dari host

```sh
bastille rdr odoo18 tcp 80 8069
bastille rdr odoo18 tcp 8072 8072  # Longpolling/livechat
```

## Konfigurasi Lanjutan

### Pemboleh Ubah ARG

| ARG                   | Lalai              | Keterangan                              |
|-----------------------|--------------------|-----------------------------------------|
| `ODOO_VERSION`        | `18`               | Nombor versi utama                      |
| `ODOO_BRANCH`         | `18.0`             | Cawangan GitHub (mis: 17.0, 18.0)       |
| `ODOO_USER`           | `odoo`             | Pengguna sistem untuk servis Odoo       |
| `ODOO_HOME`           | `/usr/local/odoo`  | Direktori utama Odoo                    |
| `ODOO_PORT`           | `8069`             | Port HTTP Odoo                          |
| `ODOO_LONGPOLL_PORT`  | `8072`             | Port longpolling (live chat)            |
| `DB_HOST`             | `localhost`        | Alamat PostgreSQL                       |
| `DB_PORT`             | `5432`             | Port PostgreSQL                         |
| `DB_USER`             | `odoo`             | Nama pengguna PostgreSQL                |
| `DB_PASSWORD`         | `changeme`         | ⚠️ TUKAR INI!                           |
| `ADMIN_PASSWD`        | `admin_secret`     | ⚠️ TUKAR INI! Kata laluan DB manager   |
| `WORKERS`             | `4`                | Bilangan pekerja Odoo (0=single-thread) |
| `MAX_CRON_THREADS`    | `2`                | Thread cron                             |
| `PYTHON_VER`          | `311`              | Versi Python tanpa titik (310/311/312)  |
| `FREEBSD_VERSION`     | `14`               | Untuk pakej postgresql-client           |
| `LOG_LEVEL`           | `info`             | Paras log                               |
| `INSTALL_WKHTMLTOPDF` | `yes`              | Pasang wkhtmltopdf untuk PDF            |
| `LIMIT_TIME_CPU`      | `600`              | Had masa CPU (saat)                     |
| `LIMIT_TIME_REAL`     | `1200`             | Had masa sebenar (saat)                 |
| `LIMIT_MEMORY_HARD`   | `2684354560`       | Had memori keras (2.5GB)                |
| `LIMIT_MEMORY_SOFT`   | `2147483648`       | Had memori lembut (2GB)                 |

## Mengemas Kini Odoo

Apabila versi baru Odoo dikeluarkan:

```sh
# Dalam jail yang sedang berjalan
bastille cmd odoo18 service odoo stop
bastille cmd odoo18 git -C /usr/local/odoo/src pull
bastille cmd odoo18 python311 -m pip install -r /usr/local/odoo/src/requirements.txt
bastille cmd odoo18 service odoo start
```

Atau untuk versi major baru, cipta jail baharu dengan `ODOO_BRANCH` berbeza.

## Penyelesaian Masalah

### Semak log
```sh
bastille cmd odoo18 tail -f /var/log/odoo/odoo-18.0.log
```

### Semak status servis
```sh
bastille cmd odoo18 service odoo status
bastille cmd odoo18 ps aux | grep odoo
```

### Semak sambungan DB
```sh
bastille cmd odoo18 psql -h 10.0.0.20 -U odoo -c "SELECT version();"
```

### Mulakan semula servis
```sh
bastille service odoo18 odoo restart
```

## Nota Keselamatan

- ⚠️ **Tukar `DB_PASSWORD` dan `ADMIN_PASSWD`** sebelum deploy production
- ⚠️ Gunakan `proxy_mode = True` jika di belakang nginx/haproxy
- ⚠️ Tetapkan `list_db = False` di production untuk sembunyikan senarai DB
- ⚠️ Pastikan fail `/usr/local/etc/odoo/odoo.conf` hanya boleh dibaca oleh pengguna `odoo`

## Lesen

Template ini dilesenkan di bawah BSD 2-Clause License.
Odoo Community Edition dilesenkan di bawah LGPL-3.
