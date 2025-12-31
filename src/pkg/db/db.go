package db

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"

	"github.com/gin-gonic/gin"
)

const (
	DOCUMENTS_ROOT = "data/documents"
	FILE_EXTENSION = ".json"
)

// --- HANDLERS PARA GIN (Añadidos para el microservicio) ---

// UploadHandler: POST /upload?id=nombredoc
func UploadHandler(c *gin.Context) {
	docID := c.Query("id")
	// En una fase real, el username vendría del token.
	// Para la P4, si no implementas validación de token aquí,
	// puedes recibirlo por header o usar uno por defecto para pruebas.
	username := c.GetHeader("X-User")
	if username == "" {
		username = "default_user"
	}

	if docID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id query param required"})
		return
	}

	body, err := c.GetRawData()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "could not read body"})
		return
	}

	size, err := SaveDocument(username, docID, body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "saved", "size": size})
}

// ViewHandler: GET /view/:id
func ViewHandler(c *gin.Context) {
	docID := c.Param("id")
	username := c.GetHeader("X-User")
	if username == "" {
		username = "default_user"
	}

	data, err := GetDocument(username, docID)
	if err != nil {
		if os.IsNotExist(err) {
			c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		}
		return
	}

	var jsonContent interface{}
	json.Unmarshal(data, &jsonContent)
	c.JSON(http.StatusOK, jsonContent)
}

// ListHandler: GET /list
func ListHandler(c *gin.Context) {
	username := c.GetHeader("X-User")
	if username == "" {
		username = "default_user"
	}

	docs, err := GetAllDocuments(username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, docs)
}

// DeleteHandler: DELETE /delete/:id
func DeleteHandler(c *gin.Context) {
	docID := c.Param("id")
	username := c.GetHeader("X-User")
	if username == "" {
		username = "default_user"
	}

	err := DeleteDocument(username, docID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "deleted"})
}

// --- LÓGICA DE PERSISTENCIA (Tu código original con pequeñas correcciones) ---

func cleanPathAndGetLocation(username string, docID string) (string, error) {
	if username == "" || docID == "" {
		return "", fmt.Errorf("username or document ID cannot be empty")
	}
	cleanUsername := filepath.Clean(username)
	cleanDocID := filepath.Clean(docID)

	userDir := filepath.Join(DOCUMENTS_ROOT, cleanUsername)
	docPath := filepath.Join(userDir, cleanDocID+FILE_EXTENSION)

	if err := os.MkdirAll(userDir, 0755); err != nil {
		return "", fmt.Errorf("failed to ensure user directory exists: %w", err)
	}
	return docPath, nil
}

func GetDocument(username string, docID string) ([]byte, error) {
	docPath, err := cleanPathAndGetLocation(username, docID)
	if err != nil {
		return nil, err
	}
	return os.ReadFile(docPath)
}

func SaveDocument(username string, docID string, content []byte) (int, error) {
	docPath, err := cleanPathAndGetLocation(username, docID)
	if err != nil {
		return 0, err
	}
	var tmp interface{}
	if err := json.Unmarshal(content, &tmp); err != nil {
		return 0, fmt.Errorf("invalid json content")
	}
	if err := os.WriteFile(docPath, content, 0644); err != nil {
		return 0, err
	}
	return len(content), nil
}

func DeleteDocument(username string, docID string) error {
	docPath, err := cleanPathAndGetLocation(username, docID)
	if err != nil {
		return err
	}
	return os.Remove(docPath)
}

func GetAllDocuments(username string) (map[string]interface{}, error) {
	userDir := filepath.Join(DOCUMENTS_ROOT, filepath.Clean(username))
	allDocs := make(map[string]interface{})

	files, err := os.ReadDir(userDir)
	if err != nil {
		if os.IsNotExist(err) {
			return allDocs, nil
		}
		return nil, err
	}

	for _, file := range files {
		if !file.IsDir() && filepath.Ext(file.Name()) == FILE_EXTENSION {
			docID := file.Name()[:len(file.Name())-len(FILE_EXTENSION)]
			content, _ := GetDocument(username, docID)
			var docContent interface{}
			if err := json.Unmarshal(content, &docContent); err == nil {
				allDocs[docID] = docContent
			}
		}
	}
	return allDocs, nil
}
