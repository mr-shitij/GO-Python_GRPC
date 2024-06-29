package main

import (
	"context"
	"log"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/protobuf/types/known/timestamppb"

	pb "GO-Python_RPC/pb"
)

func main() {
	// Set up a connection to the server.
	conn, err := grpc.Dial("localhost:50051", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewAIServiceClient(conn)

	// Contact the server and print out its response.
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	r, err := c.Process(ctx, &pb.Request{
		UserId:      "123e4567-e89b-12d3-a456-426614174000",
		SessionId:   "987e6543-e21b-12d3-a456-426614174000",
		ChatMessage: "Hello, server!",
		Timestamp:   timestamppb.Now(),
	})
	if err != nil {
		log.Fatalf("could not process chat: %v", err)
	}
	log.Printf("Server response: %s", r.GetResponseText())
}
