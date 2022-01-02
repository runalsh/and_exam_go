package main

import (
    "fmt"
    "github.com/gin-gonic/gin"
)

func HelloWorld(c *gin.Context) {
	c.String(200, "im golang app")
}

func main() {
	r := gin.Default()
	r.GET("/", HelloWorld)

	err := r.Run(":8080")
	if err != nil {
		fmt.Print("fk u linter hehe")
	}

}
