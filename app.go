package main

import (
    "fmt"
    "github.com/gin-gonic/gin"
	"time"
)

func blablabla(c *gin.Context) {
	currentTime := time.Now()
	c.String(200, "im golang app. plz dont overload me! version from 2022-01-10 1:47:14", currentTime.Format("2006.01.02 15:04:05"))
}

func main() {
	r := gin.Default()
	r.GET("/", blablabla)

	err := r.Run(":8080")
	if err != nil {
		fmt.Print("drunk")
	}

}


