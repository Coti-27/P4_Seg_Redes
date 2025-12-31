package main

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/networks-security2526/lab3-base/pkg/auth"
)

func main() {
	// Gin en modo release para limpiar la consola
	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()

	// Endpoints de identidad según el enunciado
	r.POST("/signup", auth.SignUpHandler)
	r.POST("/login", auth.LoginHandler)

	log.Println("Iniciando Servidor AUTH en https://10.0.2.3:8080")

	// Usamos los certificados montados por el Makefile
	err := r.RunTLS(":8080", "/certs/mydb-auth.crt", "/certs/mydb-auth-priv.pem")
	if err != nil {
		log.Fatal("Error al iniciar el servidor TLS: ", err)
	}
}
