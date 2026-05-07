// Package main is a minimal demo Network Function operator stub.
//
// It is intentionally simple — the goal is to give CodeQL, Trivy, Syft and the
// SLSA build-provenance attestor something real to chew on, not to implement
// a working 5G operator.
package main

import (
	"context"
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

const (
	defaultAddr     = ":9100"
	healthPath      = "/healthz"
	metricsPath     = "/metrics"
	shutdownTimeout = 10 * time.Second
)

func main() {
	addr := flag.String("addr", defaultAddr, "address to listen on")
	flag.Parse()

	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	mux := http.NewServeMux()
	mux.HandleFunc(healthPath, healthz)
	mux.HandleFunc(metricsPath, metrics)

	srv := &http.Server{
		Addr:              *addr,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	go func() {
		logger.Info("demo-nf listening", "addr", *addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("listen failed", "err", err)
			os.Exit(1)
		}
	}()

	<-ctx.Done()
	logger.Info("shutdown signal received")

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer shutdownCancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Error("graceful shutdown failed", "err", err)
		os.Exit(1)
	}
	logger.Info("shutdown complete")
}

func healthz(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_, _ = fmt.Fprintln(w, `{"status":"ok","nf":"demo-upf"}`)
}

func metrics(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "text/plain; version=0.0.4")
	w.WriteHeader(http.StatusOK)
	_, _ = fmt.Fprintln(w, "# HELP demo_nf_up 1 if the NF is healthy")
	_, _ = fmt.Fprintln(w, "# TYPE demo_nf_up gauge")
	_, _ = fmt.Fprintln(w, "demo_nf_up 1")
}
