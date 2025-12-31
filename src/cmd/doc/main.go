package main

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/networks-security2526/lab3-base/pkg/db"
)

func main() {
	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()

	r.POST("/upload", db.UploadHandler)
	r.GET("/view/:id", db.ViewHandler)
	r.GET("/list", db.ListHandler)
	r.DELETE("/delete/:id", db.DeleteHandler)

	log.Println("Iniciando Servidor DOC en https://10.0.2.4:8080")
	log.Fatal(r.RunTLS(":8080", "/certs/mydb-doc.crt", "/certs/mydb-doc-priv.pem"))
}
