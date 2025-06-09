sudo apt-get update -y
sudo apt-get install -y docker.io

sudo systemctl start docker
sudo systemctl enable docker
sudo docker run -d --restart=always -p 25565:25565 -e EULA=TRUE itzg/minecraft-server