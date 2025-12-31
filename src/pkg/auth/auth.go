package auth

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

// Constantes
const (
	TOKEN_LIFETIME = 5 * time.Minute
	USERS_DIR      = "data/users"
	TOKEN_LENGTH   = 32
)

type TokenData struct {
	Username string
	Expiry   time.Time
}

var (
	tokensMutex  sync.RWMutex
	activeTokens = make(map[string]TokenData)
)

// --- HANDLERS PARA GIN (Esto soluciona el error 'undefined' en main.go) ---

func SignUpHandler(c *gin.Context) {
	var req struct {
		User string `json:"user" binding:"required"`
		Pass string `json:"pass" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}
	if UserExists(req.User) {
		c.JSON(http.StatusConflict, gin.H{"error": "User already exists"})
		return
	}
	if err := SaveUser(req.User, req.Pass); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "User created successfully"})
}

func LoginHandler(c *gin.Context) {
	var req struct {
		User string `json:"user" binding:"required"`
		Pass string `json:"pass" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}
	token, err := AuthenticateUser(req.User, req.Pass)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"token": token})
}

// --- LÓGICA INTERNA ---

func getUsernamePath(username string) string {
	if username == "" || len(username) > 50 {
		return ""
	}
	basePath := filepath.Clean(username)
	if basePath == ".." || basePath == "." || filepath.IsAbs(basePath) || basePath != username {
		return ""
	}
	return filepath.Join(USERS_DIR, basePath+".hash")
}

func UserExists(username string) bool {
	path := getUsernamePath(username)
	if path == "" {
		return false
	}
	_, err := os.Stat(path)
	return !os.IsNotExist(err)
}

func SaveUser(username, password string) error {
	if len(password) < 8 {
		return fmt.Errorf("password too short")
	}
	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	userPath := getUsernamePath(username)
	os.MkdirAll(USERS_DIR, 0755)
	return os.WriteFile(userPath, hashedPassword, 0600)
}

func AuthenticateUser(username, password string) (string, error) {
	userPath := getUsernamePath(username)
	hashedPassword, err := os.ReadFile(userPath)
	if err != nil {
		return "", err
	}
	if err := bcrypt.CompareHashAndPassword(hashedPassword, []byte(password)); err != nil {
		return "", err
	}
	return GenerateAndRegisterToken(username)
}

func GenerateAndRegisterToken(username string) (string, error) {
	tokensMutex.Lock()
	defer tokensMutex.Unlock()
	b := make([]byte, TOKEN_LENGTH)
	io.ReadFull(rand.Reader, b)
	token := hex.EncodeToString(b)
	activeTokens[token] = TokenData{Username: username, Expiry: time.Now().Add(TOKEN_LIFETIME)}
	return token, nil
}
