set -e
echo "generate ssh key"
echo "------------------------------------------------------------"
ssh-keygen
cat  ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
echo "------------------------------------------------------------"
echo "ssh key generated"