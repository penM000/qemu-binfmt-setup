#!/bin/sh
sudo apt install qemu-user qemu-user-static -y
wget https://raw.githubusercontent.com/qemu/qemu/master/scripts/qemu-binfmt-conf.sh
chmod +x qemu-binfmt-conf.sh 
sudo mv qemu-binfmt-conf.sh /usr/local/bin/qemu-binfmt-conf.sh

cat <<EOF | sudo tee /usr/local/bin/register.sh
#!/bin/sh
QEMU_BIN_DIR=${QEMU_BIN_DIR:-/usr/bin}
if [ ! -d /proc/sys/fs/binfmt_misc ]; then
    echo "No binfmt support in the kernel."
    echo "  Try: '/sbin/modprobe binfmt_misc' from the host"
    exit 1
fi
if [ ! -f /proc/sys/fs/binfmt_misc/register ]; then
    mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
fi
if [ "${1}" = "--reset" ]; then
    shift
    find /proc/sys/fs/binfmt_misc -type f -name 'qemu-*' -exec sh -c 'echo -1 > {}' \;
fi
exec /usr/local/bin/qemu-binfmt-conf.sh --qemu-suffix "-static" --qemu-path "${QEMU_BIN_DIR}" $@
EOF
sudo chmod +x /usr/local/bin/register.sh

cat <<EOF | sudo tee /etc/systemd/system/register.service
[Unit]
Description= register cpu emulator
[Service]
ExecStart = /usr/local/bin/register.sh
Restart = no
Type = simple
RemainAfterExit=yes
[Install]
WantedBy = multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable register.service
sudo systemctl start register.service