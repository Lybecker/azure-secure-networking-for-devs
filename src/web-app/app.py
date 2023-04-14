import os
from flask import Flask, request
from blob_storage_client import BlobStorageClient

app = Flask(__name__)

@app.route('/health')
def health():
   return "OK"

@app.route('/')
def index():
   return "Hello world!"

@app.route('/create_blobs')
def create_blobs():
    try:
        blob_storage_client = BlobStorageClient("staznetdemodeveu")
        blob_storage_client.create_container("test")
        file_path = os.path.join("./", "test.txt")
        blob_storage_client.upload_blob("test", file_path)
    except Exception as ex:
        return f"Failed with exception: {ex}"

if __name__ == '__main__':
   app.run()
