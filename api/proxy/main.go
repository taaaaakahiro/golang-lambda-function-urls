package main

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-sdk-go/aws/session"
	v4 "github.com/aws/aws-sdk-go/aws/signer/v4"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type responseBody struct {
	Detail string `json:"detail"`
}

func main() {
	lambda.Start(handler)
}

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	client := &http.Client{
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
	req, err := http.NewRequest("GET", os.Getenv("LAMBDA_SERVER_URL"), nil)
	if err != nil {
		jsonBytes, _ := json.Marshal(responseBody{
			Detail: "http.Get() Failed",
		})

		return events.APIGatewayProxyResponse{
			StatusCode:      http.StatusInternalServerError,
			IsBase64Encoded: false,
			Body:            string(jsonBytes),
		}, nil
	}

	// リクエストに署名を付加
	sess := session.Must(session.NewSession())
	credential := sess.Config.Credentials
	signer := v4.NewSigner(credential)
	signer.Sign(req, nil, "lambda", "ap-northeast-1", time.Now())

	//リクエスト実行
	resp, err := client.Do(req)
	if err != nil {
		jsonBytes, _ := json.Marshal(responseBody{
			Detail: "client.Do() Failed",
		})

		return events.APIGatewayProxyResponse{
			StatusCode:      http.StatusInternalServerError,
			IsBase64Encoded: false,
			Body:            string(jsonBytes),
		}, nil
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		jsonBytes, _ := json.Marshal(responseBody{
			Detail: "ioutil.ReadAll() Failed",
		})

		return events.APIGatewayProxyResponse{
			StatusCode:      http.StatusInternalServerError,
			IsBase64Encoded: false,
			Body:            string(jsonBytes),
		}, nil
	}

	return events.APIGatewayProxyResponse{
		StatusCode:      http.StatusOK,
		IsBase64Encoded: false,
		Body:            string(body),
	}, nil
}
