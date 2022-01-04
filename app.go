package main

import (
    "fmt"
    "github.com/gin-gonic/gin"
)

func HelloWorld(c *gin.Context) {
	c.String(200, "im golang app__set min to 50")
}

func main() {
	r := gin.Default()
	r.GET("/", HelloWorld)

	err := r.Run(":8080")
	if err != nil {
		fmt.Print("linter drunk")
	}

}
