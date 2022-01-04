package main

import (
    "fmt"
    "github.com/gin-gonic/gin"
)

func HelloWorld(c *gin.Context) {
	c.String(200, "im golang app. plz dont overload me")
}

func main() {
	r := gin.Default()
	r.GET("/", HelloWorld)

	err := r.Run(":8080")
	if err != nil {
		fmt.Print("linter drunk")
	}

}
