set -e
echo "setting time zone"
echo "------------------------------------------------------------"
timedatectl set-timezone Asia/Shanghai
echo "------------------------------------------------------------"
echp "time zone set"
timedatectl
echo "------------------------------------------------------------"