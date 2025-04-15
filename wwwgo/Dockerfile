FROM golang:1.24 AS build

WORKDIR /www

COPY go.mod go.sum ./

RUN go mod download

COPY static ./static/
COPY templates ./templates/
COPY main.go ./

RUN go build -tags lambda.norpc -o main main.go

FROM public.ecr.aws/lambda/provided:al2023

COPY --from=build /www/main ./main

ENTRYPOINT ["./main", "--lambda"]
