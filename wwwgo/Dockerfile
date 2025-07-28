FROM golang:1.24 AS build

WORKDIR /www

COPY go.mod go.sum ./

RUN go mod download

COPY static ./static/
COPY templates ./templates/
COPY main.go ./

RUN GOARCH=arm64 GOOS=linux CGOENABLED=0 go build -tags lambda.norpc -o bootstrap main.go

FROM public.ecr.aws/lambda/provided:al2023

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.9.0-aarch64 /lambda-adapter /opt/extensions/lambda-adapter
COPY --from=build /www/bootstrap ./bootstrap

ENTRYPOINT ["./bootstrap"]
