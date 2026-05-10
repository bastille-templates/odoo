# odoo

rangkaian perangkat lunak manajemen bisnis (ERP) open-source terintegrasi yang mencakup CRM, e-commerce, akuntansi, inventaris, manufaktur, dan manajemen proyek dalam satu platform.

pw useradd odoo -d /home/odoo -M -r -s "$(which bash)"

cd /home
git clone --branch 19.0 --single-branch https://github.com/odoo/odoo.git

chown -R odoo:odoo /home/odoo
chmod 771 /home/odoo
setfacl -d -m g::rwx /home/odoo/rrd /home/odoo/logs /home/odoo/bootstrap/cache/ /home/odoo/storage/
setfacl -R -m g::rwx /home/odoo/rrd /home/odoo/logs /home/odoo/bootstrap/cache/ /home/odoo/storage/
