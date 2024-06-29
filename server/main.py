import grpc
from concurrent import futures
import logging
import uuid
from google.protobuf.timestamp_pb2 import Timestamp
import sys
import os

# Add the server directory to the Python path
server_dir = os.path.dirname(os.path.abspath(__file__)) + '/pb'
sys.path.insert(0, server_dir)

# Import the generated protobuf code
from pb import ai_service_pb2
from pb import ai_service_pb2_grpc

class AIService(ai_service_pb2_grpc.AIServiceServicer):
    def Process(self, request, context):
        # Log the incoming request
        logging.info(f"Received chat from user {request.user_id}, session {request.session_id}")

        # Process the chat message (replace this with your actual AI processing logic)
        response_text = f"AI processed: {request.chat_message}"

        # Create and return the response
        response = ai_service_pb2.Response(
            response_text=response_text,
            timestamp=Timestamp()
        )
        response.timestamp.GetCurrentTime()

        return response

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    ai_service_pb2_grpc.add_AIServiceServicer_to_server(AIService(), server)
    server.add_insecure_port('[::]:50051')
    server.start()
    logging.info("Server started on port 50051")
    server.wait_for_termination()

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    serve()