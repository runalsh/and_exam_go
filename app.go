package main

import (
    "fmt"
    "github.com/gin-gonic/gin"
)

func blablabla(c *gin.Context) {
	c.String(200, "im golang app. plz dont overload me")
}

func main() {
	r := gin.Default()
	r.GET("/", blablabla)

	err := r.Run(":8080")
	if err != nil {
		fmt.Print("drunk")
	}

}
