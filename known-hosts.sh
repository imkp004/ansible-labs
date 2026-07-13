for host in $(awk '/^[0-9]/{print $1}' inventory)
do
    echo "Updating $host"
    ssh-keygen -R "$host" >/dev/null 2>&1
    ssh-keyscan -T 2 -t ed25519 -H "$host" >> ~/.ssh/known_hosts 2>/dev/null
done
