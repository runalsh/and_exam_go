FROM golang:alpine as gobuilder
WORKDIR /goapp
COPY . .
RUN go get -u github.com/gin-gonic/gin
RUN CGO_ENABLED=0 go test -v
RUN CGO_ENABLED=0 go build app.go
FROM scratch 
WORKDIR /goapp
COPY --from=gobuilder /goapp/app /goapp/app
EXPOSE 8080
CMD ["/goapp/app"]
