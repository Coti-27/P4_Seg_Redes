package main

import (
	"fmt"
	"github.com/gin-gonic/gin"
)

func main() {
	fmt.Println("Lab3 assignment template")

	engine := gin.Default()
	// Add HTTP handlers here
	engine.RunTLS("localhost:5000", "cert.crt", "cert-priv.pem")
}
