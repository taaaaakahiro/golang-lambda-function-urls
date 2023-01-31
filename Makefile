proxy:
	GOOS=linux GOARCH=amd64 go build -o proxy ./api/proxy

server:
	GOOS=linux GOARCH=amd64 go build -o server ./api/server

build: proxy server
	mv proxy ./artifact/proxy
	mv server ./artifact/server