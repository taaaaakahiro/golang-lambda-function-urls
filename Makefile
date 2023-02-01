proxy:
	GOOS=linux GOARCH=amd64 go build -o proxy ./api/proxy
	mv proxy ./artifact/proxy

server:
	GOOS=linux GOARCH=amd64 go build -o server ./api/server
	mv server ./artifact/server

apply: proxy server
	terraform apply -auto-approve

	