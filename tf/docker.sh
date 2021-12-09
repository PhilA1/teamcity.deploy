docker build -t teamcitytf .

echo $'>> Initializing backend...\n'
docker run -i -t teamcitytf init
docker run -i -t teamcitytf plan

echo $'>> Executing Terraform apply...\n'
docker run -i -t teamcitytf apply