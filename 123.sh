#!/bin/bash

# Настройки
USERNAME="bax"
SSH_PORT="2222"
PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL9o0i6dEWJnBccrHdif5DfJBlBrYj7+OIU6YirODpHE alihan@komputer"

echo "[1/7] Обновление системы..."
apt update && apt upgrade -y

echo "[2/7] Установка Docker..."
# Установка Docker
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Добавляем пользователя в группу Docker
usermod -aG docker $USERNAME

# Проверим, что Docker установлен
docker --version

echo "[3/7] Установка Fail2Ban..."
# Установка Fail2Ban
apt install -y fail2ban

# Настройка Fail2Ban (по умолчанию защитит SSH)
systemctl enable fail2ban
systemctl start fail2ban

# Проверим статус Fail2Ban

echo "[4/7] Создание пользователя $USERNAME и настройка SSH-ключа..."
useradd -m -s /bin/bash $USERNAME
usermod -aG sudo $USERNAME

mkdir -p /home/$USERNAME/.ssh
echo "$PUBKEY" > /home/$USERNAME/.ssh/authorized_keys
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

echo "[5/7] Настройка SSH-сервера..."
sed -i "s/^#Port.*/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/^Port.*/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i "s/^PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
echo "AllowUsers $USERNAME" >> /etc/ssh/sshd_config

echo "[6/7] Перезапуск SSH..."
systemctl restart ssh

echo "[7/7] Настройка фаервола..."
ufw allow $SSH_PORT/tcp
ufw --force enable

echo "[Готово] Установлены Docker и Fail2Ban. Подключайтесь через: ssh $USERNAME@IP -p $SSH_PORT"
