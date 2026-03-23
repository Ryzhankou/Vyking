package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
)

var db *sql.DB

type ScoreRequest struct {
	PlayerName string `json:"player_name"`
	Score      int    `json:"score"`
}

type LeaderboardEntry struct {
	Rank       int    `json:"rank"`
	PlayerName string `json:"player_name"`
	Score      int    `json:"score"`
	CreatedAt  string `json:"created_at"`
}

func main() {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true",
		getEnv("DB_USER", "gameuser"),
		getEnv("DB_PASSWORD", "gamepass"),
		getEnv("DB_HOST", "localhost"),
		getEnv("DB_PORT", "3306"),
		getEnv("DB_NAME", "gamedb"),
	)

	var err error
	for i := 0; i < 10; i++ {
		db, err = sql.Open("mysql", dsn)
		if err == nil {
			err = db.Ping()
		}
		if err == nil {
			break
		}
		log.Printf("Waiting for database... attempt %d/10: %v", i+1, err)
		time.Sleep(5 * time.Second)
	}
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	r := mux.NewRouter()
	r.Use(loggingMiddleware)
	r.Use(corsMiddleware)

	r.HandleFunc("/api/health", healthHandler).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/archer/score", submitScoreHandler).Methods("POST", "OPTIONS")
	r.HandleFunc("/api/leaderboard", leaderboardHandler).Methods("GET", "OPTIONS")

	port := getEnv("PORT", "8080")
	log.Printf("Archer game server starting on port %s, DB=%s:%s", port, getEnv("DB_HOST", "?"), getEnv("DB_PORT", "?"))
	log.Fatal(http.ListenAndServe(":"+port, r))
}

type responseRecorder struct {
	http.ResponseWriter
	status int
}

func (rr *responseRecorder) WriteHeader(code int) {
	rr.status = code
	rr.ResponseWriter.WriteHeader(code)
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &responseRecorder{ResponseWriter: w, status: http.StatusOK}
		log.Printf("Request: %s %s from %s", r.Method, r.URL.Path, r.RemoteAddr)
		next.ServeHTTP(rec, r)
		log.Printf("Request %s %s -> %d in %v", r.Method, r.URL.Path, rec.status, time.Since(start))
	})
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func submitScoreHandler(w http.ResponseWriter, r *http.Request) {
	var req ScoreRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.PlayerName == "" {
		http.Error(w, "player_name and score are required", http.StatusBadRequest)
		return
	}
	if req.Score < 0 || req.Score > 500 {
		http.Error(w, "invalid score", http.StatusBadRequest)
		return
	}

	_, err := db.Exec(
		"INSERT INTO leaderboard (player_name, score) VALUES (?, ?)",
		req.PlayerName, req.Score,
	)
	if err != nil {
		log.Printf("Failed to save score: %v", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "saved"})
}

func leaderboardHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query(
		"SELECT player_name, score, created_at FROM leaderboard ORDER BY score DESC LIMIT 10",
	)
	if err != nil {
		log.Printf("Leaderboard query error: %v", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var entries []LeaderboardEntry
	rank := 1
	for rows.Next() {
		var e LeaderboardEntry
		var createdAt time.Time
		if err := rows.Scan(&e.PlayerName, &e.Score, &createdAt); err != nil {
			continue
		}
		e.Rank = rank
		e.CreatedAt = createdAt.Format("2006-01-02 15:04:05")
		entries = append(entries, e)
		rank++
	}

	if entries == nil {
		entries = []LeaderboardEntry{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(entries)
}

func getEnv(key, defaultValue string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultValue
}
