package main

import (
	"crypto/tls"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"

	"github.com/gin-gonic/gin"
)

func proxyTo(target string) gin.HandlerFunc {
	url, _ := url.Parse(target)
	proxy := httputil.NewSingleHostReverseProxy(url)
	proxy.Transport = &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true}, // Confía en certs internos
	}
	return func(c *gin.Context) {
		proxy.ServeHTTP(c.Writer, c.Request)
	}
}

func main() {
	r := gin.Default()

	// El broker responde a /version
	r.GET("/version", func(c *gin.Context) {
		c.JSON(200, gin.H{"version": "v4.0-distributed", "node": "broker"})
	})

	// Redirige Auth (10.0.2.3)
	r.POST("/login", proxyTo("https://10.0.2.3:8080"))
	r.POST("/signup", proxyTo("https://10.0.2.3:8080"))

	// Redirige todo lo demás a Doc (10.0.2.4)
	r.NoRoute(proxyTo("https://10.0.2.4:8080"))

	log.Println("BROKER activo en https://10.0.1.4:8080")
	log.Fatal(r.RunTLS(":8080", "/certs/mydb-broker.crt", "/certs/mydb-broker-priv.pem"))
}
